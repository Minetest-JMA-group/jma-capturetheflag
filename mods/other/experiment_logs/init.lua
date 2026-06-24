local S = core.get_translator(core.get_current_modname())

--- @type { [string]: boolean }
local experiments = {}

experiment_logs = {}

ctf_settings.register("experiments_log:subscribed", {
	type = "bool",
	label = S("Master setting to receive logs about experiments"),
	description = S(
		"By enabling this, you'll receive logs in chat whenever an experiment is going in the game. This is for receiving feedback from players."
	),
	default = "false",
})

--- @param technical_name string
--- @param label string
--- @param description string
function experiment_logs.register_new_experiment(technical_name, label, description)
	if experiments[technical_name] then
		-- Do not register twice
		core.log(
			"warning",
			string.format(
				"Experiment %s has been registered more than once",
				technical_name
			)
		)
		return
	end
	ctf_settings.register("experiment_logs:" .. technical_name, {
		type = "bool",
		label = label,
		description = description,
		default = "false",
	})
end

--- Send a chat message to all players who have subscribed to
--- experiment logs
--- @param experiment_name string
--- @param text string
--- @param only_team_players boolean?
--- @return number
function experiment_logs.log(experiment_name, text, only_team_players)
	if not experiments[experiment_name] then
		core.log(
			"warning",
			string.format(
				"Trying to call log on unregistered experiment: %s",
				experiment_name
			)
		)
		return -1
	end
	local experiment_setting = "experiment_logs:" .. experiment_name
	local players = nil
	if only_team_players then
		players = ctf_teams.get_all_team_players()
	else
		players = core.get_connected_players()
	end
	local number_of_sent = 0
	for _, player in ipairs(players) do
		local pname = player:get_player_name()
		if
			ctf_settings.get(pname, "experiment_logs:subscribed")
			and ctf_settings.get(pname, experiment_setting)
		then
			number_of_sent = number_of_sent + 1
			core.chat_send_player(S("[Experiment] ") .. text)
		end
	end
	return number_of_sent
end
