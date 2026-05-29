-- NOTE:
-- Public skins starts from 1 to 199
-- Private skins starts from 200 to 299

--Example of skin definition table:
--[1] = {
--	name = "Josh",
--	author = "juan", -- Optional
--	texture = "character_josh.png", -- Optional, if not set, the skin will be loaded from "character_1.png (deprecated format)
--	private = true, -- Optional, if not set or false, the skin will be public
--},

-- It is very important to keen unique IDs for skins!
-- Add new skins with ID higher than the last one and keep the IDs range from 1 to 199 for public skins

return {
	[1] = {
		name = "Mikey",
		author = "Maintainer",
	},
	[2] = {
		name = "Kirito",
		author = "Maintainer",
	},
	[3] = {
		name = "Asuna",
		author = "Maintainer",
	},
	[4] = {
		name = "Fiona",
		author = "loupicate",
	},
	[5] = {
		name = "Ashley",
		author = "loupicate",
	},
	[6] = {
		name = "Sam",
		author = "Minetest devs",
	},
	[7] = {
		name = "Lizardman",
		author = "Nudisohn",
	},
	[8] = {
		name = "Retro",
		author = "isaiah658",
	},
	[9] = {
		name = "Knight",
		author = "isaiah658",
	},
	[10] = {
		name = "Robot",
		author = "isaiah658",
	},
	[11] = {
		name = "Herobrine",
		author = "Player",
	},
	[12] = {
		name = "Uchiha Madara",
		author = "MadaraUchiha",
	},
	[13] = {
		name = "Black and White",
		author = "Kappasettes",
	},
	[14] = {
		name = "Bracciale Rosso Red Ring",
		author = "Kappasette",
	},
	[15] = {
		name = "pmcskin3dsteve",
		author = "Ottobunny",
	},
	[16] = {
		name = "Special OPS",
		author = "0Hi9l",
	},
	[17] = {
		name = "Santa",
		author = "jordan4ibanez",
	},
	[18] = {
		name = "Dumb Herobrine",
		author = "Imakeawfulskins13",
	},
	[19] = {
		name = "Kurohime",
		author = "",
	},
	[20] = {
		name = "TS",
		author = "",
	},
	[21] = {
		name = "Ryoko",
		author = "",
	},
	[22] = {
		name = "GojoSatoru",
		author = "",
	},
	[24] = {
		name = "Koro Sensei",
		author = "0Hi9l",
	},
	[31] = {
		name = "Wolf!!!",
		author = "Rin",
		texture = "character_969.png",
	},
	[33] = {
		name = "SilentRipper_",
		author = "leoleg",
		texture = "character_silentripper.png",
	},
	-- 34 is taken by private skin
	[35] = {
		name = "Flagelite",
		author = "i35",
		licence = "CC BY-I 3.5",
		texture = "character_flagelite.png",
	},
	-- by DrEpicGTM
	[36] = {
		name = "SWAT Officer",
		author = "DrEpicGTM",
		texture = "character_swat.png",
	},
	[37] = {
		name = "Captain Merica",
		author = "DrEpicGTM",
		texture = "character_captain_merica.png",
	},
	[38] = {
		name = "Ninja",
		author = "DrEpicGTM",
		texture = "character_ninja.png",
	},
	[39] = {
		name = "Hazmat Jeff",
		author = "DrEpicGTM",
		texture = "character_hazmat_jeff.png",
	},
	[40] = {
		name = "Red Iron",
		author = "DrEpicGTM",
		texture = "character_red_iron.png",
	},
	[41] = {
		name = "Ancient Mercenary",
		author = "DrEpicGTM",
		texture = "character_ancient_mercenary.png",
	},
	[42] = {
		name = "Sack Jarrow",
		author = "DrEpicGTM",
		texture = "character_sack_jarrow.png",
	},
	[43] = {
		name = "Diver",
		author = "DrEpicGTM",
		texture = "character_diver.png",
	},
	[44] = {
		name = "Professor",
		author = "DrEpicGTM",
		texture = "character_professor.png",
	},
	[45] = {
		name = "Bush Soldier",
		author = "DrEpicGTM",
		texture = "character_bush_soldier.png",
	},
	[46] = {
		name = "NFL Player",
		author = "DrEpicGTM",
		texture = "character_nfl_player.png",
	},

	-- Add new skins here with higher IDs (max 199) --
}
