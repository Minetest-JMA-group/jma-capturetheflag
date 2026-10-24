local storage = core.get_mod_storage()
local AUTO_KEY = "auto_record"
local MAX_VOLUME_KEY = "max_volume"
local MAX_AREA_KEY = "max_area"
local MODES_KEY = "modes"
local DEFAULT_MODES = "classes,nade_fight,classic"

-- The replay scratch area: a band above the maps (around y=0) and Elysium
-- (y=500..624). Arenas are placed along +X and reused once they are free.
local SCRATCH_POS = { x = 0, y = 4096, z = 0 }
local SCRATCH_GAP = 8
local MAX_ARENA_CANDIDATES = 1024

local function parse_limit(value)
	value = (value or ""):lower()
	if value == "inf" or value == "infinite" or value == "unlimited" then
		return math.huge
	end
	if not value:match("^%d+$") then
		return nil
	end
	return tonumber(value)
end

local function parse_modes(value)
	local names, seen = {}, {}
	for token in (value or ""):gmatch("[^,%s]+") do
		token = token:lower()
		if not seen[token] then
			seen[token] = true
			names[#names + 1] = token
		end
	end
	if #names == 0 then
		return nil
	end
	return table.concat(names, ","), seen
end

local recording_id
local auto_record = storage:get_string(AUTO_KEY) == "true"
local limits = {
	max_volume = {
		key = MAX_VOLUME_KEY,
		label = "Maximum recorded map volume",
		value = parse_limit(storage:get_string(MAX_VOLUME_KEY)) or math.huge,
	},
	max_area = {
		key = MAX_AREA_KEY,
		label = "Maximum recorded map surface area",
		value = parse_limit(storage:get_string(MAX_AREA_KEY)) or math.huge,
	},
}
local record_modes_string, record_modes = parse_modes(storage:get_string(MODES_KEY))
if not record_modes_string then
	record_modes_string, record_modes = parse_modes(DEFAULT_MODES)
end

local function set_auto_record(enabled)
	if auto_record == enabled then
		return
	end
	auto_record = enabled
	storage:set_string(AUTO_KEY, enabled and "true" or "false")
end

local function set_limit(setting, value)
	local s = limits[setting]
	local limit = parse_limit(value)
	if not limit then
		return false, string.format(
			"%s is %s.\nEnter a non-negative node count or 'inf'.",
			s.label,
			tostring(s.value)
		)
	end
	if s.value ~= limit then
		s.value = limit
		storage:set_string(s.key, tostring(limit))
	end
	return true,
		string.format(
			"%s set to %s (applies from the next match).",
			s.label,
			tostring(limit)
		)
end

local function set_modes(value)
	local normalized, set = parse_modes(value)
	if not normalized then
		return false,
			"Recorded modes are " .. record_modes_string
				.. ".\nEnter at least one mode, comma-separated."
	end
	for mode in pairs(set) do
		if not ctf_modebase.modes[mode] then
			return false, "Unknown mode: " .. mode
		end
	end
	if record_modes_string ~= normalized then
		record_modes_string = normalized
		record_modes = set
		storage:set_string(MODES_KEY, normalized)
	end
	return true,
		"Recorded modes set to " .. normalized .. " (applies from the next match)."
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

	local mode = ctf_modebase.current_mode
	if not mode or not record_modes[mode] then
		core.log(
			"action",
			"[ctf_recorder] skipping " .. map.dirname .. ": mode " .. tostring(mode)
				.. " is not recorded"
		)
		return
	end

	local sx = map.pos2.x - map.pos1.x + 1
	local sy = map.pos2.y - map.pos1.y + 1
	local sz = map.pos2.z - map.pos1.z + 1
	local volume = sx * sy * sz
	local area = sx * sz

	if volume > limits.max_volume.value then
		core.log(
			"action",
			"[ctf_recorder] skipping " .. map.dirname .. ": volume " .. volume
				.. " exceeds " .. tostring(limits.max_volume.value)
		)
		return
	end
	if area > limits.max_area.value then
		core.log(
			"action",
			"[ctf_recorder] skipping " .. map.dirname .. ": area " .. area
				.. " exceeds " .. tostring(limits.max_area.value)
		)
		return
	end

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

local function status_lines()
	local state = auto_record and "on" or "off"
	local running = "not recording"
	if recording_id then
		running = "recording " .. recording_id
	end
	local unavailable = recorder_available and "" or " (recorder_capture unavailable)"
	return table.concat({
		string.format("Auto-record is %s; %s%s.", state, running, unavailable),
		"Max volume: " .. tostring(limits.max_volume.value),
		"Max area: " .. tostring(limits.max_area.value),
		"Modes: " .. record_modes_string,
	}, "\n")
end

local usage_lines = table.concat({
	"Usage: /ctf_record <command> [arg]",
	"on|off: enable or disable automatic match recording",
	"status: show the current settings",
	"max_volume <n|inf>: skip maps with volume x*y*z above n nodes",
	"max_area <n|inf>: skip maps with surface area x*z above n nodes",
	"modes <mode[,mode...]>: only record these modes (default: " .. DEFAULT_MODES .. ")",
}, "\n")

local function ctf_record_console(_, param)
	local command, rest = (param or ""):match("^(%S*)%s*(.-)%s*$")
	if command == "" or command == "status" then
		return true, status_lines()
	elseif command == "on" then
		if not recorder_available then
			return false, "recorder_capture is not available"
		end
		set_auto_record(true)
		return true, "Automatic match recording enabled from the next match."
	elseif command == "off" then
		set_auto_record(false)
		stop_recording("auto_record_disabled")
		return true, "Automatic match recording disabled."
	elseif limits[command] then
		return set_limit(command, rest)
	elseif command == "modes" then
		return set_modes(rest)
	end
	return false, usage_lines
end

core.register_chatcommand("ctf_record", {
	description = "Manage automatic match recording",
	params = "<command> [arg]",
	privs = { ctf_admin = true },
	func = ctf_record_console,
})
