local modname = core.get_current_modname()
local S       = core.get_translator(modname)

local TELEPORT_ITEM = "spectator_teleport:item"

--  Data structures
-- teleport_data[player_name] = {players = {name1, name2, …}, index = 1}
local teleport_data = {}

-- Auto‑save each player's last known team every few seconds
local UPDATE_INTERVAL = tonumber(core.settings:get("spectator_teleport.update_interval")) or 5   -- default value of seconds and settings
local update_timer    = 0

--  Helper functions
local function get_player_team(pname)
	-- Returns the team name or nil if the player is not in a team
	return ctf_teams.get(pname)
end

local function get_player_score(pname)
	local mode = ctf_modebase:get_current_mode()
	if not mode then return 0 end
	local rankings = mode.recent_rankings
	if not rankings then return 0 end
	local all_players = rankings.players()
	return (all_players[pname] and all_players[pname].score) or 0
end

local function get_spectator_old_team(player_obj)
	local meta = player_obj:get_meta()
	return meta:get_string("spectators_old_team") or ""
end

local function build_sorted_teammates(my_name, my_team)
	local teammates = {}
	for _, p in ipairs(minetest.get_connected_players()) do
		local pname = p:get_player_name()
		if pname ~= my_name then
			local team = get_player_team(pname)
			if team == my_team and team ~= nil then
				table.insert(teammates, {name = pname, score = get_player_score(pname)})
			end
		end
	end
	table.sort(teammates, function(a, b) return a.score > b.score end)

	local name_list = {}
	for _, t in ipairs(teammates) do
		table.insert(name_list, t.name)
	end
	return name_list
end

-- Store each player's current team in meta (used later when they become a spec)
local function update_all_players_team_meta()
	for _, player in ipairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		local team  = get_player_team(pname)
		if team then
			player:get_meta():set_string("spectators_old_team", team)
		end
	end
end

--  Globalstep refresh
minetest.register_globalstep(function(dtime)
	update_timer = update_timer + dtime
	if update_timer > UPDATE_INTERVAL then
		update_all_players_team_meta()
		update_timer = 0
	end
end)

--  Player join / leave hooks
minetest.register_on_joinplayer(function(player)
	update_all_players_team_meta()
	teleport_data[player:get_player_name()] = nil
end)

minetest.register_on_leaveplayer(function(player)
	teleport_data[player:get_player_name()] = nil
end)

minetest.register_on_shutdown(function()
	teleport_data = {}
end)

--  Item use logic
local function on_teleport_item_use(itemstack, user)
	if not user or not user:is_player() then return itemstack end

	local pname    = user:get_player_name()
	local my_team  = get_player_team(pname)
	local is_spec  = (my_team == nil)	-- true if player is currently a spectator

	if is_spec then
		my_team = get_spectator_old_team(user)
		if my_team == "" then
			hud_events.new(pname, {
				quick = true,
				text  = "No old team found!",
				color = "warning",
			})
			return itemstack
		end
	end

	--  Build the sorted teammate list
	local sorted_teammates = build_sorted_teammates(pname, my_team)

	if #sorted_teammates == 0 then
		hud_events.new(pname, {
			quick = true,
			text  = "No teammates to spectate!",
			color = "warning",
		})
		return itemstack
	elseif #sorted_teammates == 1 then
		hud_events.new(pname, {
			quick = true,
			text  = "No other teammate to spectate!",
			color = "warning",
		})
		return itemstack
	end

	--  Initialise / update per‑player teleport cache
	if not teleport_data[pname] then
		teleport_data[pname] = {players = {}, index = 1}
	end

	local data = teleport_data[pname]

	-- Replace the cached list only when it changed (e.g. a teammate died or respawned)
	if #data.players ~= #sorted_teammates then
		data.players = sorted_teammates
		data.index   = 1
	end

	--  Pick the next teammate
	local target_name   = data.players[data.index]
	local target_player = minetest.get_player_by_name(target_name)

	-- If the selected teammate is offline, skip him and try the next one
	if not target_player then
		minetest.chat_send_player(pname, "Teammate offline, skipping…")
		data.index = data.index + 1
		if data.index > #data.players then data.index = 1 end
		return itemstack
	end

	--  Attach / teleport the user
	user:set_detach()
	user:set_attach(target_player, "", {x = 0, y = 0, z = 0},
	                               {x = 0, y = 0, z = 0})
	user:set_pos(target_player:get_pos())

	if user.set_camera then
		user:set_camera({mode = "third"})
	end

	--  HUD feedback
	local target_score = get_player_score(target_name)
	local rank        = data.index
	hud_events.new(pname, {
		quick = true,
		text  = ("Spectating %s (Score: %d) | Rank: %d/%d"):
		         format(target_name, target_score, rank, #data.players),
		color = "warning",
	})

	data.index = data.index + 1
	if data.index > #data.players then data.index = 1 end

	return itemstack
end

--  Register the item
minetest.register_craftitem(TELEPORT_ITEM, {
	description    = S("Teleport to Teammates"),
	inventory_image = "spectator_teleport_item.png",
	stack_max      = 1,
	on_use         = on_teleport_item_use,
})
