-- This table represents how long items take to respawn
-- Values of "true" don't automatically despawn

local default_despawn_time = 45

local item_despawn_times = {
	-- COMBAT ITEMS
	["ctf_healing:bandage"] = true,
	["ctf_healing:medkit"] = true,
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
	["ctf_ranged:pistol_loaded"] = {base_despawn_time = 2 * 60},
	["default:axe_mese"] = true,
	["default:axe_diamond"] = true,
	["default:shovel_mese"] = {base_despawn_time = 2 * 60},
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
	["ctf_mode_chaos:power_charge"] = {base_despawn_time = 2 * 60, extra_time_per_item = 4},
	["ctf_ranged:ammo"] = {extra_time_per_item = 3},
	["default:blueberries"] = {base_despawn_time = 2 * 60, extra_time_per_item = 2},
	["default:apple"] = {base_despawn_time = 2 * 60, extra_time_per_item = 2}, -- technically a node
	["default:diamond"] = true,
	["default:mese_crystal"] = true,
	["default:steel_ingot"] = {base_despawn_time = 2 * 60, extra_time_per_item = 7},
	["wind_charges:wind_charge"] = {base_despawn_time = 2 * 60, extra_time_per_item = 4},
	
	-- NODES
	["ctf_landmine:landmine"] = {base_despawn_time = 2 * 60, extra_time_per_item = 5},
	["ctf_map:spike"] = {base_despawn_time = 2 * 60, extra_time_per_item = 5},
	["ctf_teams:door_steel"] = {base_despawn_time = 2 * 60, extra_time_per_item = 5},
	["heal_block:heal"] = true,
	["default:mese"] = true,
	
	-- QUICK DESPAWNING ITEMS
	["ctf_combat:sword_stone"] = {base_despawn_time = 15},
	["default:pick_stone"] = {base_despawn_time = 15},
	["default:torch"] = {base_despawn_time = 15, extra_time_per_item = 0.5},
}



--- COPIED OVER FROM minetest_game/default/item_entity.lua

local builtin_item = minetest.registered_entities["__builtin:item"]

-- strictly speaking none of this is part of the API, so do some checks
-- and if it looks wrong skip the modifications
if not builtin_item or type(builtin_item.set_item) ~= "function" or type(builtin_item.on_step) ~= "function" then
	core.log("warning", "Builtin item entity does not look as expected, skipping overrides.")
	return
end

local item = {
	set_item = function(self, itemstring, ...)
		builtin_item.set_item(self, itemstring, ...)

		local stack = ItemStack(itemstring)

		local modifiers = item_despawn_times[stack:get_name()]
		if modifiers then
			if modifiers == true then
				self.timer = false
			else
				self.timer = (modifiers.base_despawn_time or default_despawn_time) + (modifiers.extra_time_per_item or 0) * stack:get_count() 
			end
		else
			self.timer = default_despawn_time
		end
	end,
	on_step = function(self, dtime, ...)
		builtin_item.on_step(self, dtime, ...)

		if self.timer then
			self.timer = self.timer - dtime*10
			if self.timer < 0 then
				self.object:remove()
			end
		end
	end,
}

-- set defined item as new __builtin:item, with the old one as fallback table
setmetatable(item, { __index = builtin_item })
core.register_entity(":__builtin:item", item)
