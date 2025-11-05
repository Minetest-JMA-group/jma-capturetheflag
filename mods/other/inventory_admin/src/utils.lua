inventory_admin.utils = {} 

function inventory_admin.utils.is_mineclone2()
    return core.get_modpath("mcl_core") ~= nil
end