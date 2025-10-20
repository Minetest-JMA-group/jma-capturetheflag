if os.date("%m") ~= "10" or tonumber(os.date("%d")) < 15 or not minetest.get_modpath("server_cosmetics") then return end

local META_KEY = "server_cosmetics:lanterns:"..os.date("%Y")
local COSMETIC_KEY = "server_cosmetics:entity:hallows_hat:"..os.date("%Y")
local REQUIRED_LANTERNS = 66

local dig_func = function(score, item) return function(pos, _, digger)
	minetest.remove_node(pos)
	if not digger or not digger:is_player() then
		minetest.add_item(pos, item)
		return
	end

	local meta = digger:get_meta()
	local old_val = meta:get_int(META_KEY)
	local new_val = old_val + score

	if old_val < REQUIRED_LANTERNS then
		meta:set_int(META_KEY, new_val)
		sfinv.set_page(digger, sfinv.get_page(digger))

		if new_val >= REQUIRED_LANTERNS then
			hud_events.new(digger:get_player_name(), {
				text = "You have unlocked this year's hallows hat! Put it on in the Customize tab!",
				color = "success",
			})

			meta:set_int(COSMETIC_KEY, 1)
		else
			hud_events.new(digger:get_player_name(), {
				text = string.format("[Event] %d/%d lantern points", new_val, REQUIRED_LANTERNS),
				color = "info",
				quick = true,
			})

			spooky_effects.spawn_angry_ghost(pos, digger)
		end
	else
		hud_events.new(digger:get_player_name(), {
			text = "You have already unlocked the hat!",
			color = "success",
			quick = true,
		})

		minetest.add_item(pos, item)
	end
end end

-- jack 'o lantern
minetest.register_node("hallows_hat_event:jackolantern", {
	description = "Jack 'O Lantern\nGives 1 lantern point when dug",
	tiles = {
		"hallows_hat_event_pumpkin_top.png", "hallows_hat_event_pumpkin_top.png",
		"hallows_hat_event_pumpkin_side.png", "hallows_hat_event_pumpkin_side.png",
		"hallows_hat_event_pumpkin_side.png", "hallows_hat_event_pumpkin_face_off.png"
	},
	paramtype2 = "facedir",
	light_source = 2,
	groups = {snappy = 2, choppy = 2, oddly_breakable_by_hand = 2, flammable = 2},
	sounds = default.node_sound_wood_defaults(),
	drop = "",
	on_dig = dig_func(1, "hallows_hat_event:jackolantern"),
})

minetest.register_node("hallows_hat_event:jackolantern_on", {
	description = "Jack 'O Lantern\nGives 5 lantern points when dug",
	tiles = {
		"hallows_hat_event_pumpkin_top.png", "hallows_hat_event_pumpkin_top.png",
		"hallows_hat_event_pumpkin_side.png", "hallows_hat_event_pumpkin_side.png",
		"hallows_hat_event_pumpkin_side.png", "hallows_hat_event_pumpkin_face_on.png"
	},
	light_source = default.LIGHT_MAX - 1,
	paramtype2 = "facedir",
	groups = {
		snappy = 2, choppy = 2, oddly_breakable_by_hand = 2, flammable = 2,
		not_in_creative_inventory = 1
	},
	sounds = default.node_sound_wood_defaults(),
	drop = "",
	on_dig = dig_func(5, "hallows_hat_event:jackolantern_on"),
})

-- Add jack 'o lanterns around the map on load

local ID_AIR = minetest.CONTENT_AIR
local ID_IGNORE = minetest.CONTENT_IGNORE
local ID_WATER = minetest.get_content_id("default:water_source")
ctf_api.register_on_new_match(function()
	local spawn_amount = math.floor(math.max(
		8,
		math.min(
			REQUIRED_LANTERNS + (ctf_map.current_map.dirname == "pumpkin_hills" and 10 or 0),
			3 * #minetest.get_connected_players() * (ctf_map.current_map.dirname == "pumpkin_hills" and 1.6 or 1)
		)
	))

	minetest.after(5, function()
		local vm = VoxelManip()
		local pos1, pos2 = vm:read_from_map(ctf_map.current_map.pos1, ctf_map.current_map.pos2)
		local data = vm:get_data()
		local param2_data = vm:get_param2_data()

		local Nx = pos2.x - pos1.x + 1
		local Ny = pos2.y - pos1.y + 1

		local Sx = math.min(pos1.x, pos2.x)
		local Mx = math.max(pos1.x, pos2.x) - Sx + 1

		local Sy = math.min(pos1.y, pos2.y)
		local My = math.max(pos1.y, pos2.y) - Sy + 1

		local Sz = math.min(pos1.z, pos2.z)
		local Mz = math.max(pos1.z, pos2.z) - Sz + 1

		local place_positions = {}
		local random_state = {}
		local random_count = Mx * My * Mz

		local math_random = math.random
		local math_floor = math.floor
		local table_insert = table.insert

		while random_count > 0 do
			local pos = math_random(1, random_count)
			pos = random_state[pos] or pos

			local x = pos % Mx + Sx
			local y = math_floor(pos / Mx) % My + Sy
			local z = math_floor(pos / My / Mx) + Sz

			local vi = (z - pos1.z) * Ny * Nx + (y - pos1.y) * Nx + (x - pos1.x) + 1
			local id_below = data[(z - pos1.z) * Ny * Nx + (y - 1 - pos1.y) * Nx + (x - pos1.x) + 1]
			local id_above = data[(z - pos1.z) * Ny * Nx + (y + 1 - pos1.y) * Nx + (x - pos1.x) + 1]

			if data[vi] == ID_AIR and id_below ~= ID_AIR and id_below ~= ID_IGNORE and
			id_below ~= ID_WATER and id_above == ID_AIR then
				table_insert(place_positions, {vi=vi, x=x, y=y, z=z})
				if #place_positions >= spawn_amount then
					break
				end
			end

			random_state[pos] = random_state[random_count] or random_count
			random_state[random_count] = nil
			random_count = random_count - 1
		end

		local REG_ID = minetest.get_content_id("hallows_hat_event:jackolantern")
		local ON_ID = minetest.get_content_id("hallows_hat_event:jackolantern_on")

		for _, pos in ipairs(place_positions) do
			if math_random(1, 10) ~= 2 then
				data[pos.vi] = REG_ID
			else
				data[pos.vi] = ON_ID
			end

			param2_data[pos.vi] = math_random(0, 3)
		end

		if #place_positions < spawn_amount then
			minetest.log("error",
				string.format("[MAP] Couldn't place %d from %d chests", spawn_amount - #place_positions, spawn_amount)
			)
		end

		vm:set_data(data)
		vm:set_param2_data(param2_data)
		vm:write_to_map(false)
	end)
end)

sfinv.register_page("hallows_hat_event:progress", {
	title = minetest.colorize("orange", "Event!"),
	is_in_nav = function(self, player)
		local meta = player:get_meta()

		return not meta:get_int(COSMETIC_KEY) or meta:get_int(COSMETIC_KEY) ~= 1
	end,
	get = function(self, player, context)
		local meta = player:get_meta()
		local score = meta:get_int(META_KEY)

		local form = "real_coordinates[true]"

		if score < REQUIRED_LANTERNS then
			form = string.format("%slabel[0.1,0.5;Find and dig jack 'o lanterns to get a cool halloween hat!\n%s%d%s\n%s]", form,
				"- Unlit lanterns give 1 point, lit lanterns give 5.\nYou must get ",
				REQUIRED_LANTERNS,
				" lantern points.",
				"- The lanterns spawn at the beginning of matches."
			)
		else
			form = form .. "label[0.1,0.5;Nice job! Pop over to the customization tab to try out your new hat!]"

			if not meta:get_int(COSMETIC_KEY) or meta:get_int(COSMETIC_KEY) ~= 1 then
				meta:set_int(COSMETIC_KEY, 1)
			end
		end

		form = form .. string.format([[
			label[0.1,2.7;You've collected %d/%d lantern points]
			image[0.1,3;8,1;hallows_hat_event_progress_bar.png]] ..
			[[^(([combine:38x8:1,0=hallows_hat_event_progress_bar_full.png)^[resize:%dx8)]"
		]],
		score, REQUIRED_LANTERNS,
		math.min((38/REQUIRED_LANTERNS)*score, 38) + 1
		)

		return sfinv.make_formspec(player, context, form, true)
	end,
	on_player_receive_fields = function(self, player, context, fields)
		sfinv.set_page(player, sfinv.get_page(player))
	end,
})
