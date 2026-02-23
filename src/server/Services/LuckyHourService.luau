local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Remotes = require(ServerScriptService.Server.Remotes)

local DURATION = 300 -- 5 minutes
local INTERVAL_MIN = 1800 -- 30 minutes
local INTERVAL_MAX = 3600 -- 60 minutes
local RARITY_BOOST = 2.0

local isLuckyHourActive = false
local luckyHourEndTime = 0

local LuckyHourService = {}

function LuckyHourService.isActive(): boolean
	return isLuckyHourActive
end

function LuckyHourService.getRarityBoost(): number
	if isLuckyHourActive then
		return RARITY_BOOST
	end
	return 1.0
end

function LuckyHourService.getDuration(): number
	return DURATION
end

local function startLuckyHour()
	isLuckyHourActive = true
	luckyHourEndTime = os.clock() + DURATION

	print("[LuckyHourService] Lucky Hour started! Duration: " .. DURATION .. "s")

	for _, player in Players:GetPlayers() do
		Remotes.LuckyHourStarted:FireClient(player, { duration = DURATION })
	end
end

local function endLuckyHour()
	isLuckyHourActive = false
	luckyHourEndTime = 0

	print("[LuckyHourService] Lucky Hour ended.")

	for _, player in Players:GetPlayers() do
		Remotes.LuckyHourEnded:FireClient(player, {})
	end
end

local function schedulingLoop()
	while true do
		local waitTime = math.random(INTERVAL_MIN, INTERVAL_MAX)
		print("[LuckyHourService] Next Lucky Hour in " .. waitTime .. "s")
		task.wait(waitTime)

		startLuckyHour()
		task.wait(DURATION)
		endLuckyHour()
	end
end

local function onPlayerAdded(player: Player)
	if isLuckyHourActive then
		local remaining = math.max(0, math.ceil(luckyHourEndTime - os.clock()))
		if remaining > 0 then
			Remotes.LuckyHourStarted:FireClient(player, { duration = remaining })
		end
	end
end

function LuckyHourService.init()
	task.spawn(schedulingLoop)

	Players.PlayerAdded:Connect(onPlayerAdded)

	-- Handle players already in-game (Studio edge case)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	print("[LuckyHourService] Initialized.")
end

return LuckyHourService
