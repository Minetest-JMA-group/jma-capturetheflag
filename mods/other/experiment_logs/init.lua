local S = core.get_translator(core.get_current_modname())

--- @type { [string]: boolean }
local experiments = {}

experiment_logs = {}

ctf_settings.register("experiments_log:subscribed", {
	type = "bool",
	label = S("[Experiment logs] ")
		.. S("Master setting to receive logs about experiments"),
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
		label = S("[Experiment log] ") .. label,
		description = description,
		default = "false",
	})
	experiments[technical_name] = true
end

--- Send a chat message to all players who have subscribed to
--- experiment logs
--- @param experiment_name string
--- @param text string
--- @param target ("|team_players|" | "|all|" | "|not_team_players|" | PlayerName[])?
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
	core.debug("Experiment setting name is " .. experiment_setting)
	local team_players = ctf_teams.get_all_team_players()
	local connected_players = core.get_connected_players()
	--- @type table
	local players = {}
	if target == "|team_players|" or target == "|not_team_players|" then
		for _, player in ipairs(connected_players) do
			local is_team_player = ctf_teams.get(player:get_player_name())
			if target == "|team_players|" and is_team_player then
				table.insert(players, player)
			elseif target == "|not_team_players|" and not is_team_player then
				table.insert(players, player)
			end
		end
	elseif target == "|all|" or target == nil then
		players = connected_players
	elseif type(target) == "table" then
		for _, pname in ipairs(target) do
			table.insert(players, core.get_player_by_name(pname))
		end
	else
		core.log("warning", "In experiment_logs.log, target has an invalid type or value")
		return -1
	end
	core.debug(
		string.format(
			"Sending experiment log of %s to %d players",
			experiment_name,
			#players
		)
	)
	local number_of_sent = 0
	for _, player in ipairs(players) do
		local master = ctf_settings.get(player, "experiment_logs:subscribed")
		local this = ctf_settings.get(player, experiment_setting)
		local pname = player:get_player_name()
		core.debug(
			string.format(
				"Player %s has got these values for experiment logs (master, this): %s %s",
				pname,
				master,
				this
			)
		)
		if master and this then
			number_of_sent = number_of_sent + 1
			core.chat_send_player(pname, S("[Experiment] ") .. text)
		end
	end
	return number_of_sent
end
