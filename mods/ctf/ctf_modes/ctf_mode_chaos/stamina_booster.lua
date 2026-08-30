-- ctf_mode_chaos/stamina_booster.lua
--
-- The Stamina Booster: a passive item that raises the player's max stamina
-- while it is in the hotbar (a global effect, like the Shield). Effects stack:
-- every booster in the hotbar adds another +50%, so N boosters multiply the
-- max stamina by (1 + 0.5 * N).

local BOOST_ITEM = "ctf_mode_chaos:stamina_booster"
local BOOST_PER_ITEM = 0.5 -- +50% max stamina per booster

-- Applies the stamina bonus while boosters are in the hotbar. Returns the HUD
-- label shown while the effect is active.
local function apply_stamina_boost(player, weapon_id, count)
	if sprint and sprint.set_stamina_multiplier then
		sprint.set_stamina_multiplier(PlayerName(player), 1 + BOOST_PER_ITEM * (count or 1))
	end
	return "Stamina +" .. math.floor(100 * BOOST_PER_ITEM * (count or 1)) .. "%"
end

-- Rolls the bonus back when the boosters leave the hotbar.
local function clear_stamina_boost(player)
	if sprint and sprint.set_stamina_multiplier then
		sprint.set_stamina_multiplier(PlayerName(player), 1)
	end
end

ctf_mode_chaos.register_weapon_template({
	id = "stamina_booster",
	description = "Stamina Booster",
	mode_order = { "boost" },
	item = BOOST_ITEM,
	item_prefix = "ctf_mode_chaos:mod_stamina",
	is_weapon_item = function(itemname)
		return itemname == BOOST_ITEM
	end,
	on_global = apply_stamina_boost,
	on_global_clear = clear_stamina_boost,
})

core.register_craftitem(BOOST_ITEM, {
	description = "Stamina Booster"
		.. "\n+50% max stamina per booster in the hotbar",
	inventory_image = "ctf_mode_chaos_stamina_booster.png",
	groups = {},
})
