local WEAR_MAX = 65535
local cooldown = ctf_core.init_cooldowns()

local grenade_launcher_name = "ctf_mode_potato:potato_launcher"

local weapon_list = {
	[1] = grenade_launcher_name,
}

local function run_cooldown(user, itemstack)
	local name = user:get_player_name()

	local on_finish = function()
		local inv = user:get_inventory()
		for i = 1, inv:get_size("main") do
			local itemstack = inv:get_stack("main", i)
			if itemstack:get_name() == grenade_launcher_name then
				local meta = itemstack:get_meta()
				meta:set_int("overheat", 0)
				meta:set_string("color", "")
				inv:set_stack("main", i, itemstack)
			end
		end
	end

	ctf_modebase.update_wear.start_update(name, itemstack, WEAR_MAX / 5, true, on_finish)
end

local radius = 2

local shot_types = {
	normal = {
		speed = 18,
		radius = 2,
		wear = WEAR_MAX / 5,
	},
	powered = {
		speed = 30,
		radius = 4,
		wear = WEAR_MAX / 3,
	},
}

core.register_tool("ctf_mode_potato:potato_launcher", {
	description = core.colorize("#c69828", "Potato Launcher")
		.. "\nShoot Potato Grenades sky-high",
	wield_scale = { x = 2.0, y = 2.0, z = 2.5 },
	inventory_image = "ctf_mode_chaos_grenade_launcher.png",
	wield_image = "ctf_mode_chaos_grenade_launcher.png",
	range = 4,
	on_use = function(itemstack, user, pointed_thing)
		local meta = itemstack:get_meta()
		if meta:get_int("overheat") == 1 then
			return
		end

		local shot_type = "powered"

		local inv = user:get_inventory()
		local charge = inv:remove_item("main", "ctf_mode_potato:potato_grenade 1")
		if charge:is_empty() then
			is_sneaking = false
			hud_events.new(user:get_player_name(), {
				text = "You need a potato grenade to use this",
				quick = true,
			})
			return
		end

		local stats = shot_types[shot_type]
		local name = user:get_player_name()
		local pos = user:get_pos()
		local dir = user:get_look_dir()

		if pos and dir then
			pos.y = pos.y + 1.5
			local ahead = vector.add(pos, vector.multiply(dir, 1))
			local obj = core.add_entity(ahead, "ctf_mode_potato:potato_grenade")
			if obj then
				local ent = obj:get_luaentity()
				ent.puncher_name = name
				ent.radius = cooldown:get(user) and 1 or stats.radius
				if shot_type == "powered" then
					core.add_particlespawner({
						amount = 15,
						time = 1,
						minvel = vector.multiply(dir, 2),
						maxvel = vector.multiply(dir, 4),
						minacc = vector.new(0, -1, 0),
						maxacc = vector.new(0, -1, 0),
						minexptime = 0.5,
						maxexptime = 1,
						minsize = 1,
						maxsize = 2,
						texture = "smoke_puff.png^[colorize:black:150",
						attached = obj,
					})
				end

				local speed = vector.length(user:get_velocity())
				obj:add_velocity(vector.multiply(dir, stats.speed + speed))
			end
		end

		core.sound_play("ctf_mode_chaos_grenade_launcher_plop", {
			to_player = name,
			gain = 0.5,
			pitch = shot_type == "powered" and 0.5 or 1.1,
		})

		local new_wear = itemstack:get_wear() + stats.wear
		if new_wear > 65534 then
			new_wear = 65534
		end
		itemstack:set_wear(new_wear)
		if itemstack:get_wear() >= 65532 then
			meta:set_int("overheat", 1)
			meta:set_string("color", "#fc6a6c")
			run_cooldown(user, itemstack)
		end

		-- Add recoil and particles for charged shot
		local recoil_strength = shot_type == "powered" and 10 or 5
		user:add_velocity(vector.multiply(dir, -recoil_strength))

		cooldown:set(user, 0.3)
		return itemstack
	end,
})

local function can_explode(pos, pname, radius)
	if core.is_protected(pos, "") then
		core.chat_send_player(pname, "You can't explode grenades on spawn!")
		return false
	end

	local pteam = ctf_teams.get(pname)

	if pteam then
		for flagteam, team in pairs(ctf_map.current_map.teams) do
			if not ctf_modebase.flag_captured[flagteam] and team.flag_pos then
				local distance_from_flag = vector.distance(pos, team.flag_pos)
				if distance_from_flag <= radius then
					core.chat_send_player(
						pname,
						"You can't explode grenades so close to a flag!"
					)
					return false
				end
			end
		end
	end
	return true
end

core.register_entity("ctf_mode_potato:potato_grenade", {
	initial_properties = {
		visual = "sprite",
		visual_size = { x = 1, y = 1 },
		textures = { "ctf_mode_potato_potato_grenade.png" },
		physical = true,
		makes_footstep_sound = false,
		backface_culling = false,
		static_save = false,
		pointable = false,
		collide_with_objects = true,
		collisionbox = { -0.2, -0.2, -0.2, 0.2, 0.2, 0.2 },
	},
	timer = 0,
	on_activate = function(self)
		core.add_particlespawner({
			attached = self.object,
			amount = 5,
			time = 1,
			minpos = { x = 0, y = -0.5, z = 0 }, -- Offset to middle of player
			maxpos = { x = 0, y = 0.5, z = 0 },
			minvel = { x = 0, y = 0, z = 0 },
			maxvel = self.object:get_velocity(),
			minacc = { x = 0, y = 5, z = 0 },
			maxacc = { x = 0, y = 7, z = 0 },
			minexptime = 1.5,
			maxexptime = 3.0,
			minsize = 2,
			maxsize = 3,
			collisiondetection = false,
			collision_removal = false,
			vertical = false,
			texture = "grenades_smoke.png^[colorize:black:150",
		})
	end,
	on_step = function(self, dtime, moveresult)
		self.timer = self.timer + dtime
		if self.timer >= 60 then
			self.object:remove()
			return
		end

		local pos = self.object:get_pos()
		if not pos then
			return
		end

		if moveresult.collides then
			local rad = self.radius or radius
			if can_explode(pos, self.puncher_name, rad) then
				tnt.boom(pos, {
					puncher_name = self.puncher_name,
					radius = 2,
					damage_modifier = 1.5,
				})
			end
			self.object:remove()
			return
		end

		local vel = self.object:get_velocity()
		if vel then
			local gravity = 9
			vel.y = vel.y - gravity * dtime
			self.object:set_velocity(vel)
		end
	end,
})

core.register_node("ctf_mode_potato:compressor", {
	description = core.colorize("#c69828", "Potato Compressor"),

	groups = { cracky = 3 },

	tiles = {
		"ctf_mode_potato_compressor_top.png",
		"ctf_mode_potato_compressor_top.png",
		"ctf_mode_potato_compressor_side.png",
		"ctf_mode_potato_compressor_side.png",
		"ctf_mode_potato_compressor_side.png",
		"ctf_mode_potato_compressor_front.png",
	},
	paramtype2 = "facedir",

	on_construct = function(pos)
		local meta = core.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("src", 1)

		meta:set_string(
			"formspec",
			"size[8,8.5]"
				.. "list[nodemeta:"
				.. pos.x
				.. ","
				.. pos.y
				.. ","
				.. pos.z
				.. ";src;4.5,0.5;1,1;]"
				.. "button_exit[4,2;2,1;compress_btn;Compress]"
				.. "label[0.1,2;I heard that putting 20 potatoes\nin here might do something...]"
				.. "list[current_player;main;0,4.25;8,1;]"
				.. "list[current_player;main;0,5.5;8,3;8]"
				.. "listring[context;src]"
				.. "listring[current_player;main]"
				.. default.get_hotbar_bg(0, 4.25)
		)
	end,

	on_receive_fields = function(pos, formname, fields, sender)
		if fields.compress_btn then
			core.show_formspec(sender:get_player_name(), "", "")

			local node = core.get_node(pos)

			local meta = core.get_meta(pos)
			local inv = meta:get_inventory()
			local stack = inv:get_stack("src", 1)

			local enough_potatoes = false

			if
				stack:get_name() == "ctf_mode_potato:potato"
				and stack:get_count() >= 20
			then
				enough_potatoes = true
			end

			core.set_node(
				pos,
				{ name = "ctf_mode_potato:compressor_active", param2 = node.param2 }
			)

			core.after(3, function()
				core.add_particlespawner({
					amount = 50,
					time = 5,
					texture = {
						name = "grenades_smoke.png",
						scale = 1.5,
					},
					pos = {
						min = vector.new(pos.x - 0.3, pos.y + 0.5, pos.z - 0.3),
						max = vector.new(pos.x + 0.3, pos.y + 0.5, pos.z + 0.3),
						bias = 0,
					},
					vel = {
						min = vector.new(-0.1, 0.5, -0.1),
						max = vector.new(0.1, 1.0, 0.1),
					},
				})

				core.after(2, function()
					core.add_particlespawner({
						amount = 15,
						time = 3,
						texture = {
							name = "grenades_boom.png",
							scale = 1,
							glow = 5,
						},
						pos = {
							min = vector.new(pos.x - 0.3, pos.y + 0.5, pos.z - 0.3),
							max = vector.new(pos.x + 0.3, pos.y + 0.5, pos.z + 0.3),
							bias = 0,
						},
						vel = {
							min = vector.new(-0.1, 0.5, -0.1),
							max = vector.new(0.1, 1.0, 0.1),
						},
					})
				end)
			end)
			core.after(8, function()
				-- EXPLODE
				core.add_particlespawner({
					amount = 64,
					time = 0.1,
					texture = "grenades_smoke.png",
					pos = {
						min = vector.new(pos.x - 0.5, pos.y - 0.5, pos.z - 0.5),
						max = vector.new(pos.x + 0.5, pos.y + 0.5, pos.z + 0.5),
					},
					vel = {
						min = vector.new(-3, 1, -3),
						max = vector.new(3, 5, 3),
					},
					acc = {
						min = vector.new(0, -3, 0),
						max = vector.new(0, -5, 0),
					},
					size = {
						min = 1,
						max = 3,
					},
					exptime = {
						min = 0.5,
						max = 1.5,
					},
				})
				core.sound_play("tnt_explode", {
					pos = pos,
					gain = 0.6,
					max_hear_distance = 20,
				})

				local damage_radius = 3
				for _, obj in ipairs(core.get_objects_inside_radius(pos, damage_radius)) do
					if obj:is_player() then
						obj:punch(obj, 1.0, {
							full_punch_interval = 1.0,
							damage_groups = { fleshy = 8 },
						})
					end
				end
				local knockback_radius = 5
				local knockback_force = 10

				for _, obj in
					ipairs(core.get_objects_inside_radius(pos, knockback_radius))
				do
					if obj:is_player() then
						local dist = vector.distance(pos, obj:get_pos())
						local force = knockback_force * (1 - (dist / knockback_radius))
						local dir = vector.normalize(vector.subtract(obj:get_pos(), pos))
						dir.y = dir.y + 5 -- upward bias before normalizing
						dir = vector.normalize(dir)
						obj:add_velocity(vector.multiply(dir, force))
					end
				end

				if not enough_potatoes then
					tnt.boom(pos, {
						puncher_name = sender:get_player_name(),
						radius = 3,
						damage_modifier = 1,
					})
				end

				core.set_node(
					pos,
					{ name = "ctf_mode_potato:compressor", param2 = node.param2 }
				)
				if enough_potatoes then
					local meta = core.get_meta(pos)
					local inv = meta:get_inventory()
					inv:set_stack("src", 1, ItemStack("ctf_mode_potato:potato_grenade 3"))
				end
			end)
		end
	end,

	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		return stack:get_count()
	end,

	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		return stack:get_count()
	end,

	allow_metadata_inventory_move = function(
		pos,
		from_list,
		from_index,
		to_list,
		to_index,
		count,
		player
	)
		return count
	end,
})

core.register_node("ctf_mode_potato:compressor_active", {
	description = core.colorize("#c69828", "Potato Compressor") .. " (active)",

	groups = { indestructable = 1 },

	tiles = {
		"ctf_mode_potato_compressor_top.png",
		"ctf_mode_potato_compressor_top.png",
		"ctf_mode_potato_compressor_side.png",
		"ctf_mode_potato_compressor_side.png",
		"ctf_mode_potato_compressor_side.png",
		"ctf_mode_potato_compressor_front_active.png",
	},
	paramtype2 = "facedir",

	sounds = default.node_sound_stone_defaults(),
})
