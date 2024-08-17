local api = {}
local MODNAME = minetest.get_current_modname()
rawset(_G, MODNAME, api)

local files = {
	"bullet.lua",
	"ammo.lua"
}

for _, file in ipairs(files) do
	dofile(minetest.get_modpath(MODNAME).."/"..file)
end

local checking = {}
-- Returns false if the automatic timer is currently running, returns true otherwise
function api.enable_automatic(fire_interval, itemstack, user)
	local pname = user:get_player_name()

	if checking[pname] then return false end

	checking[pname] = minetest.after(fire_interval, function()
		checking[pname] = nil

		if user and user:get_player_control().LMB then
			local wielded = user:get_wielded_item()

			if wielded:get_name() == itemstack:get_name() then
				user:set_wielded_item(itemstack:get_definition().on_use(wielded, user, {type = "nothing"}) or wielded)
			end
		end
	end)

	return true
end

minetest.register_on_leaveplayer(function(player)
	local pname = player:get_player_name()

	if checking[pname] then
		checking[pname]:cancel()
	end
end)
