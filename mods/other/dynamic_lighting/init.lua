local update_interval = 0.5
local level_delta = 2
local shiny_items = {}

--- Shining API ---
wielded_light = {}

function wielded_light.update_light(pos, light_level)
	local around_vector = {
		{ x = 0, y = 0, z = 0 },
		{ x = 0, y = 1, z = 0 },
		{ x = 0, y = -1, z = 0 },
		{ x = 1, y = 0, z = 0 },
		{ x = -1, y = 0, z = 0 },
		{ x = 0, y = 0, z = 1 },
		{ x = 0, y = 0, z = 1 },
	}
	local do_update = false
	local old_value = 0
	local timer
	local light_pos
	for _, around in ipairs(around_vector) do
		light_pos = vector.add(pos, around)
		local name = minetest.get_node(light_pos).name
		if name == "air" and (minetest.get_node_light(light_pos) or 0) < light_level then
			do_update = true
			break
		elseif name:sub(1, 16) == "dynamic_lighting" then -- Update existing light node and timer
			old_value = tonumber(name:sub(18))
			if not old_value or not light_level then
				return
			end
			if light_level > old_value then
				do_update = true
			else
				timer = minetest.get_node_timer(light_pos)
				local elapsed = timer:get_elapsed()
				if elapsed > (update_interval * 1.5) then
					do_update = true
				end
			end
			break
		end
	end
	if do_update then
		timer = timer or minetest.get_node_timer(light_pos)
		if light_level ~= old_value then
			minetest.swap_node(light_pos, { name = "dynamic_lighting:" .. light_level })
		end
		timer:start(update_interval * 3)
	end
end

function wielded_light.update_light_by_item(item, pos)
	local stack = ItemStack(item)
	local light_level = shiny_items[stack:get_name()]
	local itemdef = stack:get_definition()
	if not light_level and not itemdef then
		return
	end
	if not light_level and itemdef.light_source then
		shiny_items[stack:get_name()] = itemdef.light_source
	end

	light_level = light_level or ((itemdef.light_source or 0) - level_delta)

	if light_level > 0 then
		wielded_light.update_light(pos, light_level)
		return light_level
	end
end

for i = 1, 14 do
	minetest.register_node("dynamic_lighting:" .. i, {
		drawtype = "airlike",
		groups = { not_in_creative_inventory = 1 },
		walkable = false,
		paramtype = "light",
		sunlight_propagates = true,
		light_source = i,
		pointable = false,
		buildable_to = true,
		drops = {},
		on_timer = function(pos, elapsed)
			minetest.swap_node(pos, { name = "air" })
		end,
	})
end

local timer = 0
minetest.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer < update_interval then
		return
	end
	timer = 0

	for _, player in pairs(minetest.get_connected_players()) do
		local pos = vector.add(
			vector.add({ x = 0, y = 1, z = 0 }, vector.round(player:get_pos())),
			vector.round(vector.multiply(player:get_velocity(), update_interval * 1.5))
		)
		wielded_light.update_light_by_item(player:get_wielded_item(), pos)
	end
end)
