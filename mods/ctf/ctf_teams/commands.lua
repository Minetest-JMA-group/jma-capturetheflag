local do_set_teams = function(name, player, team)
	if minetest.get_player_by_name(player) then
		if table.indexof(ctf_teams.current_team_list, team) == -1 then
			return false, "No such team: " .. team
		end

		ctf_teams.set(player, team)

		return true, string.format("Allocated %s to team %s", player, team)
	else
		return false, "No such player: " .. player
	end
end

core.register_chatcommand("ctf_teams", {
	description = "Team management commands",
	params = "set <player> <team> | rset <match pattern> <team>",
	privs = {
		ctf_team_admin = true,
	},
	func = function(name, param)
		local iter = param:gmatch("%S+")
		local cmd = iter()
		local player = iter()
		local team = iter()
		if not player or not team or not cmd or not cmd == "set" then
			return false, "Invalid command"
		end
		return do_set_team(name, player, team)
	end
})

local function get_team_players(team)
	local tcolor = ctf_teams.team[team].color
	local count = 0
	local str = ""

	for player in pairs(ctf_teams.online_players[team].players) do
		count = count + 1
		str = str .. player .. ", "
	end

	return string.format("Team %s has %d players: %s", minetest.colorize(tcolor, team), count, str:sub(1, -3))
end

minetest.register_chatcommand("team", {
	description = "Get team members for 'team' or on which team is 'player' in",
	params = "<team> | player <player>",
	func = function(name, param)
		local _, pos = param:find("^player +")
		if pos then
			local player = param:sub(pos + 1)
			local pteam = ctf_teams.get(player)

			if not pteam then
				return false, "No such player: " .. player
			end

			local tcolor = ctf_teams.team[pteam].color
			return true, string.format("%s is in the %s team", player, minetest.colorize(tcolor, pteam))
		elseif param == "" then
			local str = ""
			for _, team in ipairs(ctf_teams.current_team_list) do
				str = str .. "> " .. get_team_players(team) .. "\n"
			end
			return true, str:sub(1, -2)
		else
			if table.indexof(ctf_teams.current_team_list, param) == -1 then
				return false, "No such team: " .. param
			end

			return true, "> " .. get_team_players(param)
		end
	end,
})
