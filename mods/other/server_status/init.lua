--Created by Fhelron
--Email: fhelron@danielschlep.de
--XMPP/Jabber: fhelron@jmaminetest.mooo.com
--License: LGPL-3-or-later

--default values (overriding this when the settings exist)
local UPDATE_INTERVAL = tonumber(core.settings:get("server_status.update_interval")) or 20
local FILEPATH = core.settings:get("server_status.filepath")
	or (core.get_worldpath() .. "/server_status.json")

local timer = 0

local function write_server_status()
	local uptime_seconds = core.get_server_uptime()

	local max_lag = core.get_server_max_lag()
	local max_lag_str = string.format("%.3f", max_lag)

	local player_count = #core.get_connected_players()

	--Gameinfo details
	local map = ctf_map.current_map
	local authors = (type(map) == "table" and map.author) or "unknown"
	local mode = ctf_modebase.current_mode
	local time_elapsed = ctf_map.get_duration()
	--helping variables
	local matches_played = ctf_modebase.current_mode_matches_played
	local total_matches = ctf_modebase.current_mode_matches
	--write the 2 above together in one variable

	if time_elapsed == "-" then
		time_elapsed = "Build time - Match not started yet"
	else
		time_elapsed = ctf_map.get_duration()
	end

	local status = {
		uptime = uptime_seconds,
		max_lag = max_lag_str,
		player_count = player_count,
		map_name = map and map.name or "unknown",
		mode = mode,
		time_elapsed = time_elapsed,
		matches_played = matches_played,
		total_matches = total_matches,
		-- collect player names
		players = {},
		--authors
		authors = authors,
	}

	-- add the player names to the players table
	for _, player in ipairs(core.get_connected_players()) do
		table.insert(status.players, player:get_player_name())
	end

	-- write
	local file = io.open(FILEPATH, "w")
	if file then
		file:write(core.serialize(status))
		file:close()
		core.log("action", "server_status written")
	else
		core.log("error", "Can't open the server_status")
	end
end

core.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer >= UPDATE_INTERVAL then
		write_server_status()
		timer = 0
	end
end)
