local pvp_switch_def = {
	description = "Switch pvp mode (Currently PVP ON)",
	inventory_image = "ctf_jma_elysium_pvp_on.png",
	stack_max = 1,
	range = 3,
	on_use = function(itemstack, user)
		local name = user:get_player_name()
		local ctx = ctf_jma_elysium.players[name]
		if not ctx then
			core.chat_send_player(name, "You are not in elysium.")
			return
		end

		local pvp_mode = ctf_jma_elysium.set_pvp_mode(user)
		if pvp_mode == nil then return end

		local msg = "PVP Mode "
		if pvp_mode then
			itemstack:set_name("ctf_jma_elysium:pvp_on")
			msg = msg .. "ON"
		else
			itemstack:set_name("ctf_jma_elysium:pvp_off")
			msg = msg .. "OFF"
		end
		cmsg.push_message_player(user, msg)
		return itemstack
	end,
	on_drop = function()
		return
	end
}

core.register_craftitem("ctf_jma_elysium:pvp_on", pvp_switch_def)
pvp_switch_def.description = "Switch pvp mode (Currently PVP OFF)"
pvp_switch_def.inventory_image = "ctf_jma_elysium_pvp_off.png"
core.register_craftitem("ctf_jma_elysium:pvp_off", pvp_switch_def)

core.register_allow_player_inventory_action(function(player, action, inventory, info)
	if ctf_jma_elysium.players[player:get_player_name()] then
		if action == "take" and info.stack:get_name():match("^ctf_jma_elysium") then
			return 0
		end
	end
end)
