core.register_node("ctf_mode_chaos:concrete", {
	description = "Concrete\nExcellent blast resistance and protection",
	tiles = { "ctf_mode_chaos_concrete.png" },
	is_ground_content = false,
	groups = { cracky = 1, stone = 2, blast_protection = 1 },
	on_blast = function() end,
	sounds = default.node_sound_stone_defaults(),
})
