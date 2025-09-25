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
ctf_jma_achieves.achievement_complete_percent_cache = {}

local players_with_achvmnt_prefix = "plrs_with_acv_"
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

core.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	local a = modstorage:get_string(storage_prefix..name)
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
		
		-- Recalculate achievement percents
		for id, _ in pairs(ctf_jma_achieves.registered_achievements) do
			local c = ctf_jma_achieves.achievement_complete_percent_cache[id].completed
			ctf_jma_achieves.achievement_complete_percent_cache[id] = {completed = c, percent = c / totalplayers}
		end
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
	table.insert(ctf_jma_achieves.registered_achievement_list, id)
end

function ctf_jma_achieves.register_on_grant_achievement(f)
	assert(f, "Please provide a function!")
	table.insert(ctf_jma_achieves.registered_on_grant_achievements, f)
end

local function create_visual(name, pref, def)
	-- Send chat message
	if def.type == "gold" then
		core.chat_send_player(name, S("@1 unlocked the @2 achievement!!!", name, core.colorize("lightgreen", "["..def.name.."]")))
	else
		core.chat_send_player(name, S("You unlocked an achievement@1 @2", ({bronze = "! ", silver = "!!"})[def.type], core.colorize("lightgreen", "["..def.name.."]")))
	end
	-- Create particles
	local amount = ({bronze = 50, silver = 100, gold = 150})[def.type]
	for _=1,amount do
		core.add_particle({
			expirationtime = math.random() + 1.2,
			pos = pref:get_pos() + vector.new(0, 1.5, 0),
			velocity = vector.random_direction() * 6,
			drag = {x = 3, y = 3, z = 3},
			acceleration = {x = 0, y = -1, z = 0},
			glow = 4,
			texture = {
				name = ("ctf_jma_achieves_trophy_%s.png"):format(def.type),
				alpha_tween = {1, 0.5},
				scale_tween = {5, 0}}
		})
	end
	if def.icon then
		for _=1,amount do
			core.add_particle({
				expirationtime = math.random() + 1.2,
				pos = pref:get_pos() + vector.new(0, 1.5, 0),
				velocity = vector.random_direction() * 6,
				drag = {x = 3, y = 3, z = 3},
				acceleration = {x = 0, y = -1, z = 0},
				glow = 3,
				texture = {
					name = def.icon,
					alpha_tween = {1, 0.5},
					scale_tween = {4, 0}}
			})
		end
	end
	core.add_particle({
		expirationtime = 0.3,
			pos = pref:get_pos() + vector.new(0, 1.5, 0),
			glow = 8,
			texture = {
				blend = "add",
				name = "ctf_jma_achieves_flash.png",
				alpha_tween = {0.6, 0},
				scale = 32}
	})
	
	core.sound_play("ctf_jma_achieves_applause_"..def.type, {
		to_player = name,
		gain = 1.0,
		fade = 2.0,
	})
end

function ctf_jma_achieves.grant_achievement(name, id)
	if type(id) == "string" then
		local def = assert(ctf_jma_achieves.registered_achievements[id], "Tried to grant an unknown achievement!")
		
		if ctf_jma_achieves.get_achievement_unlocked(name, id) then
			core.log("info", "[ctf_jma_achieves] Tried to grant achievement "..id.." to player "..name..", but they already had it")
			return
		end
		
		-- Visual stuff
		local pref = core.get_player_by_name(name)
		if pref then
			create_visual(name, pref, def)
		end
		
		-- Set cache and write to storage
		player_achievements_cache[name][id] = true
		local na = player_str_cache[name]..id..","
		player_str_cache[name] = na
		modstorage:set_string(storage_prefix..name, na)
		
		-- Update completion percentages
		local c = ctf_jma_achieves.achievement_complete_percent_cache[id].completed
		modstorage:set_int(players_with_achvmnt_prefix .. id, c+1)
		ctf_jma_achieves.achievement_complete_percent_cache[id] = {completed = c+1, percent = (c+1) / totalplayers}
		
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
		
		-- Chat message
		core.chat_send_player(name, S("The achievement @1 has been revoked from you.", core.colorize("lightgreen", "["..def.name.."]")))
		
		-- Set cache and write to storage
		player_achievements_cache[name][id] = nil
		modstorage:set_string(storage_prefix..name, string.gsub(player_str_cache[name], id..",", ""))
		
		-- Update completion percentages
		local c = ctf_jma_achieves.achievement_complete_percent_cache[id].completed
		modstorage:set_int(players_with_achvmnt_prefix .. id, c-1)
		ctf_jma_achieves.achievement_complete_percent_cache[id] = {completed = c-1, percent = (c-1) / totalplayers}
		
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
		ctf_jma_achieves.achievement_complete_percent_cache[id] = {completed = c, percent = c / totalplayers}
	end
end)

ctf_core.include_files("achievements.lua")

local function get_pie_image(p)
	if p > 0.9 then
		return "0"
	elseif p > 0.7 then
		return "1"
	elseif p > 0.4 then
		return "2"
	elseif p > 0.2 then
		return "3"
	elseif p > 0.1 then
		return "4"
	elseif p > 0.05 then
		return "5"
	elseif p > 0.025 then
		return "6"
	return "7"
end

local unselected_text = S([[<center><b>JMA CTF Achievements</b>
Achievements are unique challenges that can be completed for rewards.
Each achievement brings rewards when completed - this can be score, league task completion or cosmetics!
You can check your achievements and their information on this page at any time.</center>]])

local filter_and_sort = dofile(minetest.get_modpath("ctf_jma_achieves").."/sort.lua")

sfinv.register_page("ctf_jma_achieves:list", {
	title = "Achieves", -- This is called "Achieves" because "Achievements" is too long
	get = function(self, player, context)
		local name = player:get_player_name()
		local formspec
		local sorted_achieves = filter_and_sort(context.sort or {}, name)
		local pages = math.max(1, #sorted_achieves - 3)
		context.acv_page = math.min(context.acv_page or 1, pages)
		local page = context.acv_page
		
		local acl = {}
		-- Display achievements
		for j=0,3 do
			local i = page+j
			local id = sorted_achieves[i]
			if id then
				local def = ctf_jma_achieves.registered_achievements[id]
				
				local bgcolors = {bronze = {"#a05b5355", "#bf795855"}, silver = {"#a0938e55", "#cfc6b855"}, gold = {"#f4b41b33", "#d2920933"}}
				local bgcolor = bgcolors[def.type][i % 2 + 1]
				
				-- A number to simplify the code
				local has_icon = def.icon and 1.25 or 0.125
				local has_ach = ctf_jma_achieves.get_achievement_unlocked(name, id)
				
				-- Container and bos
				table.insert(acl, ("container[0,%s]"):format(j*1.25))
				table.insert(acl, ("box[0,0;9.345,1.25;%s]"):format(bgcolor))
				
				-- Title and description
				table.insert(acl, ("hypertext[%s,0.25;8,0.5;acv_title_text_%s;<b>%s</b>]"):format(has_icon, i, F(def.name)))
				table.insert(acl, ("hypertext[%s,0.6;8,0.5;acv_desc_text_%s;%s]"):format(has_icon, i, F(def.description)))
				
				-- Icon and trophy
				table.insert(acl, ("image[8.72,0.625;0.5,0.5;ctf_jma_achieves_trophy_%s.png]"):format(def.type))
				if def.icon then
					table.insert(acl, ("image[0.125,0.125;1,1;%s]"):format(def.icon))
				end
				
				if not has_ach then
					table.insert(acl, "box[0,0;9.345,1.25;#00000066]")
				end
				
				-- Button
				table.insert(acl, ("image_button[0,0;9.345,1.25;blank.png;acv_button_%s;;true;false;ctf_jma_achieves_button_pressed.png]"):format(id))
				table.insert(acl, "container_end[]")
			end
		end
		
		local plr_trophies = ctf_jma_achieves.count_trophies(name)
		formspec = {
			"image[0.25,10.6;0.5,0.5;ctf_jma_achieves_trophy_bronze.png]",
			("label[0.875,10.85;%s]"):format(F(plr_trophies.bronze..core.colorize("#999999", "/"..total_trophies.bronze))),
			"image[1.5,10.6;0.5,0.5;ctf_jma_achieves_trophy_silver.png]",
			("label[2.125,10.85;%s]"):format(F(plr_trophies.silver..core.colorize("#999999", "/"..total_trophies.silver))),
			"image[2.75,10.6;0.5,0.5;ctf_jma_achieves_trophy_gold.png]",
			("label[3.375,10.85;%s]"):format(F(plr_trophies.gold..core.colorize("#999999", "/"..total_trophies.gold))),
			"box[0.25,0.25;9.345,5;#11111144]",
			"container[0.25,0.25]",
			table.concat(acl, ""),
			"container_end[]",
			("hypertext[9.72,4.4;0.5,0.4;page_text;<center>%s</center>]"):format(page),
			"label[9.835,4.81;—]",
			("hypertext[9.71,4.9;0.5,0.4;pages_text;<center>%s</center>]"):format(pages)
		}
		
		table.insert(formspec, "box[0.25,5.5;9.97,4.85;#22222255]")
		table.insert(formspec, "container[0.5,5.75]")
		
		-- Add the achievement being viewed
		if context.viewing_acv then
			local adef = ctf_jma_achieves.registered_achievements[context.viewing_acv]
			local percent = ctf_jma_achieves.achievement_complete_percent_cache[context.viewing_acv].percent
			formspec = {
				table.concat(formspec, ""),
				("image[0,0;2,2;%s]"):format(adef.icon),
				("hypertext[2.25,0.125;8,1;acv_title_text;<style size=30><b>%s</b></style>]"):format(F(adef.name)),
				("hypertext[2.25,0.75;8,1;acv_desc_text;<style size=20>%s</style>]"):format(F(adef.description)),
				("image[2.25,1.3;0.5,0.5;ctf_jma_achieves_trophy_%s.png]"):format(adef.type),
				("image[2.875,1.3;0.5,0.5;ctf_jma_achieves_pie_%s.png]"):format(get_pie_image(percent)),
				("hypertext[3.5,1.425;8,1;acv_rarity_text;<style color=#aaaaaa>%.1f%%</style>]"):format(percent * 100),
				("tooltip[2.875,1.3;1.6,0.625;%s]"):format(F(S("@1% of players have completed this achievement", ("%.2f"):format(percent * 100))))}
			if adef.hint then
				table.insert(formspec, "image[0.5,2.25;8.97,0.05;ctf_jma_achieves_bar.png]")
				table.insert(formspec, ("hypertext[0,2.5;9.47,3;acv_hint_text;<center><i><style color=#a0a0a0>\"%s\"</style></i></center>]"):format(F(adef.hint)))
			end
			table.insert(formspec, "button[0,3.6;2,0.75;back;Back]")
			table.insert(formspec, "container_end[]")
		else
			table.insert(formspec, ("hypertext[0,0.75;9.47,3;acv_unselected_text;%s]"):format(F(unselected_text)))
			-- Easter egg :P
			table.insert(formspec, "image_button[9.21,4.1;0.5,0.5;ctf_map_trans.png;secret;;true;false]")
			table.insert(formspec, ("tooltip[secret;%s]"):format(F(S("Made with love (again) by birdlover32767\nJMA 2025"))))
			table.insert(formspec, "container_end[]")
		end
		
		-- Sort dropdown
		table.insert(formspec, ("dropdown[4.345,10.475;3,0.75;sort;Order,Alphabetical,Rarity,Mixed Alphabetical;%s]"):format((context.sort or {}).sort or 1))
		
		-- Flip button
		if context.sort and context.sort.flip then
			table.insert(formspec, "image_button[7.47,10.475;0.75,0.75;ctf_jma_achieves_descending.png;flip_swap;]")
			table.insert(formspec, ("tooltip[flip_swap;%s]"):format(F(S("Listing by descending"))))
		else
			table.insert(formspec, "image_button[7.47,10.475;0.75,0.75;ctf_jma_achieves_ascending.png;flip_swap;]")
			table.insert(formspec, ("tooltip[flip_swap;%s]"):format(F(S("Listing by ascending"))))
		end
		
		-- Reset button
		table.insert(formspec, "image_button[9.47,10.475;0.75,0.75;refresh.png;sort_reset;]")
		table.insert(formspec, ("tooltip[sort_reset;%s]"):format(F(S("Reset your filter and sort"))))
		
		-- Filter button
		if context.sort and context.sort.filter == "unlocked" then
			table.insert(formspec, "image_button[8.47,10.475;0.75,0.75;ctf_jma_achieves_show_unlocked.png;filter_all;]")
			table.insert(formspec, ("tooltip[filter_all;%s]"):format(F(S("Showing only unlocked achievements"))))
		elseif context.sort and context.sort.filter == "locked" then
			table.insert(formspec, "image_button[8.47,10.475;0.75,0.75;ctf_jma_achieves_show_locked.png;filter_unlocked;]")
			table.insert(formspec, ("tooltip[filter_unlocked;%s]"):format(F(S("Showing only locked achievements"))))
		else
			table.insert(formspec, "image_button[8.47,10.475;0.75,0.75;ctf_jma_achieves_show_all.png;filter_locked;]")
			table.insert(formspec, ("tooltip[filter_locked;%s]"):format(F(S("Showing all achievements"))))
		end
		
		-- Navigation buttons
		table.insert(formspec, ("image_button[9.72,0.25;0.5,0.5;start_icon.png%s;page_first;]"):format(F("^[transform3")))
		table.insert(formspec, ("tooltip[page_first;%s]"):format(F(S("Skip to the top"))))
		table.insert(formspec, ("image_button[9.72,0.875;0.5,0.5;prev_icon.png%s;page_prev;]"):format(F("^[transform3")))
		table.insert(formspec, ("tooltip[page_prev;%s]"):format(F(S("Scroll up by 1 achievement"))))
		table.insert(formspec, ("image_button[9.72,1.5;0.5,0.5;next_icon.png%s;page_next;]"):format(F("^[transform3")))
		table.insert(formspec, ("tooltip[page_next;%s]"):format(F(S("Scroll down by 1 achievement"))))
		table.insert(formspec, ("image_button[9.72,2.125;0.5,0.5;end_icon.png%s;page_last;]"):format(F("^[transform3")))
		table.insert(formspec, ("tooltip[page_last;%s]"):format(F(S("Skip to the end"))))
		
		return sfinv.make_formspec_v7(player, context,
				table.concat(formspec, ""), false)
	end,
	on_player_receive_fields = function(self, player, context, fields)
		context.sort = context.sort or {}
		local name = player:get_player_name()
		for field, value in pairs(fields) do
			if field:sub(1, 11) == "acv_button_" then
				local achievement = field:sub(12, -1)
				context.viewing_acv = achievement
				return true, true
			end
		end
		if fields.back then
			context.viewing_acv = nil
			return true, true
		elseif fields.page_first then
			context.acv_page = 1
			return true, true
		elseif fields.page_prev and context.acv_page ~= 1 then
			context.acv_page = (context.acv_page or 1) - 1
			return true, true
		elseif fields.page_next then
			context.acv_page = (context.acv_page or 1) + 1
			return true, true
		elseif fields.page_last then
			context.acv_page = math.huge -- This will be clamped down
			return true, true
		elseif fields.sort_reset then
			context.sort = {}
			return true, true
		elseif fields.filter_all then
			context.sort.filter = "all"
			return true, true
		elseif fields.filter_locked then
			context.sort.filter = "locked"
			return true, true
		elseif fields.filter_unlocked then
			context.sort.filter = "unlocked"
			return true, true
		elseif fields.flip_swap then
			context.sort.flip = not context.sort.flip
			return true, true
		elseif fields.secret and math.random() < 0.01 then
				core.chat_send_player(name, "(>_<) ?")
				core.get_inventory({type="player", name = name}):add_item("main", "default:gold_ingot 1")
		elseif fields.sort then
			local t = {["Order"] = 1, ["Alphabetical"] = 2, ["Rarity"] = 3, ["Mixed Alphabetical"] = 4}
			context.sort.sort = t[fields.sort] or 1
			return true, true
		end
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
	on_player_receive_fields = function(self, player, context, fields)
		local name = player:get_player_name()
		return true
	end
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
		
		ctf_jma_achieves.revoke_achievement(plr, ach)
		return true, S("Achievement revoked.")
	end,
})

-- Note: The inventory does not refresh when an achievement
-- is revoked but I think it's rare enough to not be an issue
ctf_jma_achieves.register_on_grant_achievement(function(name)
    local player = core.get_player_by_name(name)
    if not player then
        return
    end

    local context = sfinv.get_or_create_context(player)
    if context.page ~= "ctf_jma_achieves:list" then
        return
    end

    sfinv.set_player_inventory_formspec(player, context)
end)