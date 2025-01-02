do
    local date = os.date("*t")
    local day, month = date.day, date.month
    if not ((month == 12 and day >= 31) or (month == 1 and day <= 1)) then
        return
    end
end

new_year_event = {}

local TARGET_FIREWORK_COUNT = 73
local METADATA_FIREWORKS_KEY = "fireworks_event"
local COSMETIC_KEY = "server_cosmetics:headwear:sunglasses:blue_classic"

sfinv.register_page("new_year_event:progress", {
    title = "Event!",
    is_in_nav = function(self, player)
        return ctf_teams.get(player) and true or false
    end,
    get = function(self, player, context)
        local meta = player:get_meta()
        local firework_count = meta:get_int(METADATA_FIREWORKS_KEY)

        local form = "real_coordinates[true]"

        if firework_count < TARGET_FIREWORK_COUNT then
            form = string.format("%slabel[0.1,0.5;Launch %d fireworks to earn cool glasses!\n%s]", form,
            TARGET_FIREWORK_COUNT,
                "They can be launched during the New Year event."
            )
        else
            form = form .. "label[0.1,0.5;Great job! Head over to the customization tab to check out your glasses!]"
        end

        form = form .. string.format([[
            label[0.1,2.7;You've launched %d/%d fireworks]
            image[0.1,3;8,1;new_year_event_progress_bar.png]] ..
            [[^(([combine:38x8:1,0=new_year_event_progress_bar_full.png)^[resize:%dx8)]"
        ]],
        firework_count, TARGET_FIREWORK_COUNT, math.min((38 / TARGET_FIREWORK_COUNT) * firework_count, 38) + 1 )

        return sfinv.make_formspec(player, context, form, true)
    end,
    on_player_receive_fields = function(self, player, context, fields)
        sfinv.set_page(player, sfinv.get_page(player))
    end,
})

function new_year_event.add_firework_count(player)
	player = PlayerObj(player)
	if not player then return end

    local meta = player:get_meta()
    local firework_count = meta:get_int(METADATA_FIREWORKS_KEY)

    if firework_count < TARGET_FIREWORK_COUNT then
        firework_count = firework_count + 1
        meta:set_int(METADATA_FIREWORKS_KEY, firework_count)

        if firework_count >= TARGET_FIREWORK_COUNT then
            hud_events.new(player:get_player_name(), {
                text = "You've reached the goal! You've received a unique glasses :)\n Put it on in the Customize tab (Sunglasses > Blue Classic).",
                color = "success",
            })

            if meta:get_int(COSMETIC_KEY) ~= 1 then
                meta:set_int(COSMETIC_KEY, 1)
            end
            minetest.chat_send_all(string.format("%s has completed the New Year fireworks event!", player:get_player_name()))
        else
            hud_events.new(player:get_player_name(), {
				text = string.format("[Event] %d/%d fireworks launched", firework_count, TARGET_FIREWORK_COUNT),
				color = "info",
				quick = true,
			})
        end

		local curr_page = sfinv.get_page(player)
		if curr_page == "new_year_event:progress" then
			sfinv.set_page(player, "new_year_event:progress")
		end
    end
end