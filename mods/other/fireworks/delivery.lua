
local gravity = 7
local mass = 0.9
local amplitude = 1
local frequency = 3

minetest.register_entity("fireworks:firework_static", {
	initial_properties = {
        visual = "wielditem",
		wield_item = "default:apple",
		physical = true,
		makes_footstep_sound = false,
		backface_culling = false,
		shaded = true,
		static_save = false,
		pointable = true,
		glow = 5,
		visual_size = {x = 0.7, y = 0.7, z = 0.7},
		collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
	},

	timer = 0,
	timeout = 200,

	on_step = function(self, dtime, movement)
		self.timer = self.timer + dtime
		if self.timer > self.timeout then
			self.object:remove()
		end

		if self.inactive then
			return
		end

		if movement.touching_ground then
			self.inactive = true
            local pos = self.object:get_pos()
            if not minetest.is_protected(pos, "") then
                minetest.add_node(pos, {name = self.object:get_properties().wield_item})
            end
			if random_gifts.entity_exists(self.parachute) then
				self.parachute:remove()
				self.parachute = nil
			end
			self.object:remove()
            return
        end

		local vel = self.object:get_velocity()
		if not vel then return end

		self.time_falling = (self.time_falling or 0) + dtime
		local sideways_speed = amplitude * math.sin(frequency * self.time_falling)
		local acceleration = {
			x = sideways_speed,
			y = -gravity * mass,
			z = sideways_speed,
		}

		self.object:set_velocity(vector.add(vector.multiply(vel, dtime), acceleration))
	end,

	on_activate = function(self, staticdata, dtime_s)
		local par = minetest.add_entity(self.object:get_pos(), "random_gifts:parachute")
		par:set_attach(self.object)
		par:set_properties({visual_size = {x = 18, y = 18, z = 18}})
		self.parachute = par

        local item = "fireworks:" .. fireworks.colors[math.random(1, #fireworks.colors)][1]

		if math.random(1, 8) == 1 then
			item = "torch_bomb:mega_torch_bomb_rocket"
		end

        self.object:set_properties({wield_item = item})
	end,

	on_deactivate = function(self, removal)
		if random_gifts.entity_exists(self.parachute) then
			self.parachute:remove()
		end
	end,
})

local timer
local spawn_interval = 180
local reduce_radius = 8

local function spawn_giftbox()
    local spawn_amount = math.max(15, math.min(#minetest.get_connected_players(), 40))

    local vm = VoxelManip()
    local pos1, pos2 = vm:read_from_map(vector.add(ctf_map.current_map.pos1, reduce_radius), vector.subtract(ctf_map.current_map.pos2, reduce_radius))

    for _ = 1, spawn_amount do
        local rand_pos = vector.new(math.random(pos1.x, pos2.x), pos2.y + 1, math.random(pos1.z, pos2.z))

        local air_nodes = 0

        for y_off = 1, 50 do
            local npos = vector.offset(rand_pos, 0, -y_off, 0)
            local node_name = vm:get_node_at(npos).name

            if node_name == "air" then
                air_nodes = air_nodes + 1
            else
                air_nodes = 0
            end

            if air_nodes >= 3 then
                minetest.add_entity(npos, "fireworks:firework_static")
                break
            end
        end
    end

    timer = minetest.after(spawn_interval, spawn_giftbox)
end

function fireworks.run_spawn_timer()
    timer = minetest.after(10, spawn_giftbox)
end

function fireworks.stop_spawn_timer()
    if timer then
        timer:cancel()
    end
end

ctf_api.register_on_new_match(function ()
	fireworks.run_spawn_timer()
end)

ctf_api.register_on_match_end(function ()
	fireworks.stop_spawn_timer()
end)