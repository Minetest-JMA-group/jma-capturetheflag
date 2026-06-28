--Inspired from Andrey's bandages mod

local S = core.get_translator(core.get_current_modname())

ctf_healing = {}

--- @alias BandageDef { after_heal: fun(obj: ObjectRef, user: ObjectRef)?, description: string,
--- heal_percent: number, inventory_image: string, inventory_overlay: string?,
--- wield_image: string?, heal_max: number?, heal_min: number? }

function ctf_healing.register_bandage(name, def)
	local tooldef = {
		description = def.description,
		inventory_image = def.inventory_image,
		inventory_overlay = def.inventory_overlay,
		wield_image = def.wield_image,
		on_use = function(itemstack, player, pointed_thing)
			local pname = player:get_player_name()
			if restrict_item then
				if restrict_item.is_restricted_for_player(pname, name) then
					hud_events.new(player, {
						text = S("You cannot use this item!"),
						quick = true,
					})
					return
				end
			end
			if pointed_thing.type == "object" then
				local object = pointed_thing.ref
				if not object:is_player() then
					local entity = object:get_luaentity()
					if entity and entity.name == "__builtin:item" and entity.on_punch then
						entity:on_punch(player)
					end
					return
				end

				local pname = object:get_player_name()
				local uname = player:get_player_name()

				if pname == uname then
					return
				end

				if ctf_teams.get(pname) ~= ctf_teams.get(uname) then
					hud_events.new(uname, {
						quick = true,
						text = S("@1 isn't in your team!", pname),
						color = "warning",
					})
					return
				end

				local hp = object:get_hp()
				local limit = def.heal_percent * object:get_properties().hp_max

				if hp <= 0 then
					hud_events.new(uname, {
						quick = true,
						text = S("@1 is dead!", pname),
						color = "warning",
					})
					return
				end

				if hp >= limit then
					hud_events.new(uname, {
						quick = true,
						text = S("@1 already has @2 HP!", pname, limit),
						color = "warning",
					})
					return
				end

				local hp_add = math.random(def.heal_min or 3, def.heal_max or 4)

				if hp + hp_add > limit then
					hp_add = limit - hp
					hp = limit
				else
					hp = hp + hp_add
				end

				local result =
					RunCallbacks(ctf_healing.registered_on_heal, player, object, hp_add)

				if not result then
					object:set_hp(hp)
					hud_events.new(pname, {
						quick = true,
						text = S("@1 healed you!", uname),
						color = 0xC1FF44,
					})
					hud_events.new(uname, {
						quick = true,
						text = S("You healed @1!", pname),
						color = 0xC1FF44,
					})
				elseif type(result) == "string" then
					hud_events.new(uname, {
						quick = true,
						text = result,
						color = "warning",
					})
				end
				if def.after_heal then
					def.after_heal(object, player)
				end
			elseif pointed_thing.type == "node" then
				local node_pointed = core.get_node(pointed_thing.under)
				local node_above = core.get_node(pointed_thing.under:offset(0, 1, 0))
				if node_pointed.name ~= "ctf_modebase:flag_captured_top" then
					if node_pointed.name:find("ctf_modebase:flag_") then
						ctf_modebase.flag_on_punch(
							player,
							pointed_thing.under,
							node_pointed
						)
					elseif
						node_above.name:find("ctf_modebase:flag_")
						and node_above.name ~= "ctf_modebase:flag_captured_top"
					then
						ctf_modebase.flag_on_punch(
							player,
							pointed_thing.under:offset(0, 1, 0),
							node_above
						)
					end
				end
			end
		end,
	}

	if def.rightclick_func then
		tooldef.on_place = function(itemstack, user, pointed, ...)
			local pointed_def
			local node

			if pointed and pointed.under then
				node = core.get_node(pointed.under)
				pointed_def = core.registered_nodes[node.name]
			end

			if pointed_def and pointed_def.on_rightclick then
				return core.item_place(itemstack, user, pointed)
			else
				return def.rightclick_func(itemstack, user, pointed, ...)
			end
		end

		tooldef.on_secondary_use = def.rightclick_func
	end

	core.register_tool(name, tooldef)
end

local HEAL_PERCENT = 0.75
ctf_healing.register_bandage("ctf_healing:bandage", {
	description = S("Bandage")
		.. "\n"
		.. S(
			"Heals teammates for 3-4 HP until target's HP is equal to @1% of their maximum HP",
			HEAL_PERCENT * 100
		),
	inventory_image = "ctf_healing_bandage.png",
	heal_percent = HEAL_PERCENT,
})

local SUPER_BANDAGE_HEAL_RADIUS = 3

--- @param pos1 Vector
--- @param pos2 Vector
local function generate_random_pos_inside(pos1, pos2)
	local x = math.random(pos1.x, pos2.x) + math.random() - 0.5
	local y = math.random(pos1.y, pos2.y) + math.random() - 0.5
	local z = math.random(pos1.z, pos2.z) + math.random() - 0.5
	return {
		x = x,
		y = y,
		z = z,
	}
end

--- @param pos1 Vector
--- @param pos2 Vector
local function spawn_heal_particles(pos1, pos2)
	for i = 1, 200 do
		local expire = math.random() * 2
		local y_velocity = math.random() * 0.5
		local pos = generate_random_pos_inside(pos1, pos2)
		core.add_particle({
			pos = pos,
			velocity = { x = 0, y = y_velocity, z = 0 },
			acceleration = { x = 0, y = 0, z = 0 },
			expirationtime = expire,
			size = 1,
			collisiondetection = false,
			collision_removal = false,
			object_collision = true,
			vertical = false,
			texture = "ctf_healing_healing_particle.png",
			glow = 4,
		})
	end
end

ctf_healing.register_bandage("ctf_healing:super_bandage", {
	description = S("Super Bandage") .. "\n" .. S(
		"Heal your teammate for 5-6 HP, while also healing nearby teammates by 2-3HP"
	),
	inventory_image = "ctf_healing_super_bandage.png",
	heal_percent = HEAL_PERCENT * 1.1,
	heal_min = 5,
	heal_max = 6,
	after_heal = function(obj, user)
		-- Also heal nearby teammates for a taxicab radius of 3
		if not obj:is_player() then
			return
		end
		local pos_center = obj:get_pos()
		local radius = {
			x = SUPER_BANDAGE_HEAL_RADIUS,
			y = SUPER_BANDAGE_HEAL_RADIUS,
			z = SUPER_BANDAGE_HEAL_RADIUS,
		}
		local pos1 = vector.subtract(pos_center, radius)
		local pos2 = vector.add(pos_center, radius)
		spawn_heal_particles(pos1, pos2)
		local objs = core.get_objects_in_area(pos1, pos2)
		local team = ctf_teams.get(obj:get_player_name())
		for _, obj2 in ipairs(objs) do
			local target_name = obj2:get_player_name()
			local team2 = ctf_teams.get(target_name)
			if obj2:is_player() and team2 == team then
				local current_hp = obj2:get_hp()
				local max_hp = obj2:get_properties().hp_max
				local hp_add = 2
				if math.random() > 0.5 then
					hp_add = 3
				end
				local result =
					RunCallbacks(ctf_healing.registered_on_heal, user, obj2, hp_add)
				local hp = math.min(current_hp + hp_add, max_hp)
				local healer_name = user:get_player_name()
				if not result and current_hp ~= max_hp then
					obj2:set_hp(hp)
					ctf_combat_mode.add_healer(obj2, user, 60)
					hud_events.new(target_name, {
						quick = true,
						text = S("@1 healed you!", healer_name),
						color = 0xC1FF44,
					})
				elseif type(result) == "string" then
					hud_events.new(healer_name, {
						quick = true,
						text = result,
						color = "warning",
					})
				end
			end
		end
	end,
})
