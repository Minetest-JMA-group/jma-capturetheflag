ctf_settings.register("ctf_kill_list:tp_size", {
	type = "list",
	description = "Your texturepack's texture size. Used to scale things like kill feed images",
	list = {"8px", "16px", "32px", "64px", "128px", "256px"},
	image_scale_map = {2, 1, 0.5, 0.25, 0.125, 0.0625},
	default = "2",
})

ctf_settings.register("use_hudbars", {
	label = "Use modern hudbars instead of icon hud",
	type = "bool",
	default = "false",
	description = "Use a bar with a label instead of icons for quantites like\n" ..
		"health, stamina, and breath.\n" ..
		"Reconnect to see effects.",
	on_change = function(player, new_value)
		minetest.chat_send_player(player:get_player_name(), "Please reconnect to apply setting: \"Use modern hudbars instead of icon hud\"")
	end,
})