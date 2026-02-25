local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Brainrots = require(ReplicatedStorage.Shared.Config.Brainrots)
local Mutations = require(ReplicatedStorage.Shared.Config.Mutations)
local DataService = require(ServerScriptService.Server.Services.DataService)
local BaseService = require(ServerScriptService.Server.Services.BaseService)
local EarningsService = require(ServerScriptService.Server.Services.EarningsService)
local Remotes = require(ServerScriptService.Server.Remotes)

local SELL_SECONDS = 60

local SellService = {}

local function calculateSellValue(brainrot): number
	local config = Brainrots.BRAINROT_BY_NAME[brainrot.name]
	if not config then
		warn("[SellService] Unknown brainrot: " .. tostring(brainrot.name))
		return 0
	end

	local baseEarnings = config.baseEarningsPerSec
	local sizeMult = brainrot.size
	local baseMutMult = Mutations.getBaseMutationMultiplier(brainrot.baseMutation)

	return math.floor(baseEarnings * SELL_SECONDS * sizeMult * baseMutMult)
end

local function handleSellBrainrot(player: Player, data: { [string]: any })
	local playerData = DataService.getData(player)
	if not playerData then
		warn("[SellService] No data for " .. player.Name)
		return
	end

	local brainrotId = data.brainrotId
	if type(brainrotId) ~= "string" then
		warn("[SellService] Invalid brainrotId from " .. player.Name)
		return
	end

	-- Find brainrot by id
	local brainrot = nil
	local brainrotIndex = nil
	for i, b in playerData.ownedBrainrots do
		if b.id == brainrotId then
			brainrot = b
			brainrotIndex = i
			break
		end
	end

	if not brainrot then
		warn("[SellService] Brainrot not found: " .. brainrotId)
		return
	end

	local sellValue = calculateSellValue(brainrot)

	table.remove(playerData.ownedBrainrots, brainrotIndex)
	DataService.addMoney(player, sellValue)
	EarningsService.recalculate(player)

	local current, max = BaseService.getCapacity(player)
	Remotes.CapacityUpdated:FireClient(player, { current = current, max = max })
	Remotes.SellConfirmed:FireClient(player, { soldCount = 1, totalValue = sellValue, soldIds = { brainrotId } })

	-- Phase 9: broadcast rival update
	BaseService.broadcastRivalUpdate(player)
end

local function handleSellAll(player: Player)
	local playerData = DataService.getData(player)
	if not playerData then
		warn("[SellService] No data for " .. player.Name)
		return
	end

	if #playerData.ownedBrainrots == 0 then
		warn("[SellService] No brainrots to sell for " .. player.Name)
		return
	end

	local totalValue = 0
	local soldCount = #playerData.ownedBrainrots
	local soldIds = {}

	for _, brainrot in playerData.ownedBrainrots do
		totalValue += calculateSellValue(brainrot)
		table.insert(soldIds, brainrot.id)
	end

	playerData.ownedBrainrots = {}
	DataService.addMoney(player, totalValue)
	EarningsService.recalculate(player)

	Remotes.CapacityUpdated:FireClient(player, { current = 0, max = playerData.baseCapacity })
	Remotes.SellConfirmed:FireClient(player, { soldCount = soldCount, totalValue = totalValue, soldIds = soldIds })

	-- Phase 9: broadcast rival update
	BaseService.broadcastRivalUpdate(player)
end

function SellService.init()
	Remotes.SellBrainrot.OnServerEvent:Connect(handleSellBrainrot)
	Remotes.SellAll.OnServerEvent:Connect(handleSellAll)
end

return SellService
