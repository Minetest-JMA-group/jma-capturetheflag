local backend = minetest.settings:get("ctf_rankings_backend") or "default"

local rankings
local top = ctf_core.include_files("top.lua")

if backend == "redis" then
	local env = minetest.request_insecure_environment()
	assert(env, "Please add 'ctf_rankings' to secure.trusted_mods if you want to use the redis backend")

	local old_require = require

	env.rawset(_G, "require", env.require)
	rankings = env.dofile(env.debug.getinfo(1, "S").source:sub(2, -9) .. "redis.lua")
	env.rawset(_G, "require", old_require)
else
	rankings = ctf_core.include_files(backend..".lua")
end

ctf_rankings = {
	init = function()
		return rankings(minetest.get_current_modname() .. '|', top:new())
	end,

	registered_on_rank_reset = {},

	do_reset = false, -- See ranking_reset.lua
	current_reset = 0, -- See ranking_reset.lua
}

---@param func function
--- * pname
--- * rank
function ctf_rankings.register_on_rank_reset(func)
	table.insert(ctf_rankings.registered_on_rank_reset, func)
end

-- ctf_core.include_files("ranking_reset.lua")
