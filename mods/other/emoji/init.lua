-- Modified by fancyfinn9 and Nanowolf4
local cooldown = ctf_core.init_cooldowns()

local emojis = {
	["B-)"] = "2_emoji",
	[":D"] = "5_emoji",
	[":_("] = "7_emoji",
	[">:-["] = "8_emoji",
	["]:-)"] = "9_emoji",
	[":/"] = "10_emoji",
	[";)"] = "11_emoji",
	[":("] = "12_emoji",
	[";P"] = "13_emoji",
	[":'-D"] = "14_emoji",
	["~:["] = "15_emoji",
	["o_O"] = "16_emoji",
	["xD"] = "17_emoji",
	["xP"] = "18_emoji",
	[":P"] = "20_emoji",
	[":O"] = "21_emoji",
	["jma"] = "jma_emoji",
	["rabbit"] = "rabbit_emoji",
	["sus"] = "sus_emoji",
	["troll"] = "troll_emoji",
	["rick"] = "rick_emoji",
}

local hidden_emojis = {
	["rick"] = true,
}

local function get_emoji_formspec()
	local bg = "bg_emoji.png"
	local cols = 5
	local btn_size = 2
	local spacing = 0.1
	local start_y = 0
	local form = "formspec_version[7] size[10.4,10.4] bgcolor[#333444cc; false]"
	local i = 0

	-- Pass emoji as texture name to avoid escaping issues with special characters in the formspec
	for n, texture in pairs(emojis) do
		if hidden_emojis[n] then
			goto continue
		end

		local x = (i % cols) * (btn_size + spacing)
		local y = start_y + math.floor(i / cols) * (btn_size + spacing)
		form = form .. string.format(
			"image_button_exit[%.2f,%.2f;%.2f,%.2f;%s^%s.png;%s;]",
			x,
			y,
			btn_size,
			btn_size,
			bg,
			texture,
			texture
		)
		i = i + 1

		::continue::
	end

	return form
end

core.register_chatcommand("e", {
	params = "",
	description = "Emoji",
	privs = {shout = true},
	func = function(name, param)
		core.show_formspec(name, "emoji_form", get_emoji_formspec())
	end,
})

local function spawn_emoji_particles(pos, texture, anim)
	local def = {
		amount = 1,
		time = 0.01,
		minpos = { x = pos.x, y = pos.y + 2, z = pos.z },
		maxpos = { x = pos.x, y = pos.y + 2, z = pos.z },
		minvel = { x = 0, y = 0.15, z = 0 },
		maxvel = { x = 0, y = 0.15, z = 0 },
		minacc = { x = 0, y = 0, z = 0 },
		maxacc = { x = 0, y = 0, z = 0 },
		minexptime = 2.5,
		maxexptime = 2.5,
		minsize = 9,
		maxsize = 9,
		collisiondetection = false,
		texture = texture,
	}
	if anim then
		def.animation  = {
			type = "vertical_frames",
			aspect_w = 347,
			aspect_h = 350,
			length = 2.0,
		}
	end
	core.add_particlespawner(def)
end

local function play_sound(pos)
	core.sound_play(
		"emoji_sound",
		{ pos = pos, max_hear_distance = 10, gain = 1.0 }
	)
end

core.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "emoji_form" then
		if cooldown:get(player) then
			return true
		end
		cooldown:set(player, 1)

		local pos = player:get_pos()
		local name = player:get_player_name()
		for _, texture in pairs(emojis) do
			if fields[texture] then
				play_sound(pos)
				spawn_emoji_particles(pos, texture .. ".png")

				core.close_formspec(name, "emoji_form")
				return true
			end
		end

		core.close_formspec(name, "emoji_form")
		return true
	end
end)

-- Find the emoji in the first or last word of the message, and spawn the particles if found
core.register_on_chat_message(function(name, message)
	local first_word = message:match("^(%S+)")
	local last_word = message:match("(%S+)$")
	local texture = emojis[first_word] or emojis[last_word]

	if texture then
		local player = core.get_player_by_name(name)
		local pos = player:get_pos()

		play_sound(pos)
		spawn_emoji_particles(pos, texture .. ".png", true)
	end
end)
