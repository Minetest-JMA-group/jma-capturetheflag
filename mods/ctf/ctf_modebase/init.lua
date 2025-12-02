--- @alias GameMode table

ctf_modebase = {
	--- Table containing all registered modes and their definitions
	--- @type { [string]: GameMode }
	modes = {}, ---@type table

	--- Same as ctf_modebase.modes but in list form
	--- @type GameMode[]
	modelist = {},

	--- Name of the mode currently being played. On server start this will be false
	--- @type string?
	current_mode = nil,

	--- Players can hit, heal, etc
	--- @type boolean
	match_started = false,

	--- For team allocator
	--- @type boolean
	in_game = false,

	--- Get the mode def of the current mode.
	--- On server start, this will return nil
	--- @return GameMode?
	get_current_mode = function(self)
		return self.current_mode and self.modes[self.current_mode]
	end,

	--- Amount of matches played since this mode won the last vote
	--- @type integer
	current_mode_matches_played = 0,

	-- How many matches will be played for the current mode
	--- @type integer
	current_mode_matches = 5,

	--- @type { [Team]: FlagCarrier }
	taken_flags = {},

	--- @type { [Team]: {[PlayerName]: Team[] }}
	team_flag_takers = {},

	--- @type { [Team]: PlayerName }
	flag_taken = {},

	--- @type { [Team]: boolean? }
	flag_captured = {},

	--- @type { [PlayerName]: (number[])?}
	flag_attempt_history = {},

	--- @type { [PlayerName]: number? }
	player_on_flag_attempt_streak = {},
}

ctf_gui.old_init()

local S = core.get_translator(core.get_current_modname())
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
				visible = false,
			})
			player:set_sun({
				visible = false,
			})
			player:set_clouds({
				density = 0,
			})

			player:hud_set_flags({
				crosshair = false,
				wielditem = false,
			})

			player:override_day_night_ratio(0)

			player:set_hp(20)
			player:set_nametag_attributes({
				color = { a = 0, r = 255, g = 255, b = 255 },
				text = "",
			})
		end)
	elseif ctf_core.settings.server_mode == "play" then
		core.after(0.2, ctf_modebase.start_new_match)
	end

	for _, name in pairs(ctf_modebase.modelist) do
		ctf_settings.register("ctf_modebase:default_vote_" .. name, {
			type = "list",
			description = S("Match count vote for the mode '@1'", HumanReadable(name)),
			list = {
				S("@1 - Ask", HumanReadable(name)),
				S("0"),
				S("1"),
				S("2"),
				S("3"),
				S("4"),
				S("5"),
			},
			_list_map = { "ask", 0, 1, 2, 3, 4, 5 },
			default = "1", -- "Ask"
		})
	end
end)

core.override_chatcommand("pulverize", {
	privs = { creative = true },
})

core.register_chatcommand("mode", {
	description = S("Prints the current mode and matches played"),
	func = function(name)
		local mode = ctf_modebase.current_mode
		if not mode then
			return false, S("The game isn't running")
		end

		return true,
			S(
				"The current mode is @1. Matches finished: @2/@3",
				HumanReadable(ctf_modebase.current_mode),
				ctf_modebase.current_mode_matches_played - 1,
				ctf_modebase.current_mode_matches
			)
	end,
})

core.register_chatcommand("match", {
	description = S("Shows current match information"),
	func = function(name)
		local mode = ctf_modebase.current_mode
		if not mode then
			return false, S("The game isn't running")
		end

		-- Current mode
		local mode_str = S(
			"Mode: @1 (@2/@3 matches)",
			HumanReadable(mode),
			ctf_modebase.current_mode_matches_played - 1,
			ctf_modebase.current_mode_matches
		)

		-- Current map
		local map = ctf_map.current_map
		local map_str = map and S("Map: @1 by @2", map.name, map.author)
			or S("No map loaded")

		-- Teams info
		local team_str = ""
		local total = 0
		for _, team in ipairs(ctf_teams.current_team_list) do
			local count = ctf_teams.online_players[team].count
			team_str = team_str .. string.format("%s: %d, ", team, count)
			total = total + count
		end
		team_str = S("Players (@1 total): @2", total, team_str:sub(1, -3)) -- Remove trailing ", "

		local duration = S("Duration: @1", ctf_map.get_duration())
		return true,
			string.format("%s\n%s\n%s\n%s", mode_str, map_str, duration, team_str)
	end,
})
