--- @alias TeamsOnAllocCallback fun(player: string, team: TeamColour)
--- @type TeamsOnAllocCallback[]
ctf_teams.registered_on_allocplayer = {}
--- @param func TeamsOnAllocCallback
function ctf_teams.register_on_allocplayer(func)
	table.insert(ctf_teams.registered_on_allocplayer, func)
end
