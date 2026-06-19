local VOTING_TIME = 20
local NUM_MAPS_VOTE = 3

local RESHUFFLE = "%RESHUFFLE%"

local map_sample = nil
local timer = nil
local formspec_send_timer = nil
local votes = nil
local voted = nil
local voters_count = nil

--- @type boolean Has a reshuffle happened once during this vote?
local done_reshuffle_once = false

ctf_api.register_on_match_start(function()
	done_reshuffle_once = false
end)

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
	if not map_sample then
		return
	end

	ctf_gui.show_formspec(player, "ctf_modebase:map_select", function(ctx)
		local num_maps = #map_sample
		local form_x = num_maps * 7 + 1
		local form_y = 9.8

		local out = {
			"formspec_version[4]",
			{ "size[%f,%f]", form_x, form_y },
			{
				"hypertext[0.2,0.2;%f,1.4;title;<center><big>%s</big>\n%s</center>]",
				form_x - 0.4,
				core.formspec_escape(S("Vote for the next map")),
				core.formspec_escape(S("Please click on the map that you would like to play next!")),
			},
		}

		-- Background behind images
		table.insert(out, {
			"box[0,1.5;%f,6.2;#232323]",
			form_x,
		})

		for idx, mapID in ipairs(map_sample) do
			local map_info = ctf_modebase.map_catalog.maps[mapID]
			if map_info then
				local image_texture = map_info.dirname
					.. "_screenshot.png"
				local image_path = string.format(
					"%s/textures/%s",
					core.get_modpath("ctf_map"),
					image_texture
				)

				local x_pos = (idx - 1) * 7 + 1
				if ctf_core.file_exists(image_path) then
					table.insert(out, {
						"image[%f,2;6,4;%s]",
						x_pos,
						image_texture,
					})
				end
			end

			local x_pos = (idx - 1) * 7 + 2
			local map_name = ctf_modebase.map_catalog.map_names[mapID]
			table.insert(out, {
				"button_exit[%f,6.3;4,1;vote_%d;%s]",
				x_pos,
				idx,
				core.formspec_escape(map_name),
			})
		end

		-- Compute start_pos using original formula: i/2 adjusted for button count
		-- i after the loop = 1 + num_maps * 7
		local buttons_size_x = 3
		local gap_between_buttons = 0.5
		local i = 1 + num_maps * 7
		local start_pos = i / 2
		if done_reshuffle_once then
			start_pos = start_pos - buttons_size_x - gap_between_buttons
		else
			start_pos = start_pos - 1.5 * buttons_size_x - gap_between_buttons
		end

		table.insert(out, {
			"button_exit[%f,8.5;%f,0.6;quit_button;%s]",
			start_pos,
			buttons_size_x,
			core.formspec_escape(S("Exit Game")),
		})
		start_pos = start_pos + buttons_size_x + gap_between_buttons

		if not done_reshuffle_once then
			table.insert(out, {
				"button_exit[%f,8.5;%f,0.6;reshuffle_button;%s]",
				start_pos,
				buttons_size_x,
				core.formspec_escape(S("Reshuffle")),
			})
			start_pos = start_pos + buttons_size_x + gap_between_buttons
		end

		table.insert(out, {
			"button_exit[%f,8.5;%f,0.6;abstain_button;%s]",
			start_pos,
			buttons_size_x,
			core.formspec_escape(S("Abstain")),
		})

		return ctf_gui.list_to_formspec_str(out)
	end, {
	_on_formspec_input = function(pname, _, fields)
			if fields.quit_button then
				core.kick_player(
					pname,
					S("You clicked 'Exit Game' in the map vote formspec")
				)
				return
			end

			if fields.reshuffle_button then
				player_vote(pname, RESHUFFLE)
				return
			end

			if fields.abstain_button then
				player_vote(pname, nil)
				return
			end

			for field_name in pairs(fields) do
				local idx = field_name:match("^vote_(%d+)$")
				if idx then
					idx = tonumber(idx)
					if idx >= 1 and idx <= #map_sample then
						player_vote(pname, map_sample[idx])
						return
					end
				end
			end
		end,
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
	local reshuffle_votes = 0
	local other_votes = 0
	if votes then
		for _, mapID in pairs(votes) do
			if mapID == RESHUFFLE then
				reshuffle_votes = reshuffle_votes + 1
			else
				vote_counts[mapID] = (vote_counts[mapID] or 0) + 1
				other_votes = other_votes + 1
			end
		end
	end

	votes = nil
	voted = nil
	if (2 * reshuffle_votes) >= other_votes and reshuffle_votes ~= 0 then
		done_reshuffle_once = true
		core.chat_send_all(S("A reshuffle has been requested by majority of players."))
		ctf_modebase.map_vote.start_vote()
		return
	end

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
		if map_sample and #map_sample > 0 then
			winning_mapID = map_sample[1]
		else
			-- Fallback: use first available map
			local all_maps = ctf_modebase.map_catalog.get_maps_for_mode(ctf_modebase.current_mode)
			if all_maps and #all_maps > 0 then
				winning_mapID = all_maps[1]
			else
				-- No maps available at all
				winning_mapID = nil
			end
		end
	end

	local winner_name
	if winning_mapID then
		winner_name = ctf_modebase.map_catalog.map_names[winning_mapID] or tostring(winning_mapID)
	else
		winner_name = "nil"
	end
	core.chat_send_all(S("Map voting is over. The next map will be @1", winner_name))

	if map_sample then
		core.chat_send_all(S("Vote results:"))
	for _, mapID in pairs(map_sample) do
		local map_name = ctf_modebase.map_catalog.map_names[mapID]
			or ("Unknown (" .. tostring(mapID) .. ")")
		local count = vote_counts[mapID] or 0
		if count == 1 then
			core.chat_send_all(S("1 vote for @1", map_name))
		elseif count == 0 then
			core.chat_send_all(S("No vote for @1", map_name))
		else
			core.chat_send_all(S("@1 votes for @2", count, map_name))
		end
	end
	end

	if winning_mapID then
		ctf_modebase.map_catalog.select_map(winning_mapID)
		ctf_modebase.start_match_after_map_vote()
	else
		core.log("error", "map_vote: No map selected for voting")
		core.chat_send_all(S("No map available for voting"))
	end
end

core.register_on_joinplayer(function(player)
	local pname = player:get_player_name()

	if votes and voted and not voted[pname] then
		show_mapchoose_form(pname)
		voted[pname] = false
		voters_count = voters_count + 1
	end
end)

core.register_on_leaveplayer(function(player)
	local pname = player:get_player_name()

	if votes and voted and not voted[pname] then
		voters_count = voters_count - 1

		if voters_count == 0 then
			ctf_modebase.map_vote.end_vote()
		end
	end

	if voted then
		voted[pname] = nil
	end
end)