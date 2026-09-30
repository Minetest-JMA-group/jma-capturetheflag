local storage = core.get_mod_storage()
local S = core.get_translator(core.get_current_modname())
local BOX_MARGIN = 50 -- gap between the main map and the first box (in nodes)
local BOX_GAP = 100 -- gap between adjacent boxes (in nodes)
-- Step of the row of boxes. It has to fit the widest template, otherwise
-- boxes of different sizes placed in the same row would overlap.
-- Computed in register_box_template.
local BOX_ROW_STEP = 0

local RESPAWN_NODE_NAME = "ctf_jma_elysium:box_respawn"
local RESPAWN_NODE_ITEM = RESPAWN_NODE_NAME .. " 2"
-- Cooldown (in seconds) between respawn marker handouts for a box
local RESPAWN_ITEM_COOLDOWN_TIME = 60
-- local FORMNAME_WAIT = "ctf_jma_elysium:wait"

local PERSISTENT_KEY = "persistent_boxes" -- modstorage key for the box registry
local PERSISTENT_DIR = core.get_worldpath() .. "/elysium_boxes" -- packed .mts files
local PERSISTENT_PRIV = "pvpbox_persistent"

-- Idle persistent boxes are packed (saved to disk and removed from the map)
-- after this many seconds without members
local PERSISTENT_IDLE_PACK_TIME = 30 * 60
-- Empty non-persistent boxes are removed after this many seconds
local BOX_EMPTY_DESTROY_TIME = 10 * 60
-- Cooldown between PvP Box joins
local BOX_JOIN_COOLDOWN_TIME = 30
local BOX_JOIN_COOLDOWN = ctf_core.init_cooldowns()

core.mkdir(PERSISTENT_DIR)

core.register_privilege(PERSISTENT_PRIV, {
	description = "Allows creating persistent PvP Boxes",
	give_to_admin = true,
})

local IGNORE_OBJECTS = {
	"hpbar:entity",
	"wield3d:entity",
	"playertag:tag",
	"server_cosmetics:hat",
}

---Registers a map that can be used for PvP Boxes
---@param name string
---@param def table { file, bounds = {pos1, pos2}?, size = vector?, respawns = vector[], map_offset = vector?, barrier = string? }
function ctf_jma_elysium.register_box_template(name, def)
	local size = def.size
	if not size and def.bounds then
		size = {
			x = def.bounds.pos2.x - def.bounds.pos1.x + 1,
			y = def.bounds.pos2.y - def.bounds.pos1.y + 1,
			z = def.bounds.pos2.z - def.bounds.pos1.z + 1,
		}
	elseif not size then
		size = ctf_jma_elysium.read_mts_size(def.file)
	end

	if not size then
		core.log(
			"error",
			"[ctf_jma_elysium] Failed to detect size of PvP Box map: " .. name
		)
		return
	end

	local bounds = def.bounds or {
		pos1 = { x = 0, y = 0, z = 0 },
		pos2 = { x = size.x - 1, y = size.y - 1, z = size.z - 1 },
	}
	local respawns = def.respawns
	if #respawns < 2 then
		core.log(
			"error",
			"[ctf_jma_elysium] PvP Box map "
				.. name
				.. " must define at least two respawn positions"
		)
		return
	end

	ctf_jma_elysium.box_templates[name] = {
		name = name,
		file = def.file,
		size = size,
		bounds = {
			pos1 = { x = bounds.pos1.x, y = bounds.pos1.y, z = bounds.pos1.z },
			pos2 = { x = bounds.pos2.x, y = bounds.pos2.y, z = bounds.pos2.z },
		},
		respawns = def.respawns,
		map_offset = def.map_offset or { x = 0, y = 0, z = 0 },
		barrier = def.barrier,
		meta_key = "box_" .. name,
	}

	-- The row step has to fit every registered template
	BOX_ROW_STEP = math.max(BOX_ROW_STEP, size.x + BOX_GAP)

	core.log(
		"action",
		string.format(
			"[ctf_jma_elysium] Registered PvP Box map: %s (%d x %d x %d)",
			name,
			size.x,
			size.y,
			size.z
		)
	)
end

function ctf_jma_elysium.get_box_templates()
	local names = {}
	for name in pairs(ctf_jma_elysium.box_templates) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

---Finds the lowest box id that is not in use. The id doubles as the place of
---the box in the row, so freed ids are reused instead of growing forever.
---@return integer
function ctf_jma_elysium.allocate_box_id()
	local id = 0
	repeat
		id = id + 1
	until not ctf_jma_elysium.boxes[id] and not ctf_jma_elysium.box_reserved_ids[id]

	return id
end

-- Computes the absolute region of the box with the given id.
-- Boxes are placed in a row next to the main Elysium map along +X, so the
-- region is a pure function of the id and never overlaps another box.
local function compute_box_region(tmpl, id)
	local main = ctf_jma_elysium.maps.main

	local origin = {
		x = main.pos2.x + BOX_MARGIN + (id - 1) * BOX_ROW_STEP,
		y = main.pos1.y,
		z = main.pos1.z,
	}

	return vector.add(origin, tmpl.bounds.pos1), vector.add(origin, tmpl.bounds.pos2)
end

function ctf_jma_elysium.get_box_by_player(name)
	local ctx = ctf_jma_elysium.players[name]
	if ctx and ctx.box then
		return ctf_jma_elysium.boxes[ctx.box]
	end
	return nil
end

---Finds the PvP Box that contains the given position (if any)
---@param pos vector
---@return table|nil
function ctf_jma_elysium.get_box_at(pos)
	for _, box in pairs(ctf_jma_elysium.boxes) do
		if ctf_core.pos_inside(pos, box.pos1, box.pos2) then
			return box
		end
	end
	return nil
end

-- Finds a box the player is a member of. Unlike get_box_by_player it does not
-- rely on the Elysium context, so it also works on disconnect.
local function find_box_by_member(name)
	for _, box in pairs(ctf_jma_elysium.boxes) do
		if box.members[name] then
			return box
		end
	end
	return nil
end

-- Finds a box owned by the player, even if the player is not inside it.
-- Needed to manage orphaned persistent boxes.
local function get_owned_box(name)
	for _, box in pairs(ctf_jma_elysium.boxes) do
		if box.owner == name then
			return box
		end
	end
	return nil
end

-- Finds a box of the given kind owned by the player (even if not inside it).
-- A player may own one persistent and one regular box at the same time.
local function get_owned_box_of_kind(name, persistent)
	for _, box in pairs(ctf_jma_elysium.boxes) do
		if box.owner == name and box.persistent == persistent then
			return box
		end
	end
	return nil
end

-- Finds a box owned by the player that contains the given player
-- (as a member, or as a former member of a persistent box)
local function find_owned_box_with_member(name, target)
	for _, box in pairs(ctf_jma_elysium.boxes) do
		if
			box.owner == name
			and (
				box.members[target]
				or (box.persistent and box.former_members[target])
			)
		then
			return box
		end
	end
	return nil
end

-- Finds a box owned by the player that has a pending join request from target
local function find_owned_box_with_request(name, target)
	for _, box in pairs(ctf_jma_elysium.boxes) do
		if box.owner == name and box.requests and box.requests[target] then
			return box
		end
	end
	return nil
end

---Remembers a respawn marker position in the box context
---@param box table
---@param pos vector
function ctf_jma_elysium.add_box_respawn_node(box, pos)
	if not box or not pos then
		return
	end

	box.respawn_nodes = box.respawn_nodes or {}
	box.respawn_nodes[core.pos_to_string(pos)] = vector.new(pos.x, pos.y, pos.z)
end

---Forgets a respawn marker position in the box context
---@param box table
---@param pos vector
function ctf_jma_elysium.remove_box_respawn_node(box, pos)
	if not box or not box.respawn_nodes or not pos then
		return
	end

	box.respawn_nodes[core.pos_to_string(pos)] = nil
end

---Rebuilds the respawn markers of the box from the world. Called once when the
---box area is (re)placed, not on respawn.
---@param box table
function ctf_jma_elysium.scan_box_respawn_nodes(box)
	if not box then
		return
	end

	box.respawn_nodes = {}
	local positions =
		core.find_nodes_in_area(box.pos1, box.pos2, { RESPAWN_NODE_NAME })
	for _, pos in ipairs(positions) do
		box.respawn_nodes[core.pos_to_string(pos)] =
			vector.new(pos.x, pos.y, pos.z)
	end
end

---Returns the respawn positions of the box: one node above every marker the
---owner placed. The box area has to be loaded.
---@param box table
---@return vector[]
function ctf_jma_elysium.get_box_respawn_nodes(box)
	local list = {}
	for _, pos in pairs(box.respawn_nodes or {}) do
		local above = { x = pos.x, y = pos.y + 1, z = pos.z }
		local first = core.get_node(above).name
		local second =
			core.get_node({ x = pos.x, y = pos.y + 2, z = pos.z }).name
		local first_def = core.registered_nodes[first]
		local second_def = core.registered_nodes[second]

		-- The player is spawned on top of the marker and needs headroom
		if
			core.get_node(pos).name == RESPAWN_NODE_NAME
			and not (first_def and first_def.walkable)
			and not (second_def and second_def.walkable)
		then
			table.insert(list, above)
		end
	end

	table.sort(list, function(a, b)
		if a.y ~= b.y then
			return a.y < b.y
		end
		if a.z ~= b.z then
			return a.z < b.z
		end
		return a.x < b.x
	end)

	return list
end

---Picks the valid respawn point nearest to the player's current position.
---@param box table
---@param name string
---@param target_pos vector|nil
---@return vector|nil
function ctf_jma_elysium.select_box_spawn(box, name, target_pos)
	local respawns = ctf_jma_elysium.get_box_respawn_nodes(box)
	if not respawns or not respawns[1] then
		return nil
	end

	local player = PlayerObj(name)
	target_pos = player:get_pos()
	if not target_pos then
		return nil
	end
	local nearest, nearest_distance
	for _, pos in ipairs(respawns) do
		local distance = vector.distance(target_pos, pos)
		if not nearest_distance or distance < nearest_distance then
			nearest = pos
			nearest_distance = distance
		end
	end

	return nearest
end

local function teleport_to_box_spawn(player, box, name, pos)
	local middle = vector.multiply(vector.add(box.pos1, box.pos2), 0.5)

	local function apply()
		local p = PlayerObj(name)
		if not p or ctf_jma_elysium.get_box_by_player(name) ~= box then
			return
		end

		p:set_pos(pos)
		p:set_velocity(vector.zero())

		local dist2d = vector.distance({ x = pos.x, y = 0, z = pos.z },
			{ x = middle.x, y = 0, z = middle.z })

		if dist2d > 0.1 then
			p:set_look_vertical(0)
			p:set_look_horizontal(
				vector.dir_to_rotation(vector.direction(pos, middle)).y
			)
		end
	end

	apply()
	core.after(0.1, apply)
end

---Returns the respawn point of the PvP Box the player is currently in
---@param player string|ObjectRef
---@return vector|nil
function ctf_jma_elysium.get_box_spawn(player)
	local name = PlayerName(player)
	local box = ctf_jma_elysium.get_box_by_player(name)
	if not box then
		return nil
	end

	return ctf_jma_elysium.select_box_spawn(box, name)
end

---Puts the player on one of the respawn points of the box he is inside.
---Used after death, when the respawn delay is over.
---@param player ObjectRef
---@param death_pos vector|nil
---@return boolean
function ctf_jma_elysium.respawn_player(player, death_pos)
	local name = player:get_player_name()

	local sprint_info = sprint.get_sprint_info(name)
	sprint_info.stamina = sprint.get_max_stamina(name)

	local box = ctf_jma_elysium.get_box_by_player(name)
	if not box then
		return false
	end

	local pos = ctf_jma_elysium.select_box_spawn(box, name, death_pos)
	if not pos then
		if not death_pos then
			return false
		end
		core.chat_send_player(
			name,
			S("[PvP Box] No valid respawn markers; respawning you to where you died...")
		)
		teleport_to_box_spawn(player, box, name, death_pos)
		return true
	end

	teleport_to_box_spawn(player, box, name, pos)
	return true
end

function ctf_jma_elysium.box_broadcast(box, msg, exclude)
	for mname in pairs(box.members) do
		if mname ~= exclude then
			core.chat_send_player(mname, msg)
		end
	end
end

-- Absolute path of the box's saved .mts file
local function persistent_box_path(box)
	if box.persistent and box.file then
		return box.file
	end
	return PERSISTENT_DIR .. "/" .. box.id .. ".mts"
end

local function has_meta(key)
	return storage:get_string("meta_" .. key) ~= ""
end

-- Fills a closed barrier shell (4 walls + floor + ceiling) into a VoxelManip
-- data array. minp/maxp are the outer corners of the shell; the interior
-- (one node inside) is left untouched.
local function paint_barrier_shell(node_data, param2_data, area, minp, maxp, bid)
	local function put(x, y, z)
		local vi = area:index(x, y, z)
		node_data[vi] = bid
		param2_data[vi] = 0
	end

	for y = minp.y, maxp.y do
		for z = minp.z, maxp.z do
			put(minp.x, y, z)
			put(maxp.x, y, z)
		end
		for x = minp.x, maxp.x do
			put(x, y, minp.z)
			put(x, y, maxp.z)
		end
	end

	for x = minp.x, maxp.x do
		for z = minp.z, maxp.z do
			put(x, minp.y, z)
			put(x, maxp.y, z)
		end
	end
end

-- Places a .mts schematic using VoxelManip.
-- core.place_schematic caches schematics by filename in the engine and can
-- therefore place stale data for files that were rewritten on disk, so the
-- nodes are read with core.read_schematic and written directly.
-- The flat data array is ordered with x fastest, then y, then z:
--   index = x + size.x * (y + size.y * z)
---@param pos vector Absolute position of the schematic's min corner
---@param path string Path of the .mts file
---@param barrier_node string|nil Node placed as a closed shell one node outside the schematic
---@return boolean
local function place_schematic_vm(pos, path, barrier_node)
	-- The file may be missing, empty or corrupted (never saved, removed
	-- manually, truncated by a crash, ...)
	local file = io.open(path, "rb")
	if not file then
		core.log("error", "[ctf_jma_elysium] Schematic file not found: " .. path)
		return false
	end

	local header = file:read(4) or ""
	file:close()

	if header ~= "MTSM" then
		core.log(
			"error",
			"[ctf_jma_elysium] Schematic file is empty or corrupted: " .. path
		)
		return false
	end

	local schem_ok, schem = pcall(
		core.read_schematic,
		path,
		{ write_yslice_prob = "none" }
	)
	if
		not schem_ok
		or type(schem) ~= "table"
		or not schem.size
		or not schem.data
	then
		core.log("error", "[ctf_jma_elysium] Failed to read schematic: " .. path)
		return false
	end

	local size = schem.size
	local data = schem.data

	-- When a barrier is requested the VoxelManip region is grown by one node
	-- on every side so the shell lies just outside the schematic
	local pad = barrier_node and 1 or 0
	local minp = {
		x = pos.x - pad,
		y = pos.y - pad,
		z = pos.z - pad,
	}
	local maxp = {
		x = pos.x + size.x - 1 + pad,
		y = pos.y + size.y - 1 + pad,
		z = pos.z + size.z - 1 + pad,
	}

	local vm = VoxelManip()
	local emin, emax = vm:read_from_map(minp, maxp)
	local area = VoxelArea:new({ MinEdge = emin, MaxEdge = emax })

	local node_data = vm:get_data()
	local param2_data = vm:get_param2_data()

	local i = 0
	for z = 0, size.z - 1 do
		for y = 0, size.y - 1 do
			for x = 0, size.x - 1 do
				i = i + 1

				local entry = data[i]
				local name, param2

				if type(entry) == "table" then
					name = entry.name
					param2 = entry.param2

					-- Only "never place" (prob 0) is honoured: the schematics
					-- used for PvP Boxes always place every node
					if entry.prob == 0 then
						name = nil
					end
				elseif type(entry) == "number" then
					name = core.get_name_from_content_id(entry)
				end

				if name and name ~= "ignore" then
					local vi = area:index(pos.x + x, pos.y + y, pos.z + z)
					node_data[vi] = core.get_content_id(name)
					param2_data[vi] = param2 or 0
				end
			end
		end
	end

	if barrier_node then
		local bid = core.get_content_id(barrier_node)
		if bid then
			paint_barrier_shell(node_data, param2_data, area, minp, maxp, bid)
		end
	end

	vm:set_data(node_data)
	vm:set_param2_data(param2_data)
	vm:update_liquids()
	vm:write_to_map(true)
	vm:close()

	return true
end

---Saves the registry of persistent boxes to modstorage
function ctf_jma_elysium.save_persistent_registry()
	local t = {}
	for _, box in pairs(ctf_jma_elysium.boxes) do
		if box.persistent then
			t[tostring(box.id)] = {
				template = box.name,
				owner = box.owner,
				former_members = box.former_members,
				pos1 = box.pos1,
				pos2 = box.pos2,
				active = box.active,
			}
		end
	end
	storage:set_string(PERSISTENT_KEY, core.serialize(t))
end

---Restores persistent boxes from modstorage. Schematics are NOT placed here.
function ctf_jma_elysium.load_persistent_registry()
	local data = core.deserialize(storage:get_string(PERSISTENT_KEY))
	if type(data) ~= "table" then
		return
	end

	local count = 0
	local broken = 0
	for id_str, entry in pairs(data) do
		local id = tonumber(id_str)
		local tmpl = type(entry) == "table"
			and entry.template
			and ctf_jma_elysium.box_templates[entry.template]
		-- Ids are 1-based: entries with id 0 come from the older 0-based
		-- registry format and are dropped (together with their files)
		if id and id > 0 and tmpl then
			local pos1, pos2 = entry.pos1, entry.pos2
			if not pos1 or not pos2 then
				pos1, pos2 = compute_box_region(tmpl, id)
			end

			local box = {
				id = id,
				name = entry.template,
				owner = entry.owner or "",
				members = {},
				invites = {},
				requests = {},
				order = {},
				former_members = entry.former_members or {},
				pos1 = pos1,
				pos2 = pos2,
				respawn_nodes = {},
				template_file = tmpl.file,
				-- Points to the saved file this box is restored from
				file = PERSISTENT_DIR .. "/" .. id .. ".mts",
				map_offset = tmpl.map_offset,
				barrier = tmpl.barrier,
				meta_key = "box_persistent_" .. id,
				persistent = true,
				active = entry.active ~= false,
			}

			ctf_jma_elysium.boxes[id] = box

			-- The pack timer is started only when players actually leave the
			-- box, not on startup
			count = count + 1
		else
			-- Broken entry (unknown map template): drop it together with its
			-- saved file and metadata
			broken = broken + 1
			core.log(
				"warning",
				string.format(
					"[ctf_jma_elysium] Removing broken persistent PvP Box entry #%s",
					tostring(id_str)
				)
			)

			if id then
				os.remove(PERSISTENT_DIR .. "/" .. id .. ".mts")
				storage:set_string("meta_box_persistent_" .. id, "")
			end
		end
	end

	if broken > 0 then
		ctf_jma_elysium.save_persistent_registry()
	end

	core.log(
		"action",
		string.format(
			"[ctf_jma_elysium] Restored %d persistent PvP Box(es), removed %d broken",
			count,
			broken
		)
	)
end

---Schedules packing of an idle persistent box. The timer is cancelled if a
---player joins the box again before it fires.
---@param box table
function ctf_jma_elysium.schedule_box_pack(box)
	if not box or not box.persistent or not box.active or box.pack_timer then
		return
	end

	box.pack_at = os.time() + PERSISTENT_IDLE_PACK_TIME
	box.pack_timer = core.after(PERSISTENT_IDLE_PACK_TIME, function()
		box.pack_timer = nil
		box.pack_at = nil

		if next(box.members) then
			return
		end

		ctf_jma_elysium.pack_box(box)
	end)
end

---Cancels a scheduled pack of the box (if any)
---@param box table
function ctf_jma_elysium.cancel_box_pack(box)
	if not box then
		return
	end

	if box.pack_timer then
		box.pack_timer:cancel()
		box.pack_timer = nil
	end
	box.pack_at = nil
end

---@param name string
---@param box table
---@param queue boolean|nil Force queueing the message
local function warn_box_removal(name, box, queue)
	if not name or name == "" then
		return
	end

	local msg = S(
		"[PvP Box] PvP Box #@1 will be deleted in @2 minutes unless a former member joins it again.",
		box.id,
		math.floor(BOX_EMPTY_DESTROY_TIME / 60)
	)

	if not queue and core.get_player_by_name(name) then
		core.chat_send_player(name, msg)
	else
		ctf_jma_elysium.box_warnings[name] = msg
	end
end

---Schedules removal of an empty non-persistent box. The timer is cancelled if
---a player joins the box again before it fires.
---@param box table
function ctf_jma_elysium.schedule_box_destroy(box)
	if not box or box.persistent or box.destroy_timer then
		return
	end

	box.destroy_at = os.time() + BOX_EMPTY_DESTROY_TIME
	box.destroy_timer = core.after(BOX_EMPTY_DESTROY_TIME, function()
		box.destroy_timer = nil
		box.destroy_at = nil

		if next(box.members) then
			return
		end

		ctf_jma_elysium.destroy_box(box)
	end)
end

---Cancels a scheduled removal of the box (if any)
---@param box table
function ctf_jma_elysium.cancel_box_destroy(box)
	if not box then
		return
	end

	if box.destroy_timer then
		box.destroy_timer:cancel()
		box.destroy_timer = nil
	end
	box.destroy_at = nil
end

---@param box table
---@return boolean
function ctf_jma_elysium.save_box_to_disk(box)
	if not box or not box.persistent or not box.active then
		return false
	end

	-- .mts does not store node metadata, so keep it in modstorage
	ctf_jma_elysium.save_meta(box.meta_key, box.pos1, box.pos2, box.pos1)

	local path = persistent_box_path(box)

	if not core.create_schematic(box.pos1, box.pos2, nil, path) then
		core.log(
			"error",
			"[ctf_jma_elysium] Failed to save PvP Box #" .. box.id
		)
		return false
	end

	core.log(
		"action",
		string.format(
			"[ctf_jma_elysium] PvP Box #%d saved to %s",
			box.id,
			path
		)
	)
	return true
end

-- Region to clear when dropping a box from the world. Includes the barrier
-- shell, which sits one node outside the box bounds.
---@param box table
---@return vector, vector
local function box_delete_region(box)
	if box.barrier then
		return vector.offset(box.pos1, -1, -1, -1),
			vector.offset(box.pos2, 1, 1, 1)
	end
	return box.pos1, box.pos2
end

---Packs a persistent box: stores its nodes to a .mts file plus metadata,
---then clears the area from the world.
---@param box table
function ctf_jma_elysium.pack_box(box)
	if not box or not box.persistent or box.packing or not box.active then
		return
	end
	-- Never pack a box that is in use
	if next(box.members) then
		return
	end
	ctf_jma_elysium.cancel_box_pack(box)
	box.packing = true

	ctf_map.emerge_with_callbacks(nil, box.pos1, box.pos2, function()
		-- The box may have been removed while the area was emerging
		if box._destroyed or ctf_jma_elysium.boxes[box.id] ~= box then
			box.packing = false
			return
		end

		if not ctf_jma_elysium.save_box_to_disk(box) then
			box.packing = false
			return
		end

		core.delete_area(box_delete_region(box))

		box.active = false
		box.packing = false
		ctf_jma_elysium.save_persistent_registry()

		core.log(
			"action",
			string.format("[ctf_jma_elysium] PvP Box #%d packed", box.id)
		)
	end)
end

-- Emerges the box region (slightly padded) so the area is loaded before a
-- player is teleported into it
---@param box table
---@param callback function
local function emerge_box(box, callback)
	local p1 = { x = box.pos1.x - 1, y = box.pos1.y - 1, z = box.pos1.z - 1 }
	local p2 = { x = box.pos2.x + 1, y = box.pos2.y + 1, z = box.pos2.z + 1 }

	ctf_map.emerge_with_callbacks(nil, p1, p2, callback)
end

---Places the packed box data into the world. The area must be emerged.
---A box that cannot be restored is considered broken and removed.
---@param box table
---@return boolean
local function place_box_data(box)
	-- The box may have been removed while the area was emerging
	if box._destroyed or ctf_jma_elysium.boxes[box.id] ~= box then
		core.log(
			"warning",
			string.format(
				"[ctf_jma_elysium] PvP Box #%d was removed while it was being restored",
				box.id
			)
		)
		return false
	end

	local path = persistent_box_path(box)
	local ok, placed = pcall(
		place_schematic_vm,
		vector.add(box.pos1, box.map_offset),
		path,
		box.barrier
	)
	if not ok or not placed then
		core.log(
			"error",
			string.format(
				"[ctf_jma_elysium] Failed to load PvP Box #%d from %s%s. Removing the broken box.",
				box.id,
				path,
				ok and "" or (": " .. tostring(placed))
			)
		)

		-- A persistent box that cannot be restored is broken: remove it
		ctf_jma_elysium.destroy_box(box)
		return false
	end

	if has_meta(box.meta_key) then
		ctf_jma_elysium.restore_nodemeta(box.meta_key, box.pos1)
	end

	box.active = true

	-- Seed the respawn markers that came with the saved map
	ctf_jma_elysium.scan_box_respawn_nodes(box)

	ctf_jma_elysium.save_persistent_registry()

	core.log(
		"action",
		string.format(
			"[ctf_jma_elysium] PvP Box #%d unpacked from %s",
			box.id,
			path
		)
	)
	return true
end

---Unpacks a persistent box: places its .mts and restores metadata.
---@param box table
---@param callback fun(ok: boolean)
function ctf_jma_elysium.unpack_box(box, callback)
	if not box or not box.persistent or box.active then
		callback(true)
		return
	end

	emerge_box(box, function()
		callback(place_box_data(box))
	end)
end

---Checks whether the box actually exists in the world.
---The registry flag may be stale (interrupted save, crash, older registry
---format, ...), so the ground below the box spawn is inspected directly.
---@param box table
---@return boolean
local function box_area_present(box)
	local spawn = {
		x = math.floor((box.pos1.x + box.pos2.x) / 2),
		y = box.pos1.y + 1,
		z = math.floor((box.pos1.z + box.pos2.z) / 2),
	}

	for y = spawn.y, box.pos1.y - 1, -1 do
		local node = core.get_node({ x = spawn.x, y = y, z = spawn.z })
		local def = core.registered_nodes[node.name]
		if def and def.walkable then
			return true
		end
	end

	return false
end

-- Re-arms the idle timer of an empty box (used when a join attempt fails)
---@param box table
local function restore_idle_timer(box)
	if not box or next(box.members) then
		return
	end

	if box.persistent then
		ctf_jma_elysium.schedule_box_pack(box)
	else
		ctf_jma_elysium.schedule_box_destroy(box)
	end
end

-- Makes sure the box area is loaded (and unpacked if needed), then runs the
-- callback. The area must be emerged before the player is teleported into it,
-- even when the box is already present in the world.
local function activate_box(box, callback)
	-- A player is coming back, so stop any pending pack/removal
	ctf_jma_elysium.cancel_box_pack(box)
	ctf_jma_elysium.cancel_box_destroy(box)

	emerge_box(box, function()
		if not box.persistent then
			callback(true)
			return
		end

		local present = box.active and box_area_present(box) or false

		if box.active then
			core.log(
				"action",
				string.format(
					"[ctf_jma_elysium] PvP Box #%d join: active=true, area present=%s",
					box.id,
					tostring(present)
				)
			)
		end

		if present then
			callback(true)
			return
		end

		if box.active then
			core.log(
				"warning",
				string.format(
					"[ctf_jma_elysium] PvP Box #%d area is missing, restoring from %s",
					box.id,
					persistent_box_path(box)
				)
			)
		end

		callback(place_box_data(box))
	end)
end

---Drops the invite the player received (if any), wherever it came from
---@param name string
local function clear_box_invite(name)
	local box = ctf_jma_elysium.boxes[ctf_jma_elysium.box_invites[name] or -1]
	if box then
		box.invites[name] = nil
	end

	ctf_jma_elysium.box_invites[name] = nil
	local timer = ctf_jma_elysium.box_invite_timers[name]
	if timer then
		timer:cancel()
		ctf_jma_elysium.box_invite_timers[name] = nil
	end
end

---Schedules the expiry of a pending invite: it lives one minute
---@param box table
---@param name string
local function schedule_box_invite_expiry(box, name)
	local timer
	timer = core.after(ctf_jma_elysium.INVITE_TIMEOUT_SECONDS, function()
		-- A newer invite of that player has replaced this one already
		if ctf_jma_elysium.box_invite_timers[name] ~= timer then
			return
		end
		ctf_jma_elysium.box_invite_timers[name] = nil

		if ctf_jma_elysium.box_invites[name] ~= box.id then
			return
		end

		clear_box_invite(name)

		core.chat_send_player(
			name,
			S(
				"[PvP Box] The invite from @1 expired. Ask the owner for a new one.",
				box.owner
			)
		)

		if PlayerObj(box.owner) then
			core.chat_send_player(
				box.owner,
				S("[PvP Box] Your invite to @1 expired.", name)
			)
		end
	end)

	ctf_jma_elysium.box_invite_timers[name] = timer
end

---Adds a player to the box, clears their pending invite/request and remembers
---them as a former member (needed for persistent boxes).
---@param box table
---@param name string
function ctf_jma_elysium.add_box_member(box, name)
	local player =PlayerObj(name)
	box.members[name] = true
	box.requests[name] = nil
	-- A player in a box cannot use an invite (to this or any other box) anymore
	box.invites[name] = nil
	clear_box_invite(name)
	ctf_jma_elysium.box_requests[name] = nil
	box.former_members[name] = true
	table.insert(box.order, name)

	-- The PvP switch is not usable inside a box, so take it away for now
	local items = {
		"ctf_jma_elysium:pvp_on",
		"ctf_jma_elysium:pvp_off",
	}

	local inv = player and player:get_inventory()
	if inv then
		for _, item in ipairs(items) do
			if inv:contains_item("main", item) then
				inv:remove_item("main", item)
				break
			end
		end
	end

	-- Someone is back, so cancel a pending pack/removal
	ctf_jma_elysium.cancel_box_destroy(box)

	if box.persistent then
		ctf_jma_elysium.cancel_box_pack(box)
		ctf_jma_elysium.save_persistent_registry()
	end
end

---Removes a player from the box and returns them to the Elysium spawn.
---Destroys the box when it becomes empty. Ownership is not transferred here;
---use the /box transfer command for that.
---@param box table
---@param name string
---@param opts table|nil { message = string?, broadcast = string?, no_transfer = boolean?, queue_warning = boolean? }
---@return boolean destroyed
function ctf_jma_elysium.remove_box_member(box, name, opts)
	opts = opts or {}

	box.members[name] = nil
	box.invites[name] = nil
	-- table_remove_value(box.order, name)
	local to_remove_idx = table.indexof(box.order, name)
	if to_remove_idx ~= -1 then
		table.remove(box.order, to_remove_idx)
	end

	local ctx = ctf_jma_elysium.players[name]
	if ctx and ctx.box == box.id then
		ctx.box = nil
		ctx.location = "main"
	end

	-- The kill list switches back to the feed of Elysium
	ctf_kill_list.update_player(name)

	local player = PlayerObj(name)
	if player then
		ctf_jma_elysium.set_pvp_mode(player, false)
		player:set_pos(ctf_jma_elysium.maps.main.spawn_abs)
	end

	local inv = player and player:get_inventory()
	if
		inv
		and not inv:contains_item("main", "ctf_jma_elysium:pvp_on")
		and not inv:contains_item("main", "ctf_jma_elysium:pvp_off")
	then
		-- PvP is switched off when leaving a box
		inv:add_item("main", "ctf_jma_elysium:pvp_off")
	end

	if opts.message then
		core.chat_send_player(name, opts.message)
	end

	if not next(box.members) then
		if opts.no_transfer then
			-- destroy_box is in charge of the removal
			return true
		end

		if box.persistent then
			-- Persistent boxes are kept as orphans and packed only after a
			-- period of inactivity
			ctf_jma_elysium.schedule_box_pack(box)
		else
			-- Keep the box in the world for a while so the last player can
			-- come back, then remove it
			ctf_jma_elysium.schedule_box_destroy(box)
			warn_box_removal(name, box, opts.queue_warning)
		end
		return true
	end

	if opts.broadcast then
		ctf_jma_elysium.box_broadcast(box, opts.broadcast, name)
	end

	if box.persistent then
		ctf_jma_elysium.save_persistent_registry()
	end

	return false
end

---Moves every member out of the box and removes the box area from the world
---@param box table
function ctf_jma_elysium.destroy_box(box)
	if not box or box._destroyed then
		return
	end
	box._destroyed = true
	ctf_jma_elysium.cancel_box_pack(box)
	ctf_jma_elysium.cancel_box_destroy(box)

	-- Copy the list first: it is modified while iterating
	local members = table.copy(box.order)
	for _, mname in ipairs(members) do
		ctf_jma_elysium.remove_box_member(box, mname, {
			message = S("[PvP Box] The PvP Box was deleted."),
			no_transfer = true,
		})
	end

	for iname in pairs(box.invites) do
		if ctf_jma_elysium.box_invites[iname] == box.id then
			clear_box_invite(iname)
		end
	end
	box.invites = {}

	if box.requests then
		for rname in pairs(box.requests) do
			ctf_jma_elysium.box_requests[rname] = nil
		end
		box.requests = {}
	end

	-- Drop leftover entities inside the box
	for _, obj in pairs(core.get_objects_in_area(box.pos1, box.pos2)) do
		if not obj:is_player() then
			local luaent = obj:get_luaentity()
			if luaent and table.indexof(IGNORE_OBJECTS, luaent.name) == -1 then
				obj:remove()
			end
		end
	end

	core.delete_area(box_delete_region(box))

	if box.persistent then
		os.remove(persistent_box_path(box))
		storage:set_string("meta_" .. box.meta_key, "")
	end

	ctf_jma_elysium.boxes[box.id] = nil
	ctf_jma_elysium.box_reserved_ids[box.id] = nil

	-- Ids are reused, so every stale reference to the removed box is dropped
	for pname, bid in pairs(ctf_jma_elysium.box_invites) do
		if bid == box.id then
			ctf_jma_elysium.box_invites[pname] = nil
		end
	end

	for pname, bid in pairs(ctf_jma_elysium.box_requests) do
		if bid == box.id then
			ctf_jma_elysium.box_requests[pname] = nil
		end
	end

	if box.persistent then
		ctf_jma_elysium.save_persistent_registry()
	end

	core.log(
		"action",
		string.format(
			"[ctf_jma_elysium] PvP Box %d (%s) destroyed",
			box.id,
			box.name
		)
	)
end

---Removes a player from their PvP Box (if any). Used when leaving Elysium.
---@param name string
---@return boolean
function ctf_jma_elysium.remove_from_box(name)
	-- Drop a pending invite this player received (if any)
	clear_box_invite(name)
	ctf_jma_elysium.box_creating[name] = nil

	-- Drop a pending join request this player sent (if any)
	local requested_box = ctf_jma_elysium.boxes[ctf_jma_elysium.box_requests[name] or -1]
	if requested_box and requested_box.requests then
		requested_box.requests[name] = nil
	end
	ctf_jma_elysium.box_requests[name] = nil

	local box = ctf_jma_elysium.get_box_by_player(name) or find_box_by_member(name)
	if not box then
		return false
	end

	ctf_jma_elysium.remove_box_member(box, name, {
		broadcast = S("@1 left the PvP Box.", name),
	})
	return true
end

---Adds a player to the box and teleports them inside. Shared by
---accept/approve/join. Expects the caller to have validated the player state.
---@param player ObjectRef|nil
---@param name string
---@param box table
---@return boolean
local function join_box(player, name, box)
	-- Failed join: close the loading screen and re-arm the idle timer
	local function fail(msg)
		ctf_jma_elysium.close_wait_formspec(name)
		if msg then
			core.chat_send_player(name, msg)
		end
		restore_idle_timer(box)
		return false
	end

	if not player or not player:is_player() then
		return fail()
	end

	local ctx = ctf_jma_elysium.players[name]
	if not ctx then
		return fail(
			S("You must be in Elysium to join a PvP Box. Use /elysium first.")
		)
	end

	if ctx.box then
		return fail(S("You are already in a PvP Box."))
	end

	if player:get_hp() <= 0 then
		return fail(S("You cannot join a PvP Box while dead."))
	end

	if player:get_attach() then
		return fail(S("You cannot join a PvP Box right now."))
	end

	ctf_jma_elysium.add_box_member(box, name)
	ctx.box = box.id
	ctx.location = "box:" .. box.id
	ctf_jma_elysium.set_pvp_mode(player, true)

	-- The kill list switches to the feed of the box
	ctf_kill_list.update_player(player)

	local spawn = ctf_jma_elysium.select_box_spawn(box, name)
	if not spawn then
		ctf_jma_elysium.remove_box_member(box, name)
		return fail(S("Failed to find a respawn point inside the box."))
	end

	teleport_to_box_spawn(player, box, name, spawn)

	-- Close the loading screen and start the join cooldown
	ctf_jma_elysium.close_wait_formspec(name)
	BOX_JOIN_COOLDOWN:set(player, BOX_JOIN_COOLDOWN_TIME)

	core.chat_send_player(name, S("You joined the PvP Box."))
	if box.persistent then
		core.chat_send_player(
			name,
			core.colorize(
				"#00ff00",
				S(
					"Persistent Box mode: This box will be saved automatically and can survive server restarts. Owner: @1",
					box.owner
				)
			)
		)
	end
	ctf_jma_elysium.box_broadcast(
		box,
		S("@1 joined the PvP Box.", name),
		name
	)
	return true
end

---Shows the loading screen, makes sure the box is loaded (unpacked if needed)
---and teleports the player inside. `on_fail` may override the error notice.
---@param name string
---@param box table
---@param player ObjectRef
---@param on_fail function|nil
local function load_and_join(name, box, player, on_fail)
	ctf_jma_elysium.show_wait_formspec(name)

	activate_box(box, function(ok)
		if ok then
			join_box(player, name, box)
			return
		end

		ctf_jma_elysium.close_wait_formspec(name)

		if on_fail then
			on_fail()
		else
			core.chat_send_player(
				name,
				S(
					"[PvP Box] Failed to load PvP Box #@1 (its data is missing or corrupted). The broken box was removed. You were not joined.",
					box.id
				)
			)
		end

		restore_idle_timer(box)
	end)
end

local function create_box(player, name, tmpl, persistent)
	local id = ctf_jma_elysium.allocate_box_id()
	-- Reserve the id right away so a second create cannot pick the same one
	ctf_jma_elysium.box_reserved_ids[id] = true
	local pos1, pos2 = compute_box_region(tmpl, id)
	local meta_key = persistent and ("box_persistent_" .. id) or tmpl.meta_key

	ctf_jma_elysium.show_wait_formspec(name)

	ctf_map.emerge_with_callbacks(nil, pos1, pos2, function()
		local current = PlayerObj(name)
		if not current or not ctf_jma_elysium.players[name] then
			-- Player left Elysium while the area was emerging: nothing was
			-- placed yet, just release the reserved id.
			ctf_jma_elysium.box_reserved_ids[id] = nil
			ctf_jma_elysium.box_creating[name] = nil
			return
		end

		local placed = place_schematic_vm(
			vector.add(pos1, tmpl.map_offset),
			tmpl.file,
			tmpl.barrier
		)
		if not placed then
			ctf_jma_elysium.box_reserved_ids[id] = nil
			ctf_jma_elysium.box_creating[name] = nil
			ctf_jma_elysium.close_wait_formspec(name)
			core.chat_send_player(
				name,
				S("Failed to place the map. Please contact an admin.")
			)
			core.log(
				"error",
				"[ctf_jma_elysium] Failed to place PvP Box map: " .. tmpl.file
			)
			return
		end

		-- Restore the metadata saved for this box map (if any)
		if has_meta(tmpl.meta_key) then
			ctf_jma_elysium.restore_nodemeta(tmpl.meta_key, pos1)
		end
		-- A reused id restores its own metadata on top
		if meta_key ~= tmpl.meta_key and has_meta(meta_key) then
			ctf_jma_elysium.restore_nodemeta(meta_key, pos1)
		end

		local box = {
			id = id,
			name = tmpl.name,
			owner = name,
			members = {},
			invites = {},
			requests = {},
			order = {},
			former_members = {},
			pos1 = pos1,
			pos2 = pos2,
			respawn_nodes = {},
			template_file = tmpl.file,
			-- Persistent boxes live in their own saved file
			file = persistent
					and (PERSISTENT_DIR .. "/" .. id .. ".mts")
				or tmpl.file,
			map_offset = tmpl.map_offset,
			barrier = tmpl.barrier,
			meta_key = meta_key,
			persistent = persistent,
			active = true,
		}

		ctf_jma_elysium.boxes[id] = box
		for _, respawn in ipairs(tmpl.respawns) do
			local player_pos = vector.add(pos1, respawn)
			local marker_pos = {
				x = player_pos.x,
				y = player_pos.y - 1,
				z = player_pos.z,
			}
			core.set_node(marker_pos, { name = RESPAWN_NODE_NAME })
			ctf_jma_elysium.add_box_respawn_node(box, marker_pos)
		end
		-- Also collect any additional marker nodes placed in the schematic.
		ctf_jma_elysium.scan_box_respawn_nodes(box)
		ctf_jma_elysium.box_reserved_ids[id] = nil
		ctf_jma_elysium.box_creating[name] = nil
		ctf_jma_elysium.add_box_member(box, name)

		if persistent then
			-- A new persistent box starts from the template, so drop a stale
			-- saved file of a previously deleted box with this id
			os.remove(persistent_box_path(box))
		end

		local ctx = ctf_jma_elysium.players[name]
		if ctx then
			ctx.box = id
			ctx.location = "box:" .. id
		end

		ctf_jma_elysium.set_pvp_mode(current, true)

		local spawn = ctf_jma_elysium.select_box_spawn(box, name)
			or vector.add(pos1, tmpl.respawns[1])
		teleport_to_box_spawn(current, box, name, spawn)

		-- Just in case the placement left the player outside of the box
		core.after(0.2, function()
			local p = PlayerObj(name)
			if p and not ctf_core.pos_inside(p:get_pos(), pos1, pos2) then
				p:set_pos(spawn)
			end
		end)

		ctf_jma_elysium.close_wait_formspec(name)
		core.chat_send_player(
			name,
			S(
				'[PvP Box] PvP Box "@1" #@2 @3created. Use /box invite <player> to invite players.',
				tmpl.name,
				id,
				persistent and "(persistent) " or ""
			)
		)

		-- Let the rest of Elysium know about the new box
		ctf_jma_elysium.broadcast(
			S(
				"@1 created PvP Box #@2 (@3).",
				name,
				id,
				tmpl.name
			)
		)
		core.log(
			"action",
			string.format(
				"[ctf_jma_elysium] PvP Box %d (%s) created by %s at %s",
				id,
				tmpl.name,
				name,
				core.pos_to_string(pos1)
			)
		)
	end)
end

local function handle_create(name, mapname, persistent)
    local player = PlayerObj(name)

	if persistent and not core.check_player_privs(name, { [PERSISTENT_PRIV] = true }) then
		return false,
			S(
				"You need the '@1' privilege to create a persistent PvP Box.",
				PERSISTENT_PRIV
			)
	end

	local ctx = ctf_jma_elysium.players[name]
	if not ctx then
		return false,
			S("You must be in Elysium to create a PvP Box. Use /elysium first.")
	end

	if ctf_jma_elysium.box_creating[name] then
		return false, S("Please wait, your PvP Box is being created...")
	end

	if ctx.box then
		return false,
			S(
				"You are already in a PvP Box. Use /box leave first to create another one."
			)
	end

	-- A player may own one persistent and one regular box at the same time
	local owned = get_owned_box_of_kind(name, persistent)
	if owned then
		return false,
			S(
				"You already own a @1 PvP Box (#@2). Use /box join @3 to enter it.",
				persistent and "persistent" or "regular",
				owned.id,
				owned.id
			)
	end

	if player:get_hp() <= 0 then
		return false, S("You cannot create a PvP Box while dead.")
	end

	if player:get_attach() then
		return false, S("You cannot create a PvP Box right now.")
	end

	if ctf_combat_mode.in_combat(player) then
		return false, S("You cannot create a PvP Box while in combat.")
	end

	local templates = ctf_jma_elysium.get_box_templates()
	if #templates == 0 then
		return false, S("No PvP Box maps available.")
	end

	if mapname == "" then
		if #templates > 1 then
			return false,
				S(
					"Choose a PvP Box map: @1\nUsage: /box create <map>",
					table.concat(templates, ", ")
				)
		end
		mapname = templates[1]
	end

	local tmpl = ctf_jma_elysium.box_templates[mapname]
	if not tmpl then
		return false,
			S(
				"Unknown PvP Box map: @1. Available: @2",
				mapname,
				table.concat(templates, ", ")
			)
	end

	ctf_jma_elysium.box_creating[name] = true
	create_box(player, name, tmpl, persistent)
	return true
end

local function handle_invite(name, target)
	local box = ctf_jma_elysium.get_box_by_player(name)
	if not box then
		return false, S("You are not in a PvP Box.")
	end

	if box.owner ~= name then
		return false, S("Only the owner can invite players.")
	end

	if target == "" then
		return false, S("Usage: /box invite <player>")
	end

	if target == name then
		return false, S("You cannot invite yourself.")
	end

	local tplayer = core.get_player_by_name(target)
	if not tplayer then
		return false, S("Player @1 is not online.", target)
	end

	if box.members[target] then
		return false, S("@1 is already in your PvP Box.", target)
	end

	local tctx = ctf_jma_elysium.players[target]
	if tctx and tctx.box then
		return false, S("@1 is already in a PvP Box.", target)
	end

	if ctf_jma_elysium.box_invites[target] then
		return false, S("@1 already has a pending PvP Box invite.", target)
	end

	box.invites[target] = true
	ctf_jma_elysium.box_invites[target] = box.id
	schedule_box_invite_expiry(box, target)

	if tctx then
		core.chat_send_player(
			target,
			S(
				"[PvP Box] @1 invited you to their PvP Box. Use /box accept to join within @2 seconds.",
				name,
				ctf_jma_elysium.INVITE_TIMEOUT_SECONDS
			)
		)
	else
		core.chat_send_player(
			target,
			S(
				"[PvP Box] @1 invited you to their PvP Box.\nYou need Elysium access to join: use /elysium, then /box accept within @2 seconds.",
				name,
				ctf_jma_elysium.INVITE_TIMEOUT_SECONDS
			)
		)
	end

	return true, S("Invited @1 to your PvP Box.", target)
end

local function handle_accept(name)
	local box_id = ctf_jma_elysium.box_invites[name]
	local box = box_id and ctf_jma_elysium.boxes[box_id]
	if not box or not box.invites[name] then
		return false, S("You have no PvP Box invite.")
	end

	local ctx = ctf_jma_elysium.players[name]
	if not ctx then
		return false,
			S("You must be in Elysium first: use /elysium, then /box accept.")
	end

	if ctx.box then
		return false, S("You are already in a PvP Box.")
	end

	if BOX_JOIN_COOLDOWN:get(name) then
		return false,
			S("Not too fast! Please wait a moment before joining a PvP Box.")
	end

	if box.packing then
		return false, S("The PvP Box is busy, please try again later.")
	end

	local player = PlayerObj(name)

	if player:get_hp() <= 0 then
		return false, S("You cannot join a PvP Box while dead.")
	end

	if player:get_attach() then
		return false, S("You cannot join a PvP Box right now.")
	end

	load_and_join(name, box, player)

	return true
end

local function handle_leave(name)
	local box = ctf_jma_elysium.get_box_by_player(name)
	if not box then
		return false, S("You are not in a PvP Box.")
	end

	local player = PlayerObj(name)
	if player and player:get_attach() then
		return false, S("You cannot leave the PvP Box while attached.")
	end

	ctf_jma_elysium.remove_box_member(box, name, {
		message = S("You left the PvP Box."),
		broadcast = S("@1 left the PvP Box.", name),
	})
	return true
end

local function handle_kick(name, target)
	if target == "" then
		return false, S("Usage: /box kick <player>")
	end

	if target == name then
		return false,
			S("You cannot kick yourself. Use /box delete to remove the box.")
	end

	-- Prefer the box the owner is currently in, otherwise any box he owns
	-- that contains the target
	local box = ctf_jma_elysium.get_box_by_player(name)
	if
		not (
			box
			and box.owner == name
			and (
				box.members[target]
				or (box.persistent and box.former_members[target])
			)
		)
	then
		box = find_owned_box_with_member(name, target)
	end

	if not box then
		if not get_owned_box(name) then
			return false, S("You do not own any PvP Box.")
		end

		return false, S("@1 is not in any of your PvP Boxes.", target)
	end

	if box.members[target] then
		local tplayer = PlayerObj(target)
		if tplayer and (tplayer:get_attach() or tplayer:get_hp() <= 0) then
			return false, S("@1 is respawning, try again in a moment.", target)
		end

		box.former_members[target] = nil
		ctf_jma_elysium.remove_box_member(box, target, {
			message = S("[PvP Box] You have been kicked by @1.", name),
			broadcast = S("[PvP Box] @1 was kicked.", target),
		})
		return true, S("@1 has been kicked from your PvP Box.", target)
	end

	-- Persistent boxes remember former members; the owner can remove them too
	if box.persistent then
		box.former_members[target] = nil
		box.requests[target] = nil
		ctf_jma_elysium.box_requests[target] = nil
		ctf_jma_elysium.save_persistent_registry()

		local tplayer = PlayerObj(target)
		if tplayer then
			core.chat_send_player(
				target,
				S("[PvP Box] You have been removed from the PvP Box.")
			)
		end
		return true, S("@1 has been removed from your PvP Box.", target)
	end

	return false, S("@1 is not in any of your PvP Boxes.", target)
end

local function handle_transfer(name, target)
	if target == "" then
		return false, S("Usage: /box transfer <player>")
	end

	if target == name then
		return false, S("You are already the owner of this PvP Box.")
	end

	-- Prefer the box the owner is currently in, otherwise any box he owns
	-- that contains the target
	local box = ctf_jma_elysium.get_box_by_player(name)
	if
		not (
			box
			and box.owner == name
			and (box.members[target] or box.former_members[target])
		)
	then
		box = find_owned_box_with_member(name, target)
	end

	if not box then
		if not get_owned_box(name) then
			return false, S("You do not own any PvP Box.")
		end

		return false, S("@1 is not a member of any of your PvP Boxes.", target)
	end

	if box.owner ~= name then
		return false, S("Only the owner can transfer ownership.")
	end

	-- Ownership may be transferred to current and former members of the box
	if not (box.members[target] or box.former_members[target]) then
		return false, S("@1 is not a member of this PvP Box.", target)
	end

	box.owner = target

	if box.persistent then
		ctf_jma_elysium.save_persistent_registry()
	end

	local tplayer = PlayerObj(target)
	if tplayer then
		core.chat_send_player(
			target,
			S("[PvP Box] You are now the owner of the PvP Box #@1.", box.id)
		)
	end

	return true, S("@1 is now the owner of the PvP Box.", target)
end

local function handle_delete(name, param)
	local is_admin = core.check_player_privs(name, { ctf_admin = true })
	-- The box the player is inside takes priority
	local box = ctf_jma_elysium.get_box_by_player(name)
	local id = tonumber(param)

	if is_admin and param ~= "" then
		if not id then
			return false, S("Usage: /box delete <id>")
		end

		box = ctf_jma_elysium.boxes[id]
		if not box then
			return false, S("There is no PvP Box with id #@1.", id)
		end
	end

	if not box then
		local owned = {}
		for _, b in pairs(ctf_jma_elysium.boxes) do
			if b.owner == name then
				table.insert(owned, b)
			end
		end
		table.sort(owned, function(a, b)
			return a.id < b.id
		end)

		if #owned == 0 then
			if is_admin then
				return false, S("Usage: /box delete <id>")
			end
			return false, S("You do not own any PvP Box.")
		end

		if id then
			box = ctf_jma_elysium.boxes[id]
			if not box or box.owner ~= name then
				return false, S("You do not own PvP Box #@1.", id)
			end
		elseif #owned == 1 then
			box = owned[1]
		else
			local list = {}
			for _, b in ipairs(owned) do
				table.insert(
					list,
					string.format(
						"#%d (%s)",
						b.id,
						b.persistent and "persistent" or "regular"
					)
				)
			end

			return false,
				S(
					"You own several PvP Boxes: @1\nUsage: /box delete <id>",
					table.concat(list, ", ")
				)
		end
	end

	if box.owner ~= name and not is_admin then
		return false, S("Only the owner can delete the PvP Box.")
	end

	if box.persistent and not is_admin then
		return false,
			S(
				"Persistent PvP Boxes cannot be deleted. Ask an admin if it must be removed."
			)
	end

	ctf_jma_elysium.destroy_box(box)
	return true, S("PvP Box #@1 has been deleted.", box.id)
end

local BOX_USAGE = "Usage: /box help | create [map] | create_persistent [map] | maps | list | join [id] | info | invite <player> | accept | approve <player> | deny <player> | leave | kick <player> | respawn | transfer <player> | delete [id]"
local BOX_HELP = {
	{ "help", S("Show this help.") },
	{
		"create [map]",
		S(
			"Create a regular PvP Box. If all members leave, it is deleted after @1. With several maps, choose one via /box maps.",
			algorithms.time_to_string(BOX_EMPTY_DESTROY_TIME)
		),
	},
	{
		"create_persistent [map]",
		S(
			"Create a persistent PvP Box (needs the @1 privilege). It is saved and restored after a server restart.",
			PERSISTENT_PRIV
		),
	},
	{ "maps", S("List the available PvP Box maps.") },
	{ "list", S("List every PvP Box with its map, owner and member count.") },
	{
		"join [id]",
		S(
			"Join the PvP Box with the given id. Invited players and former members enter directly, everybody else has to ask the owner."
		),
	},
	{ "info", S("Show the details of the PvP Box you are currently in.") },
	{ "invite <player>", S("Invite a player to your PvP Box (owner only).") },
	{ "accept", S("Accept a pending invite and join the PvP Box.") },
	{ "approve <player>", S("Approve a join request (owner only).") },
	{ "deny <player>", S("Deny a join request (owner only).") },
	{ "leave", S("Leave the PvP Box you are in.") },
	{ "kick <player>", S("Remove a player from your PvP Box (owner only).") },
	{
		"respawn",
		S(
			"Get a respawn marker. Place it inside your PvP Box to set where players respawn after death (owner only). Players respawn above the marker."
		),
	},
	{ "transfer <player>", S("Transfer ownership of your PvP Box to a member (owner only).") },
	{ "delete [id]", S("Delete your PvP Box (owner only).") },
}

---Builds the player-facing help of the /box command
---@return boolean, string
local function handle_help()
	local lines = { S("[PvP Box] Commands:") }
	for _, entry in ipairs(BOX_HELP) do
		table.insert(lines, S("  /box @1 - @2", entry[1], entry[2]))
	end
	table.insert(
		lines,
		S("Tip: start with /box maps and /box list, then create your own box.")
	)
	return true, table.concat(lines, "\n")
end

local function handle_list(name)
	local ids = {}
	for id in pairs(ctf_jma_elysium.boxes) do
		table.insert(ids, id)
	end
	table.sort(ids)

	local lines = {}
	for _, id in ipairs(ids) do
		local box = ctf_jma_elysium.boxes[id]

		local members = 0
		for _ in pairs(box.members) do
			members = members + 1
		end

		local marks = {}
		if box.persistent then
			table.insert(marks, "persistent")
		end
		if not next(box.members) then
			if box.persistent then
				table.insert(marks, box.active and "orphaned" or "packed")
			else
				table.insert(marks, "empty")
			end

			if box.destroy_at then
				local left = math.max(box.destroy_at - os.time(), 0)
				table.insert(
					marks,
					string.format("deletes in %dm", math.ceil(left / 60))
				)
			end
		end

		local mark = #marks > 0 and (" [" .. table.concat(marks, ", ") .. "]") or ""

		table.insert(
			lines,
			string.format(
				"#%d%s | map: %s | owner: %s | members: %d",
				id,
				mark,
				box.name,
				box.owner ~= "" and box.owner or "?",
				members
			)
		)
	end

	if #lines == 0 then
		return false, S("There are no active PvP Boxes.")
	end

	return true, table.concat(lines, "\n")
end

---@param box table
---@param name string
---@return boolean
local function may_join_directly(box, name)
	if box.owner == name then
		return true
	end

	if box.invites[name] then
		return true
	end

	if box.former_members[name] then
		return true
	end

	return false
end

local function handle_join(name, param)
	param = (param or ""):trim()
	local ctx = ctf_jma_elysium.players[name]
	if not ctx then
		return false, S("You must be in Elysium to join a PvP Box.")
	end

	if ctx.box then
		return false, S("You are already in a PvP Box.")
	end

	if BOX_JOIN_COOLDOWN:get(name) then
		return false,
			S("Not too fast! Please wait a moment before joining a PvP Box.")
	end

	local player = PlayerObj(name)

	if player:get_hp() <= 0 then
		return false, S("You cannot join a PvP Box while dead.")
	end

	if player:get_attach() then
		return false, S("You cannot join a PvP Box right now.")
	end

	local box
	if param == "" then
		local candidates = {}
		for _, candidate in pairs(ctf_jma_elysium.boxes) do
			if
				not candidate.packing
				and not candidate.members[name]
				and (
					may_join_directly(candidate, name)
					or next(candidate.members)
				)
			then
				table.insert(candidates, candidate)
			end
		end
		table.sort(candidates, function(a, b)
			return a.id < b.id
		end)

		if #candidates == 0 then
			return false, S("There are no PvP Boxes available to join right now.")
		end
		if #candidates > 1 then
			local choices = {}
			for _, candidate in ipairs(candidates) do
				table.insert(
					choices,
					string.format("#%d (%s)", candidate.id, candidate.name)
				)
			end
			return false,
				S(
					"Choose a PvP Box: @1\nUsage: /box join <id>",
					table.concat(choices, ", ")
				)
		end
		box = candidates[1]
	else
		local id = tonumber(param)
		if not id then
			return false, S("Usage: /box join <id>")
		end

		box = ctf_jma_elysium.boxes[id]
		if not box then
			return false, S("There is no PvP Box with id #@1.", id)
		end
	end

	if box.packing then
		return false, S("The PvP Box is busy, please try again later.")
	end
	if box.members[name] then
		return false, S("You are already in this PvP Box.")
	end

	-- The owner, invited players and (for persistent boxes) former members
	-- enter directly, everybody else has to ask the owner.
	if may_join_directly(box, name) then
		load_and_join(name, box, player)
		return true
	end

	-- An empty box is not open to strangers: it is kept for its former members
	-- (a regular box stays in the world for a grace period before removal)
	if not next(box.members) then
		return false,
			S("This PvP Box is empty. Only its former members can join it for now.")
	end

	-- Replace a previous (possibly stale) request with this one
	local previous_id = ctf_jma_elysium.box_requests[name]
	if previous_id then
		if previous_id == box.id then
			return false, S("You already have a pending request to this PvP Box.")
		end

		local previous = ctf_jma_elysium.boxes[previous_id]
		if previous and previous.requests then
			previous.requests[name] = nil
		end
	end

	box.requests[name] = true
	ctf_jma_elysium.box_requests[name] = box.id

	local owner = box.owner
	if owner ~= name and core.get_player_by_name(owner) then
		core.chat_send_player(
			owner,
			S(
				"[PvP Box] @1 wants to join your PvP Box #@2. Use /box approve @3 or /box deny @4.",
				name,
				box.id,
				name,
				name
			)
		)
	end

	return true, S("Join request sent to the owner of PvP Box #@1.", box.id)
end

local function handle_approve(name, target)
	if target == "" then
		return false, S("Usage: /box approve <player>")
	end

	-- Prefer the box the owner is currently in, otherwise any box he owns
	-- that has a pending request from the target
	local box = ctf_jma_elysium.get_box_by_player(name)
	if
		not (
			box
			and box.owner == name
			and box.requests
			and box.requests[target]
		)
	then
		box = find_owned_box_with_request(name, target)
	end

	if not box then
		if not get_owned_box(name) then
			return false, S("You do not own any PvP Box.")
		end

		return false,
			S("@1 has no pending request to join your PvP Boxes.", target)
	end

	if box.packing then
		return false, S("The PvP Box is busy, please try again later.")
	end

	local tplayer = PlayerObj(target)
	if not tplayer or not tplayer:is_player() then
		return false, S("Player @1 is not online.", target)
	end

	local tctx = ctf_jma_elysium.players[target]
	if not tctx then
		return false, S("@1 is not in Elysium.", target)
	end

	box.requests[target] = nil
	ctf_jma_elysium.box_requests[target] = nil

	if tctx.box then
		return false, S("@1 is already in a PvP Box.", target)
	end

	if BOX_JOIN_COOLDOWN:get(target) then
		return false,
			S("@1 must wait a moment before joining a PvP Box.", target)
	end

	load_and_join(target, box, tplayer, function()
		local fail = S(
			"[PvP Box] Failed to load PvP Box #@1 (its data is missing or corrupted). The broken box was removed. Nobody was joined.",
			box.id
		)
		core.chat_send_player(name, fail)
		core.chat_send_player(target, fail)
	end)

	return true, S("@1 has been approved to join your PvP Box.", target)
end

local function handle_deny(name, target)
	if target == "" then
		return false, S("Usage: /box deny <player>")
	end

	-- Prefer the box the owner is currently in, otherwise any box he owns
	-- that has a pending request from the target
	local box = ctf_jma_elysium.get_box_by_player(name)
	if
		not (
			box
			and box.owner == name
			and box.requests
			and box.requests[target]
		)
	then
		box = find_owned_box_with_request(name, target)
	end

	if not box then
		if not get_owned_box(name) then
			return false, S("You do not own any PvP Box.")
		end

		return false,
			S("@1 has no pending request to join your PvP Boxes.", target)
	end

	box.requests[target] = nil
	ctf_jma_elysium.box_requests[target] = nil
	core.chat_send_player(
		target,
		S("[PvP Box] Your request to join the PvP Box was denied.")
	)
	return true, S("Denied @1.", target)
end

local function handle_info(name)
	local box = ctf_jma_elysium.get_box_by_player(name)
	if not box then
		return false, S("You are not in a PvP Box.\n") .. BOX_USAGE
	end

	local members = {}
	for mname in pairs(box.members) do
		table.insert(members, mname)
	end
	table.sort(members)

	local info = S(
		'[PvP Box] map: @1 | owner: @2 | members (@3): @4',
		box.name,
		box.owner,
		#members,
		table.concat(members, ", ")
	)

	if box.persistent then
		info = info .. S(" | persistent (@1)", box.active and "active" or "packed")
	end

	if box.owner == name then
		local requests = {}
		for rname in pairs(box.requests) do
			table.insert(requests, rname)
		end
		if #requests > 0 then
			table.sort(requests)
			info = info .. S("\nJoin requests: @1", table.concat(requests, ", "))
		end
	end

	return true, info
end

-- Gives the box owner the respawn marker node. The owner places it inside his
-- box to define where players respawn after death. The handout time is kept in
-- the box context so it cannot be spammed.
local function handle_respawn(name)
	local player = PlayerObj(name)

	local box = get_owned_box(name)
	if not box then
		return false, S("You do not own any PvP Box.")
	end

    -- One handout per box per cooldown period
	-- ctf_core.init_cooldowns is not suitable here because the cooldown is per box, not per player
	local now = os.time()
	local cooldown_until = box.respawn_item_cooldown or 0
	if cooldown_until > now then
		return false,
			S(
				"Please wait @1 seconds before requesting another respawn marker.",
				cooldown_until - now
			)
	end

	local inv = player:get_inventory()
	if inv:contains_item("main", RESPAWN_NODE_ITEM) then
		return true,
			S(
				"You already have a respawn marker. Place it inside your PvP Box - players will respawn above it."
			)
	end

	local leftover = inv:add_item("main", RESPAWN_NODE_ITEM)
	if leftover and not leftover:is_empty() then
		return false, S("Your inventory is full.")
	end

	-- Remember the handout time in the box context
	box.respawn_item_cooldown = now + RESPAWN_ITEM_COOLDOWN_TIME

	return true,
		S(
			"Respawn marker added to your inventory. Place it inside your PvP Box - players will respawn above it. Only you can place and dig it."
		)
end

core.register_chatcommand("box", {
	params = "help | create [map] | create_persistent [map] | maps | list | join [id] | info | invite <player> | accept | approve <player> | deny <player> | leave | kick <player> | respawn | transfer <player> | delete",
	description = S("Manage your PvP Box"),
	privs = { interact = true },
	func = function(name, param)
		local args = string.split(param or "", " ", false, 2)
		local sub = string.lower(args[1] or "")
		local rest = (args[2] or ""):trim()

		-- The help is documentation and works everywhere
		if sub == "help" or sub == "?" then
			return handle_help()
		end

		if not ctf_jma_elysium.players[name] then
			return false,
				S("You must be in Elysium to use PvP Box commands. Use /elysium first.")
		end

		if sub == "" or sub == "info" then
			return handle_info(name)
		elseif sub == "maps" then
			local templates = ctf_jma_elysium.get_box_templates()
			if #templates == 0 then
				return false, S("No PvP Box maps available.")
			end
			return true,
				S("Available PvP Box maps: @1", table.concat(templates, ", "))
		elseif sub == "list" then
			return handle_list(name)
		elseif sub == "create" then
			return handle_create(name, rest, false)
		elseif sub == "create_persistent" then
			return handle_create(name, rest, true)
		elseif sub == "join" then
			return handle_join(name, rest)
		elseif sub == "invite" then
			return handle_invite(name, rest)
		elseif sub == "accept" then
			return handle_accept(name)
		elseif sub == "approve" then
			return handle_approve(name, rest)
		elseif sub == "deny" then
			return handle_deny(name, rest)
		elseif sub == "leave" then
			return handle_leave(name)
		elseif sub == "kick" then
			return handle_kick(name, rest)
		elseif sub == "respawn" then
			return handle_respawn(name)
		elseif sub == "transfer" then
			return handle_transfer(name, rest)
		elseif sub == "delete" then
			return handle_delete(name, rest)
		end

		return false, BOX_USAGE
	end,
})

-- Remind players about a pending PvP Box invite once they join Elysium
ctf_jma_elysium.register_on_join(function(player)
	local name = player:get_player_name()
	local box_id = ctf_jma_elysium.box_invites[name]
	local box = box_id and ctf_jma_elysium.boxes[box_id]
	if box then
		core.chat_send_player(
			name,
			S(
				"[PvP Box] You have a pending invite to @1's PvP Box. Use /box accept to join.",
				box.owner
			)
		)
	end

	-- Let owners know about join requests that arrived while they were offline
	for _, owned in pairs(ctf_jma_elysium.boxes) do
		if owned.owner == name and owned.requests then
			local requests = {}
			for rname in pairs(owned.requests) do
				table.insert(requests, rname)
			end
			if #requests > 0 then
				table.sort(requests)
				core.chat_send_player(
					name,
					S(
						"[PvP Box] Pending join requests for your PvP Box #@1: @2",
						owned.id,
						table.concat(requests, ", ")
					)
				)
			end
		end
	end
end)

-- Clean up membership when a player disconnects
core.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	clear_box_invite(name)
	ctf_jma_elysium.box_creating[name] = nil

	local requested = ctf_jma_elysium.boxes[ctf_jma_elysium.box_requests[name] or -1]
	if requested and requested.requests then
		requested.requests[name] = nil
	end
	ctf_jma_elysium.box_requests[name] = nil

	local box = find_box_by_member(name)
	if box then
		ctf_jma_elysium.remove_box_member(box, name, {
			broadcast = S("[PvP Box] @1 left the PvP Box.", name),
			queue_warning = true,
		})
	end
end)

-- Deliver queued PvP Box warnings (e.g. after a disconnect while in a box)
core.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	local warning = ctf_jma_elysium.box_warnings[name]
	if warning then
		ctf_jma_elysium.box_warnings[name] = nil
		core.chat_send_player(name, warning)
	end
end)

-- Persist persistent boxes on shutdown: save them and remove their areas so
-- the next server start always restores them from the saved file
core.register_on_shutdown(function()
	for _, box in pairs(ctf_jma_elysium.boxes) do
		if box.persistent and box.active and not box.packing then
			if ctf_jma_elysium.save_box_to_disk(box) then
				-- core.delete_area(box.pos1, box.pos2)
				box.active = false
			end
		end
	end

	ctf_jma_elysium.save_persistent_registry()
end)

-- Bounds are auto-detected from the .mts. Respawn coordinates are player
-- destinations relative to bounds.pos1; marker nodes are placed one node below.
--
-- Optional "barrier" field: name of a node used to build a closed barrier
-- shell (4 walls + floor + ceiling) one node outside the box bounds, e.g.
--   barrier = "ctf_map:ind_glass_red"
-- Leave it unset to keep the box open.

-- fappy1
ctf_jma_elysium.register_box_template("island", {
	file = ctf_jma_elysium.modpath .. "/maps/jma_elysium_pvpbox1.mts",
	respawns = {
		{ x = 22, y = 16, z = 16 },
		{ x = 22, y = 16, z = 31 },
	},
	barrier = "ctf_jma_elysium:ind_glass",
})

-- Unknown
ctf_jma_elysium.register_box_template("oldely", {
	file = ctf_jma_elysium.modpath .. "/maps/jma_elysium_old.mts",
	respawns = {
		{ x = 50, y = 1, z = 55 },
		{ x = 50, y = 1, z = 67 },

		{ x = 83, y = 2, z = 49 },
		{ x = 91, y = 2, z = 41 },

		{ x = 29, y = 2, z = 29 },
		{ x = 13, y = 2, z = 13 },
	},
	barrier = "ctf_jma_elysium:ind_glass",
})

-- Loki
ctf_jma_elysium.register_box_template("box", {
	file = ctf_jma_elysium.modpath .. "/maps/jma_elysium_box.mts",
	respawns = {
		{ x = 21, y = 1, z = 12 },
		{ x = 3, y = 1, z = 12 },
	},
	barrier = "ctf_jma_elysium:ind_glass",
})

-- Restore persistent boxes (no schematics are placed here, unpacking is lazy)
ctf_jma_elysium.load_persistent_registry()
