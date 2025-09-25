local COOLDOWN = ctf_core.init_cooldowns()
local S = core.get_translator(core.get_current_modname())

local function make_pvp_switch(pvp_on)
	return {
		description = S(
			"Switch pvp mode (Currently PVP @1)",
			(pvp_on and S("ON") or S("OFF"))
		),
		inventory_image = "ctf_jma_elysium_pvp_" .. (pvp_on and "on" or "off") .. ".png",
		stack_max = 1,
		range = 3,
		on_use = function(itemstack, user)
			local name = user:get_player_name()
			local ctx = ctf_jma_elysium.players[name]
			if not ctx then
				core.chat_send_player(name, S("You are not in elysium."))
				return
			end

			local new_mode = ctf_jma_elysium.set_pvp_mode(user)
			if new_mode == nil then
				return
			end

			itemstack:set_name("ctf_jma_elysium:pvp_" .. (new_mode and "on" or "off"))
			cmsg.push_message_player(
				user,
				S("PVP Mode @1", (new_mode and S("ON") or S("OFF")))
			)
			return itemstack
		end,
		on_drop = function() end,
	}
end

core.register_craftitem("ctf_jma_elysium:pvp_on", make_pvp_switch(true))
core.register_craftitem("ctf_jma_elysium:pvp_off", make_pvp_switch(false))

do
	local apple_def = table.copy(core.registered_nodes["default:apple"])
	apple_def.description = S("Infinite Apple (Copy of default apple)")
	apple_def.tiles = { "ctf_jma_elysium_inf_apple.png" }
	apple_def.inventory_image = "ctf_jma_elysium_inf_apple.png"
	apple_def.stack_max = 1
	apple_def.on_use = function(itemstack, user, ...)
		if not COOLDOWN:get(user) then
			COOLDOWN:set(user, 0.2)

			local hp = user:get_hp()
			if hp > 0 then
				user:set_hp(hp + 3)
			end
		end
	end
	core.register_node("ctf_jma_elysium:inf_apple", apple_def)
end

local deny_items = {
	["ctf_jma_elysium:pvp_on"] = true,
	["ctf_jma_elysium:pvp_off"] = true,
}

core.register_allow_player_inventory_action(function(player, action, inventory, info)
	if ctf_jma_elysium.get_player(player:get_player_name()) then
		if action == "take" and info.stack and deny_items[info.stack:get_name()] then
			return 0
		end
	end
end)
