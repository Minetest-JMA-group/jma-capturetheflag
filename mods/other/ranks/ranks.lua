-- ranks/ranks.lua

ranks.register("admin", {
	prefix = "[Admin]",
	colour = {a = 255, r = 255, g = 0, b = 0},
})

ranks.register("moderator", {
	prefix = "[Moderator]",
	colour = {a = 255, r = 60, g = 60, b = 200},
	grant_missing = true,
	privs = {
		pmute = true,
		fly = true,
		fast = true,
		vanish = true,
		kick = true,
		moderator = true,
		ban = true,
	},
})

ranks.register("guardian", {
	prefix = "[Guardian]",
	colour = {a = 255, r = 120, g = 130, b = 150},
	grant_missing = true,
	privs = {
		moderator = true,
		kick = true,
		pmute = true,
	},
})

ranks.register("Developer", {
	prefix = "[Developer]",
	colour = {a = 255, r = 190, g = 0, b = 200},
	grant_missing = true,
	privs = {
		dev = true,
	}
})

ranks.register("DevGuardian", {
	prefix = "[Dev&Guardian]",
	colour = {a = 255, r = 100, g = 130, b = 230},
	grant_missing = true,
	privs = {
		moderator = true,
		kick = true,
		pmute = true,
		dev = true,
	},
})

ranks.register("youtube", {
	prefix = "[YouTuber]",
	colour = {a = 255, r = 200, g = 30, b = 30},
})

ranks.register("pro", {
	prefix = "[PRO]",
	colour = {a = 255, r = 0, g = 255, b = 0},
})

ranks.register("speedrunner", {
	prefix = "[SpeedRunner]",
	colour = {a = 255, r = 0, g = 255, b = 255},
})
