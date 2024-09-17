-- * Copyright (c) 2024 Nanowolf4 (n4w@tutanota.com)
-- * SPDX-License-Identifier: GPL-3.0-or-later


random_gifts = {}
local open_boxes = {}

local gravity = 7.5
local mass = 0.5
local amplitude = 1
local frequency = 3

local fs_name = "giftbox_form"

function random_gifts.entity_exists(obj)
	return obj ~= nil and obj:get_pos() ~= nil
end
local entity_exists = random_gifts.entity_exists

dofile(minetest.get_modpath("random_gifts") .. "/gifts.lua")
local list = random_gifts.list

local function choose_item_with_chance(itemList)
    local total_chance = 0
    for _, item in ipairs(itemList) do
        total_chance = total_chance + item.chance
    end

    local random_value = math.random(total_chance)
    local accumulated_chance = 0

    for i, item in ipairs(itemList) do
        accumulated_chance = accumulated_chance + item.chance
        if random_value <= accumulated_chance then
            return i
        end
    end

    -- something went wrong
    return nil
end

local function show_formspec(player)
	local player_name = player:get_player_name()
	local formspec =
		"formspec_version[7]" ..
		"size[10,5]" ..
		-- "no_prepend[]" ..
		-- "background[0,0;10,5;random_gifts_background.png]"..
		"button_exit[9.3,0;0.7,0.7;;X]" ..
		"style_type[image_button;bgcolor=black]" ..
		"style_type[item_image_button;bgcolor=black]"

	local box = open_boxes[player_name]

	local total_width = 8 --amount of elements
	local element_width = 1 --width of each element
	local spacing = 0.2 --space between elements
	local total_elements_width = total_width * element_width + (total_width - 1) * spacing

	local start_offset = (10 - total_elements_width) / 2 --X centering

	for i = 1, total_width do
		local offset = start_offset + (i - 1) * (element_width + spacing)
		local gift_index = box.gifts[i]
		if gift_index then
			local gift = list[gift_index]
			local amount = gift.amount or 1
			local field_name = "item_" .. gift_index
			if gift.oneshot then
				formspec = formspec .. "style[" .. field_name .. ";bgcolor=yellow]"
			end
			if gift.itemname then
				formspec = formspec .. string.format("item_image_button[%f,1.7;1,1;%s;%s;%s]",
				offset, gift.itemname, field_name, amount)
			elseif gift.image then
				formspec = formspec .. string.format("image_button[%f,1.7;1,1;%s;%s;%s]",
			 	offset, gift.image, field_name, amount)
			end
		else
			formspec = formspec .. "box[" .. offset .. ",1.7;1,1;gray]"
		end
	end

	minetest.show_formspec(player:get_player_name(), fs_name, formspec)
end

local function random_rgb_color()
    local r = math.random(0, 255)
    local g = math.random(0, 255)
    local b = math.random(0, 255)
	return minetest.colorspec_to_colorstring({a=0, r=r, g=g, b=b})
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= fs_name then
		return
	end

	local player_name = player:get_player_name()
	local box = open_boxes[player_name]
	if not box then
		minetest.close_formspec(player_name, fs_name)
		return
	end

	if fields.quit then
		open_boxes[player_name] = nil
		return
	end

	if not entity_exists(box.entity) then
		open_boxes[player_name] = nil
		minetest.close_formspec(player_name, fs_name)
		return
	end

	local box_pos = box.entity:get_pos()
	if vector.distance(box_pos, player:get_pos()) > 5 then
		open_boxes[player_name] = nil
		minetest.close_formspec(player_name, fs_name)
		minetest.chat_send_player(player_name, "You're too far away")
		return
	end

	for i, gift_index in ipairs(box.gifts) do
		if fields["item_" .. gift_index] then
			local gift = list[gift_index]

			local stack
			local remove_giftbox = false
			if gift.itemname then
				stack = ItemStack({
					name = gift.itemname,
					count = gift.amount or 1
				})
			elseif type(gift.func) == "function" then
				stack, remove_giftbox = gift.func(player, box.entity)
			end

			if stack then
				local inv = minetest.get_inventory({type = "player", name = player_name})
				local left_overs = inv:add_item("main", stack)
				if left_overs:get_count() > 0 then
					minetest.add_item(player:get_pos(), left_overs)
					minetest.chat_send_player(player_name, "Your gift has fallen to the ground!")
				end
			end

			table.remove(box.gifts, i)

			if not next(box.gifts) or remove_giftbox or gift.oneshot then
				box.entity:remove()
				open_boxes[player_name] = nil
				minetest.close_formspec(player_name, fs_name)

				-- particles from fireworks mod
				-- https://github.com/KaylebJay/fireworks
				minetest.add_particlespawner({
					amount = 10,
					time = 0.001,
					minpos = box_pos,
					maxpos = box_pos,
					minvel = vector.new(-1, - 1, - 1),
					maxvel = vector.new(1, 1, 1),
					minacc = {x = 0, y = -0.5, z = 0},
					maxacc = {x = 0, y = -1, z = 0},
					minexptime = 2,
					maxexptime = 2.5,
					minsize = 2,
					maxsize = 3,
					collisiondetection = true,
					vertical = false,
					glow = 5,
					texture = "random_gifts_spark.png^[multiply:" .. random_rgb_color()
				})
				return
			end
			break
		end
	end
	show_formspec(player)
end)

minetest.register_entity("random_gifts:gift", {
	initial_properties = {
		visual = "mesh",
		textures = {"radom_gifts_chest.png"},
		mesh = "random_gifts_chest.obj",
		physical = true,
		makes_footstep_sound = false,
		backface_culling = false,
		shaded = true,
		static_save = false,
		pointable = true,
		glow = 1,
		visual_size = {x = 10, y = 10, z = 10},
		collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
	},

	timer = 0,
	timeout = 200,

	on_step = function(self, dtime, movement)
		self.timer = self.timer + dtime
		if self.timer > self.timeout then
			self.object:remove()
		end

		if self.inactive then
			return
		end

		if movement.touching_ground then
			self.inactive = true
			self.object:set_velocity(vector.zero())
			if entity_exists(self.parachute) then
				self.parachute:remove()
				self.parachute = nil
				return
			end
		end

		local vel = self.object:get_velocity()
		if not vel then return end

		self.time_falling = (self.time_falling or 0) + dtime
		local sideways_speed = amplitude * math.sin(frequency * self.time_falling)
		local acceleration = {
			x = sideways_speed,
			y = -gravity * mass,
			z = sideways_speed,
		}

		self.object:set_velocity(vector.add(vector.multiply(vel, dtime), acceleration))
	end,

	on_activate = function(self, staticdata, dtime_s)
		-- self.object:set_properties({textures = "radom_gifts_chest.png"})
		local par = minetest.add_entity(self.object:get_pos(), "random_gifts:parachute")
		par:set_attach(self.object)
		self.parachute = par

		self.selected_gifts = {}
		for _ = 1, math.random(4, 8) do
			local selected = choose_item_with_chance(list)
			if selected then
				table.insert(self.selected_gifts, selected)
			end
		end
	end,

	on_deactivate = function(self, removal)
		if entity_exists(self.parachute) then
			self.parachute:remove()
		end
	end,

	on_rightclick = function(self, clicker)
		local player_name = clicker:get_player_name()
		if next(self.selected_gifts) then
			if not open_boxes[player_name] then
				open_boxes[player_name] = {
					gifts = self.selected_gifts,
					entity = self.object,
				}
			end
			show_formspec(clicker)
		else
			minetest.chat_send_player(player_name, "Oops, that gift is empty, you'll have better luck next time!")
			self.object:remove()
			return
		end
		self.object:set_properties({mesh = "random_gifts_chest_opened.obj"})
	end,

	-- on_punch = function(self, puncher)
    --     if puncher and puncher:is_player() then
    --         local punch_direction = vector.direction(puncher:get_pos(), self.object:get_pos())
    --         local repel_force = 5

    --         self.object:add_velocity(vector.multiply(vector.offset(punch_direction, 0, 0.5, 0), repel_force))
    --     end
    --     return true
    -- end,
})

minetest.register_entity("random_gifts:parachute", {
	initial_properties = {
		visual = "mesh",
		textures = {"random_gifts_parachute.png"},
		mesh = "random_gifts_parachute.obj",
		physical = false,
		makes_footstep_sound = false,
		backface_culling = false,
		shaded = true,
		static_save = false,
		pointable = false,
		glow = 1,
		visual_size = {x = 1, y = 1, z = 1},
	},
	on_punch = function() return true end,
	on_activate = function(self, staticdata, dtime_s)
		self.object:set_properties({textures = {"random_gifts_parachute.png^[multiply:" .. random_rgb_color()}})
	end,
})

minetest.register_chatcommand("spawn_giftbox",{
	privs = {dev = true},
	func = function(name)
		local player = minetest.get_player_by_name(name)
		minetest.add_entity(vector.offset(player:get_pos(), 0, 1, 0), "random_gifts:gift")
	end
})

dofile(minetest.get_modpath("random_gifts") .. "/spawner.lua")