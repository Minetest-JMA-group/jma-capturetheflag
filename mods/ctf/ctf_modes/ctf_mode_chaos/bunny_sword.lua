local weapons_api = ctf_mode_chaos.weapons_api

local BUNNY_SWORD_ID = "bunny_sword"
local NORMAL_ITEM = "ctf_mode_chaos:bunny_sword"

local MELEE_RANGE = 6     -- raycast length of the LMB attack
local SWING_COOLDOWN = 0.35 -- minimum delay between two LMB attacks
local ATTACK_INTERVAL = 0.6 -- full punch interval of the sword
local PUNCH_INTERVAL = 1.0  -- time_from_last_punch passed to punch()

local BASE_DAMAGE = 7       -- LMB fleshy damage
local BASE_KNOCKBACK = 6    -- LMB knockback group
local LEAP_FORWARD = 11     -- leap horizontal velocity
local LEAP_UP = 3           -- leap vertical velocity

local CHARGE_TICKS = 2      -- seconds the sword stays charged
local WEAR_MAX = 65534
local CHARGE_STEP = math.floor(WEAR_MAX / CHARGE_TICKS)

local LEAP_STAMINA_COST = 1 -- stamina consumed by each leap

local swing_cooldown = ctf_core.init_cooldowns()

-- Damage and knockback scaled by the sword's mods.
local function get_damage(player, base)
	local sharpness = ctf_mode_chaos.param_level(player, BUNNY_SWORD_ID, "sharpness")
	return base + sharpness
end

local function get_knockback(player, base)
	local punt = ctf_mode_chaos.param_level(player, BUNNY_SWORD_ID, "punt")
	return base + punt * 2
end

-- Returns the first enemy player hit by a ray from the user's eyes, or nil.
local function get_melee_target(user, range)
	local pos = vector.offset(user:get_pos(), 0, user:get_properties().eye_height, 0)
	local dir = user:get_look_dir()
	local ray = core.raycast(pos, vector.add(pos, vector.multiply(dir, range)), true, false)
	for hit in ray do
		if hit.type == "object" then
			local obj = hit.ref
			if obj:is_player() then
				local pname = user:get_player_name()
				local vname = obj:get_player_name()
				if weapons_api.can_hit(pname, vname) and obj:get_hp() > 0 then
					return obj
				end
			end
		else
			break -- a node blocks the swing
		end
	end
	return nil
end

-- Punches an enemy player with the given damage groups.
local function punch_player(target, user, damage_groups)
	target:punch(user, PUNCH_INTERVAL, {
		full_punch_interval = ATTACK_INTERVAL,
		damage_groups = damage_groups,
	}, nil)
end


-- The LMB attack uses the base damage only; the charge is reserved for the
-- leap state and the visual charge effect, not a stronger melee strike.
local function do_swing(itemstack, user)
	if swing_cooldown:get(user) then
		return itemstack
	end
	swing_cooldown:set(user, SWING_COOLDOWN)

	local target = get_melee_target(user, MELEE_RANGE)
	if not target then
		return itemstack
	end

	core.sound_play("ctf_melee_whoosh", {
		object = user,
		gain = 1.1,
		max_hear_distance = 6,
	}, true)

	punch_player(target, user, {
		fleshy = get_damage(user, BASE_DAMAGE),
		knockback = get_knockback(user, BASE_KNOCKBACK),
	})

	core.sound_play("player_damage", {
		object = user,
		exclude_player = target:get_player_name(),
		pitch = 0.8,
		gain = 0.4,
		max_hear_distance = 16,
	}, true)

	return itemstack
end

local function reset_sword(pname, item_id)
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
		local meta = stack:get_meta()
		meta:set_string("color", "")
		stack:set_wear(0)
		inv:set_stack("main", pos, stack)
	end
end

-- Cancels the charged state early (RMB while the sword is charged).
local function cancel_charge(itemstack, user)
	local pname = user:get_player_name()
	local item_id = itemstack:get_meta():get_string("update_wear_id")
	if item_id ~= "" then
		ctf_modebase.update_wear.cancel_item_update(pname, item_id)
	end
	local meta = itemstack:get_meta()
	meta:set_string("color", "")
	itemstack:set_wear(0)
	return itemstack
end

local function do_leap(itemstack, user)
	local pname = user:get_player_name()

	-- While charged, RMB cancels the charge instead of leaping again.
	if itemstack:get_meta():get_string("color") ~= "" then
		return cancel_charge(itemstack, user)
	end

	-- Only leap from solid ground.
	local pos = user:get_pos()
	if not pos then
		return itemstack
	end
	local below_node = core.get_node(vector.offset(pos, 0, -0.5, 0))
	local below_def = core.registered_nodes[below_node.name]
	if not below_def or not below_def.walkable then
		hud_events.new(pname, {
			text = "You need solid ground to leap!",
			quick = true,
		})
		return itemstack
	end

	local sprint_info = sprint.get_sprint_info(pname)
	if sprint_info then
		if sprint_info.stamina < LEAP_STAMINA_COST then
			hud_events.new(pname, {
				text = "Too tired to leap!",
				quick = true,
			})
			return itemstack
		end
		sprint_info.stamina = sprint_info.stamina - LEAP_STAMINA_COST
	end

	-- The hop itself.
	local legs = ctf_mode_chaos.param_level(user, BUNNY_SWORD_ID, "bunny_legs")
	local dir = user:get_look_dir()
	local leap_vel = vector.add(
		vector.multiply(dir, LEAP_FORWARD + legs * 0.4),
		{ x = 0, y = LEAP_UP + legs * 0.3, z = 0 }
	)
	user:add_velocity(leap_vel)

	-- Dust kicked up at the takeoff point.
	core.add_particlespawner({
		amount = 10,
		time = 0.5,
		minpos = vector.offset(pos, -1.5, 0.8, -1.5),
		maxpos = vector.offset(pos, 1.5, 0.5, 1.5),
		minvel = vector.new(-1, 1, -1),
		maxvel = vector.new(1, 3, 1),
		minacc = vector.new(0, -6, 0),
		maxacc = vector.new(0, -6, 0),
		minexptime = 0.4,
		maxexptime = 1,
		minsize = 1,
		maxsize = 2,
		collisiondetection = false,
		collision_removal = false,
		vertical = false,
		texture = "grenades_smoke.png^[colorize:#8B4513:150",
	})

	--Particles track the player while in the air
	core.add_particlespawner({
		amount = 10,
		time = 2.5,
		minvel = vector.new(-0.5, -0.5, -0.5),
		maxvel = vector.new(0.5, 0.5, 0.5),
		minacc = vector.new(0, 0, 0),
		maxacc = vector.new(0, 0, 0),
		minexptime = 1,
		maxexptime = 1.5,
		minsize = 0.5,
		maxsize = 1,
		collisiondetection = false,
		collision_removal = false,
		vertical = false,
		texture = "grenades_smoke.png^[colorize:white:255",
		glow = 5,
		attached = user,
	})

	core.sound_play("ctf_melee_whoosh", {
		object = user,
		pitch = 0.9,
		gain = 1.2,
		max_hear_distance = 12,
	}, true)

	-- Charge the sword: update_wear tracks it by id (even if it moves slots)
	-- and restores the normal color when the charge ends or is cancelled.
	local item_id
	itemstack:set_wear(WEAR_MAX)
	itemstack:get_meta():set_string("color", "red")
	item_id = ctf_modebase.update_wear.start_update(
		pname,
		itemstack,
		CHARGE_STEP,
		true, -- the wear counts down to 0, which finishes the charge
		function()
			reset_sword(pname, item_id)
		end,
		function()
			reset_sword(pname, item_id)
		end
	)

	return itemstack
end

core.register_tool(NORMAL_ITEM, {
	description = "Bunny Sword"
		.. "\nLMB: slash"
		.. "\nRMB: bunny leap (knocks enemies back and charges the sword)"
		.. "\nLeaps consume stamina"
		.. "\nThe sword turns red while charged"
		.. "\nUpgrade it with Bunny Sword mods",
	inventory_image = "ctf_mode_chaos_bunny_sword.png",
	wield_image = "ctf_mode_chaos_bunny_sword.png",
	wield_scale = { x = 1.0, y = 1.0, z = 1.0 },
	range = MELEE_RANGE,
	groups = { sword = 1 },
	tool_capabilities = {
		full_punch_interval = ATTACK_INTERVAL,
		max_drop_level = 1,
		groupcaps = {
			snappy = { times = { [1] = 2.5, [2] = 1.2, [3] = 0.35 }, uses = 0, maxlevel = 3 },
		},
		damage_groups = { fleshy = BASE_DAMAGE, knockback = BASE_KNOCKBACK },
		punch_attack_uses = 0,
	},
	on_use = function(itemstack, user, pointed_thing)
		return do_swing(itemstack, user)
	end,
	on_secondary_use = function(itemstack, user, pointed_thing)
		return do_leap(itemstack, user)
	end,
	on_place = function(itemstack, user, pointed_thing)
		if pointed_thing and pointed_thing.under then
			local node = core.get_node(pointed_thing.under)
			local ndef = core.registered_nodes[node.name]
			if ndef and ndef.on_rightclick then
				return core.item_place(itemstack, user, pointed_thing)
			end
		end
		return do_leap(itemstack, user)
	end,
})

local function apply_sword_global(player)
	local legs = ctf_mode_chaos.param_level(player, BUNNY_SWORD_ID, "bunny_legs")
	physics.set(PlayerName(player), "ctf_mode_chaos:bunny_legs_global", {
		jump = 1.25 + 0.05 * legs,
	})
end

local function clear_sword_global(player)
	physics.remove(PlayerName(player), "ctf_mode_chaos:bunny_legs_global")
end

ctf_mode_chaos.register_weapon_template({
	id = BUNNY_SWORD_ID,
	description = "Bunny Sword",
	mode_order = { "sword" },
	item = NORMAL_ITEM,
	item_prefix = "ctf_mode_chaos:mod_bunny",
	is_weapon_item = function(itemname)
		return itemname == NORMAL_ITEM
	end,
	param_defs = {
		sharpness = {
			description = "Sharpness",
			max_level = 3,
			weight = 8,
			icon = "ctf_mode_chaos_bunny_sword_upgrade.png^[colorize:#ffffff:200",
		},
		bunny_legs = {
			description = "Bunny Legs",
			max_level = 5,
			weight = 12,
			icon = "ctf_mode_chaos_bunny_sword_upgrade.png^[colorize:#ffcc88:180",
		},
	},
	on_global = apply_sword_global,
	on_global_clear = clear_sword_global,
})
