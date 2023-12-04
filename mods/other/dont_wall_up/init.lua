local vecnew = vector.new

local scan_radius = 1.8
local scan_step = 0.5
local y_offset_min = 0.2 -- Make easier to place node under feet

local function check_collisions(collisionbox_player, pos)
	local pos_min = vecnew(pos.x + collisionbox_player[1], pos.y + collisionbox_player[2] + y_offset_min, pos.z + collisionbox_player[3])
	local pos_max = vecnew(pos.x + collisionbox_player[4], pos.y + collisionbox_player[5], pos.z + collisionbox_player[6])

    for x = pos_min.x, pos_max.x, scan_step do
        for y = pos_min.y, pos_max.y, scan_step do
            for z = pos_min.z, pos_max.z, scan_step do
                local npos = vecnew(x, y, z)
				-- vizlib.draw_point(npos)
                local name = minetest.get_node(npos).name
				local node_def = minetest.registered_nodes[name]
                if node_def and node_def.walkable then
                    return true
                end
            end
        end
    end
    return false
end

minetest.register_on_placenode(function(pos, newnode, player, oldnode)
	if (minetest.registered_nodes[newnode.name] or {}).walkable == false then
		return
	end

	for _, object in ipairs(minetest.get_objects_inside_radius(pos, scan_radius)) do
		if minetest.is_player(object) and object ~= player then -- ignores itself
			if check_collisions(object:get_properties().collisionbox, object:get_pos()) then
				minetest.set_node(pos, oldnode)
				minetest.log("action", player:get_player_name() .. " trying to place node inside of " .. object:get_player_name())
				return true
			end
		end
	end
end)
