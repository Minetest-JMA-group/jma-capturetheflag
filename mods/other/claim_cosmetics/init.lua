-- SPDX-License-Identifier: GPL-3.0-or-later
-- Copyright (c) 2026 Marko Petrović

local storage = core.get_mod_storage()
local modname = core.get_current_modname()
local claim_timeout = storage:get_int("claim_timeout")

local function merger(data1, data2)
	local last1 = tonumber(data1.last_claim or 0)
	local last2 = tonumber(data2.last_claim or 0)
	return { last_claim = tostring(math.max(last1, last2)) }
end

local mod_storage = ipdb.get_mod_storage(merger)
if not mod_storage then
	error("[claim_cosmetics] Failed to initialize ipdb mod storage")
end

local function is_ipv4(str)
	return str:match("^%d+%.%d+%.%d+%.%d+$") ~= nil
end

local cosmetics_func = core.registered_chatcommands["cosmetics"] and core.registered_chatcommands["cosmetics"].func
assert(cosmetics_func, "[claim_cosmetics]: Cannot load cosmetics command")

core.register_chatcommand("claim", {
	description = "Claim crown and sunglasses as a reward for joining JMA Discord server",
	func = function(name, params)
		if core.get_player_by_name(name) then
			core.chat_send_player(name, core.colorize("red", "You have to run this command from Discord while being offline in-game."))
			return false, "JMA Discord Invite Link: https://discord.gg/SSd9XcCqZk"
		end

		local ctx = mod_storage:get_context_by_name(name)
		if not ctx then
			return false, "You must join the server at least once before using /claim."
		end

		local last_claim_str = ctx:get_string("last_claim")
		local last_claim = tonumber(last_claim_str) or 0
		local curtime = os.time()
		local passed_time = curtime - last_claim

		if passed_time < claim_timeout then
			ctx:finalize()
			return false, "You have to wait " .. algorithms.time_to_string(claim_timeout - passed_time) .. " before next claim"
		end

		ctx:set_string("last_claim", tostring(curtime))
		ctx:finalize()

		cosmetics_func(name, "give " .. name .. " server_cosmetics:headwear:sunglasses:black")
		cosmetics_func(name, "give " .. name .. " server_cosmetics:entity:crown:normal")

		return true, "You have claimed cosmetics items. Check cosmetics tab in your inventory."
	end,
})

core.register_chatcommand("claim_timeout", {
	description = "Set timeout for claim command",
	privs = { cosmetic_manager = true },
	params = "<timeout_time>",
	func = function(name, param)
		local unix_time = algorithms.parse_time(param)
		if not unix_time then
			core.chat_send_player(name, "Current timeout is " .. tostring(claim_timeout))
			return false, "You have to enter a valid number to change it."
		end
		claim_timeout = unix_time
		storage:set_int("claim_timeout", unix_time)
		return true, "claim_timeout set to " .. param
	end,
})

core.register_chatcommand("claim_migrate", {
	description = "Migrate claim data from xban to ipdb",
	privs = { dev = true },
	func = function(name, param)
		if not xban or not xban.db then
			return false, "xban mod not loaded or no database found"
		end

		local id_map = {}
		local sample_id = {}

		for _, entry in ipairs(xban.db) do
			local moddata = entry["modstorage:claim_cosmetics"]
			if moddata and moddata.last_claim then
				local last_claim = tonumber(moddata.last_claim)
				if last_claim then
					local first_key = next(entry.names)
					if first_key then
						local ctx
						if is_ipv4(first_key) then
							ctx = mod_storage:get_context_by_ip(first_key)
						else
							ctx = mod_storage:get_context_by_name(first_key)
						end

						if ctx then
							local uid = ctx._userentry_id
							id_map[uid] = math.max(id_map[uid] or 0, last_claim)
							if not sample_id[uid] then
								sample_id[uid] = first_key
							end
							ctx:finalize()
						else
							core.log("warning", "[claim_cosmetics] No ipdb entry for " .. first_key .. " during migration, skipping.")
						end
					end
				end
			end
		end

		local count = 0
		for uid, max_claim in pairs(id_map) do
			local ident = sample_id[uid]
			if ident then
				local ctx
				if is_ipv4(ident) then
					ctx = mod_storage:get_context_by_ip(ident)
				else
					ctx = mod_storage:get_context_by_name(ident)
				end
				if ctx then
					ctx:set_string("last_claim", tostring(max_claim))
					ctx:finalize()
					count = count + 1
				end
			end
		end

		return true, string.format("Migrated %d entries from xban to ipdb", count)
	end,
})
