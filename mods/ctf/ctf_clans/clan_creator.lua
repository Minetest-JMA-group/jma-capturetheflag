local cc_formname = "clan_creator"
local formspec_data = {}

local base_formspec = [[
formspec_version[7]
size[18.5,9.5]
box[0,0;18.5,7.5;black]
%s
label[0.5,0.5;Clan Creator]
]]

local rules = [[It is recommended to use English language in the clan description and name, but other languages are also acceptable.
The name should be appropriate for all age groups and cultures.
The clan name should be distinctive and not similar to existing clans. Avoid using offensive, obscene, or profane words or phrases.
Сolor and description are optional fields.]]


local function error_form(player_name, label)
	local bf = string.format(base_formspec, "")
	local form = string.format("%slabel[6.25,3.75;%s]button_exit[8,8;1.5,1;;OK]", bf, label)
	minetest.show_formspec(player_name, cc_formname, form)

end

local function creator_form(player_name, label, clan_name, new_color, desc)
	new_color = new_color or ""
	clan_name = clan_name or ""
	desc = desc or ""

	local jitter = math.random(1, 100) -- Hack! Forcing the engine to update the input fields
	local form = string.format(base_formspec, "box[0,0;6,7.5;#17223e]")
		.. "textarea[6.5,0.5;11,5;;Rules;" .. rules .."]"
		.. "field[0.5,1.5;3,0.8;clan_name;Clan Name;" .. clan_name .. "]"
		.. "field[0.5,3;3,0.8;color;Prefix Color;" .. new_color .. "]"
		.. "box[0,3;0.2,0.8;" .. new_color .. "]"
		.. "field[0.5,4.5;5,0.8;short_desc;Short Description;" .. desc .. "]"
		.. "image_button[3.5,3;0.8,0.8;ctf_clans_random_color.png;random_color;]"
		.. "button[0.5,8;2.5,0.8;create;Create]"
		.. "button_exit[17.500" .. tostring(jitter) .. ",0;1,1;;X]"

	if label then
		form = form .. "label[4,8.3;" .. minetest.colorize("red", label) .. "]"
	end

	minetest.show_formspec(player_name, cc_formname, form)
	if not formspec_data[player_name] then
		formspec_data[player_name] = {}
	end
end

function ctf_clans.show_clan_creator(player_name)
	local curr_id = ctf_clans.get_clan_id(player_name)
	if curr_id then
		local clan_name = ctf_clans.get_clan_name(curr_id)
		local label = "You're already a member of a clan " .. minetest.colorize("yellow", clan_name) .. ".\nLeave a clan before you can start a new one."
		error_form(player_name, label)
		return
	end

	creator_form(player_name)
end

local function check_color(color)
    local pattern = "^#(%x%x%x%x%x%x)$"
    local match = string.match(color, pattern)
    return match ~= nil
end

local function generate_random_color()
	local color = ""
	for i = 1, 6 do
		local hex_digit = string.format("%X", math.random(0, 15))
		color = color .. hex_digit
	end
	return "#" .. color
end

local function truncate_string(str, max_length)
	if type(str) == "string" then
		if string.len(str) < max_length then
			return str
		else
			return string.sub(str, 1, max_length)
		end
	else
		return ""
	end
end

local function has_newline(str)
    local _, count = string.gsub(str, "\n", "")
    return count > 0
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= cc_formname then
		return
	end

	local player_name = player:get_player_name()
	local fd = formspec_data[player_name]
	if not fd then return end

	if fields.quit then
		fd = nil
		return
	end

	local desc = fields.short_desc:trim()
	local cn = fields.clan_name:trim()
	local color = fields.color:trim()

	local function update_form(label)
		creator_form(player_name, label, truncate_string(cn, 15), truncate_string(color, 7), truncate_string(desc, 60))
	end


	if fields.create then
		local new_clan = {
			owner = player_name,
			clan_name = ""
		}

		if cn and cn ~= "" then
			if #cn >= 3 and #cn <= 15 then
				if has_newline(cn) then
					update_form("Newline is not allowed in the clan name")
					return
				end
				new_clan.clan_name = cn
			else
				update_form("Сlan name must be no less than 3 and no more than 15 characters")
				return
			end
		else
			update_form("You didn't specify a clan name")
			return
		end

		if desc and desc ~= "" then
			if #desc >= 5 and #desc <= 60 then
				if has_newline(desc) then
					update_form("Newline is not allowed in the description")
					return
				end
				new_clan.description = desc
			else
				update_form("Description must be no less than 5 and no more than 60 characters")
				return
			end
		end

		if color and color ~= "" then
			if check_color(color) then
				new_clan.color = color
			else
				update_form("Incorrect color format")
				return
			end
		end

		-- Create a new clan with the provided parameters
		local id = ctf_clans.create(player_name, new_clan)
		if id then
			local bf = string.format(base_formspec, "")
			local ht = string.format("hypertext[2,1;15,4;hypertext;<bigger>Congratulations, now you're owner of \"%s\".</bigger>\n"
				.. "Invite new members and enjoy the game!\nClan ID:%s]", new_clan.clan_name, id)
			local form = string.format("%s%sbutton_exit[8,8;1.5,1;;OK]", bf, ht)
			minetest.show_formspec(player_name, cc_formname, form)
			sfinv.set_page(player, "sfinv:clans") -- refresh the inventory page
		else
			error_form(player_name, "Oh, sh, you're broken it!\nPlease inform admins")
		end

	elseif fields.random_color then
		creator_form(player_name, nil, cn, generate_random_color(), desc)
		return
	end
end)

minetest.register_chatcommand("clan_creator", {
	description = "Create a new clan",
	privs = {},
	params = "",
	func = function(name, param)
		ctf_clans.show_clan_creator(name)
	end
})
