local VOTING_TIME = 20

local selected = nil
local timer = nil
local formspec_send_timer = nil
local votes = nil
local voted = nil
local voters_count = nil

ctf_modebase.map_vote = {}

local function player_vote(name, mapID)
	if not voted then return end

    print("Player " .. name .. ' Vote' .. mapID)

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


    -- local image_texture = "empty_map_screenshot.png"
    -- --local image_texture = current_map_meta.dirname .. "_screenshot.png"
	-- if ctf_core.file_exists(string.format"%s/textures/%s", minetest.get_modpath("ctf_map"), image_texture)) then
    --     print("Exists image")
    --     elements["map_1"] = {
    --         type = "image",
    --         pos = {x = 0, y = 0},
    --         image_scale = -100,
    --         z_index = 1001,
    --         texture = image_texture
    --         --texture = map.dirname.."_screenshot.png^[opacity:30",
    --     }
    -- end

    local i = 0.4

    -- Create vote buttons dynamically
    for idx, mapID in ipairs(selected) do
        elements["vote_button_" .. idx] = {
            type = "button",
            exit = true,
            label = ctf_modebase.map_catalog.map_names[mapID],
            pos = {x = "center", y = i},
            func = function(playername, fields, field_name)
                player_vote(playername, mapID)
            end,
        }
        i = i + 1
    end
    
    -- Add quit button
    i = i + 1.2
    elements["quit_button"] = {
        type = "button",
        exit = true,
        label = "Exit Game",
        pos = {x = "center", y = i},
        func = function(playername, fields, field_name)
            minetest.kick_player(playername, "You clicked 'Exit Game' in the map vote formspec")
        end,
    }
    i = i + (ctf_gui.ELEM_SIZE.y - 0.2)
    
    ctf_gui.old_show_formspec(player, "ctf_modebase:map_select", {
        size = {x = 8, y = i + 3.5},
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
			show_mapchoose_form(pname)
		end
	end
	formspec_send_timer = minetest.after(2, send_formspec)
end


function ctf_modebase.map_vote.start_vote()
    votes = {}
    voted = {}
    voters_count = 0

    selected = ctf_modebase.map_catalog.sample_map_for_mode(ctf_modebase.current_mode, 3) --select three maps at random

    for _, player in pairs(minetest.get_connected_players()) do
		--if ctf_teams.get(player) ~= nil or not ctf_modebase.current_mode then
		local pname = player:get_player_name()

		show_mapchoose_form(pname)

		voted[pname] = false
		voters_count = voters_count + 1
		--end
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

    local winning_mapID = nil
    local max_votes = 0
    for mapID, count in pairs(vote_counts) do
        if count > max_votes then
            max_votes = count
            winning_mapID = mapID
        end
    end

    local winner_name = ctf_modebase.map_catalog.map_names[winning_mapID] or tostring(winning_mapID)
    minetest.chat_send_all("Map voting is over. The next map will be " .. winner_name)

    minetest.chat_send_all("Vote results:")
    for mapID, count in pairs(vote_counts) do
        local map_name = ctf_modebase.map_catalog.map_names[mapID] or ("Unknown (" .. tostring(mapID) .. ")")
        minetest.chat_send_all(count .." vote(s) for " .. map_name)
    end

    ctf_modebase.map_catalog.select_map(winning_mapID)
    ctf_modebase.start_match_after_map_vote()
end

minetest.register_on_joinplayer(function(player)
	local pname = player:get_player_name()

	if votes and not voted[pname] then
		show_mapchoose_form(pname)
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