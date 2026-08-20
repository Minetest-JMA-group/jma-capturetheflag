local DEFAULT_DESPAWN_TIME = 600
local DESPAWN_CHECK_DELAY = 20

--- @class ObjectRef
--- @field check_for_despawn fun(self: ObjectRef)

-- This table represents how long items take to respawn
-- Values of "true" don't automatically despawn

--- @type {[string]: any}
local item_despawn_times = {
	-- COMBAT ITEMS
	["ctf_healing:super_bandage"] = true,
	["ctf_healing:bandage"] = true,
	["ctf_healing:heal_block"] = true,
	["ctf_healing:healing_pistol"] = true,
	["default:sword_wood"] = true,
	["ctf_melee:sword_steel"] = true,
	["ctf_melee:sword_mese"] = true,
	["ctf_melee:sword_diamond"] = true,
	["ctf_ranged:assault_rifle"] = true,
	["ctf_ranged:assault_rifle_loaded"] = true,
	["ctf_ranged:shotgun"] = true,
	["ctf_ranged:shotgun_loaded"] = true,
	["ctf_ranged:rifle"] = true,
	["ctf_ranged:rifle_loaded"] = true,
	["ctf_ranged:sniper"] = true,
	["ctf_ranged:sniper_loaded"] = true,
	["ctf_ranged:sniper_magnum"] = true,
	["ctf_ranged:sniper_magnum_loaded"] = true,
	["ctf_ranged:pistol_loaded"] = true,
	["default:axe_mese"] = true,
	["default:axe_diamond"] = true,
	["default:shovel_mese"] = { base_despawn_time = 3 * 60 },
	["default:shovel_diamond"] = true,
	["default:pick_mese"] = true,
	["default:pick_diamond"] = true,
	["fire:flint_and_steel"] = true,
	["rocket_launcher:launcher"] = true,
	["grenades:frag"] = true,
	["grenades:frag_sticky"] = true,
	["grenades:poison"] = true,
	["grenades:smoke"] = true,

	-- ITEMS
	["ctf_mode_chaos:power_charge"] = {
		base_despawn_time = 3 * 60,
		extra_time_per_item = 5,
	},
	["ctf_ranged:ammo"] = true,
	["ctf_healing:ammo"] = true,

	["default:blueberries"] = { base_despawn_time = 3 * 60, extra_time_per_item = 3 },
	["default:apple"] = { base_despawn_time = 3 * 60, extra_time_per_item = 3 }, -- technically a node
	["default:diamond"] = true,
	["default:mese_crystal"] = true,
	["default:steel_ingot"] = { base_despawn_time = 3 * 60, extra_time_per_item = 7 },
	["wind_charges:wind_charge"] = { base_despawn_time = 3 * 60, extra_time_per_item = 4 },

	-- NODES
	["ctf_landmine:landmine"] = true,
	["ctf_map:spike"] = true,
	["ctf_map:spike_diamond"] = true,
	["ctf_map:spike_mese"] = true,
	["ctf_map:spike_double_diamond"] = true,
	["ctf_map:spike_double_mese"] = true,
	["ctf_teams:door_steel"] = { base_despawn_time = 3 * 60, extra_time_per_item = 5 },
	["heal_block:heal"] = true,
	["default:mese"] = true,

	-- QUICK DESPAWNING ITEMS
	["ctf_combat:sword_stone"] = { base_despawn_time = 15 },
	["default:pick_stone"] = { base_despawn_time = 15 },
	["default:torch"] = { base_despawn_time = 25, extra_time_per_item = 1 },
}

--- COPIED OVER FROM minetest_game/default/item_entity.lua

local builtin_item = core.registered_entities["__builtin:item"]

-- strictly speaking none of this is part of the API, so do some checks
-- and if it looks wrong skip the modifications
if
	not builtin_item
	or type(builtin_item.set_item) ~= "function"
	or type(builtin_item.on_step) ~= "function"
then
	core.log(
		"warning",
		"Builtin item entity does not look as expected, skipping overrides."
	)
	return
end

--- @type {[string]: {object: ObjectRef, check_for_despawn: fun(self: table), timer: table|false}}
local active_items = {}

local item = {
	check_for_despawn = function(self)
		if self.timer then
			self.timer = self.timer - DESPAWN_CHECK_DELAY
			if self.timer <= 0 then
				self.object:remove()
			end
		end
	end,
	set_item = function(self, itemstring, ...)
		builtin_item.set_item(self, itemstring, ...)

		local stack = ItemStack(itemstring)

		local modifiers = item_despawn_times[stack:get_name()]
		core.debug(
			string.format(
				"Modifiers for item %s is %s",
				stack:get_name(),
				tostring(modifiers)
			)
		)
		if modifiers then
			if modifiers == true then
				self.timer = false
			else
				self.timer = (modifiers.base_despawn_time or DEFAULT_DESPAWN_TIME)
					+ (modifiers.extra_time_per_item or 1) * stack:get_count()
			end
		else
			self.timer = DEFAULT_DESPAWN_TIME
		end
	end,
	on_activate = function(self, ...)
		builtin_item.on_activate(self, ...)
		active_items[self.object:get_guid()] = self
	end,
	on_deactivate = function(self, removal, ...)
		---@diagnostic disable-next-line: redundant-parameter
		(builtin_item.on_deactivate or function() end)(self, removal, ...) -- future-proofed
		active_items[self.object:get_guid()] = nil
		if not removal then
			self.object:remove()
		end
	end,
}

local t = 0
core.register_globalstep(function(dtime)
	t = t + dtime
	if t > DESPAWN_CHECK_DELAY then
		for guid, ref in pairs(active_items) do
			if ref.object:is_valid() then
				ref:check_for_despawn()
			else
				active_items[guid] = nil
			end
		end
		t = 0
	end
end)

-- set defined item as new __builtin:item, with the old one as fallback table
setmetatable(item, { __index = builtin_item })
core.register_entity(":__builtin:item", item)
