
--[[
    Anti-Spam mod for Minetest
    SPDX-License-Identifier: GPL-3.0-or-later
    Copyright (c) 2025 astra0081X (partake-kudos-only@duck.com)
    Current Date and Time (UTC): 2025-01-10 11:09:06)
--]]

-- Player data storage
local players = {}

-- Default settings
local MIN_TIME_BETWEEN_MESSAGES = 5  -- Minimum seconds between messages
local MIN_TIME_BETWEEN_MESSAGES_USEC = MIN_TIME_BETWEEN_MESSAGES * 1e6
local MESSAGES_BEFORE_WARN = 6  -- Messages before first warning
local WARNS_BEFORE_MUTE = 3     -- Number of warnings before mute
local MESSAGE_RESET_TIME = 30    -- Seconds until message count resets
local MESSAGE_RESET_TIME_USEC = MESSAGE_RESET_TIME * 1e6
local MUTE_DURATION = 600        -- 10 minutes mute duration

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
    local ok = xban.mute_player(name, "Antispam", expires, "Automatically muted by system, reason:  spamming. Please notify the server staff if you have been falsely muted.")
    
    if ok then
        core.log("action", string.format("[Antispam] Player %s muted for %d minutes", name, MUTE_DURATION/60))
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
            message_count = 0,
            last_message_time = 0,
            warning_count = 0,
            last_warning_time = 0
        }
    end
    
    local player = players[name]
    local time_since_last = current_time - player.last_message_time

    -- Clean old messages
    for msg, time in pairs(player.messages) do
        if current_time - time >= MESSAGE_RESET_TIME_USEC then
            player.messages[msg] = nil
            player.message_count = player.message_count - 1
        end
    end

    -- Reset warning count if enough time has passed
    if current_time - player.last_warning_time >= MESSAGE_RESET_TIME_USEC then
        player.warning_count = 0
    end

    -- Check message frequency
    if time_since_last < MIN_TIME_BETWEEN_MESSAGES_USEC then
        player.message_count = player.message_count + 1
        
        if player.message_count > MESSAGES_BEFORE_WARN then
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

    -- Store message data
    player.messages[message] = current_time
    player.last_message_time = current_time

    return false
end)

-- Chat command for configuration
core.register_chatcommand("antispam", {
    description = "Configure anti-spam settings",
    params = "<setting> <value>",
    privs = {filtering = true},
    func = function(name, param)
        local option, value = param:match("^(%S+)%s+(%d+)$")
        
        if not option or not value then
            local help = {
                COLORS.TITLE .. "Anti-Spam Settings",
                COLORS.TEXT .. "â¢ speed: " .. COLORS.VALUE .. "Seconds between messages " .. 
                    COLORS.TEXT .. "(default: " .. COLORS.VALUE .. MIN_TIME_BETWEEN_MESSAGES .. COLORS.TEXT .. ")",
                COLORS.TEXT .. "â¢ warn: " .. COLORS.VALUE .. "Messages before warning " ..
                    COLORS.TEXT .. "(default: " .. COLORS.VALUE .. MESSAGES_BEFORE_WARN .. COLORS.TEXT .. ")",
                COLORS.TEXT .. "â¢ mute: " .. COLORS.VALUE .. "Warnings before mute " ..
                    COLORS.TEXT .. "(default: " .. COLORS.VALUE .. WARNS_BEFORE_MUTE .. COLORS.TEXT .. ")",
                COLORS.TEXT .. "â¢ reset: " .. COLORS.VALUE .. "Seconds until warnings reset " ..
                    COLORS.TEXT .. "(default: " .. COLORS.VALUE .. MESSAGE_RESET_TIME .. COLORS.TEXT .. ")",
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
                name = "Message speed",
                desc = "seconds between messages"
            },
            warn = {
                update = function(v) 
                    MESSAGES_BEFORE_WARN = v
                end,
                name = "Warning threshold",
                desc = "messages before warning"
            },
            mute = {
                update = function(v) 
                    WARNS_BEFORE_MUTE = v
                end,
                name = "Warnings before mute",
                desc = "warnings before mute"
            },
            reset = {
                update = function(v) 
                    MESSAGE_RESET_TIME = v
                    MESSAGE_RESET_TIME_USEC = v * 1e6
                end,
                name = "Reset time",
                desc = "seconds until reset"
            }
        }

        local handler = options[option]
        if handler then
            local ok, err = handler.update(value)
            if ok == false then
                return false, COLORS.ERROR .. "Error: " .. err
            end
            return true, COLORS.SUCCESS .. "[Anti-Spam] " .. COLORS.TEXT .. 
                        "Updated " .. COLORS.VALUE .. handler.name .. COLORS.TEXT ..
                        " to " .. COLORS.VALUE .. value .. " " .. COLORS.TEXT .. handler.desc
        else
            return false, COLORS.ERROR .. "Error: Invalid setting! Use /antispam for help."
        end
    end
})
