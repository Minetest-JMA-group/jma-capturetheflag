minetest.register_node("nintendo:wii", {
	description = "Wii",
	tiles = {
		"wii-side.png",
		"wii-side.png",
		"wii-side.png",
		"wii-side.png",
		"wii-side.png",
		"wii-front.png"
	},
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.1875, -0.5, -0.5, 0.125, 0.375, 0.5}, -- NodeBox1
		}
	},
	groups = {crumbly = 3},
	on_punch = function(pos, node, puncher)
		if puncher:get_wielded_item():get_name() == "nintendo:wii_disc" then
			tnt.boom(pos, {radius=3, damage_radius=3, puncher_name=puncher:get_player_name()})
		elseif puncher:get_wielded_item():get_name() == "nintendo:gamecube_disc" then
			tnt.boom(pos, {radius=6, damage_radius=6, puncher_name=puncher:get_player_name()})
		end
	end,
})

minetest.register_craftitem("nintendo:wii_disc", {
	description = "Wii disc",
	inventory_image = "wii-disc.png"
})

minetest.register_craftitem("nintendo:gamecube_disc", {
	description = "GameCube disc\nCompatible with the Nintendo Wii",
	inventory_image = "gamecube-disc.png"
})