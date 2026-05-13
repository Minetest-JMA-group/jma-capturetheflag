core.register_craftitem("ctf_healing:ammo", {
	description = "Healing Ammo\nUsed to reload healing guns",
	inventory_image = "ctf_healing_healing_ammo.png",
})

local PISTOL_HEAL_AMOUNT = 3

local S = core.get_translator(core.get_current_modname())

--- @type OnHitCallback
local function on_teammate_hit(hitpoint, prev_hitpoint, shooter, look_dir, def)
	local target = hitpoint.ref
	if not target then
		return false
	end
	local target_name = target:get_player_name()
	local shooter_name = shooter:get_player_name()
	local target_hp = target:get_hp()

	if target_hp >= target:get_properties().hp_max then
		return false
	end

	local result =
		RunCallbacks(ctf_healing.registered_on_heal, shooter, target, PISTOL_HEAL_AMOUNT)

	if not result then
		target:set_hp(target_hp + PISTOL_HEAL_AMOUNT)
		hud_events.new(target_name, {
			quick = true,
			text = S("@1 healed you!", shooter_name),
			color = 0xC1FF44,
		})
		hud_events.new(shooter_name, {
			quick = true,
			text = S("You healed @1!", target_name),
			color = 0xC1FF44,
		})
	elseif type(result) == "string" then
		hud_events.new(shooter_name, {
			quick = true,
			text = result,
			color = "warning",
		})
	end
	return false
end

ctf_ranged.simple_register_gun("ctf_healing:healing_pistol", {
	type = "pistol",
	description = "Healing Pistol\nHeals teammates on hit",
	texture = "ctf_healing_healing_pistol.png",
	fire_sound = "ctf_ranged_pistol",
	rounds = 75,
	range = 75,
	fire_interval = 0.4,
	liquid_travel_dist = 2,
	on_use = ctf_ranged.on_hp_change_gun_use(on_teammate_hit, function()
		return false
	end),
	ammo = "ctf_healing:ammo",
})
