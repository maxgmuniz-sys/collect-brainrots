local ServerScriptService = game:GetService("ServerScriptService")

local Remotes = require(ServerScriptService.Server.Remotes)
local DataService = require(ServerScriptService.Server.Services.DataService)

local PLOT_POSITIONS = {
	Vector3.new(0, 1, 0),
}
local MAX_PLOTS = 1

local playerPlots = {}
local occupiedPlots = {}

local BaseService = {}

local function handleUpgradeCapacity(player: Player)
	warn("Capacity upgrade not available in Phase 1")
end

function BaseService.init()
	Remotes.UpgradeCapacity.OnServerEvent:Connect(handleUpgradeCapacity)
end

function BaseService.onPlayerAdded(player: Player)
	for i = 1, MAX_PLOTS do
		if not occupiedPlots[i] then
			occupiedPlots[i] = true
			playerPlots[player] = i
			return
		end
	end
	warn("[BaseService] No available plots for " .. player.Name)
end

function BaseService.onPlayerRemoving(player: Player)
	local plotIndex = playerPlots[player]
	if not plotIndex then
		return
	end
	occupiedPlots[plotIndex] = nil
	playerPlots[player] = nil
end

function BaseService.getPlotPosition(player: Player): Vector3?
	local plotIndex = playerPlots[player]
	if not plotIndex then
		return nil
	end
	return PLOT_POSITIONS[plotIndex]
end

function BaseService.canAddBrainrot(player: Player): boolean
	local data = DataService.getData(player)
	if not data then
		return false
	end
	return #data.ownedBrainrots < data.baseCapacity
end

function BaseService.getCapacity(player: Player): (number, number)
	local data = DataService.getData(player)
	if not data then
		return 0, 0
	end
	return #data.ownedBrainrots, data.baseCapacity
end

return BaseService
