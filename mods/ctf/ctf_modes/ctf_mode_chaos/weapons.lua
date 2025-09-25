local WEAR_MAX = 65535
local cooldown = ctf_core.init_cooldowns()

local shotgun_name = "ctf_mode_chaos:chaotic_shotgun"
local grenade_launcher_name = "ctf_mode_chaos:grenade_launcher"

local weapon_list = {
	[1] = grenade_launcher_name,
	[2] = function(meta)
		if meta:get_int("shotgun_unloaded") == 1 then
			return shotgun_name
		end
		return shotgun_name .. "_loaded"
	end,
}

local function can_swap(meta)
	if meta:get_int("overheat") == 1 then
		return false
	end
	return true
end

local function swap_weapon(itemstack)
	local meta = itemstack:get_meta()
	local idx = meta:get_int("idx")
	if idx == 0 then
		idx = 1
	end
	local weapon_idx_next = idx + 1

	if weapon_idx_next > #weapon_list then
		weapon_idx_next = 1
	end

	local next_weapon_name = ""
	if type(weapon_list[weapon_idx_next]) == "function" then
		next_weapon_name = weapon_list[weapon_idx_next](meta)
	else
		next_weapon_name = weapon_list[weapon_idx_next]
	end

	itemstack:set_name(next_weapon_name)
	meta:set_int("idx", weapon_idx_next)

	return itemstack
end

ctf_ranged.simple_register_gun(shotgun_name, {
	type = "shotgun",
	description = "Chaotic Shotgun",
	texture = "ctf_mode_chaos_shotgun.png",
	fire_sound = "ctf_mode_chaos_shotgun",
	rounds = 10,
	bullet = {
		amount = 6,
		spread = 3.5,
	},
	range = 75,
	damage = 1,
	automatic = true,
	fire_interval = 0.2,
	liquid_travel_dist = 5,
	on_secondary_use = function(itemstack, user, pointed_thing)
		local meta = itemstack:get_meta()
		if not can_swap(meta) then
			return
		end

		itemstack = swap_weapon(itemstack)
		meta:set_int("shotgun_wear", itemstack:get_wear())
		itemstack:set_wear(meta:get_int("grenade_launcher_wear"))
		return itemstack
	end,
})

local shotgun_wield_scale = { x = 1.5, y = 1.5, z = 2 }

-- Shotgun unloaded
core.override_item(shotgun_name, {
	wield_scale = shotgun_wield_scale,
	on_secondary_use = function(itemstack, user, pointed_thing)
		local meta = itemstack:get_meta()
		if not can_swap(meta) then
			return
		end

		itemstack = swap_weapon(itemstack)

		meta:set_int("shotgun_unloaded", 1)
		meta:set_int("shotgun_wear", 0)
		itemstack:set_wear(meta:get_int("grenade_launcher_wear"))

		return itemstack
	end,
})

-- Shotgun loaded
core.override_item(shotgun_name .. "_loaded", {
	wield_scale = shotgun_wield_scale,
	on_secondary_use = function(itemstack, user, pointed_thing)
		local meta = itemstack:get_meta()

		itemstack = swap_weapon(itemstack)
		meta:set_int("shotgun_unloaded", 0)
		meta:set_int("shotgun_wear", itemstack:get_wear())
		itemstack:set_wear(meta:get_int("grenade_launcher_wear"))
		return itemstack
	end,
})

local function run_cooldown(user, itemstack)
	local name = user:get_player_name()

	local on_finish = function()
		local inv = user:get_inventory()
		for i = 1, inv:get_size("main") do
			local itemstack = inv:get_stack("main", i)
			if itemstack:get_name() == grenade_launcher_name then
				local meta = itemstack:get_meta()
				meta:set_int("overheat", 0)
				meta:set_string("color", "")
				inv:set_stack("main", i, itemstack)
			end
		end
	end

	ctf_modebase.update_wear.start_update(name, itemstack, WEAR_MAX / 5, true, on_finish)
end

local radius = 2

local shot_types = {
	normal = {
		speed = 18,
		radius = 2,
		wear = WEAR_MAX / 5,
	},
	powered = {
		speed = 30,
		radius = 4,
		wear = WEAR_MAX / 3,
	},
}

core.register_craftitem("ctf_mode_chaos:power_charge", {
	description = "Grenade Power Charge",
	inventory_image = "ctf_mode_chaos_power_charge.png",
	stack_max = 25,
})

core.register_tool("ctf_mode_chaos:grenade_launcher", {
	description = "Grenade Launcher",
	wield_scale = { x = 2.0, y = 2.0, z = 2.5 },
	inventory_image = "ctf_mode_chaos_grenade_launcher.png",
	inventory_overlay = "ctf_modebase_special_item.png",
	wield_image = "ctf_mode_chaos_grenade_launcher.png",
	range = 4,
	on_use = function(itemstack, user, pointed_thing)
		local meta = itemstack:get_meta()
		if meta:get_int("overheat") == 1 then
			return
		end

		local is_sneaking = user:get_player_control().sneak
		local shot_type = "normal"

		if is_sneaking then
			local inv = user:get_inventory()
			local charge = inv:remove_item("main", "ctf_mode_chaos:power_charge 1")
			if charge:is_empty() then
				is_sneaking = false
				hud_events.new(user:get_player_name(), {
					text = "No power charges",
					quick = true,
				})
			else
				shot_type = "powered"
			end
		end

		local stats = shot_types[shot_type]
		local name = user:get_player_name()
		local pos = user:get_pos()
		local dir = user:get_look_dir()

		if pos and dir then
			pos.y = pos.y + 1.5
			local ahead = vector.add(pos, vector.multiply(dir, 1))
			local obj = core.add_entity(ahead, "ctf_mode_chaos:grenade")
			if obj then
				local ent = obj:get_luaentity()
				ent.puncher_name = name
				ent.radius = cooldown:get(user) and 1 or stats.radius
				if shot_type == "powered" then
					core.add_particlespawner({
						amount = 15,
						time = 1,
						minvel = vector.multiply(dir, 2),
						maxvel = vector.multiply(dir, 4),
						minacc = vector.new(0, -1, 0),
						maxacc = vector.new(0, -1, 0),
						minexptime = 0.5,
						maxexptime = 1,
						minsize = 1,
						maxsize = 2,
						texture = "smoke_puff.png^[colorize:black:150",
						attached = obj,
					})
					obj:set_properties({
						textures = {
							"ctf_mode_chaos_grenade_powered.png^[multiply:red:100",
						},
					})
				end

				local speed = vector.length(user:get_velocity())
				obj:add_velocity(vector.multiply(dir, stats.speed + speed))
			end
		end

		core.sound_play("ctf_mode_chaos_grenade_launcher_plop", {
			to_player = name,
			gain = 0.5,
			pitch = shot_type == "powered" and 0.5 or 1.1,
		})

		local new_wear = itemstack:get_wear() + stats.wear
		if new_wear > 65534 then
			new_wear = 65534
		end
		itemstack:set_wear(new_wear)
		if itemstack:get_wear() >= 65532 then
			meta:set_int("overheat", 1)
			meta:set_string("color", "#fc6a6c")
			run_cooldown(user, itemstack)
		end

		-- Add recoil and particles for charged shot
		local recoil_strength = shot_type == "powered" and 10 or 5
		user:add_velocity(vector.multiply(dir, -recoil_strength))

		cooldown:set(user, 0.3)
		return itemstack
	end,

	on_secondary_use = function(itemstack, user, pointed_thing)
		local meta = itemstack:get_meta()
		if not can_swap(meta) then
			return
		end
		itemstack = swap_weapon(itemstack)

		meta:set_int("grenade_launcher_wear", itemstack:get_wear())
		itemstack:set_wear(meta:get_int("shotgun_wear"))

		return itemstack
	end,
})

local function can_explode(pos, pname, radius)
	if core.is_protected(pos, "") then
		core.chat_send_player(pname, "You can't explode grenade on spawn!")
		return false
	end

	local pteam = ctf_teams.get(pname)

	if pteam then
		for flagteam, team in pairs(ctf_map.current_map.teams) do
			if not ctf_modebase.flag_captured[flagteam] and team.flag_pos then
				local distance_from_flag = vector.distance(pos, team.flag_pos)
				if distance_from_flag <= radius then
					minetest.chat_send_player(
						pname,
						"You can't explode grenade so close to a flag!"
					)
					return false
				end
			end
		end
	end
	return true
end

core.register_entity("ctf_mode_chaos:grenade", {
	initial_properties = {
		visual = "sprite",
		visual_size = { x = 1, y = 1 },
		textures = { "ctf_mode_chaos_grenade.png^[multiply:black:100" },
		physical = true,
		makes_footstep_sound = false,
		backface_culling = false,
		static_save = false,
		pointable = false,
		collide_with_objects = true,
		collisionbox = { -0.2, -0.2, -0.2, 0.2, 0.2, 0.2 },
	},
	timer = 0,
	on_activate = function(self)
		core.add_particlespawner({
			attached = self.object,
			amount = 5,
			time = 1,
			minpos = { x = 0, y = -0.5, z = 0 }, -- Offset to middle of player
			maxpos = { x = 0, y = 0.5, z = 0 },
			minvel = { x = 0, y = 0, z = 0 },
			maxvel = self.object:get_velocity(),
			minacc = { x = 0, y = 5, z = 0 },
			maxacc = { x = 0, y = 7, z = 0 },
			minexptime = 1.5,
			maxexptime = 3.0,
			minsize = 2,
			maxsize = 3,
			collisiondetection = false,
			collision_removal = false,
			vertical = false,
			texture = "grenades_smoke.png^[colorize:black:150",
		})
	end,
	on_step = function(self, dtime, moveresult)
		self.timer = self.timer + dtime
		if self.timer >= 60 then
			self.object:remove()
			return
		end

		local pos = self.object:get_pos()
		if not pos then
			return
		end

		if moveresult.collides then
			local rad = self.radius or radius
			if can_explode(pos, self.puncher_name, rad) then
				tnt.boom(pos, {
					puncher_name = self.puncher_name,
					radius = rad,
					damage_modifier = 2.5,
				})
			end
			self.object:remove()
			return
		end

		local vel = self.object:get_velocity()
		if vel then
			local gravity = 9
			vel.y = vel.y - gravity * dtime
			self.object:set_velocity(vel)
		end
	end,
})
