local REGENERATE_TIME = 25 * 60 -- 25mins
local CHAT_COLOR = "orange"
local timer = nil

local BLACKLIST_ITEMS = {
	"ctf_ranged:pistol",
	"ctf_ranged:desert_eagle",
	"ctf_ranged:shotgun",
	"ctf_ranged:rifle",
	"ctf_ranged:assault_rifle",
	"ctf_ranged:minigun",
	"ctf_ranged:sniper",
	"ctf_ranged:sniper_magnum",
	"ctf_melee:",
	"ctf_map:",
}

local S = core.get_translator(core.get_current_modname())

ctf_api.register_on_match_start(function()
	if timer then
		timer:cancel()
		timer = nil
	end
	local function callback()
		core.chat_send_all(
			core.colorize(CHAT_COLOR, S("Treasures has been regenerated!"))
		)
		ctf_modebase.regenerate_treasures()
		timer = core.after(REGENERATE_TIME, callback)
	end
	timer = core.after(REGENERATE_TIME, callback)
end)

ctf_api.register_on_match_end(function()
	if timer then
		timer:cancel()
		timer = nil
	end
end)

function ctf_modebase.regenerate_treasures()
	local tr = ctf_modebase:get_current_mode().treasures or {}

	local treasurefy_func
	if next(tr) then
		local map_treasures = table.copy(tr)

		for k, v in
			pairs(ctf_map.treasure.treasure_from_string(ctf_map.current_map.treasures))
		do
			map_treasures[k] = v
		end
		for _, black_listed in ipairs(BLACKLIST_ITEMS) do
			for item, _ in pairs(map_treasures) do
				if string.find(item, black_listed) then
					map_treasures[item] = nil
				end
			end
		end
		treasurefy_func = function(inv)
			ctf_map.treasure.treasurefy_node(inv, map_treasures)
		end
	end

	ctf_map.regenerate_treasures(treasurefy_func)
end

core.register_chatcommand("regenerate_treasure", {
	description = S("Regenerate items in treasure chests"),
	privs = { ctf_admin = true, server = true },
	func = ctf_modebase.regenerate_treasures,
})
