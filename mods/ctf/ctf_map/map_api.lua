minetest.register_globalstep(function(dtime)
	if ctf_map.globalstep_function then
		pcall(ctf_map.globalstep_function, dtime)
	end
end)

function ctf_map.set_globalstep_function(globalstep_function)
    if globalstep_function == nil then
        ctf_map.globalstep_function = nil
    elseif type(globalstep_function) == "function" then
        ctf_map.globalstep_function = globalstep_function
    else
        error("globalstep_function must be a function or nil, got " .. type(globalstep_function))
    end
end


ctf_api.register_on_match_end(function()
	minetest.after(0, function()
		ctf_map.globalstep_function = nil
	end)
end)