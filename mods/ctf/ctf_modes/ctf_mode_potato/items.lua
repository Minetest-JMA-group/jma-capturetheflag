core.register_craftitem("ctf_mode_potato:potato", {
    description = core.colorize("#c69828", "Potato"),
    groups = { potato = 1 },
    inventory_image = "ctf_mode_potato_potato.png",

	on_use = core.item_eat(1),
})

core.register_craftitem("ctf_mode_potato:potato_grenade", {
    description = core.colorize("#c69828", "Potato Grenade").."\nAmmo for a Potato Launcher",
    groups = { potato = 1 },
    inventory_image = "ctf_mode_potato_potato_grenade.png",
})

core.register_node("ctf_mode_potato:potato_block", {
    description = core.colorize("#c69828", "Potato Block"),

    paramtype2 = "facedir",

    tiles = {"ctf_mode_potato_ground.png"},

    groups = { potato = 5, oddly_breakable_by_hand = 2 },

    drop = {
        max_items = 1,
        items = {
            {
                tool_groups = {
                    {"pickaxe"}
                },
                items = {"ctf_mode_potato:potato_block"},
            },
            {
                items = {"ctf_mode_potato:potato"},
            },
        },
    },
})

core.register_node("ctf_mode_potato:potatone", {
    description = core.colorize("#c69828", "Potatone"),

    paramtype2 = "facedir",

    tiles = {"default_stone.png"},
    color = "#dfb135",

    groups = {
        cracky = 3,
        real_suffocation = 1,
        stone = 1,
        potato = 2
    },

    sounds = default.node_sound_stone_defaults(),
})

core.register_node("ctf_mode_potato:fries", {
	description = core.colorize("#c69828", "Fries"),
	drawtype = "plantlike",
	tiles = {"ctf_mode_potato_fries.png"},
	inventory_image = "ctf_mode_potato_fries.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	is_ground_content = false,
	selection_box = {
		type = "fixed",
		fixed = {-3 / 16, -7 / 16, -3 / 16, 3 / 16, 4 / 16, 3 / 16}
	},
	groups = {oddly_breakable_by_hand = 3, potato = 2},
	on_use = core.item_eat(2),
	sounds = default.node_sound_leaves_defaults(),
})
