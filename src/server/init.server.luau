-- init.server.luau
-- Server bootstrap: load services in dependency order

local Players = game:GetService("Players")

-- 1. Create all remotes first (must exist before services connect listeners)
local Remotes = require(script.Remotes)

-- 2. Initialize services in dependency order
local DataService = require(script.Services.DataService)
DataService.init()

local BaseService = require(script.Services.BaseService)
BaseService.init()

local EarningsService = require(script.Services.EarningsService)
EarningsService.init()

local IndexService = require(script.Services.IndexService)
IndexService.init()

local FoodService = require(script.Services.FoodService)
FoodService.init()

local SellService = require(script.Services.SellService)
SellService.init()

local WeatherService = require(script.Services.WeatherService)
WeatherService.init()

local GiftService = require(script.Services.GiftService)
GiftService.init()

local LeaderboardService = require(script.Services.LeaderboardService)
LeaderboardService.init()

-- Connect player lifecycle events
Players.PlayerAdded:Connect(function(player)
	DataService.onPlayerAdded(player)
	BaseService.onPlayerAdded(player)
end)

Players.PlayerRemoving:Connect(function(player)
	BaseService.onPlayerRemoving(player)
	DataService.onPlayerRemoving(player)
end)

-- Handle players who joined before the script loaded (Studio edge case)
for _, player in Players:GetPlayers() do
	task.spawn(function()
		DataService.onPlayerAdded(player)
		BaseService.onPlayerAdded(player)
	end)
end

print("[Server] All services initialized.")
