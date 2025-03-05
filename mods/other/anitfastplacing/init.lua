-- * Copyright (c) 2025 Nanowolf4 (n4w@tutanota.com)
-- * SPDX-License-Identifier: GPL-3.0-or-later

antifastplacing = {}

local player_contexts = {}
local mt_ustime = minetest.get_us_time
local abs = math.abs
local storage = minetest.get_mod_storage()
local callbacks = {}

local allowed_interval = 0.1 * 1000000

if storage:contains("interval") then
	allowed_interval = storage:get_float("interval")
	minetest.log("action", "Node placement interval is " .. allowed_interval)
end

local log_cooldown = 1 * 1000000 -- log once per second
local last_log_time = {}

-- Register a callback to be called when a player places nodes too fast.
-- Callbacks should return true if they handled the event otherwise the default behaviour will be applied.
-- Will be called in order of priority, higher priority first.
function antifastplacing.register_on_fastplace(func, priority, target)
	assert(type(func) == "function", "Callback must be a function")
	table.insert(callbacks, {func = func, priority = priority or 0, target = target})
	table.sort(callbacks, function(a, b) return a.priority > b.priority end)
end

local function on_place_node(pos, newnode, oldnode, player)
	local name = player:get_player_name()
	local current_time = mt_ustime()
	if not current_time then return end

	local context = player_contexts[name]
	if not context then
		context = {
			last_placing_time = current_time,
			triggered = 0,
			interval = allowed_interval
		}
		player_contexts[name] = context
	end

	local diff_time = abs(current_time - context.last_placing_time)
	if diff_time < context.interval then
		context.triggered = context.triggered + 1
		context.last_diff_time = diff_time

		if not last_log_time[name] or abs(current_time - last_log_time[name]) > log_cooldown then
			last_log_time[name] = current_time
			minetest.log("action",
			string.format("%s placing nodes too fast: %0.3f, triggered: %d times", name, diff_time / 1000000, context.triggered))
		end

		-- Run callbacks
		local is_handled = false
		for _, callback in ipairs(callbacks) do
			if callback.func(context, player, pos, newnode, oldnode) then
				is_handled = true
			end
		end

		-- Do default behaviour
		if not is_handled then
			minetest.set_node(pos, oldnode)
		end

		return true
	end
	context.last_placing_time = current_time
end

minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
	return on_place_node(pos, newnode, oldnode, placer)
end)

function antifastplacing.start_tracking(player)
	local name = player:get_player_name()
	local key = "ignore:" .. name
	if storage:contains(key) and storage:get_int(key) == 1 then
		return false
	end

	if not player_contexts[name] then
		player_contexts[name] = {
			last_placing_time = mt_ustime(),
			triggered = 0,
			interval = allowed_interval,
			last_diff_time = 0
		}
		return true
	end
end

function antifastplacing.stop_tracking(name)
	if not player_contexts[name] then
		return false
	end

	if last_log_time[name] then
		last_log_time[name] = nil
	end

	player_contexts[name] = nil
	return true
end

minetest.register_on_joinplayer(function(player)
	antifastplacing.start_tracking(player)
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	antifastplacing.stop_tracking(name)
end)

minetest.register_chatcommand("afp_print",{
	description = "Print AFP statistics",
	privs = {dev = true},
	params = "[target]",
	func = function(name, param)
		local target = param:trim()
		local output = {"AFP Statistics:"}
		table.insert(output, "-------------------")

		local function add_context_to_output(pn, context)
			table.insert(output, string.format("Player: %s\n  triggered: %d times\n  Last Placing Time: %d\n  Interval: %0.3f seconds",
				pn, context.triggered, context.last_placing_time, context.interval / 1000000))
			table.insert(output, "-------------------")
		end

		if target == "" then
			for _, p in ipairs(minetest.get_connected_players()) do
				local pn = p:get_player_name()
				local context = player_contexts[pn]
				if context then
					add_context_to_output(pn, context)
				end
			end
		else
			local context = player_contexts[target]
			if context then
				add_context_to_output(target, context)
			else
				return false, "Player context not found"
			end
		end
		return true, table.concat(output, "\n")
	end
})

minetest.register_chatcommand("afp_interval",{
	description = "Set placement interval",
	privs = {server = true},
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
	privs = {server = true},
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

minetest.register_chatcommand("afp_temp_interval", {
	description = "Set temporary placement interval for a player",
	privs = {moderator = true},
	params = "<name> <interval>",
	func = function(name, param)
		local args = param:split(" ")
		local target_name = args[1]
		local interval = tonumber(args[2])
		if not target_name or not interval then
			return false, "Invalid usage. Use: /afp_temp_interval <name> <interval>"
		end
		if minetest.player_exists(target_name) then
			local context = player_contexts[target_name]
			if context then
				context.interval = interval * 1000000 -- convert to microseconds
				return true, "Temporary interval set for " .. target_name
			else
				return false, "Player context not found"
			end
		else
			return false, "Player does not exist"
		end
	end
})