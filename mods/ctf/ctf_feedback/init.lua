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

local io = nil

--- @param pname PlayerName
--- @param feedback string
--- @return boolean, ("length" | "ratelimit" | "playtime")?
local function record_feedback(pname, feedback)
	core.debug(
		"Got feedback from " .. pname .. ". Length is " .. tonumber(string.len(feedback))
	)
	local can_send, reason = can_send_feedback(pname)
	if not can_send then
		return can_send, reason
	end
	if string.len(feedback) > FEEDBACK_MAX_LENGTH then
		return false, "length"
	end
	if io then
		local file
		if type(feedbacks_path) == "string" then
			file = io.open(feedbacks_path .. "/" .. pname .. ".txt", "a+")
		else
			file = io.tmpfile()
		end
		if not file then
			file = io.tmpfile()
		end
		file:write("\n\n")

		file:write(feedback)
		file:close()
	else
		core.debug("not recording feedback cuz there is no insecure env")
	end
	if last_feedback_times[pname] == nil then
		last_feedback_times[pname] = os.time()
	elseif math.abs(os.time() - last_feedback_times[pname]) <= ONE_HOUR then
		used_followup_feedback[pname] = true
		last_feedback_times[pname] = os.time()
	end
	return true
end

if type(feedbacks_path) ~= "string" then
	core.log(
		"warning",
		"ctf_feedback_path must be a string. using temporary files as a fallback"
	)
end

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
	local status, reason = record_feedback(pname, fields.feedback)
	local message
	local close = true
	if status then
		message = S("Thanks! Your feedback has been recorded!")
	else
		if reason == "playtime" then
			message = S("You don't have enough playtime to send a feedback")
		elseif reason == "ratelimit" then
			message = S("You can send at most 2 feedbacks per hour")
		else
			message =
				S("Your feedback is too long. Maximum length is @1", FEEDBACK_MAX_LENGTH)
			close = false
		end
	end
	if close then
		core.close_formspec(pname, formname)
	end
	return true, message
end)
