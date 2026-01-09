--[[
RandomMessages mod by arsdragonfly.
arsdragonfly@gmail.com
6/19/2013
--]]

local MAP_SUBMISSION_URL = "https://discord.gg/KuUXcBuG5M"
local DISCORD_SERVER = "https://ctf.jma-sig.de"

local S = core.get_translator(core.get_current_modname())

random_messages = {}

if core.settings:get("random_messages_disabled") == "true" then
	return
end

local messages = {
	S("You can give feedback to server admin and game developers using /feedback"),
	S(
		"Heal the flag thief on your team, and when they capture, you will also get a reward."
	),
	S("You get more score for killing a flag thief than if they didn't have the flag"),
	S(
		"Want someone dead on enemy team for real? Try putting a bounty of 16 score on them: /bo targetName 16"
	),
	S(
		"A group of medics and knights are closing in? Target the medic(s) with shooter's grenade!"
	),
	S("You get more attempt score the closer you get to your own flag"),
	S(
		"If someone walks into your spike and dies, you get a kill. But a bug in kill log, shows the incorrect weapon. Sometimes hands or torches. Funny?"
	),
	S(
		"To talk only with your team, start your messages with /t. For example, /t Hello team!"
	),
	S("Use apples to quickly restore your health."),
	S("Moving or fighting can prevent an inactivity kick."),
	S(
		"Earn more score by killing more than you die, healing teammates with bandages, or capturing the flag."
	),
	S("You gain more score the better the opponent you defeat."),
	S("Find weapons in chests or mine and use furnaces to craft stronger swords."),
	S("Use team doors (steel) to prevent the enemy from entering your base."),
	S("Sprint by pressing the sprint key (E) when you have stamina."),
	S("Want to submit your own map? Visit @1 to get involved.", MAP_SUBMISSION_URL),
	"Using limited resources to build structures that don't strengthen your base's defenses is discouraged.",
	"Help your team claim victory by storing extra weapons in the team chest, and never taking more than you need.",
	"Use /r to check your rank and other statistics.",
	"Use /r <playername> to check the rankings of another player.",
	"Use bandages on teammates to heal them by 3-4 HP if their health is below 15 HP.",
	"Use /m to add a team marker at a pointed location, visible only to teammates.",
	"Use /summary (or /s) to check scores of the current match and the previous match.",
	"Strengthen your team by capturing enemy flags.",
	"Hitting your enemy does more damage than not hitting them.",
	"Use /top50 command to see the leaderboard.",
	"Use /top50 <mode:technical modename> to see the leaderboard in another mode."
		.. " For example: /top50 mode:nade_fight.",
	"To check someone's rank in another mode, use /r <mode:technical modename> <playername>."
		.. " For example: /r mode:nade_fight randomplayer.",
	"To check someone's team, use /team player <player_name>.",
	"To check all team members, use /team.",
	"You can capture multiple enemy flags at once!",
	S("Consider joining our Discord server at @1", DISCORD_SERVER),
	"You can press sneak while jumping to jump up two blocks.",
	S("Use /donate <playername> <score> to reward a teammate for their work."),
	"A medic and knight working together can wreak havoc on the enemy team(s).",
	"Check/news to see our recent updates and rules, you will also figure out how to get the [PRO] tag at that page.",
	S("Join us on Discord: @1", DISCORD_SERVER),
	"Use /news to see the server news",
	"Stuck? Use /killme to return to base",
	"Strengthen your defense: build walls, set obstacles, and traps to secure your base.",
	S("Want to get a new skin? Send it to us at @1", DISCORD_SERVER),
	"Try modern HUD instead of hearts/arrows (in the in-game settings)",
	S(
		"It is recommended that you avoid sharing personal information such as your address, phone number, or other confidential data to ensure your safety and privacy."
	),
	-- connection, fps, minetest issues
	"To ensure smooth gameplay, we recommend updating to the latest version of Minetest",
	"If you on older hardware or a mobile device, adjust to lower graphics for smoother gameplay, improving FPS.",
	"Having a stable internet connection is crucial as it minimizes lag, ensuring smoother multiplayer interactions",
	"If you can't open chests, exit then rejoin the game",
	"Your VPS service is being blocked? Contact our server staff so we can whitelist you",
	"Check your connection latency to the server with /ping",
	--translator usage tips
	S(
		"Overcoming a language barrier? Use a translator in the chat by adding %<language code> after your message, e.g, %en or %ен"
	),
	S(
		"Set your preferred language for in-game translator using /lang <lang code> . For example, use /lang en"
	),
	S("Use /b to translate the last message to your preferred language"),
	--other
	S(
		"Want to send a nice welcoming message with the 8 score gift? Use /wb <mode:technical modename> <playername>"
	),
	S("The chaos mode is active on weekends only."),
	"Use /change_vote <questionID> to change your vote on the poll. Check question ID with /list_questions",
	"Keep the team door closed to stop enemies from getting in",
	"You can claim the crown as a reward for joining our Discord server",
	"Use /e to send emojis into the air",
	"You have problems exiting the game? Use /kickme to get disconnected from the server",
	"Want to check match status? Type /match to see current mode, map details and teams info",
	"Want to enter Elysium? Heal 100 HP and capture 1 flag to unlock access for 24 hours! Check progress with /eprogress",

	--Security & rules related messages
	"Use /rules to read the server rules",
	"You can report player who don't behave to the server staff my using /report <name> <action>.",
	"You can find our Terms Of Service and the privacy policy on our GitHub page: https://github.com/Minetest-JMA-group/information/",
	"It is recommended that you avoid sharing personal information such as your address, phone number, or other confidential data to ensure your safety and privacy."
	"Please avoid or refrain from introducing any other potentially offensive or inappropriate topics.",
	"Excessive spawn-killing is a direct violation of the rules - appropriate punishments will be given.",
	"Using a unofficial client builds or modified clients which gives unfair game advantage is strictly forbidden and will result in a ban. ",
	"Swearing, trolling, and being rude will not be tolerated, and strict action will be taken.",
	"Trapping teammates on purpose is strictly against the rules, doing so will result in a ban.",
	S("To report misbehaving players to moderators, please use /report <name> <action> or send the report on Discord: @1", DISCORD_SERVER),
}

local MESSAGE_INTERVAL = tonumber(core.settings:get("random_messages_interval")) or 120

function random_messages.get_random_message()
	return messages[math.random(1, #messages)]
end

local timer = 0
core.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer > MESSAGE_INTERVAL then
		if #core.get_connected_players() > 0 then
			core.chat_send_all(
				core.colorize("#808080", random_messages.get_random_message()),
				"random_messages"
			)
		end
		timer = 0
	end
end)
