--- @alias TeamsOnAllocCallback fun(player: PlayerName, team: Team)
--- @type TeamsOnAllocCallback[]
ctf_teams.registered_on_allocplayer = {}
--- @alias TeamChestCallback fun(player: PlayerName, team: Team)
--- @type TeamChestCallback[]
ctf_teams.registered_on_open_teamchest = {}
--- @type TeamChestCallback[]
ctf_teams.registered_on_close_teamchest = {}

--- @param func TeamsOnAllocCallback
function ctf_teams.register_on_allocplayer(func)
	table.insert(ctf_teams.registered_on_allocplayer, func)
end

--- @param func TeamChestCallback
function ctf_teams.register_on_open_teamchest(func)
	table.insert(ctf_teams.registered_on_open_teamchest, func)
end

--- @param func TeamChestCallback
function ctf_teams.register_on_close_teamchest(func)
	table.insert(ctf_teams.registered_on_close_teamchest, func)
end
