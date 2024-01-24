-- SPDX-License-Identifier: GPL-3.0-or-later
-- Copyright (c) 2023 Marko Petrović

local storage = minetest.get_mod_storage()
local minLen = storage:get_int("minLen") or 1
filter_caps = {}
filter_caps.parse = function(name, message) return message end

local MP = minetest.get_modpath(minetest.get_current_modname())
local ie = minetest.request_insecure_environment()
local libinit, err = ie.package.loadlib(MP.."/mylibrary.so", "luaopen_mylibrary")
if not libinit and err then
	minetest.log("[filter_caps]: Failed to load shared object file")
	minetest.log("[filter_caps]: "..err)
else
	local mylibrary = libinit()
	filter_caps.parse = function(name, message) return mylibrary.parse(minLen, message) end
end

minetest.register_chatcommand("capsMin", {
	description = "Set the minimum length of the word to be allowed in all caps",
	params = "<capsMin>",
	privs = { dev=true },
	func = function(name, param)
		local number = tonumber(param) or 1
		number = math.floor(number)
		if number < 0 then
			return false, "You have to enter a valid non-negative integer"
		end
		minLen = number
		storage:set_int("minLen", number)
		return true, "Minimum all caps word length set to "..tostring(number)
	end,
})
