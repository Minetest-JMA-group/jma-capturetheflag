ctf_kill_list = {}

local hud = mhud.init()

local KILLSTAT_REMOVAL_TIME = 30

local MAX_NAME_LENGTH = 19
local HUD_LINES = 6
local HUD_LINE_HEIGHT = 36
local HUDNAME_FORMAT = "kill_list:%d,%d"

local HUD_DEFINITIONS = {
	{
		type = "text",
		position = {x = 0, y = 0.8},
		offset = {x = MAX_NAME_LENGTH*10, y = 0},
		alignment = {x = "left", y = "center"},
		color = 0xFFFFFF,
	},
	{
		type = "image",
		position = {x = 0, y = 0.8},
		offset = {x = (MAX_NAME_LENGTH*10) + 28, y = 0},
		alignment = {x = "center", y = "center"},
	},
	{
		type = "text",
		position = {x = 0, y = 0.8},
		offset = {x = (MAX_NAME_LENGTH*10) + 54, y = 0},
		alignment = {x = "right", y = "center"},
		color = 0xFFFFFF,
	},
}
local kill_list = {}
local player_settings = {}

local image_scale_map = ctf_settings.settings["ctf_kill_list:tp_size"].image_scale_map
local function update_kill_list_hud(player)
	local player_name = PlayerName(player)
	local ps = player_settings[player_name]
	if not ps then return end
	for idx = 1, ps.history_size, 1 do
		local new = kill_list[idx]
		idx = ps.history_size - (idx-1)

		local img_scale = ps.image_scale

		img_scale = image_scale_map[img_scale] * 2

		for i=1, 3, 1 do
			local hname = string.format(HUDNAME_FORMAT, idx, i)
			local phud = hud:get(player, hname)

			if new then
				if phud then
					hud:change(player, hname, {
						text = (new[i].text or new[i].image),
						image_scale = img_scale,
						color = new[i].color or 0xFFFFFF
					})
				else
					local newhud = table.copy(HUD_DEFINITIONS[i])

					newhud.offset.y = -(idx-1)*HUD_LINE_HEIGHT
					newhud.text = new[i].text or new[i].image
					newhud.image_scale = img_scale
					newhud.color = new[i].color or 0xFFFFFF
					hud:add(player, hname, newhud)
				end
			elseif phud then
				hud:change(player, hname, {
					text = ""
				})
			end
		end
	end
end

function ctf_kill_list.apply_settings(player, update_hud)
	local player_name = PlayerName(player)
	local ps = {}
	ps.history_size = tonumber(ctf_settings.get(player, "ctf_kill_list:history_size")) or HUD_LINES
	ps.image_scale = tonumber(ctf_settings.get(player, "ctf_kill_list:tp_size")) or 2

	player_settings[player_name] = ps

	if update_hud then
		if hud.huds[player_name] then
			for i in pairs(hud.huds[player_name]) do
				hud:remove(player, i)
			end
		end
		update_kill_list_hud(player)
	end
end

local globalstep_timer = 0
local function add_kill(x, y, z)
	table.insert(kill_list, 1, {x, y, z})

	if #kill_list > HUD_LINES then
		table.remove(kill_list)
	end

	for _, p in pairs(core.get_connected_players()) do
		update_kill_list_hud(p)
	end

	globalstep_timer = 0
end

core.register_globalstep(function(dtime)
	globalstep_timer = globalstep_timer + dtime

	if globalstep_timer >= KILLSTAT_REMOVAL_TIME then
		globalstep_timer = 0

		table.remove(kill_list)

		for _, p in pairs(core.get_connected_players()) do
			update_kill_list_hud(p)
		end
	end
end)

ctf_api.register_on_match_end(function()
	kill_list = {}
	hud:clear_all()
end)

core.register_on_joinplayer(function(player)
	ctf_kill_list.apply_settings(player)
end)

core.register_on_leaveplayer(function(player)
	player_settings[PlayerName(player)] = nil
end)

function ctf_kill_list.add(killer, victim, weapon_image, comment)
	killer = PlayerName(killer)
	victim = PlayerName(victim)

	local k_teamcolor = ctf_teams.get(killer)
	local v_teamcolor = ctf_teams.get(victim)

	if k_teamcolor then
		k_teamcolor = ctf_teams.team[k_teamcolor].color_hex
	end
	if v_teamcolor then
		v_teamcolor = ctf_teams.team[v_teamcolor].color_hex
	end

	add_kill(
		{text = killer, color = k_teamcolor or 0xFFFFFF},
		{image = weapon_image or "ctf_kill_list_punch.png"},
		{text = victim .. (comment or ""), color = v_teamcolor or 0xFFFFFF}
	)
end
