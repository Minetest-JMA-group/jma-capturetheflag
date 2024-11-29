local ui_data = {}

local back_to_main_button = "box[0,0;10.47,1;black]" .. "button[9.43,0.035;1,1;back_to_main;X]"

local function get_info_form(msg)
	return "box[0,1;10.47,1.85;#202020]"
		.. "hypertext[0,1;10.47,1.85;h;<global valign=middle> <center>" .. msg .. "</center>]"
end

local formspecs = {
	info_form = function(player, ctx)
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
	end,

	question_form = function(player, ctx)
		local question = ctx.question
		local msg =  question.msg

		if question.bold then
			msg = "<b>" .. msg .. "</b>"
		end

		return get_info_form(msg)
			.. "button[5.735,8;2,1;question_yes;Yes]"
			.. "button[2.735,8;2,1;question_no;No]"
			.. "image[4.235,4.5;2,2;ctf_clans_question.png]"
	end,

	no_clan = function(player, ctx)
		local no_clan_ht = [[
			<global valign=middle>
			<center><b>You are currently not a member of any clan.</b>
			You have the option to start your own clan or join an existing one by accepting an invitation.</center>
		]]
		return back_to_main_button
			.. "hypertext[0,0;10.47,11.35;h;" .. no_clan_ht .. "]"
			.. "button[3.73,7.235;3,1;new_clan;I want a new clan]"
	end,

	invite = function(player, ctx)
		local msg = "<b>Enter the name of the player you would like to invite</b>"
		local elems = "button[7.03,4.5;2,1;invite_send;Send Invite]"
			.. "field[2,4.5;5,1;invite_playername;Player Name;" .. (ctx.invite_field or "") .. "]"

		if ctx.invite_error then
			msg = "<style color=red><b>" .. ctx.invite_error .. "</b></style>"
			ctx.invite_error = nil
		end

		return back_to_main_button .. get_info_form(msg) .. elems
	end,

	clan_manager = function(player, ctx, id)
		local this_clan = ctf_clans.get_clan_def(id)
		if not this_clan then return end

		ctx.page = "clan_manager"
		local list = ""
		local first = true
		local table_imgs = {}
		ctx.playerlist = {}
		local icon_i = 0

		for pn, def in pairs(this_clan.members) do
			table.insert(ctx.playerlist, pn)
			local rank_name = def.rank

			if rank_name ~= "member" then
				pn = string.format("%s [%s]", pn, rank_name)
			end

			local icon = ctf_clans.get_rank_icon(this_clan.ranks[rank_name])
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
			.. "hypertext[0,1.1;5.235,10.2;h;<center><b>Description</b></center>\n" .. (this_clan.board or "") .. "]" -- description
			.. "tablecolumns[" .. column_imgs .. ";text]"
			.. "tableoptions[highlight=#777777]"
			.. "table[5.4,1.3;4.9,8.8;playerlist;" .. list .. "]"
			.. "button[6.2,0.2;2,0.8;options_list;Options]"

		local player_name = player:get_player_name()

		if ctf_clans.has_permission(id, player_name, "invite") then
			formspec = formspec .. "button[8.3,0.2;2,0.8;invite;Invite]"
		end

		if ctx.playerlist_selected then
			local pl_elements = {}
			if not ctx.member_options_bar then
				table.insert(pl_elements, "image_button[%s,%s;%s,%s;ctf_clans_modify.png;member_options_bar;]")
			else
				if ctf_clans.has_permission(id, player_name, "kick") then
					table.insert(pl_elements, "button[%s,%s;%s,%s;kick;Kick]")

				end

				if ctf_clans.has_permission(id, player_name, "set_rank") then
					table.insert(pl_elements, "button[%s,%s;%s,%s;set_rank;Set Rank]")
				end
			end

			formspec = formspec .. ctf_clans.generate_element_layout(pl_elements, {
				direction = "horizontal",
				pos_start = {5.4, 10.2},
				size = {0.8, 0.8},
				spacing = 0.1,
			})
		end

		-- sfse.open_formspec(player_name, "", "size[10.47,11.35]" .. formspec)
		return formspec
	end,

	set_rank = function(player, ctx, id)
		ctx.ranklist = {}
		local this_clan = ctf_clans.get_clan_def(id)
		if not this_clan then return end
		local list = ""
		local table_imgs = {}
		local first = true
		local icon_i = 0
		for rank_name, def in pairs(this_clan.ranks) do
			table.insert(ctx.ranklist, rank_name)
			local icon = ctf_clans.get_rank_icon(def)
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

			list = list .. (col_img or "") .. "," .. minetest.formspec_escape(rank_name)
		end

		local column_imgs = "image"
		for fn, i in pairs(table_imgs) do
			column_imgs = column_imgs .. "," .. string.format("%d=%s", i, fn)
		end

		local msg = "Select a rank"
		if ctx.set_rank_error then
			msg = "<style color=red><b>" .. ctx.set_rank_error .. "</b></style>"
			ctx.set_rank_error = nil
		end

		return back_to_main_button
			.. get_info_form(msg)
			.. "button[4.235,8;2,1;set_rank_apply;Apply]"
			.. "tablecolumns[".. column_imgs .. ";text]"
			.. "table[0.5,3;9.5,4.5;ranklist;" .. list .. "]"
	end,

	options_list = function()
		local buttons = {
			{"change_desc", "Description"},
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
	end,
}

sfinv.register_page("sfinv:clans", {
	title = "Clans",
	get = function(self, player, context)
		local player_name = player:get_player_name()
		local ctx = ui_data[player_name]
		local id = ctf_clans.get_clan_id(player_name)
		local fs = ""
		if ctx.page and formspecs[ctx.page] then
			fs = formspecs[ctx.page](player, ctx, id)
		else
			if id then
				fs = formspecs.clan_manager(player, ctx, id)
			else
				fs = formspecs.no_clan(player, ctx)
			end
		end

		return sfinv.make_formspec_v7(player, context, fs, false)
	end,

	on_player_receive_fields = function(self, player, context, fields)
		local player_name = player:get_player_name()
		local ctx = ui_data[player_name]
		local id = ctf_clans.get_clan_id(player_name)
		if not ctf_clans.is_clan_exist(id) then
			if fields.new_clan then
				ctf_clans.show_clan_maker(player_name)
			end
			ctx.page = "no_clan"
			return true, true
		end

		local clan_def = ctf_clans.get_clan_def(id)
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
				ctx.page = "info_form"
				ctx.info = {
					msg = "Insufficient privileges",
					status = true,
					color = "red",
					bold = true
				}
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

		elseif fields.set_rank then
			if ctx.playerlist_selected then
				ctx.page = "set_rank"
			end
			update_fs = true

		elseif fields.ranklist then
			local event = minetest.explode_table_event(fields.ranklist)
			local rank_index = event.row
			if ctx.ranklist[rank_index] then
				ctx.rank_selected = rank_index
				update_fs = true
			end

		elseif fields.set_rank_apply then
			if not ctf_clans.has_permission(id, player_name, "set_rank") then
				ctx.page = "info_form"
				ctx.info = {
					msg = "Insufficient privileges",
					status = true,
					color = "red",
					bold = true
				}
				return true, true
			end

			if ctx.rank_selected and ctx.playerlist_selected then
				local selected_name = ctx.playerlist_selected
				if selected_name == player_name then
					return true
				end

				local rank_name = ctx.ranklist[ctx.rank_selected]

				if rank_name == "owner" then
					ctx.set_rank_error = "The rank cannot be changed to \"Owner\""
					return true, true
				end

				ctx.page = "info_form"
				if ctf_clans.set_member_rank(id, selected_name, rank_name) then
					ctx.ranklist = nil
					ctx.info = {
						msg = selected_name  .. "'s rank has been changed to " .. rank_name,
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
				ctx.page = "info_form"
				ctx.info = {
					msg = "Insufficient privileges",
					status = true,
					color = "red",
					bold = true
				}
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
							minetest.chat_send_player(selected_name, "You are no longer a member of the clan " .. clan_def.clan_name)
						end
						return true
					end,

					callback_no = function(player, ctx)
						ctx.page = "clan_manager"
						return true
					end,
				}
			end
			update_fs = true

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
		end


		return true, update_fs
	end,

	on_enter = function(self, player, context)
		ui_data[player:get_player_name()] = {}
	end,

	on_leave = function(self, player, context)
		ui_data[player:get_player_name()] = nil
	end
})