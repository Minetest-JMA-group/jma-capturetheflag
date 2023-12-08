
local S = skins.translate


minetest.register_on_joinplayer(function(player)

	inventory_plus.register_button(player, "skins", S("Skins"), 0,
			"inventory_plus_skins.png")
end)


minetest.register_on_player_receive_fields(function(player, formname, fields)

	if skins.sfinv then

		local name = player:get_player_name()

		if fields.skins then

			inventory_plus.set_inventory_formspec(player,
				"size[8,8.6]"
				.. "bgcolor[#08080822;true]"
				.. skins.formspec.main(name)
				.. "button[0,.75;2,.5;main;" .. S("Back") .. "]")
		end

		local event = minetest.explode_textlist_event(fields["skins_set"])

		if event.type == "CHG" then

			skins.event_CHG(event, player)

			inventory_plus.set_inventory_formspec(player,
				"size[8,8.6]"
				.. "bgcolor[#08080822;true]"
				.. skins.formspec.main(name)
				.. "button[0,.75;2,.5;main;" .. S("Back") .. "]")
		end
	end
end)
