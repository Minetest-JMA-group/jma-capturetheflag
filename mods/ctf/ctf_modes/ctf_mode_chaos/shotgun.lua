ctf_ranged.simple_register_gun("ctf_mode_chaos:shotgun", {
	type = "shotgun",
	description = "Chaotic Shotgun",
	texture = "ctf_mode_chaos_shotgun.png",
	fire_sound = "ctf_mode_chaos_shotgun",
	bullet = {
		amount = 15,
		spread = 2,
	},
	automatic = true,
	rounds = 7,
	range = 20,
	on_use = ctf_ranged.on_hit_damage(1),
	fire_interval = 0.2,
})
