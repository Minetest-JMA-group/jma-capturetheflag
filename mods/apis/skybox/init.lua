--[[

Copyright (C) 2017 - Auke Kok <sofar@foo-projects.org>

"skybox" is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation; either version 2.1
of the license, or (at your option) any later version.

]]--

--
-- Builtin sky box textures and color/shadings, clouds
--

local skies = {
    {"DarkStormy", "#1f2226", 0.5, { density = 0.5, color = "#aaaaaae0", ambient = "#000000",
        height = 64, thickness = 32, speed = {x = 6, y = -6},}, "jpg"},
    {"CloudyLightRays", "#5f5f5e", 0.9, { density = 0.4, color = "#efe3d5d0", ambient = "#000000",
        height = 96, thickness = 24, speed = {x = 4, y = 0},}, "jpg"},
    {"FullMoon", "#24292c", 0.2, { density = 0.25, color = "#ffffff80", ambient = "#404040",
        height = 140, thickness = 8, speed = {x = -2, y = 2},}, "jpg"},
    {"SunSet", "#72624d", 0.4, { density = 0.2, color = "#f8d8e8e0", ambient = "#000000",
        height = 120, thickness = 16, speed = {x = 0, y = -2},}, "jpg"},
    {"ThickCloudsWater", "#a57850", 0.8, { density = 0.35, color = "#ebe4ddfb", ambient = "#000000",
        height = 80, thickness = 32, speed = {x = 4, y = 3},}, "png"},
    {"TropicalSunnyDay", "#f1f4ee", 1.0, { density = 0.25, color = "#fffffffb", ambient = "#000000",
        height = 120, thickness = 8, speed = {x = -2, y = 0},}, "jpg"},
}

local selected_skies = {}

--
-- API
--

skybox = {}

local function clamp(value, min, max)
	return math.min(math.max(value, min), max)
end

-- Brighter-night hack: the day/night ratio is clamped so that nights never get
-- darker than BRIGHTER_NIGHT_MIN_RATIO, while daytime brightness is left
-- unchanged.

---@type { normal: number, applied: number }?
local last_day_night_ratios

-- Minimum day/night ratio used at night
local BRIGHTER_NIGHT_MIN_RATIO = 0.45
local DAY_NIGHT_RATIO_UPDATE_INTERVAL = 1
-- How much the normal day/night ratio has to change before the override is updated again.
local DAY_NIGHT_RATIO_CHANGE_THRESHOLD = 0.05
-- Apply the ratio unconditionally near full day: the normal ratio can approach
-- its maximum so slowly that the change stays below the threshold, leaving the
-- override stuck below full daylight.
local FULL_DAY_RATIO_EPSILON = 1e-3
-- Small epsilon to absorb floating-point noise when comparing the ratio change
-- against the threshold.
local RATIO_CHANGE_EPSILON = 1e-9

---@return number, boolean  -- the ratio and whether it was updated
function skybox.get_day_night_ratio()
	local normal_ratio = core.time_to_day_night_ratio(core.get_timeofday())
	local is_full_day = normal_ratio >= 1 - FULL_DAY_RATIO_EPSILON
	local ratio = clamp(normal_ratio, BRIGHTER_NIGHT_MIN_RATIO, 1)
	if is_full_day then
		ratio = 1
	end

	if not last_day_night_ratios then
		last_day_night_ratios = { normal = normal_ratio, applied = ratio }
		return ratio, true
	end

	-- The clamped ratio can stay the same while the normal ratio drifts
	-- (for example at night, where it is always BRIGHTER_NIGHT_MIN_RATIO).
	-- There is nothing to update in that case.
	if last_day_night_ratios.applied == ratio then
		return ratio, false
	end

	-- Bypass the threshold only when full day is reached, not on every
	-- update after that.
	local reached_full_day = ratio == 1 and last_day_night_ratios.applied < 1
	local diff = math.abs(normal_ratio - last_day_night_ratios.normal)
	if
		not reached_full_day
		and diff <= DAY_NIGHT_RATIO_CHANGE_THRESHOLD + RATIO_CHANGE_EPSILON
	then
		return ratio, false
	end

	last_day_night_ratios = { normal = normal_ratio, applied = ratio }
	return ratio, true
end

skybox.set = function(player, number)
    if number == 0 then
        skybox.clear(player)
    else
        local sky = skies[number]
		if not sky then
			core.log("error", "Invalid skybox number: " .. tostring(number))
			skybox.clear(player)
			return
		end
		selected_skies[player:get_player_name()] = number
		local ratio = sky[3]
		if ratio == nil then
			ratio = skybox.get_day_night_ratio()
		end
		player:override_day_night_ratio(ratio)
        local file_type = sky[5] or "png"
        local textures = {
            sky[1] .. "Up." .. file_type,
            sky[1] .. "Down." .. file_type,
            sky[1] .. "Front." .. file_type,
            sky[1] .. "Back." .. file_type,
            sky[1] .. "Left." .. file_type,
            sky[1] .. "Right." .. file_type,
        }
        if player.get_sky_color ~= nil then
            player:set_sky({
                base_color = sky[2],
                type = "skybox",
                textures = textures,
                clouds = true
            })
            -- making the sun invisible deactivates the dynamic shadows
            -- making the sun visible with an invisible texture keeps shadows intact
            player:set_sun({visible = true, sunrise_visible = false, texture = "blank.png"})
            player:set_moon({visible = true, texture = "blank.png"})
            player:set_stars({visible = false})
        else
            player:set_sky(sky[2], "skybox", textures, true)
        end
        player:set_clouds(sky[4])
    end
end

---@diagnostic disable-next-line: duplicate-set-field
skybox.clear = function(player)
	selected_skies[player:get_player_name()] = nil
	player:override_day_night_ratio(skybox.get_day_night_ratio())
	if player.get_sky_color ~= nil then
		player:set_sky({base_color = "white", type = "regular"})
	else
		player:set_sky("white", "regular")
	end
	player:set_clouds({
		density = 0.4,
		color = "#fff0f0e5",
		ambient = "#000000",
		height = 120,
		thickness = 16,
		speed = {x = 0, y = -2},
	})
	player:set_sun({visible = true, sunrise_visible = true, texture = ""})
	player:set_moon({visible = true, texture = ""})
	player:set_stars({visible = true})

end

---@diagnostic disable-next-line: duplicate-set-field
skybox.add = function(def)
	table.insert(skies, def)
end

skybox.get_skies = function()
	return table.copy(skies)
end

--
-- registrations and load/save code
--

local t = 0
core.register_globalstep(function(dtime)
	t = t + dtime
	if t < DAY_NIGHT_RATIO_UPDATE_INTERVAL then
		return
	end
	t = 0

	local ratio, update_required = skybox.get_day_night_ratio()
	if update_required then
		for _, player in ipairs(core.get_connected_players()) do
			local selected_sky_index = selected_skies[player:get_player_name()]
			local selected_sky = selected_sky_index and skies[selected_sky_index]
			if selected_sky_index == nil or (selected_sky and selected_sky[3] == nil) then
				player:override_day_night_ratio(ratio)
			end
		end
	end
end)

core.register_on_joinplayer(skybox.clear)
core.register_on_leaveplayer(function(player)
	selected_skies[player:get_player_name()] = nil
end)

core.register_privilege("skybox", {
	description = "Change sky box for yourself",
})

core.register_chatcommand("skybox", {
	params = "<skybox> or <number> or \"off\" or empty to list skyboxes",
	description = "Change your sky box set",
	privs = {"skybox"},
	func = function(name, param)
		local player = core.get_player_by_name(name)
		if not player then
			return
		end
		if param == nil or param == "" then
			core.chat_send_player(name, "Available sky boxes:")
			for _, v in ipairs(skies) do
				core.chat_send_player(name, v[1])
			end
			return
		elseif tonumber(param) ~= nil and tonumber(param) >= 1 and tonumber(param) <= #skies then
			skybox.set(player, tonumber(param))
			return
		elseif param == "off" or param == "0" then
			skybox.clear(player)
			return
		end
		for k, v in ipairs(skies) do
			if v[1] == param then
				skybox.set(player, k)
				return
			end
		end
		core.chat_send_player(name, "Could not find that sky box.")
	end
})
