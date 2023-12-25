if os.date("%m") ~= "12" then return end

-- Particlespawner attachment is currently broken, so the following code positions a
-- particle spawner which lasts for 1.4s every 0.7s for each player. The spawners are
-- bound to individual players

snow = {
	SPAWN_SNOW = false,
}

-- Set clouds for normal skybox
local old_clear = skybox.clear
skybox.clear = function(player)
	old_clear(player)

	player:set_clouds({
		density = 0.7,
		color = "#999999cc",
		height = 100,
		thickness = 20,
		speed = {x = -3, z = -3},
	})

	player:set_sky({
		sky_color = {
			day_sky = "#529cd5",
			day_horizon = "#69aed3",
			dawn_sky = "#b19be6",
			dawn_horizon = "#a99bde",
		}
	})
end

-- Spawns snow particles around player
local function spawn_particles(player)
	minetest.add_particlespawner({
		amount = 6 * 60,
		minpos = vector.new(-25, 10, -25),
		maxpos = vector.new( 25, 25,  25),
		minvel = vector.new(-2, -7, -2),
		maxvel = vector.new(-2, -9, -2),
		time = math.random(60, 90),
		minexptime = 10,
		maxexptime = 10,
		minsize = 1,
		maxsize = 3,
		collisiondetection = true,
		collision_removal = true,
		object_collision = true,
		vertical = false,
		texture = ("[combine:7x7:%s,%s=snow_snowflakes.png"):format(math.random(0, 3) * -7, math.random(0, 1) * -7),
		playername = player:get_player_name(),
		attached = player,
		glow = 2
	})
end

local spawner_step = 50
minetest.register_globalstep(function(dtime)
	if spawner_step >= 60 then
		if snow.SPAWN_SNOW then
			spawner_step = 0

			for _, player in pairs(minetest.get_connected_players()) do
				spawn_particles(player)
			end
		end
	else
		spawner_step = spawner_step + dtime
	end
end)
