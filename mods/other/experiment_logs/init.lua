local S = core.get_translator(core.get_current_modname())

ctf_settings.register("experiments_log:subscribed", {
	type = "bool",
	label = S("Receive logs about experiments"),
	description = S(
		"By enabling this, you'll receive logs in chat whenever an experiment is going in the game. This is for receiving feedback from players."
	),
	default = "false",
})

--- Send a chat message to all players who have subscribed to
--- experiment logs
--- @param text string
--- @param only_team_players boolean?
--- @return number
function experiment_logs.log(text, only_team_players)
	local players = nil
	if only_team_players then
		players = ctf_teams.get_all_team_players()
	else
		players = core.get_connected_players()
	end
	local number_of_sent = 0
	for _, player in ipairs(players) do
		if ctf_settings.get(player:get_player_name(), "experiment_logs:subscribed") then
			number_of_sent = number_of_sent + 1
			core.chat_senmd_player(S("[Experiment] ") .. text)
		end
	end
	return number_of_sent
end
