local weapons_api = ctf_mode_chaos.weapons_api
local LAUNCHER = weapons_api.LAUNCHER

weapons_api.register_gun(LAUNCHER, "frag", {
	description = "Grenade Launcher",
	image = "ctf_mode_chaos_grenade_launcher.png",
	type = "grenade",
	grenade = "frag",
	ammo = "ctf_mode_chaos:power_charge",
	ammo_label = "power charges",
	cost = 1,
	charged_cost = 3,
	cooldown = 0.35,
	recoil = 4,
	charged_recoil = 10,
	speed = 15,
	charged_speed = 30,
	radius = 1,
	charged_radius = 4,
	max_lifetime = 3,
	on_use_sound = "ctf_mode_chaos_grenade_launcher_plop",
	damage_modifier = 0.7,
})

weapons_api.register_gun(LAUNCHER, "bouncy", {
	description = "Bouncy Launcher",
	image = "ctf_mode_chaos_grenade_launcher.png^[colorize:#00d7ff:120",
	type = "grenade",
	grenade = "bouncy",
	ammo = "ctf_mode_chaos:power_charge",
	ammo_label = "power charges",
	cost = 1,
	charged_cost = 2,
	cooldown = 0.4,
	recoil = 4,
	charged_recoil = 7,
	speed = 19,
	charged_speed = 28,
	radius = 2,
    charged_radius = 3,
	max_lifetime = 5,
	on_use_sound = "ctf_mode_chaos_grenade_launcher_plop",
	damage_modifier = 0.7,
})

weapons_api.register_gun(LAUNCHER, "cluster", {
	description = "Cluster Launcher",
	image = "ctf_mode_chaos_grenade_launcher.png^[colorize:#ffd700:120",
	type = "grenade",
	grenade = "cluster",
	ammo = "ctf_mode_chaos:power_charge",
	ammo_label = "power charges",
	cost = 1,
	charged_cost = 2,
	cooldown = 0.5,
	recoil = 3,
	charged_recoil = 9,
	speed = 16,
	charged_speed = 26,
	radius = 2,
	charged_radius = 2,
	mini_count = 5,
	charged_mini_count = 8,
	max_lifetime = 3.5,
	on_use_sound = "ctf_mode_chaos_grenade_launcher_plop",
	damage_modifier = 1,
})

weapons_api.register_gun(LAUNCHER, "sticky", {
	description = "Sticky Launcher",
	image = "ctf_mode_chaos_grenade_launcher.png^[colorize:#aa66cc:120",
	type = "grenade",
	grenade = "sticky",
	ammo = "ctf_mode_chaos:power_charge",
	ammo_label = "power charges",
	cost = 1,
	charged_cost = 2,
	cooldown = 1,
	recoil = 4,
	charged_recoil = 7,
	speed = 18,
	charged_speed = 28,
	radius = 2,
	charged_radius = 3,
	arm_time = 0.6,
	trigger_radius = 2.5,
	charged_trigger_radius = 3.5,
	max_lifetime = 20,
	on_use_sound = "ctf_mode_chaos_grenade_launcher_plop",
	damage_modifier = 1.2,
})

ctf_mode_chaos.register_weapon_template({
	id = LAUNCHER,
	description = "Grenade Launcher",
	mode_order = { "frag", "bouncy", "cluster", "sticky" },
	item_prefix = "ctf_mode_chaos:mod",
	on_use_sound = "ctf_mode_chaos_grenade_launcher_plop",
	is_weapon_item = function(itemname)
		return itemname:match("^ctf_mode_chaos:grenade_launcher_") ~= nil
	end,
	param_defs = {
		fast_reload = weapons_api.PARAM_fast_reload,
		propellant = weapons_api.PARAM_PROPELLANT,
		big_bang = weapons_api.PARAM_BIG_BANG,
		stabilizer = weapons_api.PARAM_STABILIZER,
		charger = weapons_api.PARAM_CHARGER,
	},
	mode_mods = {
		bouncy = {
			description = "Bouncy Rounds",
			weight = 10,
			icon = "ctf_mode_chaos_grenade.png^[colorize:#00d7ff:200",
		},
		cluster = {
			description = "Cluster Rounds",
			weight = 8,
			icon = "ctf_mode_chaos_grenade.png^[colorize:#ffd700:200",
		},
		sticky = {
			description = "Sticky Rounds",
			weight = 8,
			icon = "ctf_mode_chaos_grenade.png^[colorize:#aa66cc:200",
		},
	},
})

core.register_craftitem("ctf_mode_chaos:power_charge", {
	description = "Grenade Power Charge\nAmmo for grenade modes of the Grenade Launcher",
	inventory_image = "ctf_mode_chaos_power_charge.png",
})

local function explode(self, pos)
	local gtype = self.gtype or "frag"
	local pname = self.puncher_name
	local radius = self.radius or 1

	if not weapons_api.can_explode(pos, pname, radius) then
		return
	end

	if gtype == "cluster" then
		tnt.boom(pos, {
			puncher_name = pname,
			radius = 1,
			damage_modifier = self.damage_modifier or 1.2,
			damage_multiplier = self.damage_multiplier or 1,
			knockback_multiplier = self.knockback or 1,
		})
		local count = self.mini_count or 5
		for _ = 1, count do
			local mpos = vector.offset(
				pos,
				math.random(-2, 2) / 10,
				math.random(0, 4) / 10,
				math.random(-2, 2) / 10
			)
			local mobj = core.add_entity(mpos, "ctf_mode_chaos:mini_grenade")
			if mobj then
				local ment = mobj:get_luaentity()
				ment.puncher_name = pname
				ment.radius = 1
				ment.damage_multiplier = self.damage_multiplier or 1
				ment.knockback = self.knockback or 1
				local dir = vector.new(
					math.random() * 2 - 1,
					math.random() * 0.8 + 0.4,
					math.random() * 2 - 1
				)
				mobj:set_velocity(vector.multiply(dir, 7))
			end
		end
	else
		tnt.boom(pos, {
			puncher_name = pname,
			radius = radius,
			damage_modifier = self.damage_modifier or 1.5,
			damage_multiplier = self.damage_multiplier or 1,
			knockback_multiplier = self.knockback or 1,
		})
	end
end

-- Point-blank shots (impact less than this many nodes from where the grenade
-- spawned) ricochet off solid nodes instead of exploding/sticking, so firing
-- into a wall at close range can't blow the shooter up.
local POINT_BLANK_DISTANCE = 1.5
local MAX_RICOCHETS = 5

local function is_point_blank(self, pos)
	local start = self.start_pos
	return start and vector.distance(start, pos) < POINT_BLANK_DISTANCE
end

local function hit_solid(moveresult)
	local collision = moveresult.collisions and moveresult.collisions[1]
	return collision and collision.type == "node"
end

local function ricochet(self, obj, moveresult)
	local vel = obj:get_velocity()
	local collision = moveresult.collisions and moveresult.collisions[1]
	if not vel or not collision then
		return
	end
	local axis = collision.axis
	local incoming = self.last_vel and self.last_vel[axis] or vel[axis]
	vel[axis] = -incoming * 0.8
	obj:set_velocity(vel)
	core.sound_play("grenades_glasslike_break", {
		pos = obj:get_pos(),
		gain = 0.6,
		max_hear_distance = 10,
	}, true)
	self.ricochets = self.ricochets + 1
	if self.ricochets > MAX_RICOCHETS then
		explode(self, obj:get_pos())
		obj:remove()
	end
end

local function handle_entity_timer(self, dtime)
	if self.timer > (self.max_lifetime or 5) then
		explode(self, self.object:get_pos())
		self.object:remove()
	end
end

core.register_entity("ctf_mode_chaos:grenade", {
	initial_properties = {
		visual = "sprite",
		visual_size = { x = 0.7, y = 0.7 },
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
		self.start_pos = self.object:get_pos()
		self.ricochets = 0 -- Count of ricochets off solid nodes
	end,
	on_step = function(self, dtime, moveresult)
		self.timer = self.timer + dtime
		local obj = self.object
		local pos = obj:get_pos()
		if not pos then
			return
		end

		local gtype = self.gtype or "frag"

		if gtype == "bouncy" then
			if moveresult.collides then
				ricochet(self, obj, moveresult)
			end

			handle_entity_timer(self, dtime)
			weapons_api.apply_gravity(self, dtime)
			return
		end

		if gtype == "sticky" then
			if not self.stuck then
				if moveresult.collides then
					-- Point-blank hits on solid nodes ricochet instead of
					-- sticking, so the shooter can't get stuck at close range
					if hit_solid(moveresult) and is_point_blank(self, pos) then
						ricochet(self, obj, moveresult)
					else
						self.stuck = true
						obj:set_velocity(vector.zero())
						obj:set_acceleration(vector.zero())
					end
				end
				if not self.stuck then
					weapons_api.apply_gravity(self, dtime)
				end
			elseif self.timer >= (self.arm_time or 0.6) then
				for _, v in
				ipairs(core.get_objects_inside_radius(pos, self.trigger_radius or 3))
				do
					if
						v:is_player()
						and v:get_hp() > 0
						and v:get_properties().pointable
						and weapons_api.can_hit(self.puncher_name, v:get_player_name())
					then
						explode(self, pos)
						obj:remove()
						return
					end
				end
			end
		else
			if moveresult.collides then
				if hit_solid(moveresult) and is_point_blank(self, pos) then
					ricochet(self, obj, moveresult)
				else
					explode(self, pos)
					obj:remove()
					return
				end
			end
		end

		handle_entity_timer(self, dtime)
		weapons_api.apply_gravity(self, dtime)
	end,
})


core.register_entity("ctf_mode_chaos:mini_grenade", {
	initial_properties = {
		visual = "sprite",
		visual_size = { x = 0.5, y = 0.5 },
		textures = { "ctf_mode_chaos_grenade.png^[multiply:yellow:100" },
		physical = true,
		makes_footstep_sound = false,
		backface_culling = false,
		static_save = false,
		pointable = false,
		collide_with_objects = true,
		collisionbox = { -0.15, -0.15, -0.15, 0.15, 0.15, 0.15 },
	},
	timer = 0,
	on_step = function(self, dtime, moveresult)
		self.timer = self.timer + dtime
		local pos = self.object:get_pos()
		if not pos then
			return
		end

		if moveresult.collides then
			if weapons_api.can_explode(pos, self.puncher_name, self.radius or 1) then
				tnt.boom(pos, {
					puncher_name = self.puncher_name,
					radius = self.radius or 1,
					damage_modifier = self.damage_modifier or 1.2,
					damage_multiplier = self.damage_multiplier or 1,
					knockback_multiplier = self.knockback or 1,
				})
			end
			self.object:remove()
			return
		end

		if self.timer > 5 then
			self.object:remove()
			return
		end

		local vel = self.object:get_velocity()
		if vel then
			vel.y = vel.y - 9 * dtime
			self.object:set_velocity(vel)
		end
	end,
})

for mode, gun in pairs(weapons_api.guns) do
	core.register_tool("ctf_mode_chaos:grenade_launcher_" .. mode, {
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
			return weapons_api.handle_use(user, itemstack, pointed_thing, LAUNCHER, mode)
		end,
		on_secondary_use = function(itemstack, user, pointed_thing)
			---@cast user PlayerRef
			return weapons_api.switch_mode(user, itemstack, LAUNCHER, mode)
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
			return weapons_api.switch_mode(user, itemstack, LAUNCHER, mode)
		end,
	})
end
