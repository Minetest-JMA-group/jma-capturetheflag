--Created by Fhelron
--Email: fhelron@danielschlep.de
--XMPP/Jabber: fhelron@jmaminetest.mooo.com
--License: LGPL-3-or-later

--default values (overriding this when the settings exist)
local FILEPATH = core.settings:get("server_status.filepath")
	or (core.get_worldpath() .. "/server_status.json")

local ie_env = algorithms.request_insecure_environment()
if not ie_env then
	core.log("error", "[server_status]: Failed to obtain insecure environment.")
	return
end

local function produce_server_status()
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

	local data, err = core.write_json(status)
	if err then
		core.log("error", "[server_status]: Failed to write status to JSON ("..err..")")
	end
	return data
end

ie_env.unlink(FILEPATH)
do
	local errstr = ie_env.mkfifo(FILEPATH, 0644)
	if errstr then
		core.log("error", "[server_status]: Failed to create a pipe ("..errstr..")")
		return
	end
	local errstr = ie_env.signal(algorithms.signal.SIGPIPE, algorithms.signal.SIG_IGN)
	if errstr then
		core.log("error", "[server_status]: Failed to ignore SIGPIPE ("..errstr..")")
		return
	end
end
local flags = bit.bor(algorithms.fcntl.O_WRONLY, algorighms.fcntl.O_NONBLOCK)
local fatal_error = false

core.register_globalstep(function(dtime)
	if fatal_error then
		-- Don't repeat the same mistake over and over again to spam the log
		return
	end
	local fd, errstr, errnum = ie_env.open(FILEPATH, flags)
	if errnum == algorithms.errno.ENXIO then
		return
	end
	if not fd then
		core.log("error", "[server_status]: Failed to open a pipe ("..errstr..")")
		fatal_error = true
		return
	end

	local data = produce_server_status()
	if not data then
		fatal_error = true
		ie_env.close(fd)
		return
	end
	local bytes_written = 0
	while bytes_written ~= #data do
		local b, errstr, errnum = ie_env.write(fd, data:sub(bytes_written+1))
		if errnum == algorithms.errno.EINTR then
			goto continue
		end
		if errstr then
			core.log("error", "[server_status]: Failed to write to pipe ("..errstr..")")
			fatal_error = true
			break
		end
		bytes_written = bytes_written + b
		::continue::
	end
	ie_env.close(fd)
end)
