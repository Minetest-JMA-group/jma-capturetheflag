local modname = core.get_current_modname()
local S = core.get_translator(modname)

local TELEPORT_ITEM = modname .. ":item"

-- saves player: list, index
local teleport_data = {}

-- timer for team saving
local update_timer = 0
local UPDATE_INTERVAL = 5  -- update every 5 seconds

-- pick the spectators team
local function get_player_team(pname)
    return ctf_teams.get(pname)
end

-- pick score
local function get_player_score(pname)
    local mode = ctf_modebase:get_current_mode()
    if not mode then return 0 end
    local rankings = mode.recent_rankings
    if not rankings then return 0 end
        local all_players = rankings.players()
    return all_players[pname] and all_players[pname].score or 0
end

-- pick the team of the spectator (save automatically)
local function get_spectator_team(player_obj, pname)
    local meta = player_obj:get_meta()
    return meta:get_string("spectators_old_team") or ""
end

-- pick up sorted teammates (no spectators / or yourself)
local function build_sorted_teammates(player_name, my_team, player_obj)
    local teammates = {}
    for _, p in ipairs(minetest.get_connected_players()) do
        local pname = p:get_player_name()
        local team = get_player_team(pname)
        if pname ~= player_name and team == my_team and team ~= nil then
            local score = get_player_score(pname)
            table.insert(teammates, {name = pname, score = score})
        end
    end
    table.sort(teammates, function(a, b) return a.score > b.score end)
    local name_list = {}
    for _, t in ipairs(teammates) do
        table.insert(name_list, t.name)
    end
    return name_list
end

-- save team for later
local function update_team_meta()
    for _, player in ipairs(minetest.get_connected_players()) do
        local pname = player:get_player_name()
        local team = get_player_team(pname)
        if team then
            local meta = player:get_meta()
            meta:set_string("spectators_old_team", team)
        end
    end
end

-- globalstep for auto updating
minetest.register_globalstep(function(dtime)
    update_timer = update_timer + dtime
    if update_timer > UPDATE_INTERVAL then
        update_team_meta()
        update_timer = 0
    end
end)

-- update on join
minetest.register_on_joinplayer(function(player)
    local pname = player:get_player_name()
    update_team_meta()  -- Sofort updaten
    teleport_data[pname] = nil  -- Reset data
end)

-- item_use function
local function on_teleport_item_use(itemstack, user)
    if not user or not user:is_player() then return itemstack end
    local pname = user:get_player_name()
    local my_team = get_player_team(pname)
    local is_spec = not my_team
    if is_spec then
        my_team = get_spectator_team(user, pname)
        if my_team == "" then
            hud_events.new(pname, {
                quick = true,
                text = "No old team found!",
                color = "warning",
            })
            return itemstack
        end
    end
    local sorted_teammates = build_sorted_teammates(pname, my_team, user)
    if #sorted_teammates == 0 then
        hud_events.new(pname, {
            quick = true,
            text = "No teammates to spectate!",
            color = "warning",
        })
        return itemstack
    elseif #sorted_teammates == 1 then
        hud_events.new(pname, {
            quick = true,
            text = "No other teammate to spectate!",
            color = "warning",
        })
        return itemstack
    end
    -- Daten updaten
    if not teleport_data[pname] then
        teleport_data[pname] = {players = {}, index = 1}
    end
    local old_len = #teleport_data[pname].players
    teleport_data[pname].players = sorted_teammates
    if old_len ~= #sorted_teammates then
        teleport_data[pname].index = 1
    end
    local data = teleport_data[pname]
    local target_name = data.players[data.index]
    local target_player = minetest.get_player_by_name(target_name)
    if not target_player then
        minetest.chat_send_player(pname, "Teammate offline, skip...")
        data.index = data.index + 1
        if data.index > #data.players then data.index = 1 end
        return itemstack
    end
    -- set anchor and teleportation
    user:set_detach()
    user:set_attach(target_player, "", {x=0, y=0, z=0}, {x=0, y=0, z=0})
    user:set_pos(target_player:get_pos())
    user:set_camera({mode = "third"})

    local target_score = get_player_score(target_name)
    local current_rank = data.index
    hud_events.new(pname, {
        quick = true,
        text = "Spectating " .. target_name .. " (Score: " .. target_score .. ") | Rank in team: " .. current_rank .. "/" .. #data.players,
        color = "warning",
    })
    -- cycle through teammates
    data.index = data.index + 1
    if data.index > #data.players then
        data.index = 1
    end
    return itemstack
end
-- item
minetest.register_craftitem(TELEPORT_ITEM, {
    description = S("Teleport to Teammates"),
    inventory_image = "spectator_teleport_item.png",
    stack_max = 1,
    on_use = on_teleport_item_use,
})

-- cleanup on leave
minetest.register_on_leaveplayer(function(player)
    local pname = player:get_player_name()
    teleport_data[pname] = nil
end)

-- cleanup on shutdown
minetest.register_on_shutdown(function()
    teleport_data = {}
end)
