local CHAT_COLOR =

local S = core.get_translator(core.get_current_modname())

ctf_settings.register("ctf_experiment:receive_experiment_messages", {
	type = "bool",
	label = S("Receive experiment messages"),
	description = S(
		"Turn it on if you would like to receive messages about experiments and potentionally, provide feedback"
	),
	default = "false", -- "Ask"
})

ctf_experiment = {}

--- Send a message to players who are interestd about experiments
--- @param msg string The message
--- @param team boolean? Set to true if message should be sent only to players who are in
--- a team
--- @return nil
function ctf_experiment.send_message(msg, team)
	--- @type fun(pname: string) : boolean)
	local function check(pname)
		return true
	end
	if team then
		check = function(pname)
			if ctf_teams.get(pname) ~= nil then
				return true
			else
				return false
			end
		end
	end
	for _, player in core.get_connected_players() do
		local pname = player:get_player_name()
		if check(pname) then
			core.chat_send_player(pname, core.colorize(msg, CHAT_COLOR))
		end
	end
end
