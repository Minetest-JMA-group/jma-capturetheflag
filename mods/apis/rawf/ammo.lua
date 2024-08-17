local MODNAME = minetest.get_current_modname()
local api = rawget(_G, MODNAME)

function api.also_register_loaded_tool(name, def, user_loaded_def)
	local loaded_def = table.copy(def)

	if user_loaded_def then
		user_loaded_def(loaded_def)
	end

	loaded_def.unloaded_name = name
	def.loaded_name = name.."_loaded"

	minetest.register_tool(def.loaded_name, loaded_def)

	return name, def
end

function api.unload_weapon(weapon, amount)
	local iname = weapon:get_name()
	local rounds = assert(
		minetest.registered_tools[iname].rounds,
		"Must define 'rounds' property for ranged weapon "..dump(iname)
	)

	local new_wear = (65535 / (rounds-1)) * (amount or 1)

	new_wear = weapon:get_wear() + new_wear

	if new_wear >= 65535 then
		return ItemStack(weapon:get_definition().unloaded_name)
	end

	weapon:set_wear(new_wear)

	return weapon
end

function api.load_weapon(weapon, inv, lists)
	local idef = weapon:get_definition()

	assert(idef.loaded_name, "Item "..idef.name.." doesn't have 'loaded_name' set!")
	assert(idef.ammo, "Item "..idef.name.." doesn't have 'ammo' set!")

	if type(idef.ammo) ~= "table" then
		idef.ammo = {idef.ammo}
	end

	if not lists then
		lists = {"main"}
	elseif type(lists) ~= "table" then
		lists = {lists}
	end

	for _, item in pairs(idef.ammo) do
		for _, list in pairs(lists) do
			if inv:contains_item(list, item) then
				inv:remove_item(list, item)

				return ItemStack(idef.loaded_name)
			end
		end
	end

	return weapon
end
