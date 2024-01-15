-- SPDX-License-Identifier: LGPL-2.1-only
-- Copyright (c) 2023 Marko Petrović

local cooldown = 60

local last_time = {}
minetest.register_chatcommand("lp", {
	description = "Check what's the longest palindrome present in your string",
	params = "<word/sentence>",
	privs = { shout=true },
	func = function(name, param)
		if last_time[name] and (os.time() - last_time[name]) < cooldown then
			return false, "Don't spam with palindromes."
		end
		if param == "" then
			return false, "You have to enter a word in which palindrome will be searched for."
		end
		minetest.chat_send_all(name.." has found the palindrome: "..algorithms.lcs(param, utf8_simple.reverse(param)))
		last_time[name] = os.time()
	end,
})
