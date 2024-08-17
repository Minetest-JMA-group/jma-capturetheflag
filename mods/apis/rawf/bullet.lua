local MODNAME = minetest.get_current_modname()
local api = rawget(_G, MODNAME)

function api.get_bullet_start_data(player)
	local look_dir = player:get_look_dir()
	local spawnpos = vector.offset(player:get_pos(), 0, player:get_properties().eye_height, 0)
	spawnpos = vector.add(spawnpos, player:get_eye_offset())
	spawnpos = vector.add(spawnpos, vector.multiply(look_dir, 0.4))

	return spawnpos, look_dir
end

function api.bulletcast(bullet, pos1, pos2, objects, liquids)
	minetest.add_particle({
		pos = pos1,
		velocity = vector.multiply(vector.direction(pos1, pos2), bullet.particle_speed or 400),
		acceleration = {x=0, y=0, z=0},
		expirationtime = 0.1,
		size = 1,
		collisiondetection = true,
		collision_removal = true,
		object_collision = objects,
		texture = bullet.texture or bullet,
		glow = bullet.glow or 0
	})

	local raycast = minetest.raycast(pos1, pos2, objects, liquids)
	local bulletcast = {
		raycast = raycast,
		hit_object_or_node = function(self, options)
			if not options then
				options = {}
			end

			for hitpoint in self.raycast do
				if hitpoint.type == "node" then
					if not options.node or options.node(minetest.registered_nodes[minetest.get_node(hitpoint.under).name]) then
						return hitpoint
					end
				elseif hitpoint.type == "object" then
					if not options.object or options.object(hitpoint.ref) then
						return hitpoint
					end
				end
			end
		end,
	}

	setmetatable(bulletcast, {
		__index = function(table, key)
			local not_raycast_func = rawget(table, key)

			if not_raycast_func then
				return not_raycast_func
			else
				return function(self, ...)
					local sraycast = rawget(self, "raycast")

					return sraycast[key](sraycast, ...)
				end
			end
		end,
		__call = function(table, ...)
			return rawget(table, "raycast")(...)
		end
	})

	return bulletcast
end

function api.spread_bulletcast(bullet, pos1, pos2, objects, liquids)
	local rays = {}

	for i=1, bullet.amount or 1, 1 do
		rays[i] = api.bulletcast(
			bullet,
			pos1, vector.offset(pos2,
				math.random(-bullet.spread, bullet.spread),
				math.random(-bullet.spread, bullet.spread),
				math.random(-bullet.spread, bullet.spread)
			),
			objects, liquids
		)
	end

	return rays
end
