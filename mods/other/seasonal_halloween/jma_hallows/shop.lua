local esc = core.formspec_escape

local function preview_model(y, field, item)
	local p = item.preview
	return string.format("model[0.55,%.2f;2,2;preview_%s;%s;%s;%s;false;true;%s]",
		y + 0.15, field, p.mesh, p.textures, p.rot or "0,180", p.anim or "0,0")
end

local function coin_row(y, field, item, name, desc, price, owned)
	local status
	if owned then
		status = "<style color=#20bf5c><b>Owned</b></style>"
	else
		status = string.format("<style color=#FFD700>Price: %d coins</style>", price)
	end

	local text = string.format(
		"<b><style size=17>%s</style></b>\n<style size=14>%s</style>\n%s",
		esc(name), esc(desc), status
	)

	local f = {
		string.format("box[0.3,%.2f;9.87,2.3;#252525]", y),
		preview_model(y, field, item),
		string.format("hypertext[2.75,%.2f;4.4,2.05;item_%s;%s]", y + 0.12, field, text),
	}

	if not owned then
		f[#f + 1] = string.format("button[7.3,%.2f;2.6,0.9;%s;Buy]", y + 0.7, field)
	end

	return table.concat(f)
end

--- @param player ObjectRef
local function announce_completion(player)
	local meta = player:get_meta()

	if meta:get_int(jma_hallows.COMPLETED_KEY) == 1 then
		return
	end

	local name = player:get_player_name()

	if player:get_meta():get_int(jma_hallows.HAT_KEY) ~= 1
	or not skins.player_has_skin(name, jma_hallows.SKIN_ID)
	or not skins.player_has_skin(name, jma_hallows.SKIN_ID2) then
		return
	end

	meta:set_int(jma_hallows.COMPLETED_KEY, 1)

	core.chat_send_all(core.colorize("orange",
		string.format(
			"[Event] %s has collected all Halloween cosmetics and completed the event!",
			name)))
end

local function notify(player, color, text)
	core.chat_send_player(player:get_player_name(),
		core.colorize(color, "[Pumpkin Shop] " .. text))
end

--- @param player ObjectRef
--- @param item table catalogue entry from SHOP_ITEMS
local function try_purchase(player, item)
	if item.is_owned(player) then
		notify(player, "#FFA500", item.already_owned_msg)
		return true
	end

	local price = item.get_price()
	local meta = player:get_meta()
	local coins = meta:get_int(jma_hallows.COIN_KEY)

	if coins < price then
		notify(player, "#FF5555", string.format(
			"Not enough pumpkin coins (%d/%d)", coins, price))
		return true
	end

	meta:set_int(jma_hallows.COIN_KEY, coins - price)
	item.grant(player)
	notify(player, "#20bf5c", item.success_msg)
	announce_completion(player)
	sfinv.set_page(player, "jma_hallows:shop")
	return true
end

local SHOP_ITEMS = {
	{
		field = "buy_hat",
		name = "Hallows Hat",
		desc = "Wear the limited edition Halloween hat. Show it off in the Customize tab.",
		preview = {
			mesh = "server_cosmetics_hallows_hat2026.obj",
			textures = "server_cosmetics_hallows_hat2026.png",
			rot = "0,30",
		},
		already_owned_msg = "You already own the Hallows Hat!",
		success_msg = "You unlocked this year's Hallows Hat! Put it on in the Customize tab!",
		get_price = function() return jma_hallows.HAT_PRICE end,
		is_owned = function(player)
			return player:get_meta():get_int(jma_hallows.HAT_KEY) == 1
		end,
		grant = function(player)
			player:get_meta():set_int(jma_hallows.HAT_KEY, 1)
		end,
		on_purchase = function(player, item) return try_purchase(player, item) end,
	},
	{
		field = "buy_skin",
		name = "Warlock",
		desc = "Unlock an exclusive Halloween skin for your collection.",
		preview = {
			mesh = "character.b3d",
			textures = "character_warlock.png",
			rot = "0,160",
		},
		already_owned_msg = "You already own the Warlock skin!",
		success_msg = "You unlocked the Warlock skin! Check the Skins tab (Show my collection).",
		get_price = function() return jma_hallows.SKIN_PRICE end,
		is_owned = function(player)
			return skins.player_has_skin(player:get_player_name(), jma_hallows.SKIN_ID)
		end,
		grant = function(player)
			skins.add_skin_to_collection(player:get_player_name(), jma_hallows.SKIN_ID)
		end,
		on_purchase = function(player, item) return try_purchase(player, item) end,
	},
	{
		field = "buy_skin2",
		name = "Dark Amethyst",
		desc = "Unlock an exclusive Halloween skin for your collection.",
		preview = {
			mesh = "character.b3d",
			textures = "character_dark_amethyst.png",
			rot = "0,160",
		},
		already_owned_msg = "You already own the Dark Amethyst skin!",
		success_msg = "You unlocked the Dark Amethyst skin! Check the Skins tab (Show my collection).",
		get_price = function() return jma_hallows.SKIN2_PRICE end,
		is_owned = function(player)
			return skins.player_has_skin(player:get_player_name(), jma_hallows.SKIN_ID2)
		end,
		grant = function(player)
			skins.add_skin_to_collection(player:get_player_name(), jma_hallows.SKIN_ID2)
		end,
		on_purchase = function(player, item) return try_purchase(player, item) end,
	},
}

local ROW_Y0 = 2.7
local ROW_STEP = 2.6
sfinv.register_page("jma_hallows:shop", {
	title = core.colorize("orange", "Pumpkin Shop"),
	get = function(self, player, context)
		local meta = player:get_meta()
		local coins = meta:get_int(jma_hallows.COIN_KEY)

		local f = {
			"bgcolor[#1e1e1e;true]",
			"box[0,0.9;10.47,1.5;#2d2d2d]",
			"hypertext[0.3,0.98;7,0.8;title;<center><style size=24 color=#FF7518><b>Pumpkin Shop</b></style></center>]",
			string.format(
				"hypertext[7.2,1.05;2.3,0.8;coins;<right><style size=18 color=#FFD700><b>%d</b></style></right>]",
				coins
			),
			"image[9.72,1.15;0.6,0.6;jma_hallows_coin.png]",
			"hypertext[0.3,1.85;9.9,0.5;info;<style size=14 color=#CCCCCC>"..
			"Collect pumpkin coins from the pumpkins and spend them on Halloween cosmetics.</style>]",
		}

		for i, item in ipairs(SHOP_ITEMS) do
			f[#f + 1] = coin_row(ROW_Y0 + (i - 1) * ROW_STEP,
				item.field, item, item.name, item.desc,
				item.get_price(), item.is_owned(player))
		end

		return sfinv.make_formspec_v7(player, context, table.concat(f))
	end,
	on_player_receive_fields = function(self, player, context, fields)
		for _, item in ipairs(SHOP_ITEMS) do
			if fields[item.field] then
				return item.on_purchase(player, item)
			end
		end

		return false
	end,
})

core.register_chatcommand("pumpkin_shop", {
	description = "Open the Pumpkin Shop",
	privs = {interact = true},
	func = function(name)
		sfinv.set_page(player, "jma_hallows:shop")
		core.show_formspec(name, "", sfinv.get_formspec(player, sfinv.get_or_create_context(player)))
		return true
	end,
})
