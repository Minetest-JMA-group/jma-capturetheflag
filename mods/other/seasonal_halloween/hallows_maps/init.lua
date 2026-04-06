if (os.date("%m") ~= "10" or tonumber(os.date("%d")) < 15) and os.date("%m") ~= "11" then return end

ctf_map.register_maps_dir(core.get_modpath(core.get_current_modname()).."/maps/")

local old_select_map_for_mode = ctf_modebase.map_catalog.select_map_for_mode
local was_last = false
local first_map = true
function ctf_modebase.map_catalog.select_map_for_mode(mode, ...)
	if first_map or (math.random(1, 10) == 2 and not was_last) then
		was_last = true
		first_map = false

		ctf_modebase.map_catalog.select_map(ctf_modebase.map_catalog.map_dirnames["pumpkin_hills"])
	else
		was_last = false
		old_select_map_for_mode(mode, ...)
	end
end
