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
		position = { x = 0, y = 0.8 },
		offset = { x = MAX_NAME_LENGTH * 10, y = 0 },
		alignment = { x = "left", y = "center" },
		color = 0xFFFFFF,
	},
	{
		type = "image",
		position = { x = 0, y = 0.8 },
		offset = { x = (MAX_NAME_LENGTH * 10) + 28, y = 0 },
		alignment = { x = "center", y = "center" },
	},
	{
		type = "text",
		position = { x = 0, y = 0.8 },
		offset = { x = (MAX_NAME_LENGTH * 10) + 54, y = 0 },
		alignment = { x = "right", y = "center" },
		color = 0xFFFFFF,
	},
}
local kill_list = {}
local player_settings = {}

---Optional provider of the kill list of the area a player is in. It must
---return a table of entries or nil for the regular match feed and is set by a
---mod that has areas with their own kill list
---@type fun(name: string): table[]|nil
ctf_kill_list.feed_provider = nil

---Aging timer of every feed (weak keys: the feeds are owned by other mods)
local feed_timers = setmetatable({}, { __mode = "k" })

---Entries the player is currently looking at
---@param name string
---@return table[]
local function feed_entries(name)
	if ctf_kill_list.feed_provider then
		local entries = ctf_kill_list.feed_provider(name)
		if entries then
			return entries
		end
	end

	return kill_list
end

local image_scale_map = ctf_settings.settings["ctf_kill_list:tp_size"].image_scale_map
local function update_kill_list_hud(player)
	local player_name = PlayerName(player)
	local ps = player_settings[player_name]
	if not ps then
		return
	end
	local entries = feed_entries(player_name)

	for idx = 1, ps.history_size, 1 do
		local new = entries[idx]
		idx = ps.history_size - (idx - 1)

		local img_scale = ps.image_scale

		img_scale = image_scale_map[img_scale] * 2

		for i = 1, 3, 1 do
			local hname = string.format(HUDNAME_FORMAT, idx, i)
			local phud = hud:get(player, hname)

			if new then
				if phud then
					hud:change(player, hname, {
						text = (new[i].text or new[i].image),
						image_scale = img_scale,
						color = new[i].color or 0xFFFFFF,
					})
				else
					local newhud = table.copy(HUD_DEFINITIONS[i])

					newhud.offset.y = -(idx - 1) * HUD_LINE_HEIGHT
					newhud.text = new[i].text or new[i].image
					newhud.image_scale = img_scale
					newhud.color = new[i].color or 0xFFFFFF
					hud:add(player, hname, newhud)
				end
			elseif phud then
				hud:change(player, hname, {
					text = "",
				})
			end
		end
	end
end

function ctf_kill_list.apply_settings(player, update_hud)
	local player_name = PlayerName(player)
	local ps = {}
	ps.history_size = tonumber(ctf_settings.get(player, "ctf_kill_list:history_size"))
		or HUD_LINES
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

---Refreshes the players that are currently looking at the given feed
---@param list table[]
local function refresh_feed(list)
	for _, player in ipairs(core.get_connected_players()) do
		if feed_entries(PlayerName(player)) == list then
			update_kill_list_hud(player)
		end
	end
end

---@param list table[]
---@param entry table
local function add_kill(list, entry)
	table.insert(list, 1, entry)

	if #list > HUD_LINES then
		table.remove(list)
	end

	feed_timers[list] = 0
	refresh_feed(list)
end

core.register_globalstep(function(dtime)
	-- Copy the feeds first: refreshing them reads the same table
	local lists = {}
	for list in pairs(feed_timers) do
		table.insert(lists, list)
	end

	for _, list in ipairs(lists) do
		feed_timers[list] = feed_timers[list] + dtime

		if feed_timers[list] >= KILLSTAT_REMOVAL_TIME then
			feed_timers[list] = 0

			table.remove(list)
			refresh_feed(list)
		end
	end
end)

ctf_api.register_on_match_end(function()
	kill_list = {}
	hud:clear_all()

	-- Players outside of the match (Elysium, PvP Boxes) keep their own feed
	for _, player in ipairs(core.get_connected_players()) do
		update_kill_list_hud(player)
	end
end)

---Rebuilds the kill list HUD of a player, e.g. after he changed his location
---@param player string|ObjectRef
function ctf_kill_list.update_player(player)
	local p = core.get_player_by_name(PlayerName(player))
	if p then
		update_kill_list_hud(p)
	end
end

core.register_on_joinplayer(function(player)
	ctf_kill_list.apply_settings(player)
end)

core.register_on_leaveplayer(function(player)
	player_settings[PlayerName(player)] = nil
end)

function ctf_kill_list.add(killer, victim, weapon_image, comment)
	local k_teamcolor = ctf_teams.get(killer)
	local v_teamcolor = ctf_teams.get(victim)

	if k_teamcolor then
		---@diagnostic disable-next-line: cast-local-type
		k_teamcolor = ctf_teams.team[k_teamcolor].color_hex
	end
	if v_teamcolor then
		---@diagnostic disable-next-line: cast-local-type
		v_teamcolor = ctf_teams.team[v_teamcolor].color_hex
	end

	-- The kill belongs to the feed of the area the players are in
	local list
	if killer and killer ~= "" then
		list = feed_entries(killer)
	end
	if (not list or list == kill_list) and victim and victim ~= "" then
		list = feed_entries(victim)
	end

	add_kill(list or kill_list, {
		{ text = killer, color = k_teamcolor or 0xFFFFFF },
		{ image = weapon_image or "ctf_kill_list_punch.png" },
		{ text = victim .. (comment or ""), color = v_teamcolor or 0xFFFFFF },
	})
end
