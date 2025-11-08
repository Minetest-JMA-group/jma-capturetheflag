local COOK_TIME = 5 -- seconds

local INFOTEXT = "Medical Furnace\n\n" ..
                    "Right-click with an ore to start."

local medical_recipes = {
    ["default:diamond"] = {output = "ctf_healing:medkit", count = 3},
    ["default:mese_crystal"] = {output = "ctf_healing:medkit", count = 2},
    ["default:steel_ingot"] = {output = "ctf_healing:medkit", count = 1},
}

-- Check if a player can use the furnace
local function can_use_furnace(player)
    local current_mode = ctf_modebase:get_current_mode()

    if current_mode and current_mode.is_restricted_item then
        return not current_mode.is_restricted_item(player, "ctf_healing:medical_furnace")
    end

    return true
end

core.register_node("ctf_healing:medical_furnace", {
    description = INFOTEXT,
    tiles = {
        "medical_furnace_top_bottom.png",
        "medical_furnace_top_bottom.png",
        "default_furnace_side.png",
        "default_furnace_side.png",
        "default_furnace_side.png",
        "default_furnace_front.png",
    },
    groups = { cracky = 2 },
    sounds = default.node_sound_stone_defaults(),
    paramtype2 = "facedir",
    legacy_facedir_simple = true,

    on_construct = function(pos)
        local meta = core.get_meta(pos)
        meta:set_string("infotext", INFOTEXT)
        meta:set_int("src_time", 0)
        meta:set_string("input_item", "")
        core.get_node_timer(pos):start(1)
    end,

    -- Right-click to insert item
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        if can_use_furnace(clicker) then
            local meta = core.get_meta(pos)
            if meta:get_string("input_item") == "" and not itemstack:is_empty() then
                local name = itemstack:get_name()
                if medical_recipes[name] then
                    meta:set_string("input_item", name)
                    itemstack:take_item()
                end
            end
        end
        
        return itemstack
    end,

    -- Timer to cook
    on_timer = function(pos)
        local meta = core.get_meta(pos)
        local item = meta:get_string("input_item")

        if item ~= "" then
            local progress = meta:get_int("src_time") + 1
            meta:set_int("src_time", progress)
            meta:set_string("infotext", "Cooking... (" .. progress .. "/" .. COOK_TIME .. ")")

            if progress >= COOK_TIME then
                local recipe = medical_recipes[item]
                if recipe then
                    core.sound_play("default_cool_lava", {
                        pos = pos,
                        gain = 0.5,
                        max_hear_distance = 16,
                        loop = false,
                    })

                    for i = 1, recipe.count do
                        core.after(i, function()
                            core.add_item(pos, recipe.output)
                        end)
                    end
                end

                meta:set_string("input_item", "")
                meta:set_int("src_time", 0)
                meta:set_string("infotext", INFOTEXT)
            end
        end

        return true
    end,

    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        local leftover = oldmetadata.fields.input_item
        if leftover and leftover ~= "" then
            core.add_item(pos, leftover)
        end
    end,
})
