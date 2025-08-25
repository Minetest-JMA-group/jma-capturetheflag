ctf_jma_achieves = {
		registered_achievements = {},
		registered_achievement_list = {},
		registered_on_grant_achievements = {},
}

local S = minetest.get_translator("ctf_jma_achieves")

local modstorage = core.get_mod_storage()
local storage_prefix = "achievements_"
local player_achievements_cache = {}
local player_str_cache = {}

-- probably inefficient but more compact than core.serialize
local function parse_csv(str)
	if str == "" then return {} end
	if str:sub(-1) ~= "," then str = str.."," end
	local out = {}
	local last = ""
	local i = 1
	while i <= #str do
		local l = str:sub(i, i)
		if l == "," then
			out[last] = true
			last = ""
		else
			last = last..l
		end
		i = i + 1
	end
	return out
end
local function serialize_achvs(achvs)
	local out = ""
	for a, _ in pairs(achvs) do
		out = out..a
		out = out..","
	end
	return out
end
local function load_achievementstr(name)
	return modstorage:get_string(storage_prefix..name)
end

core.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	local a = load_achievementstr(name)
	player_str_cache[name] = a
	player_achievements_cache[name] = parse_csv(a)
end)
core.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	player_achievements_cache[name] = nil
	player_str_cache[name] = nil
end)

function ctf_jma_achieves.get_achievement_unlocked(name, id)
	return player_achievements_cache[name][id] == true
end

function ctf_jma_achieves.register_achievement(id, def)
	assert(id, "Please provide a name when registering an achievement!")
	assert(not string.find(id, ","), "Commas are not allowed in achievement names!")
	def = def or {}
	def.name = def.name or id
	def.description = def.description or ""
	def.type = def.type or "bronze"
	ctf_jma_achieves.registered_achievements[id] = def
	table.insert(ctf_jma_achieves.registered_achievement_list, id)
end

function ctf_jma_achieves.register_on_grant_achievement(function(f)
	assert(f, "Please provide a function!")
	table.insert(ctf_jma_achieves.registered_on_grant_achievements, f)
end)

function ctf_jma_achieves.grant_achievement(name, id)
	if type(id) == "string" then
		local def = assert(ctf_jma_achieves.registered_achievements[id], "Tried to grant an unknown achievement!")
		
		if ctf_jma_achieves.get_achievement_unlocked(name, id) then
			core.log("warning", "[ctf_jma_achieves] Tried to re-grant achievement "..id.." to player "..name)
			return
		end
		
		core.chat_send_player(name, core.colorize("orange", S("[!] You unlocked an achievement@2 @1"), {"!", "!!", "!!!"}[def.type]}, def.name))
		player_achievements_cache[name][id] = true
		local na = player_str_cache[name]..id..","
		player_str_cache[name] = na
		modstorage:set_string(storage_prefix..name, na)
		
		for _, f in ipairs(ctf_jma_achieves.registered_on_grant_achievements) do
			f(name, id)
		end
		
		core.log("action", "[ctf_jma_achieves] Achievement "..id.." granted to player "..name)
	else
		error("Unknown type given to ctf_jma_achieves.grant_achievement!")
	end
end

function ctf_jma_achieves.count_trophies(name)
	local out = {bronze = 0, silver = 0, gold = 0}
	for a, _ in pairs(player_achievements_cache[name]) do
		local def = ctf_jma_achieves.registered_achievements[a]
		out[def.type] = (out[def.type] or 0) + 1
	end
	return out
end
local total_trophies = {bronze = 0, silver = 0, gold = 0}
core.register_on_mods_loaded(function()
	
	-- Count total achievement trophies for the achievements page
	for _, def in pairs(ctf_jma_achieves.registered_achievements) do
		total_trophies[def.type] = (total_trophies[def.type] or 0) + 1
	end
end)

dofile(minetest.get_modpath("ctf_jma_achieves") .. "/achievements.lua")

sfinv.register_page("ctf_jma_achieves:list", {
	title = "Achieves", -- This is called "Achieves" because "Achievements" is too long
	get = function(self, player, context)
		local name = player:get_player_name()
		local achievementform = {}
		
		for i, aname in ipairs(ctf_jma_achieves.registered_achievement_list) do
			local adef = ctf_jma_achieves.registered_achievements[aname]
			local j = i - 1
			
			local bgcolor = "#aaaaaa44"
			-- Make the individual achievements more visible by alternating colors
			if j % 2 == 1 then
				bgcolor = "#77777744"
			end
			
			-- A number for to simplify the code
			local has_icon = adef.icon and 1.25 or 0.125
			local has_ach = ctf_jma_achieves.get_achievement_unlocked(name, aname)
			
			table.insert(achievementform, string.format("box[0,%s;9.345,1.25;%s]", j*1.25, bgcolor))
			table.insert(achievementform, string.format("hypertext[%s,%s;8,0.5;acv_title_text_%s;%s]", has_icon, j*1.25 + 0.25, i, core.formspec_escape("<b>"..adef.name.."</b>")))
			table.insert(achievementform, string.format("hypertext[%s,%s;8,0.5;acv_desc_text_%s;%s]", has_icon, j*1.25 + 0.625, i, core.formspec_escape(adef.description)))
			table.insert(achievementform, string.format("image[8.72,%s;0.5,0.5;ctf_jma_achieves_trophy_%s.png]", j*1.25 + 0.625, adef.type))
			if adef.icon then
				table.insert(achievementform, string.format("image[0.125,%s;1,1;%s]", j*1.25 + 0.125, adef.icon))
			end
			if not has_ach then
				table.insert(achievementform, string.format("box[0,%s;9.345,1.25;#00000055]", j*1.25))
			end
		end
		
		local plr_trophies = ctf_jma_achieves.count_trophies(name)
		local formspec = {
			"box[0.25,0.25;9.345,10.1;#11111155]",
			"scroll_container[0.25,0.25;9.345,10.1;achievlist;vertical]",
			"scrollbaroptions[]",
			table.concat(achievementform, ""),
			"scroll_container_end[]",
			"scrollbar[9.72,0.25;0.5,10.1;vertical;achievlist;0]",
			"image[0.25,10.6;0.5,0.5;ctf_jma_achieves_trophy_bronze.png]",
			"label[0.875,10.85;"..core.formspec_escape(plr_trophies.bronze..core.colorize("#999999", "/"..total_trophies.bronze)).."]",
			"image[1.5,10.6;0.5,0.5;ctf_jma_achieves_trophy_silver.png]",
			"label[2.125,10.85;"..core.formspec_escape(plr_trophies.silver..core.colorize("#999999", "/"..total_trophies.silver)).."]",
			"image[2.75,10.6;0.5,0.5;ctf_jma_achieves_trophy_gold.png]",
			"label[3.375,10.85;"..core.formspec_escape(plr_trophies.gold..core.colorize("#999999", "/"..total_trophies.gold)).."]",
		}
		return sfinv.make_formspec_v7(player, context,
				table.concat(formspec, ""), false)
	end
})