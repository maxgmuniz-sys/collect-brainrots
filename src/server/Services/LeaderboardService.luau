local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local DataService = require(ServerScriptService.Server.Services.DataService)
local Remotes = require(ServerScriptService.Server.Remotes)

local UPDATE_INTERVAL = 60
local LEADERBOARD_SIZE = 50
local LEADERBOARD_VERSION = "v1"

local STORE_NAMES = {
	MostMoney = "Leaderboard_MostMoney_" .. LEADERBOARD_VERSION,
	MostTime = "Leaderboard_MostTime_" .. LEADERBOARD_VERSION,
	MostRobux = "Leaderboard_MostRobux_" .. LEADERBOARD_VERSION,
}

local STAT_FIELDS = {
	MostMoney = "totalMoneyEarned",
	MostTime = "totalTimePlayed",
	MostRobux = "totalRobuxSpent",
}

local DISPLAY_NAMES = {
	MostMoney = "Most Money Earned",
	MostTime = "Most Time Played",
	MostRobux = "Most Robux Spent",
}

local orderedStores = {}
local cachedResults = {}
local isRunning = false

local LeaderboardService = {}

local function resolvePlayerName(userId: number): string
	local onlinePlayer = Players:GetPlayerByUserId(userId)
	if onlinePlayer then
		return onlinePlayer.Name
	end

	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)

	if ok and name then
		return name
	end

	return "Player_" .. tostring(userId)
end

local function updateLeaderboards()
	-- Push phase: push all online players' stats
	for _, player in Players:GetPlayers() do
		local data = DataService.getData(player)
		if not data then
			continue
		end

		for key, field in STAT_FIELDS do
			if not orderedStores[key] then
				continue
			end

			local value = data[field]

			-- For time, add current session elapsed time
			if key == "MostTime" then
				local sessionStart = DataService.getSessionStartTime(player)
				if sessionStart then
					value = value + (os.clock() - sessionStart)
				end
			end

			value = math.floor(value)

			if value > 0 then
				local ok, err = pcall(function()
					orderedStores[key]:SetAsync(tostring(player.UserId), value)
				end)

				if not ok then
					warn("[LeaderboardService] Failed to push " .. key .. " for " .. player.Name .. ": " .. tostring(err))
				end
			end
		end
	end

	-- Fetch phase: get top 50 for each leaderboard
	for key, _ in STORE_NAMES do
		if not orderedStores[key] then
			continue
		end

		local ok, result = pcall(function()
			return orderedStores[key]:GetSortedAsync(false, LEADERBOARD_SIZE)
		end)

		if not ok then
			warn("[LeaderboardService] Failed to fetch " .. key .. ": " .. tostring(result))
			continue
		end

		local pageOk, page = pcall(function()
			return result:GetCurrentPage()
		end)

		if not pageOk then
			warn("[LeaderboardService] Failed to get page for " .. key .. ": " .. tostring(page))
			continue
		end

		local entries = {}
		for rank, entry in ipairs(page) do
			local userId = tonumber(entry.key)
			table.insert(entries, {
				rank = rank,
				userId = userId,
				value = entry.value,
				name = resolvePlayerName(userId),
			})
		end

		cachedResults[key] = entries
	end
end

local function updateLoop()
	while isRunning do
		task.wait(UPDATE_INTERVAL)

		local ok, err = pcall(updateLeaderboards)
		if not ok then
			warn("[LeaderboardService] Update cycle failed: " .. tostring(err))
		end
	end
end

local function handleRequestLeaderboard(player: Player)
	local response = {
		MostMoney = cachedResults.MostMoney or {},
		MostTime = cachedResults.MostTime or {},
		MostRobux = cachedResults.MostRobux or {},
		displayNames = DISPLAY_NAMES,
	}

	Remotes.LeaderboardData:FireClient(player, response)
end

function LeaderboardService.init()
	for key, storeName in STORE_NAMES do
		local ok, store = pcall(function()
			return DataStoreService:GetOrderedDataStore(storeName)
		end)
		if ok then
			orderedStores[key] = store
		else
			warn("[LeaderboardService] Failed to get OrderedDataStore for " .. key .. ": " .. tostring(store))
		end
	end

	for key, _ in STORE_NAMES do
		cachedResults[key] = {}
	end

	Remotes.RequestLeaderboard.OnServerEvent:Connect(handleRequestLeaderboard)

	isRunning = true
	task.spawn(updateLoop)

	print("[LeaderboardService] Initialized with " .. UPDATE_INTERVAL .. "s update interval.")
end

return LeaderboardService
