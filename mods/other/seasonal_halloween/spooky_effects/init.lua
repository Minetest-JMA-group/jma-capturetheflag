if os.date("%m") ~= "10" or tonumber(os.date("%d")) < 17 then return end

spooky_effects = {}

function spooky_effects.spawn_ghost(pos, vel, accel)
	minetest.add_particle({
		pos = pos,
		velocity = vel or {x=math.random(-0.5, 0.5), y=3, z=math.random(-0.5, 0.5)},
		acceleration = accel or {x=0, y=0.5, z=0},
		expirationtime = 1.5,
		size = 8,
		collisiondetection = false,
		collision_removal = false,
		object_collision = false,
		vertical = true,
		texture = "spooky_effects_ghost.png",
		glow = 8
	})
end

function spooky_effects.spawn_angry_ghost(pos, target, vel, accel)
	local dest

	if not target then
		dest = pos:offset(0, 4, 0)
	else
		dest = target:get_pos():offset(0, 1.3, 0)
	end

	minetest.add_particle({
		pos = pos,
		velocity = vector.multiply(vector.direction(pos, dest), vel or 9),
		acceleration = accel or {x=0, y=0, z=0},
		expirationtime = 1.4,
		size = 11,
		collisiondetection = false,
		collision_removal = true,
		object_collision = true,
		texture = "spooky_effects_ghost_angry.png",
		glow = 8
	})
end

minetest.register_on_dieplayer(function(ded)
	spooky_effects.spawn_angry_ghost(ded:get_pos())
end)
