local function check_hit(pos1, pos2, obj)
	local ray = minetest.raycast(pos1, pos2, true, false)
	local hit = ray:next()

	-- Skip over non-normal nodes like ladders, water, doors, glass, leaves, etc
	-- Also skip over all objects that aren't the target
	-- Any collisions within a 1 node distance from the target don't stop the grenade
	while hit and (
		(
		 hit.type == "node"
		 and
		 (
			hit.intersection_point:distance(pos2) <= 1
			or
			not minetest.registered_nodes[minetest.get_node(hit.under).name].walkable
		 )
		)
		or
		(
		 hit.type == "object" and hit.ref ~= obj
		)
	) do
		hit = ray:next()
	end

	if hit and hit.type == "object" and hit.ref == obj then
		return true
	end
end

local fragdef_small = table.copy(minetest.registered_craftitems["grenades:frag"].grenade)
fragdef_small.description = "Firecracker (Hurts anyone near blast)"
fragdef_small.image = "ctf_mode_chaos_firecracker_grenade.png"
fragdef_small.explode_radius = 4
fragdef_small.explode_damage = 16
fragdef_small.clock = 1.7

local old_explode = fragdef_small.on_explode
fragdef_small.on_explode = function(def, obj, pos, name, ...)
	local player = minetest.get_player_by_name(name or "")

	if player and pos then
		local dist = pos.y - player:get_pos().y

		if dist <= -20 then
			return
		end
	end

	return old_explode(def, obj, pos, name, ...)
end

grenades.register_grenade("ctf_mode_chaos:small_frag", fragdef_small)

local tool = {}
local sounds = {}

local KNOCKBACK_AMOUNT = 35
local KNOCKBACK_AMOUNT_WITH_FLAG = KNOCKBACK_AMOUNT / 2
local KNOCKBACK_RADIUS = 3.5
grenades.register_grenade("ctf_mode_chaos:knockback_grenade", {
	description = "Knockback Grenade, players within a very small area take extreme knockback",
	image = "ctf_mode_chaos_knockback_grenade.png",
	clock = 1.8,
	on_collide = function()
		return true
	end,
	on_explode = function(def, obj, pos, name)
		minetest.add_particle({
			pos = pos,
			velocity = {x=0, y=0, z=0},
			acceleration = {x=0, y=0, z=0},
			expirationtime = 0.3,
			size = 15,
			collisiondetection = false,
			collision_removal = false,
			object_collision = false,
			vertical = false,
			texture = "grenades_boom.png",
			glow = 10
		})

		minetest.sound_play("grenades_explode", {
			pos = pos,
			gain = 0.6,
			pitch = 3.0,
			max_hear_distance = KNOCKBACK_RADIUS * 4,
		}, true)

		for _, v in pairs(minetest.get_objects_inside_radius(pos, KNOCKBACK_RADIUS)) do
			local vname = v:get_player_name()
			local player = minetest.get_player_by_name(name)

			if player and v:is_player() and v:get_hp() > 0 and v:get_properties().pointable and
			(vname == name or ctf_teams.get(vname) ~= ctf_teams.get(name)) then
				local footpos = vector.offset(v:get_pos(), 0, 0.1, 0)
				local headpos = vector.offset(v:get_pos(), 0, v:get_properties().eye_height, 0)
				local footdist = vector.distance(pos, footpos)
				local headdist = vector.distance(pos, headpos)
				local target_head = false

				if footdist >= headdist then
					target_head = true
				end

				local hit_pos1 = check_hit(pos, target_head and headpos or footpos, v)

				-- Check the closest distance, but if that fails try targeting the farther one
				if hit_pos1 or check_hit(pos, target_head and footpos or headpos, v) then
					v:punch(player, 1, {
						punch_interval = 1,
						damage_groups = {
							fleshy = 1,
							knockback_grenade = 1,
						}
					}, nil)
					minetest.add_particlespawner({
						attached = v,
						amount = 10,
						time = 1,
						minpos = {x = 0, y = 1, z = 0}, -- Offset to middle of player
						maxpos = {x = 0, y = 1, z = 0},
						minvel = {x = 0, y = 0, z = 0},
						maxvel = v:get_velocity(),
						minacc = {x = 0, y = -9, z = 0},
						maxacc = {x = 0, y = -9, z = 0},
						minexptime = 1,
						maxexptime = 2.8,
						minsize = 3,
						maxsize = 4,
						collisiondetection = false,
						collision_removal = false,
						vertical = false,
						texture = "grenades_smoke.png",
					})

					local kb
					if ctf_modebase.taken_flags[vname] then
						kb = KNOCKBACK_AMOUNT_WITH_FLAG
					else
						kb = KNOCKBACK_AMOUNT
					end

					local dir = vector.direction(pos, headpos)
					if dir.y < 0 then dir.y = 0 end
					local vel = {x = dir.x * kb, y = dir.y * (kb / 1.8), z = dir.z * kb }
					v:add_velocity(vel)
				end
			end
		end
	end,
})

local WEAR_MAX = 65535
local grenade_list = {
	{name = "ctf_mode_chaos:small_frag"         , cooldown = 1 },
	{name = "ctf_mode_chaos:knockback_grenade"  , cooldown = 1 },
}

local held_grenade = {}
local function swap_next_grenade(itemstack, user, pointed)
	if itemstack:get_wear() > 1 then return end

	local nadeid = itemstack:get_name():sub(-1, -1)
	local nadeid_next = nadeid + 1

	if nadeid_next > #grenade_list then
		nadeid_next = 1
	end

	held_grenade[user:get_player_name()] = nadeid_next
	return "ctf_mode_chaos:grenade_tool_"..nadeid_next
end

minetest.register_on_leaveplayer(function(player)
	held_grenade[player:get_player_name()] = nil
end)

for idx, info in ipairs(grenade_list) do
	local def = minetest.registered_items[info.name]

	minetest.register_tool("ctf_mode_chaos:grenade_tool_"..idx, {
		description = def.description..minetest.colorize("gold", "\nRightclick off cooldown to switch to other grenades"),
		inventory_image = def.inventory_image,
		wield_image = def.inventory_image,
		inventory_overlay = "ctf_modebase_special_item.png",
		on_use = function(itemstack, user, pointed_thing)
			if itemstack:get_wear() > 1 then return end

			if itemstack:get_wear() <= 1 then
				grenades.throw_grenade(info.name, 17, user)
			end

			itemstack:set_wear(WEAR_MAX - 6000)
			ctf_modebase.update_wear.start_update(
				user:get_player_name(),
				"ctf_mode_chaos:grenade_tool_"..idx,
				WEAR_MAX/info.cooldown,
				true
			)

			return itemstack
		end,
		on_place = function(itemstack, user, pointed, ...)
			local node = false
			local pointed_def

			if pointed and pointed.under then
				node = minetest.get_node(pointed.under)
				pointed_def = minetest.registered_nodes[node.name]
			end

			if node and pointed_def.on_rightclick then
				return minetest.item_place(itemstack, user, pointed)
			else
				return swap_next_grenade(itemstack, user, pointed)
			end
		end,
		on_secondary_use = swap_next_grenade
	})
end

function tool.get_grenade_tool(player)
	return "ctf_mode_chaos:grenade_tool_" .. (held_grenade[PlayerName(player)] or 1)
end

ctf_api.register_on_match_end(function()
	for sound in pairs(sounds) do
		minetest.sound_stop(sound)
	end
	sounds = {}
end)

return tool
