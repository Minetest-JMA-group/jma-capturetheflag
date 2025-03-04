--[[
 * Copyright (c) 2023 Nanowolf4 (n4w@tutanota.com)
 * SPDX-License-Identifier: GPL-3.0-or-later
-]]

local handlers = {}
local match_started = false
local mt_ustime = minetest.get_us_time
local abs = math.abs
local storage = minetest.get_mod_storage()

local allowed_interval = 0.1 * 1000000

if storage:contains("interval") then
	allowed_interval = storage:get_float("interval")
	minetest.log("action", "Node placement interval is " .. allowed_interval)
end

local function create_antifastplacing_handler(player)
	local self = {
		last_placing_time = mt_ustime() or 0,
		blocked = 0
	}

	self.on_place_node = function(pos, oldnode)
		local current_time = mt_ustime()
		if not current_time then return end
		local diff_time = abs(self.last_placing_time - current_time)
		if allowed_interval > diff_time then
			self.blocked = self.blocked + 1
			minetest.log("action",
			string.format("%s placing nodes too fast: %0.3f, blocked: %d times", player:get_player_name(), diff_time / 1000000, self.blocked))
			minetest.set_node(pos, oldnode)
			return true
		end
		self.last_placing_time = current_time
	end

	return self
end

minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
	local h = handlers[placer:get_player_name()]
	if not h then return end
	return h.on_place_node(pos, oldnode)
end)

local function run_handler(player)
	local name = player:get_player_name()
	local key = "ignore:" .. name
	if storage:contains(key) and storage:get_int(key) == 1 then
		return
	end

	if not handlers[name] then
		handlers[name] = create_antifastplacing_handler(player)
	end
end

ctf_api.register_on_new_match(function()
	match_started = true
	for _, p in ipairs(minetest.get_connected_players()) do
		run_handler(p)
	end
end)

ctf_api.register_on_match_end(function()
	match_started = false
	for _, p in ipairs(minetest.get_connected_players()) do
		local name = p:get_player_name()
		if handlers[name] then
			handlers[name] = nil
		end
	end
end)

minetest.register_on_joinplayer(function(player)
	if match_started then
		run_handler(player)
	end
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	if handlers[name] then
		handlers[name] = nil
	end
end)

minetest.register_chatcommand("afp_print",{
	description = "Print AFP statiscs",
	privs = {dev = true},
	params = "",
	func = function(name, param)
		local output = {}
		for _, p in ipairs(minetest.get_connected_players()) do
			local pn = p:get_player_name()
			local h = handlers[pn]
			if h then
				table.insert(output, string.format("%s, blocked: %d", pn, h.blocked))
			end
		end
		return true, table.concat(output, "\n")
	end
})

minetest.register_chatcommand("afp_interval",{
	description = "Set placement interval",
	privs = {dev = true},
	params = "<get|set> [interval]",
	func = function(name, param)
		local args = param:split(" ")
		local action = args[1]
		if not action then
			return false, "Invalid usage. Add 'get' or 'set' as first argument"
		end

		if action == "get" then
			return true, "Current interval: " .. allowed_interval / 1000000 -- convert to seconds
		elseif action == "set" then
			local interval = tonumber(args[2])
			if not interval then
				return false, "Missing or invalid interval"
			end
			allowed_interval = interval * 1000000 -- convert to microseconds
			storage:set_float("interval", allowed_interval)

			minetest.log("action", "[AFP]: " .. name .. " set node placement interval to " .. interval)
			return true, "Interval set to " .. interval
		end
		return false, "Invalid usage"
	end
})

minetest.register_chatcommand("afp_ignore",{
	description = "",
	privs = {dev = true},
	params = "<name> <add|remove>",
	func = function(_, param)
		local args = param:split(" ")
		local target_name = args[2]
		if not target_name then
			return false, "Missing player name"
		end
		local operation = args[1]
		if not operation then
			return false, "Invalid usage"
		end
		if minetest.player_exists(target_name) then
			if operation == "add" then
				storage:set_int("ignore:" .. target_name, 1)
				return true, "Player added"
			elseif operation == "remove" then
				storage:set_int("ignore:" .. target_name, 0)
				return true, "Player removed"
			end
			return false, "Invalid usage (<name> <add|remove>)"
		else
			return false, "Player does not exist"
		end
	end
})