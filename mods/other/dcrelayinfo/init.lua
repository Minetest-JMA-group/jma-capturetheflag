local http = minetest.request_http_api()
local conf = minetest.settings

if not http then
    return minetest.log("error", "[Match Discord] Cannot access HTTP API. Add this mod to secure.http_mods.")
end

local webhook_url = conf:get("dcrelayinfo.url") or ""
if webhook_url == "" then
    return minetest.log("error", "[Match Discord] Discord Webhook URL not set in minetest.conf.")
end

local webhook_id, webhook_token = webhook_url:match("webhooks/(%d+)/([%w-_]+)")
if not webhook_id or not webhook_token then
    return minetest.log("error", "[Match Discord] Invalid Discord Webhook URL.")
end

local message_id_file = minetest.get_worldpath() .. "/match_message_id.txt"
local github_base = "https://raw.githubusercontent.com/Minetest-JMA-group/jma-maps/master/"
local team_emojis = {
    red = "🔴", blue = "🔵", green = "🟢",
    orange = "🟠", violet = "🟣", yellow = "🟡"
}

local message_id = nil
local creating_message = false
local retry_delay, max_attempts, attempts = 1, 20, 0

local function store_discord_message_id(id)
    local f = io.open(message_id_file, "w")
    if f then f:write(id) f:close() end
end

local function load_discord_message_id()
    local f = io.open(message_id_file, "r")
    if not f then return nil end
    local id = f:read("*a")
    f:close()
    if id and id ~= "" then
        minetest.log("action", "[Match Discord] Loaded message ID: " .. id)
        return id
    end
end

message_id = load_discord_message_id()

local function generate_match_summary()
    local mode = ctf_modebase.current_mode
    if not mode then return "❌ The game isn't running" end

    local mode_str = string.format("🎮 Mode: %s (%d/%d matches)",
        HumanReadable(mode),
        math.max(0, ctf_modebase.current_mode_matches_played - 1),
        ctf_modebase.current_mode_matches
    )

    local map = ctf_map.current_map
    local map_str = map and string.format("🗺️ Map: %s by %s", map.name, map.author) or "🗺️ No map loaded"

    local total, team_str = 0, ""
    for _, team in ipairs(ctf_teams.current_team_list) do
        local team_data, players = ctf_teams.online_players[team], {}
        if team_data and team_data.players then
            for k, v in pairs(team_data.players) do
                table.insert(players, type(k) == "string" and k or v)
            end
        end
        if #players > 0 then
            total = total + #players
            team_str = team_str .. string.format("%s **%s (%d):** %s\n\n",
                team_emojis[team] or "⚪", team:upper(), #players, table.concat(players, ", "))
        end
    end

    local duration_str = "⏱️ Duration: " .. (ctf_map.get_duration and ctf_map.get_duration() or "-")

    return string.format("%s\n\n%s\n\n%s\n\n👥 Players (%d total):\n\n%s",
        mode_str, map_str, duration_str, total, team_str ~= "" and team_str or "*No players connected*")
end

local function build_map_image_url(map)
    local folder = map and (map.dirname or map.name)
    return folder and (github_base .. folder .. "/screenshot.png") or nil
end

local function generate_top50_embed(mode_name, color)
    local mode_data = ctf_modebase.modes[mode_name]
    if not (mode_data and mode_data.rankings) then return nil end

    local lines = {}
    for i, pname in ipairs(mode_data.rankings.top:get_top(50)) do
        local s = mode_data.rankings:get(pname) or {}
        table.insert(lines, string.format(
            "%d. **%s** 🏆%d ⚔️%d 💀%d 🤝%d 🚩%d 🎯%d 🎯💀%d",
            i, pname,
            s.score or 0, s.kills or 0, s.deaths or 0, s.kill_assists or 0,
            s.flag_captures or 0, s.flag_attempts or 0, s.bounty_kills or 0
        ))
    end

    return {
        title = "🏆 Top 50 — " .. mode_name,
        color = color or 0x3498DB,
        description = (#lines > 0 and table.concat(lines, "\n") or "*No data*")
            .. "\n\n> 📖 **Player :** 🏆 Score | ⚔️ Kills | 💀 Deaths | 🤝 Assists | 🚩 Captures | 🎯 flag attempts | 🎯💀 Bounty Kills"
    }
end

local function handle_discord_response(res, data)
    if res.succeeded and (res.code == 200 or res.code == 204) then
        retry_delay, attempts = 1, 0
    elseif res.code == 404 then
        message_id, retry_delay, attempts = nil, 1, attempts + 1
        create_discord_message(data)
    elseif res.code == 400 or res.code == 401 or res.code == 403 then
        minetest.log("error", "[Match Discord] Fatal error " .. res.code .. ", sync stopped.")
        attempts = max_attempts
    else
        attempts = attempts + 1
        retry_delay = math.min(retry_delay * 2, 300)
        minetest.log("warning", "[Match Discord] Error " .. tostring(res.code) ..
            ", attempt " .. attempts .. "/" .. max_attempts ..
            " (next in " .. retry_delay .. "s)")
    end
end

function create_discord_message(data)
    if creating_message then return end
    creating_message = true

    http.fetch({
        url = webhook_url .. "?wait=true",
        method = "POST",
        extra_headers = { "Content-Type: application/json" },
        data = minetest.write_json(data)
    }, function(res)
        creating_message = false
        if res.succeeded and res.data and res.data ~= "" then
            local body = minetest.parse_json(res.data)
            if body and body.id then
                message_id = body.id
                store_discord_message_id(message_id)
                minetest.log("action", "[Match Discord] Created new message with ID: " .. message_id)
                retry_delay, attempts = 1, 0
            end
        else
            handle_discord_response(res, data)
        end
    end)
end

local function sync_discord_message()
    local embeds, colors = {}, { chaos = 0x9B59B6, classes = 0x1ABC9C, classic = 0xE74C3C, nade_fight = 0xF1C40F }

    for _, m in ipairs({ "chaos", "classes", "classic", "nade_fight" }) do
        local embed = generate_top50_embed(m, colors[m])
        if embed then table.insert(embeds, embed) end
    end

    table.insert(embeds, {
        title = "⚔️ Match in progress",
        color = 0xE67E22,
        description = generate_match_summary(),
        image = ctf_map.current_map and { url = build_map_image_url(ctf_map.current_map) } or nil
    })

    local data = { embeds = embeds }

    if message_id then
        http.fetch({
            url = ("https://discord.com/api/webhooks/%s/%s/messages/%s"):format(webhook_id, webhook_token, message_id),
            method = "PATCH",
            extra_headers = { "Content-Type: application/json" },
            data = minetest.write_json(data)
        }, function(res) handle_discord_response(res, data) end)
    else
        create_discord_message(data)
    end
end

local function schedule_discord_sync()
    if attempts >= max_attempts then
        return minetest.log("error", "[Match Discord] Max attempts reached (" .. max_attempts .. "), sync stopped.")
    end
    sync_discord_message()
    minetest.after(retry_delay, schedule_discord_sync)
end

minetest.register_on_mods_loaded(function()
    minetest.after(5, function()
        if not message_id then
            create_discord_message({
                embeds = {{ title = "⏳ Initialization...", description = "Match info pending" }}
            })
        else
            sync_discord_message()
        end
        schedule_discord_sync()
    end)
end)
