minetest.register_abm({
    label = "Cactus damage",
    nodenames = {"default:cactus"},
    interval = 1.0,
    chance = 1,
    action = function(pos, node, active_object_count, active_object_count_wider)
        local objs = minetest.get_objects_inside_radius(pos, 1.5)
		for _, obj in ipairs(objs) do
            if obj:is_player() then
                minetest.log("action", "[cactus_mod] Player taking damage from cactus.")
                obj:set_hp(obj:get_hp() - 1)
            end
        end
    end,
})

