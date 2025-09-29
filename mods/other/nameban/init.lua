-- SPDX-License-Identifier: LGPL-2.1-only
-- Copyright (c) 2023 Marko Petrović

local storage = minetest.get_mod_storage()
local db = minetest.deserialize(storage:get_string("database")) or {}
local mode = storage:get_int("mode") or 1
local filter_on = storage:get_int("filter") or 1
local LCSthreshold = storage:get_int("LCSthreshold") or 4

local function make_logger(level)
	return function(text, ...)
		minetest.log(level, "[nameban] " .. text:format(...))
	end
end

local ACTION = make_logger("action")
local WARNING = make_logger("warning")

local function save_db()
	storage:set_string("database", minetest.serialize(db))
end

local function findElement(data, string)
	string = string:lower()
	for i, word in ipairs(data) do
		if word:lower() == string then
			return i
		end
	end
	return nil
end
local function patternExists(pattern, text)
	pattern = pattern:lower()
	text = text:lower()
	if #pattern > #text then
		return false
	end
	if #pattern <= LCSthreshold then
		return text:find(pattern) ~= nil
	end
	if pattern == algorithms.lcs(pattern, text) then
		return true
	end
	return false
end

local function parse_players(name)
	db.namelock = db.namelock or {}
	local whitelisted = findElement(db.namelock, name)
	local msg = "Your username is not allowed. Please, change it and relogin."
	local logmsg = "User " .. name .. " has been denied access to the server. [ENFORCING]"
	if mode == 0 then
		msg = nil
		logmsg = "User "
			.. name
			.. " would have been denied access to the server. [PERMISSIVE]"
	end

	if filter_on == 1 and filter and not filter.check_message(name) then
		ACTION(logmsg .. " [filter-detected]")
		return msg
	end
	for _, word in ipairs(db) do
		if patternExists(word, name) then
			ACTION(logmsg)
			return msg
		end
	end
	for _, word in ipairs(db.namelock) do
		if not whitelisted and patternExists(word, name) then
			ACTION(logmsg)
			return msg
		end
	end
end

local function check_online_players()
	for _, player in ipairs(minetest.get_connected_players()) do
		local playername = player:get_player_name()
		local msg = parse_players(playername)
		if msg then
			minetest.kick_player(playername, msg)
		end
	end
end

minetest.register_chatcommand("wordban", {
	description = "Add a word to the blacklist for what's allowed in player names",
	params = "<word>",
	privs = { ban = true },
	func = function(name, params)
		if params:match("[%p%s]") ~= nil then
			return false,
				"You have to enter something that's possible to appear in the filename in the first place."
		end
		if findElement(db, params) then
			return false, "Word " .. params .. " is already blacklisted."
		end
		table.insert(db, params)
		save_db()

		check_online_players()
		if xban then
			xban.report_to_discord(
				"nameban: ***" .. name .. "*** has banned the word: " .. params
			)
		end
		return true, "Word " .. params .. " has been blacklisted."
	end,
})

minetest.register_chatcommand("wordunban", {
	description = "Remove a word from the blacklist for what's allowed in player names",
	params = "<word>",
	privs = { ban = true },
	func = function(name, params)
		local index = findElement(db, params)
		if not index then
			return false, "Word " .. params .. " doesn't exist in the blacklist."
		end
		table.remove(db, index)
		save_db()
		if xban then
			xban.report_to_discord(
				"nameban: ***" .. name .. "*** has UNbanned the word " .. params
			)
		end
		return true, "Word " .. params .. " has been removed from the blacklist."
	end,
})

minetest.register_chatcommand("namelock", {
	description = "Lock a name so that no other player with a similar name may log in",
	params = "<playername>",
	privs = { ban = true },
	func = function(name, params)
		db.namelock = db.namelock or {}
		if params:match("[%p%s]") ~= nil then
			return false,
				"You have to enter something that's possible to appear in the filename in the first place."
		end
		if findElement(db.namelock, params) then
			return false, "Name " .. params .. " is already locked"
		end
		table.insert(db.namelock, params)
		save_db()

		check_online_players()
		if xban then
			xban.report_to_discord(
				"nameban: ***" .. name .. "*** has locked the playername " .. params
			)
		end
		return true, "Name " .. params .. " has been locked."
	end,
})

minetest.register_chatcommand("nameunlock", {
	description = "Unlock a name so that other players can use it as part of their username",
	params = "<playername>",
	privs = { ban = true },
	func = function(name, params)
		db.namelock = db.namelock or {}
		local index = findElement(db.namelock, params)
		if not index then
			return false, "Name " .. params .. " isn't locked."
		end
		table.remove(db.namelock, index)
		save_db()
		if xban then
			xban.report_to_discord(
				"nameban: ***" .. name .. "*** has UNlocked the playername " .. params
			)
		end
		return true, "Name " .. params .. " has been unlocked."
	end,
})

minetest.register_chatcommand("nameban_mode", {
	description = "Set nameban mode of operation",
	params = "<permissive/enforcing/filter/no_filter>",
	privs = { dev = true },
	func = function(name, params)
		if params == "permissive" then
			if mode == 0 then
				return false, "Mode is already permissive"
			end
			mode = 0
			storage:set_int("mode", 0)
			return true, "Nameban mode set to permissive"
		end
		if params == "enforcing" then
			if mode == 1 then
				return false, "Mode is already enforcing"
			end
			mode = 1
			storage:set_int("mode", 1)
			check_online_players()
			return true, "Nameban mode set to enforcing"
		end
		if params == "filter" then
			if filter_on == 1 then
				return false, "Filter is already enabled"
			end
			filter_on = 1
			storage:set_int("filter", 1)
			check_online_players()
			return true, "Filter is enabled"
		end
		if params == "no_filter" then
			if filter_on == 0 then
				return false, "Filter is already disabled"
			end
			filter_on = 0
			storage:set_int("filter", 0)
			return true, "Filter is disabled"
		end
		return false,
			"Error: Your parameter doesn't match any operation.\nParameters: <permissive/enforcing/filter/no_filter>"
	end,
})

minetest.register_chatcommand("nameban_lcs", {
	description = "Set minimal pattern length for LCS to be employed",
	params = "<pattern length>",
	privs = { dev = true },
	func = function(name, params)
		local number = tonumber(params) or 4
		number = math.floor(number)
		if number < 0 then
			return false, "You have to enter a valid non-negative integer"
		end
		LCSthreshold = number
		storage:set_int("LCSthreshold", number)
		return true, "Nameban LCSthreshold set to " .. tostring(number)
	end,
})

minetest.register_on_prejoinplayer(parse_players)
