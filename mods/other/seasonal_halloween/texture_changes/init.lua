if (os.date("%m") ~= "10" or tonumber(os.date("%d")) < 17) and os.date("%m") ~= "11" then return end

local function get_color(texture)
	-- Change trees to a dark grey/brown
	if texture:find("tree") and not (texture:find("aspen") or texture:find("leaves")) then
		return "^[colorize:#171716:111"
	-- Make sands a bit darker too
	elseif texture:find("sand") then
		return "^[colorize:#4c4238:90"
	elseif os.date("%m") == "10" then -- Color a little orange
		return "^[colorize:#9b6300:40"
	else
		return ""
	end
end

minetest.register_on_mods_loaded(function()
	for name, def in pairs(minetest.registered_nodes) do
		if def.tiles then
			for key, texture in ipairs(def.tiles) do
				if type(texture) == "string" then
					def.tiles[key] = "(" .. texture .. ")" .. get_color(texture)
				elseif type(texture) == "table" then
					if texture.image then
						def.tiles[key].image = "(" .. texture.image..")" .. get_color(texture.image)
					elseif texture.name then
						def.tiles[key].name = "(" .. texture.name..")" .. get_color(texture.name)
					end
				end
			end

			minetest.override_item(name, {tiles = def.tiles})
		elseif def.special_tiles then
			for key, texture in ipairs(def.special_tiles) do
				if type(texture) == "string" then
					def.special_tiles[key] = "(" .. texture .. ")" .. get_color(texture)
				elseif type(texture) == "table" then
					if texture.image then
						def.special_tiles[key].image = "(" .. texture.image..")" .. get_color(texture.image)
					elseif texture.name then
						def.special_tiles[key].name = "(" .. texture.name..")" .. get_color(texture.name)
					end
				end
			end

			minetest.override_item(name, {special_tiles = def.special_tiles})
		end
	end

	if os.date("%m") == "10" then
		local tools = {"sword", "pick", "axe", "shovel"}
		for name, def in pairs(minetest.registered_tools) do
			for _, tool in ipairs(tools) do
				if name:find(tool) then
					local wield_image

					if tool == "shovel" then
						wield_image = def.wield_image.."^(overlay_shovel.png^[transformR90)"
					end

					minetest.override_item(name, {
						inventory_image = ("%s^overlay_%s.png"):format(def.inventory_image, tool),
						wield_image = wield_image,
					})

					break
				end
			end
		end

		local water_source_tiles = minetest.registered_nodes["default:water_source"].tiles
		local water_flowing_tiles = minetest.registered_nodes["default:water_flowing"].special_tiles

		for _, v in pairs(water_source_tiles) do
			v.name = "texture_changes_water_source_animated.png"
		end

		for _, v in pairs(water_flowing_tiles) do
			v.name = "texture_changes_water_flowing_animated.png"
		end

		minetest.override_item("default:water_source", {
			tiles = water_source_tiles,
			post_effect_color = {a = 150, r = 67, g = 13, b = 13},
		})
		minetest.override_item("default:water_flowing", {
			tiles = {"texture_changes_water.png"},
			special_tiles = water_flowing_tiles,
			post_effect_color = {a = 150, r = 67, g = 13, b = 13},
		})

		minetest.override_item("default:ice", {tiles = {"texture_changes_ice.png"}})
		minetest.override_item("default:cave_ice", {tiles = {"texture_changes_ice.png"}})
	end

	local textures = {
		-- texture = halloween_only
		["_snow_side.png"] = true,
		["_snow.png"] = true,
		["_snowball.png"] = true,
		["_dirt.png"] = true,
		["_cobble.png"] = true,
		["_sand.png"] = true,
		["_stone_block.png"] = true,
		["_stone_brick.png"] = true,
		["_stone.png"] = true,
		["_desert_sand.png"] = true,
		["_acacia_leaves_simple.png"] = false,
		["_acacia_leaves.png"] = false,
		["_aspen_leaves_simple.png"] = false,
		["_aspen_leaves.png"] = false,
		["_blueberry_bush_leaves.png"] = false,
		["_grass_1.png"] = false,
		["_grass_2.png"] = false,
		["_grass_3.png"] = false,
		["_grass_4.png"] = false,
		["_grass_5.png"] = false,
		["_grass_side.png"] = false,
		["_grass.png"] = false,
		["_jungleleaves_simple.png"] = false,
		["_jungleleaves.png"] = false,
		["_leaves_simple.png"] = false,
		["_leaves.png"] = false,
		["_pine_needles_simple.png"] = false,
		["_pine_needles.png"] = false,
	}

	local halloween = os.date("%m") == "10"
	local function replace_textures(x)
		for texture, halloween_only in pairs(textures) do
			if not halloween_only or (halloween_only and halloween) then
				x = x:gsub("default"..texture, "texture_changes"..texture)
			end
		end

		return x
	end

	for name, def in pairs(minetest.registered_items) do
		local update = false

		if def.tiles then
			for k, v in pairs(def.tiles) do
				if type(v) == "string" then
					def.tiles[k] = replace_textures(v)
					update = true
				elseif type(v) == "table" and v.name then
					def.tiles[k].name = replace_textures(v.name)
					update = true
				end
			end
		end

		if def.inventory_image then
			def.inventory_image = replace_textures(def.inventory_image)
			update = true
		end

		if def.wield_image then
			def.wield_image = replace_textures(def.wield_image)
			update = true
		end

		if update then
			minetest.override_item(name, {
				tiles = def.tiles,
				inventory_image = def.inventory_image,
				wield_image = def.wield_image
			})
		end
	end
end)
