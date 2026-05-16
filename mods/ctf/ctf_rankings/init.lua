--- @alias Rank { place: number?, kills: number?, deaths: number?, kill_assists: number?,
--- capture_points: number?, build_points: number, hp_healed: number?, score: number?}

--- @alias RankGetFun fun(pname: PlayerName): Rank
--- @alias RankSetFun fun(pname: PlayerName, newrankings: Rank, erase_unset: boolean?)
--- @alias RankAddFun fun(pname: PlayerName, amount: Rank)
--- @alias RankDelFun fun(pname: PlayerName)
--- @alias OpFun fun(key: string, value: string)
--- @alias RankingBackendType "default" | "redis"

--- @alias RankingBackend { get: RankGetFun, set: RankSetFun, add: RankAddFun,
--- del: RankDelFun, backend: RankingBackendType, prefix: string,
--- op_all: fun(operation: OpFun)}

--- @type RankingBackendType
local backend = core.settings:get("ctf_rankings_backend") or "default"

--- @type fun(prefix: string, top: any): RankingBackend
local rankings
local top = ctf_core.include_files("top.lua")

if backend == "redis" then
	local env = core.request_insecure_environment()
	assert(
		env,
		"Please add 'ctf_rankings' to secure.trusted_mods if you want to use the redis backend"
	)

	local old_require = require

	env.rawset(_G, "require", env.require)
	rankings = env.dofile(env.debug.getinfo(1, "S").source:sub(2, -9) .. "redis.lua")
	env.rawset(_G, "require", old_require)
else
	rankings = ctf_core.include_files(backend .. ".lua")
end

ctf_rankings = {
	--- @return RankingBackend
	init = function()
		return rankings(core.get_current_modname() .. "|", top:new())
	end,

	--- @type (fun(pname: PlayerName, rank: Rank))[]
	registered_on_rank_reset = {},

	--- @type boolean
	do_reset = false, -- See ranking_reset.lua
	--- @type integer
	current_reset = 0, -- See ranking_reset.lua
}

---@param func fun(pname: PlayerName, rank: Rank)
function ctf_rankings.register_on_rank_reset(func)
	table.insert(ctf_rankings.registered_on_rank_reset, func)
end

-- ctf_core.include_files("ranking_reset.lua")
