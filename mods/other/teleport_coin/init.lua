local modname = core.get_current_modname()
local S = core.get_translator(modname)

local COIN_ITEM = modname .. ":coin"
local MAX_ATTEMPTS = 128

local function is_passable(name)
	if not name or name == "" then
		return false
	end

	if name == "air" then
		return true
	end

	if name == "ignore" or name == "ctf_map:ignore" then
		return false
	end

	local def = core.registered_nodes[name]
	if not def then
		return false
	end

	if def.walkable then
		return false
	end

	if def.liquidtype and def.liquidtype ~= "none" then
		return false
	end

	return true
end

local function is_solid_ground(name)
	if not name or name == "" then
		return false
	end

	if name == "ignore" or name == "ctf_map:ignore" then
		return false
	end

	if name == "air" then
		return false
	end

	local def = core.registered_nodes[name]
	if not def then
		return false
	end

	if def.walkable == false then
		return false
	end

	if def.liquidtype and def.liquidtype ~= "none" then
		return false
	end

	return true
end

local function get_map_bounds()
	if not ctf_map or not ctf_map.current_map then
		return nil, nil, S("No active map is available.")
	end

	local pos1 = ctf_map.current_map.pos1
	local pos2 = ctf_map.current_map.pos2
	if not pos1 or not pos2 then
		return nil, nil, S("Map bounds are incomplete.")
	end

	local minp = {
		x = math.min(pos1.x, pos2.x),
		y = math.min(pos1.y, pos2.y),
		z = math.min(pos1.z, pos2.z),
	}

	local maxp = {
		x = math.max(pos1.x, pos2.x),
		y = math.max(pos1.y, pos2.y),
		z = math.max(pos1.z, pos2.z),
	}

	return minp, maxp
end

local function find_surface_position()
	local minp, maxp, err = get_map_bounds()
	if not minp or not maxp then
		return nil, err
	end

	local column_min = { x = 0, y = 0, z = 0 }
	local column_max = { x = 0, y = 0, z = 0 }

	for _ = 1, MAX_ATTEMPTS do
		local x = math.random(minp.x, maxp.x)
		local z = math.random(minp.z, maxp.z)

		column_min.x, column_min.y, column_min.z = x, minp.y - 1, z
		column_max.x, column_max.y, column_max.z = x, maxp.y + 2, z
		core.load_area(column_min, column_max)

		for y = maxp.y, minp.y - 1, -1 do
			local ground = core.get_node({ x = x, y = y, z = z })
			if is_solid_ground(ground.name) then
				local above = core.get_node({ x = x, y = y + 1, z = z })
				local top = core.get_node({ x = x, y = y + 2, z = z })

				if is_passable(above.name) and is_passable(top.name) then
					return { x = x, y = y + 1, z = z }
				end
			end
		end
	end

	return nil, S("Unable to find a valid surface right now.")
end

local function spawn_teleport_effect(pos)
	if not pos then
		return
	end

	local spread = { x = 0.4, y = 0.3, z = 0.4 }

	core.add_particlespawner({
		amount = 18,
		time = 0.25,
		minpos = vector.subtract(pos, spread),
		maxpos = vector.add(pos, spread),
		minvel = { x = -0.5, y = 0.4, z = -0.5 },
		maxvel = { x = 0.5, y = 1.2, z = 0.5 },
		minacc = { x = 0, y = -2.8, z = 0 },
		maxacc = { x = 0, y = -1.2, z = 0 },
		minexptime = 0.35,
		maxexptime = 0.65,
		minsize = 1.4,
		maxsize = 2.4,
		texture = "default_item_smoke.png^[brighten",
		glow = 6,
	})

	core.add_particlespawner({
		amount = 10,
		time = 0.15,
		minpos = vector.subtract(pos, { x = 0.2, y = 0.1, z = 0.2 }),
		maxpos = vector.add(pos, { x = 0.2, y = 0.4, z = 0.2 }),
		minvel = { x = -0.2, y = 0.6, z = -0.2 },
		maxvel = { x = 0.2, y = 1.0, z = 0.2 },
		minexptime = 0.2,
		maxexptime = 0.35,
		minsize = 1.0,
		maxsize = 1.6,
		texture = "default_mese_crystal_fragment.png^[brighten",
		glow = 8,
	})
end

local function teleport_player(player)
	local origin = player:get_pos()
	local pos, err = find_surface_position()
	if not pos then
		return false, err
	end

	if origin then
		spawn_teleport_effect(origin)
	end

	player:set_pos(pos)
	player:set_velocity({ x = 0, y = 0, z = 0 })
	spawn_teleport_effect(pos)

	return true
end

core.register_craftitem(COIN_ITEM, {
	description = S("Teleport Coin"),
	inventory_image = "teleport_coin_32px.png",
	stack_max = 1,
	on_use = function(itemstack, user)
		if not user or not user:is_player() then
			return itemstack
		end

		if ctf_modebase and not ctf_modebase.match_started then
			core.chat_send_player(
				user:get_player_name(),
				S("You must wait for the match to begin before using this coin.")
			)
			return itemstack
		end

		local ok, err = teleport_player(user)
		if ok then
			itemstack:take_item()
		else
			if err and err ~= "" then
				core.chat_send_player(user:get_player_name(), err)
			end
		end

		return itemstack
	end,
	on_drop = function(itemstack, dropper)
		if dropper and dropper:is_player() then
			core.chat_send_player(
				dropper:get_player_name(),
				S("The teleport coin refuses to leave you.")
			)
		end
		return itemstack
	end,
})

core.register_allow_player_inventory_action(function(player, action, inventory, info)
	if action ~= "take" then
		return
	end

	if not info or not info.stack or info.stack:get_name() ~= COIN_ITEM then
		return
	end

	if player and player:is_player() then
		core.chat_send_player(
			player:get_player_name(),
			S("You cannot store the teleport coin elsewhere.")
		)
	end

	return 0
end)
