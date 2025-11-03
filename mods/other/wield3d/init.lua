wield3d = {no_entity_attach = {}}

local location = {
	"Arm_Right",          -- default bone
	{x=0, y=5.5, z=3},    -- default position
	{x=-90, y=225, z=90}, -- default rotation
	{x=0.3, y=0.3, z=0.25},     -- default scale
}

local players = {}

core.register_item("wield3d:hand", {
	type = "none",
	wield_image = "blank.png",
})

core.register_entity("wield3d:entity", {
	initial_properties = {
		visual = "wielditem",
		wield_item = "wield3d:hand",
		visual_size = location[4],
		physical = false,
		makes_footstep_sound = false,
		backface_culling = false,
		static_save = false,
		pointable = false,
		glow = 7,
	},
	on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
		if core.is_player(puncher) then
			puncher:set_hp(puncher:get_hp() - damage,  {type="punch"}) --cause damage to yourself.
			core.log("warning", puncher:get_player_name() .. " is trying to damage non-pointable entity \"wield3d:entity\".")
		end
		return true
	end
})

function wield3d.add_wielditem(player)
	local player_name = player:get_player_name()
	if wield3d.no_entity_attach[player_name] then
		return
	end
	local entity = core.add_entity(player:get_pos(), "wield3d:entity")
	if not entity then return end

	local setting = ctf_settings.get(player, "wield3d:use_old_wielditem_display")

	entity:set_attach(
		player,
		location[1], location[2], location[3],
		setting == "false"
	)

	players[player_name] = {entity=entity, item="wield3d:hand"}

	player:hud_set_flags({wielditem = (setting == "true")})
end

function wield3d.remove_wielditem(player)
	local pname = player:get_player_name()
	if players[pname] ~= nil then
		players[pname].entity:remove()
		players[pname] = nil
	end
end

local function update_entity(player)
	local pname = player:get_player_name()
	local item = player:get_wielded_item():get_name()

	if item == "" then
		item = "wield3d:hand"
	end

	if players[pname].item == item then
		return
	end
	players[pname].item = item

	if players[pname].entity:get_luaentity() then
		players[pname].entity:set_properties({wield_item = item})
	else
		wield3d.add_wielditem(player)
	end
end

local globalstep_timer = 0
core.register_globalstep(function(dtime)
	globalstep_timer = globalstep_timer + dtime
	if globalstep_timer < 0.5 then return end

	globalstep_timer = 0

	for _, player in ipairs(core.get_connected_players()) do
		if players[player:get_player_name()] ~= nil then
			update_entity(player)
		end
	end
end)

core.register_on_joinplayer(function(player)
	local pname = player:get_player_name()
	core.after(1.5, function()
		if core.get_player_by_name(pname) then --checking if the player is still online
			wield3d.add_wielditem(player)
		end
	end)
end)
core.register_on_leaveplayer(wield3d.remove_wielditem)


ctf_settings.register("wield3d:use_old_wielditem_display", {
	label = "Use old wielditem display",
	type = "bool",
	default = "true",
	description = "Will use Minetest's default method of showing the wielded item.\n" ..
		"This won't show custom animations, but might be less jarring",
	on_change = function(player, new_value)
		wield3d.remove_wielditem(player)
		wield3d.add_wielditem(player)
	end,
})