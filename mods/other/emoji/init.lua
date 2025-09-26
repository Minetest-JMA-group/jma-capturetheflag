-- Modified by fancyfinn9

local bg = "bg_emoji.png"

local form = "size[10,7.8] bgcolor[#333444cc; false] image_button_exit[0,0;2,2;"
	.. bg
	.. "^2_emoji.png;2_emoji;] image_button_exit[2,0;2,2;"
	.. bg
	.. "^5_emoji.png;5_emoji;] image_button_exit[4,0;2,2;"
	.. bg
	.. "^7_emoji.png;7_emoji;] image_button_exit[6,0;2,2;"
	.. bg
	.. "^8_emoji.png;8_emoji;] image_button_exit[8,0;2,2;"
	.. bg
	.. "^9_emoji.png;9_emoji;] image_button_exit[0,2;2,2;"
	.. bg
	.. "^10_emoji.png;10_emoji;] image_button_exit[2,2;2,2;"
	.. bg
	.. "^11_emoji.png;11_emoji;] image_button_exit[4,2;2,2;"
	.. bg
	.. "^12_emoji.png;12_emoji;] image_button_exit[6,2;2,2;"
	.. bg
	.. "^13_emoji.png;13_emoji;] image_button_exit[8,2;2,2;"
	.. bg
	.. "^14_emoji.png;14_emoji;] image_button_exit[0,4;2,2;"
	.. bg
	.. "^15_emoji.png;15_emoji;] image_button_exit[2,4;2,2;"
	.. bg
	.. "^16_emoji.png;16_emoji;] image_button_exit[4,4;2,2;"
	.. bg
	.. "^17_emoji.png;17_emoji;] image_button_exit[6,4;2,2;"
	.. bg
	.. "^18_emoji.png;18_emoji;] image_button_exit[8,4;2,2;"
	.. bg
	.. "^20_emoji.png;20_emoji;] image_button_exit[0,6;2,2;"
	.. bg
	.. "^21_emoji.png;21_emoji;] image_button_exit[2,6;2,2;"
	.. bg
	.. "^jma_emoji.png;jma_emoji;] image_button_exit[4,6;2,2;"
	.. bg
	.. "^rabbit_emoji.png;rabbit_emoji;] image_button_exit[6,6;2,2;"
	.. bg
	.. "^sus_emoji.png;sus_emoji;] image_button_exit[8,6;2,2;"
	.. bg
	.. "^troll_emoji.png;troll_emoji;]"

core.register_chatcommand("e", {
	params = "",
	description = "Emoji",
	privs = {},
	func = function(name, param)
		core.show_formspec(name, "emoji_form", form)
	end,
})

local v = {
	{ "2_emoji", "B-)" },
	{ "5_emoji", ":D" },
	{ "7_emoji", ":_(" },
	{ "8_emoji", ">:-[" },
	{ "9_emoji", "]:-)" },
	{ "10_emoji", ":/" },
	{ "11_emoji", ";)" },
	{ "12_emoji", ":(" },
	{ "13_emoji", ";P" },
	{ "14_emoji", ":'-D" },
	{ "15_emoji", "~:[" },
	{ "16_emoji", "o_O" },
	{ "17_emoji", "xD" },
	{ "18_emoji", "xP" },
	{ "20_emoji", ":P" },
	{ "21_emoji", ":O" },
	{ "jma_emoji", "jma" },
	{ "rabbit_emoji", "rabbit" },
	{ "sus_emoji", "sus" },
	{ "troll_emoji", "troll" },
	{ "rick_emoji", "rick" },
}

core.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "emoji_form" then
		local pos = player:get_pos()

		for _, v in pairs(v) do
			if fields[v[1]] then
				core.sound_play(
					"emoji_sound",
					{ pos = pos, max_hear_distance = 12, gain = 1.0 }
				)

				core.add_particlespawner(
					1, --amount
					0.01, --time
					{ x = pos.x, y = pos.y + 2, z = pos.z }, --minpos
					{ x = pos.x, y = pos.y + 2, z = pos.z }, --maxpos
					{ x = 0, y = 0.15, z = 0 }, --minvel
					{ x = 0, y = 0.15, z = 0 }, --maxvel
					{ x = 0, y = 0, z = 0 }, --minacc
					{ x = 0, y = 0, z = 0 }, --maxacc
					2.5, --minexptime
					2.5, --maxexptime
					9, --minsize
					9, --maxsize
					false, --collisiondetection
					v[1] .. ".png"
				)
			end
		end
	end
end)

core.register_on_chat_message(function(name, message, pos)
	local checkingmessage = (name .. " " .. message .. " ")
	for _, v in pairs(v) do
		if string.find(checkingmessage, v[2], 1, true) ~= nil then
			if v[2] == "rick" then
				local player = core.get_player_by_name(name)

				local pos = player:get_pos()

				core.add_particlespawner({
					amount = 1,
					time = 0.01,
					minpos = { x = pos.x, y = pos.y + 2, z = pos.z },
					maxpos = { x = pos.x, y = pos.y + 2, z = pos.z },
					minvel = { x = 0, y = 0.15, z = 0 }, --minvel
					maxvel = { x = 0, y = 0.15, z = 0 }, --maxvel
					minacc = { x = 0, y = 0, z = 0 }, --minacc
					maxacc = { x = 0, y = 0, z = 0 }, --maxacc
					minexptime = 2.5, --minexptime
					maxexptime = 2.5, --maxexptime
					minsize = 9, --minsize
					maxsize = 9, --maxsize
					collisiondetection = false, --collisiondetection
					texture = "rick_emoji.png",
					animation = {
						type = "vertical_frames",

						aspect_w = 347,

						aspect_h = 350,

						length = 2.0,
					},
				})
			else
				local player = core.get_player_by_name(name)

				local pos = player:get_pos()

				core.add_particlespawner(
					1, --amount
					0.01, --time
					{ x = pos.x, y = pos.y + 2, z = pos.z }, --minpos
					{ x = pos.x, y = pos.y + 2, z = pos.z }, --maxpos
					{ x = 0, y = 0.15, z = 0 }, --minvel
					{ x = 0, y = 0.15, z = 0 }, --maxvel
					{ x = 0, y = 0, z = 0 }, --minacc
					{ x = 0, y = 0, z = 0 }, --maxacc
					2.5, --minexptime
					2.5, --maxexptime
					9, --minsize
					9, --maxsize
					false, --collisiondetection
					v[1] .. ".png"
				)
			end
		end
	end
end)
