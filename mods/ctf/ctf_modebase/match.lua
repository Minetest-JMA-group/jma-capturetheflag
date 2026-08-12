--- @type false | string
ctf_modebase.restart_on_next_match = false -- used by server_restart mod to restart after a match

ctf_modebase.map_on_next_match = nil
ctf_modebase.mode_on_next_match = nil

local S = core.get_translator(core.get_current_modname())

-- Overridable
---@diagnostic disable-next-line: duplicate-set-field
function ctf_modebase.map_chosen(map) end

function ctf_modebase.start_match_after_mode_vote()
	local old_mode = ctf_modebase.current_mode

	if ctf_modebase.mode_on_next_match ~= old_mode then
		ctf_modebase.on_mode_end()
		ctf_modebase.current_mode = ctf_modebase.mode_on_next_match
		ctf_modebase.on_mode_start()
	end
	ctf_modebase.mode_on_next_match = nil

	if ctf_modebase.map_on_next_match then
		ctf_modebase.map_catalog.current_map =
			ctf_modebase.map_catalog.map_dirnames[ctf_modebase.map_on_next_match]
		ctf_modebase.map_on_next_match = nil
		ctf_modebase.start_match_after_map_vote()
	else
		ctf_modebase.map_vote.start_vote()
	end
end

if experiment_logs then
	experiment_logs.register_new_experiment(
		"new_team_alloc",
		S("New team allocation algorithm based on value of each player"),
		S(
			"In the new algorithm, the game tries to allocate players such that 'sum value'"
		)
			.. "\n"
			.. S(
				"of teams do not differ significantly. Note that the 'sum' used might not be just"
			)
			.. "\n"
			.. S(
				"normal addition. Because when 2 players are combined, the influence is bigger"
			)
			.. "\n"
			.. S("than when each of them work alone")
	)
end

function ctf_modebase.start_match_after_map_vote()
	ctf_modebase.show_loading_screen()
	local map = ctf_modebase.map_catalog.maps[ctf_modebase.map_catalog.current_map]
	ctf_modebase.map_chosen(map)
	ctf_map.place_map(map, function()
		-- Set time and time_speed
		core.set_timeofday(map.start_time / 24000)
		core.settings:set("time_speed", map.time_speed * 72)

		ctf_map.announce_map(map)
		ctf_map.set_current_mode(ctf_modebase.current_mode)
		ctf_modebase.announce(
			string.format(
				"New match: %s map by %s, %s mode",
				map.name,
				map.author,
				HumanReadable(ctf_modebase.current_mode)
			)
		)

		ctf_modebase.on_new_match()

		ctf_modebase.in_game = true

		local current_map = ctf_map.current_map
		local current_mode = ctf_modebase.current_mode
		if not current_map then
			return
		end

		--- @alias PlayerValue { pname: PlayerName, val: number }
		--- @type PlayerValue[][] Each slot is an array for a team
		local allocation = {}
		local i = 1
		for team, _ in pairs(current_map.teams) do
			allocation[i] = {}
			i = i + 1
		end

		--- @type { [PlayerName]: boolean }
		local players_to_assign = {}
		--- @type integer
		local players_num = 0
		for _, player in ipairs(core.get_connected_players()) do
			local pname = player:get_player_name()
			if pname ~= "" and not ctf_teams.non_team_players[pname] then
				players_to_assign[pname] = true
				players_num = players_num + 1
			end
		end

		local get_player_value = ctf_modebase.values.get_player_value
		-- Now assign players equally per teams
		local t = 1
		for pname, _ in pairs(players_to_assign) do
			--- @type PlayerValue
			local v = {
				pname = pname,
				val = get_player_value(pname, 0.0),
			}
			table.insert(allocation[(t % #allocation) + 1], v)
			t = t + 1
		end

		--- A team's value equals to product
		--- of values of all its players
		--- @param team PlayerValue[]
		--- @return number
		local function get_team_value(team)
			local val = 1
			for _, p_val in ipairs(team) do
				val = val * p_val.val
			end
			return val
		end

		--- Compute differece between teams
		--- @param allocation2 PlayerValue[][]
		--- @return number
		local function get_teams_difference(allocation2)
			--- @type number
			local difference = 0
			--- @type number[]
			local team_vals = {}
			for index, team in ipairs(allocation2) do
				team_vals[index] = get_team_value(team)
			end
			for index = 1, #team_vals - 1 do
				local this_val = team_vals[index]
				local next_val = team_vals[index + 1]
				difference = difference + math.abs(this_val - next_val)
			end
			return difference
		end

		--- @type integer
		local assigned_players_before = 0
		for _, alloc in ipairs(allocation) do
			assigned_players_before = assigned_players_before + #alloc
		end
		-- Now, we've got an optimization problem. We've got
		-- many "buckets" and we are supposed to minimize
		-- "team_value" difference between teams.
		-- This is called Backpack problem. Here instead of
		-- solving this problem directly, we use
		-- Simulated Annealing to optimize it. I've got
		-- two reasons for this. First, I believe directly solving
		-- the problem will be slow. Second, I think it'll be
		-- also harder to implement it in Lua. --Farooq
		local temperature = 10
		local step = 0.5
		-- There is nothing to do if there aren't enough players
		-- to allocate...
		if #ctf_teams.get_all_team_players() <= #allocation then
			temperature = -1
		end
		while temperature > 0 do
			if #ctf_teams.get_all_team_players() <= 2 then
				break
			end
			--- @type integer
			local team_a_index = math.random(#allocation)
			--- @type integer
			local team_b_index = math.random(#allocation)
			if team_a_index ~= team_b_index then
				--- @type number
				local current_difference = get_teams_difference(allocation)
				--- @type PlayerValue[][]
				local new_allocation = table.copy(allocation)
				local team_a_len = #new_allocation[team_a_index]
				local team_b_len = #new_allocation[team_b_index]
				-- There is 10% chance we would remove a player
				-- from one team and add to another one
				if math.random() < 0.1 then
					--- @type PlayerValue
					local player_val = table.remove(
						new_allocation[team_a_index],
						math.random(team_a_len)
					)
					table.insert(new_allocation[team_b_index], player_val)
				else
					--- @type integer
					local player_val_a_index = math.random(team_a_len)
					--- @type integer
					local player_val_b_index = math.random(team_b_len)
					--- @type PlayerValue
					local player_val_a = new_allocation[team_a_index][player_val_a_index]
					--- @type PlayerValue
					local player_val_b = new_allocation[team_b_index][player_val_b_index]
					-- Swap the two players between the teams by writing back
					-- into the allocation (previously only locals were
					-- reassigned, making this branch a no-op).
					new_allocation[team_a_index][player_val_a_index] = table.copy(player_val_b)
					new_allocation[team_b_index][player_val_b_index] = table.copy(player_val_a)
				end
				--- @type number
				local new_difference = get_teams_difference(new_allocation)
				-- As in accord with SA, if the new combination is better than the old one
				-- just pick the new one.
				if new_difference - current_difference < 0 then
					allocation = new_allocation
					core.debug(
						string.format("Team allocation new diff: %f", new_difference)
					)
				else
					-- if the new allocation is worse, there still will be a small
					-- chance that it'll be picked. The chance depends on the
					-- current temperature as well as how much worse the new
					-- one is.
					local diff = math.abs(new_difference - current_difference)
					if math.random() >= math.exp(-diff / temperature) then
						allocation = new_allocation
						core.log(
							"info",
							string.format("Team allocation new diff: %f", new_difference)
						)
					end
				end
				temperature = temperature - step
				--- We consider a difference of 0.5 or smaller
				--- as negligible
				if new_difference < 0.5 then
					break
				end
			end
		end

		--- @type integer
		local assigned_players_after = 0
		for _, alloc in ipairs(allocation) do
			assigned_players_after = assigned_players_after + #alloc
		end

		if assigned_players_after ~= assigned_players_before then
			core.log("error", "Inconsistentency in assigning players to teams")
		end

		core.log(
			"info",
			"The new team allocation algorithm result: " .. core.serialize(allocation)
		)

		if experiment_logs then
			--- @type integer
			local assigned_players = 0
			-- Now we announce it to the chat. Let's receive comments
			-- and feedback from the player
			--- @type string[]
			local teams_str = {}
			for index, team in ipairs(allocation) do
				if teams_str[index] == nil then
					teams_str[index] = string.format("Team %d: ", index)
				end
				for _, p_val in ipairs(team) do
					teams_str[index] = teams_str[index] .. " " .. p_val.pname
					assigned_players = assigned_players + 1
				end
			end
			local final_str = ""
			for _, str in ipairs(teams_str) do
				final_str = final_str .. str .. "\n"
			end
			local prefix = ""
			if assigned_players ~= players_num then
				prefix = string.format("[a%d,to-a%d] ", assigned_players, players_num)
				core.log(
					"error",
					"[NEW TEAM ALLOC] assigned players and players to assign are not equal: "
						.. prefix
				)
			end
			experiment_logs.log(
				"new_team_alloc",
				prefix .. "New allocation would've been:\n" .. final_str,
				"|team_players|"
			)
		end

		ctf_teams.allocate_teams(ctf_map.current_map.teams)

		ctf_modebase.current_mode_matches_played = ctf_modebase.current_mode_matches_played
			+ 1

		if table.indexof(current_map.game_modes, current_mode) == -1 then
			local concat =
				"The current mode is not in the list of modes supported by the current map."
			local cmd_text = string.format(
				"/ctf_next -f [mode:technical modename] %s",
				current_map.dirname
			)
			local msg = core.colorize(
				"red",
				string.format(
					"%s\nSupported mode(s): %s. To switch to a mode set for the map, do %s",
					concat,
					table.concat(current_map.game_modes, ", "),
					cmd_text
				)
			)
			if chat_lib and chat_lib.send_message_to_privileged then
				chat_lib.send_message_to_privileged(msg, { "ctf_admin", "server" })
			end
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
	elseif
		ctf_modebase.current_mode_matches_played >= ctf_modebase.current_mode_matches
		or not ctf_modebase.current_mode
	then
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
		core.after(delay, start_new_match)
	else
		start_new_match()
	end
end

core.register_chatcommand("ctf_next", {
	description = "Set a new map and mode",
	privs = { ctf_admin = true },
	params = "[-f] [mode:technical modename] [technical mapname]",
	func = function(name, param)
		core.log("action", string.format("[ctf_admin] %s ran /ctf_next %s", name, param))

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

core.register_chatcommand("ctf_skip", {
	description = "Skip to a new match",
	privs = { ctf_admin = true },
	func = function(name, param)
		core.log("action", string.format("[ctf_admin] %s ran /ctf_skip", name))

		if not ctf_modebase.in_game then
			return false, "Map switching is in progress"
		end

		ctf_modebase.start_new_match()

		return true, "Skipping match..."
	end,
})
