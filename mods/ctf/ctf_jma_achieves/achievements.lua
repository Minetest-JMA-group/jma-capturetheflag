-- Note: Try to make the achievement names as short as possible to conserve storage space,
-- especially the common (bronze) ones

-- The order is in the order of registration

local S = minetest.get_translator("ctf_jma_achieves")

ctf_jma_achieves.register_achievement("cja:vct", {
	name = S("Victory!"),
	description = S("Win a match by being on the last team"),
	icon = "ctf_jma_achieves_victory.png",
	hint = S("Congratulations! Now do it again."),
	order = 0,
	type = "bronze"
})
ctf_jma_achieves.register_achievement("cja:sic", {
	name = S("Sharing is Caring"),
	description = S("Put an item in the team chest and get points"),
	icon = "ctf_jma_achieves_chest.png",
	hint = S("Steel tools for all!...wait, they're useless."),
	order = 1,
	type = "bronze"
})
ctf_jma_achieves.register_achievement("cja:tbs", {
	name = S("'Tis But A Scratch"),
	description = S("Heal <mono>10</mono>HP or more at once with a medkit"),
	hint = S("Depending on your condition, it could still be more than a scratch."),
	icon = "ctf_jma_achieves_medkit.png",
	order = 2,
	type = "bronze"
})
ctf_jma_achieves.register_achievement("cja:ff", {
	name = S("Fistfight"),
	description = S("Kill someone by punching with your hand"),
	icon = "ctf_jma_achieves_fist.png",
	hint = S("...You don't have to only use your hand, you know?"),
	order = 3,
	type = "bronze"
})
ctf_jma_achieves.register_achievement("cja:rq", {
	name = S("Ragequit"),
	description = S("Have someone leave just after you killed them"),
	hint = S("Congratulations: you just made a noob leave and never join back! Hooray!"),
	icon = "ctf_jma_achieves_broken_screen.png",
	order = 3.5,
	type = "bronze"
})
ctf_jma_achieves.register_achievement("cja:ew", {
	name = S("Emoji Wizard"),
	description = S("Create a secret emoji icon"),
	hint = S("Wow, what now? You want a hint? Pickle."),
	icon = "ctf_jma_achieves_emoji.png",
	order = 4,
	type = "bronze"
})


ctf_jma_achieves.register_achievement("cja:cap1", {
	name = S("Capturing Newbie"),
	description = S("Capture your first flag"),
	icon = "ctf_jma_achieves_captures_1.png",
	hint = S("Keep going!"),
	order = 5,
	type = "silver"
})
ctf_jma_achieves.register_achievement("cja:btg", {
	name = S("Beyond the Grave"),
	description = S("Kill someone while dead"),
	hint = S("Kamikaze!"),
	icon = "ctf_jma_achieves_grave.png",
	order = 6,
	type = "silver"
})
ctf_jma_achieves.register_achievement("cja:bs", {
	name = S("Bullseye"),
	description = S("Kill by shooting from <mono>100</mono>+ blocks away"),
	hint = S("You haven't <b>really</b> completed this until you find a bull's eye from a chest and shoot it."),
	icon = "ctf_jma_achieves_target.png",
	order = 6.5,
	type = "silver"
})
ctf_jma_achieves.register_achievement("cja:spdrn", {
	name = S("Speedrun"),
	description = S("Capture the last flag in less than <mono>3</mono> minutes"),
	icon = "ctf_jma_achieves_speedrun.png",
	hint = S("The worst is when they drag you into an empty corner and spawnkill you again and again."),
	order = 7,
	type = "silver"
})
ctf_jma_achieves.register_achievement("cja:wntd", {
	name = S("Wanted"),
	description = S("Become bountied"),
	icon = "ctf_jma_achieves_wanted.png",
	hint = S("Killing and killing with no deaths in sight."),
	order = 8,
	type = "silver"
})
ctf_jma_achieves.register_achievement("cja:ndd", {
	name = S("Needed"),
	description = S("Claim a bounty"),
	icon = "ctf_jma_achieves_gold_bars.png",
	hint = S("You could also call this \"Bounty Hunter\" ;)"),
	order = 9,
	type = "silver"
})
ctf_jma_achieves.register_achievement("cja:cap2", {
	name = S("Capturing Enthusiast"),
	description = S("Capture 10 flags"),
	icon = "ctf_jma_achieves_captures_2.png",
	hint = S("Getting into the capturing groove!"),
	order = 10,
	type = "silver"
})
ctf_jma_achieves.register_achievement("cja:pro", {
	name = S("Professional"),
	description = S("Have access to the pro chest in any mode"),
	hint = S("The R is slightly thinner than the other letters. Have a good day."),
	icon = "ctf_jma_achieves_pro.png",
	order = 11,
	type = "silver"
})
ctf_jma_achieves.register_achievement("cja:0_0", {
	name = "(.0_0.)",
	description = "???",
	icon = "ctf_jma_achieves_0_0.png",
	hint = S("Well, about your eyes... they would need to be in the highest league to spot THIS!"),
	order = 12,
	type = "silver"
})

ctf_jma_achieves.register_achievement("cja:cap3", {
	name = S("Capturing Hobbyist"),
	description = S("Capture <mono>100</mono> flags"),
	hint = S("You could make an EPIC CAPTURE compilation with these."),
	icon = "ctf_jma_achieves_captures_3.png",
	order = 13,
	type = "gold"
})
ctf_jma_achieves.register_achievement("cja:atl", {
	name = S("Above The Law"),
	description = S("Get a bounty of <mono>100</mono> score or more"),
	hint = S("Someone abused their shotty today."),
	icon = "ctf_jma_achieves_wanted.png",
	order = 14,
	type = "gold"
})
ctf_jma_achieves.register_achievement("cja:mcapt", {
	name = S("Multicapture"),
	description = S("Capture <mono>2</mono> or more flags at once"),
	icon = "ctf_jma_achieves_multicap.png",
	hint = S("GET 2X AS MANY CAPTURES WITH THIS SIMPLE TRICK PROS DON'T WANT YOU TO KNOW ABOUT!"),
	order = 15,
	type = "gold"
})
ctf_jma_achieves.register_achievement("cja:cap4", {
	name = S("Capturing Connoiseur"),
	description = S("Capture <mono>500</mono> flags"),
	icon = "ctf_jma_achieves_captures_4.png",
	hint = S("I think you're an expert in this field now."),
	order = 16,
	type = "gold"
})
ctf_jma_achieves.register_achievement("cja:slwrn", {
	name = S("Slowrun"),
	description = S("Capture the last flag in more than <mono>45</mono> minutes"),
	icon = "ctf_jma_achieves_speedrun.png",
	hint = S("Gotta go slow."),
	order = 17,
	type = "gold"
})

---[[ ACHIEVEMENT GRANTING LOGIC ]]---
local unlocked = ctf_jma_achieves.get_achievement_unlocked
local grant = ctf_jma_achieves.grant_achievement

-- Code taken from ctf_jma_leagues/tasks.lua
local function get_mode_rankings(mode_name, player_name)
	local mode = ctf_modebase.modes[mode_name]
	return mode.rankings:get(player_name) or {}
end
local function collect(player_name)
	local res = {}
	local total = {kd = 0}

	for mode_name, _ in pairs(ctf_modebase.modes) do
		res[mode_name] = {}

		for k, v in pairs(get_mode_rankings(mode_name, player_name)) do
			res[mode_name][k] = v

			if not total[k] then
				total[k] = 0
			end
			total[k] = total[k] + v
		end
	end

	total.kd = total.kills and total.deaths and (total.kills / total.deaths)
	res.total = total
	return res
end

core.register_on_punchplayer(function(player, hitter, _, _, _, damage)
	local hname = hitter:get_player_name()
	if not hitter:is_player() or hname == player:get_player_name() then return false end
	if player:get_hp() <= 0 then
		-- We know that this hit killed the player
		
		-- Check for the hitter being dead
		if hitter:get_hp() == 0 then
			grant(hname, "cja:btg")
		end
		
		-- Check for the hitter not wielding any items
		if hitter:get_wielded_item():get_name() == "" then
			grant(hname, "cja:ff")
		end
		
		-- Check for seperation being greater than or equal to 100
		if hitter:get_pos():distance(player:get_pos()) >= 100 then
			grant(hname, "cja:bs")
		end
		
		core.after(3, function()
			-- Check for the player being offline
			if hitter:get_player_name() ~= "" and player:get_player_name() == "" then
				grant(hname, "cja:rq")
			end
		end)
	end
end)

local function check_caps(name)
	if unlocked(name, "cja:cap4") then return end
	
	local caps = collect(name).total.flag_captures or 0
	
	if caps >= 1 then grant(name, "cja:cap1") end
	if caps >= 10 then grant(name, "cja:cap2") end
	if caps >= 100 then grant(name, "cja:cap3") end
	if caps >= 500 then grant(name, "cja:cap4") end
end
local function check_pro(name)
	for mode_name, def in pairs(ctf_modebase.modes) do
		if def.player_is_pro(name) then
			grant(name, "cja:pro")
		end
	end
end

core.register_on_joinplayer(function(player)
	core.after(2, function()
		local name = player:get_player_name()
		if name and name ~= "" then
			check_caps(name)
			check_pro(name)
		end
	end)
end)

ctf_api.register_on_match_end(function()
	core.after(2, function()
		for _, plr in pairs(core.get_connected_players()) do
			local name = plr:get_player_name()
			check_pro(name)
		end
	end)
end)

ctf_api.register_on_flag_capture(function(plr, flags)
	core.after(2, function()
		local name = plr:get_player_name()
		if name and name ~= "" then
			check_caps(name)
			if #flags > 1 then
				grant(plr:get_player_name(), "cja:mcapt")
			end
		end
		
		-- HACK: Check the map teams and the captured flags to see which one isn't captured
		local uncaptured_teams = {}
		for _, team in ipairs(ctf_teams.current_team_list) do
			if not ctf_modebase.flag_captured[team] then
				table.insert(uncaptured_teams, team)
			end
		end
		
		if #uncaptured_teams == 1 then -- If this is not the case then it's likely the match has not ended
			local winning_team = uncaptured_teams[1]
			for name, _ in pairs(ctf_teams.online_players[winning_team].players) do
				grant(name, "cja:vct")
			end
			
			-- Check for speedrun as well because we're here
			-- The player to capture the last flag is always on the winning team, so no need to check that
			local time = os.time() - ctf_map.start_time
			if time < 3*60 then
				grant(name, "cja:spdrn")
			elseif time > 45*60 then
				grant(name, "cja:slwrn")
			end
		end
	end)
end)