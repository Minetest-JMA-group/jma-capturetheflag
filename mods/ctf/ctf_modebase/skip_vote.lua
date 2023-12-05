local hud = mhud.init()

local SKIP_DELAY = 50 * 60
local VOTING_TIME = 30

local timer = nil
local time_left = 0
local votes = nil
local voters_count = nil

local voted_skip = false
local flags_hold = 0

local already_voted = false

--TODO Setting to hide vote HUD
-- ctf_settings.register("show_match_skip_vote", {
-- 	type = "bool",
-- 	label = "Show voting for skip the match when it is available",
-- 	description = "",
-- 	default = "false"
-- })

ctf_modebase.skip_vote = {}


local function vote_timer_hud(player)
	local time_str = string.format("Vote to skip match [%d]", math.floor(time_left % 60))

	if not hud:exists(player, "skip_vote:timer") then
		hud:add(player, "skip_vote:timer", {
			hud_elem_type = "text",
			position = {x = 1, y = 0.5},
			offset = {x =-100, y = -30},
			text = time_str,
			color = 0xFFFFFF,
		})
	else
		hud:change(player, "skip_vote:timer", {
			text = time_str
		})
	end
end

local function add_vote_hud(player)
	hud:add(player, "skip_vote:vote", {
		hud_elem_type = "text",
		position = {x = 1, y = 0.5},
		offset = {x = -100, y = 0},
		text = "/yes /no or /abs",
		color = 0xFFFFFF,
		style = 2
	})
	vote_timer_hud(player)
end

local function timer_func()
	if time_left <= 0 then
		time_left = 0
		ctf_modebase.skip_vote.end_vote()
		return
	end

	for _, player in ipairs(minetest.get_connected_players()) do
		vote_timer_hud(player)
	end

	time_left = time_left - 1
	timer = minetest.after(1, timer_func)
end

function ctf_modebase.skip_vote.start_vote()
	if timer then
		timer:cancel()
		timer = nil
	end

	votes = {}
	voters_count = 0

	for _, player in ipairs(minetest.get_connected_players()) do
		add_vote_hud(player)
		voters_count = voters_count + 1
	end

	time_left = VOTING_TIME
	timer_func()
end

function ctf_modebase.skip_vote.end_vote()
	if timer then
		timer:cancel()
		timer = nil
	end

	hud:remove_all()

	local yes = 0
	local no = 0

	for _, vote in pairs(votes) do
		if vote == "yes" then
			yes = yes + 1
		elseif vote == "no" then
			no = no + 1
		end
	end

	votes = nil

	local connected_players = #minetest.get_connected_players()
	if connected_players == 0 then
		return
	end

	if voters_count < math.ceil(connected_players / 2) then
		if yes > no then
			minetest.chat_send_all(string.format("Vote to skip match passed, %d to %d", yes, no))

			voted_skip = true
			if flags_hold <= 0 then
				ctf_modebase.start_new_match(5)
			end
		else
			minetest.chat_send_all(string.format("Vote to skip match failed, %d to %d", yes, no))
		end
	else
		minetest.chat_send_all("Vote to skip match failed, too few votes")
	end
end

-- Automatically start a skip vote after 50m, and subsequent votes every 15m
ctf_api.register_on_match_start(function()
	if timer then
		timer:cancel()
		timer = nil
	end

	hud:remove_all()

	votes = nil

	voted_skip = false
	flags_hold = 0


	timer = minetest.after(SKIP_DELAY, ctf_modebase.skip_vote.start_vote)
	already_voted = false
end)

ctf_api.register_on_match_end(function()
	if timer then
		timer:cancel()
		timer = nil
	end

	hud:remove_all()

	votes = nil

	voted_skip = false
	flags_hold = 0
	already_voted = false
end)

function ctf_modebase.skip_vote.on_flag_take()
	flags_hold = flags_hold + 1
end

function ctf_modebase.skip_vote.on_flag_drop(count)
	flags_hold = flags_hold - count
	if flags_hold <= 0 and voted_skip then
		ctf_modebase.start_new_match(5)
	end
end

function ctf_modebase.skip_vote.on_flag_capture(count)
	flags_hold = flags_hold - count
	if flags_hold <= 0 and voted_skip then
		voted_skip = false
		timer = minetest.after(30, ctf_modebase.skip_vote.start_vote)
	end
end

minetest.register_on_joinplayer(function(player)
	if votes and not votes[player:get_player_name()] then
		add_vote_hud(player)
		voters_count = voters_count + 1
	end
end)

minetest.register_on_leaveplayer(function(player)
	if votes and not votes[player:get_player_name()] then
		voters_count = voters_count - 1

		if voters_count == 0 then
			ctf_modebase.skip_vote.end_vote()
		end
	end
end)

minetest.register_chatcommand("vote_skip", {
	description = "Start a match skip vote",
	privs = {ctf_admin = true},
	func = function(name, param)
		minetest.log("action", string.format("[ctf_admin] %s ran /vote_skip", name))

		if not ctf_modebase.in_game then
			return false, "Map switching is in progress"
		end

		if votes then
			return false, "Vote is already in progress"
		end

		ctf_modebase.skip_vote.start_vote()
		return true, "Vote is started"
	end,
})

-- ctf_api.register_on_new_match(function()
-- 	--start voting later, otherwise will start at loading


-- 	minetest.after(1, function()
-- 		if not ctf_modebase.in_game or votes then
-- 			return
-- 		end

-- 		if #minetest.get_connected_players() > 1 then
-- 			ctf_modebase.skip_vote.start_vote()
-- 		end
-- 	end)
-- end)

local function player_vote(name, vote)
	local function do_vote()
		if not votes then
			return
		end

		if not votes[name] then
			voters_count = voters_count - 1
		end

		votes[name] = vote

		local player = minetest.get_player_by_name(name)
		if hud:exists(player, "skip_vote:vote") then
			hud:change(player, "skip_vote:vote", {
				text = string.format("[%s]", vote),
				style = 1
			})
		end
	end

	if not votes then
		if not ctf_modebase.match_started then
			if #minetest.get_connected_players() > 0 and not already_voted then
				ctf_modebase.skip_vote.start_vote()
				do_vote()
				already_voted = true
				return true
			else
				return false, "Sorry, you can't vote right now"
			end
		else
			return false, "You can't vote during the match"
		end
		return false, "There is no vote in progress"
	end

	do_vote()
	return true
end

minetest.register_chatcommand("yes", {
	description = "Vote yes",
	privs = {interact = true},
	func = function(name, params)
		return player_vote(name, "yes")
	end
})

minetest.register_chatcommand("no", {
	description = "Vote no",
	privs = {interact = true},
	func = function(name, params)
		return player_vote(name, "no")
	end
})

minetest.register_chatcommand("abs", {
	description = "Vote third party",
	privs = {interact = true},
	func = function(name, params)
		return player_vote(name, "abstain")
	end
})
