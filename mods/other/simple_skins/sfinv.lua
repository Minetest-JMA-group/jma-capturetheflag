
local S = skins.translate


if skins.default_skin_tab then

	sfinv.register_page("skins:skins", {title = S("Skins"),

		get = function(self, player, context)

			local name = player:get_player_name()

			return sfinv.make_formspec(player, context,skins.formspec.main(name))
		end,

		on_player_receive_fields = function(self, player, context, fields)

			local event = minetest.explode_textlist_event(fields["skins_set"])

			if event.type == "CHG" then

				skins.event_CHG(event, player)

				sfinv.override_page("skins:skins", {

					get = function(self, player, context)

						local name = player:get_player_name()

						return sfinv.make_formspec(player, context,
								skins.formspec.main(name))
					end
				})

				sfinv.set_player_inventory_formspec(player)
			end
		end
	})
end
