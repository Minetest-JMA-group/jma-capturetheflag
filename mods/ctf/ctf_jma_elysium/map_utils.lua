local storage = core.get_mod_storage()

local function serialize_inventory(t)
	local result = {}
	for list_name, stacks in pairs(t) do
		result[list_name] = {}
		for i, stack in ipairs(stacks) do
			result[list_name][i] = stack:to_string()
		end
	end
	return result
end

local function deserialize_inventory(t)
	local result = {}
	for list_name, strings in pairs(t) do
		result[list_name] = {}
		for i, str in ipairs(strings) do
			result[list_name][i] = ItemStack(str)
		end
	end
	return result
end

function ctf_jma_elysium.restore_nodemeta(mapname)
	local t = core.deserialize(storage:get_string("meta_" .. mapname))
	if not t then
		core.log("warning", "Failed to restore metadata for " .. mapname .. ": no metadata saved")
		return false
	end

	local mapdef = ctf_jma_elysium.maps[mapname]
	for saved_pos, saved in pairs(t) do
		saved_pos = vector.add(saved_pos, mapdef.pos1)

		local current_node = core.get_node(saved_pos)
		-- if current_node.name == saved.node_name or place then
		core.set_node(saved_pos, {
			name = saved.node_name,
			param1 = saved.param1 or 0,
			param2 = saved.param2 or 0,
		})

		local meta = core.get_meta(saved_pos)

		if saved.meta_fields then
			meta:from_table({fields = saved.meta_fields})
		end

		if saved.inventory then
			local inv = core.get_inventory({type="node", pos = saved_pos})
			if inv then
				local res = deserialize_inventory(saved.inventory)
				inv:set_lists(res)
			end
		end

		local def = core.registered_nodes[saved.node_name]
		if def._update then
			def._update(saved_pos)
		end

		core.log("action", "Restored node meta at: " .. core.pos_to_string(saved_pos))
		-- else
			-- core.log("warning", "Expected node '" .. (saved.node_name or "?") .. "' not found at: " .. core.pos_to_string(saved_pos))
		-- end
	end

	return true
end

function ctf_jma_elysium.save_meta(mapname)
	local mapdef = ctf_jma_elysium.maps[mapname]

	local pos1 = mapdef.pos1
	local pos2 = mapdef.pos2

	local minp = vector.new(
		math.min(pos1.x, pos2.x),
		math.min(pos1.y, pos2.y),
		math.min(pos1.z, pos2.z)
	)

	local maxp = vector.new(
		math.max(pos1.x, pos2.x),
		math.max(pos1.y, pos2.y),
		math.max(pos1.z, pos2.z)
	)

	local vm = VoxelManip()
	local emerged_min, emerged_max = vm:read_from_map(minp, maxp)
	local data = vm:get_data()
	local area = VoxelArea:new{MinEdge = emerged_min, MaxEdge = emerged_max}

	local count = 0
	local to_save = {}

	for index in area:iterp(minp, maxp) do
		local node_id = data[index]
		if node_id ~= core.CONTENT_IGNORE and node_id ~= core.CONTENT_AIR and
		node_id ~= core.CONTENT_UNKNOWN then

			local cpos = area:position(index)
			local meta = core.get_meta(cpos):to_table()
			local node = core.get_node(cpos)

			local t = {}
			local has_meta = false

			if next(meta.fields) then
				has_meta = true
				t.meta_fields = meta.fields
			end
			if next(meta.inventory) then
				has_meta = true
				t.inventory = serialize_inventory(meta.inventory)
			end

			if has_meta then
				t.node_name = node.name
				t.param1 = node.param1
				t.param2 = node.param2

				to_save[vector.subtract(cpos, mapdef.pos1)] = t
				count = count + 1
			end
		end
	end

	storage:set_string("meta_" .. mapname, core.serialize(to_save))
	return true, count
end

-- Replaces default nodes with ctf_map: variants (if exist)
-- For case of further editing of the map
function ctf_jma_elysium.replace_nodes_with_ctf_map(mapname)
	local mapdef = ctf_jma_elysium.maps[mapname]
	local pos1 = mapdef.pos1
	local pos2 = mapdef.pos2

	local minp = vector.new(
		math.min(pos1.x, pos2.x),
		math.min(pos1.y, pos2.y),
		math.min(pos1.z, pos2.z)
	)
	local maxp = vector.new(
		math.max(pos1.x, pos2.x),
		math.max(pos1.y, pos2.y),
		math.max(pos1.z, pos2.z)
	)

	local vm = VoxelManip()
	local emerged_min, emerged_max = vm:read_from_map(minp, maxp)
	local data = vm:get_data()
	local area = VoxelArea:new{MinEdge = emerged_min, MaxEdge = emerged_max}

	local replaced_count = 0
	local skipped_count = 0

	for index in area:iterp(minp, maxp) do
		local node_id = data[index]

		if node_id ~= core.CONTENT_IGNORE and node_id ~= core.CONTENT_AIR and
		   node_id ~= core.CONTENT_UNKNOWN then

			local node_name = core.get_name_from_content_id(node_id)

			if not string.match(node_name, "^ctf_map:") then
				local ctf_map_name = "ctf_map:" .. node_name:gsub("^[^:]+:", "")

				if core.registered_nodes[ctf_map_name] then
					data[index] = core.get_content_id(ctf_map_name)
					replaced_count = replaced_count + 1
				else
					skipped_count = skipped_count + 1
				end
			end
		end
	end

	vm:set_data(data)
	vm:write_to_map(true)

	return replaced_count, skipped_count
end

core.register_chatcommand("el_save_meta", {
	description = "Save metadata in the current map region",
	privs = {server = true},
	func = function(name, mapname)
		if not ctf_jma_elysium.loaded_maps[mapname] then
			return false, "The map does not exist or not loaded"
		end

		local result, count = ctf_jma_elysium.save_meta(mapname)
		if result then
			return true, "The nodes metadata has been saved to modstorage. Nodes count: " .. count
		end
		return false, "Failed to save"
	end
})

core.register_chatcommand("el_restore_meta", {
	description = "Restore node metadata",
	privs = {server = true},
	func = function(namem, mapname)
		if not ctf_jma_elysium.loaded_maps[mapname] then
			return false, "The map does not exist or not loaded"
		end

		ctf_jma_elysium.restore_nodemeta(mapname)
		return true, "Restored"
	end
})

local export_path = core.get_worldpath() .. "/maps_meta/"
minetest.mkdir(export_path) -- make sure the directory exists

core.register_chatcommand("el_meta", {
	params = "export|import <mapname>",
	description = "Export or import metadata of the map",
	privs = {server = true},
	func = function(name, param)
		local args = string.split(param, " ", false, 2)
		local action = args[1]
		local mapname = args[2]

		if not action or not mapname then
			return false, "Usage: /el_meta export|import <mapname>"
		end

		local path = export_path .. mapname .. ".meta"

		if action == "export" then
			local data = storage:get_string("meta_" .. mapname)
			if data == "" then
				return false, "No metadata saved, nothing to export"
			end

			local f = io.open(path, "w")
			if not f then return false, "Cannot open file for writing: " .. path end
			f:write(data)
			f:close()
			return true, "Exported metadata to " .. path

		elseif action == "import" then
			local f = io.open(path, "r")
			if not f then return false, "File not found: " .. path end

			local contents = f:read("*a")
			f:close()

			if type(core.deserialize(contents)) ~= "table" then
				return false, "Invalid metadata format"
			end

			storage:set_string("meta_" .. mapname, contents)
			ctf_jma_elysium.restore_nodemeta(mapname)
			return true, "Imported metadata from " .. path

		else
			return false, "Unknown action. Available actions: import, export"
		end
	end
})

core.register_chatcommand("el_get_area", {
	params = "<mapname>",
	description = "Show local coordinates of your WorldEdit selection for the given map",
	privs = {server = true},
	func = function(name, mapname)
		if not mapname or mapname == "" then
			return false, "Invalid map name"
		end
		local mapdef = ctf_jma_elysium.maps[mapname]
		if not mapdef then
			return false, "Map not found: " .. mapname
		end
		local we = worldedit.pos1[name] and worldedit.pos2[name] and worldedit
		if not we then
			return false, "You must select a region with WorldEdit first."
		end
		local pos1 = worldedit.pos1[name]
		local pos2 = worldedit.pos2[name]

		local local_min = vector.subtract(pos1, mapdef.pos1)
		local local_max = vector.subtract(pos2, mapdef.pos1)
		return true, string.format(
			"Local region: min (%d, %d, %d), max (%d, %d, %d)",
			local_min.x, local_min.y, local_min.z,
			local_max.x, local_max.y, local_max.z
		)
	end
})

core.register_chatcommand("el_replace_nodes", {
	description = "Replace all nodes in the current map region with ctf_map variants",
	privs = {server = true},
	func = function(name, mapname)
		if not ctf_jma_elysium.loaded_maps[mapname] then
			return false, "The map does not exist or not loaded"
		end

		local replaced_count, skipped_count = ctf_jma_elysium.replace_nodes_with_ctf_map(mapname)
		return true, "Nodes replacement completed. Replaced: " .. replaced_count .. ", Skipped: " .. skipped_count
	end
})