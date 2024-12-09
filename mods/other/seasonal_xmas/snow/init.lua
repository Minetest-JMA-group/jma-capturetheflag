if os.date("%m") ~= "12" then return end

snow = {
	SPAWN_SNOW = false,
}

local spawners = {}

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
	local name = player:get_player_name()
	local amount = 6 * 60

	if ctf_settings then
		amount = amount * tonumber(ctf_settings.settings["snow:particle_amount"]._list_map[
			tonumber(ctf_settings.get(player, "snow:particle_amount"))
		])
	end

	if amount > 0 then
		local time = math.random(60, 90)

		spawners[name] = {
			id = minetest.add_particlespawner({
				amount = amount,
				minpos = vector.new(-25, 10, -25),
				maxpos = vector.new( 25, 25,  25),
				minvel = vector.new(-2, -7, -2),
				maxvel = vector.new(-2, -9, -2),
				time = time,
				minexptime = 10,
				maxexptime = 10,
				minsize = 1,
				maxsize = 3,
				collisiondetection = true,
				collision_removal = true,
				object_collision = true,
				vertical = false,
				texture = ("[combine:7x7:%s,%s=snow_snowflakes.png"):format(math.random(0, 3) * -7, math.random(0, 1) * -7),
				playername = name,
				attached = player,
				glow = 2
			}),
			timer = minetest.after(time-1, function()
				spawners[name] = nil
			end)
		}
	else
		spawners[name] = nil
	end
end

local spawner_step = 50
minetest.register_globalstep(function(dtime)
	if not snow.SPAWN_SNOW then return end

	if spawner_step >= 60 then
		spawner_step = 0

		for _, player in pairs(minetest.get_connected_players()) do
			spawn_particles(player)
		end
	else
		spawner_step = spawner_step + dtime
	end
end)

if ctf_settings then
	ctf_settings.register("snow:particle_amount", {
		type = "list",
		description = "How much falling snow to spawn around you",
		list = {
			"Snow Particles - Default",
			"Snow Particles - None",
			"Snow Particles - 0.5x",
			"Snow Particles - 2x",
			"Snow Particles - 5x",
			"Snow Particles - 10x",
			"Snow Particles - 20x",
		},
		_list_map = {1, 0, 0.5, 2, 5, 10, 20},
		default = "1", -- "Snow Particles - Default"
		on_change = function(player, new_value)
			local name = player:get_player_name()

			if spawners[name] then
				minetest.delete_particlespawner(spawners[name].id)
				spawners[name].timer:cancel()
			end

			spawn_particles(player)
		end
	})
end