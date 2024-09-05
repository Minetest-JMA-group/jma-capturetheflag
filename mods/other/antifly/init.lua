-- * Copyright (c) 2024 Nanowolf4 (n4w@tutanota.com)
-- * SPDX-License-Identifier: GPL-3.0-or-later


local handlers = {}
local match_started = false
local blacklist = {}
-- local blacklist = {Nanowolf4 = true} -- Added myself to make easier debugging

local vecnew = vector.new
local mt_nodes = minetest.registered_nodes
local mt_getnode = minetest.get_node

local max_score = 2.4
local scan_interval = 0.3
local on_surface_cost = -0.05

local function isAir(pos)
	return mt_getnode(pos).name == "air"
end

local function isClimbable(pos)
	local node = mt_getnode(pos)
	local node_def = mt_nodes[node.name]
 	return node_def.climbable
end

local function isWalkable(pos)
	local node = mt_getnode(pos)
	local node_def = mt_nodes[node.name]
	if node_def.walkable or isClimbable(pos) or node_def.liquidtype ~= "none" then -- consider liquids as a surface
		return true
	end
	return false
end

local function is_on_surface(pos)
	if isWalkable(pos) or isWalkable(vecnew(pos.x, pos.y - 1, pos.z)) then
		return true
	end

	for dx = -1, 1 do
		for dz = -1, 1 do
			local neighbor_underfeet = vecnew(pos.x + dx, pos.y, pos.z + dz)
			local top = vecnew(pos.x + dx, pos.y + 1, pos.z + dz)
			if isWalkable(neighbor_underfeet) and isAir(top) or isClimbable(top) then
				return true
			end
		end
	end

	return false
end

local function compare_ints_tolerance(arr, tolerance)
	if #arr < 2 then
		return false
	end

	for i = 2, #arr do
		if math.abs(arr[i - 1] - arr[i]) > tolerance then
			return false
		end
	end
	return true
end

local function new_antifly_handler(player)
	local name = player:get_player_name()
	local pos = player:get_pos()
	local collbox = player:get_properties().collisionbox
	local checker = {
		old_pos = pos,
		old_vel = player:get_velocity(),
		score = 0,
		triggered = 0,
		old_pos_on_surface = pos,
		speed_history = {},
		speed_history_index = 1
	}

	local function tp_to_surface()
		local function do_tp(p)
			if checker.after_tp_pos and vector.distance(checker.after_tp_pos, player:get_pos()) <= 0.2 then
				minetest.kick_player(name, "An error occurred! Please reconnect to the server")
				minetest.log("warning", string.format("AntiFly: Failed to teleport player %s to stable position, kicked", name))
				return
			end
			local new_pos = vector.offset(p, 0, (collbox[2] + collbox[5]) / 2, 0)
			player:set_pos(new_pos)
			checker.after_tp_pos = player:get_pos()
		end
		local curr_pos = vector.floor(player:get_pos())
		for offy = 1, 5 do
			local p = vector.offset(curr_pos, 0, -offy, 0)
			if isWalkable(p) then
				do_tp(p)
				return
			end
		end
		do_tp(checker.old_pos_on_surface)
	end

	local function suspect(i)
		checker.old_score = checker.score
		checker.score = math.min(math.max(checker.score + i, 0), max_score)

		--debug info
		-- if checker.score ~= checker.old_score then
		-- 	minetest.debug(name, checker.score)
		-- end

		if checker.score >= max_score then
			-- Player is flying, initiate additional checks
			if vector.distance(checker.old_pos_on_surface, player:get_pos()) < 0.9 then
				-- Player is on the surface, assume they are not using a fly hack
				checker.score = math.max(checker.score - 0.5, 0)
			else
				-- Flying detected
				if checker.triggered > 0 and checker.triggered % 10 == 0 then
					minetest.chat_send_all(minetest.colorize("pink",
					string.format("[JMA Anti-Cheat]: Player %s caught for using a fly hack %d times. Kicked.", name, checker.triggered)))

					minetest.kick_player(name, "Please disable your fly cheat")
					discord.send_report("AntiFly: **%s** has been kicked for using fly hack", name)

					minetest.log("warning", string.format("%s has been kicked for using fly hack", name))
					return
				else
					tp_to_surface()
				end

				checker.triggered = checker.triggered + 1
				checker.score = math.max(checker.score - 0.1, 0)
				minetest.log("warning", string.format("%s caught for fly hack %d times at %s", name, checker.triggered, vector.to_string(player:get_pos())))
			end
		end
	end

	local function add_to_speed_history(val)
		local index = checker.speed_history_index
		if index > 2 then
			index = 1
		end
		checker.speed_history[index] = val
		index = index + 1
		checker.speed_history_index = index
	end

	checker.on_step_scan = function()
		--remove checker when player does not exist
		if not minetest.get_player_by_name(name) then
			handlers[name] = nil
			return
		end

		local player_physics = player:get_physics_override()
		if player_physics.gravity and player_physics.gravity < 0.7 then
			return
		end

		local pos = player:get_pos()
		if not pos or player:get_hp() == 0 or player:get_attach() then
			return
		end

		--Check the node on which the player is standing, if this is not the case, we do a detailed checks
		local pos_bottom = vecnew(pos.x, math.floor(pos.y + collbox[2]), pos.z)
		if is_on_surface(pos_bottom) then
			--The player is on surface. Removing suspicion gradually
			suspect(on_surface_cost)
			checker.old_pos_on_surface = pos_bottom

			if checker.score ~= checker.old_score then
				checker.speed_history = {}
				checker.speed_history_index = 1
			end
		else
			--Check if player really uses fly hack
			local player_vel = player:get_velocity()
			-- Player is moving?
			if not vector.equals(player_vel, vector.zero()) then
				add_to_speed_history(math.sqrt(player_vel.x^2 + player_vel.y^2 + player_vel.z^2))

				-- print(dump(checker.speed_history))
				--Pretty sure it's a fly hack...
				local controls = player:get_player_control()
				if ((controls.jump and pos.y > checker.old_pos.y) or (controls.sneak and pos.y < checker.old_pos.y))
				and compare_ints_tolerance(checker.speed_history, 0.15) then
					suspect(1.8)
				elseif player_vel.y == 0 then
					--moves, height is not changed
					suspect(0.9)
				end
			else
				--doesn't move, do regard this as suspicious. Maybe the player is lagging?
				suspect(0.3)
			end

			checker.old_pos = pos
			checker.old_vel = player_vel
		end
	end

	return checker
end

local timer = 0
minetest.register_globalstep(function(dtime)
	if timer < scan_interval then
		timer = timer + dtime
		return
	else
		timer = 0
	end

	for _, p in ipairs(minetest.get_connected_players()) do
		local name = p:get_player_name()
		local h = handlers[name]
		if h then
			h.on_step_scan()
		end
	end

end)

local function run_checker(player)
	local name = player:get_player_name()
	if not handlers[name] and (blacklist[name] or not minetest.check_player_privs(name, "fly")) then
		handlers[name] = new_antifly_handler(player)
	end
end

ctf_api.register_on_new_match(function()
	match_started = true
	for _, p in ipairs(minetest.get_connected_players()) do
		run_checker(p)
	end
end)

ctf_api.register_on_match_end(function ()
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
		run_checker(player)
	end
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	if handlers[name] then
		handlers[name] = nil
	end
end)

minetest.register_chatcommand("af_print",{
	description = "Prints scores",
	privs = {dev = true},
	params = "",
	func = function(name, param)
		if param ~= "" then
			local player = minetest.get_player_by_name(param)
			if player then
				local h = handlers[param]
				if h then
					return true, "score: " .. h.score .. " triggered: " .. h.triggered
				end
			else
				return false, "player not found"
			end
		end
		local output = {}
		for _, p in ipairs(minetest.get_connected_players()) do
			local pn = p:get_player_name()
			local h = handlers[pn]
			if h then
				table.insert(output, string.format("name: %s, score: %0.3f, triggered: %d", pn, h.score, h.triggered))
			end
		end
		return true, table.concat(output, "\n")
	end
})

minetest.register_chatcommand("af_threshold",{
	description = "Set trigger threshold",
	privs = {dev = true},
	params = "<int>",
	func = function(_, param)
		local i = tonumber(param)
		if i and i > 0.5 then
			max_score = i
			return true, "Done."
		end
		return false, "Invalid value"
	end
})

minetest.register_chatcommand("af_interval",{
	description = "Set scan interval",
	privs = {dev = true},
	params = "<int>",
	func = function(_, param)
		local i = tonumber(param)
		if i and i > 0 then
			scan_interval = i
			return true, "Done."
		end
		return false, "Invalid value"
	end
})

minetest.register_chatcommand("af_speed_rs",{
	description = "Set speed of suspicion removal",
	privs = {dev = true},
	params = "<int>",
	func = function(_, param)
		local i = tonumber(param)
		if i and i < 0 and math.abs(on_surface_cost - i) <= max_score then
			on_surface_cost = i
			return true, "Done."
		end
		return false, "Invalid value"
	end
})

minetest.register_chatcommand("af_blacklist",{
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
		if minetest.get_player_by_name(target_name) then
			if operation == "add" then
				blacklist[target_name] = true
				return true, "Player added"
			elseif operation == "remove" then
				blacklist[target_name] = nil
				return true, "Player removed"
			end
			return false, "Invalid usage (<name> <add|remove>)"
		else
			return false, "Player does not exist"
		end
	end
})