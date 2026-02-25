local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Remotes = require(ServerScriptService.Server.Remotes)
local DataService = require(ServerScriptService.Server.Services.DataService)

local MAX_PLOTS = 6
local PLOT_SIZE = 30

-- 6 plot positions arranged in a 2x3 grid
local PLOT_POSITIONS = {
	Vector3.new(-50, 0, -50),
	Vector3.new(50, 0, -50),
	Vector3.new(-50, 0, 25),
	Vector3.new(50, 0, 25),
	Vector3.new(-50, 0, 100),
	Vector3.new(50, 0, 100),
}

local MAX_CAPACITY = 30
local UPGRADE_BASE_COST = 500
local UPGRADE_COST_MULTIPLIER = 2.5

-- Maps plot index (1-6) to owning Player (or nil)
local plotOwners = {}
-- Maps Player to their assigned plot index
local playerPlots = {}

local BaseService = {}
BaseService.MAX_CAPACITY = MAX_CAPACITY
BaseService.MAX_PLOTS = MAX_PLOTS
BaseService.PLOT_POSITIONS = PLOT_POSITIONS
BaseService.PLOT_SIZE = PLOT_SIZE

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

local function buildBrainrotSummaries(data): { any }
	local summaries = {}
	for _, brainrot in data.ownedBrainrots do
		table.insert(summaries, {
			name = brainrot.name,
			baseMutation = brainrot.baseMutation,
			weatherMutation = brainrot.weatherMutation,
			size = brainrot.size,
			sizeLabel = brainrot.sizeLabel,
			personality = brainrot.personality,
		})
	end
	return summaries
end

function BaseService.broadcastRivalUpdate(player: Player)
	local plotIndex = playerPlots[player]
	if not plotIndex then
		return
	end

	local data = DataService.getData(player)
	if not data then
		return
	end

	local summaries = buildBrainrotSummaries(data)

	for _, otherPlayer in Players:GetPlayers() do
		if otherPlayer ~= player then
			Remotes.RivalBaseUpdate:FireClient(otherPlayer, {
				plotIndex = plotIndex,
				playerName = player.Name,
				brainrots = summaries,
			})
		end
	end
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
	-- Find first available plot
	local assignedIndex = nil
	for i = 1, MAX_PLOTS do
		if not plotOwners[i] then
			assignedIndex = i
			break
		end
	end

	if not assignedIndex then
		warn("[BaseService] No available plots for " .. player.Name)
		return
	end

	plotOwners[assignedIndex] = player
	playerPlots[player] = assignedIndex

	-- Fire PlotAssigned to the joining player with allPositions so they can create all platforms
	Remotes.PlotAssigned:FireClient(player, {
		plotIndex = assignedIndex,
		plotPosition = PLOT_POSITIONS[assignedIndex],
		allPositions = PLOT_POSITIONS,
		playerName = player.Name,
	})

	-- Broadcast to all OTHER clients that a new player took a plot
	for _, otherPlayer in Players:GetPlayers() do
		if otherPlayer ~= player then
			Remotes.PlotAssigned:FireClient(otherPlayer, {
				plotIndex = assignedIndex,
				plotPosition = PLOT_POSITIONS[assignedIndex],
				playerName = player.Name,
				playerId = player.UserId,
			})
		end
	end

	-- Send existing occupied plots to the joining player (rival data)
	for i = 1, MAX_PLOTS do
		if plotOwners[i] and plotOwners[i] ~= player then
			local owner = plotOwners[i]
			local ownerData = DataService.getData(owner)
			if ownerData then
				local summaries = buildBrainrotSummaries(ownerData)
				Remotes.RivalBaseUpdate:FireClient(player, {
					plotIndex = i,
					playerName = owner.Name,
					brainrots = summaries,
				})
			end
		end
	end
end

function BaseService.onPlayerRemoving(player: Player)
	local plotIndex = playerPlots[player]
	if not plotIndex then
		return
	end

	plotOwners[plotIndex] = nil
	playerPlots[player] = nil

	-- Tell all remaining clients to clear this plot
	Remotes.RivalBaseUpdate:FireAllClients({
		plotIndex = plotIndex,
		playerName = nil,
		brainrots = {},
	})
end

function BaseService.getPlotPosition(player: Player): Vector3?
	local plotIndex = playerPlots[player]
	if not plotIndex then
		return nil
	end
	return PLOT_POSITIONS[plotIndex]
end

function BaseService.getPlotIndex(player: Player): number?
	return playerPlots[player]
end

function BaseService.getAllPlotPositions()
	return PLOT_POSITIONS
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
