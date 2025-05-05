--[[
RandomMessages mod by arsdragonfly.
arsdragonfly@gmail.com
6/19/2013
--]]

random_messages = {}

if minetest.settings:get("random_messages_disabled") == "true" then return end

local messages = {
    "To talk only with your team, start your messages with /t. For example, /t Hello team!",
    "Use apples to quickly restore your health.",
    "Moving or fighting can prevent an inactivity kick.",
    "Earn more score by killing more than you die, healing teammates with bandages, or capturing the flag.",
    "You gain more score the better the opponent you defeat.",
    "Find weapons in chests or mine and use furnaces to craft stronger swords.",
    "Use team doors (steel) to prevent the enemy from entering your base.",
    "Sprint by pressing the sprint key (E) when you have stamina.",
    "Want to submit your own map? Visit https://discord.gg/KuUXcBuG5M to get involved.",
    "Using limited resources to build structures that don't strengthen your base's defenses is discouraged.",
    "To report misbehaving players to moderators, please use /report <name> <action> or send the report on Discord: ctf.jma-sig.de",
    "Swearing, trolling, and being rude will not be tolerated, and strict action will be taken.",
    "Trapping teammates on purpose is strictly against the rules, and you will be kicked immediately.",
    "Help your team claim victory by storing extra weapons in the team chest, and never taking more than you need.",
    "Excessive spawn-killing is a direct violation of the rules - appropriate punishments will be given.",
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
    "Consider joining our Discord server at https://discord.gg/SSd9XcCqZk",
    "You can press sneak while jumping to jump up two blocks.",
    "Use /donate <playername> <score> to reward a teammate for their work.",
    "A medic and knight working together can wreak havoc on the enemy team(s).",
    "Check/news to see our recent updates and rules, you will also figure out how to get the [PRO] tag at that page.",
    "Join us on Discord: https://ctf.jma-sig.de",
    "Use /news to see the server news",
    "Please avoid or refrain from introducing any other potentially offensive or inappropriate topics.",
    "Stuck? Use /killme to return to base",
    "Strengthen your defense: build walls, set obstacles, and traps to secure your base.",
    "Want to skip a match? Use /yes to vote during build time",
    "Want to get a new skin? Send it to us at https://discord.gg/SSd9XcCqZk",
    "Try modern HUD instead of hearts/arrows (in the in-game settings)",
    "It is recommended that you avoid sharing personal information such as your address, phone number, or other confidential data to ensure your safety and privacy.",
    -- connection, fps, minetest issues
    "To ensure smooth gameplay, we recommend updating to the latest version of Minetest",
    "If you on older hardware or a mobile device, adjust to lower graphics for smoother gameplay, improving FPS.",
    "Having a stable internet connection is crucial as it minimizes lag, ensuring smoother multiplayer interactions",
    --translator usage tips
    "Overcoming a language barrier? Use a translator in the chat by adding %<language code> after your message, e.g, %en or %ен",
    "Set your preferred language for in-game translator using /lang <lang code> . For example, use /lang en",
    "Use /b to translate the last message to your preferred language",
    "Want to send a nice welcoming message with the 8 score gift? Use /wb <mode:technical modename> <playername>",
    "To report a player sending inappropriate private messages to you, use /report playername PM reason",
    "The chaos mode is active on weekends only.",
    "Use /change_vote <questionID> to change your vote on the poll. Check question ID with /list_questions",
    "Keep the team door closed to stop enemies from getting in",
    "Use /rules to read the server rules",
    "You can claim the crown as a reward for joining our Discord server",
    "Your VPS service is being blocked? Contact our server staff so we can whitelist you",
    "Use /e to send emojis into the air",
    "You have problems exiting the game? Use /kickme to get disconnected from the server",
    "Check your connection latency to the server with /ping",
    "Want to check match status? Type /match to see current mode, map details and teams info",
}

local MESSAGE_INTERVAL = tonumber(minetest.settings:get("random_messages_interval")) or 120

function random_messages.get_random_message()
	return messages[math.random(1, #messages)]
end

local timer = 0
minetest.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer > MESSAGE_INTERVAL then
        if #minetest.get_connected_players() > 0 then
			minetest.chat_send_all(minetest.colorize("#808080", random_messages.get_random_message()), "random_messages")
        end
        timer = 0
    end
end)
