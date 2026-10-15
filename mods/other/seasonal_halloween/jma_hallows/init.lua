if os.date("%m") ~= "10" or tonumber(os.date("%d")) < 15 or not core.get_modpath("server_cosmetics") then return end

jma_hallows = {}

local YEAR = os.date("%Y")

jma_hallows.COIN_KEY = "jma_hallows:coins:"..YEAR
jma_hallows.PUMPKINS_KEY = "jma_hallows:pumpkins:"..YEAR
jma_hallows.HAT_KEY = "server_cosmetics:entity:hallows_hat:"..YEAR
jma_hallows.SKIN_KEY = "jma_hallows:skin:"..YEAR
jma_hallows.COMPLETED_KEY = "jma_hallows:completed:"..YEAR

-- Global variables to edit in runtime
jma_hallows.SKIN_ID = 51
jma_hallows.SKIN_ID2 = 52
jma_hallows.HAT_PRICE = 105
jma_hallows.SKIN_PRICE = 50
jma_hallows.SKIN2_PRICE = 35

local SMALL_REWARD = 1

local GROUP_MIN = 2
local GROUP_MAX = 7
local GROUP_RADIUS = 3
local GROUP_VERTICAL = 7
local CENTRE_RADIUS_FRACTION = 0.20

local pumpkin_timer = nil
local PUMPKIN_DELAY = 3 * 60

local PUMPKIN_DELAY_RANDOM_FACTOR = 0.10

--- @return integer
local function get_pumpkin_delay()
	local min_delay = PUMPKIN_DELAY * (1 - PUMPKIN_DELAY_RANDOM_FACTOR)
	local max_delay = PUMPKIN_DELAY * (1 + PUMPKIN_DELAY_RANDOM_FACTOR)

	return math.random(math.floor(min_delay), math.ceil(max_delay))
end

--- Returns the player's current pumpkin coin balance.
--- @param player ObjectRef
--- @return integer
function jma_hallows.get_coins(player)
	return player:get_meta():get_int(jma_hallows.COIN_KEY)
end

--- Awards coins, saves the progress to player metadata and returns the total.
--- @param player ObjectRef
--- @param amount integer
--- @return integer total
function jma_hallows.give_coins(player, amount)
	local meta = player:get_meta()
	local total = meta:get_int(jma_hallows.COIN_KEY) + amount

	meta:set_int(jma_hallows.COIN_KEY, total)
	meta:set_int(jma_hallows.PUMPKINS_KEY, meta:get_int(jma_hallows.PUMPKINS_KEY) + 1)

	return total
end

core.register_node("jma_hallows:pumpkin", {
	description = "Pumpkin\nGives 1 pumpkin coin when dug",
	drawtype = "nodebox",
	paramtype = "light",
	tiles = {
		"jma_hallows_pumpkin_top.png", "jma_hallows_pumpkin_bottom.png",
		"jma_hallows_pumpkin_side.png", "jma_hallows_pumpkin_side.png",
		"jma_hallows_pumpkin_side.png",
		{
			name = "jma_hallows_pumpkin_face.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 6.0,
			},
		},
	},
	paramtype2 = "facedir",
	light_source = 5,
	groups = {choppy = 1, oddly_breakable_by_hand = 1, flammable = 2},
	sounds = default.node_sound_wood_defaults(),
	drop = "",
	on_dig = function (pos, node, digger)
		local total = jma_hallows.give_coins(digger, SMALL_REWARD)

		hud_events.new(digger:get_player_name(), {
			text = string.format("[Event] +%d pumpkin coin (total %d)", SMALL_REWARD, total),
			color = "info",
			quick = true,
		})

		if math.random(1, 3) == 1 then
			spooky_effects.spawn_angry_ghost(pos, digger)
		end

		return core.node_dig(pos, node, digger)
	end,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.375, -0.4375, -0.375, 0.375, 0.1875, 0.375}, -- NodeBox1
			{-0.375, -0.5, -0.3125, 0.375, 0.25, 0.3125}, -- NodeBox7
			{-0.3125, -0.5, -0.375, 0.3125, 0.25, 0.375}, -- NodeBox8
			{-0.082463, 0.25, -0.09, 0.081017, 0.3125, 0.069443}, -- NodeBox9
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.375, -0.5, -0.375, 0.375, 0.3125, 0.375},
		}
	},
	collision_box = {
		type = "fixed",
		fixed = {
			{-0.375, -0.5, -0.375, 0.375, 0.3125, 0.375},
		}
	},
})

-- Spawn pumpkins on natural ground, in small clusters of GROUP_MIN..GROUP_MAX
-- nodes, close to the centre of the map. This is the jack 'o lantern spawner
-- from hallows_hat_event with a single change: candidates are restricted to the
-- central area and grown into groups.
local function spawn_pumpkins()
	local map = ctf_map.current_map

	if not map or not map.pos1 or not map.pos2 then
		return
	end

	local vm = VoxelManip()
	local pos1, pos2 = vm:read_from_map(map.pos1, map.pos2)
	local data = vm:get_data()
	local param2_data = vm:get_param2_data()

	local Nx = pos2.x - pos1.x + 1
	local Ny = pos2.y - pos1.y + 1
	local Nz = pos2.z - pos1.z + 1
	local stride_z = Ny * Nx

	local ID_AIR = core.CONTENT_AIR
	local ID_IGNORE = core.CONTENT_IGNORE
	local ID_WATER = core.get_content_id("default:water_source")
	local ID_PUMPKIN = core.get_content_id("jma_hallows:pumpkin")

	local function vi(x, y, z)
		return (z - pos1.z) * stride_z + (y - pos1.y) * Nx + (x - pos1.x) + 1
	end

	-- A spot is plantable when it is air sitting on solid, non-water ground
	-- with air above it, just like the original spawner.
	local function is_plantable(x, y, z)
		if x < pos1.x or x > pos2.x or z < pos1.z or z > pos2.z
			or y <= pos1.y or y >= pos2.y then
			return false
		end

		local id_below = data[vi(x, y - 1, z)]
		local id_above = data[vi(x, y + 1, z)]

		return data[vi(x, y, z)] == ID_AIR and id_below ~= ID_AIR
			and id_below ~= ID_IGNORE and id_below ~= ID_WATER and id_above == ID_AIR
	end

	-- Only spawn close to the centre of the map.
	local centre = map.flag_center or {x = (pos1.x + pos2.x) / 2, z = (pos1.z + pos2.z) / 2}
	local radius = math.max(20, math.floor(math.min(Nx, Nz) * CENTRE_RADIUS_FRACTION))
	local radius_sq = radius * radius

	local player_count = math.max(1, #core.get_connected_players())
	local group_count = math.max(1, math.min(10, player_count))

	local groups = {}
	local placed = 0

	local random_state = {}
	local random_count = Nx * Ny * Nz
	local math_random = math.random
	local math_floor = math.floor

	while random_count > 0 and #groups < group_count do
		local pos = math_random(1, random_count)

		pos = random_state[pos] or pos

		local x = pos % Nx + pos1.x
		local y = math_floor(pos / Nx) % Ny + pos1.y
		local z = math_floor(pos / Ny / Nx) + pos1.z

		random_state[pos] = random_state[random_count] or random_count
		random_state[random_count] = nil
		random_count = random_count - 1

		local dx = x - centre.x
		local dz = z - centre.z
		local near_centre = dx * dx + dz * dz <= radius_sq

		if near_centre and is_plantable(x, y, z) then
			-- Keep clusters apart from each other.
			local far_enough = true

			for _, group in ipairs(groups) do
				local gdx = x - group.x
				local gdz = z - group.z

				if gdx * gdx + gdz * gdz <= GROUP_RADIUS * GROUP_RADIUS then
					far_enough = false
					break
				end
			end

			if far_enough then
				-- Collect the plantable spots of the cluster around the seed.
				local members = {}

				for cz = z - GROUP_RADIUS, z + GROUP_RADIUS do
					for cx = x - GROUP_RADIUS, x + GROUP_RADIUS do
						for cy = y - GROUP_VERTICAL, y + GROUP_VERTICAL do
							if is_plantable(cx, cy, cz) then
								members[#members + 1] = {x = cx, y = cy, z = cz}
							end
						end
					end
				end

				if #members >= GROUP_MIN then
					for i = #members, 2, -1 do
						local j = math_random(i)

						members[i], members[j] = members[j], members[i]
					end

					local take = math_random(GROUP_MIN, math.min(GROUP_MAX, #members))

					for i = 1, take do
						local member = members[i]
						local mvi = vi(member.x, member.y, member.z)

						data[mvi] = ID_PUMPKIN
						param2_data[mvi] = math_random(0, 3)
					end

					groups[#groups + 1] = {x = x, y = y, z = z}
					placed = placed + take
				end
			end
		end
	end

	if placed == 0 then
		core.log("warning", "[jma_hallows] No place for pumpkins was found.")
		return 0, 0, nil
	end

	vm:set_data(data)
	vm:set_param2_data(param2_data)
	vm:write_to_map(false)

	core.log("action", string.format(
		"[jma_hallows] Spawned %d pumpkins in %d group(s)",
		placed, #groups))

	-- Centre of all groups, so both teams get one shared marker pointing at
	-- the pumpkin patch.
	local cx, cy, cz = 0, 0, 0

	for _, group in ipairs(groups) do
		cx = cx + group.x
		cy = cy + group.y
		cz = cz + group.z
	end

	return placed, #groups, {
		x = math.floor(cx / #groups + 0.5),
		y = math.floor(cy / #groups + 0.5),
		z = math.floor(cz / #groups + 0.5),
	}
end

-- One shared pumpkin marker visible to both teams. markers.add() is
-- team-scoped (one marker per player, shown only to their team), so place it
-- through one online player per team.
local function place_pumpkin_markers(centre)
	local done_teams = {}

	for _, player in ipairs(core.get_connected_players()) do
		local pname = player:get_player_name()
		local pteam = ctf_teams.get(pname)

		if pteam and not done_teams[pteam] then
			done_teams[pteam] = true
			ctf_modebase.markers.add(pname, " Pumpkins", centre, true)
		end
	end
end

local function announce_pumpkins()
	local placed, _, centre = spawn_pumpkins()

	if placed > 0 then
		core.chat_send_all(core.colorize("orange",
			"[Event] Pumpkins have sprouted! Dig them for pumpkin coins!"))
		place_pumpkin_markers(centre)
	end
end

ctf_api.register_on_match_start(function()
	if pumpkin_timer then
		pumpkin_timer:cancel()
		pumpkin_timer = nil
	end

	local delay = get_pumpkin_delay()

	pumpkin_timer = core.after(delay, function()
		pumpkin_timer = nil
		announce_pumpkins()
	end)

	core.chat_send_all(core.colorize("orange",
		"[Event] Pumpkins will sprout in " .. algorithms.time_to_string(delay) .. "!"))
end)

ctf_api.register_on_match_end(function()
	if pumpkin_timer then
		pumpkin_timer:cancel()
		pumpkin_timer = nil
	end
end)

dofile(core.get_modpath(core.get_current_modname()).."/shop.lua")
