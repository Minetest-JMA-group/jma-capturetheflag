ctf_map_vote_recorder = {}

local sqlite = require("lsqlite3")

local db_path = core.settings:get("map_votes_db_path")

local db

if db_path then
	db = sqlite.open(db_path, sqlite.OPEN_READWRITE + sqlite.OPEN_CREATE + sqlite.OPEN_SHAREDCACHE)
else
	db = sqlite.open_memory()
end

initialize_db()


core.register_on_shutdown(function()
	if db and db:isopen() then
		db:close()
	end
end)

local function initialize_db()
	db:exec([=[
		CREATE TABLE IF NOT EXISTS votes(
			map INTEGER,
			mode INTEGER,
			pname TEXT,
			timestamp DATETIME,
			online_players INTEGER
		);
		CREATE INDEX IF NOT EXISTS votes_index_general ON votes(
			map,
			mode,
			timestamp,
			online_players
		);
		CREATE INDEX IF NOT EXISTS votes_low_pop ON votes(
			map,
			mode,
			timestamp,
			online_players
		) WHERE online_players < 8;
		CREATE INDEX IF NOT EXISTS votes_med_pop ON votes(
			map,
			mode,
			timestamp,
			online_players
		) WHERE online_players >= 8 AND online_players <= 16;
		CREATE INDEX IF NOT EXISTS votes_high_pop ON votes(
			map,
			mode,
			timestamp,
			online_players
		) WHERE online_players > 16;
	]=])
end

--- Record a vote
--- @param map_name string
--- @param mode string
--- @param pname PlayerName
--- @return nil
function ctf_map_vote_recorder.record(map_name, mode, pname)
	local stmt = db:prepare([=[
		INSERT INTO votes (
			map,
			mode,
			pname,
			timestamp,
			online_players
		) VALUES(?, ?, ?, ?, ?);
	]=])
	stmt:bind(1, string_hash(map_name))
	stmt:bind(2, string_hash(mode))
	stmt:bind(3, pname)
	stmt:bind(4, os.time())
	stmt:bind(5, #core.get_connected_players())
	stmt:finalize()
end

--- @param s string
--- @return number
function ctf_map_vote_recorder.string_hash(s)
	local s2 = string.sub(core.sha1(s), 0, 6)
	return tonumber(s2)
end

--- @param mode string
--- @return { [string]: number }
local function get_maps_votes_n(mode)
	local mode_hash = ctf_map_vote_recorder.string_hash(s)
	--- @type { [string]: number }
	local map_votes = {}
	local function counter(udata, ncols, values, names)
		local map_name = values[0]
		if map_votes[map_name] == nil then
			map_votes[map_name] = 0
		end
		map_votes[map_name] = map_votes[map_name] + 1
	end
	db:exec("SELECT (map, pname) FROM votes WHERE mode == " .. mode_hash .. " ;", counter)
	return map_votes
end


--- @param maps ({ map: string, votes: number })[]
--- @return { [string]: number }
local function get_top5(maps, compare_fn)
	table.sort(maps, compare_fn)
	local top5 = {}
	local i = 4
	for _, map in ipairs(maps) do
		if i >= 0 then
			top5[map.map] = map.votes
		end
		i = i - 1
	end
	return top5
end


--- Return 5 most/least popular maps for the mode
--- @param mode string
--- @param most_popular boolean
--- @return { [string]: number }
function ctf_map_vote_recorder.get_top5(mode, most_popular)
	local map_votes = get_maps_votes_n(mode)
	--- @type ({ map: string, votes: number})[]
	local maps = {}
	for map, votes_n in pairs(map_votes) do
		table.insert(maps, {map = map, votes= votes_n})
	end
	local compare_fn
	if most_popular then
		compare_fn = function(a, b)
			return a["votes"] > b["votes"]
		end
	else
		compare_fn = function(a, b)
			return a["votes"] < b["votes"]
		end
	end
	return get_top5(maps, compare_fn)
end

core.register_chatcommand("mtop5", {
	params = "<most|least> <mode> [broadcast]",
	description = "Get 5 most/least popular maps",
	privs = {"dev", "admin", "server"},
	func = function(name, params)
		local most_popular = true
		local most_popular, mode, broadcast = string.match(params, "(.*) (.*) (.*)")
		if most_popular == "l" or most_popular == "least" then
			most_popular = false
		end
		local top5 = ctf_map_vote_recorder.get_top5(mode, most_popular)
		local function send(text)
			if broadcast and (broadcast == "true" or broadcast == "t") then
				core.chat_send_all(text)
			else
				core.chat_send_player(name, text)
			end
		end
		if most_popular then
			send("Most popular maps:")
		else
			send("Least popular maps:")
		end
		for map, votes in pairs(top5) do
			send(map .. ": " .. tostring(votes))
		end
	end
})
