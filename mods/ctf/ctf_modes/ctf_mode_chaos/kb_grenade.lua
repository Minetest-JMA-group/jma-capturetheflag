local WEAR_MAX = 65535
local function check_hit(pos1, pos2, obj)
	local ray = minetest.raycast(pos1, pos2, true, false)
	local hit = ray:next()

	-- Skip over non-normal nodes like ladders, water, doors, glass, leaves, etc
	-- Also skip over all objects that aren't the target
	-- Any collisions within a 1 node distance from the target don't stop the grenade
	while
		hit
		and (
			(
				hit.type == "node"
				and (
					hit.intersection_point:distance(pos2) <= 1
					or not minetest.registered_nodes[minetest.get_node(hit.under).name].walkable
				)
			) or (hit.type == "object" and hit.ref ~= obj)
		)
	do
		hit = ray:next()
	end

	if hit and hit.type == "object" and hit.ref == obj then
		return true
	end
end

local sounds = {}

local KNOCKBACK_AMOUNT = 35
local KNOCKBACK_RADIUS = 4.5
local KNOCKBACK_AMOUNT_WITH_FLAG = 15
grenades.register_grenade("ctf_mode_chaos:knockback_grenade", {
	description = "Knockback Grenade, players within a very small area take extreme knockback",
	image = "ctf_mode_chaos_knockback_grenade.png",
	clock = 1.8,
	on_collide = function()
		return true
	end,
	touch_interaction = "short_dig_long_place", -- throw with short tap

	on_explode = function(def, obj, pos, name)
		minetest.add_particle({
			pos = pos,
			velocity = { x = 0, y = 0, z = 0 },
			acceleration = { x = 0, y = 0, z = 0 },
			expirationtime = 0.3,
			size = 15,
			collisiondetection = false,
			collision_removal = false,
			object_collision = false,
			vertical = false,
			texture = "grenades_boom.png",
			glow = 10,
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

			if
				player
				and v:is_player()
				and v:get_hp() > 0
				and v:get_properties().pointable
				and (
					vname == name
					or ctf_teams.get(vname) ~= ctf_teams.get(name)
					or ctf_jma_elysium.get_player(name)
						and ctf_jma_elysium.get_player(vname)
				)
			then
				local footpos = vector.offset(v:get_pos(), 0, 0.1, 0)
				local headpos =
					vector.offset(v:get_pos(), 0, v:get_properties().eye_height, 0)
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
						},
					}, nil)
					minetest.add_particlespawner({
						attached = v,
						amount = 10,
						time = 1,
						minpos = { x = 0, y = 1, z = 0 }, -- Offset to middle of player
						maxpos = { x = 0, y = 1, z = 0 },
						minvel = { x = 0, y = 0, z = 0 },
						maxvel = v:get_velocity(),
						minacc = { x = 0, y = -9, z = 0 },
						maxacc = { x = 0, y = -9, z = 0 },
						minexptime = 1,
						maxexptime = 2.8,
						minsize = 3,
						maxsize = 4,
						collisiondetection = false,
						collision_removal = false,
						vertical = false,
						texture = "grenades_smoke.png",
					})

					local kb = KNOCKBACK_AMOUNT
					if ctf_modebase.taken_flags[vname] then
						kb = KNOCKBACK_AMOUNT_WITH_FLAG
					else
						kb = KNOCKBACK_AMOUNT
					end

					local dir = vector.direction(pos, headpos)
					if dir.y < 0 then
						dir.y = 0
					end
					local vel = { x = dir.x * kb, y = dir.y * (kb / 1.8), z = dir.z * kb }
					v:add_velocity(vel)
				end
			end
		end
	end,
})

do
	local kb_def = minetest.registered_items["ctf_mode_chaos:knockback_grenade"]
	kb_def.name = "ctf_mode_chaos:knockback_grenade_tool"
	kb_def.on_use = function(itemstack, user, pointed_thing)
		if itemstack:get_wear() > 1 then
			return
		end

		if itemstack:get_wear() <= 1 then
			grenades.throw_grenade("ctf_mode_chaos:knockback_grenade", 17, user)
		end

		itemstack:set_wear(WEAR_MAX - 6000)
		ctf_modebase.update_wear.start_update(
			user:get_player_name(),
			itemstack,
			WEAR_MAX,
			true
		)

		return itemstack
	end
	minetest.register_tool(kb_def.name, kb_def)

	ctf_api.register_on_match_end(function()
		for sound in pairs(sounds) do
			minetest.sound_stop(sound)
		end
		sounds = {}
	end)
end

