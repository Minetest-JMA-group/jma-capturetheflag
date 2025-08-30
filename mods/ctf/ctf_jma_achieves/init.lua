ctf_jma_achieves = {
		registered_achievements = {},
		registered_achievement_list = {},
		registered_on_grant_achievements = {},
}

local S = minetest.get_translator("ctf_jma_achieves")
local F = core.formspec_escape

local modstorage = core.get_mod_storage()
local storage_prefix = "achievements_"

local player_achievements_cache = {}
local player_str_cache = {}
local achievement_complete_percent_cache = {}

local players_with_achvmnt_prefix = "plrs_with_ach_"
local total_players_storage_name = "totalplayers"
local totalplayers -- Will be initialized later

-- Probably inefficient but more compact than core.serialize
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

local function load_achievementstr(name)
	return modstorage:get_string(storage_prefix..name)
end

local function format_complete_percent(completed)
	return S("@1% of players have completed this achievement", string.format("%.2f", completed/totalplayers * 100))
end

core.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	local a = load_achievementstr(name)
	player_str_cache[name] = a
	player_achievements_cache[name] = parse_csv(a)
	
	-- Try counting player in total_players
	-- The reason why we don't just check if the player is logging in for
	-- the first time is because people have joined before this
	local pmeta = player:get_meta()
	if pmeta:get_int("counted_in_achievement_totalplayers") == 0 then
		pmeta:set_int("counted_in_achievement_totalplayers", 1)
		totalplayers = totalplayers + 1
		modstorage:set_string(total_players_storage_name, totalplayers)
	end
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
	achievement_complete_percent_cache[id] = {}
	table.insert(ctf_jma_achieves.registered_achievement_list, id)
end

function ctf_jma_achieves.register_on_grant_achievement(f)
	assert(f, "Please provide a function!")
	table.insert(ctf_jma_achieves.registered_on_grant_achievements, f)
end

function ctf_jma_achieves.grant_achievement(name, id)
	if type(id) == "string" then
		local def = assert(ctf_jma_achieves.registered_achievements[id], "Tried to grant an unknown achievement!")
		
		if ctf_jma_achieves.get_achievement_unlocked(name, id) then
			core.log("info", "[ctf_jma_achieves] Tried to grant achievement "..id.." to player "..name..", but they already had it")
			return
		end
		
		if def.type == "gold" then
			core.chat_send_player(name, S("@1 unlocked the @2 achievement!!!", name, core.colorize("lightgreen", "["..def.name.."]")))
		else
			core.chat_send_player(name, S("You unlocked an achievement@1 @2", ({bronze = "!  ", silver = "!! ", gold = "!!!"})[def.type], core.colorize("lightgreen", "["..def.name.."]")))
		end
		player_achievements_cache[name][id] = true
		local na = player_str_cache[name]..id..","
		player_str_cache[name] = na
		modstorage:set_string(storage_prefix..name, na)
		
		local c = achievement_complete_percent_cache[id].completed
		modstorage:set_int(players_with_achvmnt_prefix .. id, c+1)
		achievement_complete_percent_cache[id].completed = c+1
		achievement_complete_percent_cache[id].formatted = format_complete_percent(c+1)
		
		for _, f in ipairs(ctf_jma_achieves.registered_on_grant_achievements) do
			f(name, id)
		end
		
		core.log("action", "[ctf_jma_achieves] Achievement "..id.." granted to player "..name)
	else
		error("Unknown type given to ctf_jma_achieves.grant_achievement!")
	end
end
function ctf_jma_achieves.revoke_achievement(name, id)
	if type(id) == "string" then
		local def = assert(ctf_jma_achieves.registered_achievements[id], "Tried to revoke an unknown achievement!")
		
		if not ctf_jma_achieves.get_achievement_unlocked(name, id) then
			core.log("info", "[ctf_jma_achieves] Tried to revoke achievement "..id.." from player "..name..", but they didn't have it")
			return
		end
		
		core.chat_send_player(name, S("The achievement @1 has been revoked from you.", core.colorize("lightgreen", "["..def.name.."]")))
		player_achievements_cache[name][id] = nil
		modstorage:set_string(storage_prefix..name, string.gsub(player_str_cache[name], id..",", ""))
		
		local c = achievement_complete_percent_cache[id].completed
		modstorage:set_int(players_with_achvmnt_prefix .. id, c-1)
		achievement_complete_percent_cache[id].completed = c-1
		achievement_complete_percent_cache[id].formatted = format_complete_percent(c-1)
		
		core.log("action", "[ctf_jma_achieves] Achievement "..id.." revoked from player "..name)
	else
		error("Unknown type given to ctf_jma_achieves.revoke_achievement!")
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
	totalplayers = modstorage:get_int(total_players_storage_name)
	
	for id, def in pairs(ctf_jma_achieves.registered_achievements) do
		-- Count total achievement trophies for the achievements page
		total_trophies[def.type] = (total_trophies[def.type] or 0) + 1
		
		-- Count total players that have completed the achievement
		local c = modstorage:get_int(players_with_achvmnt_prefix .. id)
		achievement_complete_percent_cache[id] = {completed = c, formatted = format_complete_percent(c)}
	end
end)

dofile(minetest.get_modpath("ctf_jma_achieves") .. "/achievements.lua")



-- This Function MIT by Rubenwardy
--- Creates a scrollbaroptions for a scroll_container
--
-- @param visible_l the length of the scroll_container and scrollbar
-- @param total_l length of the scrollable area
-- @param scroll_factor as passed to scroll_container
local function make_scrollbaroptions_for_scroll_container(visible_l, total_l, scroll_factor)

	assert(total_l >= visible_l)

	local thumb_size = (visible_l / total_l) * (total_l - visible_l)

	local max = total_l - visible_l

	return ("scrollbaroptions[min=0;max=%f;thumbsize=%f]"):format(max / scroll_factor, thumb_size / scroll_factor)
end

sfinv.register_page("ctf_jma_achieves:list", {
	title = "Achieves", -- This is called "Achieves" because "Achievements" is too long
	get = function(self, player, context)
		local name = player:get_player_name()
		local acf  = {}
		
		local scroll_len = 0
		for i, aname in ipairs(ctf_jma_achieves.registered_achievement_list) do
			local adef = ctf_jma_achieves.registered_achievements[aname]
			local j = i - 1
			
			local bgcolors = {bronze = {"#bf795855", "#a05b5355"}, silver = {"#cfc6b855", "#a0938e55"}, gold = {"#f4b41b33", "#d2920933"}}
			local bgcolor = bgcolors[adef.type][j % 2 + 1]
			
			-- A number to simplify the code
			local has_icon = adef.icon and 1.25 or 0.125
			local has_ach = ctf_jma_achieves.get_achievement_unlocked(name, aname)
			
			table.insert(acf, string.format("box[0,%s;9.345,1.25;%s]", j*1.25, bgcolor))
			table.insert(acf, string.format("tooltip[0,%s;9.345,1.25;%s]", j*1.25, F(achievement_complete_percent_cache[aname].formatted)))
			table.insert(acf, string.format("hypertext[%s,%s;8,0.5;acv_title_text_%s;<b>%s</b>]", has_icon, j*1.25 + 0.25, i, F(adef.name)))
			table.insert(acf, string.format("hypertext[%s,%s;8,0.5;acv_desc_text_%s;%s]", has_icon, j*1.25 + 0.6, i, F(adef.description)))
			table.insert(acf, string.format("image[8.72,%s;0.5,0.5;ctf_jma_achieves_trophy_%s.png]", j*1.25 + 0.625, adef.type))
			if adef.icon then
				table.insert(acf, string.format("image[0.125,%s;1,1;%s]", j*1.25 + 0.125, adef.icon))
			end
			if not has_ach then
				table.insert(acf, string.format("box[0,%s;9.345,1.25;#00000066]", j*1.25))
			end
			scroll_len = j*1.25
		end
		scroll_len = scroll_len + 1.35
		
		local plr_trophies = ctf_jma_achieves.count_trophies(name)
		local formspec = {
			"box[0.25,0.25;9.345,10.1;#11111155]",
			"scroll_container[0.25,0.25;9.345,10.1;achievlist;vertical]",
			make_scrollbaroptions_for_scroll_container(10.1, math.max(10.1, scroll_len), 0.1),
			table.concat(acf, ""),
			"scroll_container_end[]",
			"scrollbar[9.72,0.25;0.5,10.1;vertical;achievlist;0]",
			"image[0.25,10.6;0.5,0.5;ctf_jma_achieves_trophy_bronze.png]",
			"label[0.875,10.85;"..F(plr_trophies.bronze..core.colorize("#999999", "/"..total_trophies.bronze)).."]",
			"image[1.5,10.6;0.5,0.5;ctf_jma_achieves_trophy_silver.png]",
			"label[2.125,10.85;"..F(plr_trophies.silver..core.colorize("#999999", "/"..total_trophies.silver)).."]",
			"image[2.75,10.6;0.5,0.5;ctf_jma_achieves_trophy_gold.png]",
			"label[3.375,10.85;"..F(plr_trophies.gold..core.colorize("#999999", "/"..total_trophies.gold)).."]",
		}
		return sfinv.make_formspec_v7(player, context,
				table.concat(formspec, ""), false)
	end
})

core.register_chatcommand("grant_achievement", {
	params = "[playername] <achievement>",
	description = "Grant an achievement to a player",
	privs = {ctf_admin = true},
	func = function(name, param)
		local plr, ach = string.match(param, "^(.+) (.+)$")
		if not plr then
			plr = name
			ach = param
		end
		
		if not core.get_player_by_name(plr) then
			if plr == name then
				return false, S("You must be online to grant an achievement to yourself!")
			else
				return false, S("The player must be online!")
			end
		end
		if not ctf_jma_achieves.registered_achievements[ach] then
			return false, S("The achievement is unknown!")
		end
		
		ctf_jma_achieves.grant_achievement(name, ach)
		return true, S("Achievement granted.")
	end,
})
core.register_chatcommand("revoke_achievement", {
	params = "[playername] <achievement>",
	description = "Revoke an achievement from a player",
	privs = {ctf_admin = true},
	func = function(name, param)
		local plr, ach = string.match(param, "^(.+) (.+)$")
		if not plr then
			plr = name
			ach = param
		end
		
		if not core.get_player_by_name(plr) then
			if plr == name then
				return false, S("You must be online to revoke an achievement from yourself!")
			else
				return false, S("The player must be online!")
			end
		end
		if not ctf_jma_achieves.registered_achievements[ach] then
			return false, S("The achievement is unknown!")
		end
		
		ctf_jma_achieves.revoke_achievement(name, ach)
		return true, S("Achievement revoked.")
	end,
})

ctf_jma_achieves.register_on_grant_achievement(function(name)
    local player = minetest.get_player_by_name(name)
    if not player then
        return
    end

    local context = sfinv.get_or_create_context(player)
    if context.page ~= "ctf_jma_achieves:list" then
        return
    end

    sfinv.set_player_inventory_formspec(player, context)
end)