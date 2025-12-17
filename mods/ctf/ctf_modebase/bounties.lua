--- @alias Reward { bounty_kills?: integer, score: number }
--- @alias ContributedBounty { contributors: { [string]: number } }
--- @alias GameBounty { name: string, rewards: Reward, msg: string }
--- @type "orange"
local CHAT_COLOR = "orange"
--- @type nil | table
local timer = nil
--- @type { [string]: GameBounty }
local game_bounties = {} -- bounties assigned by the game
--- @type { [string]: ContributedBounty }-- bounties contributed by the players
local contributed_bounties = {}
--- @type number
local PLAYER_BOUNTY_CAP = 100
--- @type number
local PLAYER_BOUNTY_MIN = 5

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

-- Whenever players change team, e.g. in many team maps or on rejoin
-- this has to be called
ctf_teams.register_on_allocplayer(function()
	local cur_mode = ctf_modebase:get_current_mode()
	for target_name, bounties2 in pairs(contributed_bounties) do
		for contributor, amount in pairs(bounties2.contributors) do
			if ctf_teams.get(target_name) == ctf_teams.get(contributor) then
				cur_mode.recent_rankings.add(contributor, { score = amount }, true)
				bounties2.contributors[contributor] = nil
			end
		end
	end
end)

--- Clean ups
--- @return nil
local function cleanup_contributed_bounty()
	for bname, bounty_data in pairs(contributed_bounties) do
		for contributor, score in pairs(bounty_data.contributors) do
			if score <= 0 then
				bounty_data.contributors[contributor] = nil
			end
		end

		-- are there any contributors left?
		if next(bounty_data.contributors) == nil then
			contributed_bounties[bname] = nil
		end
	end
end

--- Get a list of contributors for some player if any
--- @param name string Player name
--- @return string | nil A human readable comma separated list of bounties
local function get_contributors_str(name)
	local bounty = contributed_bounties[name]
	if not bounty then
		return nil
	end
	--- @type string[]
	local contributors = {}
	for contributor, _ in pairs(contributed_bounties[name]) do
		table.insert(contributors, contributor)
	end
	if #contributors == 1 then
		return contributors[1]
	end
	if #contributors == 2 then
		return S("@1 and @2", contributors[1], contributors[2])
	end
	--- @type string
	local return_string = ""
	for i = 1, #contributors do
		local current = contributors[i]
		if i == #contributors then
			return_string = return_string .. S(" and @1", current)
		else
			return_string = return_string .. S(", @1", current)
			-- ^ We need to wrap it in S() cuz in
			-- some languages, they use different comma
			-- characters. One example is Persian.
			-- -- Farooq <fkz on riseup dot net>
		end
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

	--- @type Reward | nil
	local rewards = nil
	if got_game_bounty then
		rewards = game_bounties[pteam].rewards
	end

	if rewards then
		local reward_str = get_reward_str(rewards)
		local messages = {
			S("[Bounty] @1 defeated @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 outplayed @2 and collected @3", killer, player, reward_str),
			S("[Bounty] @1 brought down @2 and won @3", killer, player, reward_str),
			S("[Bounty] @1 claimed victory over @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 bested @2 and secured @3", killer, player, reward_str),
			S("[Bounty] @1 overcame @2 and received @3", killer, player, reward_str),
			S("[Bounty] @1 conquered @2 and gained @3", killer, player, reward_str),
			S("[Bounty] @1 surpassed @2 and picked up @3", killer, player, reward_str),
			S("[Bounty] @1 outsmarted @2 and claimed @3", killer, player, reward_str),
			S("[Bounty] @1 defeated @2 to earn @3", killer, player, reward_str),
			S("[Bounty] @1 took the win against @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 triumphed over @2 and collected @3", killer, player, reward_str),
			S("[Bounty] @1 finished the challenge against @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 prevailed against @2 and secured @3", killer, player, reward_str),
			S("[Bounty] @1 won the duel with @2 and claimed @3", killer, player, reward_str),
			S("[Bounty] @1 came out on top versus @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 beat @2 fair and square and got @3", killer, player, reward_str),
			S("[Bounty] @1 proved stronger than @2 and gained @3", killer, player, reward_str),
			S("[Bounty] @1 showed skill against @2 and received @3", killer, player, reward_str),
			S("[Bounty] @1 completed the bounty on @2 and claimed @3", killer, player, reward_str),
			S("[Bounty] @1 outmatched @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 bested @2 to collect @3", killer, player, reward_str),
			S("[Bounty] @1 claimed the bounty on @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 overcame the odds versus @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 stood victorious over @2 and secured @3", killer, player, reward_str),
			S("[Bounty] @1 succeeded against @2 and received @3", killer, player, reward_str),
			S("[Bounty] @1 mastered the fight with @2 and claimed @3", killer, player, reward_str),
			S("[Bounty] @1 handled @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 completed the task against @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 won the encounter with @2 and gained @3", killer, player, reward_str),
			S("[Bounty] @1 outplayed @2 to secure @3", killer, player, reward_str),
			S("[Bounty] @1 finished @2 and collected @3", killer, player, reward_str),
			S("[Bounty] @1 achieved victory over @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 claimed success against @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 prevailed in the match with @2 and secured @3", killer, player, reward_str),
			S("[Bounty] @1 took control against @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 dominated the duel with @2 and claimed @3", killer, player, reward_str),
			S("[Bounty] @1 bested the challenge of @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 emerged victorious over @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 proved victorious against @2 and received @3", killer, player, reward_str),
			S("[Bounty] @1 won against @2 and picked up @3", killer, player, reward_str),
			S("[Bounty] @1 earned the bounty from @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 surpassed @2 to earn @3", killer, player, reward_str),
			S("[Bounty] @1 claimed a win over @2 and secured @3", killer, player, reward_str),
			S("[Bounty] @1 succeeded in the duel with @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 finished the encounter with @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 completed the victory over @2 and claimed @3", killer, player, reward_str),
			S("[Bounty] @1 bested @2 and walked away with @3", killer, player, reward_str),
			S("[Bounty] @1 won the bounty after defeating @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 took the bounty from @2 and secured @3", killer, player, reward_str),
			S("[Bounty] @1 came out victorious over @2 and gained @3", killer, player, reward_str),
			S("[Bounty] @1 claimed the reward after beating @2: @3", killer, player, reward_str),
			S("[Bounty] @1 finished strong against @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 proved their skill versus @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 bested the opponent @2 and claimed @3", killer, player, reward_str),
			S("[Bounty] @1 won fair play against @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 secured victory over @2 and received @3", killer, player, reward_str),
			S("[Bounty] @1 completed the bounty challenge on @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 triumphed in style over @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 achieved success against @2 and claimed @3", killer, player, reward_str),
			S("[Bounty] @1 stood tall against @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 won the challenge with @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 earned @3 by defeating @2", killer, player, reward_str),
			S("[Bounty] @1 claimed @3 after overcoming @2", killer, player, reward_str),
			S("[Bounty] @1 secured @3 by beating @2", killer, player, reward_str),
			S("[Bounty] @1 gained @3 for besting @2", killer, player, reward_str),
			S("[Bounty] @1 collected @3 after winning against @2", killer, player, reward_str),
			S("[Bounty] @1 received @3 for defeating @2", killer, player, reward_str),
			S("[Bounty] @1 picked up @3 after outplaying @2", killer, player, reward_str),
			S("[Bounty] @1 earned the reward @3 by beating @2", killer, player, reward_str),
			S("[Bounty] @1 won big against @2 and claimed @3", killer, player, reward_str),
			S("[Bounty] @1 finished the job against @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 claimed a clean win over @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 proved victorious in the fight with @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 handled the duel with @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 emerged on top against @2 and claimed @3", killer, player, reward_str),
			S("[Bounty] @1 took the win versus @2 and received @3", killer, player, reward_str),
			S("[Bounty] @1 earned @3 after a victory over @2", killer, player, reward_str),
			S("[Bounty] @1 showed great skill against @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 finished victorious against @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 bested @2 in battle and claimed @3", killer, player, reward_str),
			S("[Bounty] @1 won the match versus @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 claimed the prize after beating @2: @3", killer, player, reward_str),
			S("[Bounty] @1 secured the bounty on @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 triumphed over @2 to gain @3", killer, player, reward_str),
			S("[Bounty] @1 defeated @2 and walked away with @3", killer, player, reward_str),
			S("[Bounty] @1 earned their bounty by beating @2: @3", killer, player, reward_str),
			S("[Bounty] @1 claimed a victory over @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 proved the winner against @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 secured a win against @2 and claimed @3", killer, player, reward_str),
			S("[Bounty] @1 finished the duel against @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 won the showdown with @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 achieved a win over @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 bested @2 in a fair fight and claimed @3", killer, player, reward_str),
			S("[Bounty] @1 claimed success after defeating @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 earned @3 after claiming victory over @2", killer, player, reward_str),
			S("[Bounty] @1 stood victorious in the duel with @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 proved their strength against @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 completed the bounty by beating @2 and claimed @3", killer, player, reward_str),
			S("[Bounty] @1 won the bounty challenge against @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 claimed the bounty reward @3 after defeating @2", killer, player, reward_str),
			S("[Bounty] @1 finished the match against @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 gained the upper hand over @2 and claimed @3", killer, player, reward_str),
			S("[Bounty] @1 won the fight versus @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 claimed victory and @3 after beating @2", killer, player, reward_str),
			S("[Bounty] @1 earned @3 for winning against @2", killer, player, reward_str),
			S("[Bounty] @1 proved the better player than @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 secured the win over @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 claimed a solid victory over @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 bested @2 to walk away with @3", killer, player, reward_str),
			S("[Bounty] @1 completed the bounty successfully against @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 won the encounter versus @2 and claimed @3", killer, player, reward_str),
			S("[Bounty] @1 earned the prize @3 by defeating @2", killer, player, reward_str),
			S("[Bounty] @1 showed great play against @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 came out ahead of @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 claimed the reward @3 after winning against @2", killer, player, reward_str),
			S("[Bounty] @1 secured success versus @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 triumphed in the duel with @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 bested the match against @2 and claimed @3", killer, player, reward_str),
			S("[Bounty] @1 achieved a clean win over @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 earned @3 after outmatching @2", killer, player, reward_str),
			S("[Bounty] @1 claimed the win and @3 after beating @2", killer, player, reward_str),
			S("[Bounty] @1 secured the bounty by defeating @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 completed the fight against @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 won the challenge cleanly against @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 gained victory over @2 and claimed @3", killer, player, reward_str),
			S("[Bounty] @1 bested @2 with skill and earned @3", killer, player, reward_str),
			S("[Bounty] @1 emerged as the winner against @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 proved their victory over @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 claimed a smooth win over @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 won the bounty by beating @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 earned the bounty after a win against @2: @3", killer, player, reward_str),
			S("[Bounty] @1 completed the win over @2 and claimed @3", killer, player, reward_str),
			S("[Bounty] @1 secured the prize by defeating @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 bested the opponent @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 claimed the bounty successfully against @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 finished ahead of @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 earned @3 thanks to a victory over @2", killer, player, reward_str),
			S("[Bounty] @1 stood victorious after defeating @2 and claimed @3", killer, player, reward_str),
			S("[Bounty] @1 won the bounty prize against @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 claimed a well‑earned win over @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 completed the bounty task against @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 bested @2 in the encounter and claimed @3", killer, player, reward_str),
			S("[Bounty] @1 earned the reward for beating @2: @3", killer, player, reward_str),
			S("[Bounty] @1 secured a clean victory over @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 won the duel cleanly against @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 proved successful against @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 claimed the bounty after a fair win over @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 achieved victory and earned @3 against @2", killer, player, reward_str),
			S("[Bounty] @1 finished victorious and claimed @3 after beating @2", killer, player, reward_str),
			S("[Bounty] @1 secured the win and @3 against @2", killer, player, reward_str),
			S("[Bounty] @1 earned @3 by claiming victory over @2", killer, player, reward_str),
			S("[Bounty] @1 bested the challenge versus @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 won the fight cleanly against @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 claimed the bounty reward by defeating @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 completed a victory over @2 and claimed @3", killer, player, reward_str),
			S("[Bounty] @1 earned the win and @3 against @2", killer, player, reward_str),
			S("[Bounty] @1 secured success after beating @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 proved their win over @2 and claimed @3", killer, player, reward_str),
			S("[Bounty] @1 finished the bounty with a win over @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 won the encounter cleanly against @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 earned the bounty prize after defeating @2: @3", killer, player, reward_str),
			S("[Bounty] @1 claimed victory cleanly over @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 bested @2 and earned the reward @3", killer, player, reward_str),
			S("[Bounty] @1 secured a bounty win against @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 earned the reward after a clean win over @2", killer, player, reward_str),
			S("[Bounty] @1 completed the bounty with success against @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 won fairly against @2 and claimed @3", killer, player, reward_str),
			S("[Bounty] @1 claimed a fair victory over @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 proved victorious fairly against @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 earned @3 after a fair win against @2", killer, player, reward_str),
			S("[Bounty] @1 secured the bounty fairly by beating @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 bested @2 in a clean match and earned @3", killer, player, reward_str),
			S("[Bounty] @1 claimed a friendly win over @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 earned the bounty in a fair fight against @2: @3", killer, player, reward_str),
			S("[Bounty] @1 secured a friendly victory over @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 won the bounty fairly against @2 and claimed @3", killer, player, reward_str),
			S("[Bounty] @1 completed a fair win over @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 earned @3 thanks to a fair victory over @2", killer, player, reward_str),
			S("[Bounty] @1 claimed the bounty after a clean match with @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 won the encounter in good play against @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 bested @2 with good play and earned @3", killer, player, reward_str),
			S("[Bounty] @1 secured the win with skill against @2 and claimed @3", killer, player, reward_str),
			S("[Bounty] @1 earned the bounty with skillful play against @2: @3", killer, player, reward_str),
			S("[Bounty] @1 claimed a skillful win over @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 won thanks to skill against @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 bested the game against @2 and claimed @3", killer, player, reward_str),
			S("[Bounty] @1 completed a skillful victory over @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 secured a skillful win against @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 earned @3 after a skillful victory over @2", killer, player, reward_str),
			S("[Bounty] @1 claimed the bounty through skill against @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 won the match with skill against @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 bested @2 with smart play and earned @3", killer, player, reward_str),
			S("[Bounty] @1 claimed a smart win over @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 earned the bounty after smart play against @2: @3", killer, player, reward_str),
			S("[Bounty] @1 secured a smart victory over @2 and earned @3", killer, player, reward_str),
			S("[Bounty] @1 won by smart play against @2 and claimed @3", killer, player, reward_str),
			S("[Bounty] @1 completed a smart win over @2 and got @3", killer, player, reward_str),
			S("[Bounty] @1 earned @3 thanks to smart play against @2", killer, player, reward_str),
			S("[Bounty] @1 claimed the bounty after outsmarting @2 and earned @3", killer, player, reward_str)
		}
		--- @type string
		local bounty_kill_text = messages[math.random(1, #messages)]
		core.chat_send_all(core.colorize(CHAT_COLOR, bounty_kill_text))
	end

	game_bounties[pteam] = nil

	if contributed_bounties[player] then
		local score = calc_total_contributed_bounty(player)
		if rewards == nil then
			rewards = { bounty_kills = 0, score = 0 }
		end
		local contributors = contributed_bounties[player].contributors
		rewards.score = rewards.score + score
		rewards.bounty_kills = #contributors + rewards.bounty_kills
		local player_bounty_text = S(
			"[Player bounty] @1 killed @2 and got @3 from @4.",
			killer,
			player,
			score,
			get_contributors_str(player)
		)
		core.chat_send_all(core.colorize(CHAT_COLOR, player_bounty_text))
		ctf_modebase.announce(player_bounty_text)
		contributed_bounties[player] = nil
	end

	if rewards and rewards.bounty_kills == 0 then
		rewards.bounty_kills = nil
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
					core.colorize("cyan", calc_total_contributed_bounty(pname))
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
		return true, S("Successfully placed a bounty of @1 on @2!", amount, player)
	end,
})

local last_bounty_use = {}

ctf_core.register_chatcommand_alias(
	"bounty",
	"bo",
	{ -- /b is already registered in babelfish mod in JMA
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
			local now = core.get_gametime()
			if last_bounty_use[name] and now - last_bounty_use[name] < 5 then
				local remaining = 5 - (now - last_bounty_use[name])
				return false,
					S(
						"You must wait @1 seconds before using this command again.",
						remaining
					)
			end
			last_bounty_use[name] = now

			local bname, amount = string.match(params, "([^%s]*) ([^%s]*)")
			amount = tonumber(amount)
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
				if
					not contributed_bounties[bname]
					or not contributed_bounties[bname].contributors[name]
				then
					return false, S("You don't have any bounty on this player to revoke")
				end

				local my_contribution = contributed_bounties[bname].contributors[name]
				local revoke_amount = math.min(math.abs(amount), my_contribution)

				contributed_bounties[bname].contributors[name] = my_contribution
					- revoke_amount
				cleanup_contributed_bounty()
				current_mode.recent_rankings.add(name, { score = revoke_amount }, true)
				return true, S("@1 points returned to you.", revoke_amount)
			end

			if amount < PLAYER_BOUNTY_MIN then
				return false, S("Your bounty needs to be of at least 5 points")
			end
			if amount > PLAYER_BOUNTY_CAP then
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
				contributed_bounties[bname] = { contributors = contributors }
			else
				--- @type ContributedBounty
				local c_bounty = contributed_bounties[bname]
				if not c_bounty.contributors[name] then
					c_bounty.contributors[name] = amount
				else
					c_bounty.contributors[name] = c_bounty.contributors[name] + amount
				end
			end
			local total = calc_total_contributed_bounty(bname)
			local msg = S(
				"@1 placed @2 bounty on @3! Now there is a total of @4 for @5",
				name,
				amount,
				bname,
				total,
				bname
			)
			core.chat_send_all(core.colorize(CHAT_COLOR, msg))
			return true, S("Bounty placed!")
		end,
	}
)

function ctf_modebase.bounties.get_unclaimed_player_bounties()
	return contributed_bounties
end

function ctf_modebase.bounties.clear_player_bounties()
	contributed_bounties = {}
end
