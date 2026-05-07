core.register_craftitem("ctf_healing:ammo", {
	description = "Healing Ammo\nUsed to reload healing guns",
	inventory_image = "ctf_healing_healing_ammo.png",
})

ctf_ranged.simple_register_gun("ctf_healing:healing_pistol", {
	type = "pistol",
	description = "Healing Pistol\nHeals teammates on hit",
	texture = "ctf_healing_healing_pistol.png",
	fire_sound = "ctf_ranged_pistol",
	rounds = 75,
	range = 75,
	fire_interval = 0.6,
	liquid_travel_dist = 2,
	on_use = ctf_ranged.on_hp_change_gun_use(2),
	ammo = "ctf_healing:ammo",
})
