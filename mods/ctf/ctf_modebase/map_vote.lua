local VOTING_TIME = 20
local NUM_MAPS_VOTE = 3

local map_sample = nil
local timer = nil
local formspec_send_timer = nil
local votes = nil
local voted = nil
local voters_count = nil

local S = core.get_translator(core.get_current_modname())
ctf_modebase.map_vote = {}

local function player_vote(name, mapID)
	if not voted then
		return
	end

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

	-- Create vote buttons
	for idx, mapID in ipairs(map_sample) do
		local image_texture = ctf_modebase.map_catalog.maps[mapID].dirname
			.. "_screenshot.png"
		local image_path = string.format(
			"%s/textures/%s",
			core.get_modpath("ctf_map"),
			image_texture
		)

		if ctf_core.file_exists(image_path) then
			elements["map_image_" .. idx] = {
				type = "image",
				pos = { x = i, y = 1 },
				size = { x = 6, y = 4 },
				texture = image_texture,
			}
		end

		elements["vote_button_" .. idx] = {
			type = "button",
			exit = true,
			label = ctf_modebase.map_catalog.map_names[mapID],
			pos = { x = i + 1, y = 6 },
			size = { x = 4, y = 1 },
			func = function(playername, fields, field_name)
				player_vote(playername, mapID)
			end,
		}
		i = i + 7
	end

	-- Add quit button
	elements["quit_button"] = {
		type = "button",
		exit = true,
		label = S("Exit Game"),
		pos = { x = (i / 2) + 0.5, y = 8 },
		size = { x = 3, y = 0.6 },
		func = function(playername, fields, field_name)
			core.kick_player(
				playername,
				S("You clicked 'Exit Game' in the map vote formspec")
			)
		end,
	}

	elements["abstain_button"] = {
		type = "button",
		exit = true,
		label = S("Abstain"),
		pos = { x = (i / 2) - 3.5, y = 8 },
		size = { x = 3, y = 0.6 },
		func = function(playername, fields, field_name)
			player_vote(playername, nil)
		end,
	}

	ctf_gui.old_show_formspec(player, "ctf_modebase:map_select", {
		size = { x = i, y = 11 },
		title = S("Vote for the next map"),
		description = S("Please click on the map that you would like to play next!"),
		header_height = 1.4,
		elements = elements,
	})
end

local function send_formspec()
	if not voted then
		return
	end
	for pname in pairs(voted) do
		if not voted[pname] then
			show_mapchoose_form(pname)
		end
	end
	formspec_send_timer = core.after(2, send_formspec)
end

function ctf_modebase.map_vote.start_vote()
	votes = {}
	voted = {}
	voters_count = 0

	map_sample = ctf_modebase.map_catalog.sample_map_for_mode(
		ctf_modebase.current_mode,
		NUM_MAPS_VOTE
	) --select three maps at random

	for _, player in pairs(core.get_connected_players()) do
		local pname = player:get_player_name()
		if not ctf_teams.non_team_players[pname] then
			show_mapchoose_form(pname)

			voted[pname] = false
			voters_count = voters_count + 1
		end
	end

	timer = core.after(VOTING_TIME, ctf_modebase.map_vote.end_vote)
	formspec_send_timer = core.after(2, send_formspec)
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

	for _, player in pairs(core.get_connected_players()) do
		core.close_formspec(player:get_player_name(), "ctf_modebase:map_select")
	end

	local vote_counts = {}
	for _, mapID in pairs(votes) do
		vote_counts[mapID] = (vote_counts[mapID] or 0) + 1
	end

	votes = nil
	voted = nil

	--find the maximum amount of votes
	local max_votes = 0
	for _, count in pairs(vote_counts) do
		if count > max_votes then
			max_votes = count
		end
	end

	--insert all the joint first in the table
	local winning_mapIDs = {}
	for mapID, count in pairs(vote_counts) do
		if count == max_votes then
			table.insert(winning_mapIDs, mapID)
		end
	end

	local winning_mapID = nil
	if #winning_mapIDs > 0 then
		--determine winner randomly in case of a draw
		local random_index = math.random(1, #winning_mapIDs)
		winning_mapID = winning_mapIDs[random_index]
	else
		--if no votes were cast
		winning_mapID = map_sample[1]
	end

	local winner_name = ctf_modebase.map_catalog.map_names[winning_mapID]
		or tostring(winning_mapID)
	core.chat_send_all(S("Map voting is over. The next map will be @1", winner_name))

	core.chat_send_all(S("Vote results:"))
	for _, mapID in pairs(map_sample) do
		local map_name = ctf_modebase.map_catalog.map_names[mapID]
			or ("Unknown (" .. tostring(mapID) .. ")")
		local count = vote_counts[mapID] or 0
		if count == 1 then
			core.chat_send_all(S("A vote for @1", map_name))
		elseif count == 0 then
			core.chat_send_all(S("No vote for @1", map_name))
		else
			core.chat_send_all(S("@1 votes for @2", count, map_name))
		end
	end

	ctf_modebase.map_catalog.select_map(winning_mapID)
	ctf_modebase.start_match_after_map_vote()
end

core.register_on_joinplayer(function(player)
	local pname = player:get_player_name()

	if votes and not voted[pname] then
		show_mapchoose_form(pname)
		voted[pname] = false
		voters_count = voters_count + 1
	end
end)

core.register_on_leaveplayer(function(player)
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
