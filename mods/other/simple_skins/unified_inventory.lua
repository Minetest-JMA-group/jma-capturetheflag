
local S = skins.translate


unified_inventory.register_button("skins", {
	type = "image",
	image = "inventory_plus_skins.png",
	tooltip = S("Skins")
})


unified_inventory.register_page("skins", {

	get_formspec = function(player, perplayer_formspec)

		local formheadery =  perplayer_formspec.form_header_y
		local F = minetest.formspec_escape
		local player_name = player:get_player_name()
		local formspec = "label[0," .. formheadery .. ";" .. F(S("Skins")) .."]"

		formspec = formspec .. "listcolors[#00000000;#00000000]"
		formspec = formspec .. skins.formspec.main(player_name)

		return {formspec = formspec, draw_inventory = false}
	end
})


minetest.register_on_player_receive_fields(function(player, formname, fields)

	if skins.sfinv then

		local name = player:get_player_name()

		if fields.skins then
			unified_inventory.set_inventory_formspec(player, "skins")
		end

		local event = minetest.explode_textlist_event(fields["skins_set"])

		if event.type == "CHG" then

			skins.event_CHG(event, player)

			unified_inventory.set_inventory_formspec(player, "skins")
		end
	end
end)
