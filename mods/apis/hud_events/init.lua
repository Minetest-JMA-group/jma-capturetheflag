hud_events = {}

local hud = mhud.init()

local HUD_SHOW_TIME = 3
local HUD_SHOW_QUICK_TIME = 2
local HUD_SHOW_NEXT_TIME = 0.6
local HUD_SHOW_SCROLL_TIME = 5
local HUD_SCROLL_MAX_ENTRIES = 10
local HUD_SCROLL_ROW_HEIGHT = 20

local HUD_COLORS = {
	primary = 0x0D6EFD,
	secondary = 0x6C757D,
	success = 0x20bf5c,
	info = 0x0DCAF0,
	warning = 0xFFC107,
	danger = 0xDC3545,
	light = 0xF8F9FA,
	dark = 0x212529,
	gray = 0x808080,
}

local hud_queues = {
	-- {}, channel 1
	-- {}, channel 2
	-- ...
}
local quick_event_timer = {}
local scroll_events = {}

local function make_scroll_huddef(layout, index, count, text, color)
	local offset = table.copy(layout.offset)
	offset.y = offset.y + (index - (count + 1) / 2) * HUD_SCROLL_ROW_HEIGHT

	return {
		type = "text",
		position = table.copy(layout.position),
		offset = offset,
		alignment = table.copy(layout.alignment),
		text = text,
		color = color,
	}
end

local function redraw_scroll_events(player, state)
	local count = #state.entries
	for index, entry in ipairs(state.entries) do
		local def = make_scroll_huddef(
			state.layout,
			index,
			count,
			entry.text,
			entry.color
		)

		if hud:exists(player, entry.hud_name) then
			hud:change(player, entry.hud_name, def)
		else
			hud:add(player, entry.hud_name, def)
		end
	end
end

local function remove_scroll_event(player, pname, event_id)
	local state = scroll_events[pname]
	if not state then
		return
	end

	for index, entry in ipairs(state.entries) do
		if entry.id == event_id then
			if entry.timer then
				entry.timer:cancel()
			end
			if player and hud:exists(player, entry.hud_name) then
				hud:remove(player, entry.hud_name)
			end
			table.remove(state.entries, index)
			break
		end
	end

	if #state.entries == 0 then
		scroll_events[pname] = nil
	elseif player then
		redraw_scroll_events(player, state)
	end
end

local function show_scroll_hud_event(player, huddef)
	local pname = player:get_player_name()
	local state = scroll_events[pname]

	if not state then
		state = {
			entries = {},
			next_id = 0,
			layout = {
				position = { x = 0, y = 0.5 },
				offset = { x = 10, y = 0 },
				alignment = { x = "right", y = "center" },
			},
		}
		scroll_events[pname] = state
	end

	state.next_id = state.next_id + 1
	local entry = {
		id = state.next_id,
		hud_name = "hud_event_scroll_" .. tostring(state.next_id),
		text = huddef.text,
		color = huddef.color,
	}
	table.insert(state.entries, entry)

	while #state.entries > HUD_SCROLL_MAX_ENTRIES do
		local removed = table.remove(state.entries, 1)
		if removed.timer then
			removed.timer:cancel()
		end
		if hud:exists(player, removed.hud_name) then
			hud:remove(player, removed.hud_name)
		end
	end

	redraw_scroll_events(player, state)
	entry.timer = core.after(HUD_SHOW_SCROLL_TIME, function()
		local online_player = core.get_player_by_name(pname)
		remove_scroll_event(online_player, pname, entry.id)
	end)
end

core.register_on_leaveplayer(function(player)
	local pname = player:get_player_name()

	for channel = 1, #hud_queues do
		if hud_queues[channel][pname] then
			hud_queues[channel][pname].t:cancel()
			hud_queues[channel][pname] = nil
		end
	end

	if quick_event_timer[pname] then
		quick_event_timer[pname]:cancel()
		quick_event_timer[pname] = nil
	end

	local scroll_state = scroll_events[pname]
	if scroll_state then
		for _, entry in ipairs(scroll_state.entries) do
			if entry.timer then
				entry.timer:cancel()
			end
		end
		scroll_events[pname] = nil
	end
end)

local function show_quick_hud_event(player, huddef)
	local pname = player:get_player_name()

	if not hud:exists(player, "hud_event_quick") then
		hud:add(player, "hud_event_quick", {
			type = "text",
			position = { x = 0.5, y = 0.5 },
			offset = { x = 0, y = 20 },
			alignment = { x = "center", y = "down" },
			text = huddef.text,
			color = huddef.color,
		})
	else
		hud:change(
			player,
			"hud_event_quick",
			{ text = huddef.text, color = huddef.color }
		)
	end

	if quick_event_timer[pname] then
		quick_event_timer[pname]:cancel()
	end
	quick_event_timer[pname] = core.after(HUD_SHOW_QUICK_TIME, function()
		if not player:is_player() then
			return
		end

		if hud:exists(player, "hud_event_quick") then
			hud:remove(player, "hud_event_quick")
		end
	end)
end

local function handle_hud_events(player, channel)
	local pname = player:get_player_name()

	local huddef = table.remove(hud_queues[channel][pname].e, 1)
	local event_name = "hud_event_" .. tostring(channel)

	if not hud:exists(player, event_name) then
		hud:add(player, event_name, {
			type = "text",
			position = { x = 0.5, y = 0.5 },
			offset = { x = 0, y = 45 + (channel - 1) * 25 },
			alignment = { x = "center", y = "down" },
			text = huddef.text,
			color = huddef.color,
		})
	else
		hud:change(player, event_name, {
			text = huddef.text,
			color = huddef.color,
		})
	end

	hud_queues[channel][pname].t = core.after(HUD_SHOW_TIME, function()
		player = core.get_player_by_name(pname)

		if player then
			hud:change(player, event_name, { text = "" })

			hud_queues[channel][pname].t = core.after(HUD_SHOW_NEXT_TIME, function()
				player = core.get_player_by_name(pname)

				if player then
					if #hud_queues[channel][pname].e >= 1 then
						handle_hud_events(player, channel)
					else
						hud:remove(player, event_name)
						hud_queues[channel][pname] = nil
					end
				end
			end)
		end
	end)
end

--[[
	hud_events.new(player, {
		text = "This is a hud event",
		color = "info",
		quick = true,
		scroll = true,
		channel = an integer or nil
	})
]]
function hud_events.new(player, def)
	player = PlayerObj(player)
	if not player then
		return
	end

	if type(def) == "string" then
		def = { text = def }
	end

	def.channel = def.channel or 1

	if def.color then
		if type(def.color) == "string" then
			def.color = HUD_COLORS[def.color]
		end
	else
		def.color = 0x00D1FF
	end

	if def.quick then
		show_quick_hud_event(player, def)
	elseif def.scroll then
		show_scroll_hud_event(player, def)
	else
		local pname = player:get_player_name()

		while not hud_queues[def.channel] do
			table.insert(hud_queues, {})
		end

		if not hud_queues[def.channel][pname] then
			hud_queues[def.channel][pname] = { e = {} }
		end
		table.insert(
			hud_queues[def.channel][pname].e,
			{ text = def.text, color = def.color, channel = def.channel }
		)

		if not hud_queues[def.channel][pname].t then
			handle_hud_events(player, def.channel)
		end
	end
end
