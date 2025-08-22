
sfinv.register_page("ctf_jma_achievements:list", {
	title = "Achieves",
	get = function(self, player, context)
		return sfinv.make_formspec(player, context,
				"label[0.1,0.1;Hello world!]", true)
	end
})

