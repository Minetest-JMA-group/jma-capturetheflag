local SHIELD_ITEM = "ctf_mode_chaos:shield"
local SHIELD_WEAPON_ID = "shield"
local WEAR_MAX = 65535

-- Damage protection: 10% while the shield is in the hotbar, 50% (+ "hardened"
-- bonus) while it is held. Only the held shield wears down.
local GLOBAL_BLOCK_PCT = 25
local BASE_BLOCK_PCT = 50
local HARDENED_BLOCK_PCT = 6

-- Base durability consumed per blocked damage point; divided by (1 + tough).
local BASE_WEAR_PER_DAMAGE = 1000
local VITALITY_HP_PER_LEVEL = 5

local vitality_bonus = {}
local global_active = {}

local function get_block_pct(player)
	local pname = PlayerName(player)
	if not pname then
		return 0
	end

	if ctf_mode_chaos.get_wielded_weapon(player) == SHIELD_WEAPON_ID then
		local hardened = ctf_mode_chaos.param_level(player, SHIELD_WEAPON_ID, "hardened")
		return BASE_BLOCK_PCT + HARDENED_BLOCK_PCT * hardened
	end

	if global_active[pname] then
		return GLOBAL_BLOCK_PCT
	end

	return 0
end

function ctf_mode_chaos.block_shield_damage(player, damage)
	if not player or not player:is_player() or damage <= 0 then
		return 0
	end

	local block_pct = get_block_pct(player)
	if block_pct <= 0 then
		return 0
	end

	local wielded = ctf_mode_chaos.get_wielded_weapon(player) == SHIELD_WEAPON_ID
	local blocked = math.floor(damage * block_pct / 100)
	if blocked <= 0 then
		return 0
	end

	if wielded then
		-- "Tough" reduces the durability cost of each blocked hit.
		local tough = ctf_mode_chaos.param_level(player, SHIELD_WEAPON_ID, "tough")
		local wear_cost = math.ceil(BASE_WEAR_PER_DAMAGE / (2 + tough))

		-- Consume shield durability; the shield breaks when fully worn out.
		local itemstack = player:get_wielded_item()
		local wear = itemstack:get_wear() + blocked * wear_cost
		if wear >= WEAR_MAX then
			player:set_wielded_item(ItemStack(""))
		else
			itemstack:set_wear(wear)
			player:set_wielded_item(itemstack)
		end
	end

	return blocked
end

-- Recomputes the vitality hp bonus for a player and applies or rolls it back.
-- No-op when the bonus didn't change.
local function update_vitality(player)
	if not player or not player:is_player() then
		return
	end
	local pname = PlayerName(player)
	if not pname then
		return
	end

	local level = 0
	if global_active[pname] then
		level = ctf_mode_chaos.param_level(player, SHIELD_WEAPON_ID, "vitality")
	end
	local bonus = level * VITALITY_HP_PER_LEVEL
	local old = vitality_bonus[pname] or 0
	if bonus == old then
		return
	end

	local new_max = player:get_properties().hp_max - old + bonus
	player:set_properties({ hp_max = new_max })
	vitality_bonus[pname] = bonus

	-- Never let the current HP exceed the (possibly reduced) new maximum.
	if player:get_hp() > new_max then
		player:set_hp(new_max)
	end
	return bonus
end

local function apply_shield_global(player)
	global_active[PlayerName(player)] = true
	local bonus = update_vitality(player)
	local pct = get_block_pct(player)
	return "Shield: " .. pct .. "% protection"
		.. (bonus and bonus > 0 and ", Vitality +" .. bonus .. " HP" or "")
end

local function clear_shield_global(player)
	global_active[PlayerName(player)] = nil
	update_vitality(player)
end

core.register_on_leaveplayer(function(player)
	vitality_bonus[PlayerName(player)] = nil
end)

-- The shield is a weapon without unlockable modes; its upgrades come from the
-- param modifiers. Registering it through the modifier engine gives it HUD
-- display, per-player upgrade state and mod drops.
ctf_mode_chaos.register_weapon_template({
	id = SHIELD_WEAPON_ID,
	description = "Shield",
	mode_order = { "block" },
	item = SHIELD_ITEM,
	item_prefix = "ctf_mode_chaos:mod_shield",
	is_weapon_item = function(itemname)
		return itemname == SHIELD_ITEM
	end,
	param_defs = {
		hardened = {
			description = "Hardened",
			max_level = 5,
			weight = 10,
			icon = "ctf_mode_chaos_hardened.png",
		},
		tough = {
			description = "Tough",
			max_level = 5,
			weight = 8,
			icon = "default_steel_block.png^[colorize:#00cc88:180",
		},
		vitality = {
			description = "Vitality",
			max_level = 3,
			weight = 8,
			icon = "ctf_mode_chaos_vitality.png",
		},
	},
	on_global = apply_shield_global,
	on_global_clear = clear_shield_global,
})

core.register_tool(SHIELD_ITEM, {
	description = "Shield"
		.. "\nBlocks " .. BASE_BLOCK_PCT .. "% of damage while held"
		.. "\nBlocks " .. GLOBAL_BLOCK_PCT .. "% of damage while in the hotbar"
		.. "\nWears down with every blocked hit while held"
		.. "\nUpgrade it with Shield mods",
	inventory_image = "ctf_mode_chaos_shield.png",
	wield_image = "ctf_mode_chaos_shield.png",
	wield_scale = { x = 1.8, y = 1.8, z = 1.8 },
	range = 4,
	groups = { disable_repair = 1 },
	on_use = function(itemstack, user, pointed_thing)
		return itemstack
	end,
})


