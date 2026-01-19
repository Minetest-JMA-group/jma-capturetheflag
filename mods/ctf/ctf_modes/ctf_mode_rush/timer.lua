local timer = {}

timer.ROUND_DURATION = 300
timer.HUD_UPDATE_INTERVAL = 0.5

local state
local config = {
	is_mode_active = function()
		return false
	end,
	on_time_expired = function() end,
}

local hud_timer = 0

local function ensure_state()
	if not state then
		error("ctf_mode_rush.timer not initialised")
	end
end

local function get_alive_counts()
	local counts = {}

	for team, players in pairs(state.alive_players) do
		local count = 0
		for _, alive in pairs(players) do
			if alive then
				count = count + 1
			end
		end
		counts[team] = count
	end

	return counts
end

local function format_round_hud_text()
	if not state.match_id then
		return ""
	end

	local time_left = math.max(0, state.round_time_left or 0)
	local minutes = math.floor(time_left / 60)
	local seconds = math.floor(time_left % 60)
	local time_line = string.format("Time: %d:%02d", minutes, seconds)

	local counts = get_alive_counts()
	local team_parts = {}
	for _, team_name in ipairs(ctf_teams.teamlist) do
		local count = counts[team_name]
		if count then
			local label = HumanReadable(team_name)
			table.insert(team_parts, string.format("%s: %d", label, count))
		end
	end

	local teams_line = table.concat(team_parts, "  ")
	if teams_line ~= "" then
		return time_line .. "\n" .. teams_line
	end

	return time_line
end

local function update_round_hud_for_player(player)
	local text = format_round_hud_text()
	local pname = player:get_player_name()

	if text == "" then
		timer.clear_round_hud(pname)
		return
	end

	local handle = state.hud_handles[pname]
	if not handle then
		handle = player:hud_add({
			type = "text",
			position = { x = 1, y = 1 },
			offset = { x = -20, y = -80 },
			alignment = { x = -1, y = -1 },
			number = 0xFFFFFF,
			scale = { x = 100, y = 100 },
			text = text,
		})
		state.hud_handles[pname] = handle
	else
		player:hud_change(handle, "text", text)
	end
end

function timer.setup(opts)
	state = opts.state or error("timer.setup requires state")

	if opts.is_mode_active then
		config.is_mode_active = opts.is_mode_active
	end

	if opts.on_time_expired then
		config.on_time_expired = opts.on_time_expired
	end
end

function timer.set_timeout_handler(func)
	config.on_time_expired = func or function() end
end

function timer.clear_round_hud(name)
	ensure_state()

	local handle = state.hud_handles[name]
	if not handle then
		return
	end

	local player = core.get_player_by_name(name)
	if player then
		player:hud_remove(handle)
	end

	state.hud_handles[name] = nil
end

function timer.clear_all_round_huds()
	ensure_state()

	for name in pairs(state.hud_handles) do
		timer.clear_round_hud(name)
	end
end

function timer.update_round_huds()
	ensure_state()

	if not state.round_timer_active then
		timer.clear_all_round_huds()
		return
	end

	if not config.is_mode_active() or not state.match_id then
		timer.clear_all_round_huds()
		return
	end

	for _, player in ipairs(core.get_connected_players()) do
		update_round_hud_for_player(player)
	end
end

function timer.reset()
	ensure_state()

	state.round_time_left = 0
	state.round_timer_active = false
	state.hud_handles = {}
	hud_timer = 0
end

function timer.start_round(duration)
	ensure_state()

	state.round_time_left = duration or timer.ROUND_DURATION
	state.round_timer_active = true
	timer.update_round_huds()
end

function timer.stop_round()
	ensure_state()

	state.round_timer_active = false
	timer.update_round_huds()
end

function timer.on_globalstep(dtime)
	ensure_state()

	if not config.is_mode_active() then
		return
	end

	if state.round_timer_active then
		state.round_time_left = math.max(0, (state.round_time_left or 0) - dtime)
		if state.round_time_left <= 0 then
			state.round_time_left = 0
			state.round_timer_active = false
			config.on_time_expired()
		end
	end

	hud_timer = hud_timer + dtime
	if hud_timer >= timer.HUD_UPDATE_INTERVAL then
		hud_timer = 0
		timer.update_round_huds()
	end
end

function timer.get_alive_counts()
	ensure_state()
	return get_alive_counts()
end

core.register_on_joinplayer(function(player)
	local pname = player.get_player_name()
	update_round_hud_for_player(pname)
end)

return timer
