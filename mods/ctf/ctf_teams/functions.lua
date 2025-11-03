--
--- Team set/get
--

--- @param player PlayerName | ObjectRef
--- @return nil
function ctf_teams.remove_online_player(player)
	player = PlayerName(player)

	--- @type Team?
	local team = ctf_teams.player_team[player]
	if team then
		if ctf_teams.online_players[team].players[player] then
			ctf_teams.online_players[team].players[player] = nil
			ctf_teams.online_players[team].count = ctf_teams.online_players[team].count
				- 1
		end
	end
end

--- Change/Set some player's team, optionally forcefully
--- @param player PlayerName | ObjectRef
--- @param new_team Team?
--- @param force boolean?
--- @return nil
function ctf_teams.set(player, new_team, force)
	--- @type string
	player = PlayerName(player)

	if not new_team then
		ctf_teams.player_team[player] = nil
		return
	end

	ctf_teams.non_team_players[player] = nil

	assert(type(new_team) == "string")

	--- @type Team?
	local old_team = ctf_teams.player_team[player]
	if not force and old_team == new_team then
		return
	end

	ctf_teams.remove_online_player(player)

	ctf_teams.player_team[player] = new_team
	--- @type TeamPlayerStatus
	local team_status = ctf_teams.online_players[new_team]
	team_status.players[player] = true

	team_status.count = team_status.count + 1

	RunCallbacks(
		ctf_teams.registered_on_allocplayer,
		PlayerObj(player),
		new_team,
		old_team
	)
end

--- Which team is the player on if any?
--- @param player PlayerName | ObjectRef
--- @return Team?
function ctf_teams.get(player)
	--- @type PlayerName
	player = PlayerName(player)

	return ctf_teams.player_team[player]
end

--
--- Allocation
--

local tpos = 1
--- @param player ObjectRef | PlayerName
--- @return Team?
function ctf_teams.default_team_allocator(player)
	if #ctf_teams.current_team_list <= 0 then
		return
	end -- No teams initialized yet
	player = PlayerName(player)

	if ctf_teams.player_team[player] then
		return ctf_teams.player_team[player]
	end

	local team = ctf_teams.current_team_list[tpos]

	if tpos >= #ctf_teams.current_team_list then
		tpos = 1
	else
		tpos = tpos + 1
	end

	return team
end
ctf_teams.team_allocator = ctf_teams.default_team_allocator

--- @param player PlayerName | ObjectRef
--- @param force boolean? [optional]
--- @return Team?
function ctf_teams.allocate_player(player, force)
	player = PlayerName(player)
	local team = ctf_teams.team_allocator(player)

	ctf_teams.set(player, team, force)

	return team
end

--- @param teams TeamsMap
--- @return nil
function ctf_teams.allocate_teams(teams)
	ctf_teams.player_team = {}
	ctf_teams.online_players = {}
	ctf_teams.current_team_list = {}
	tpos = 1

	for teamname, _ in pairs(teams) do
		ctf_teams.online_players[teamname] = { count = 0, players = {} }
		table.insert(ctf_teams.current_team_list, teamname)
	end

	local players = core.get_connected_players()
	table.shuffle(players)
	for _, player in ipairs(players) do
		if not ctf_teams.non_team_players[player:get_player_name()] then
			ctf_teams.allocate_player(player, false)
		end
	end
end

--
--- Other
--

--- Returns 'nil' if there is no current map.
---
--- Example usage: `pos1, pos2 = ctf_teams.get_team_territory("red")`
--- @param teamname Team
--- @return table?, table?
function ctf_teams.get_team_territory(teamname)
	local current_map = ctf_map.current_map
	if not current_map then
		return
	end

	return current_map.teams[teamname].pos1, current_map.teams[teamname].pos2
end

--- Like `core.chat_send_player()` but sends to all members of the given team
--- @param teamname Team Name of team
--- @param message string message to send
--- @return nil
function ctf_teams.chat_send_team(teamname, message)
	assert(teamname and message, "Incorrect usage of chat_send_team()")

	for player in pairs(ctf_teams.online_players[teamname].players) do
		core.chat_send_player(player, message)
	end
end

--- Returns a list of all team-assigned online players
--- @return PlayerName[]
function ctf_teams.get_all_team_players()
	local result = {}

	for _, t in pairs(ctf_teams.online_players) do
		for pn in pairs(t.players) do
			table.insert(result, pn)
		end
	end

	return result
end
