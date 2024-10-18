local FORMSIZE = {x = 8, y = 4.5}
local SCROLLBAR = {width = 0.3}

-- This Function MIT by Rubenwardy

--- Creates a scrollbaroptions for a scroll_container

--

-- @param visible_l the length of the scroll_container and scrollbar

-- @param total_l length of the scrollable area

-- @param scroll_factor as passed to scroll_container

local function make_scrollbaroptions_for_scroll_container(visible_l, total_l, scroll_factor,arrows)

	assert(total_l >= visible_l)

	arrows = arrows or "default"

	local thumb_size = (visible_l / total_l) * (total_l - visible_l)

	local max = total_l - visible_l

	return ("scrollbaroptions[min=0;max=%f;thumbsize=%f;arrows=%s]"):format(max / scroll_factor, thumb_size / scroll_factor,arrows)

end

sfinv.register_page("server_cosmetics:customize", {
	title = "Customize",
	get = function(self, player, context)
		local pname = player:get_player_name()
		local current = ctf_cosmetics.get_extra_clothing(player)
		local props = player:get_properties()
		local walk_anim = player_api.registered_models[props.mesh].animations.walk
		local cosmetic_forms = ""
		local pos = -0.4
		local pteam = ctf_teams.get(pname)
		local models = {
			{
				mesh = props.mesh,
				texture = {ctf_cosmetics.get_colored_skin(player, pteam and ctf_teams.team[pteam].color), "blank.png"},
				anim_range = walk_anim,
				rotation = {0, 160},
			}
		}

		for category, contents in pairs(server_cosmetics.cosmetics) do
			for ctype, cosmetics in pairs(contents) do
				local available_cosmetics = {}
				local readable_available_cosmetics = {}
				local convert = {}

				for name, info in pairs(cosmetics) do
					if name:sub(1, 1) ~= "_" and server_cosmetics.can_use(player, ctype, name) then
						table.insert(available_cosmetics, name)
						table.insert(readable_available_cosmetics, HumanReadable(name))
						convert[HumanReadable(name)] = name
					end
				end

				if #available_cosmetics >= 1 then
					local element_name = string.format("%s:%s", category, ctype)

					context["enable_"..element_name] = function(fields, enable)
						if enable == "true" then
							local selected = convert[fields["select_"..element_name]] or available_cosmetics[1]

							local selected_color = cosmetics[selected]
							if not server_cosmetics.can_use(player, ctype, selected) then
								minetest.log("warning", "Player "..pname.." is trying to exploit the cosmetic formspecs")
								return true
							end
							ctf_cosmetics.set_extra_clothing(player, { [ctype] = selected_color })
						else
							ctf_cosmetics.set_extra_clothing(player, { _remove = {ctype} })
							current[ctype] = nil
						end

						player_api.set_texture(player, 1, ctf_cosmetics.get_skin(player))
					end

					context["select_"..element_name] = function(fields, selected)
						if not current[ctype] then return true end

						selected = convert[selected] or available_cosmetics[1]

						local selected_color = cosmetics[selected]
						if not server_cosmetics.can_use(player, ctype, selected) then
							minetest.log("warning", "Player "..pname.." is trying to exploit the cosmetic formspecs")
							return true
						end

						if current[ctype]._key == selected_color._key then return true end -- Already changed
						ctf_cosmetics.set_extra_clothing(player, { [ctype] = selected_color })
						player_api.set_texture(player, 1, ctf_cosmetics.get_skin(player))
					end

					if cosmetics._model then
						table.insert(models, {
							mesh = cosmetics._model,
							texture = (current[ctype] or cosmetics[available_cosmetics[1]]).color,
							anim_range = (cosmetics._anims and cosmetics._anims.idle) or {x = 1, y = 1},
							rotation = cosmetics._preview_rot or {0, 0},
						})
					end

					local selected = current[ctype] and table.indexof(available_cosmetics, current[ctype]._key)
					if not selected or selected == -1 then
						selected = 1
					end
					cosmetic_forms = string.format([[%s
						checkbox[0,%f;enable_%s;%s;%s]
						dropdown[0,%f;%f;select_%s;%s;%d]
					]], cosmetic_forms,
						--checkbox
						pos, element_name, (cosmetics._prefix or "Enable ") .. (cosmetics._description or HumanReadable(ctype)),
							current[ctype] and "true" or "false",
						--dropdown
						pos + 0.8, (FORMSIZE.x/2),
							element_name, current[ctype] and table.concat(readable_available_cosmetics, ",") or "", selected
					)

					pos = pos + 1.8
				end
			end
		end

		if not context.model_selected or context.model_selected > #models then
			context.model_selected = 1
		end

		local form = string.format(
			[[
				formspec_version[4]
				real_coordiantes[true]
				box[0,-0.2;%f,%f;#00000055]
				model[0,0;%f,%f;playerview;%s;%s,%s;%d,%d;;;%f,%f]
				image_button[0,%f;0.8,0.8;creative_prev_icon.png;model_prev;]
				label[%f,%f;%d/%d]
				image_button[%f,%f;0.8,0.8;creative_next_icon.png;model_next;]

				%s
				scrollbar[%f,-0.1;%f,%f;vertical;cosmetics_scrollbar;%f]
				scroll_container[%f,0.3;%f,%f;cosmetics_scrollbar;vertical;0.1]
					%s
				scroll_container_end[]
			]],
			--box
			(FORMSIZE.x/2) - 0.8, FORMSIZE.y,
			--model
			(FORMSIZE.x/2), FORMSIZE.y + 0.2,
				models[context.model_selected].mesh,
				models[context.model_selected].texture[1] or "blank.png",
				models[context.model_selected].texture[2] or "blank.png",
				models[context.model_selected].rotation[1], models[context.model_selected].rotation[2],
				models[context.model_selected].anim_range.x, models[context.model_selected].anim_range.y,
			--image_button
			FORMSIZE.y-0.1,
			--label
			(FORMSIZE.x/4) - 0.5, FORMSIZE.y, context.model_selected, #models,
			--image_button
			(FORMSIZE.x/2) - 1.39, FORMSIZE.y-0.1,

			--scrollbaroptions
			make_scrollbaroptions_for_scroll_container(FORMSIZE.y - 0.3, pos + 0.7, 0.1),
			--scrollbar
			FORMSIZE.x-SCROLLBAR.width, SCROLLBAR.width, FORMSIZE.y + 0.6, context.scrollbar or 0,
			--scroll_container
			(FORMSIZE.x/2 + 0.3), 6 - SCROLLBAR.width, FORMSIZE.y + 1.4,

			cosmetic_forms
		)

		return sfinv.make_formspec(player, context, form, true)
	end,
	on_player_receive_fields = function(self, player, context, fields)
		local refresh = true

		if fields.model_next then
			context.model_selected = context.model_selected + 1
		elseif fields.model_prev then
			context.model_selected = math.max(context.model_selected - 1, 1)
		elseif not fields.quit then
			refresh = false
		end

		for fieldname, info in pairs(fields) do
			if context[fieldname] then
				if not refresh and not context[fieldname](fields, info) then --not context[]() -> not no_refresh_needed()
					refresh = true
				end
			end
		end

		if not refresh then return end

		if fields.cosmetics_scrollbar then
			local scrollevent = minetest.explode_scrollbar_event(fields.cosmetics_scrollbar)

			if scrollevent.value then
				context.scrollbar = scrollevent.value
			end
		end

		sfinv.set_page(player, sfinv.get_page(player))
	end,
})
