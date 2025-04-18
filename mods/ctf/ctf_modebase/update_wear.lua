local wear_timers = {}
local item_pos_cache = {}

ctf_modebase.update_wear = {}

function ctf_modebase.update_wear.generate_item_id()
    local id
    repeat
        id = tostring(math.random(1, 999999))
    until not item_pos_cache[id]
    return id
end

function ctf_modebase.update_wear.find_item_by_id(pinv, item_id)
    if item_pos_cache[item_id] then
        local stack = pinv:get_stack("main", item_pos_cache[item_id])
        local meta = stack:get_meta()
        if meta:get_string("update_wear_id") == item_id then
            return item_pos_cache[item_id], stack
        end
    end

    -- Fall back to full search if cache miss
    for pos, stack in pairs(pinv:get_list("main")) do
        local meta = stack:get_meta()
        if meta:get_string("update_wear_id") == item_id then
            item_pos_cache[item_id] = pos
            return pos, stack
        end
    end

	if item_pos_cache[item_id] then
    	item_pos_cache[item_id] = nil
	end

    return nil, nil
end

function ctf_modebase.update_wear.assign_id(stack)
	local meta = stack:get_meta()
	local item_id = meta:get_string("update_wear_id")

	if item_id == "" then
		item_id = ctf_modebase.update_wear.generate_item_id()
		meta:set_string("update_wear_id", item_id)
	end

	return stack, item_id
end

function ctf_modebase.update_wear.start_update(pname, stack, step, down, finish_callback, cancel_callback)
	assert(type(stack) == "userdata", "stack must be a userdata")
	if not wear_timers[pname] then wear_timers[pname] = {} end

	-- Assign ID to the item if it doesn't have one
	local modified_stack, item_id = ctf_modebase.update_wear.assign_id(stack)

	if wear_timers[pname][item_id] then return end

	-- Store the item in player's inventory with the ID
	local player = minetest.get_player_by_name(pname)
	if player then
		local pinv = player:get_inventory()
		local pos, _ = ctf_modebase.update_wear.find_item_by_id(pinv, item_id)
		if pos then
			pinv:set_stack("main", pos, modified_stack)
		end
	end

	wear_timers[pname][item_id] = {c=cancel_callback, t = minetest.after(1, function()
		wear_timers[pname][item_id] = nil
		local player = minetest.get_player_by_name(pname)

		if player then
			local pinv = player:get_inventory()
			local pos, _ = ctf_modebase.update_wear.find_item_by_id(pinv, item_id)

			if pos then
				local wear = stack:get_wear()

				if down then
					wear = math.max(0, wear - step)
				else
					wear = math.min(65534, wear + step)
				end

				stack:set_wear(wear)
				pinv:set_stack("main", pos, stack)

				if (down and wear > 0) or (not down and wear < 65534) then
					ctf_modebase.update_wear.start_update(pname, stack, step, down, finish_callback, cancel_callback)
				elseif finish_callback then
					finish_callback(item_id)
				end
			end
		end
	end)}

	return item_id
end

-- Cancel updates for a specific item ID
function ctf_modebase.update_wear.cancel_item_update(pname, item_id)
	pname = PlayerName(pname)

	if wear_timers[pname] and wear_timers[pname][item_id] then
		if wear_timers[pname][item_id].c then
			wear_timers[pname][item_id].c(item_id)
		end
		wear_timers[pname][item_id].t:cancel()
		wear_timers[pname][item_id] = nil
	end
end

ctf_api.register_on_match_end(function()
	for _, timers in pairs(wear_timers) do
		for _, timer in pairs(timers) do
			if timer.c then
				timer.c()
			end
			timer.t:cancel()
		end
	end

	wear_timers = {}
    item_pos_cache = {} -- Clear the cache on match end
end)

function ctf_modebase.update_wear.cancel_player_updates(pname)
	pname = PlayerName(pname)

	if wear_timers[pname] then
		for item_id, timer in pairs(wear_timers[pname]) do
			if timer.c then
				timer.c(item_id)
			end
			timer.t:cancel()
		end

		wear_timers[pname] = nil
	end
end

minetest.register_on_dieplayer(function(player)
	ctf_modebase.update_wear.cancel_player_updates(player)
end)

minetest.register_on_leaveplayer(function(player)
	ctf_modebase.update_wear.cancel_player_updates(player)
end)
