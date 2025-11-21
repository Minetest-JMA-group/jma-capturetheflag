-- map callbacks
ctf_map.callbacks = {
    register_globalstep = false,
    register_on_dieplayer = false,
    register_on_joinplayer = false,
    register_on_leaveplayer = false,
}


-- Callbacks that return values (modifiers/controllers)
ctf_map.callbacks_with_return = {
    register_on_punchplayer = false,
    register_on_player_hpchange = false, -- modifier = false
    register_on_player_hpchange_modifier = false, -- modifier = true
    register_on_respawnplayer = false,
}

local callback_mappings = {
    register_globalstep = minetest.register_globalstep,
    register_on_punchnode = minetest.register_on_punchnode,
    register_on_leaveplayer = minetest.register_on_leaveplayer,
    register_on_punchplayer = minetest.register_on_punchplayer,
    register_on_player_hpchange = minetest.register_on_player_hpchange,
    register_on_dieplayer = minetest.register_on_dieplayer,
    register_on_respawnplayer = minetest.register_on_respawnplayer,
    register_on_joinplayer = minetest.register_on_joinplayer,
}


local function register_regular_callback(callback_name, minetest_function)
    minetest_function(function(...)
        if ctf_map.callbacks[callback_name] then
            pcall(ctf_map.callbacks[callback_name], ...)
        end
    end)
end

local function register_callback_with_return(callback_name, minetest_function)
    minetest_function(function (...)
        local ok, result
        if ctf_map.callbacks_with_return[callback_name] then
            ok, result = pcall(ctf_map.callbacks[callback_name], ...)
        end
        if ok then
            return result
        else
            minetest.log("warning", "ctf_map: Callback returned error status " .. tostring(callback_name))
            return nil
        end
    end)
end


for callback_name, minetest_function in pairs(callback_mappings) do
    if ctf_map.callbacks[callback_name] then
        register_regular_callback(callback_name, minetest_function)
    elseif ctf_map.callbacks_with_return[callback_name] then
        register_callback_with_return(callback_name, minetest_function)
    end
end


minetest.register_on_player_hpchange(function(player, hp_change, reason)
    if ctf_map.callbacks.register_on_player_hpchange_modifier then
        local ok, result = pcall(ctf_map.callbacks.register_on_player_hpchange_modifier, player, hp_change, reason)
        if ok then
            return result
        end
    end
    return hp_change
end, true)



function ctf_map.set_callback_function(callback_name, callback_function)
    minetest.log("info", "map_api: registering callback " .. tostring(callback_name))
    if ctf_map.callbacks[callback_name] == nil or ctf_map.callbacks_with_return[callback_name] then
        minetest.log("warning", "Unknown callback: " .. tostring(callback_name))
        return false
    end

    if callback_function == nil or type(callback_function) == "function" then
        ctf_map.callbacks[callback_name] = callback_function
        return true
    else
        minetest.log("error", "Invalid callback function for " .. callback_name ..
                ": expected function or nil, got " .. type(callback_function))
        return false
    end
end

function ctf_map.clear_all_callbacks()
    for callback_name, _ in pairs(ctf_map.callbacks) do
        ctf_map.callbacks[callback_name] = false
    end
    for callback_name, _ in pairs(ctf_map.callbacks_with_return) do
        ctf_map.callbacks_with_return[callback_name] = false
    end
end

ctf_api.register_on_match_end(function()
    minetest.after(0, function()
	    ctf_map.clear_all_callbacks()
    end)
end)
