local ServerScriptService = game:GetService("ServerScriptService")

local Remotes = require(ServerScriptService.Server.Remotes)
local DataService = require(ServerScriptService.Server.Services.DataService)

local PLOT_POSITIONS = {
	Vector3.new(0, 1, 0),
}
local MAX_PLOTS = 1

local MAX_CAPACITY = 30
local UPGRADE_BASE_COST = 500
local UPGRADE_COST_MULTIPLIER = 2.5

local playerPlots = {}
local occupiedPlots = {}

local BaseService = {}
BaseService.MAX_CAPACITY = MAX_CAPACITY

local function handleUpgradeCapacity(player: Player)
	local data = DataService.getData(player)
	if not data then
		warn("[BaseService] UpgradeCapacity: No data for " .. player.Name)
		return
	end

	if data.baseCapacity >= MAX_CAPACITY then
		warn("[BaseService] UpgradeCapacity: Already at max capacity for " .. player.Name)
		return
	end

	local cost = math.floor(UPGRADE_BASE_COST * UPGRADE_COST_MULTIPLIER ^ (data.baseCapacity - 1))

	if not DataService.subtractMoney(player, cost) then
		warn("[BaseService] UpgradeCapacity: Insufficient money for " .. player.Name)
		return
	end

	data.baseCapacity = data.baseCapacity + 1
	Remotes.CapacityUpdated:FireClient(player, { current = #data.ownedBrainrots, max = data.baseCapacity })
	print("[BaseService] " .. player.Name .. " upgraded capacity to " .. data.baseCapacity)
end

function BaseService.getUpgradeCost(player: Player): number?
	local data = DataService.getData(player)
	if not data then
		return nil
	end
	if data.baseCapacity >= MAX_CAPACITY then
		return nil
	end
	return math.floor(UPGRADE_BASE_COST * UPGRADE_COST_MULTIPLIER ^ (data.baseCapacity - 1))
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
