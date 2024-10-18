if os.date("%m") ~= "10" or tonumber(os.date("%d")) < 17 then return end

local textures = {
	"chest_front.png",
	"chest_side.png",
	"chest_top.png"
}
local function replace_textures(x)
	for _, texture in pairs(textures) do
		x = x:gsub("default_"..texture, "chest_changes_"..texture)
	end

	return x
end


local def = table.copy(minetest.registered_nodes["ctf_map:chest"])
for k, v in pairs(def.tiles) do
	def.tiles[k] = replace_textures(v)
end
minetest.override_item("ctf_map:chest", {
	tiles = def.tiles,
	on_rightclick = function(pos, ...)
		spooky_effects.spawn_ghost(pos)

		if def.on_rightclick then
			return def.on_rightclick(pos, ...)
		end
	end,
})

local odef = table.copy(minetest.registered_nodes["ctf_map:chest_opened"])
for k, v in pairs(odef.tiles) do
	odef.tiles[k] = replace_textures(v)
end
minetest.override_item("ctf_map:chest_opened", {
	tiles = odef.tiles,
	on_metadata_inventory_take = function(pos, listname, index, stack, player, ...)
		if math.random(1, 4) == 1 then
			spooky_effects.spawn_angry_ghost(pos, player)
		end

		return odef.on_metadata_inventory_take(pos, listname, index, stack, player, ...)
	end,
})
