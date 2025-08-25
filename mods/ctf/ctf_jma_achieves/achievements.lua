-- Note: Try to make the achievement names as short as possible to conserve storage space,
-- especially the common (bronze) ones

-- The order is in the order of registration

ctf_jma_achieves.register_achievement("cja:vct", {
	name = "Victory!",
	description = "Win a match by being on the last team",
	icon = "ctf_jma_achieves_victory.png",
	type = "bronze"
})
ctf_jma_achieves.register_achievement("cja:unt", {
	name = "Unintended",
	description = "Kill a player without using a sword/gun/explosion",
	type = "bronze"
})



ctf_jma_achieves.register_achievement("cja:cap1", {
	name = "Capturing Newbie",
	description = "Capture your first flag",
	icon = "ctf_jma_achieves_captures_1.png",
	type = "silver"
})
ctf_jma_achieves.register_achievement("cja:cap2", {
	name = "Capturing Enthusiast",
	description = "Capture 10 flags",
	icon = "ctf_jma_achieves_captures_2.png",
	type = "silver"
})
ctf_jma_achieves.register_achievement("cja:spdr", {
	name = "Speedrun",
	description = "Capture the last flag and end the match in less than 3 minutes",
	icon = "ctf_jma_achieves_speedrun.png",
	type = "silver"
})


ctf_jma_achieves.register_achievement("cja:cap3", {
	name = "Capturing Hobbyist",
	description = "Capture 100 flags",
	icon = "ctf_jma_achieves_captures_3.png",
	type = "gold"
})
ctf_jma_achieves.register_achievement("cja:mcapt", {
	name = "Multicapture",
	description = "Capture 2 or more flags at once",
	icon = "ctf_jma_achieves_multicap.png",
	type = "gold"
})

ctf_jma_achieves.register_achievement("cja:cap4", {
	name = "Capturing Connoiseur",
	description = "Capture 500 flags",
	icon = "ctf_jma_achieves_captures_4.png",
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


local function check_caps(name)
	if unlocked(name, "cja:cap4") then return end
	
	local caps = collect(name).total.flag_captures
	if caps >= 1 and not unlocked(name, "cja:cap1") then grant(name, "cja:cap1") end
	if caps >= 10 and not unlocked(name, "cja:cap2") then grant(name, "cja:cap2") end
	if caps >= 100 and not unlocked(name, "cja:cap3") then grant(name, "cja:cap3") end
	if caps >= 500 then grant(name, "cja:cap4") end
end

core.register_on_joinplayer(function(player)
	core.after(1, function()
		local name = player:get_player_name()
		if name and name ~= "" then
			check_caps(name)
		end
	end)
end)

ctf_api.register_on_flag_capture(function(plr, flags)
	core.after(1, function()
		local name = plr:get_player_name()
		if name and name ~= "" then
			check_caps(name)
			if #flags > 1 then
				grant(plr:get_player_name(), "cja:mcapt")
			end
		end
	end)
end)