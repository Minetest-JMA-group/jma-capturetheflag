ctf_modebase = {
	-- Table containing all registered modes and their definitions
	modes                = {},    ---@type table

	-- Same as ctf_modebase.modes but in list form
	modelist             = {},    ---@type list

	-- Name of the mode currently being played. On server start this will be false
	current_mode         = false, ---@type string

	-- Players can hit, heal, etc
	match_started         = false, ---@type boolean

	-- For team allocator
	in_game               = false, ---@type boolean

	-- Get the mode def of the current mode. On server start this will return false
	get_current_mode = function(self)
		return self.current_mode and self.modes[self.current_mode]
	end,

	-- Amount of matches played since this mode won the last vote
	current_mode_matches_played = 0, ---@type integer

	-- How many matches will be played for the current mode
	current_mode_matches        = 5, ---@type integer

	-- taken_flags[Player Name] = list of team names
	taken_flags          = {},

	-- team_flag_takers[Team name][Player Name] = list of team names
	team_flag_takers     = {},

	-- flag_taken[Team Name] = Name of thief
	flag_taken           = {},

	--flag_captured[Team name] = true if captured, otherwise nil
	flag_captured        = {},

	flag_attempt_history = {
		-- ["player"] = {time0, time1, time2, ...}
	},

	player_on_flag_attempt_streak = {
		-- ["player"] = streak index
	},
}

ctf_gui.old_init()

-- Can be added to by other mods, like irc
function ctf_modebase.announce(msg)
	core.log("action", msg)
end

ctf_core.include_files(
	"register.lua",
	"map_catalog.lua",
	"map_catalog_show.lua",
	"ranking_commands.lua",
	"summary.lua",
	"player.lua",
	"immunity.lua",
	"treasure.lua",
	"flags/nodes.lua",
	"flags/taking.lua",
	"flags/huds.lua",
	"match.lua",
	"crafting.lua",
	"hpregen.lua",
	"respawn_delay.lua",
	"markers.lua",
	"bounties.lua",
	"build_timer.lua",
	"update_wear.lua",
	"mode_vote.lua",
	"skip_vote.lua",
	"recent_rankings.lua",
	"bounty_algo.lua",
	"features.lua",
	"map_vote.lua"
)

core.register_on_mods_loaded(function()
	table.sort(ctf_modebase.modelist)

	if ctf_rankings.do_reset then
		core.register_on_joinplayer(function(player)
			skybox.clear(player)

			player:set_moon({
				visible = false
			})
			player:set_sun({
				visible = false
			})
			player:set_clouds({
				density = 0
			})

			player:hud_set_flags({
				crosshair = false,
				wielditem = false,
			})

			player:override_day_night_ratio(0)

			player:set_hp(20)
			player:set_nametag_attributes({color = {a = 0, r = 255, g = 255, b = 255}, text = ""})
		end)
	elseif ctf_core.settings.server_mode == "play" then
		core.after(0.2, ctf_modebase.start_new_match)
	end

	for _, name in pairs(ctf_modebase.modelist) do
		ctf_settings.register("ctf_modebase:default_vote_"..name, {
			type = "list",
			description = "Match count vote for the mode '"..HumanReadable(name).."'",
			list = {HumanReadable(name).." - Ask", "0", "1", "2", "3", "4", "5"},
			_list_map = {"ask", 0, 1, 2, 3, 4, 5},
			default = "1", -- "Ask"
		})
	end
end)

core.override_chatcommand("pulverize", {
	privs = {creative = true},
})

core.register_chatcommand("mode", {
	description = "Prints the current mode and matches played",
	func = function(name)
		local mode = ctf_modebase.current_mode
		if not mode then
			return false, "The game isn't running"
		end

		return true, string.format("The current mode is %s. Matches finished: %d/%d",
			HumanReadable(ctf_modebase.current_mode),
			ctf_modebase.current_mode_matches_played-1,
			ctf_modebase.current_mode_matches
		)
	end
})

core.register_chatcommand("match", {
	description = "Shows current match information",
	func = function(name)
		local mode = ctf_modebase.current_mode
		if not mode then
			return false, "The game isn't running"
		end

		-- Current mode
		local mode_str = string.format("Mode: %s (%d/%d matches)",
			HumanReadable(mode),
			ctf_modebase.current_mode_matches_played-1,
			ctf_modebase.current_mode_matches
		)

		-- Current map
		local map = ctf_map.current_map
		local map_str = map and string.format("Map: %s by %s",
			map.name, map.author) or "No map loaded"

		-- Teams info
		local team_str = ""
		local total = 0
		for _, team in ipairs(ctf_teams.current_team_list) do
			local count = ctf_teams.online_players[team].count
			team_str = team_str .. string.format("%s: %d, ", team, count)
			total = total + count
		end
		team_str = string.format("Players (%d total): %s",
			total, team_str:sub(1, -3)) -- Remove trailing ", "

		local duration = string.format("Duration: %s", ctf_map.get_duration())
		return true, string.format("%s\n%s\n%s\n%s",
			mode_str, map_str, duration, team_str)
	end
})
