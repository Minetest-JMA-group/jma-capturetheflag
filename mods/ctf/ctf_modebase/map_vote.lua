local VOTING_TIME = 20
local NUM_MAPS_VOTE = 3

local map_sample = nil
local timer = nil
local formspec_send_timer = nil
local votes = nil
local voted = nil
local voters_count = nil

local storage = minetest.get_mod_storage()

-- Vote history tracking
local vote_history = {
    per_day = {},
    per_week = {},
    per_month = {},
}

-- Load vote history from storage
local function load_vote_history()
    local data = storage:get_string("vote_history")
    if data and data ~= "" then
        local ok, result = pcall(minetest.deserialize, data)
        if ok and type(result) == "table" then
            vote_history = result
        end
    end
end

-- Save vote history to storage
local function save_vote_history()
    local data = minetest.serialize(vote_history)
    storage:set_string("vote_history", data)
end

load_vote_history()

-- Helper to get sliding keys
local function get_date_keys()
    local now = os.time()
    return {
        day = os.date("%Y-%m-%d", now),
        week = os.date("%Y-W%U", now),
        month = os.date("%Y-%m", now),
    }
end

-- Record a vote result
function vote_history.record(mapID)
    local keys = get_date_keys()

    for _, timeframe in ipairs({"per_day", "per_week", "per_month"}) do
        local key = keys[timeframe:sub(5)]
        vote_history[timeframe][key] = vote_history[timeframe][key] or {}
        vote_history[timeframe][key][mapID] = (vote_history[timeframe][key][mapID] or 0) + 1
    end

    save_vote_history()
end

minetest.register_privilege("mapcreator", {
    description = "Allows use of the /maps_s command to view map voting statistics",
    give_to_singleplayer = false, -- Optionally, don't give to singleplayer by default
})

-- Command to show map stats
minetest.register_chatcommand("maps_s", {
    description = "Display vote stats for each map",
    privs = {mapcreator = true},
    func = function(name)
        local keys = get_date_keys()

        local function format_stats(label, data)
            local text = label .. ":\n"
            local total_votes = 0
            local counts = {}

            for mapID, count in pairs(data or {}) do
                counts[mapID] = count
                total_votes = total_votes + count
            end

            if total_votes == 0 then
                return text .. "  No data.\n"
            end

            for mapID, count in pairs(counts) do
                local map_name = ctf_modebase.map_catalog.map_names[mapID] or tostring(mapID)
                local percent = string.format("%.1f", (count / total_votes) * 100)
                text = text .. string.format("  %s: %s%% (%d votes)\n", map_name, percent, count)
            end
            return text
        end

        local msg = format_stats("Votes today", vote_history.per_day[keys.day])
        msg = msg .. "\n" .. format_stats("Votes this week", vote_history.per_week[keys.week])
        msg = msg .. "\n" .. format_stats("Votes this month", vote_history.per_month[keys.month])

        minetest.chat_send_player(name, msg)
    end,
})

-- Vote logic
ctf_modebase.map_vote = {}

local function player_vote(name, mapID)
    if not voted then return end

    if not voted[name] then
        voters_count = voters_count - 1
    end

    voted[name] = true
    votes[name] = mapID

    if voters_count == 0 then
        ctf_modebase.map_vote.end_vote()
    end
end

local function show_mapchoose_form(player)
    local elements = {}
    local i = 1

    for idx, mapID in ipairs(map_sample) do
        local image_texture = ctf_modebase.map_catalog.maps[mapID].dirname .. "_screenshot.png"
        local image_path = string.format("%s/textures/%s", minetest.get_modpath("ctf_map"), image_texture)

        if ctf_core.file_exists(image_path) then
            elements["map_image_" .. idx] = {
                type = "image",
                pos = {x = i, y = 1},
                size = {x = 6, y = 4},
                texture = image_texture,
            }
        end

        elements["vote_button_" .. idx] = {
            type = "button",
            exit = true,
            label = ctf_modebase.map_catalog.map_names[mapID],
            pos = {x = i + 1, y = 6},
            size = {x = 4, y = 1},
            func = function(playername, fields, field_name)
                player_vote(playername, mapID)
            end,
        }
        i = i + 7
    end

    elements["quit_button"] = {
        type = "button",
        exit = true,
        label = "Exit Game",
        pos = {x = (i / 2) + 0.5, y = 8},
        size = {x = 3, y = 0.6},
        func = function(playername, fields, field_name)
            minetest.kick_player(playername, "You clicked 'Exit Game' in the map vote formspec")
        end,
    }

    elements["abstain_button"] = {
        type = "button",
        exit = true,
        label = "Abstain",
        pos = {x = (i / 2) - 3.5, y = 8},
        size = {x = 3, y = 0.6},
        func = function(playername, fields, field_name)
            player_vote(playername, nil)
        end,
    }

    ctf_gui.old_show_formspec(player, "ctf_modebase:map_select", {
        size = {x = i, y = 11},
        title = "Vote for the next map",
        description = "Please click on the map that you would like to play next!",
        header_height = 1.4,
        elements = elements,
    })
end

local function send_formspec()
    if not voted then return end
    for pname in pairs(voted) do
        if not voted[pname] then
            show_mapchoose_form(minetest.get_player_by_name(pname))
        end
    end
    formspec_send_timer = minetest.after(2, send_formspec)
end

function ctf_modebase.map_vote.start_vote()
    votes = {}
    voted = {}
    voters_count = 0

    map_sample = ctf_modebase.map_catalog.sample_map_for_mode(ctf_modebase.current_mode, NUM_MAPS_VOTE)

    for _, player in pairs(minetest.get_connected_players()) do
        local pname = player:get_player_name()
        show_mapchoose_form(player)
        voted[pname] = false
        voters_count = voters_count + 1
    end

    timer = minetest.after(VOTING_TIME, ctf_modebase.map_vote.end_vote)
    formspec_send_timer = minetest.after(2, send_formspec)
end

function ctf_modebase.map_vote.end_vote()
    if timer then
        timer:cancel()
        timer = nil
    end
    if formspec_send_timer then
        formspec_send_timer:cancel()
        formspec_send_timer = nil
    end

    for _, player in pairs(minetest.get_connected_players()) do
        minetest.close_formspec(player:get_player_name(), "ctf_modebase:map_select")
    end

    local vote_counts = {}
    for _, mapID in pairs(votes) do
        vote_counts[mapID] = (vote_counts[mapID] or 0) + 1
    end

    votes = nil
    voted = nil

    local max_votes = 0
    for _, count in pairs(vote_counts) do
        if count > max_votes then
            max_votes = count
        end
    end

    local winning_mapIDs = {}
    for mapID, count in pairs(vote_counts) do
        if count == max_votes then
            table.insert(winning_mapIDs, mapID)
        end
    end

    local winning_mapID = nil
    if #winning_mapIDs > 0 then
        winning_mapID = winning_mapIDs[math.random(1, #winning_mapIDs)]
    else
        winning_mapID = map_sample[1]
    end

    -- Record in stats
    vote_history.record(winning_mapID)

    local winner_name = ctf_modebase.map_catalog.map_names[winning_mapID] or tostring(winning_mapID)
    minetest.chat_send_all("Map voting is over. The next map will be " .. winner_name)

    minetest.chat_send_all("Vote results:")
    for _, mapID in pairs(map_sample) do
        local map_name = ctf_modebase.map_catalog.map_names[mapID] or ("Unknown (" .. tostring(mapID) .. ")")
        local count = vote_counts[mapID] or 0
        minetest.chat_send_all(count .. " vote(s) for " .. map_name)
    end

    ctf_modebase.map_catalog.select_map(winning_mapID)
    ctf_modebase.start_match_after_map_vote()
end

minetest.register_on_joinplayer(function(player)
    local pname = player:get_player_name()
    if votes and not voted[pname] then
        show_mapchoose_form(player)
        voted[pname] = false
        voters_count = voters_count + 1
    end
end)

minetest.register_on_leaveplayer(function(player)
    local pname = player:get_player_name()
    if votes and not voted[pname] then
        voters_count = voters_count - 1
        if voters_count == 0 then
            ctf_modebase.map_vote.end_vote()
        end
    end
    if voted then
        voted[pname] = nil
    end
end)
