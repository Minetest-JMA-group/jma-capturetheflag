-- SPDX-License-Identifier: GPL-3.0-or-later
-- Copyright (c) 2023 Marko Petrović
assert(algorithms.load_library())
local registered_on_chat_message = {}

filter_caps.register_on_chat_message = function(func)
	table.insert(registered_on_chat_message, func)
end

minetest.register_on_chat_message(function(name, message)
	if #registered_on_chat_message == 0 then
		return false
	end

	message = filter_caps.parse(name, message)
	for _, func in ipairs(registered_on_chat_message) do
		if func(name, message) then
			return true
		end
	end
end)
