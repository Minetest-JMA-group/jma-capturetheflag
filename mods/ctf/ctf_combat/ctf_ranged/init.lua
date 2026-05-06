--- @alias HitPoint { type: "object" | "node", under: Vector, intersection_point: Vector,
--- ref: ObjectRef?}
--- @alias RayCast any -- FIXME

local hitstats_exists = core.global_exists("hit_statistics")

local hud = mhud.init()
local shoot_cooldown = ctf_core.init_cooldowns()

--- @alias ScopedThing {
--- item_name: ItemString,
--- wielditem: table,
--- hud: boolean,
--- physics_override: string}

ctf_ranged = {
	--- @type { [PlayerName]: ScopedThing }
	scoped = {},
}

local scoped = ctf_ranged.scoped
local scale_const = 6
local hit_sent = {}
local rico_sent = nil

core.register_craftitem("ctf_ranged:ammo", {
	description = "Ammo\nUsed to reload guns",
	inventory_image = "ctf_ranged_ammo.png",
})

--- @param name PlayerName
local function play_hit_sound(name)
	if not hit_sent[name] then
		hit_sent[name] = true
		core.after(0.6, function()
			hit_sent[name] = nil
		end)
		core.sound_play("ctf_ranged_hit", {
			to_player = name,
		})
	end

	core.sound_play("ctf_ranged_hit", {
		to_player = name,
		pitch = 1.2,
		gain = 0.9,
	}, true)
end

--- @param hitpoint HitPoint
--- @param shooter ObjectRef
--- @param look_dir Vector
--- @param def GunDef
--- @return boolean? True if it is supposed to travel further
local function on_hit_node(hitpoint, shooter, look_dir, def)
	local pos = hitpoint.under
	local node = core.get_node(pos)
	local nodedef = core.registered_nodes[node.name]

	if
		nodedef.on_ranged_shoot
		or nodedef.groups.snappy
		or (nodedef.groups.oddly_breakable_by_hand or 0) >= 3
	then
		if not core.is_protected(pos, shooter:get_player_name()) then
			if hitstats_exists then
				hit_statistics.maybe_record_shot(
					shooter,
					"block_destroyed",
					shooter:get_wielded_item():get_name()
				)
			end
			if nodedef.on_ranged_shoot then
				nodedef.on_ranged_shoot(hitpoint.under, node, shooter, def.type)
			else
				core.dig_node(hitpoint.under)
			end
		elseif hitstats_exists then
			hit_statistics.maybe_record_shot(
				shooter,
				"none",
				shooter:get_wielded_item():get_name()
			)
		end

		if def.type ~= "shotgun" then
			core.add_particlespawner({
				amount = 10,
				time = 0.03,
				minpos = hitpoint.intersection_point,
				maxpos = hitpoint.intersection_point,
				minvel = { x = -4, y = 2, z = -4 },
				maxvel = { x = 4, y = 3, z = 4 },
				minacc = { x = 0, y = -15, z = 0 },
				maxacc = { x = 0, y = -15, z = 0 },
				minexptime = 0.1,
				maxexptime = 0.3,
				minsize = 1,
				maxsize = 2,
				node = { name = nodedef.name },
				collisiondetection = true,
				collision_removal = false,
				glow = 3,
			})
		end
	else
		if nodedef.walkable and nodedef.pointable then
			core.add_particle({
				pos = vector.subtract(
					hitpoint.intersection_point,
					vector.multiply(look_dir, 0.04)
				),
				velocity = vector.zero(),
				acceleration = vector.zero(),
				expirationtime = def.bullethole_lifetime or 3,
				size = 1,
				collisiondetection = false,
				texture = "ctf_ranged_bullethole.png",
			})

			if
				not rico_sent
				or vector.distance(rico_sent, hitpoint.intersection_point) > 10
			then
				if not rico_sent then
					core.after(0.2, function()
						rico_sent = nil
					end)
				end
				rico_sent = hitpoint.intersection_point

				core.sound_play(
					"ctf_ranged_ricochet",
					{ gain = 2.4, pos = hitpoint.intersection_point }
				)
			end

			if def.type ~= "shotgun" then
				core.add_particlespawner({
					amount = 10,
					time = 0.03,
					minpos = hitpoint.intersection_point,
					maxpos = hitpoint.intersection_point,
					minvel = { x = -4, y = 2, z = -4 },
					maxvel = { x = 4, y = 3, z = 4 },
					minacc = { x = 0, y = -15, z = 0 },
					maxacc = { x = 0, y = -15, z = 0 },
					minexptime = 0.2,
					maxexptime = 0.4,
					minsize = 1,
					maxsize = 1,
					node = { name = nodedef.name },
					collisiondetection = true,
					collision_removal = false,
					glow = 14,
				})
			end

			if hitstats_exists then
				hit_statistics.maybe_record_shot(
					shooter,
					"bullethole",
					shooter:get_wielded_item():get_name()
				)
			end
		elseif nodedef.groups.liquid then
			if def.type ~= "shotgun" then
				core.add_particlespawner({
					amount = 10,
					time = 0.1,
					minpos = hitpoint.intersection_point,
					maxpos = hitpoint.intersection_point,
					minvel = { x = look_dir.x * 3, y = 4, z = -look_dir.z * 3 },
					maxvel = { x = look_dir.x * 4, y = 6, z = look_dir.z * 4 },
					minacc = { x = 0, y = -10, z = 0 },
					maxacc = { x = 0, y = -13, z = 0 },
					minexptime = 1,
					maxexptime = 1,
					minsize = 0,
					maxsize = 0,
					collisiondetection = false,
					glow = 3,
					node = { name = nodedef.name },
				})
			end

			if def.liquid_travel_dist then
				return true
				--[[process_ray(
						,
						user,
						look_dir,
						def
					)--]]
			end
		end
	end
end

--- @param hitpoint HitPoint
--- @param shooter ObjectRef?
--- @param gundef GunDef
--- @param look_dir Vector
--- @param amount number
local function change_hp(hitpoint, shooter, gundef, look_dir, amount)
	if hitpoint.type == "object" and hitpoint.ref then
		--- @type ObjectRef
		local ref = hitpoint.ref
		if amount < 0 then
			ref:punch(shooter, 1, {
				full_punch_interval = 1,
				damage_groups = {
					[gundef.type] = 1,
					ranged = 1,
					fleshy = -amount,
				},
			}, look_dir)
		else
			local current_hp = ref:get_hp()
			ref:set_hp(current_hp + amount)
			ctf_combat_mode.add_healer(ref, shooter, 1)
		end
	end
end

--- @type OnHitCallback
local function on_hit(hitpoint, prev_hitpoint, shooter, look_dir, def, callbacks)
	if hitpoint.type == "node" then
		return on_hit_node(hitpoint, shooter, look_dir, def) or false
	end
	if hitpoint.type == "object" and hitpoint.ref then
		local ref = hitpoint.ref
		local victim_name = ref:get_player_name()

		local is_friend = ctf_teams.get(victim_name)
			== ctf_teams.get(shooter:get_player_name())

		if hitstats_exists then
			if is_friend then
				hit_statistics.maybe_record_shot(
					shooter,
					"teammate",
					shooter:get_wielded_item():get_name()
				)
			else
				hit_statistics.maybe_record_shot(
					shooter,
					"enemy",
					shooter:get_wielded_item():get_name()
				)
			end
		end
		local ret_val = nil
		if is_friend then
			ret_val =
				callbacks.on_teammate_hit(hitpoint, prev_hitpoint, shooter, look_dir, def)
		else
			ret_val =
				callbacks.on_enemy_hit(hitpoint, prev_hitpoint, shooter, look_dir, def)
		end
		play_hit_sound(shooter:get_player_name())
		return ret_val
	end
end

-- Can be overridden for custom behaviour
---@diagnostic disable-next-line: duplicate-set-field
--- @param player ObjectRef
--- @param name PlayerName
function ctf_ranged.can_use_gun(player, name)
	return true
end

--- @alias ItemString string
--- @alias Bullet {
--- texture: string,
--- glow: number,
--- spread: number?,
--- particle_speed: number? }
--- @alias OnHitCallbacks { on_teammate_hit: OnHitCallback, on_enemy_hit: OnHitCallback }
--- @alias OnHitCallback fun(hitpoint: HitPoint, prev_hitpoint: HitPoint?, shooter: ObjectRef, look_dir: Vector, def: GunDef, callbacks: OnHitCallbacks?): boolean
--- @alias OnUseCallback fun(bulletcast: any, shooter: ObjectRef, look_dir: Vector, def: GunDef)
--- @alias GunDef {
--- ammo: ItemString,
--- texture: string,
--- description: string,
--- bullethole_lifetime: number?,
--- type: string,
--- tier: number,
--- rounds: number,
--- texture_overlay: string,
--- wield_texture: string?,
--- on_use: fun(player: ObjectRef),
--- on_secondary_use: fun(player: ObjectRef),
---	fire_interval: number,
---	fire_sound: string,
---	range: number,
---	bullet: Bullet,
---	automatic: boolean?,
---	rightclick_func: fun(itemstack: string, user: ObjectRef, Pointed: any, ...),
---	liquid_travel_dist: number?,
--- on_use:  OnUseCallback}

--- @param name string
--- @param def GunDef
function ctf_ranged.simple_register_gun(name, def)
	core.register_tool(rawf.also_register_loaded_tool(name, {
		description = def.description,
		inventory_image = def.texture .. "^[colorize:#F44:42",
		ammo = def.ammo or "ctf_ranged:ammo",
		rounds = def.rounds,
		_g_category = def.type,
		groups = {
			ranged = 1,
			[def.type] = 1,
			tier = def.tier or 1,
			not_in_creative_inventory = 1,
		},
		on_use = function(itemstack, user)
			if not ctf_ranged.can_use_gun(user, name) then
				core.sound_play("ctf_ranged_click", { pos = user:get_pos() }, true)
				return
			end

			local result = rawf.load_weapon(itemstack, user:get_inventory())

			if result:get_name() == itemstack:get_name() then
				core.sound_play("ctf_ranged_click", { pos = user:get_pos() }, true)
			else
				core.sound_play("ctf_ranged_reload", { pos = user:get_pos() }, true)
			end

			return result
		end,
	}, function(loaded_def)
		loaded_def.description = def.description .. " (Loaded)"
		loaded_def.inventory_image = def.texture
		loaded_def.inventory_overlay = def.texture_overlay
		loaded_def.wield_image = def.wield_texture or def.texture
		loaded_def.groups.not_in_creative_inventory = nil
		loaded_def.on_secondary_use = def.on_secondary_use
		loaded_def.on_use = function(itemstack, user)
			if not ctf_ranged.can_use_gun(user, name) then
				core.sound_play("ctf_ranged_click", { pos = user:get_pos() }, true)
				return
			end

			if shoot_cooldown:get(user) then
				return
			end

			if def.automatic then
				if not rawf.enable_automatic(def.fire_interval, itemstack, user) then
					return
				end
			else
				shoot_cooldown:set(user, def.fire_interval)
			end

			local spawnpos, look_dir = rawf.get_bullet_start_data(user)
			local endpos = vector.add(spawnpos, vector.multiply(look_dir, def.range))
			local rays

			if type(def.bullet) == "table" then
				def.bullet.texture = "ctf_ranged_bullet.png^[colorize:#FFDB4C:255"
				def.bullet.glow = 14
			else
				def.bullet = {
					texture = "ctf_ranged_bullet.png^[colorize:#FFDB4C:255",
					glow = 14,
				}
			end

			if not def.bullet.spread then
				rays = { rawf.bulletcast(def.bullet, spawnpos, endpos, true, true) }
			else
				rays = rawf.spread_bulletcast(def.bullet, spawnpos, endpos, true, true)
			end

			core.sound_play(def.fire_sound, { pos = user:get_pos() }, true)
			def.on_use(rays, user, look_dir, def)

			if def.rounds > 0 then
				return rawf.unload_weapon(itemstack)
			end
		end

		if def.rightclick_func then
			loaded_def.on_place = function(itemstack, user, pointed, ...)
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

			loaded_def.on_secondary_use = def.rightclick_func
		end
	end))
end

core.register_on_leaveplayer(function(player)
	scoped[player:get_player_name()] = nil
end)

function ctf_ranged.show_scope(name, item_name, fov_mult)
	local player = core.get_player_by_name(name)
	if not player then
		return
	end

	scoped[name] = {
		item_name = item_name,
		wielditem = player:hud_get_flags().wielditem,
		hud = true,
		physics_override = "ctf_ranged:scoping",
	}

	hud:add(player, "ctf_ranged:scope", {
		type = "image",
		position = { x = 0.5, y = 0.5 },
		text = "ctf_ranged_rifle_crosshair.png",
		scale = { x = scale_const, y = scale_const },
		alignment = { x = "center", y = "center" },
	})

	player:set_fov(1 / fov_mult, true)
	physics.set(name, "ctf_ranged:scoping", { speed = 0.1, jump = 0 })
	player:hud_set_flags({ wielditem = false })
end

function ctf_ranged.show_shoulder_scope(name, item_name, fov_mult)
	local player = core.get_player_by_name(name)
	if not player then
		return
	end
	local item_range = core.registered_items[item_name].range or 4
	local pos = player:get_pos()
	local ray = core.raycast(pos, vector.add(pos, item_range), true)
	for pointed_thing in ray do
		local ppos = nil
		if pointed_thing.type == "node" then
			ppos = pointed_thing.under
		elseif pointed_thing.type == "object" then
			ppos = pointed_thing.ref:get_pos()
		end
		if not ppos then
			if vector.dist(pos, ppos) <= item_range then
				return
			else
				break
			end
		end
	end

	scoped[name] = {
		item_name = item_name,
		wielditem = player:hud_get_flags().wielditem,
		hud = false,
		physics_override = "ctf_ranged:shoulder_scoping",
	}

	player:set_fov(1 / fov_mult, true)
	physics.set(name, "ctf_ranged:shoulder_scoping", { speed = 0.5, jump = 0.5 })
end

function ctf_ranged.hide_scope(name)
	local player = core.get_player_by_name(name)
	if not player then
		return
	end

	if scoped[name].hud then
		hud:remove(name, "ctf_ranged:scope")
	end
	player:set_fov(0)
	physics.remove(name, scoped[name].physics_override)
	player:hud_set_flags({ wielditem = scoped[name].wielditem })
	scoped[name] = nil
end

function ctf_ranged.chain_callbacks(...)
	--- @param hitpoint HitPoint
	--- @param shooter ObjectRef?
	local function callback(hitpoint, shooter)
		for _, callback2 in ipairs(arg) do
			callback2(hitpoint, shooter)
		end
	end
	return callback
end
--- @param hitpoint HitPoint
--- @param shooter ObjectRef?
--- @param gundef GunDef
--- @param look_dir Vector
function ctf_ranged.count_heal_for_meat_shield(hitpoint, shooter, gundef, look_dir) end

--- @param damage number
function ctf_ranged.on_damage_gun_use(damage)
	--- @type OnUseCallback
	local function on_damage_callback_inner(rays, shooter, look_dir, def)
		local callbacks = {
			--- @type OnHitCallback
			on_teammate_hit = function(
				hitpoint,
				prev_hitpoint,
				shooter,
				look_dir,
				def,
				_
			)
			end,
			--- @type OnHitCallback
			on_enemy_hit = function(hitpoint, prev_hitpoint, shooter, look_dir, def, _)
				counter = counter + 1
				change_hp(hitpoint, shooter, def, look_dir, -damage)
			end,
		}
		--- @type HitPoint?
		local prev_hitpoint = nil
		while #rays > 0 do
			local ray = table.remove(rays)
			local hitpoint = ray:hit_object_or_node({
				node = function(ndef)
					return (ndef.walkable and ndef.pointable) or ndef.groups.liquid
				end,
				object = function(obj)
					return obj:is_player() and obj ~= shooter
				end,
			})
			if
				hitpoint
				and on_hit(hitpoint, prev_hitpoint, shooter, look_dir, def, callbacks)
			then
				if hitpoint.type == "node" then
					local bulletcast = rawf.bulletcast(
						def.bullet,
						hitpoint.intersection_point,
						vector.add(
							hitpoint.intersection_point,
							vector.multiply(look_dir, def.liquid_travel_dist)
						),
						true,
						false
					)
					table.insert(rays, bulletcast)
				end
			end
			prev_hitpoint = hitpoint
		end
	end
	return on_damage_callback_inner
end

ctf_ranged.simple_register_gun("ctf_ranged:pistol", {
	type = "pistol",
	description = "Pistol\nDmg: 2 | FR: 0.6s | Mag: 75",
	texture = "ctf_ranged_pistol.png",
	fire_sound = "ctf_ranged_pistol",
	rounds = 75,
	range = 75,
	automatic = true,
	fire_interval = 0.6,
	liquid_travel_dist = 2,
	rightclick_func = function(itemstack, user, pointed, ...)
		if scoped[user:get_player_name()] then
			ctf_ranged.hide_scope(user:get_player_name())
		else
			local item_name = itemstack:get_name()
			ctf_ranged.show_shoulder_scope(user:get_player_name(), item_name, 2)
		end
	end,
	on_use = ctf_ranged.on_damage_gun_use(2),
})

ctf_ranged.simple_register_gun("ctf_ranged:rifle", {
	type = "rifle",
	description = "Rifle\nDmg: 1 | FR: 0.8s | Mag: 40",
	texture = "ctf_ranged_rifle.png",
	fire_sound = "ctf_ranged_rifle",
	rounds = 40,
	range = 150,
	on_use = ctf_ranged.on_damage_gun_use(4),
	automatic = true,
	fire_interval = 0.8,
	liquid_travel_dist = 4,
})

ctf_ranged.simple_register_gun("ctf_ranged:shotgun", {
	type = "shotgun",
	description = "Shotgun\nDmg: 1x28 | FR: 2s | Mag: 10",
	texture = "ctf_ranged_shotgun.png",
	fire_sound = "ctf_ranged_shotgun",
	bullet = {
		amount = 28,
		spread = 4,
	},
	rounds = 10,
	range = 24,
	on_use = ctf_ranged.on_damage_gun_use(1),
	fire_interval = 2,
})

ctf_ranged.simple_register_gun("ctf_ranged:assault_rifle", {
	type = "smg",
	description = "Assault Rifle\nDmg: 2 | FR: 0.1s | Mag: 35",
	texture = "ctf_ranged_assault_rifle.png",
	fire_sound = "ctf_ranged_assault_rifle",
	bullet = {
		spread = 1.5,
	},
	automatic = true,
	rounds = 35,
	range = 89,
	on_use = ctf_ranged.on_damage_gun_use(2),
	fire_interval = 0.1,
	liquid_travel_dist = 3,
	rightclick_func = function(itemstack, user, pointed, ...)
		if scoped[user:get_player_name()] then
			ctf_ranged.hide_scope(user:get_player_name())
		else
			local item_name = itemstack:get_name()
			ctf_ranged.show_shoulder_scope(user:get_player_name(), item_name, 2)
		end
	end,
})

ctf_ranged.simple_register_gun("ctf_ranged:sniper", {
	type = "sniper",
	description = "Sniper rifle\nDmg: 12 | FR: 2s | Mag: 25",
	texture = "ctf_ranged_sniper_rifle.png",
	fire_sound = "ctf_ranged_sniper",
	rounds = 25,
	range = 300,
	on_use = ctf_ranged.on_damage_gun_use(12),
	fire_interval = 2,
	liquid_travel_dist = 10,
	rightclick_func = function(itemstack, user, pointed, ...)
		if scoped[user:get_player_name()] then
			ctf_ranged.hide_scope(user:get_player_name())
		else
			local item_name = itemstack:get_name()
			ctf_ranged.show_scope(user:get_player_name(), item_name, 4)
		end
	end,
})

ctf_ranged.simple_register_gun("ctf_ranged:sniper_magnum", {
	type = "sniper",
	description = "Magnum sniper rifle\nDmg: 16 | FR: 2s | Mag: 20",
	texture = "ctf_ranged_sniper_rifle_magnum.png",
	fire_sound = "ctf_ranged_sniper",
	rounds = 20,
	range = 400,
	on_use = ctf_ranged.on_damage_gun_use(16),
	fire_interval = 2,
	liquid_travel_dist = 15,
	rightclick_func = function(itemstack, user, pointed, ...)
		if scoped[user:get_player_name()] then
			ctf_ranged.hide_scope(user:get_player_name())
		else
			local item_name = itemstack:get_name()
			ctf_ranged.show_scope(user:get_player_name(), item_name, 8)
		end
	end,
})

------------------
-- Scope-check --
------------------

-- Hide scope if currently wielded item is not the same item
-- player wielded when scoping

local time = 0
core.register_globalstep(function(dtime)
	time = time + dtime
	if time < 1 then
		return
	end

	time = 0
	for name, info in pairs(scoped) do
		local player = core.get_player_by_name(name)
		---@cast player PlayerRef
		local wielded_item = player:get_wielded_item():get_name()
		if wielded_item ~= info.item_name then
			ctf_ranged.hide_scope(name)
		end
	end
end)
