local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local DataService = require(ServerScriptService.Server.Services.DataService)
local Remotes = require(ServerScriptService.Server.Remotes)

local earningsCache = {}

local EarningsService = {}

function EarningsService.recalculate(player: Player)
	local data = DataService.getData(player)
	if not data then
		earningsCache[player] = 0
		return
	end

	local total = 0
	for _, brainrot in data.ownedBrainrots do
		total += brainrot.earningsPerSec
	end

	earningsCache[player] = total
	Remotes.EarningsUpdated:FireClient(player, { earningsPerSec = total })
end

local function earningsLoop()
	while true do
		task.wait(1)
		for _, player in Players:GetPlayers() do
			local totalEarnings = earningsCache[player]
			if totalEarnings and totalEarnings > 0 then
				DataService.addMoney(player, totalEarnings)
			end
		end
	end
end

function EarningsService.init()
	task.spawn(earningsLoop)

	Players.PlayerRemoving:Connect(function(player)
		earningsCache[player] = nil
	end)
end

return EarningsService
