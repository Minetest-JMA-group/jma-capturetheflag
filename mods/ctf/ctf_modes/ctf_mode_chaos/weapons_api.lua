local api = {}

-- Weapon ids (must match the ids used in ctf_mode_chaos.register_weapon_template)
api.LAUNCHER = "launcher"
api.ROCKET_LAUNCHER = "rocket_launcher"

-- Mode switch cooldown shared by the multi-mode weapons
api.SWITCH_COOLDOWN = 0.5
api.switch_cooldown = ctf_core.init_cooldowns()
local SAFE_RADIUS = 3

-- Charged shots (ALT + fire) deal this much more damage/knockback than a
-- normal shot. The wider blast radius is compensated by per-shot multipliers
-- computed in fire_grenade_mode, so the net effect stays at this bonus.
local CHARGED_BONUS = 1.15

-- Gun definitions, one table per weapon
api.guns = {}
api.rocket_guns = {}

-- Item name prefix of each weapon's mode items (the tool items, not the mod
-- items). The launcher and the rocket launcher get one item per mode.
api.tool_prefixes = {
	[api.LAUNCHER] = "ctf_mode_chaos:grenade_launcher_",
	[api.ROCKET_LAUNCHER] = "ctf_mode_chaos:rocket_launcher_",
}

-- Shared modifier param definitions. A weapon lists a param to grant its
-- effect. Params marked shared = true become a single mod item shared by all
-- weapons listing them (e.g. ctf_mode_chaos:fast_reload); using it opens a
-- formspec to pick which owned weapon to install the upgrade on. The rest get
-- a per-weapon mod item set via the weapon's item prefix.
api.PARAM_fast_reload = {
	description = "Fast-Loader",
	max_level = 3,
	weight = 14,
	shared = true,
	icon = "ctf_mode_chaos_fast_reload.png",
}
api.PARAM_PROPELLANT = {
	description = "Propellant",
	max_level = 3,
	weight = 14,
	shared = true,
	icon = "ctf_ranged_bullet.png^[colorize:#ffa500:200",
}
api.PARAM_BIG_BANG = {
	description = "Big Bang",
	max_level = 3,
	weight = 12,
	shared = true,
	icon = "ctf_mode_chaos_big_bang.png",
}
api.PARAM_STABILIZER = {
	description = "Stabilizer",
	max_level = 3,
	weight = 12,
	shared = true,
	icon = "ctf_mode_chaos_grenade_launcher.png^[colorize:#00ff88:150",
}
api.PARAM_CHARGER = {
	description = "Charger",
	max_level = 1,
	weight = 10,
	shared = true,
	icon = "ctf_mode_chaos_grenade.png^[colorize:#ff6600:180",
}

-- Registers a gun mode for a weapon.
function api.register_gun(weapon_id, mode, def)
	if weapon_id == api.LAUNCHER then
		api.guns[mode] = def
	elseif weapon_id == api.ROCKET_LAUNCHER then
		api.rocket_guns[mode] = def
	else
		return false
	end
	return true
end

-- Returns the gun definition of a mode, resolved through the weapon id.
function api.get_gun(weapon_id, mode)
	if weapon_id == api.LAUNCHER then
		return api.guns[mode]
	end
	if weapon_id == api.ROCKET_LAUNCHER then
		return api.rocket_guns[mode]
	end
	return nil
end

-- Can pname hurt vname? (different teams, or both in Elysium)
function api.can_hit(pname, vname)
	if pname == vname then
		return false
	end
	local pteam = ctf_teams.get(pname)
	local vteam = ctf_teams.get(vname)
	if pteam and vteam then
		return pteam ~= vteam
	end
	if ctf_jma_elysium and ctf_jma_elysium.get_player then
		return ctf_jma_elysium.get_player(pname)
			and ctf_jma_elysium.get_player(vname)
	end
	return false
end

-- Can an explosion happen here? (spawn protection + flag proximity)
function api.can_explode(pos, pname, radius)
	if not pos or core.is_protected(pos, "") then
		return false
	end

	local pteam = pname and ctf_teams.get(pname)

	if pteam then
		for flagteam, team in pairs(ctf_map.current_map.teams) do
			if not ctf_modebase.flag_captured[flagteam] and team.flag_pos then
				local distance_from_flag = vector.distance(pos, team.flag_pos)
				if distance_from_flag <= radius + SAFE_RADIUS then
					return false
				end
			end
		end
	end
	return true
end

function api.apply_gravity(self, dtime)
	local vel = self.object:get_velocity()
	if vel then
		vel.y = vel.y - 9 * dtime
		self.object:set_velocity(vel)
		self.last_vel = vel
	end
end

-- Grenade sprite tints per grenade type (Grenade Launcher modes)
api.grenade_textures = {
	frag = "ctf_mode_chaos_grenade.png^[multiply:black:100",
	bouncy = "ctf_mode_chaos_grenade.png^[multiply:cyan:100",
	cluster = "ctf_mode_chaos_grenade.png^[multiply:yellow:100",
	sticky = "ctf_mode_chaos_grenade.png^[multiply:purple:100",
}


local WEAR_MAX = 65534

-- Restores the wear of a launcher when its cooldown timer is cancelled
-- (death, match end, ...).
local function reset_gun_cooldown(pname, item_id)
	local player = core.get_player_by_name(pname)
	if not player then
		return
	end
	local inv = player:get_inventory()
	if not inv then
		return
	end
	local pos, stack = ctf_modebase.update_wear.find_item_by_id(inv, item_id)
	if pos then
		stack:set_wear(0)
		inv:set_stack("main", pos, stack)
	end
end

-- Starts the cooldown of a just-fired launcher. The wear is spread over whole
-- ticks so short cooldowns stay accurate.
function api.start_gun_cooldown(pname, itemstack, cd)
	local ticks = math.max(1, math.ceil(cd))
	local step = math.floor(WEAR_MAX / ticks)
	itemstack:set_wear(step * ticks)
	ctf_modebase.update_wear.start_update(
		pname,
		itemstack,
		step,
		true, -- the wear counts down to 0, which ends the cooldown
		nil,
		function(item_id)
			reset_gun_cooldown(pname, item_id)
		end,
		cd / ticks
	)
end

function api.is_gun_on_cooldown(pname, itemstack)
	local wear = itemstack:get_wear()
	if wear == 0 then
		return false
	end
	local item_id = itemstack:get_meta():get_string("update_wear_id")
	if item_id ~= "" and ctf_modebase.update_wear.is_item_updating(pname, item_id) then
		return true
	end
	itemstack:set_wear(0)
	return false
end

local function is_solid(pos)
    local node = core.get_node(pos)
    local node_def = core.registered_nodes[node.name]
    if node_def.walkable then
        return true
    end
    return false
end

-- Throttled hint telling the player that charged shots need the Charger mod.
local charger_hint_timers = {}
local function hint_no_charger(pname)
	if not charger_hint_timers[pname] or charger_hint_timers[pname] < os.time() then
		charger_hint_timers[pname] = os.time() + 5
		hud_events.new(pname, {
			text = "Sneak + fire needs the Charger mod!",
			quick = true,
		})
	end
end

function api.fire_grenade_mode(user, itemstack, gun, mode, weapon_id)
	local pname = user:get_player_name()
	local inv = user:get_inventory()

	local is_sneaking = user:get_player_control().sneak
	local charged = false
	local cost = gun.cost

	-- Charged shots (Sneak + fire) are unlocked by the shared "Charger" mod
	if is_sneaking and gun.charged_cost then
		if ctf_mode_chaos.param_level(user, weapon_id, "charger") > 0 then
			cost = gun.charged_cost
			charged = true
		else
			hint_no_charger(pname)
		end
	end

	local ammo_needed = ItemStack(gun.ammo .. " " .. cost)
	if not inv:contains_item("main", ammo_needed) then
		if charged then
			-- Fall back to a normal shot if we can't afford a charged one
			charged = false
			cost = gun.cost
			ammo_needed = ItemStack(gun.ammo .. " " .. cost)
			if not inv:contains_item("main", ammo_needed) then
				hud_events.new(pname, {
					text = "No " .. gun.ammo_label .. "!",
					quick = true,
				})
				return
			end
		else
			hud_events.new(pname, {
				text = "No " .. gun.ammo_label .. "!",
				quick = true,
			})
			return
		end
	end
	inv:remove_item("main", ammo_needed)

	local pos = user:get_pos()
	local dir = user:get_look_dir()
	if pos and dir then
		pos.y = pos.y + 1.5
		local ahead = vector.add(pos, vector.multiply(dir, 1))
		if is_solid(ahead) then
			return
		end
		if gun.grenade == "rain" then
			-- "Rain" volley: many small rockets in a spread cone
			local count = gun.mini_count or 8
			local spread = gun.spread or 0.12
			local mspeed = (gun.speed or 40)
				* (1 + ctf_mode_chaos.param_level(user, weapon_id, "propellant") * 0.2)
			for _ = 1, count do
				local mdir = vector.normalize(vector.new(
					dir.x + math.random() * spread * 2 - spread,
					dir.y + math.random() * spread * 2 - spread,
					dir.z + math.random() * spread * 2 - spread
				))
				-- Small random offsets so the rockets don't spawn inside each other
				local mpos = vector.offset(ahead,
					math.random(-2, 2) / 10,
					math.random(-2, 2) / 10,
					math.random(-2, 2) / 10
				)
				local mobj = core.add_entity(mpos, "ctf_mode_chaos:mini_rocket")
				if mobj then
					local ment = mobj:get_luaentity()
					ment.puncher_name = pname
					ment.disable_destruction = gun.disable_destruction
					mobj:set_velocity(vector.multiply(mdir, mspeed))
				end
			end
		else
			local is_rocket = gun.grenade == "rocket"
			local obj = core.add_entity(
				ahead,
				is_rocket and "ctf_mode_chaos:rocket" or "ctf_mode_chaos:grenade"
			)
			if obj then
				local ent = obj:get_luaentity()
				ent.puncher_name = pname
				ent.gtype = gun.grenade or "frag"

				local speed = gun.speed or 18
				local radius = gun.radius or 2
				if charged then
					speed = gun.charged_speed or speed
					radius = gun.charged_radius or radius
				end
				speed = speed * (1 + ctf_mode_chaos.param_level(user, weapon_id, "propellant") * 0.2)
				radius = radius * (1 + ctf_mode_chaos.param_level(user, weapon_id, "big_bang") * 0.25)

				ent.radius = radius
				ent.max_lifetime = gun.max_lifetime
				ent.arm_time = gun.arm_time
				ent.trigger_radius = (charged and gun.charged_trigger_radius) or gun.trigger_radius
				ent.mini_count = (charged and gun.charged_mini_count) or gun.mini_count
				ent.damage_modifier = (charged and gun.charged_damage_modifier) or
				gun.damage_modifier

				-- Charged shots have a wider blast radius; the multipliers
				-- compensate it so damage/knockback stay only slightly above a
				-- normal shot (+CHARGED_BONUS instead of scaling with radius).
				ent.damage_multiplier = 1
				ent.knockback = 1
				if charged then
					local base_radius = gun.radius or 1
					local blast_radius = gun.charged_radius or base_radius
					local base_damage = base_radius + (gun.damage_modifier or 0)
					local blast_damage = blast_radius + (gun.damage_modifier or 0)
					ent.damage_multiplier = (base_damage / blast_damage) * CHARGED_BONUS
					ent.knockback = (base_radius / blast_radius) * CHARGED_BONUS
				end

				-- Optional per-gun terrain settings (rocket launcher): the crater
				-- radius is decoupled from the damage radius and destruction can
				-- be disabled entirely. Falls back to the damage radius / on.
				local destruction_radius = gun.destruction_radius
				if charged and gun.charged_destruction_radius then
					destruction_radius = gun.charged_destruction_radius
				end
				ent.destruction_radius = destruction_radius
				ent.disable_destruction = gun.disable_destruction

				if is_rocket then
					local pitch = user:get_look_vertical()
					obj:set_velocity(vector.multiply(dir, speed))
					obj:set_acceleration({ x = 0, y = -1, z = 0 })
					obj:set_rotation({ x = -pitch, y = 0, z = 0 })
				else
					local player_speed = vector.length(user:get_velocity())
					obj:add_velocity(vector.multiply(dir, speed + player_speed))
					local texture = api.grenade_textures[ent.gtype]
					if texture then
						obj:set_properties({ textures = { texture } })
					end
				end

				if charged then
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
				end
			end
		end
	end

	core.sound_play(gun.on_use_sound or "tnt_ignite", {
		to_player = pname,
		gain = 0.5,
		pitch = charged and 0.5 or 1.1,
	})

	if dir then
		local recoil = gun.recoil or 5
		if charged then
			recoil = gun.charged_recoil or recoil
		end
		recoil = recoil * (1 - ctf_mode_chaos.param_level(user, weapon_id, "stabilizer") * 0.25)
		user:add_velocity(vector.multiply(dir, -recoil))
	end

	local cd = gun.cooldown * (1 - ctf_mode_chaos.param_level(user, weapon_id, "fast_reload") * 0.15)
	api.start_gun_cooldown(pname, itemstack, math.max(0.1, cd))
end

-- Dispatches a weapon use: checks cooldowns, then fires the current mode.
function api.handle_use(user, itemstack, pointed_thing, weapon_id, mode)
	if pointed_thing.type == "node" then
		local node = core.get_node(pointed_thing.under)
		if node.name:match("ctf_modebase:flag") then
			local ndef = core.registered_nodes[node.name]
			if ndef then
				return ndef.on_punch(pointed_thing.under, node, user, pointed_thing)
			end
		end
	end

	if not ctf_mode_chaos.can_use() then
		return itemstack
	end

	local gun = api.get_gun(weapon_id, mode)
	if not gun then
		return itemstack
	end

	-- The switch cooldown gates firing right after a mode switch
	if api.switch_cooldown:get(user) then
		return itemstack
	end

	if api.is_gun_on_cooldown(user:get_player_name(), itemstack) then
		core.sound_play("ctf_ranged_click", { pos = user:get_pos() }, true)
		return itemstack
	end

	api.fire_grenade_mode(user, itemstack, gun, mode, weapon_id)

	return itemstack
end

-- Cycles to the next unlocked mode of a weapon (right-click / use key).
function api.switch_mode(user, itemstack, weapon_id, current_mode)
	if not ctf_mode_chaos.can_use() then
		return itemstack
	end

	local pname = user:get_player_name()

	if api.is_gun_on_cooldown(pname, itemstack) then
		return itemstack
	end

	if api.switch_cooldown:get(user) then
		return itemstack
	end

	local unlocked = ctf_mode_chaos.get_unlocked_modes(user, weapon_id)
	if #unlocked <= 1 then
		hud_events.new(pname, {
			text = "Only the base mode is unlocked",
			quick = true,
		})
		return
	end

	local is_sneaking = user:get_player_control().sneak
	local idx = table.indexof(unlocked, current_mode)
	if not idx then
		idx = 1
	end

	local next_idx
	if is_sneaking then
		next_idx = ((idx - 2) % #unlocked) + 1
	else
		next_idx = (idx % #unlocked) + 1
	end

	local next_mode = unlocked[next_idx]
	itemstack:set_name(api.tool_prefixes[weapon_id] .. next_mode)
	ctf_mode_chaos.set_current_mode(user, weapon_id, next_mode)
	api.switch_cooldown:set(user, api.SWITCH_COOLDOWN)
	ctf_mode_chaos.update_hud(user)

	local gun = api.get_gun(weapon_id, next_mode)
	hud_events.new(pname, {
		text = "Mode: " .. (gun and gun.description or next_mode),
		quick = true,
	})

	return itemstack
end

return api

