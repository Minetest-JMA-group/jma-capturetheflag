--- @alias Reward { bounty_kills: integer, score: number }
--- @alias ContributedBounty { contributors: { [string]: number }, total: number }
--- @alias GameBounty { name: string, rewards: Reward, msg: string }
--- @type "orange"
local CHAT_COLOR = "orange"
--- @type nil | table
local timer = nil
--- @type { [string]: GameBounty }
local game_bounties = {} -- bounties assigned by the game
--- @type { [string]: ContributedBounty }-- bounties contributed by the players
local contributed_bounties = {}

local S = core.get_translator(core.get_current_modname())

ctf_modebase.bounties = {} -- this is for the bounties API

--- @param pname string
--- @return number
local function calc_total_contributed_bounty(pname)
	if contributed_bounties[pname] == nil then
		return 0
	end
	--- @type number
	local total = 0
	for _, amount in pairs(contributed_bounties[pname].contributors) do
		-- Make sure that amount is positive
		if amount > 0 then
		    total = total + amount
		end
	end
	return total
end

local function update_bounty_total(pname)
	if contributed_bounties[pname] then
		contributed_bounties[pname].total = calc_total_contributed_bounty(pname)
		if contributed_bounties[pname].total <= 0 then
			contributed_bounties[pname] = nil
		end
	end
end

-- Whenever players change team, e.g. in many team maps or on rejoin
-- this has to be called
ctf_teams.register_on_allocplayer(function()
	local cur_mode = ctf_modebase:get_current_mode()
	for target_name, bounties2 in pairs(contributed_bounties) do
		for contributor, amount in pairs(bounties2.contributors) do
			if ctf_teams.get(target_name) == ctf_teams.get(contributor) then
				cur_mode.recent_rankings.add(contributor, { score = amount }, true)
				game_bounties[contributor] = nil
			end
		end
	end
end)

--- Get a list of contributors for some player if any
--- @param name string Player name
--- @return string | nil A human readable comma separated list of bounties
local function get_contributors(name)
	local bounty = contributed_bounties[name]
	if not bounty then
		return ""
	else
		local list = ""
		local first = true
		for contributor, score in pairs(bounty.contributors) do
			if first then
				list = list .. contributor
				first = false
			else
				list = "," .. list .. contributor
			end
		end
		return list
	end
end

--- @param rewards Reward[]
--- @return string
local function get_reward_str(rewards)
	local ret = ""

	for reward, amount in pairs(rewards) do
		ret = string.format(
			"%s%s%d %s, ",
			ret,
			amount >= 0 and "+" or "-",
			amount,
			HumanReadable(reward)
		)
	end

	return ret:sub(1, -3)
end

--- @param pname string Player's name
--- @param pteam string Player's teamname
--- @param rewards Reward[]
--- @return nil
local function set(pname, pteam, rewards)
	local bounty_message = core.colorize(
		CHAT_COLOR,
		S("[Bounty] @1. Rewards: @2", pname, get_reward_str(rewards))
	)

	for _, team in ipairs(ctf_teams.current_team_list) do -- show bounty to all but target's team
		if team ~= pteam then
			ctf_teams.chat_send_team(team, bounty_message)
		end
	end

	game_bounties[pteam] = { name = pname, rewards = rewards, msg = bounty_message }
end

--- @param pname string
--- @param pteam string
--- @return nil
local function remove(pname, pteam)
	core.chat_send_all(
		core.colorize(CHAT_COLOR, S("[Bounty] @1 is no longer bountied", pname))
	)
	game_bounties[pteam] = nil
end

--- @param player string
--- @param killer string
function ctf_modebase.bounties.claim(player, killer)
	--- @type string | nil
	local pteam = ctf_teams.get(player)
	if pteam == nil then
		return
	end
	--- @type boolean
	local got_game_bounty = game_bounties[pteam] and game_bounties[pteam].name == player
	local got_player_bounty = contributed_bounties[player]
	if not got_game_bounty and not got_player_bounty then
		return
	end

	local rewards = nil
	if got_game_bounty then
		rewards = game_bounties[pteam].rewards
	end

	if rewards then
		local reward_str = get_reward_str(rewards)
		local messages = {
			S("[Bounty] @1 eliminated @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 took down @2 and claimed @3", killer, player, reward_str),
			S("[Bounty] @1 got rid of @2 and secured @3", killer, player, reward_str),
			S("[Bounty] @1 turned @2 into loot and pocketed @3 (nice!)", killer, player, reward_str), -- Humorous one
		}
		--- @type string
		local bounty_kill_text = messages[math.random(1, #messages)]
		core.chat_send_all(core.colorize(CHAT_COLOR, bounty_kill_text))
	end

	game_bounties[pteam] = nil

	if contributed_bounties[player] then
		local score = contributed_bounties[player].total
		if rewards == nil then
			rewards = { bounty_kills = 0, score = 0 }
		end
		rewards.score = rewards.score + score
		rewards.bounty_kills = #contributed_bounties[player].contributors
			+ rewards.bounty_kills
		local bounty_kill_text = S(
			"[Player bounty] @1 killed @2 and got @3 from @4!",
			killer,
			player,
			score,
			get_contributors(player)
		)
		core.chat_send_all(core.colorize(CHAT_COLOR, bounty_kill_text))
		ctf_modebase.announce(bounty_kill_text)
		contributed_bounties[player] = nil
	end

	return rewards
end

--- @return nil
function ctf_modebase.bounties.reassign()
	local teams = {}

	for tname, team in pairs(ctf_teams.online_players) do
		teams[tname] = {}
		for player in pairs(team.players) do
			table.insert(teams[tname], player)
		end
	end

	for tname in pairs(game_bounties) do
		if not teams[tname] then
			teams[tname] = {}
		end
	end

	for tname, team_members in pairs(teams) do
		local old = nil
		if game_bounties[tname] then
			old = game_bounties[tname].name
		end

		local new = nil
		if #team_members > 0 then
			new = ctf_modebase.bounties.get_next_bounty(team_members)
		end

		if old and old ~= new then
			remove(old, tname)
		end

		if new then
			set(new, tname, ctf_modebase.bounties.bounty_reward_func(new))
		end
	end
end

--- @return nil
function ctf_modebase.bounties.reassign_timer()
	timer = core.after(math.random(180, 360), function()
		ctf_modebase.bounties.reassign()
		ctf_modebase.bounties.reassign_timer()
	end)
end

ctf_api.register_on_match_start(ctf_modebase.bounties.reassign_timer)

ctf_api.register_on_match_end(function()
	game_bounties = {}
	if timer then
		timer:cancel()
		timer = nil
	end
end)

--- @return Reward
function ctf_modebase.bounties.bounty_reward_func()
	return { bounty_kills = 1, score = 500 }
end

--- @param team_members string[]
--- @return string
function ctf_modebase.bounties.get_next_bounty(team_members)
	return team_members[math.random(1, #team_members)]
end

ctf_teams.register_on_allocplayer(
	--- @param player table
	--- @param new_team string
	--- @param old_team string
	--- @return nil
	function(player, new_team, old_team)
		local pname = player:get_player_name()

		if
			old_team
			and old_team ~= new_team
			and game_bounties[old_team]
			and game_bounties[old_team].name == pname
		then
			remove(pname, old_team)
		end

		local output = {}

		for tname, bounty in pairs(game_bounties) do
			if new_team ~= tname then
				table.insert(output, bounty.msg)
			end
		end

		if #output > 0 then
			core.chat_send_player(pname, table.concat(output, "\n"))
		end
	end
)

ctf_core.register_chatcommand_alias("list_bounties", "lb", {
	description = S("List current bounties"),
	--- @param name string
	--- @return boolean, string
	func = function(name)
		--- @type string | nil
		local pteam = ctf_teams.get(name)
		--- @type string[]
		local output = {}
		--- @type number
		local x = 0
		for tname, bounty in pairs(game_bounties) do
			--- @type table | nil
			local player = core.get_player_by_name(bounty.name)

			if player and pteam ~= tname then
				local label = string.format(
					"label[%d,0.1;%s: %s score]",
					x,
					bounty.name,
					core.colorize("cyan", bounty.rewards.score)
				)

				table.insert(output, label)
				--- @type string
				local model =
					"model[%d,1;4,6;player;character.b3d;%s,blank.png;{0,160};;;]"
				model = string.format(model, x, player:get_properties().textures[1])
				table.insert(output, model)
				x = x + 4.5
			end
		end
		for pname, bounty in pairs(contributed_bounties) do
			--- @type table | nil
			local player = core.get_player_by_name(pname)
			if player then
				--- @type string
				local label = string.format(
					"label[%d,0.1;%s: %s score]",
					x,
					pname,
					core.colorize("cyan", bounty.total)
				)
				table.insert(output, label)
				--- @type string
				local model = "model[%d,1;4,6;player;character.b3d;%s;{0,160};;;]"
				model = string.format(model, x, player:get_properties().textures[1])
				table.insert(output, model)
				x = x + 4.5
			end
		end

		if #output <= 0 then
			return false, S("There are no bounties you can claim")
		end
		x = x - 1.5
		local formspec = "size[" .. x .. ",6]\n" .. table.concat(output, "\n")
		core.show_formspec(name, "ctf_modebase:lb", formspec)
		return true, ""
	end,
})

ctf_core.register_chatcommand_alias("put_bounty", "pb", {
	description = S("Put bounty on some player"),
	params = "<player> <amount>",
	privs = { ctf_admin = true },
	--- @param name string
	--- @param param string
	--- @return boolean, string
	func = function(name, param)
		--- @type string, string
		local player, amount_s = param:match("(%S+)%s+(%S+)")
		--- @type string | nil
		local pteam = ctf_teams.get(player)
		if not (player and pteam and amount_s) then
			return false, S("Incorrect parameters")
		end
		--- @type number
		local amount = ctf_core.to_number(amount_s)
		set(player, pteam, { bounty_kills = 1, score = amount })
		return true,
			S("Successfully placed a bounty of @1 on @2!", amount, player)
	end,
})

ctf_core.register_chatcommand_alias("bounty", "bo", { -- /b is already registered in babelfish mod
	description = S(
		"Place a bounty on someone using your match score.\n"
			.. "The score is returned to you if the match ends and nobody kills.\n"
			.. "Use negative score to revoke a bounty"
	),
	params = "<player> <score>",
	--- @param name string The player calling this
	--- @param params string Passed parameters
	--- @return boolean, string
	func = function(name, params)
		--- @type string?, number?
		local bname, amount = string.match(params, "([^%s]*) ([^%s]*)")
		if not (amount and bname) then
			return false, S("Missing argument(s)")
		end
		amount = math.floor(amount)
		local bteam = ctf_teams.get(bname)
		if not bteam then
			return false, S("This player isn't online or isn't in a team")
		end
		if bteam == ctf_teams.get(name) then
			return false, S("You cannot place a bounty on your teammate!")
		end
		local current_mode = ctf_modebase:get_current_mode()

		if not current_mode or not ctf_modebase.match_started then
			return false, S("Match has not started yet.")
		end

		if amount <= 0 then
			if not contributed_bounties[bname] or not contributed_bounties[bname].contributors[name] then
				return false, S("You don't have any bounty on this player to revoke")
			end

			local my_contribution = contributed_bounties[bname].contributors[name]
			local revoke_amount = math.min(math.abs(amount), my_contribution)

			contributed_bounties[bname].contributors[name] = my_contribution - revoke_amount

			if contributed_bounties[bname].contributors[name] <= 0 then
				contributed_bounties[bname].contributors[name] = nil

				local has_contributors = false
				for _ in pairs(contributed_bounties[bname].contributors) do
					has_contributors = true
					break
				end

				if not has_contributors then
					contributed_bounties[bname] = nil
				else
					update_bounty_total(bname)
				end
			else
				update_bounty_total(bname)
			end

			current_mode.recent_rankings.add(name, { score = revoke_amount }, true)
			return true, S("@1 points returned to you.", revoke_amount)
		end

		if amount < 5 then
			return false, S("Your bounty needs to be of at least 5 points")
		end
		if amount > 100 then
			return false, S("Your bounty cannot be of more than 100 points")
		end
		local cur_score = current_mode.recent_rankings.get(name).score or 0
		if amount > cur_score then
			return false, S("You haven't got enough points")
		end
		current_mode.recent_rankings.add(name, { score = -amount }, true)
		if not contributed_bounties[bname] then
			local contributors = {}
			contributors[name] = amount
			contributed_bounties[bname] = { contributors = contributors, total = amount }
		else
			--- @type ContributedBounty
			local c_bounty = contributed_bounties[bname]
			if not c_bounty.contributors[name] then
				c_bounty.contributors[name] = amount
			else
				c_bounty.contributors[name] = c_bounty.contributors[name] + amount
			end
			update_bounty_total(bname)
		end
		local total = calc_total_contributed_bounty(bname)
		core.chat_send_all(
			core.colorize(
				CHAT_COLOR,
				S("@1 placed @2 bounty on @3!", get_contributors(bname), total, bname)
			)
		)
	end,
})

ctf_api.register_on_match_end(function()
	-- there might be some unclaimed player bounties, here we return
	-- the points to their contributors
	local current_mode = ctf_modebase:get_current_mode()
	for _, bounty in pairs(contributed_bounties) do
		for bounty_donator, bounty_amount in pairs(bounty.contributors) do
			current_mode.recent_rankings.add(
				bounty_donator,
				{ score = bounty_amount },
				true
			)
		end
	end
	contributed_bounties = {} -- Clean up on match end
end)
