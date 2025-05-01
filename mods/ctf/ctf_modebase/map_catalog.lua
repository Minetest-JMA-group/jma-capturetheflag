ctf_modebase.map_catalog = {
	maps = {},
	map_names = {},
	map_dirnames = {},
	current_map = false,
}

local maps_pool = {}
local used_maps = {}
local used_maps_idx = 1
local map_repeat_interval

local function init()
	table.sort(ctf_map.registered_maps)

	local to_remove = {}
	for i, dirname in ipairs(ctf_map.registered_maps) do
		local map = ctf_map.load_map_meta(i, dirname)
		if map then
			if map.map_version and map.enabled then
				table.insert(ctf_modebase.map_catalog.maps, map)
				table.insert(ctf_modebase.map_catalog.map_names, map.name)
				ctf_modebase.map_catalog.map_dirnames[map.dirname] = #ctf_modebase.map_catalog.maps
			end
		else
			minetest.log("info", "Map " .. dirname .. " is invalid")
			table.insert(to_remove, i)
		end
	end

	for i = #to_remove, 1, -1 do
		table.remove(ctf_map.registered_maps, to_remove[i])
	end

	for i = 1, #ctf_modebase.map_catalog.maps do
		table.insert(maps_pool, i)
	end

	map_repeat_interval = math.floor(#ctf_modebase.map_catalog.maps / 2)
end

minetest.register_on_mods_loaded(function()
	init()
	assert(#ctf_modebase.map_catalog.maps > 0 or ctf_core.settings.server_mode == "mapedit")
end)

function ctf_modebase.map_catalog.sample_maps(filter, full_pool, n)
	local maps = {}
	for _, pool in pairs({maps_pool, full_pool and used_maps}) do
		for idx, map in ipairs(pool) do
			if not filter or filter(ctf_modebase.map_catalog.maps[map]) then
				table.insert(maps, full_pool and map or idx)
			end
		end
	end

	--Sample the n maps randomly
	local function shuffle(t)
		for i = #t, 2, -1 do
			local j = math.random(i)
			t[i], t[j] = t[j], t[i]
		end
	end
	shuffle(maps)

	local selected = {}
	for i = 1, n do
		table.insert(selected, maps[i])
	end


	return selected
end


function ctf_modebase.map_catalog.select_map(selected)
	if not selected then
		selected = ctf_modebase.map_catalog.map_dirnames["plains"]
	end

	if full_pool then
		ctf_modebase.map_catalog.current_map = selected
	else
		ctf_modebase.map_catalog.current_map = maps_pool[selected]

		if map_repeat_interval > 0 then
			if #used_maps < map_repeat_interval then
				table.insert(used_maps, maps_pool[selected])
				maps_pool[selected] = maps_pool[#maps_pool]
				maps_pool[#maps_pool] = nil
			else
				used_maps[used_maps_idx], maps_pool[selected] = maps_pool[selected], used_maps[used_maps_idx]
				used_maps_idx = used_maps_idx + 1
				if used_maps_idx > #used_maps then
					used_maps_idx = 1
				end
			end
		end
	end
end

function ctf_modebase.map_catalog.sample_map_for_mode(mode, n)
	return ctf_modebase.map_catalog.sample_maps(function(map)
		return not map.game_modes or table.indexof(map.game_modes, mode) ~= -1
	end, nil, n)
end
