--[[
    Anti-Spam mod for Minetest
    SPDX-License-Identifier: GPL-3.0-or-later
    Copyright (c) 2025 astra0081X (partake-kudos-only@duck.com)
    Current Date and Time (UTC): 2025-01-11 14:22:05
--]]

-- Initialize the players table as a global variable
players = players or {}

-- Default settings
local MIN_TIME_BETWEEN_MESSAGES = 6  -- Minimum seconds between messages
local MIN_TIME_BETWEEN_MESSAGES_USEC = MIN_TIME_BETWEEN_MESSAGES * 1e6
local MESSAGES_BEFORE_WARN = 6  -- Messages before first warning
local WARNS_BEFORE_MUTE = 3     -- Number of warnings before mute
local MESSAGE_RESET_TIME = 30    -- Seconds until message count resets
local MESSAGE_RESET_TIME_USEC = MESSAGE_RESET_TIME * 1e6
local MUTE_DURATION = 600 -- In seconds
-- Color scheme
local COLORS = {
    WARNING = core.get_color_escape_sequence"#FFBB33",
    SUCCESS = core.get_color_escape_sequence"#44FF44",
    ERROR = core.get_color_escape_sequence"#FF5555",
    TITLE = core.get_color_escape_sequence"#55CCFF",
    TEXT = core.get_color_escape_sequence"#FFFFFF",
    VALUE = core.get_color_escape_sequence"#FFFF55"
}

-- Cleanup player data on leave
core.register_on_leaveplayer(function(player)
    players[player:get_player_name()] = nil
end)

local function mute_player(name)
    local expires = os.time() + MUTE_DURATION
    local ok = xban.mute_player(name, "Antispam", expires, "Automatically muted by system, reason: Spamming. Please notify the server staff if you have been falsely muted.")

    if ok then
        core.log("action", string.format("[Antispam] Player %s muted for %d minutes.", name, MUTE_DURATION/60))
    else
        core.log("action", string.format("[Antispam] Failed to mute player %s", name))
    end
    
    players[name] = nil
end

-- Chat message handler
core.register_on_chat_message(function(name, message)
    local current_time = core.get_us_time()
    
    -- Initialize player data if not exists
    if not players[name] then
        players[name] = {
            messages = {},
            repeated_messages = {},
            message_count = 0,
            last_message_time = 0,
            warning_count = 0,
            last_warning_time = 0
        }
    end
    
    local player = players[name]
    local time_since_last = current_time - player.last_message_time

    -- Clean old messages (frequency check)
    for msg, time in pairs(player.messages) do
        if current_time - time >= MESSAGE_RESET_TIME_USEC then
            player.messages[msg] = nil
            player.message_count = player.message_count - 1
        end
    end

    -- Clean old repeated messages
    for msg, data in pairs(player.repeated_messages) do
        if current_time - data.last_time >= MESSAGE_RESET_TIME_USEC then
            player.repeated_messages[msg] = nil
        end
    end

    -- Reset warning count if enough time has passed
    if current_time - player.last_warning_time >= MESSAGE_RESET_TIME_USEC then
        player.warning_count = 0
    end

    -- Check message frequency
    if time_since_last < MIN_TIME_BETWEEN_MESSAGES_USEC then
        player.message_count = player.message_count + 1
        
        if player.message_count >= MESSAGES_BEFORE_WARN then
            player.warning_count = player.warning_count + 1
            player.last_warning_time = current_time
            
            if player.warning_count >= WARNS_BEFORE_MUTE then
                mute_player(name)
                return true
            end
            
            core.chat_send_player(name, COLORS.WARNING .. 
                string.format("[AntiSpam] Warning [%d/%d]: Please slow down! Wait %d seconds between messages.", 
                    player.warning_count, WARNS_BEFORE_MUTE, MIN_TIME_BETWEEN_MESSAGES))
        end
    else
        player.message_count = 1
    end

    -- Check repeated messages separately
    if player.repeated_messages[message] then
        local msg_data = player.repeated_messages[message]
        msg_data.count = msg_data.count + 1
        msg_data.last_time = current_time

        if msg_data.count >= MESSAGES_BEFORE_WARN then
            player.warning_count = player.warning_count + 1
            player.last_warning_time = current_time
            
            if player.warning_count >= WARNS_BEFORE_MUTE then
                mute_player(name)
                return true
            end
            
            core.chat_send_player(name, COLORS.WARNING .. 
                string.format("[AntiSpam] Warning [%d/%d]: Please avoid repeating the same message. Wait %d seconds.", 
                    player.warning_count, WARNS_BEFORE_MUTE, MESSAGE_RESET_TIME))
        end
    else
        player.repeated_messages[message] = {
            count = 1,
            last_time = current_time
        }
    end

    -- Store message data for frequency checking
    player.messages[message] = current_time
    player.last_message_time = current_time

    return false
end)

-- Chat command for configuration
core.register_chatcommand("antispam", {
    description = "Configure anti-spam settings",
    params = "<setting> <value>",
    privs = {server = true},
    func = function(name, param)
        local option, value = param:match("^(%S+)%s+(%d+)$")
        
        if not option or not value then
            local help = {
                COLORS.TITLE .. "Anti-Spam Settings",
                COLORS.TEXT .. "• speed: " .. COLORS.VALUE .. "Seconds between messages " .. 
                    COLORS.TEXT .. "(default: " .. COLORS.VALUE .. "6" .. COLORS.TEXT .. ")",
                COLORS.TEXT .. "• warn: " .. COLORS.VALUE .. "Messages before warning " ..
                    COLORS.TEXT .. "(default: " .. COLORS.VALUE .. "6" .. COLORS.TEXT .. ")",
                COLORS.TEXT .. "• mute: " .. COLORS.VALUE .. "Warnings before mute " ..
                    COLORS.TEXT .. "(default: " .. COLORS.VALUE .. "3" .. COLORS.TEXT .. ")",
                COLORS.TEXT .. "• duration: " .. COLORS.VALUE .. "Duration of mute " ..
                    COLORS.TEXT .. "(default: " .. COLORS.VALUE .. "10 minutes" .. COLORS.TEXT .. ")",
                COLORS.TEXT .. "• reset: " .. COLORS.VALUE .. "Seconds until warnings and repeated messages reset " ..
                    COLORS.TEXT .. "(default: " .. COLORS.VALUE .. "30" .. COLORS.TEXT .. ")",
                "",
                COLORS.TITLE .. "Usage: " .. COLORS.TEXT .. "/antispam <setting> <value>"
            }
            return false, table.concat(help, "\n")
        end

        value = tonumber(value)
        if not value or value < 1 then
            return false, COLORS.ERROR .. "Error: Value must be positive!"
        end

        local options = {
            speed = {
                update = function(v) 
                    MIN_TIME_BETWEEN_MESSAGES = v
                    MIN_TIME_BETWEEN_MESSAGES_USEC = v * 1e6
                end,
                name = "message speed",
                desc = "seconds between messages"
            },
            warn = {
                update = function(v) 
                    MESSAGES_BEFORE_WARN = v
                end,
                name = "warning threshold",
                desc = "messages before warning"
            },
            mute = {
                update = function(v) 
                    WARNS_BEFORE_KICK = v
                end,
                name = "warnings before mute", 
                desc = "warnings before mute"
            },
            duration = {
                update = function(v)
                    MUTE_DURATION = v*60 -- Input should be in minutes
                end,
                name = "duration of mute",
                desc = "minutes"
            },
            reset = {
                update = function(v) 
                    MESSAGE_RESET_TIME = v
                    MESSAGE_RESET_TIME_USEC = v * 1e6
                end,
                name = "reset time",
                desc = "seconds until warnings and repeated messages reset"
            }
        }

        local handler = options[option]
        if handler then
            handler.update(value)
            return true, COLORS.SUCCESS .. "[Anti-Spam] " .. COLORS.TEXT .. 
                        "Updated " .. COLORS.VALUE .. handler.name .. COLORS.TEXT ..
                        " to " .. COLORS.VALUE .. value .. " " .. COLORS.TEXT .. handler.desc
        else
            return false, COLORS.ERROR .. "Error: Invalid setting! Use /antispam for help."
        end
    end
})
