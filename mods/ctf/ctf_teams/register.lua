--- @alias TeamsOnAllocCallback fun(player: PlayerRef, team: Team, old_team: Team?, force: boolean?, team_unchanged: boolean)
--- @alias TeamsOnRemoveOnlinePlayerCallback fun(player: PlayerRef, team: Team?)

--- @type TeamsOnAllocCallback[]
ctf_teams.registered_on_allocplayer = {}
--- @param func TeamsOnAllocCallback
function ctf_teams.register_on_allocplayer(func)
	table.insert(ctf_teams.registered_on_allocplayer, func)
end

--- @type TeamsOnRemoveOnlinePlayerCallback[]
ctf_teams.registered_on_online_player_remove = {}
--- @param func TeamsOnRemoveOnlinePlayerCallback
function ctf_teams.register_on_online_player_remove(func)
	table.insert(ctf_teams.registered_on_online_player_remove, func)
end
