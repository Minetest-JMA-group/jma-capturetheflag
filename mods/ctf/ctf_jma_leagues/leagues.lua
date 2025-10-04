return {
	["grass"] = {
		display_name = "Grass League",
		icon_texture = "ctf_jma_leagues_grass.png",
		order = 1,
		color = "#71aa34",
		requirements = {
			{task_type = "kills", params = {goal = 25, mode_name = "total"}, description = "Reach 25 kills"},
			{task_type = "score", params = {goal = 200, mode_name = "total"}, description = "Reach 200 score"},
			{task_type = "playtime", params = {goal = 20}, description = "Play for 20 minutes"},
			{task_type = "kd", params = {goal = 0.25, mode_name = "total"}, description = "Maintain a K/D ratio of at least 0.25"},
		}
	},
	["wood"] = {
		display_name = "Wood League",
		icon_texture = "ctf_jma_leagues_wood.png",
		order = 2,
		color = "#a05b53",
		requirements = {
			{task_type = "kills", params = {goal = 60, mode_name = "total"}, description = "Reach 60 kills"},
			{task_type = "playtime", params = {goal = 60}, description = "Play for 1 hour"},
			{task_type = "kill_assists", params = {goal = 45, mode_name = "total"}, description = "Reach 45 kill assists"},
			{task_type = "hp_healed", params = {goal = 20, mode_name = "total"}, description = "Heal 20 HP"},
			{task_type = "flag_captures", params = {goal = 3, mode_name = "total"}, description = "Capture 3 flags"},
			{task_type = "score", params = {goal = 600, mode_name = "total"}, description = "Reach 600 score"},
			{task_type = "kd", params = {goal = 0.75, mode_name = "total"}, description = "Maintain a K/D ratio of at least 0.75"},
		}
	},
	["stone"] = {
		display_name = "Stone League",
		icon_texture = "ctf_jma_leagues_stone.png",
		order = 3,
		color = "#a0938e",
		requirements = {
			{task_type = "kills", params = {goal = 100, mode_name = "total"}, description = "Reach 100 kills"},
			{task_type = "kill_assists", params = {goal = 95, mode_name = "total"}, description = "Reach 95 kill assists"},
			{task_type = "hp_healed", params = {goal = 60, mode_name = "total"}, description = "Heal 60 HP"},
			{task_type = "flag_captures", params = {goal = 8, mode_name = "total"}, description = "Capture 8 flags"},
			{task_type = "playtime", params = {goal = 250}, description = "Play for 4 hours and 10 minutes"},
			{task_type = "score", params = {goal = 1650, mode_name = "total"}, description = "Reach 1650 score"},
			{task_type = "kd", params = {goal = 0.94, mode_name = "total"}, description = "Maintain a K/D ratio of at least 0.94"},

		}
	},
	["obsidian"] = {
		display_name = "Obsidian League",
		icon_texture = "ctf_jma_leagues_obsidian.png",
		order = 4,
		color = "#564064",
		requirements = {
			{task_type = "kills", params = {goal = 400, mode_name = "total"}, description = "Reach 400 kills"},
			{task_type = "kill_assists", params = {goal = 180, mode_name = "total"}, description = "Reach 180 kill assists"},
			{task_type = "hp_healed", params = {goal = 150, mode_name = "total"}, description = "Heal 150 HP"},
			{task_type = "flag_captures", params = {goal = 20, mode_name = "total"}, description = "Capture 20 flags"},
			{task_type = "playtime", params = {goal = 280}, description = "Play for 4 hours and 40 minutes"},
			{task_type = "score", params = {goal = 3300, mode_name = "total"}, description = "Reach 3300 score"},
			{task_type = "kd", params = {goal = 1.12, mode_name = "total"}, description = "Maintain a K/D ratio of at least 1.12"},
			{task_type = "top_pos", params = {goal = 1000, range = 1200, mode_name = "classes"}, description = "Reach Top 1000 (in Classes)"},
		}
	},
	["steel"] = {
		display_name = "Steel League",
		icon_texture = "ctf_jma_leagues_steel.png",
		order = 5,
		color = "#cfc6b8",
		requirements = {
			{task_type = "kills", params = {goal = 700, mode_name = "total"}, description = "Reach 700 kills"},
			{task_type = "kill_assists", params = {goal = 300, mode_name = "total"}, description = "Reach 300 kill assists"},
			{task_type = "hp_healed", params = {goal = 200, mode_name = "total"}, description = "Heal 200 HP"},
			{task_type = "flag_captures", params = {goal = 30, mode_name = "total"}, description = "Capture 30 flags"},
			{task_type = "playtime", params = {goal = 370}, description = "Play for 6 hours and 10 minutes"},
			{task_type = "score", params = {goal = 5500, mode_name = "total"}, description = "Reach 5500 score"},
			{task_type = "kd", params = {goal = 1.19, mode_name = "total"}, description = "Maintain a K/D ratio of at least 1.19"},
			{task_type = "top_pos", params = {goal = 700, range = 800, mode_name = "classes"}, description = "Reach Top 700 (in Classes)"},
		}
	},
	["bronze"] = {
		display_name = "Bronze League",
		icon_texture = "ctf_jma_leagues_bronze.png",
		order = 6,
		color = "#bf7958",
		requirements = {
			{task_type = "kills", params = {goal = 900, mode_name = "total"}, description = "Reach 900 kills"},
			{task_type = "kill_assists", params = {goal = 360, mode_name = "total"}, description = "Reach 360 kill assists"},
			{task_type = "hp_healed", params = {goal = 250, mode_name = "total"}, description = "Heal 250 HP"},
			{task_type = "flag_captures", params = {goal = 45, mode_name = "total"}, description = "Capture 45 flags"},
			{task_type = "playtime", params = {goal = 540}, description = "Play for 9 hours"},
			{task_type = "score", params = {goal = 7700, mode_name = "total"}, description = "Reach 7700 score"},
			{task_type = "kd", params = {goal = 1.27, mode_name = "total"}, description = "Maintain a K/D ratio of at least 1.27"},
			{task_type = "top_pos", params = {goal = 500, range = 600, mode_name = "nade_fight"}, description = "Reach Top 500 (in Nades)"},
		}
	},
	["gold"] = {
		display_name = "Gold League",
		icon_texture = "ctf_jma_leagues_gold.png",
		order = 7,
		color = "#f4b41b",
		requirements = {
			{task_type = "kills", params = {goal = 1000, mode_name = "total"}, description = "Reach 1000 kills"},
			{task_type = "kill_assists", params = {goal = 600, mode_name = "total"}, description = "Reach 600 kill assists"},
			{task_type = "hp_healed", params = {goal = 380, mode_name = "total"}, description = "Heal 380 HP"},
			{task_type = "flag_captures", params = {goal = 70, mode_name = "total"}, description = "Capture 70 flags"},
			{task_type = "playtime", params = {goal = 720}, description = "Play for 12 hours"},
			{task_type = "score", params = {goal = 10000, mode_name = "total"}, description = "Reach 10000 score"},
			{task_type = "top_pos", params = {goal = 1000, range = 1200, mode_name = "classes"}, description = "Reach Top 1000 (in Classes)"},
			{task_type = "kd", params = {goal = 1.55, mode_name = "total"}, description = "Maintain a K/D ratio of at least 1.55"},
			{task_type = "top_pos", params = {goal = 500, range = 600, mode_name = "classic"}, description = "Reach Top 500 (in Classic)"},
		}
	},
	["mese"] = {
		display_name = "Mese League",
		icon_texture = "ctf_jma_leagues_mese.png",
		order = 8,
		color = "#eea160",
		requirements = {
			{task_type = "kills", params = {goal = 1500, mode_name = "total"}, description = "Reach 1500 kills"},
			{task_type = "kill_assists", params = {goal = 840, mode_name = "total"}, description = "Reach 840 kill assists"},
			{task_type = "hp_healed", params = {goal = 480, mode_name = "total"}, description = "Heal 480 HP"},
			{task_type = "flag_captures", params = {goal = 85, mode_name = "total"}, description = "Capture 85 flags"},
			{task_type = "playtime", params = {goal = 1070}, description = "Play for 17 hours and 50 minutes"},
			{task_type = "score", params = {goal = 20000, mode_name = "total"}, description = "Reach 20000 score"},
			{task_type = "kd", params = {goal = 2.1, mode_name = "total"}, description = "Maintain a K/D ratio of at least 2.1"},
			{task_type = "top_pos", params = {goal = 200, range = 300, mode_name = "classes"}, description = "Reach Top 200 (in Classes)"},
		}
	},
	["diamond"] = {
		display_name = "Diamond League",
		icon_texture = "ctf_jma_leagues_diamond.png",
		order = 9,
		color = "#8aebf1",
		requirements = {
			{task_type = "kills", params = {goal = 3000, mode_name = "total"}, description = "Reach 3000 kills"},
			{task_type = "kill_assists", params = {goal = 1200, mode_name = "total"}, description = "Reach 1200 kill assists"},
			{task_type = "hp_healed", params = {goal = 550, mode_name = "total"}, description = "Heal 550 HP"},
			{task_type = "flag_captures", params = {goal = 120, mode_name = "total"}, description = "Capture 120 flags"},
			{task_type = "playtime", params = {goal = 1240}, description = "Play for 20 hours and 40 minutes"},
			{task_type = "score", params = {goal = 22000, mode_name = "total"}, description = "Reach 22000 score"},
			{task_type = "kd", params = {goal = 2.25, mode_name = "total"}, description = "Maintain a K/D ratio of at least 2.25"},
			{task_type = "top_pos", params = {goal = 100, range = 200, mode_name = "total"}, description = "Reach Top 100 (in Any Mode)"},
		}
	},
	["platinum"] = {
		display_name = "Platinum League",
		icon_texture = "ctf_jma_leagues_platinum.png",
		order = 10,
		color = "#dff6f5",
		requirements = {
			{task_type = "kills", params = {goal = 3500, mode_name = "total"}, description = "Reach 3500 kills"},
			{task_type = "kill_assists", params = {goal = 1800, mode_name = "total"}, description = "Reach 1800 kill assists"},
			{task_type = "hp_healed", params = {goal = 700, mode_name = "total"}, description = "Heal 700 HP"},
			{task_type = "flag_captures", params = {goal = 200, mode_name = "total"}, description = "Capture 200 flags"},
			{task_type = "playtime", params = {goal = 1800}, description = "Play for 30 hours"},
			{task_type = "score", params = {goal = 38000, mode_name = "total"}, description = "Reach 38000 score"},
			{task_type = "kd", params = {goal = 2.4, mode_name = "total"}, description = "Maintain a K/D ratio of at least 2.4"},
			{task_type = "top_pos", params = {goal = 50, range = 100, mode_name = "classic"}, description = "Reach Top 50 (in Classic)"},
			{task_type = "top_pos", params = {goal = 50, range = 100, mode_name = "classes"}, description = "Reach Top 50 (in Classes)"},
			{task_type = "top_pos", params = {goal = 50, range = 100, mode_name = "nade_fight"}, description = "Reach Top 50 (in Nades)"},
		}
	},
	["titanium"] = {
		display_name = "Titanium League",
		icon_texture = "ctf_jma_leagues_titanium.png",
		order = 11,
		color = "#cd6093",
		requirements = {
			{task_type = "kills", params = {goal = 4500, mode_name = "total"}, description = "Reach 4500 kills"},
			{task_type = "kill_assists", params = {goal = 2400, mode_name = "total"}, description = "Reach 2400 kill assists"},
			{task_type = "hp_healed", params = {goal = 900, mode_name = "total"}, description = "Heal 900 HP"},
			{task_type = "flag_captures", params = {goal = 300, mode_name = "total"}, description = "Capture 300 flags"},
			{task_type = "playtime", params = {goal = 2100}, description = "Play for 35 hours and 40 minutes"},
			{task_type = "score", params = {goal = 55500, mode_name = "total"}, description = "Reach 55500 score"},
			{task_type = "kd", params = {goal = 2.6, mode_name = "total"}, description = "Maintain a K/D ratio of at least 2.6"},
			{task_type = "top_pos", params = {goal = 30, range = 50, mode_name = "classic"}, description = "Reach Top 30 (in Classic)"},
			{task_type = "top_pos", params = {goal = 30, range = 50, mode_name = "classes"}, description = "Reach Top 30 (in Classes)"},
			{task_type = "top_pos", params = {goal = 30, range = 50, mode_name = "nade_fight"}, description = "Reach Top 30 (in Nades)"},
		}
	},
	["legend"] = {
		display_name = "Legend League",
		icon_texture = "ctf_jma_leagues_legend.png",
		order = 12,
		color = "#827094",
		requirements = {
			{task_type = "kills", params = {goal = 6000, mode_name = "total"}, description = "Reach 6000 kills"},
			{task_type = "kill_assists", params = {goal = 3000, mode_name = "total"}, description = "Reach 3000 kill assists"},
			{task_type = "hp_healed", params = {goal = 1500, mode_name = "total"}, description = "Heal 1500 HP"},
			{task_type = "flag_captures", params = {goal = 500, mode_name = "total"}, description = "Capture 500 flags"},
			{task_type = "playtime", params = {goal = 3000}, description = "Play for 50 hours"},
			{task_type = "score", params = {goal = 85000, mode_name = "total"}, description = "Reach 85000 score"},
			{task_type = "kd", params = {goal = 3.0, mode_name = "total"}, description = "Maintain a K/D ratio of at least 3.0"},
			{task_type = "top_pos", params = {goal = 10, range = 50, mode_name = "classic"}, description = "Reach Top 10 (in Classic)"},
			{task_type = "top_pos", params = {goal = 10, range = 50, mode_name = "classes"}, description = "Reach Top 10 (in Classes)"},
			{task_type = "top_pos", params = {goal = 10, range = 50, mode_name = "nade_fight"}, description = "Reach Top 10 (in Nades)"},
		}
	},
}