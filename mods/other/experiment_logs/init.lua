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
--- @param target ("|team_players|" | "|all|" | string)?
--- @return number
function experiment_logs.log(experiment_name, text, target)
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
	if target == "|team_players|" then
		players = ctf_teams.get_all_team_players()
	elseif target == "|all|" or target == nil then
		players = core.get_connected_players()
	elseif type(target) == "table" then
		players = target
	elseif type(target) == "string" then
		players = { target }
	else
		core.log("warning", "In experiment_logs.log, target has an invalid type or value")
		return -1
	end
	local number_of_sent = 0
	for _, player in ipairs(players) do
		local pname = PlayerName(player)
		local master = ctf_settings.get(pname, "experiment_logs:subscribed")
		local this = ctf_settings.get(pname, experiment_setting)
		core.debug(
			string.format(
				"Player %s has got these values for experiment logs (master, this): %s %s",
				pname,
				master,
				this
			)
		)
		if
			ctf_settings.get(pname, "experiment_logs:subscribed")
			and ctf_settings.get(pname, experiment_setting)
		then
			number_of_sent = number_of_sent + 1
			core.chat_send_player(pname, S("[Experiment] ") .. text)
		end
	end
	return number_of_sent
end
