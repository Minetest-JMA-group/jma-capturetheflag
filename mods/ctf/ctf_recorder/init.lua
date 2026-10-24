local storage = core.get_mod_storage()
local AUTO_KEY = "auto_record"

-- The replay scratch area: a band above the maps (around y=0) and Elysium
-- (y=500..624). Arenas are placed along +X and reused once they are free.
local SCRATCH_POS = { x = 0, y = 4096, z = 0 }
local SCRATCH_GAP = 8
local MAX_ARENA_CANDIDATES = 1024

local recording_id
local auto_record = storage:get_string(AUTO_KEY) == "true"

local function set_auto_record(enabled)
	if auto_record == enabled then
		return
	end
	auto_record = enabled
	storage:set_string(AUTO_KEY, enabled and "true" or "false")
end

local recorder_available = recorder ~= nil and recorder.start ~= nil
local replay_available = recorder_replay ~= nil and recorder_replay.sessions ~= nil

local function add_box(boxes, box)
	if box and box.pos1 and box.pos2 then
		boxes[#boxes + 1] = box
	end
end

-- Everything a replay arena must not overwrite.
local function protected_boxes()
	local boxes = {}
	add_box(boxes, ctf_map.current_map)
	add_box(boxes, ctf_jma_elysium.maps.main)
	for _, box in pairs(ctf_jma_elysium.boxes) do
		add_box(boxes, box)
	end
	return boxes
end

local function provide_arena(size, taken)
	local sx = math.max(1, math.floor(size.x))
	local sy = math.max(1, math.floor(size.y))
	local sz = math.max(1, math.floor(size.z))

	local conflicts = {}
	for _, box in ipairs(taken or {}) do
		add_box(conflicts, box)
	end
	for _, box in ipairs(protected_boxes()) do
		conflicts[#conflicts + 1] = box
	end

	local x = SCRATCH_POS.x
	for _ = 1, MAX_ARENA_CANDIDATES do
		local box = {
			pos1 = { x = x, y = SCRATCH_POS.y, z = SCRATCH_POS.z },
			pos2 = {
				x = x + sx - 1,
				y = SCRATCH_POS.y + sy - 1,
				z = SCRATCH_POS.z + sz - 1,
			},
		}

		local hit
		for _, other in ipairs(conflicts) do
			if recorder_common.region.overlaps(box, other) then
				hit = other
				break
			end
		end
		if not hit then
			return box.pos1, box.pos2
		end
		x = hit.pos2.x + SCRATCH_GAP
	end

	return nil, "the replay scratch area is full"
end

local function before_enter(player)
	local name = player:get_player_name()
	if ctf_jma_elysium.get_player(name) then
		if not ctf_jma_elysium.detach(player) then
			core.log("warning", "[ctf_recorder] cannot detach " .. name .. " from Elysium")
		end
	end
	ctf_modebase.player.leave_match(player)
end

local function on_leave(player)
	-- Elysium claims the player before its prejoin callbacks, so this is a
	-- transfer into Elysium rather than a return to the match.
	if ctf_jma_elysium.get_player(player:get_player_name()) then
		return
	end
	ctf_modebase.player.rejoin_match(player, { clear_inventory = true })
end

local function leave_replay_for_elysium(player)
	if not replay_available then
		return
	end
	local session = recorder_replay.sessions.for_player(player:get_player_name())
	if session then
		recorder_replay.sessions.leave(session, player)
	end
end

local function stop_recording(reason)
	if not recording_id then
		return
	end
	local id = recording_id
	recording_id = nil
	local err = recorder.stop(id, reason)
	if err then
		core.log("error", "[ctf_recorder] cannot stop " .. id .. ": " .. tostring(err))
	end
end

local function add_metadata(id, map_name, mode_name)
	for _, entry in ipairs(recorder.list()) do
		if entry.id == id then
			if entry.recording then
				recorder.add_meta("ctf:map", map_name, id)
				recorder.add_meta("ctf:mode", mode_name, id)
			elseif entry.snapshotting or entry.catching_up then
				core.after(1, add_metadata, id, map_name, mode_name)
			end
			return
		end
	end
end

local function can_enter_replay(player)
	if player:get_hp() == 0 then
		return false, "You cannot watch a replay while dead."
	end
	if player:get_attach() then
		return false, "You cannot watch a replay while attached."
	end
	return true
end

local function start_auto_recording()
	if not auto_record then
		return
	end
	if not recorder_available then
		core.log(
			"error",
			"[ctf_recorder] auto-record is enabled but recorder_capture is unavailable"
		)
		return
	end

	local map = ctf_map.current_map
	if not map then
		return
	end

	stop_recording("superseded")

	local id, err = recorder.start(map.dirname, { pos1 = map.pos1, pos2 = map.pos2 })
	if not id then
		core.log("error", "[ctf_recorder] cannot start recording: " .. tostring(err))
		return
	end

	recording_id = id
	core.log(
		"action",
		"[ctf_recorder] started recording " .. map.dirname .. " (" .. id .. ")"
	)
	core.after(1, add_metadata, id, map.dirname, ctf_modebase.current_mode or "")
end

ctf_api.register_on_new_match(function()
	-- Run after the mode's on_new_match has placed the map's chests.
	core.after(0, start_auto_recording)
end)

ctf_api.register_on_match_end(function()
	stop_recording("match_end")
end)

if recorder_common then
	recorder_common.register_game_hooks({
		world_persistent = false,
		arena = provide_arena,
		can_enter = can_enter_replay,
		before_enter = before_enter,
		on_leave = on_leave,
	})
end
ctf_jma_elysium.register_on_prejoin(leave_replay_for_elysium)

core.register_chatcommand("ctf_record", {
	description = "Toggle automatic recording of matches",
	params = "[on|off|status]",
	privs = { ctf_admin = true },
	func = function(name, param)
		local command = (param or ""):match("^(%S*)")
		if command == "on" then
			if not recorder_available then
				return false, "recorder_capture is not available"
			end
			set_auto_record(true)
			return true, "Automatic match recording enabled from the next match."
		elseif command == "off" then
			set_auto_record(false)
			stop_recording("auto_record_disabled")
			return true, "Automatic match recording disabled."
		elseif command == "" or command == "status" then
			local state = auto_record and "on" or "off"
			local running = "not recording"
			if recording_id then
				running = "recording " .. recording_id
			end
			local unavailable = recorder_available and "" or " (recorder_capture unavailable)"
			return true,
				string.format("Auto-record is %s; %s%s.", state, running, unavailable)
		end
		return false, "Usage: /ctf_record [on|off|status]"
	end,
})
