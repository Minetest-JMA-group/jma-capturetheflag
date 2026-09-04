local weapons_api = ctf_mode_chaos.weapons_api
local ROCKET_LAUNCHER = weapons_api.ROCKET_LAUNCHER

weapons_api.register_gun(ROCKET_LAUNCHER, "rocket", {
	description = "Rocket Launcher",
	image = "ctf_mode_chaos_rocket_launcher.png",
	type = "grenade",
	grenade = "rocket",
	ammo = "ctf_mode_chaos:rocket",
	ammo_label = "rockets",
	cost = 1,
	charged_cost = 2,
	cooldown = 1.0,
	recoil = 13,
	speed = 33,
	charged_speed = 45,
	radius = 3,
	charged_radius = 4,
	destruction_radius = 2,
	damage_modifier = 1.4,
})

-- "Rain" fires a tight volley of small rockets that explode on impact.
weapons_api.register_gun(ROCKET_LAUNCHER, "rain", {
	description = "Rain Launcher",
	image = "ctf_mode_chaos_rocket_launcher.png^[colorize:#aaddff:150",
	type = "grenade",
	grenade = "rain",
	ammo = "ctf_mode_chaos:rocket",
	ammo_label = "rockets",
	cost = 3,
	cooldown = 3.5,
	recoil = 17,
	speed = 39,
	spread = 0.05,
	mini_count = 10,
	mini_damage = 4,
	disable_destruction = true,
})

local rocket_mode_order = { "rocket", "rain" }

ctf_mode_chaos.register_weapon_template({
	id = ROCKET_LAUNCHER,
	description = "Rocket Launcher",
	mode_order = rocket_mode_order,
	is_weapon_item = function(itemname)
		return itemname:match("^ctf_mode_chaos:rocket_launcher_") ~= nil
	end,
	param_defs = {
		fast_reload = weapons_api.PARAM_fast_reload,
		propellant = weapons_api.PARAM_PROPELLANT,
		big_bang = weapons_api.PARAM_BIG_BANG,
		charger = weapons_api.PARAM_CHARGER,
	},
	mode_mods = {
		rain = {
			description = "Rocket Rain",
			weight = 6,
			icon = "ctf_mode_chaos_rocket.png^[colorize:#aaddff:200",
		},
	},
})

core.register_craftitem("ctf_mode_chaos:rocket", {
	description = "Rocket\nAmmo for the Rocket Launcher",
	inventory_image = "ctf_mode_chaos_rocket.png",
})

local ROCKET_KNOCKBACK = 0.1 -- everyone else
local ROCKET_SELF_KNOCKBACK = 0.5 -- the shooter

local function explode_rocket(self, pos)
	if weapons_api.can_explode(pos, self.puncher_name, self.radius or 3) then
		tnt.boom(pos, {
			puncher_name = self.puncher_name,
			-- Damage/entity radius is governed by self.radius; terrain
			-- destruction uses its own, separately tuned radius.
			radius = self.radius or 3,
			destruction_radius = self.destruction_radius,
			damage_modifier = self.damage_modifier or 1.4,
			damage_multiplier = self.damage_multiplier or 1,
			knockback_multiplier = (self.knockback or 1) * ROCKET_KNOCKBACK,
			self_knockback_multiplier = (self.knockback or 1) * ROCKET_SELF_KNOCKBACK,
		})
	end
end

-- Spawns a single smoke puff while a rocket flies. Particles do not inherit
-- the rocket's velocity, so the fast-moving rocket leaves them behind as a trail.
local function spawn_rocket_smoke(pos, vel, exptime)
	core.add_particle({
		pos = pos,
		velocity = vel,
		acceleration = { x = 0, y = 1.5, z = 0 },
		expirationtime = exptime,
		size = 1.5,
		collisiondetection = false,
		vertical = false,
		texture = "grenades_smoke.png^[colorize:white:150",
	})
end

core.register_entity("ctf_mode_chaos:rocket", {
	initial_properties = {
		visual = "sprite",
		textures = {"ctf_mode_chaos_rocket_sprite.png"},
		physical = true,
		makes_footstep_sound = false,
		backface_culling = false,
		pointable = false,
		collide_with_objects = false,
		automatic_face_movement_dir = 270,
		static_save = false,
		collisionbox = { -0.25, -0.25, -0.25, 0.25, 0.25, 0.25 },
	},
	timer = 0,
	on_step = function(self, dtime, moveresult)
		self.timer = self.timer + dtime
		local pos = self.object:get_pos()
		if not pos then
			return
		end

		if self.timer >= 60 then
			self.object:remove()
			return
		end

		if self.timer > 0.2 then
			-- Detonate when close to a player
			local objs = core.get_objects_inside_radius(
				vector.offset(pos, 0, -1, 0),
				1.3
			)
			for _, obj in ipairs(objs) do
				if obj:is_player() then
					explode_rocket(self, pos)
					self.object:remove()
					return
				end
			end
		end

		if moveresult.collides and self.timer > 0.2 then
			explode_rocket(self, pos)
			self.object:remove()
		end

		-- Leave a smoke trail while flying
		self.smoke_timer = (self.smoke_timer or 0) + dtime
		if self.smoke_timer >= 0.05 then
			self.smoke_timer = self.smoke_timer - 0.05
			local vel = self.object:get_velocity()
			local backward = vector.zero()
			if vel and vector.length(vel) > 0.5 then
				backward = vector.multiply(vector.normalize(vel), -2)
			end
			spawn_rocket_smoke(pos, backward, math.random() * 1 + 0.8)
		end
	end,
})

-- Mini rocket entity (rain mode)
-- Explodes a small rocket through the tnt weapons_api. radius 1 with a negative
-- damage modifier keeps the blast small: about 2 damage at point blank,
-- falling off with distance.
local function explode_mini_rocket(self, pos)
	if weapons_api.can_explode(pos, self.puncher_name, 1) then
		tnt.boom(pos, {
			puncher_name = self.puncher_name,
			radius = 1,
			-- Rain mini rockets never dig the terrain (see the rain gun def).
			disable_destruction = self.disable_destruction,
			damage_modifier = self.damage_modifier or 1,
			damage_multiplier = self.damage_multiplier or 1,
			knockback_multiplier = (self.knockback or 1) * ROCKET_KNOCKBACK,
			self_knockback_multiplier = (self.knockback or 1) * ROCKET_SELF_KNOCKBACK,
		})
	end
end

core.register_entity("ctf_mode_chaos:mini_rocket", {
	initial_properties = {
		visual = "sprite",
		visual_size = { x = 0.35, y = 0.35 },
		textures = {"ctf_mode_chaos_rocket_sprite.png"},
		physical = true,
		makes_footstep_sound = false,
		backface_culling = false,
		static_save = false,
		pointable = false,
		collide_with_objects = false,
		collisionbox = { -0.12, -0.12, -0.12, 0.12, 0.12, 0.12 },
	},
	timer = 0,
	on_step = function(self, dtime, moveresult)
		self.timer = self.timer + dtime
		local pos = self.object:get_pos()
		if not pos then
			return
		end

		-- Explode on any collision (node or player)
		if moveresult.collides then
			explode_mini_rocket(self, pos)
			self.object:remove()
			return
		end

		-- Fast small rockets can skip the physics collision with a player,
		-- so also detonate when flying close to one.
		if self.timer > 0.05 then
			local objs = core.get_objects_inside_radius(pos, 0.7)
			for _, obj in ipairs(objs) do
				if obj:is_player() and weapons_api.can_hit(self.puncher_name, obj:get_player_name()) then
					explode_mini_rocket(self, pos)
					self.object:remove()
					return
				end
			end
		end

		if self.timer > 5 then
			self.object:remove()
		end

		-- Leave a smoke trail while flying
		self.smoke_timer = (self.smoke_timer or 0) + dtime
		if self.smoke_timer >= 0.1 then
			self.smoke_timer = self.smoke_timer - 0.1
			local vel = self.object:get_velocity()
			local backward = vector.zero()
			if vel and vector.length(vel) > 0.5 then
				backward = vector.multiply(vector.normalize(vel), -1.5)
			end
			spawn_rocket_smoke(pos, backward, math.random() * 0.8 + 0.5
			)
		end
	end,
})

for mode, gun in pairs(weapons_api.rocket_guns) do
	core.register_tool("ctf_mode_chaos:rocket_launcher_" .. mode, {
		description = gun.description
			.. "\nAmmo: " .. gun.ammo_label
			.. "\nRight-click: switch mode"
			.. "\nSneak + fire: charged shot",
		wield_scale = { x = 2.0, y = 2.0, z = 2.5 },
		inventory_image = gun.image,
		inventory_overlay = "ctf_modebase_special_item.png",
		wield_image = gun.image,
		range = 4,
		groups = {},
		on_use = function(itemstack, user, pointed_thing)
			---@cast user PlayerRef
			return weapons_api.handle_use(user, itemstack, pointed_thing, ROCKET_LAUNCHER, mode)
		end,
		on_secondary_use = function(itemstack, user, pointed_thing)
			---@cast user PlayerRef
			return weapons_api.switch_mode(user, itemstack, ROCKET_LAUNCHER, mode)
		end,
		on_place = function(itemstack, user, pointed_thing)
			---@cast user PlayerRef
			if pointed_thing and pointed_thing.under then
				local node = core.get_node(pointed_thing.under)
				local ndef = core.registered_nodes[node.name]
				if ndef and ndef.on_rightclick then
					return core.item_place(itemstack, user, pointed_thing)
				end
			end
			return weapons_api.switch_mode(user, itemstack, ROCKET_LAUNCHER, mode)
		end,
	})
end

