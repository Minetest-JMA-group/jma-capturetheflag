local blacklist = {
	"default:pine_needles",
	".*leaves$",
	"ctf_melee:sword_stone",
	"default:pick_stone",
}

local S = core.get_translator(core.get_current_modname())

--- Table to track which chest each player is currently viewing
local player_chest_positions = {}

--- Does the player have access to the chest?
--- Example usage: `has_normal, has_pro = get_chest_access(name)`
--- @param name PlayerName
--- @return boolean, boolean
local function get_chest_access(name)
	local current_mode = ctf_modebase:get_current_mode()
	if not current_mode then
		return false, false
	end

	return current_mode.get_chest_access(name)
end

--- @param listname string | "helper"
--- @param stack ItemStack
--- @return boolean
function ctf_teams.is_allowed_in_team_chest(listname, stack)
	if listname == "helper" then
		return false
	end

	for _, itemstring in ipairs(blacklist) do
		if stack:get_name():match(itemstring) then
			return false
		end
	end

	return true
end

for _, team in ipairs(ctf_teams.teamlist) do
	if not ctf_teams.team[team].not_playing then
		local chestcolor = ctf_teams.team[team].color
		local function get_chest_texture(chest_side, color, mask, extra)
			return string.format(
				"(default_chest_%s.png"
					.. "^[colorize:%s:130)"
					.. "^(default_chest_%s.png"
					.. "^[mask:ctf_teams_chest_%s_mask.png"
					.. "^[colorize:%s:60)"
					.. "%s",
				chest_side,
				color,
				chest_side,
				mask,
				color,
				extra or ""
			)
		end

		local def = {
			description = S("@1 Team's chest", HumanReadable(team)),
			tiles = {
				get_chest_texture("top", chestcolor, "top"),
				get_chest_texture("top", chestcolor, "top"),
				get_chest_texture("side", chestcolor, "side"),
				get_chest_texture("side", chestcolor, "side"),
				get_chest_texture("side", chestcolor, "side"),
				get_chest_texture("front", chestcolor, "side", "^ctf_teams_lock.png"),
			},
			paramtype2 = "facedir",
			groups = { immortal = 1, team_chest = 1 },
			legacy_facedir_simple = true,
			is_ground_content = false,
			sounds = default.node_sound_wood_defaults(),
		}

		function def.on_construct(pos)
			local meta = core.get_meta(pos)
			meta:set_string("infotext", S("@1 Team's Chest", HumanReadable(team)))

			local inv = meta:get_inventory()
			inv:set_size("main", 6 * 7)
			inv:set_size("pro", 4 * 7)
			inv:set_size("helper", 1 * 1)
		end

		function def.can_dig(pos, player)
			return false
		end

		function def.on_rightclick(pos, node, player)
			local name = player:get_player_name()

			local flag_captured = ctf_modebase.flag_captured[team]
			if not flag_captured and team ~= ctf_teams.get(name) then
				hud_events.new(player, {
					quick = true,
					text = S("You're not on team @1", HumanReadable(team)),
					color = "warning",
				})
				return
			end

			local formspec = table.concat({
				"size[10,12]",
				default.get_hotbar_bg(1.4, 7.85),
				"list[current_player;main;1.4,7.85;8,1;]",
				"list[current_player;main;1.4,9.08;8,3;8]",
			}, "")

			local reg_access, pro_access
			if not flag_captured and ctf_rankings.backend ~= "dummy" then
				reg_access, pro_access = get_chest_access(name)
			else
				reg_access, pro_access = true, true
			end

			if reg_access ~= true then
				local msg = tostring(reg_access) or S("You aren't allowed to access the team chest")
				formspec = formspec
					.. "label[0.75,3;"
					.. core.formspec_escape(
						core.wrap_text(msg, 60)
					)
					.. "]"

				core.show_formspec(name, "ctf_teams:no_access", formspec)
				return
			end

			local chestinv = "nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z

			formspec = formspec
				.. "list["
				.. chestinv
				.. ";main;0,0.3;6,7;]"
				.. "background[6,-0.2;4.15,7.7;ctf_map_pro_section.png;false]"

			if pro_access == true then
				formspec = formspec
					.. "list["
					.. chestinv
					.. ";pro;6,0.3;4,7;]"
					.. "listring["
					.. chestinv
					.. ";pro]"
					.. "listring["
					.. chestinv
					.. ";helper]"
					.. "label[7,-0.2;"
					.. core.formspec_escape(S("Pro players only"))
					.. "]"
			else
				local msg = tostring(pro_access) or S("You aren't allowed to access the pro section")
				formspec = formspec
					.. "label[6.5,2;"
					.. core.formspec_escape(
						core.wrap_text(msg, 20)
					)
					.. "]"
			end

			formspec = formspec
			    .. "label[0,7.3;Take ammo]"
				.. "image_button[0,7.85;0.9,0.9;ctf_ranged_ammo.png;ammo_1;1]"
				.. "image_button[0,8.75;0.9,0.9;ctf_ranged_ammo.png;ammo_3;3]"
				.. "image_button[0,9.65;0.9,0.9;ctf_ranged_ammo.png;ammo_6;6]"
				.. "listring["
				.. chestinv
				.. ";main]"
				.. "listring[current_player;main]"

			-- Store position for field handler
			player_chest_positions[name] = { pos = pos, team = team }
			core.show_formspec(name, "ctf_teams:chest", formspec)
		end

		function def.allow_metadata_inventory_move(
			pos,
			from_list,
			from_index,
			to_list,
			to_index,
			count,
			player
		)
			local name = player:get_player_name()

			if team ~= ctf_teams.get(name) then
				hud_events.new(player, {
					quick = true,
					text = S("You're not on team") .. " " .. team,
					color = "warning",
				})
				return 0
			end

			local reg_access, pro_access = get_chest_access(name)

			if ctf_rankings.backend == "dummy" then
				reg_access, pro_access = true, true
			end

			if
				reg_access == true
				and (pro_access == true or from_list ~= "pro" and to_list ~= "pro")
			then
				if to_list == "helper" then
					-- handle move & overflow
					local chestinv = core.get_inventory({ type = "node", pos = pos })
					local playerinv = player:get_inventory()
					local stack = chestinv:get_stack(from_list, from_index)
					local leftover = playerinv:add_item("main", stack)
					local n_stack = stack
					n_stack:set_count(stack:get_count() - leftover:get_count())
					chestinv:remove_item("helper", stack)
					chestinv:remove_item("pro", n_stack)
					return 0
				elseif from_list == "helper" then
					return 0
				else
					return count
				end
			else
				return 0
			end
		end

		function def.allow_metadata_inventory_put(pos, listname, index, stack, player)
			local name = player:get_player_name()

			if team ~= ctf_teams.get(name) then
				hud_events.new(player, {
					quick = true,
					text = S("You're not on team") .. " " .. team,
					color = "warning",
				})
				return 0
			end

			if not ctf_teams.is_allowed_in_team_chest(listname, stack) then
				return 0
			end

			local reg_access, pro_access = get_chest_access(name)

			if ctf_rankings.backend == "dummy" then
				reg_access, pro_access = true, true
			end

			if reg_access == true and (pro_access == true or listname ~= "pro") then
				local chestinv = core.get_inventory({ type = "node", pos = pos })
				if chestinv:room_for_item("pro", stack) then
					return stack:get_count()
				else
					-- handle overflow
					local playerinv = player:get_inventory()
					local leftovers = chestinv:add_item("pro", stack)
					local leftover = chestinv:add_item("main", leftovers)
					local n_stack = stack
					n_stack:set_count(stack:get_count() - leftover:get_count())
					playerinv:remove_item("main", n_stack)
					return 0
				end
			else
				return 0
			end
		end

		function def.allow_metadata_inventory_take(pos, listname, index, stack, player)
			if listname == "helper" then
				return 0
			end

			if ctf_modebase.flag_captured[team] then
				return stack:get_count()
			end

			local name = player:get_player_name()

			if team ~= ctf_teams.get(name) then
				hud_events.new(player, {
					quick = true,
					text = S("You're not on team") .. " " .. team,
					color = "warning",
				})
				return 0
			end

			local reg_access, pro_access = get_chest_access(name)

			if ctf_rankings.backend == "dummy" then
				reg_access, pro_access = true, true
			end

			if reg_access == true and (pro_access == true or listname ~= "pro") then
				return stack:get_count()
			else
				return 0
			end
		end

		function def.on_metadata_inventory_put(pos, listname, index, stack, player)
			local meta = stack:get_meta()
			local dropped_by = meta:get_string("dropped_by")
			local pname = player:get_player_name()
			core.log(
				"action",
				string.format(
					"%s puts %s to team chest at %s. Dropped by is: %s",
					pname,
					stack:to_string(),
					core.pos_to_string(pos),
					dropped_by or "<EMPTY_STRING>"
				)
			)
			local dropteam = ctf_teams.get(dropped_by)
			if dropped_by ~= pname and dropped_by ~= "" and dropteam then
				local cur_mode = ctf_modebase:get_current_mode()
				if pname and cur_mode then
					local item_name = stack:get_name()
					local score = cur_mode.get_item_value(item_name, pos)
					core.debug(
						"We are supposed to give score for "
							.. item_name
							.. " and its value is "
							.. tostring(score)
					)
					if score > 0 then
						local item_desc = stack:get_short_description()
						if item_desc == "" then
							item_desc = item_name
						end

						cur_mode.recent_rankings.add(pname, { score = score }, true)
						cmsg.push_message_player(
							player,
							"+ " .. score .. ": " .. item_desc
						)
					end
				end
			end
			meta:set_string("dropped_by", "")
			local inv = core.get_inventory({ type = "node", pos = pos })
			local stack_ = inv:get_stack(listname, index)
			stack_:get_meta():set_string("dropped_by", "")
			inv:set_stack(listname, index, stack_)
		end

		function def.on_metadata_inventory_take(pos, listname, index, stack, player)
			core.log(
				"action",
				string.format(
					"%s takes %s from team chest at %s",
					player:get_player_name(),
					stack:to_string(),
					core.pos_to_string(pos)
				)
			)
		end

		core.register_node("ctf_teams:chest_" .. team, def)
	end
end

--- Handle quick ammo button clicks
core.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "ctf_teams:chest" then
		return
	end

	local name = player:get_player_name()
	local chest_data = player_chest_positions[name]

	if not chest_data then
		return
	end

	local amount = nil
	if fields.ammo_1 then
		amount = 1
	elseif fields.ammo_3 then
		amount = 3
	elseif fields.ammo_6 then
		amount = 6
	else
		return
	end

	local pos = chest_data.pos
	local team = chest_data.team

	-- Check if player still has access
	local flag_captured = ctf_modebase.flag_captured[team]
	if not flag_captured and team ~= ctf_teams.get(name) then
		return
	end

	local reg_access, pro_access = get_chest_access(name)

	if ctf_rankings.backend == "dummy" then
		reg_access, pro_access = true, true
	end

	if reg_access ~= true then
		return
	end

	-- Get inventories
	local chest_inv = core.get_inventory({ type = "node", pos = pos })
	local player_inv = player:get_inventory()
	local ammo_itemstring = "ctf_ranged:ammo"

	local total_taken = ItemStack()
	local remaining = amount

	-- Try pro section first if they have access
	if pro_access == true then
		local pro_taken = chest_inv:remove_item("pro", ammo_itemstring .. " " .. remaining)
		total_taken:add_item(pro_taken)
		remaining = remaining - pro_taken:get_count()
	end

	-- Take from main section for remaining
	if remaining > 0 then
		local main_taken = chest_inv:remove_item("main", ammo_itemstring .. " " .. remaining)
		total_taken:add_item(main_taken)
	end

	-- Add to player inventory
	local leftover = player_inv:add_item("main", total_taken)

	-- Return any leftover to the chest
	if leftover:get_count() > 0 then
		chest_inv:add_item("main", leftover)
	end
end)
