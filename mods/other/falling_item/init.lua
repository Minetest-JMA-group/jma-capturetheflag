-- Minetest: builtin/item.lua (override falling entity with new features)

local function add_fall_damage(node, damage)

	if core.registered_nodes[node] then

		local group = core.registered_nodes[node].groups

		group.falling_node_damage = damage

		core.override_item(node, {groups = group})
	else
		print (node .. " not found to add falling_node_damage to")
	end
end

-- override falling nodes to add damage
add_fall_damage("default:sand", 2)
add_fall_damage("default:desert_sand", 2)
add_fall_damage("default:silver_sand", 2)
add_fall_damage("default:gravel", 3)
add_fall_damage("tnt:tnt_burning", 4)


--
-- Falling stuff
--

local node_fall_hurt = true
local delay = 0.1 -- used to simulate lag
local gravity = core.settings:get("movement_gravity") or 9.81
local builtin_shared = ...
local SCALE = 0.667
local facedir_to_euler = {
	{y = 0, x = 0, z = 0},
	{y = -math.pi/2, x = 0, z = 0},
	{y = math.pi, x = 0, z = 0},
	{y = math.pi/2, x = 0, z = 0},
	{y = math.pi/2, x = -math.pi/2, z = math.pi/2},
	{y = math.pi/2, x = math.pi, z = math.pi/2},
	{y = math.pi/2, x = math.pi/2, z = math.pi/2},
	{y = math.pi/2, x = 0, z = math.pi/2},
	{y = -math.pi/2, x = math.pi/2, z = math.pi/2},
	{y = -math.pi/2, x = 0, z = math.pi/2},
	{y = -math.pi/2, x = -math.pi/2, z = math.pi/2},
	{y = -math.pi/2, x = math.pi, z = math.pi/2},
	{y = 0, x = 0, z = math.pi/2},
	{y = 0, x = -math.pi/2, z = math.pi/2},
	{y = 0, x = math.pi, z = math.pi/2},
	{y = 0, x = math.pi/2, z = math.pi/2},
	{y = math.pi, x = math.pi, z = math.pi/2},
	{y = math.pi, x = math.pi/2, z = math.pi/2},
	{y = math.pi, x = 0, z = math.pi/2},
	{y = math.pi, x = -math.pi/2, z = math.pi/2},
	{y = math.pi, x = math.pi, z = 0},
	{y = -math.pi/2, x = math.pi, z = 0},
	{y = 0, x = math.pi, z = 0},
	{y = math.pi/2, x = math.pi, z = 0}
}

local function fall_hurt_check(self, pos)

	if self.hurt_toggle then

		-- Get damage level from falling_node_damage group
		local damage = core.registered_nodes[self.node.name] and
				core.registered_nodes[self.node.name].groups.falling_node_damage

		if damage then

			local all_objects = core.get_objects_inside_radius(pos, 0.8)

			for _,obj in ipairs(all_objects) do

				local name = obj:get_luaentity() and obj:get_luaentity().name

				if (name ~= "__builtin:item" and name ~= "__builtin:falling_node")
				or obj:is_player() then

					obj:punch(self.object, 4.0, {damage_groups = {fleshy = damage}}, nil)

					self.hurt_toggle = false
				end
			end
		end
	else
		self.hurt_toggle = true
	end
end


-- override falling node entity with new version
core.register_entity(":__builtin:falling_node", {

	initial_properties = {
		visual = "wielditem",
		visual_size = {x = SCALE, y = SCALE, z = SCALE},
		textures = {},
		physical = true,
		is_visible = false,
		collide_with_objects = false,
		collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}
	},

	set_node = function(self, node, meta)

		self.node = node
		meta = meta or {}
		self.hurt_toggle = true

		if type(meta.to_table) == "function" then
			meta = meta:to_table()
		end

		for _, list in pairs(meta.inventory or {}) do

			for i, stack in pairs(list) do

				if type(stack) == "userdata" then
					list[i] = stack:to_string()
				end
			end
		end

		local def = core.registered_nodes[node.name]

		if not def then

			-- Don't allow unknown nodes to fall
			core.log("warning", "Unknown falling node removed at "
				.. core.pos_to_string(self.object:get_pos()))

			self.object:remove()

			return
		end

		self.meta = meta

		-- make sure param2 isnt nil
		local np2 = node.param2 or 0

		-- Cache whether we're supposed to float on water
		self.floats = core.get_item_group(node.name, "float") ~= 0

		-- Set entity visuals
		if def.drawtype == "torchlike" or def.drawtype == "signlike" then

			local textures

			if def.tiles and def.tiles[1] then

				local tile = def.tiles[1]

				if type(tile) == "table" then
					tile = tile.name
				end

				if def.drawtype == "torchlike" then
					textures = {"(" .. tile .. ")^[transformFX", tile}
				else
					textures = {tile, "(" .. tile .. ")^[transformFX"}
				end
			end

			local vsize

			if def.visual_scale then

				local s = def.visual_scale

				vsize = {x = s, y = s, z = s}
			end

			self.object:set_properties({
				is_visible = true,
				visual = "upright_sprite",
				visual_size = vsize,
				textures = textures,
				glow = def.light_source
			})

		elseif def.drawtype ~= "airlike" then

			local itemstring = node.name

			if core.is_colored_paramtype(def.paramtype2) then
				itemstring = core.itemstring_with_palette(itemstring, np2)
			end

			-- FIXME: solution needed for paramtype2 == "leveled"
			local vsize

			local s = {}
			s.x = (def.visual_scale or 1) * SCALE
			s.y = s.x
			s.z = s.x

			-- Compensate for wield_scale
			if def.wield_scale then
				s.x = s.x / def.wield_scale.x
				s.y = s.y / def.wield_scale.y
				s.z = s.z / def.wield_scale.z
			end

			self.object:set_properties({
				is_visible = true,
				wield_item = itemstring,
				visual_size = s,
				glow = def.light_source
			})
		end

		-- Set collision box (certain nodeboxes only for now)
		local nb_types = {fixed = true, leveled = true, connected = true}

		if def.drawtype == "nodebox" and def.node_box
		and nb_types[def.node_box.type] and def.node_box.fixed then

			local box = table.copy(def.node_box.fixed)

			if type(box[1]) == "table" then
				box = #box == 1 and box[1] or nil -- We can only use a single box
			end

			if box then

				if def.paramtype2 == "leveled" and (self.node.level or 0) > 0 then
					box[5] = -0.5 + self.node.level / 64
				end

				self.object:set_properties({
					collisionbox = box
				})
			end
		end

		-- Rotate entity
		if def.drawtype == "torchlike" then

			self.object:set_yaw(math.pi * 0.25)

		elseif ((np2 ~= 0 or def.drawtype == "nodebox" or def.drawtype == "mesh")
		and (def.wield_image == "" or def.wield_image == nil))
		or def.drawtype == "signlike"
		or def.drawtype == "mesh"
		or def.drawtype == "normal"
		or def.drawtype == "nodebox" then

			if def.paramtype2 == "facedir" or def.paramtype2 == "colorfacedir" then

				local fdir = np2 % 32 % 24

				-- Get rotation from a precalculated lookup table
				local euler = facedir_to_euler[fdir + 1]

				if euler then
					self.object:set_rotation(euler)
				end

			elseif def.paramtype2 == "4dir"
			or def.paramtype2 == "color4dir" then

				local fdir = node.param2 % 4

				-- Get rotation from a precalculated lookup table
				local euler = facedir_to_euler[fdir + 1]

				if euler then
					self.object:set_rotation(euler)
				end

			elseif def.drawtype ~= "plantlike"
			and def.drawtype ~= "plantlike_rooted"
			and (def.paramtype2 == "wallmounted"
			or def.paramtype2 == "colorwallmounted"
			or def.drawtype == "signlike") then

				local rot = node.param2 % 8

				if def.drawtype == "signlike"
				and def.paramtype2 ~= "wallmounted"
				and def.paramtype2 ~= "colorwallmounted" then
					-- Change rotation to "floor" by default for non-wallmounted paramtype2
					rot = 1
				end

				local pitch, yaw, roll = 0, 0, 0

				if def.drawtype == "nodebox" or def.drawtype == "mesh" then

					if rot == 0 then
						pitch, yaw = math.pi/2, 0
					elseif rot == 1 then
						pitch, yaw = -math.pi/2, math.pi
					elseif rot == 2 then
						pitch, yaw = 0, math.pi/2
					elseif rot == 3 then
						pitch, yaw = 0, -math.pi/2
					elseif rot == 4 then
						pitch, yaw = 0, math.pi
					end
				else
					if rot == 1 then
						pitch, yaw = math.pi, math.pi
					elseif rot == 2 then
						pitch, yaw = math.pi/2, math.pi/2
					elseif rot == 3 then
						pitch, yaw = math.pi/2, -math.pi/2
					elseif rot == 4 then
						pitch, yaw = math.pi/2, math.pi
					elseif rot == 5 then
						pitch, yaw = math.pi/2, 0
					end
				end

				if def.drawtype == "signlike" then

					pitch = pitch - math.pi/2

					if rot == 0 then
						yaw = yaw + math.pi/2
					elseif rot == 1 then
						yaw = yaw - math.pi/2
					end

				elseif def.drawtype == "mesh"
				or def.drawtype == "normal" or def.drawtype == "nodebox" then

					if rot >= 0 and rot <= 1 then
						roll = roll + math.pi
					else
						yaw = yaw + math.pi
					end
				end

				self.object:set_rotation({x = pitch, y = yaw, z = roll})

			elseif (def.drawtype == "mesh" and def.paramtype2 == "degrotate") then

				local p2 = (np2 - (def.place_param2 or 0)) % 240
				local yaw = (p2 / 240) * (math.pi * 2)

				self.object:set_yaw(yaw)

			elseif (def.drawtype == "mesh" and def.paramtype2 == "colordegrotate") then

				local p2 = (np2 % 32 - (def.place_param2 or 0) % 32) % 24
				local yaw = (p2 / 24) * (math.pi * 2)

				self.object:set_yaw(yaw)
			end
		end
	end,

	get_staticdata = function(self)

		return core.serialize({
			node = self.node,
			meta = self.meta
		})
	end,

	on_activate = function(self, staticdata)

		self.object:set_armor_groups({immortal = 1})
		self.object:set_acceleration({x = 0, y = -gravity, z = 0})

		local ds = core.deserialize(staticdata)

		if ds and ds.node then
			self:set_node(ds.node, ds.meta)

		elseif ds then
			self:set_node(ds)

		elseif staticdata ~= "" then
			self:set_node({name = staticdata})
		end
	end,

	-- incase falling entity is stuck, punching drops as item to recover
	on_punch = function(self, puncher, tflp, tool_caps, dir, damage)

		if puncher and puncher:is_player() then

			local drops = core.get_node_drops(self.node, "")

			for _, dropped_item in pairs(drops) do
				core.add_item(self.object:get_pos(), dropped_item)
			end

			self.object:remove()
		end
	end,

	on_step = function(self, dtime)

		-- used to simulate a little lag
		self.timer = (self.timer or 0) + dtime

		if self.timer < delay then
			return
		end

		self.timer = 0

		-- Set gravity and horizontal slowing
		self.object:set_acceleration({x = 0, y = -gravity, z = 0})

		local vel = self.object:get_velocity()

		vel.x = vel.x * 0.95
		vel.z = vel.z * 0.95

		if vel.x < 0.1 and vel.z < 0.1 then
			vel.x = 0
			vel.z = 0
		end

		self.object:set_velocity(vel)

		local pos = self.object:get_pos()

		-- Position of bottom center point
		local below_pos = {x = pos.x, y = pos.y - 0.7, z = pos.z}

		-- Check for player/mobs below falling node and hurt them >:D
		if node_fall_hurt then
			fall_hurt_check(self, below_pos)
		end

		--  check if falling node has custom function set
		local custom = core.registered_items[self.node.name]
				and core.registered_items[self.node.name].falling_step

		if custom and custom(self, pos, dtime + delay) == false then
			return -- skip further checks if false
		end

		-- Avoid bugs caused by an unloaded node below
		local below_node = core.get_node_or_nil(below_pos)

		-- Delete on contact with ignore at world edges or return if unloaded
		if not below_node then
			return

		elseif below_node.name == "ignore" then

			self.object:remove()

			return
		end

		local below_nodef = core.registered_nodes[below_node.name]

		-- Is it a level node we can add to?
		if below_nodef and below_nodef.leveled and below_node.name == self.node.name then

			local addlevel = self.node.level

			if not addlevel or addlevel <= 0 then
				addlevel = below_nodef.leveled
			end

			if core.add_node_level(below_pos, addlevel) == 0 then

				self.object:remove()

				return
			end
		end

		-- Stop node if it falls on walkable surface, or floats on water
		if (below_nodef and below_nodef.walkable == true)
		or (below_nodef
		and core.get_item_group(self.node.name, "float") ~= 0
		and below_nodef.liquidtype ~= "none") then

			self.object:set_velocity({x = 0, y = 0, z = 0})
		end

		-- Has the fallen node stopped moving ?
		if vector.equals(vel, {x = 0, y = 0, z = 0}) then

			local npos = self.object:get_pos()

			if not npos then return end

			-- Get node we've landed inside
			local cnode = core.get_node(npos)
			local cdef = core.registered_nodes[cnode.name]

			-- If air_equivalent or buildable_to or an attached_node then place
			--  node, otherwise drop falling node as an item instead.
			if ((cdef and cdef.air_equivalent == true)
			or (cdef and cdef.buildable_to == true)
			or (cdef and cdef.liquidtype ~= "none")
			-- only drop attached nodes if area not protected (torch, rails etc.)
			or (core.get_item_group(cnode.name, "attached_node") ~= 0))
			and not core.is_protected(npos, "") then

				-- Are we an attached node ? (grass, flowers, torch)
				if core.get_item_group(cnode.name, "attached_node") ~= 0 then

					-- Add drops from attached node
					local drops = core.get_node_drops(cnode.name, "")

					for _, dropped_item in pairs(drops) do
						core.add_item(npos, dropped_item)
					end

					-- Run script hook
					for _, callback in pairs(core.registered_on_dignodes) do
						callback(npos, cnode)
					end
				end

				-- Round position
				npos = vector.round(npos)

				-- Place falling entity as node and write any metadata
				core.add_node(npos, self.node)

				if self.meta then

					local meta = core.get_meta(npos)

					meta:from_table(self.meta)
				end

				-- Play placed sound
				local def = core.registered_nodes[self.node.name]

				if def.sounds and def.sounds.place and def.sounds.place.name then
					core.sound_play(def.sounds.place, {pos = npos}, true)
				end

				-- Just incase we landed on other falling nodes
				core.check_for_falling(npos)
			else
				-- Add drops from falling node
				local drops = core.get_node_drops(self.node, "")

				for _, dropped_item in pairs(drops) do
					core.add_item(npos, dropped_item)
				end
			end

			-- Remove falling entity if it cannot be placed
			self.object:remove()
		end
	end
})


--[[
core.override_item("default:gravel", {
	falling_step = function(self, pos, dtime)
		print ("Gravel falling!", dtime)
	end
})
]]


print("[MOD] Falling Item loaded")
