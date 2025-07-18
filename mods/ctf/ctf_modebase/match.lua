--- @type false | string
ctf_modebase.restart_on_next_match = false -- used by server_restart mod to restart after a match


ctf_modebase.map_on_next_match = nil
ctf_modebase.mode_on_next_match = nil

-- Overridable
function ctf_modebase.map_chosen(map)
end

function ctf_modebase.start_match_after_mode_vote()
	local old_mode = ctf_modebase.current_mode

	if ctf_modebase.mode_on_next_match ~= old_mode then
		ctf_modebase.on_mode_end()
		ctf_modebase.current_mode = ctf_modebase.mode_on_next_match
		ctf_modebase.on_mode_start()
	end
	ctf_modebase.mode_on_next_match = nil

	if ctf_modebase.map_on_next_match then
		ctf_modebase.map_catalog.current_map = ctf_modebase.map_catalog.map_dirnames[ctf_modebase.map_on_next_match]
		ctf_modebase.map_on_next_match = nil
		ctf_modebase.start_match_after_map_vote()
	else
		ctf_modebase.map_vote.start_vote()
	end
end

function ctf_modebase.start_match_after_map_vote()
	ctf_modebase.show_loading_screen()
	local map = ctf_modebase.map_catalog.maps[ctf_modebase.map_catalog.current_map]
	ctf_modebase.map_chosen(map)
	ctf_map.place_map(map, function()
		-- Set time and time_speed
		minetest.set_timeofday(map.start_time/24000)
		minetest.settings:set("time_speed", map.time_speed * 72)

		ctf_map.announce_map(map)
		ctf_modebase.announce(string.format("New match: %s map by %s, %s mode",
			map.name,
			map.author,
			HumanReadable(ctf_modebase.current_mode))
		)

		ctf_modebase.on_new_match()

		ctf_modebase.in_game = true
		ctf_teams.allocate_teams(ctf_map.current_map.teams)

		ctf_modebase.current_mode_matches_played = ctf_modebase.current_mode_matches_played + 1

		local current_map = ctf_map.current_map
		local current_mode = ctf_modebase.current_mode

		if table.indexof(current_map.game_modes, current_mode) == -1 then
			local concat = "The current mode is not in the list of modes supported by the current map."
			local cmd_text = string.format("/ctf_next -f [mode:technical modename] %s", current_map.dirname)
			local msg = minetest.colorize(
				"red", string.format("%s\nSupported mode(s): %s. To switch to a mode set for the map, do %s",
				concat, table.concat(current_map.game_modes, ", "), cmd_text))

			chat_lib.send_message_to_privileged(msg, {"ctf_admin", "server"})
		end
	end)
end

local function start_new_match()
	ctf_modebase.in_game = false
	ctf_modebase.on_match_end()

	if ctf_modebase.restart_on_next_match then
		return
	end

	if ctf_modebase.mode_on_next_match then
		ctf_modebase.current_mode_matches_played = 0
		ctf_modebase.start_match_after_mode_vote()
	elseif ctf_modebase.current_mode_matches_played >= ctf_modebase.current_mode_matches or
	not ctf_modebase.current_mode then
		ctf_modebase.current_mode_matches_played = 0
		ctf_modebase.mode_vote.start_vote()
	else
		ctf_modebase.mode_on_next_match = ctf_modebase.current_mode
		ctf_modebase.start_match_after_mode_vote()
	end
end

function ctf_modebase.start_new_match(delay)
	ctf_modebase.match_started = false
	if delay and delay > 0 then
		minetest.after(delay, start_new_match)
	else
		start_new_match()
	end
end

minetest.register_chatcommand("ctf_next", {
	description = "Set a new map and mode",
	privs = {ctf_admin = true},
	params = "[-f] [mode:technical modename] [technical mapname]",
	func = function(name, param)
		minetest.log("action", string.format("[ctf_admin] %s ran /ctf_next %s", name, param))

		local force = param == "-f"
		if force then
			param = ""
		else
			local _, pos = param:find("^-f +")
			if pos then
				param = param:sub(pos + 1)
				force = true
			end
		end

		if force and not ctf_modebase.in_game then
			return false, "Map switching is in progress"
		end

		local map, mode = ctf_modebase.match_mode(param)

		if mode then
			if not ctf_modebase.modes[mode] then
				return false, "No such game mode: " .. mode
			end
		end

		if map then
			if not ctf_modebase.map_catalog.map_dirnames[map] then
				return false, "No such map: " .. map
			end
		end

		ctf_modebase.map_on_next_match = map
		ctf_modebase.mode_on_next_match = mode

		if force then
			ctf_modebase.start_new_match()

			return true, "Skipping match..."
		else
			return true, "The next map and mode are queued"
		end
	end,
})

minetest.register_chatcommand("ctf_skip", {
	description = "Skip to a new match",
	privs = {ctf_admin = true},
	func = function(name, param)
		minetest.log("action", string.format("[ctf_admin] %s ran /ctf_skip", name))

		if not ctf_modebase.in_game then
			return false, "Map switching is in progress"
		end

		ctf_modebase.start_new_match()

		return true, "Skipping match..."
	end,
})