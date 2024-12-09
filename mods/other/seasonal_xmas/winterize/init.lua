if os.date("%m") ~= "12" then return end

winterize = {}

local snowy_dirt_tiles = minetest.registered_nodes["default:dirt_with_snow"].tiles
local snowy_dirt_sounds = minetest.registered_nodes["default:dirt_with_snow"].sounds
local grasses = {"dry_grass", "grass", "coniferous_litter",}
local leaves = {"leaves", "aspen_leaves", "jungleleaves", "bush_leaves",}

minetest.register_node("winterize:ice", { -- breaks instantly, drops nothing
	drawtype = "signlike",
	description = "Ice",
	tiles = {"winterize_ice_seethrough.png"},
	buildable_to = true,
	floodable = true,
	paramtype = "light",
	sunlight_propagates = true,
	use_texture_alpha = "clip",
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, -0.4, 0.5},
		},
	},
	collision_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, -0.4, 0.5},
		},
	},
	drop = "",
	groups = {dig_immediate = 3, slippery = 4, fall_damage_add_percent = -40, grenade_breakable=1},
	sounds = default.node_sound_glass_defaults(),
})

minetest.register_node("winterize:present", {
	description = "Present",
	tiles = {
		"winterize_present_top.png",  "winterize_present_bottom.png", "winterize_present_side.png",
		"winterize_present_side.png", "winterize_present_side.png",   "winterize_present_front.png"
	},
	paramtype = "light",
	light_source = 6,
	groups = {dig_immediate = 2},
	drop = {
		items = {
			{
				items = {"throwable_snow:snowball 10"},
			},
		},
	},
	sounds = default.node_sound_wood_defaults(),
})

function winterize.get_present_count()
	return 0
end

-- Add snow and ice to map
ctf_api.register_on_new_match(function()
	local vm = VoxelManip(ctf_map.current_map.pos1, ctf_map.current_map.pos2)
	local o_pos1, o_pos2 = vm:get_emerged_area()

	minetest.log("action", "Starting to winterize...")
	minetest.handle_async(function(data, pos1, pos2, present_count)
		local outdata = {}
		local present_positions = {}

		local math_random = math.random
		local math_min = math.min

		local ID_AIR = minetest.CONTENT_AIR
		local ID_IGNORE = minetest.get_content_id("ctf_map:ignore")
		local ID_GLASS = minetest.get_content_id("ctf_map:ind_glass")
		local ID_WATER = minetest.get_content_id("default:water_source")

		local snow_place_blacklist = {
			"ctf_map:", "default:snow", "doors:", "ctf_teams:", "default:fence",
			"stairs:", "walls:", "default:mese_post", "xpanes:",
		}
		local SNOW_ID = minetest.get_content_id("default:snow")
		local ICE_ID = minetest.get_content_id("winterize:ice")
		local PRESENT_ID = minetest.get_content_id("winterize:present")

		local Nx = pos2.x - pos1.x + 1
		local Ny = pos2.y - pos1.y + 1
		local count = 0

		for y = pos1.y+1, pos2.y-1 do -- Make sure above/below checks don't go out of bounds
			for z = pos1.z, pos2.z do
				for x = pos1.x, pos2.x do
					local pre = (((z - pos1.z) * Ny) * Nx)
					local mid = (y - pos1.y) * Nx
					local post = (x - pos1.x) + 1

					local vi = pre + mid + post

					local vi_below = pre + (mid - Nx) + post

					if data[vi_below] ~= ID_AIR and data[vi] == ID_AIR then
						if y <= pos2.y - 10 and data[vi_below] == ID_WATER then -- will ignore water near the ceiling
							outdata[vi] = {i = ICE_ID, b = vi_below}
							count = count + 1
						elseif data[pre + (mid + Nx) + post] == ID_AIR then -- id_above == AIR
							local name = minetest.get_name_from_content_id(data[vi_below])
							local hit = false

							if minetest.registered_nodes[name].walkable == false then
								hit = true
							else
								for _, pattern in pairs(snow_place_blacklist) do
									if name:find(pattern) then
										hit = true
										break
									end
								end
							end

							if not hit then
								for i = 1, math_min((pos2.y - y) - 4, 80) do
									local id = data[pre + (mid + (i * Nx)) + post]

									if id ~= ID_AIR then
										-- Only count a hit if we aren't near the top of the map
										local ignore_check = data[pre + (mid + ((i+4) * Nx)) + post]

										if ignore_check ~= ID_AIR and ignore_check ~= ID_IGNORE and ignore_check ~= ID_GLASS then
											hit = true
										end

										break
									end
								end

								if not hit then
									if math_random(5) <= 4 then -- roughly 4/5 map coverage
										outdata[vi] = {i = SNOW_ID, b = vi_below}
										count = count + 1
									elseif present_count > 0 then
										table.insert(present_positions, {vi = vi, i = PRESENT_ID, b = vi_below})
									end
								end
							end
						end
					end
				end
			end
		end

		if present_count > 0 and #present_positions > 0 then
			table.shuffle(present_positions)

			for i=1, math_min(present_count, #present_positions) do
				local vi = present_positions[i].vi
				present_positions[i].vi = nil
				outdata[vi] = present_positions[i]
			end
		end

		return outdata, count
	end,
	function(outdata, change_count)
		if change_count <= 1000 then
			snow.SPAWN_SNOW = false
			minetest.log("action", "Done winterizing, skipped changes: "..change_count)
			return
		else
			snow.SPAWN_SNOW = true
			minetest.log("action", "Done winterizing. Changes: "..change_count)
		end

		local newvm = VoxelManip(o_pos1, o_pos2)
		local data = newvm:get_data()

		local ID_AIR = minetest.CONTENT_AIR
		local ID_IGNORE = minetest.CONTENT_IGNORE
		for i in pairs(data) do
			if outdata[i] then
				if data[i] == ID_AIR and data[outdata[i].b] ~= ID_AIR then
					data[i] = outdata[i].i
				end
			else
				data[i] = ID_IGNORE
			end
		end

		newvm:set_data(data)
		newvm:write_to_map(false)
	end, vm:get_data(), o_pos1, o_pos2, winterize.get_present_count())
end)

local function get_drop(original, rarity)
	return {
		items = {
			{
				items = {original},
			},
			{
				rarity = rarity,
				items = {"throwable_snow:snowball"},
			},
		}
	}
end

for _, leaftype in pairs(leaves) do
	minetest.override_item("default:" .. leaftype, {
		tiles = {"winterize_dead_leaves.png"},
		special_tiles = {"winterize_dead_leaves.png"},
	})

	minetest.override_item("ctf_map:" .. leaftype, {
		tiles = {"winterize_dead_leaves.png"},
		special_tiles = {"winterize_dead_leaves.png"},
	})
end

for _, grasstype in pairs(grasses) do
	minetest.override_item("default:dirt_with_" .. grasstype, {
		tiles = snowy_dirt_tiles,
		sounds = snowy_dirt_sounds,
		drop = get_drop("default:dirt", 3),
	})

	if minetest.registered_nodes["ctf_map:dirt_with_" .. grasstype] then
		minetest.override_item("ctf_map:dirt_with_" .. grasstype, {
			tiles = snowy_dirt_tiles,
			sounds = snowy_dirt_sounds,
		})
	end
end

-- Remove flower and grass nodes
for name, def in pairs(minetest.registered_nodes) do
	if name:find("default:grass") or name:find("flowers:") then
		minetest.register_alias_force(name, "air")
	end
end

minetest.override_item("default:snowblock", {
	drop = get_drop("default:snowblock", 2)
})
