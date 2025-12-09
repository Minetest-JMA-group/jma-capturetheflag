-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Copyright (c) 2025 Farooq Karimi Zadeh
local feedbacks_path = core.settings:get("ctf_feedback_path")
local min_playtime = core.settings:get("ctf_feedback_min_playtime")

if min_playtime ~= nil then
	min_playtime = tonumber(min_playtime)
else
	min_playtime = 0
end

local S = core.get_translator(core.get_current_modname())

local FORMNAME = "ctf_feedback:form"

local FEEDBACK_MAX_LENGTH = 10000

local ONE_HOUR = 3600 -- in seconds

-- The number is timestamp.
-- Players can send a maximum of 2 feedbacks each hour.
-- We allow 2 per hour, because the second one is an optional
-- follow up. We track the follow up feedback in the second table below.
--
-- Also we don't mind server restarts for now.
--- @type { [PlayerName]: number }
local last_feedback_times = {}

-- Has the player used their se
--- @type { [PlayerName]: boolean }
local used_followup_feedback = {}

--- @param pname PlayerName
--- @return boolean, ("ratelimit" | "playtime")?
local function can_send_feedback(pname)
	if playtime and playtime.get_total_playtime(pname) < min_playtime then
		core.debug("Not enough playtime for " .. pname .. " to give feedback")
		return false, "playtime"
	end
	if last_feedback_times[pname] == nil then
		return true
	end
	local timestamp = last_feedback_times[pname]
	if math.abs(os.time() - timestamp) <= ONE_HOUR then
		return true
	end
	if not used_followup_feedback[pname] then
		return true
	end
	return false, "ratelimit"
end

--- Generate a random new integer Id
--- @return integer
local function get_new_id()
	return math.floor(10000 + math.random() * 50000)
end

local io = nil

--- @param pname PlayerName
--- @param feedback string
--- @return boolean
local function record_feedback(pname, feedback)
	core.debug(
		"Got feedback from " .. pname .. ". Length is " .. tonumber(string.len(feedback))
	)
	if io then
		local id = get_new_id()
		local filename = pname .. "." .. tostring(id)
		local file = io.open(feedbacks_path .. "/" .. filename, "w")
		file:write(feedback)
		file:close()
	else
		core.debug("not recording feedback cuz there is no insecure env")
	end
	if not can_send_feedback(pname) then
		return false
	end
	if last_feedback_times[pname] == nil then
		last_feedback_times[pname] = os.time()
	elseif math.abs(os.time() - last_feedback_times[pname]) <= ONE_HOUR then
		used_followup_feedback[pname] = true
		last_feedback_times[pname] = os.time()
	end
	return true
end

if type(feedbacks_path) == "string" then
	local insecure_env = core.request_insecure_environment()
	io = insecure_env.io
	core.register_chatcommand("feedback", {
		params = S("[Your feedback]"),
		description = S("Write developers and server admins a feedback about the game."),
		func = function(pname, params)
			if params ~= "" then
				if record_feedback(pname, params) then
					return true, S("Thanks! Your feedback has been recorded!")
				else
					return true, S("You can send at most 2 feedbacks per hour")
				end
			end
			core.show_formspec(
				pname,
				FORMNAME,
				"formspec_version[4]size[6.6,8]"
					.. "box[0,0;6.6,8;#000000BB]"
					.. "textarea[0.2,0.6;6,6;feedback;Feedback;Your feedback here]"
					.. "button_exit[1,6.9;2,0.8;quit;Cancel]"
					.. "button[3.4,6.9;2,0.8;submit;Submit]"
			)
		end,
	})

	core.register_on_player_receive_fields(function(player, formname, fields)
		local pname = player:get_player_name()
		if formname ~= FORMNAME then
			return
		end
		if not fields.submit then
			return
		end
		core.close_formspec(pname, formname)
		if record_feedback(pname, fields.feedback) then
			return true, S("Thanks! Your feedback has been recorded!")
		else
			return true, S("You can send at most 2 feedbacks per hour")
		end
	end)
end
