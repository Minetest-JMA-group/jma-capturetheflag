wind_charges = {}

local function is_solid_node_near(pos)
    local radius = 0.1
	for _, offset in ipairs({
		{x = radius, y = 0, z = 0}, {x = -radius, y = 0, z = 0},
		{x = 0, y = radius, z = 0}, {x = 0, y = -radius, z = 0},
		{x = 0, y = 0, z = radius}, {x = 0, y = 0, z = -radius}
	}) do
		local check_pos = vector.add(pos, offset)
		local node = core.get_node_or_nil(check_pos)
		if node and core.registered_nodes[node.name] and core.registered_nodes[node.name].walkable then
			return true
		end
	end
	return false
end

core.register_entity("wind_charges:wind_projectile", {
	physical = false,
	collisionbox = {0, 0, 0, 0, 0, 0},
	visual = "sprite",
	textures = {"wind_charge.png"},
	visual_size = {x = 0.5, y = 0.5},
	timer = 0,
	lifetime = 16,
	explode = function(self)
		local pos = self.object:get_pos()
		core.sound_play("wind_charge_explode", {
			pos = pos,
			max_hear_distance = 8,
			gain = 1.0
		})

        core.add_particlespawner({
            amount = 8,
            time = 0.1,
            minpos = pos,
            maxpos = pos,
            minvel = {x = -5, y = 0, z = -5},
            maxvel = {x = 5, y = 2, z = 5},
            minacc = {x = 0, y = 0, z = 0},
            maxacc = {x = 0, y = -5, z = 0},
            minexptime = 0.1,
            maxexptime = 0.2,
            minsize = 5,
            maxsize = 8,
            texture = "wind_charge_explode_particle.png",
            glow = 5,
        })

		local objs = core.get_objects_inside_radius(pos, 4)
		for obj_index, obj in ipairs(objs) do
			if obj:is_player() then
				local player = obj
				local player_name = player:get_player_name()
				if ctf_teams.get(self.owner_name) == ctf_teams.get(player_name) and self.owner_name ~= player_name then--check if player_name is in the same team as the owner
					goto continue
				end
			end
			local obj_pos = obj:get_pos()
			local dist = vector.distance(pos, obj_pos)
			local dir = vector.direction(pos, obj_pos)
			local power = 16 * (1 - math.min(dist / 4, 1))
			if obj:is_player() then
				dir.y = 1
			else
				local ent = obj:get_luaentity()
				if ent and ent.name == "__builtin:item" then
					local owner_name = self.owner_name
					local owner = core.get_player_by_name(owner_name)
					if not owner then
						goto continue
					end
					local owner_pos = owner:get_pos()
					dir = vector.direction(pos, owner_pos)
					power = dist * 3 + 2

					obj:add_velocity({x = 0, y = 4, z = 0})
					dir.y = 0
				else
					dir.y = 0.4
				end
			end
			obj:add_velocity(vector.multiply(dir, power))
		    ::continue::
		end
		self.object:remove()
	end,

    on_step = function(self, dtime)
        self.timer = self.timer + dtime
        if self.timer > self.lifetime then
            self:explode()
            return
        end

        local pos = self.object:get_pos()
        if is_solid_node_near(pos) then
            self:explode()
            return
        end
    end,
	on_activate = function(self, staticdata, dtime_s)
		if staticdata and staticdata:match("^owner:") then
			self.owner_name = staticdata:sub(7)
		end
	end,
})

local players_wind_charge_cooldown = {}

core.register_craftitem("wind_charges:wind_charge", {
	description = "Wind Charge",
	inventory_image = "wind_charge.png",
	on_use = function(itemstack, user, pointed_thing)
		local user_name = user:get_player_name()

		local current_time = core.get_gametime()
		local last_used_time = players_wind_charge_cooldown[user_name] or 0
		local cooldown_time = 0.02

		if current_time - last_used_time < cooldown_time then
			return itemstack
		end

		players_wind_charge_cooldown[user_name] = current_time

		local pos = user:get_pos()
		local props = user:get_properties()
		local eye_height = props and props.eye_height or 1.6
		pos.y = pos.y + eye_height

		local dir = user:get_look_dir()
		local player_velocity = user:get_velocity() or {x = 0, y = 0, z = 0}

		local obj = core.add_entity(pos, "wind_charges:wind_projectile", "owner:" .. user_name)
		if obj then
			local base_speed = vector.multiply(dir, 18)
			local total_velocity = vector.add(base_speed, player_velocity)
			obj:set_velocity(total_velocity)
			obj:set_acceleration(total_velocity)

			core.sound_play("wind_charge_throw", {
				pos = pos,
				max_hear_distance = 8,
				gain = 0.8
			})
		end
		itemstack:take_item()
		return itemstack
	end
})
