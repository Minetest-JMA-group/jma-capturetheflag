-- Modified version of Itemshelf (https://github.com/hkzorman/itemshelf) by Zorman2000

local player_ctx = {}

local function get_shelf_formspec(inv_size, pos)
	local pos_string = pos.x .. "," .. pos.y .. "," .. pos.z
	return "size[8,7]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..

		"list[nodemeta:"..pos_string..";main;"..(math.abs((inv_size / 2) - 8) / 2)..",0.25;"..(inv_size / 2)..",2;]"..
		"list[current_player;main;0,2.75;8,1;]"..
		"list[current_player;main;0,4;8,3;8]"..
		"listring[detached:itemshelf_"..pos_string..";main]"..
		"listring[current_player;main]"
end

local icon_size = 1
local icon_spacing = 0.3
local button_width = 0.8
local button_spacing = 0.1
local buttons_start_x = 0.15
local button_values = {1, 4, 8, 16}

local function show_user_formspec(name)
	local ctx = player_ctx[name]
	if not ctx then
		core.log("error", "itemshelf: nil context for player "..name)
		return
	end

	local inv = core.get_inventory({type="node", pos=ctx.pos})
	if not inv then
		ctx = nil
		return
	end

	local list = inv:get_list("main")

	local count = 0
	for i = 1, ctx.inv_size do
		if list[i] and not list[i]:is_empty() then
			count = count + 1
		end
	end

	local total_width = count * icon_size + (count > 1 and (count - 1) * icon_spacing or 0)
	local area_width = 8
	local start_x = buttons_start_x + ((area_width - total_width) / 2)

	local fs = "formspec_version[7]size[10,9.7]" ..
		default.gui_bg .. default.gui_bg_img ..
		"box[0,3.5;10,1;#202232]" ..
		"box[0,1.25;10,1.35;#111111]" ..
		"list[current_player;main;0.15,4.75;8,4]" ..
		"list[detached:trash;main;0.1,3.5;1,1]" ..
		"image[0.17,3.6;0.8,0.8;creative_trash_icon.png]" ..
		"button[8.02,3.5;1.9,1;clear_inv;Trash all]"

	local b = 0
	for _, i in ipairs(button_values) do
		b = b + 1
		local btn_x = buttons_start_x + (b + 1.2) * (button_width + button_spacing)
		local btn_name = string.format("amount_%d", i)
		if i == ctx.amount then
			fs = fs .. "style[" .. btn_name .. ";bgcolor=green]"
		end
		fs = fs .. string.format(
			"button[%f,3.7;%f,0.6;%s;%d]",
			btn_x, button_width, btn_name, i
		)
	end

	local pos_string = core.pos_to_string(ctx.pos)
	local idx = 1
	for i = 1, ctx.inv_size do
		local stack = list[i]
		if stack and not stack:is_empty() then
			local itemname = stack:get_name()
			local x = start_x + (idx - 0.4) * (icon_size + icon_spacing)

			local btn_name = string.format("%s|%s", pos_string, itemname)
			fs = fs .. string.format(
				"item_image_button[%f,1.4;%f,%f;%s;%s;]", x, icon_size, icon_size, core.formspec_escape(itemname), btn_name
			)
			idx = idx + 1
		end
	end
	if idx == 1 then
		fs = fs .. "label[0.1,1;No items here! Please report this to Nanowolf4 (n4w@tutanota.com)"
	end

	core.show_formspec(name, "itemshelf:shelf", fs)
	-- sfse.open_formspec(name, "itemshelf:shelf", fs)
end

core.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "itemshelf:shelf" then
		return
	end

	local name = player:get_player_name()
	local ctx = player_ctx[name]
	for field, _ in pairs(fields) do
		if field == "quit" then
			ctx = nil
			return true
		elseif field:match("^amount_") then
			local amount = tonumber(field:match("^amount_(%d+)$")) or 1
			ctx.amount = math.min(amount, 16)
			show_user_formspec(name)
			return true
		elseif field == "clear_inv" then
			local pinv = core.get_inventory({type="player", name=name})
			for i = 1, pinv:get_size("main") do
				local stack = pinv:get_stack("main", i)
				if not stack:get_name():match("^ctf_jma_elysium") then
					pinv:set_stack("main", i, ItemStack(""))
				end
			end
			return true
		end

		local p = field:split("|")
		local pos_str = p[1]
		local itemname = p[2]
		if not pos_str or not itemname then
			core.log("error", "itemshelf: Invalid field name parsing: "..field)
			return true
		end
		local pos = core.string_to_pos(pos_str)
		if not pos then
			core.log("error", "itemshelf: Invalid position string: "..pos_str)
			return true
		end
		local inv = core.get_inventory({type="node", pos=pos})
		if not inv then
			core.log("error", "itemshelf: Failed to get inventory at "..core.pos_to_string(pos))
			return true
		end
		local list = inv:get_list("main")
		for i = 1, #list do
			local stack = list[i]
			if stack and stack:get_name() == itemname then
				if core.registered_tools[itemname] then
					local pinv = player:get_inventory()
					local tool_count = 0
					for j = 1, pinv:get_size("main") do
						local s = pinv:get_stack("main", j)
						if s:get_name() == itemname then
							tool_count = tool_count + 1
						end
					end
					if tool_count >= 2 then
						core.chat_send_player(name, "You can't have more than 2 of this tool.")
						break
					end
				end
				if not core.registered_tools[itemname] then
					stack:set_count(ctx.amount)
				end
				player:get_inventory():add_item("main", stack)
				break
			end
		end
	end
	return true
end)

local temp_texture
local temp_size

local function get_obj_dir(param2)
	return ((param2 + 1) % 4)
end

local function update_shelf(pos)
	-- Remove all objects
	local objs = core.get_objects_inside_radius(pos, 0.75)
	for _,obj in pairs(objs) do
		obj:remove()
	end

	local node = core.get_node(pos)
	local meta = core.get_meta(pos)
	-- Calculate directions
	local node_dir = core.facedir_to_dir(((node.param2 + 2) % 4))
	local obj_dir = core.facedir_to_dir(get_obj_dir(node.param2))
	-- Get maximum number of shown items (4 or 6)
	local max_shown_items = core.get_item_group(node.name, "itemshelf_shown_items")
	-- Get custom displacement properties
	local depth_displacement = meta:get_float("itemshelf:depth_displacement")
	local vertical_displacement = meta:get_float("itemshelf:vertical_displacement")
	if depth_displacement == 0 then
		depth_displacement = 0.25
	end
	if vertical_displacement == 0 then
		vertical_displacement = 0.2375
	end
	core.log("displacements: "..dump(depth_displacement)..", "..dump(vertical_displacement))
	-- Calculate the horizontal displacement. This one is hardcoded so that either 4 or 6
	-- items are properly displayed.
	local horizontal_displacement = 0.715
	if max_shown_items == 6 then
		horizontal_displacement = 0.555
	end

	-- Calculate initial position for entities
	local start_pos = {
		x=pos.x - (obj_dir.x * horizontal_displacement) + (node_dir.x * depth_displacement),
		y=pos.y + vertical_displacement,
		z=pos.z - (obj_dir.z * horizontal_displacement) + (node_dir.z * depth_displacement)
	}

	-- Calculate amount of objects in the inventory (use node inventory as source of truth)
	local inv = core.get_inventory({type="node", pos=pos})
	if not inv then
		return
	end
	local list = inv:get_list("main")
	local obj_count = 0
	for key, itemstack in pairs(list) do
		if not itemstack:is_empty() then
			obj_count = obj_count + 1
		end
	end
	core.log("Found "..dump(obj_count).." items on shelf inventory")
	if obj_count > 0 then
		local shown_items = math.min(#list, max_shown_items)
		for i = 1, shown_items do
			local offset = i
			if i > (shown_items / 2) then
				offset = i - (shown_items / 2)
			end
			if i == ((shown_items / 2) + 1) then
				start_pos.y = start_pos.y - 0.5125
			end
			local item_displacement = 0.475
			if shown_items == 6 then
				item_displacement = 0.2775
			end
			local obj_pos = {
				x=start_pos.x + (item_displacement * offset * obj_dir.x),
				y=start_pos.y,
				z=start_pos.z + (item_displacement * offset * obj_dir.z)
			}

			if not list[i]:is_empty() then
				core.log("Adding item entity at "..core.pos_to_string(obj_pos))
				temp_texture = list[i]:get_name()
				temp_size = 0.8/max_shown_items
				local ent = core.add_entity(obj_pos, "itemshelf:item")
				ent:set_properties({
					wield_item = temp_texture,
					visual_size = {x = 0.8/max_shown_items, y = 0.8/max_shown_items}
				})
				ent:set_yaw(core.dir_to_yaw(core.facedir_to_dir(node.param2)))
			end
		end
	end
end

local function can_modify_inv(player)
	local wielditem = player:get_wielded_item()
	if core.get_player_privs(player:get_player_name()).ctf_admin and wielditem:get_name() == "itemshelf:admin_key" then
		return true
	end
end

itemshelf = {}

-- Definable properties:
--   - description
--   - textures (if drawtype is nodebox)
--   - nodebox (like default core.register_node def)
--   - mesh (like default core.register_node def)
--   - item capacity (how many items will fit into the shelf, use even numbers, max 16)
--   - shown_items (how many items to show, will always show first (shown_items/2) items of each row, max 6)
--   - `half-depth`: if set to true, will use different nodebox. Do not use with `depth_offset`
--   - `vertical_offset`: starting position vertical displacement from the center of the node
--   - `depth_offset`: starting position depth displacement from the center of the node
function itemshelf.register_shelf(name, def)
	-- Determine drawtype
	local drawtype = "nodebox"
	if def.mesh then
		drawtype = "mesh"
	end

	core.register_node("itemshelf:"..name, {
		description = def.description,
		tiles = def.textures,
		paramtype = "light",
		paramtype2 = "facedir",
		drawtype = drawtype,
		node_box = def.nodebox,
		mesh = def.mesh,
		groups = {choppy = 2, itemshelf = 1, itemshelf_shown_items = def.shown_items or 4},
		use_texture_alpha = true,
		on_construct = function(pos)
			-- Initialize node inventory first
			local meta = core.get_meta(pos)
			local inv = meta:get_inventory()
			inv:set_size("main", def.capacity or 4)

			-- Initialize metadata
			if def.half_depth == true then
				meta:set_float("itemshelf:depth_displacement", -0.1475)
			end
			if def.vertical_offset then
				meta:set_float("itemshelf:vertical_displacement", def.vertical_offset)
			end
			if def.depth_offset then
				meta:set_float("itemshelf:depth_displacement", def.depth_offset)
			end
		end,
		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			local capacity = def.capacity or 4
			local name = clicker:get_player_name()
			if can_modify_inv(clicker) then
				core.show_formspec(name, "itemshelf:shelf", get_shelf_formspec(capacity, pos))
			else
				player_ctx[name] = {
					pos = pos,
					inv_size = capacity,
					amount = 1,
				}
				show_user_formspec(name)
			end
		end,
		on_dig = function(pos, node, digger)
			if can_modify_inv(digger) then
				-- Clear all object objects
				local objs = core.get_objects_inside_radius(pos, 0.7)
				for _,obj in pairs(objs) do
					obj:remove()
				end
				core.remove_node(pos)
			end
		end,
		-- Screwdriver support
		on_rotate = function(pos, node, user, mode, new_param2)
			-- Rotate
			node.param2 = new_param2
			core.swap_node(pos, node)
			update_shelf(pos)
			-- Disable rotation by screwdriver
			return false
		end,
		allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
			if can_modify_inv(player) then
				return count
			end
			return 0
		end,

		allow_metadata_inventory_put = function(pos, listname, index, stack, player)
			if can_modify_inv(player) then
				return stack:get_count()
			end
			return 0
		end,

		allow_metadata_inventory_take = function(pos, listname, index, stack, player)
			if can_modify_inv(player) then
				return stack:get_count()
			end
			return 0
		end,
		on_metadata_inventory_put = update_shelf,
		on_metadata_inventory_take = update_shelf,
		on_metadata_inventory_move = update_shelf,
		_update = update_shelf
	})
end

-- Entity for item displayed on shelf
core.register_entity("itemshelf:item", {
	hp_max = 1,
	visual = "wielditem",
	visual_size = {x = 0.20, y = 0.20},
	collisionbox = {0,0,0, 0,0,0},
	physical = false,
	on_activate = function(self, staticdata)
		-- Staticdata
		local data = {}
		if staticdata ~= nil and staticdata ~= "" then
			local cols = string.split(staticdata, "|")
			data["itemstring"] = cols[1]
			data["visualsize"] = tonumber(cols[2])
		end

		-- Texture
		if temp_texture ~= nil then
			-- Set texture from temp
			self.itemstring = temp_texture
			temp_texture = nil
		elseif staticdata ~= nil and staticdata ~= "" then
			-- Set texture from static data
			self.itemstring = data.itemstring
		end
		-- Set texture if available
		if self.itemstring ~= nil then
			self.wield_item = self.itemstring
		end

		-- Visual size
		if temp_size ~= nil then
			self.visualsize = temp_size
			temp_size = nil
		elseif staticdata ~= nil and staticdata ~= "" then
			self.visualsize = data.visualsize
		end
		-- Set visual size if available
		if self.visualsize ~= nil then
			self.visual_size = {x=self.visualsize, y=self.visualsize}
		end

		-- Set object properties
		self.object:set_properties(self)

	end,
	get_staticdata = function(self)
		local result = ""
		if self.itemstring ~= nil then
			result = self.itemstring.."|"
		end
		if self.visualsize ~= nil then
			result = result..self.visualsize
		end
		return result
	end,
})
