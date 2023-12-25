if os.date("%m") ~= "12" or tonumber(os.date("%d")) < 11 or tonumber(os.date("%d")) > 25 or not minetest.get_modpath("server_cosmetics") then return end

local META_KEY = "server_cosmetics:snowballs:"..os.date("%Y")
local COSMETIC_KEY = "server_cosmetics:entity:santa_hat:"..os.date("%Y")
local REQUIRED_COOKIES = 50
local COOKIES_PER_PRESENT = 2

local function EAT_FUNC(amount)
	return function(itemstack, user)
		if not itemstack or not user or not user:is_player() then return itemstack end

		local meta = user:get_meta()
		local current_val = meta:get_int(META_KEY)

		if current_val + amount < REQUIRED_COOKIES then
			meta:set_int(META_KEY, current_val + amount)
			sfinv.set_page(user, sfinv.get_page(user))

			hud_events.new(user:get_player_name(), {
				text = string.format("[Event] %d/%d cookies eaten", current_val + amount, REQUIRED_COOKIES),
				color = "info",
				quick = true,
			})

			itemstack:set_count(itemstack:get_count() - 1)
			return itemstack
		end

		if meta:get_int(COSMETIC_KEY) ~= 1 then
			meta:set_int(COSMETIC_KEY, 1)
			meta:set_int(META_KEY, REQUIRED_COOKIES)
			sfinv.set_page(user, sfinv.get_page(user))

			hud_events.new(user:get_player_name(), {
				text = "You have unlocked this year's christmas hat! Put it on in the Customize tab!",
				color = "success",
			})

			itemstack:set_count(itemstack:get_count() - 1)
			return itemstack
		elseif ctf_map.current_map then
			local team = ctf_teams.get(user)

			if team then
				minetest.add_item(ctf_map.current_map.teams[team].flag_pos, itemstack:get_name())

				itemstack:set_count(itemstack:get_count() - 1)
				return itemstack
			end
		end

		return itemstack
	end
end

minetest.override_item("winterize:present", {
	drop = {
		max_items = 2,
		items = {
			{
				items = {"santa_hat_event:cookie "..COOKIES_PER_PRESENT, "throwable_snow:snowball 6"},
			},
			{
				rarity = 15,
				items = {"santa_hat_event:cookie 5", "throwable_snow:snowball 6"}
			}
		},
	},
})

minetest.register_craftitem("santa_hat_event:cookie", {
	description = "A Cookie (Leftclick to eat)",
	inventory_image = "santa_hat_event_cookie.png",
	on_use = EAT_FUNC(1),
})

function winterize.get_present_count()
	local cookie_count = 2

	for _, p in pairs(minetest.get_connected_players()) do
		if p:get_meta():get_int(COSMETIC_KEY) ~= 1 then
			cookie_count = cookie_count + 1
		end
	end

	return cookie_count
end

sfinv.register_page("santa_hat_event:progress", {
	title = "Event!",
	is_in_nav = function(self, player)
		return ctf_teams.get(player) and true or false
	end,
	get = function(self, player, context)
		local meta = player:get_meta()
		local cookies_ate = meta:get_int(META_KEY)

		local form = "real_coordinates[true]"

		if cookies_ate < REQUIRED_COOKIES then
			form = string.format("%slabel[0.1,0.5;Eat %d cookies to get a cool christmas hat!\n%s]", form,
				REQUIRED_COOKIES,
				"They can be found in presents at the start of the match"
			)
		else
			form = form .. "label[0.1,0.5;Nice job! Pop over to the customization tab to try out your new hat!]"
		end

		form = form .. string.format([[
			label[0.1,2.7;You've eaten %d/%d cookies]
			image[0.1,3;8,1;santa_hat_event_progress_bar.png]] ..
			[[^(([combine:38x8:1,0=santa_hat_event_progress_bar_full.png)^[resize:%dx8)]"
		]],
		cookies_ate, REQUIRED_COOKIES,
		math.min((38/REQUIRED_COOKIES)*cookies_ate, 38) + 1
		)

		return sfinv.make_formspec(player, context, form, true)
	end,
	on_player_receive_fields = function(self, player, context, fields)
		sfinv.set_page(player, sfinv.get_page(player))
	end,
})
