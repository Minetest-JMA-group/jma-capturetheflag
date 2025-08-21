--- @alias Team "red" | "green" | "blue" | "orange" | "yellow" | "purple"
--- @alias HexColorStr string
--- @alias HexColor number
--- @alias PlayerName string
--- @alias TeamDef { color: HexColorStr, color_hex: HexColor?, irc_color: number }
--- @alias TeamsMap { [Team]: TeamDef }
--- @alias PlayerTeamMap { [PlayerName]: Team }
--- @alias TeamPlayerStatus { count: integer, players: { [PlayerName]: boolean? }}
ctf_teams = {
	--- @type TeamsMap
	team = {
		red = {
			color = "#dc0f0f",
			color_hex = 0x000,
			irc_color = 4,
		},
		green = {
			color = "#00bb00",
			color_hex = 0x000,
			irc_color = 3,
		},
		blue = {
			color = "#0062ff",
			color_hex = 0x000,
			irc_color = 2,
		},
		orange = {
			color = "#ff4e00",
			color_hex = 0x000,
			irc_color = 8,
		},
		yellow = {
			color = "#ffea00",
			color_hex = 0x000,
			irc_color = 8,
		},
		purple = {
			color = "#6f00a7",
			color_hex = 0x000,
			irc_color = 6,
		},
	},
	--- @type TeamDef[]
	teamlist = {},
	--- @type PlayerTeamMap
	player_team = {},
	--- @type { [Team]: TeamPlayerStatus }
	online_players = {},
	--- @type Team[]
	current_team_list = {},
	--- @type PlayerName[]
	non_team_players = {},
}

local S = core.get_translator(core.get_current_modname())

for team, def in pairs(ctf_teams.team) do
	table.insert(ctf_teams.teamlist, team)

	ctf_teams.team[team].color_hex = tonumber("0x" .. def.color:sub(2))
end

core.register_privilege("ctf_team_admin", {
	description = S("Allows advanced team management"),
	give_to_singleplayer = false,
	give_to_admin = false,
})

ctf_core.include_files(
	"functions.lua",
	"commands.lua",
	"register.lua",
	"team_chest.lua",
	"team_door.lua"
)

core.register_on_mods_loaded(function()
	local old_join_func = core.send_join_message
	local old_leave_func = core.send_leave_message

	local function empty_func() end

	core.send_join_message = empty_func
	core.send_leave_message = empty_func

	core.register_on_joinplayer(function(player, last_login)
		local name = player:get_player_name()

		core.after(0.5, function()
			player = core.get_player_by_name(name)

			if not player then
				old_join_func(name, last_login)
				return
			end

			ctf_teams.allocate_player(player, true)

			local pteam = ctf_teams.get(player)

			if not pteam then
				old_join_func(player:get_player_name(), last_login)
			else
				local tcolor = ctf_teams.team[pteam].color

				core.chat_send_all(
					S("*** @1 joined the game.", core.colorize(tcolor, name))
				)
			end
		end)
	end)

	core.register_on_leaveplayer(function(player, timed_out, ...)
		local pteam = ctf_teams.get(player)

		if not pteam then
			old_leave_func(player:get_player_name(), timed_out, ...)
		else
			ctf_teams.remove_online_player(player)

			local tcolor = ctf_teams.team[pteam].color
			--- @type string
			local msg
			if timed_out then
				msg = S(
					"*** @1 left the game.",
					core.colorize(tcolor, player:get_player_name())
				)
			else
				msg = S(
					"*** @1 left the game(timed out).",
					core.colorize(tcolor, player:get_player_name())
				)
			end
			core.chat_send_all(msg)
		end
	end)
end)
