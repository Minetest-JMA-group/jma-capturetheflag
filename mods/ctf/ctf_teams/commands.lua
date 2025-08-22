local S = core.get_translator(core.get_current_modname())

local do_set_team =
	--- @param name  PlayerName
	--- @param player PlayerName | ObjectRef
	--- @param team Team
	--- @return boolean, string
	function(name, player, team)
		if core.get_player_by_name(player) then
			if table.indexof(ctf_teams.current_team_list, team) == -1 then
				return false, S("No such team: @1", team)
			end

			ctf_teams.set(player, team)

			return true, S("Allocated @1 to team @2", player, team)
		else
			return false, S("No such player: @1", player)
		end
	end

core.register_chatcommand("ctf_teams", {
	description = S("Team management commands"),
	params = "set <player> <team> | rset <match pattern> <team>",
	privs = {
		ctf_team_admin = true,
	},
	--- @param name PlayerName
	--- @param param string
	--- @return boolean, string
	func = function(name, param)
		local iter = param:gmatch("%S+")
		local cmd = iter()
		local player = iter()
		local team = iter()
		if not player or not team or not cmd or cmd ~= "set" then
			return false, S("Invalid command")
		end
		return do_set_team(name, player, team)
	end,
})

--- @param team Team
--- @return string
local function get_team_players(team)
	local tcolor = ctf_teams.team[team].color
	local count = 0
	local str = ""

	for player in pairs(ctf_teams.online_players[team].players) do
		count = count + 1
		str = str .. player .. ", "
	end

	return S(
		"Team @1 has @2 players: @3",
		core.colorize(tcolor, team),
		count,
		str:sub(1, -3)
	)
end

minetest.register_chatcommand("team", {
	description = S("Get team members for 'team' or on which team is 'player' in"),
	params = "<team> | player <player>",
	func = function(name, param)
		local _, pos = param:find("^player +")
		if pos then
			local player = param:sub(pos + 1)
			local pteam = ctf_teams.get(player)

			if not pteam then
				return false, S("No such player: @1", player)
			end

			local tcolor = ctf_teams.team[pteam].color
			return true,
				S("@1 is in the @2 team", player, minetest.colorize(tcolor, pteam))
		elseif param == "" then
			local str = ""
			for _, team in ipairs(ctf_teams.current_team_list) do
				str = str .. "> " .. get_team_players(team) .. "\n"
			end
			return true, str:sub(1, -2)
		else
			if table.indexof(ctf_teams.current_team_list, param) == -1 then
				return false, S("No such team: @2", param)
			end

			return true, "> " .. get_team_players(param)
		end
	end,
})
