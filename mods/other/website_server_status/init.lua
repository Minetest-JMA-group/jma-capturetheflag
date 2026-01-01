local filepath = minetest.get_worldpath() .. "/server_status.json"
local timer = 0

local function write_server_status()
    local uptime_seconds = minetest.get_server_uptime()

    -- days, hours, minutes
    local days = math.floor(uptime_seconds / 86400)
    local remaining_seconds = uptime_seconds % 86400
    local hours = math.floor(remaining_seconds / 3600)
    local minutes = math.floor((remaining_seconds % 3600) / 60)

    -- format
    local uptime_str
    if days > 0 then
        uptime_str = string.format("%dd, %02dh, %02dmin", days, hours, minutes)
    elseif hours > 0 then
        uptime_str = string.format("%dh, %02dmin", hours, minutes)
    else
        uptime_str = string.format("%dmin", minutes)
    end

    local max_lag = minetest.get_server_max_lag()
    local max_lag_str = string.format("%.3f", max_lag)
    local player_count = #minetest.get_connected_players()

    --Gameinfo details
    local map = ctf_map.current_map
    local mode = HumanReadable(ctf_modebase.current_mode)
    local time_elapsed = ctf_map.get_duration()
    --helping variables
    local matches_played = ctf_modebase.current_mode_matches_played
    local total_matches = ctf_modebase.current_mode_matches
    --write the 2 above together in one variable
    local match_info = "Round " .. matches_played  .. " of " .. total_matches
    --
    local authors = map.author

    if time_elapsed == "-" then
        time_elapsed = "Build time - Match not started yet"
    else
        time_elapsed = ctf_map.get_duration()
    end




    local status = {
        uptime = uptime_str,
        max_lag = max_lag_str,
        player_count = player_count,
        map_name = map and map.name or "unknown",
        mode = mode,
        time_elapsed = time_elapsed,
        matches = match_info,
        -- collect player names
        players = {},
        -- authors
        authors = map and map.author or "unknown",
    }

    -- add the player names to the players table
    for _, player in ipairs(minetest.get_connected_players()) do
        table.insert(status.players, player:get_player_name())
        end

    -- write
    local file = io.open(filepath, "w")
    if file then
        file:write(minetest.serialize(status))
        file:close()
        minetest.log("action", "server_status geschrieben")
    else
        minetest.log("error", "Konnte server_status.json nicht öffnen")
    end
end

minetest.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer >= 20 then
        write_server_status()
        timer = 0
    end
end)
