local ui = {}
local formspec_size = {10.47, 11.35}
local back_to_main_button = "box[0,0;10.47,1;black]" .. "button[9.43,0.035;1,1;back_to_main;X]"

local function get_info_form(msg)
	return "box[0,1;10.47,1.85;#202020]"
		.. "hypertext[0,1;10.47,1.85;h;<global valign=middle> <center>" .. msg .. "</center>]"
end

local function msg_denied(ctx)
	ctx.page = "info_form"
	ctx.info = {
		msg = "Insufficient privileges",
		status = false,
		color = "red",
		bold = true
	}
end

ui.info_form = function(player, ctx)
	local info = ctx.info
	local msg = info.msg
	local status = info.status

	local img = "ctf_clans_question.png"
	if status == true then
		img = "ctf_clans_check.png"
	else
		img = "ctf_clans_x.png"
	end

	if info.color then
		msg = "<style color=" .. info.color .. ">" .. msg .. "</style>"
	end

	if info.bold then
		msg = "<b>" .. msg .. "</b>"
	end

	ctx.info = nil
	return back_to_main_button
		.. get_info_form(msg)
		.. "image[4.235,4.5;2,2;" .. img .. "]"
end

ui.question_form = function(player, ctx)
	local question = ctx.question
	local msg =  question.msg

	if question.bold then
		msg = "<b>" .. msg .. "</b>"
	end


	return get_info_form(msg)
		.. "button[5.735,8;2,1;question_yes;Yes]"
		.. "button[2.735,8;2,1;question_no;No]"
		.. "image[4.235,4.5;2,2;ctf_clans_question.png]"
end

ui.no_clan = function(player, ctx)
	local no_clan_ht = [[
		<global valign=middle>
		<center><b>You are currently not a member of any clan.</b>
		You have the option to start your own clan or join an existing one by accepting an invitation.</center>
	]]
	return back_to_main_button
		.. "hypertext[0,0;10.47,11.35;h;" .. no_clan_ht .. "]"
		.. "button[3.73,7.235;3,1;new_clan;I want a new clan]"
end

ui.invite = function(player, ctx)
	local msg = "<b>Enter the name of the player you would like to invite</b>"
	local elems = "button[7.03,4.5;2,1;invite_send;Send Invite]"
		.. "field[2,4.5;5,1;invite_playername;Player Name;" .. (ctx.invite_field or "") .. "]"

	if ctx.invite_error then
		msg = "<style color=red><b>" .. ctx.invite_error .. "</b></style>"
		ctx.invite_error = nil
	end

	return back_to_main_button .. get_info_form(msg) .. elems
end

ui.clan_manager = function(player, ctx, id)
	local this_clan = ctf_clans.get_clan(id)
	if not this_clan then return end

	ctx.page = "clan_manager"
	local list = ""
	local first = true
	local table_imgs = {}
	ctx.playerlist = {}
	local icon_i = 0

	for pn, def in pairs(this_clan.members) do
		table.insert(ctx.playerlist, pn)
		local role_name = def.role

		if role_name ~= "member" then
			pn = string.format("%s [%s]", pn, role_name)
		end

		local icon = ctf_clans.get_role_icon(this_clan.roles[role_name])
		local col_img
		if icon then
			if table_imgs[icon] then
				col_img = table_imgs[icon]
			else
				icon_i = icon_i + 1
				table_imgs[icon] = icon_i
				col_img = icon_i
			end
		end

		if first then
			first = false
		else
			list = list .. ","
		end

		list = list .. (col_img or "") .. "," .. minetest.formspec_escape(pn)

	end

	local column_imgs = "image"
	for fn, i in pairs(table_imgs) do
		column_imgs = column_imgs .. "," .. string.format("%d=%s", i, fn)
	end
	local ht = "hypertext[0.1,0.1;10.3,1;h;<global valign=middle color=" .. this_clan.color .."><big>" .. this_clan.clan_name
		.. "<img name=default_dirt.png width=25 height=25 float=left>]"

	local formspec = "box[0,0.1;10.47,1;black]" --title bar
		.. ht
		.. "box[5.235,1.1;5.235,10.2;gray]" -- members list background
		.. "hypertext[0,1.1;5.235,10.2;h;" .. (minetest.formspec_escape(this_clan.board or "")) .. "]" -- Clan Board
		.. "tablecolumns[" .. column_imgs .. ";text]"
		.. "tableoptions[highlight=#777777]"
		.. "table[5.4,1.3;4.9,8.8;playerlist;" .. list .. "]"

	local player_name = player:get_player_name()

	local title_bar_buttons = {
		"button[%s,%s;%s,%s;options_list;Options]"
	}

	if ctf_clans.has_permission(id, player_name, "invite") then
		table.insert(title_bar_buttons, 1, "button[%s,%s;%s,%s;invite;Invite]")
	end

	formspec = formspec .. ctf_clans.generate_element_layout(title_bar_buttons, {
		direction = "horizontal",
		pos_start = {8.3, 0.2},
		size = {2, 0.8},
		spacing = 0.1,
		reverse = true
	})

	if ctx.playerlist_selected then
		local pl_elements = {}
		local perm_set_role = ctf_clans.has_permission(id, player_name, "set_role")
		local perm_kick = ctf_clans.has_permission(id, player_name, "kick")

		if perm_set_role or perm_kick then
			if not ctx.member_options_bar then
				table.insert(pl_elements, "image_button[%s,%s;%s,%s;ctf_clans_modify.png;member_options_bar;]")
			else
				ctx.member_options_bar = nil

				if perm_set_role then
					table.insert(pl_elements, "image_button[%s,%s;%s,%s;ctf_clans_roles.png;set_role;]")
				end

				if perm_kick then
					table.insert(pl_elements, "image_button[%s,%s;%s,%s;ctf_clans_kick.png;kick;]")
				end
			end
		end

		formspec = formspec .. ctf_clans.generate_element_layout(pl_elements, {
			direction = "horizontal",
			pos_start = {5.4, 10.2},
			size = {0.8, 0.8},
			spacing = 0.1,
		})
	end

	return formspec
end

ui.set_role = function(player, ctx, id)
	ctx.rolelist = {}
	local this_clan = ctf_clans.get_clan(id)
	if not this_clan then return end
	local list = ""
	local table_imgs = {}
	local first = true
	local icon_i = 0
	for role_name, def in pairs(this_clan.roles) do
		table.insert(ctx.rolelist, role_name)
		local icon = ctf_clans.get_role_icon(def)
		local col_img
		if icon then
			if table_imgs[icon] then
				col_img = table_imgs[icon]
			else
				icon_i = icon_i + 1
				table_imgs[icon] = icon_i
				col_img = icon_i
			end
		end

		if first then
			first = false
		else
			list = list .. ","
		end

		list = list .. (col_img or "") .. "," .. minetest.formspec_escape(role_name)
	end

	local column_imgs = "image"
	for fn, i in pairs(table_imgs) do
		column_imgs = column_imgs .. "," .. string.format("%d=%s", i, fn)
	end

	local msg = "Select a role for: " .. ctx.playerlist_selected
	if ctx.set_role_error then
		msg = "<style color=red><b>" .. ctx.set_role_error .. "</b></style>"
		ctx.set_role_error = nil
	end

	return back_to_main_button
		.. get_info_form(msg)
		.. "button[4.235,8;2,1;set_role_apply;Apply]"
		.. "tablecolumns[".. column_imgs .. ";text]"
		.. "table[0.5,3;9.5,4.5;rolelist;" .. list .. "]"
end

ui.options_list = function()
	local buttons = {
		{"show_clanboard_editor", "Edit Clan Board"},
		{"change_namecolor", "Name Color"},
		{"change_clanicon", "Icon"},
	}

	local elements = {}
	for _, bt in ipairs(buttons) do
		table.insert(elements, "button[%s,%s;%s,%s;" .. bt[1] .. ";" .. bt[2] .. "]")
	end

	local formspec = ctf_clans.generate_element_layout(elements, {
		direction = "vertical",
		pos_start = {4.035, 3.5},
		size = {2.4, 0.8},
		spacing = 0.1,
	})

	return back_to_main_button
		.. get_info_form("What would you like to change?")
		.. formspec
end

ui.clanboard_editor = function(player, ctx, id)
	local this_clan = ctf_clans.get_clan(id)
	if not this_clan then return end

	local formspec = "textarea[0,1.1;10.42,8.8;clanboard_textarea;;" .. minetest.formspec_escape(this_clan.board or "") .. "]"
	.. "button[1.25,10;4,0.8;clanboard_save;Save]"
	.. "button[5.75,10;4,0.8;back_to_main;Cancel]"

	-- sfse.open_formspec(player:get_player_name(), "", "size[10.47,11.35]" .. back_to_main_button .. formspec)

	return formspec
end


sfinv.register_page("sfinv:clans", {
	title = "Clans",
	get = function(self, player, context)
		local ctx = context.clan_ui
		local player_name = player:get_player_name()
		local id = ctf_clans.get_clan_id(player_name)
		local fs
		if ctx.page and ui[ctx.page] then
			fs = ui[ctx.page](player, ctx, id)
		else
			if id then
				if not ctf_clans.player_is_clan_member(id, player_name) then
					return sfinv.make_formspec_v7(player, context, "label[0,0.5;Sorry! Something went wrong...\n"
					.. player_name .. " is in a non-existent clan " ..  id
					.. "\nPlease report it to the server stuff", false)
				end

				fs = ui.clan_manager(player, ctx, id)
			else
				fs = ui.no_clan(player, ctx)
			end
		end

		return sfinv.make_formspec_v7(player, context, fs, false)
	end,

	on_player_receive_fields = function(self, player, context, fields)
		local player_name = player:get_player_name()
		local ctx = context.clan_ui
		local id = ctf_clans.get_clan_id(player_name)
		if not ctf_clans.is_clan_exist(id) then
			if fields.new_clan then
				ctf_clans.show_clan_maker(player_name)
			end
			ctx.page = "no_clan"
			return true, true
		end

		local this_clan = ctf_clans.get_clan(id)
		if not this_clan then return end

		local update_fs = false

		if fields.back_to_main then
			ctx.page = "clan_manager"
			ctx.invite_field = nil
			update_fs = true

		elseif fields.invite then
			ctx.page = "invite"
			update_fs = true

		elseif fields.invite_send then
			if not ctf_clans.has_permission(id, player_name, "invite") then
				msg_denied(ctx)
				return true, true
			end

			local target = fields.invite_playername:trim()
			if target:match("^%s*$") == nil then
				ctx.invite_field = target
				if target ~= player_name then
					if minetest.player_exists(target) then
						if ctf_clans.get_clan_id(target) then
							ctx.invite_error = "This player is already a member of another clan, you cannot invite them"
						else
							ctf_clans.invite_player(target, player_name, id)

							ctx.page = "info_form"
							ctx.info = {
								msg = "An invitation has been sent to " .. target,
								status = true,
								bold = true,
								color = "lime"
							}
						end
					else
						ctx.invite_error = "This player does not exist"
					end
				else
					ctx.invite_errorr_msg = "Are you serious? Good luck, hacker xD"
				end
			else
				ctx.invite_error = "Player name not provided"
			end

			update_fs = true

		elseif fields.playerlist then
			local event = minetest.explode_table_event(fields.playerlist)
			local player_index = event.row
			if ctx.playerlist[player_index] then
				ctx.playerlist_selected = ctx.playerlist[player_index]
				update_fs = true
			end

		elseif fields.set_role then
			if ctx.playerlist_selected then
				ctx.page = "set_role"
			end
			update_fs = true

		elseif fields.rolelist then
			local event = minetest.explode_table_event(fields.rolelist)
			local role_index = event.row
			if ctx.rolelist[role_index] then
				ctx.role_selected = role_index
				update_fs = true
			end

		elseif fields.set_role_apply then
			if not ctf_clans.has_permission(id, player_name, "set_role") then
				msg_denied(ctx)
				return true, true
			end

			if ctx.role_selected and ctx.playerlist_selected then
				local selected_name = ctx.playerlist_selected
				-- if selected_name == player_name then
				-- 	return true
				-- end

				local role_name = ctx.rolelist[ctx.role_selected]

				ctx.page = "info_form"
				if ctf_clans.set_member_role(id, selected_name, role_name) then
					ctx.rolelist = nil
					ctx.info = {
						msg = selected_name  .. "'s role has been changed to " .. role_name,
						status = true,
						bold = true
					}
				else
					ctx.info = {
						msg = "Failed to change",
						status = false,
						bold = true
					}
				end
			end
			update_fs = true

		elseif fields.kick then
			if not ctf_clans.has_permission(id, player_name, "kick") then
				msg_denied(ctx)
				return true, true
			end

			local selected_name = ctx.playerlist_selected
			if selected_name then
				if selected_name == player_name and ctf_clans.has_permission(id, player_name, "owner") then
					ctx.page = "info_form"
					ctx.info = {
						msg = "You can't kick yourself, you're the owner.",
						status = false,
						color = "red",
						bold = true
					}
					return true, true
				end

				ctx.page = "question_form"
				ctx.question = {
					msg = "Kick " .. selected_name.. "?",
					bold = true,

					callback_yes = function(player, ctx)
						if ctf_clans.remove_member(id, selected_name) then
							ctx.page = "info_form"
							ctx.info = {
								msg = "The player " .. selected_name .. " has been kicked",
								status = true,
								bold = true
							}
							minetest.chat_send_player(selected_name, "You are no longer a member of the clan " .. this_clan.clan_name)
						end
						return true, true
					end,

					callback_no = function(player, ctx)
						ctx.page = "clan_manager"
						return true, true
					end,
				}
				return true, true
			end

		elseif fields.question_yes then
			local question = ctx.question
			if question.callback_yes then
				update_fs = question.callback_yes(player, ctx)
				question = nil
			end
		elseif fields.question_no then
			local question = ctx.question
			if question.callback_no then
				update_fs = question.callback_no(player, ctx)
				question = nil
			end
		elseif fields.options_list then
			ctx.page = "options_list"
			return true, true
		elseif fields.member_options_bar then
			ctx.member_options_bar = true
			return true, true
		elseif fields.show_clanboard_editor then
			if not ctf_clans.has_permission(id, player_name, "clanboard_write") then
				msg_denied(ctx)
				return true, true
			end
				ctx.page = "clanboard_editor"
			return true, true
		elseif fields.clanboard_save then
			if not ctf_clans.has_permission(id, player_name, "clanboard_write") then
				msg_denied(ctx)
				return true, true
			end
			if type(fields.clanboard_textarea) == "string" then
				if #fields.clanboard_textarea > 1500 then
					minetest.chat_send_player(player_name, "Unable to save, text longer than 1500 characters")
					return true
				end
				this_clan.board = fields.clanboard_textarea
				ctf_clans.storage.save_clan_data(id, this_clan)
				ctx.page = "info_form"
				ctx.info = {
					msg = "The changes have been saved",
					status = true,
					bold = true
				}
				return true, true
			end
		end

		return true, update_fs
	end,

	on_enter = function(self, player, context)
		context.clan_ui = {}
	end,

	on_leave = function(self, player, context)
		context.clan_ui = nil
	end
})