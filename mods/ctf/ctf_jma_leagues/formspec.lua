local page_name = "ctf_jma_leagues:overview"

local cooldowns = {}
local cooldown = 2

sfinv.register_page(page_name, {
	title = "Leagues",
	get = function(self, player, context)
		local name = player:get_player_name()

		local current = ctf_jma_leagues.get_league(name)
		local sorted_leagues = {}

		for k, info in pairs(ctf_jma_leagues.leagues) do
			table.insert(sorted_leagues, {
				name = k,
				order = info.order
			})
		end

		table.sort(sorted_leagues, function(a, b)
			return a.order < b.order
		end)

		local history_list = {"<style size=18><b>Reached Leagues</b></style>"}
		local found_current = false
		local next_league = nil
		local bar_width = 0

		for _, v in ipairs(sorted_leagues) do
			local league = ctf_jma_leagues.leagues[v.name]

			if current == "none" then
				-- Player has not reached any league yet
				table.insert(history_list, string.format("<style color=orange><b>★ %s [You've just begun your progress!]</b></style>",
					league.display_name
				))
				next_league = league
				break
			else
				if v.name == current then
					found_current = true
					table.insert(history_list, string.format("<style color=orange><b>★ %s [Current]</b></style>", league.display_name))
				elseif not found_current then
					table.insert(history_list, string.format("<style color=green><b>✓ %s</b></style>", league.display_name))
				elseif not next_league then
					next_league = league
				end
			end
		end

		local tasks_list = {"<style size=18><b>Tasks of the next league</b></style>"}
		if next_league and next_league.requirements then
			table.insert(tasks_list, "<style color=#aaaaaa><b>• " .. next_league.display_name .. "</b></style>")

			local eval = ctf_jma_leagues.evaluate_progress(name, next_league)
			for _, task in ipairs(eval.tasks) do
				local req = task.requirement
				local result = task.result

				if result.done then
					table.insert(tasks_list, string.format("<style color=green>✓ %s</style>", req.description))
				elseif result.current and result.required then
					table.insert(tasks_list, string.format(
						"<style color=orange>* %s (%s / %s, left %s)</style>",
						req.description,
						ctf_core.format_number(result.current),
						ctf_core.format_number(result.required),
						ctf_core.format_number(math.abs(result.required - result.current))
					))
				else
					table.insert(tasks_list, string.format("<style color=red>X %s (Failed to get status... Please contact server staff) </style>", req.description))
				end
			end

			if eval.tasks_completed >= #next_league.requirements then
				table.insert(tasks_list, "<style color=lime><b>✓ All tasks complete! Next league incoming!</b></style>")
			end

			bar_width = 10.47 * (eval.total_percentage / 100)
		else
			table.insert(tasks_list, "<style color=#111111>No tasks available</style>")
		end

		local h = table.concat(history_list, "\n")
		local t = table.concat(tasks_list, "\n")
		local formspec =
			"box[0,0;10.47,0.25;#222222]" ..
			string.format("box[0,0;%.2f,0.25;#00cc00]", bar_width) ..
			"box[0,5.05;10.47,5.3;#202232]" ..
			"box[0,0.35;10.47,4.6;#111111]" ..
			"hypertext[0.15,0.35;10.17,4.6;;" .. minetest.formspec_escape(h) .. "]" ..
			"hypertext[0.15,5.05;10.17,5.3;;" .. minetest.formspec_escape(t) .. "]" ..
			"image_button[0.15,10.47;0.8,0.8;ctf_jma_leagues_refresh.png;refresh;;true;]" ..
			"tooltip[refresh;Refresh the leagues overview]"

		-- if current == "none" then
		-- 	local tip = "<style color=#aaaaaa>" ..
		-- 		"Tip: Complete tasks to progress through leagues. " ..
		-- 		"Each league unlocks new rewards!" ..
		-- 	"</style>"
		-- 	formspec = formspec .. "hypertext[0.15,10.5;10.17,0.8;;" .. minetest.formspec_escape(tip) .. "]"
		-- end
		-- minetest.show_formspec(name, "ctf_jma_leagues:history", formspec)
		return sfinv.make_formspec_v7(player, context, formspec)
	end,

	on_player_receive_fields = function(self, player, context, fields)
		if fields.refresh then
			local name = player:get_player_name()
			local now = os.time()
			local last_refresh = cooldowns[name] or 0

			if now - last_refresh >= cooldown then
				cooldowns[name] = now
				sfinv.set_page(player, page_name)
			else
				cmsg.push_message_player(player, "Please wait " .. (cooldown - (now - last_refresh)) .. " seconds before refreshing.")
			end
		end
	end
})

-- Update sfinv page when player is promoted (if this page is open)
ctf_jma_leagues.register_on_promote(function(player_name, current, next_league)
	local player = minetest.get_player_by_name(player_name)
	if not player then return end
	if sfinv.get_page(player) == page_name then
		sfinv.set_page(player, page_name)
	end
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	cooldowns[name] = nil
end)
