minetest.register_node("ctf_changes:lava_source", {
	description = "Lava Source",
	drawtype = "liquid",
	tiles = {
		{
			name = "default_lava_source_animated.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 3.0,
			},
		},
		{
			name = "default_lava_source_animated.png",
			backface_culling = true,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 3.0,
			},
		},
	},
	paramtype = "light",
	light_source = default.LIGHT_MAX - 1,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	drop = "",
	drowning = 1,
	liquidtype = "source",
	liquid_alternative_flowing = "ctf_changes:lava_flowing",
	liquid_alternative_source = "ctf_changes:lava_source",
	liquid_viscosity = 7,
	liquid_renewable = false,
	damage_per_second = 4 * 2,
	post_effect_color = {a = 191, r = 255, g = 64, b = 0},
	groups = {lava = 3, liquid = 2, igniter = 1},
})

minetest.register_node("ctf_changes:lava_flowing", {
	description = "Flowing Lava",
	drawtype = "flowingliquid",
	tiles = {"default_lava.png"},
	special_tiles = {
		{
			name = "default_lava_flowing_animated.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 3.3,
			},
		},
		{
			name = "default_lava_flowing_animated.png",
			backface_culling = true,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 3.3,
			},
		},
	},
	paramtype = "light",
	paramtype2 = "flowingliquid",
	light_source = default.LIGHT_MAX - 1,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	drop = "",
	drowning = 1,
	liquidtype = "flowing",
	liquid_alternative_flowing = "ctf_changes:lava_flowing",
	liquid_alternative_source = "ctf_changes:lava_source",
	liquid_viscosity = 7,
	liquid_renewable = false,
	damage_per_second = 4 * 2,
	post_effect_color = {a = 191, r = 255, g = 64, b = 0},
	groups = {lava = 3, liquid = 2, igniter = 1,
		not_in_creative_inventory = 1},
})

-- minetest.register_alias("lava_flowing", "ctf_changes:lava_flowing")
-- minetest.register_alias("lava_source", "ctf_changes:lava_source")

-- Cleanup lava in protected areas
minetest.register_abm({
	nodenames = {"ctf_changes:lava_flowing"},
	neighbors = {"air"},
	interval = 5,
	chance = 1,
	action = function(pos)
		if minetest.is_protected(pos, "") then
			local nodes_checked = 0
			local source_removed = false
			local can_go = function(on_pos)
				if not source_removed and nodes_checked < 200 then
					local nn = minetest.get_node(on_pos).name
					if nn == "ctf_changes:lava_flowing" then
						minetest.set_node(on_pos, {name = "air"})
						nodes_checked = nodes_checked + 1
						return true
					elseif nn == "ctf_changes:lava_source" then
						minetest.set_node(on_pos, {name = "air"})
						source_removed = true
					end
				end
				return false
			end
			fallings_search.search_3d(can_go, pos, "touch")
		end
	end
})

minetest.register_abm({
	label = "Lava cooling",
	nodenames = {"ctf_changes:lava_source", "ctf_changes:lava_flowing"},
	neighbors = {"group:cools_lava", "group:water"},
	interval = 4,
	chance = 2,
	catch_up = false,
	action = function(...)
		default.cool_lava(...)
	end,
})

bucket.register_liquid(
	"ctf_changes:lava_source",
	"ctf_changes:lava_flowing",
	"ctf_changes:bucket_lava",
	"bucket_lava.png^[colorize:red:30",
	"Lava Bucket",
	{tool = 1}
)

minetest.register_craft({
	type = "fuel",
	recipe = "ctf_changes:bucket_lava",
	burntime = 60,
	replacements = {{"ctf_changes:bucket_lava", "bucket:bucket_empty"}},
})