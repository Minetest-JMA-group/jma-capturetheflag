ctf_player_info = {}

ctf_gui.init()

local storage = core.get_mod_storage()

local modes = {"classes", "classic", "nade_fight", "chaos", "rush"}
local mode_names = {"Classes", "Classic", "Nade", "Chaos", "Rush"}

local function generate_formspec(tab, skin_texture, target_name, league, is_online, positions, rank_data)
	tab = tonumber(tab) or 1
	positions = positions or {}
	rank_data = rank_data or {}

	local status_text  = is_online and "Online" or "Offline"	
	local status_color = is_online and "#00ff88" or "#ff5555"

	local league_data    = ctf_jma_leagues.leagues[league] or {}
	local league_name    = league_data.display_name or league or "Unranked"
	local league_color   = league_data.color or "#cccccc"
	local league_colored = core.colorize(league_color, league_name)

	local formspec =
		"size[9,7.5]" ..
		"style[label;font_size=+1]" ..
		"style_type[label;textcolor=#e0e0e0]" ..
		"box[0.2,0;8.5,0.8;#121212]" ..
		"hypertext[0.5,0;8.5,2;title;<center><style size=22 color=#FFD700><b>Player Profile</b></style></center>]" ..
		"box[0.2,0.75;8.5,0.05;#FFD700]" ..
		"tabheader[0.2,0;tab;Home,Classes,Classic,Nade,Chaos,Rush;" .. tab .. ";false;false]"

	formspec = formspec ..
		"box[0.2,1;4.6,6.6;#1b1b1b]" ..
		"model[0.6,1.3;4.4,6.4;player;character.b3d;" .. skin_texture .. ";{0,160};;;]"

	formspec = formspec ..
		"box[5,1;3.7,6.6;#1b1b1b]"

	if tab == 1 then
		formspec = formspec ..
			"label[5.2,1.2;Name]" ..
			"label[5.2,1.6;" .. core.colorize("#ffff88", core.formspec_escape(target_name)) .. "]" ..

			"label[5.2,2.2;League]" ..
			"label[5.2,2.6;" .. league_colored .. "]" ..

			"label[5.2,3.2;Status]" ..
			"label[5.2,3.6;" .. core.colorize(status_color, status_text) .. "]" ..

			"box[5.1,4.2;3.5,0.05;#333333]" ..

			"label[5.2,4.5;Positions]" ..
			"label[5.2,4.9;Classes: " .. (positions.classes or "N/A") .. "]" ..
			"label[5.2,5.3;Classic: " .. (positions.classic or "N/A") .. "]" ..
			"label[5.2,5.7;Nade: " .. (positions.nade_fight or "N/A") .. "]"..
			"label[5.2,6.1;Chaos: " .. (positions.chaos or "N/A") .. "]" ..
			"label[5.2,6.5;Rush: " .. (positions.rush or "N/A") .. "]"
	else
		local mod_idx  = tab - 1
		local mod      = modes and modes[mod_idx]
		local mod_name = mode_names and mode_names[mod_idx] or "Stats"

		formspec = formspec ..
			"label[5.2,1.2;" .. core.formspec_escape(mod_name) .. "]" ..
			"box[5.1,1.6;3.5,0.05;#333333]"

		local y = 1.9
		local stats = rank_data[mod] or {}

		for key, value in pairs(stats) do
			if type(value) == "number" then
				formspec = formspec ..
					"label[5.2," .. y .. ";" ..
					core.colorize("#7fdfff", key .. ": ") .. value .. "]"
				y = y + 0.45
			end
		end

		if y == 1.9 then
			formspec = formspec ..
				"label[5.2,2.6;No statistics available]"
		end
	end

	return formspec
end

local function show_player_info(name, target_name)
	local player = core.get_player_by_name(name)
	if not player then
		return
	end

	local target_player = core.get_player_by_name(target_name)
	local is_online = target_player ~= nil

	local league = ctf_jma_leagues.get_league(target_name)

	local skin_texture
	if is_online then
		skin_texture = target_player:get_properties().textures[1] .. ",blank.png"
	else
		local stored = core.deserialize(storage:get_string(target_name))
		local texture = stored and stored[1] or "character.png"
		skin_texture = texture .. ",blank.png"
	end

	local rank_data = {}
	local positions = {}
	for _, mode_name in ipairs(ctf_modebase.modelist) do
		local mode_data = ctf_modebase.modes[mode_name]
		if mode_data and mode_data.rankings then
			rank_data[mode_name] = mode_data.rankings:get(target_name) or {}
			positions[mode_name] = mode_data.rankings.top:get_place(target_name) or "N/A"
		else
			rank_data[mode_name] = {}
			positions[mode_name] = "N/A"
		end
	end

	ctf_gui.show_formspec(name, "ctf_player_info:" .. target_name, function(ctx)
		return generate_formspec(ctx.selected_tab or 1, skin_texture, target_name, league, is_online, positions, rank_data)
	end, {
		selected_tab = 1,
		target_name = target_name,
		skin_texture = skin_texture,
		league = league,
		is_online = is_online,
		positions = positions,
		rank_data = rank_data,
		_on_formspec_input = function(pname, ctx, fields, ...)
			if fields.tab then
				ctx.selected_tab = tonumber(fields.tab)
				return "refresh"
			end
		end
	})
end

core.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	local textures = player:get_properties().textures
	storage:set_string(name, core.serialize(textures))
end)

core.register_chatcommand("player", {
	params = "[name]",
	description = "Show player information",
	func = function(name, param)
		local target = param:trim()
		if target == "" then
			target = name
		end
		show_player_info(name, target)
		return true
	end,
})

core.register_chatcommand("p", {
	params = "[name]",
	description = "Show player information",
	func = function(name, param)
		local target = param:trim()
		if target == "" then
			target = name
		end
		show_player_info(name, target)
		return true
	end,
})