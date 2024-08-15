-- SPDX-License-Identifier: GPL-3.0-or-later
-- Copyright (c) 2023 Marko Petrović

if not algorithms.load_library() then
	minetest.log("warning", "filter_caps library cannot be loaded, using dummy functions")
	filter_caps = {}

	function filter_caps.parse(_, message)
		return message
	end
end

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
