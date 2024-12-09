unused_args = false

globals = {
	"snow", "winterize",
	"minetest", "throwable_snow", "default",
	"ctf_teams", "hud_events", "skybox",
	"ctf_settings",
}

read_globals = {
	string = {fields = {"split", "trim"}},
	table = {fields = {"copy", "getn", "shuffle"}},

	"dump", "DIR_DELIM",
	"sfinv", "creative",
	"VoxelArea", "ItemStack",
	"Settings",
	"prometheus", "hb",
	"awards",
	"vector",

	"VoxelArea",
	"VoxelManip",
	"PseudoRandom",
	"ctf_map",
	"ctf_api",

	-- Testing
	"describe",
	"it",
	"assert",
}
