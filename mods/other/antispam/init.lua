-- SPDX-License-Identifier: GPL-3.0-or-later
-- Copyright (c) 2025 astra0081. (partake-kudos-only@duck.com)
-- Inspired from antispam mod by appgurueu (https://github.com/appgurueu/antispam)

local PLAYERS_MSG = {}
local PLAYERS_FREQ = {}
local PLAYER_KICKS = {}

local SPAM_SPEED = 5
local SPAM_SPEED_MSECS = SPAM_SPEED * 1e6
local SPAM_WARN = 3
local SPAM_KICK = SPAM_WARN + 4
local SPAM_BAN_AFTER_KICKS = 2
local RESET_TIME = 30
local RESET_TIME_MSECS = RESET_TIME * 1e6
local WARNING_COLOR = minetest.get_color_escape_sequence("#FFBB33")

local function init_player_state(player_name)
    if not PLAYER_KICKS[player_name] then PLAYER_KICKS[player_name] = 0 end
    if not PLAYERS_MSG[player_name] then PLAYERS_MSG[player_name] = {} end
    if not PLAYERS_FREQ[player_name] then 
        PLAYERS_FREQ[player_name] = {0, 0, minetest.get_us_time(), 0} 
    end
end

local function handle_message(name, message)
    local current_time = minetest.get_us_time()

    if PLAYERS_MSG[name][message] then
        local message_info = PLAYERS_MSG[name][message]
        message_info[1] = message_info[1] + 1
        message_info[2] = current_time

        if message_info[1] >= SPAM_KICK then
            PLAYER_KICKS[name] = PLAYER_KICKS[name] + 1
            if PLAYER_KICKS[name] >= SPAM_BAN_AFTER_KICKS then
                minetest.log("[Antispam] Player " .. name .. " Banned for spamming.")
                minetest.ban_player(name, "Banned for spamming.")
                -- Clear player data after ban
                PLAYER_KICKS[name] = nil
                PLAYERS_MSG[name] = nil
                PLAYERS_FREQ[name] = nil
                return true  -- Player is banned, stop further processing
            else
                minetest.kick_player(name, "Kicked for spamming.")
                minetest.log("[Antispam] Player " .. name .. " kicked for spamming.")
            end
        elseif message_info[1] >= SPAM_WARN then
            minetest.chat_send_player(name, WARNING_COLOR .. "Warning! You've sent the message '" .. message .. "' too often. Wait at least " .. RESET_TIME .. " seconds before sending it again.")
        end
    else
        PLAYERS_MSG[name][message] = {1, current_time}
    end

    local player_freq = PLAYERS_FREQ[name]
    local speed = (player_freq[1] * player_freq[2] + (current_time - player_freq[3])) / (player_freq[2] + 1)
    
    if player_freq[2] >= SPAM_WARN then
        if player_freq[4] + 1 >= SPAM_KICK - SPAM_WARN then
            PLAYER_KICKS[name] = PLAYER_KICKS[name] + 1
            if PLAYER_KICKS[name] >= SPAM_BAN_AFTER_KICKS then
                minetest.log("[Antispam] Player " .. name .. " Banned for spamming.")
                minetest.ban_player(name, "Banned for spamming.")
                -- Clear player data after ban
                PLAYER_KICKS[name] = nil
                PLAYERS_MSG[name] = nil
                PLAYERS_FREQ[name] = nil
                return true 
            else
                minetest.kick_player(name, "Kicked for spamming.")
                 minetest.log("[Antispam] Player " .. name .. " kicked for spamming.")
            end
        elseif speed <= SPAM_SPEED_MSECS then
            minetest.chat_send_player(name, WARNING_COLOR .. "Warning! You're sending messages too fast. Wait at least " .. SPAM_SPEED .. " seconds.")
            player_freq[4] = player_freq[4] + 1
            player_freq[1] = SPAM_SPEED_MSECS
            player_freq[2] = SPAM_WARN
        else
            player_freq[1] = 0
            player_freq[2] = 0
            player_freq[4] = 0
        end
    end

    PLAYERS_FREQ[name] = {player_freq[1], player_freq[2] + 1, current_time, player_freq[4]}

    return false
end

minetest.register_chatcommand("antispam", {
    params = "<option> <value>",
    description = "Change spam settings: <option> can be 'speed', 'warn', 'kick', or 'ban_kicks'. <value> is the new value for that option.",
    privs = {server = true},
    func = function(name, param)
        local argv = param:split(" ")
        if #argv ~= 2 then
            return false, "Invalid parameters. Usage: /antispam <option> <value>"
        end

        local option = argv[1]
        local value = tonumber(argv[2])

        if not value then
            return false, "Invalid value. Please provide a valid number."
        end

        if option == "limit" then
            SPAM_SPEED = value
            SPAM_SPEED_MSECS = SPAM_SPEED * 1e6
        elseif option == "warn" then
            SPAM_WARN = value
            SPAM_KICK = SPAM_WARN + 4
        elseif option == "ban_kicks" then
            SPAM_BAN_AFTER_KICKS = value
        else
            return false, "Invalid option. Available options: speed, warn, kick, ban_kicks."
        end

        return true, minetest.colorize("#FF0000", "[Antispam] ") .. minetest.colorize("#00FF00", "Option " .. option .. " set to " .. value)
    end
})

minetest.register_on_leaveplayer(function(player)
    local pname = player:get_player_name()
    PLAYERS_MSG[pname] = nil
    PLAYERS_FREQ[pname] = nil
end)

minetest.register_on_joinplayer(function(player)
    local pname = player:get_player_name()
    init_player_state(pname)
end)

minetest.register_on_chat_message(function(name, message)
    handle_message(name, message)
end)
