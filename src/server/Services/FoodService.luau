local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Brainrots = require(ReplicatedStorage.Shared.Config.Brainrots)
local Foods = require(ReplicatedStorage.Shared.Config.Foods)
local Sizes = require(ReplicatedStorage.Shared.Config.Sizes)
local Utils = require(ReplicatedStorage.Shared.Utils)
local DataService = require(ServerScriptService.Server.Services.DataService)
local BaseService = require(ServerScriptService.Server.Services.BaseService)
local EarningsService = require(ServerScriptService.Server.Services.EarningsService)
local Remotes = require(ServerScriptService.Server.Remotes)

local FoodService = {}

local function handleBuyFood(player: Player, data: { [string]: any })
	-- Validate player data
	local playerData = DataService.getData(player)
	if not playerData then
		warn("[FoodService] No data for " .. player.Name)
		return
	end

	-- Validate food tier name
	local foodTier = data.foodTier
	if type(foodTier) ~= "string" then
		warn("[FoodService] Invalid foodTier type from " .. player.Name)
		return
	end

	-- Validate food tier exists
	local food = Foods.FOOD_BY_NAME[foodTier]
	if not food then
		warn("[FoodService] Unknown food tier: " .. foodTier)
		return
	end

	-- Validate money
	if playerData.money < food.cost then
		warn("[FoodService] Not enough money for " .. player.Name)
		return
	end

	-- Validate capacity
	if not BaseService.canAddBrainrot(player) then
		warn("[FoodService] Base is full for " .. player.Name)
		return
	end

	-- Deduct money
	if not DataService.subtractMoney(player, food.cost) then
		warn("[FoodService] Failed to deduct money for " .. player.Name)
		return
	end

	-- Roll rarity using the food tier's own rarityWeights
	local rarityWeights = food.rarityWeights
	local rolledRarity = Utils.weightedRandom(rarityWeights)

	-- Roll brainrot
	local nameList = Brainrots.BRAINROTS_BY_RARITY[rolledRarity]
	local rolledName = nameList[math.random(1, #nameList)]
	local brainrotConfig = Brainrots.BRAINROT_BY_NAME[rolledName]

	-- Roll size tier and get a random size value within that tier's range
	local size, sizeLabel = Sizes.rollSize()

	-- Compute weight based on brainrot's base weight scaled by size
	local weight = Sizes.getWeight(brainrotConfig.name, size)

	-- Size IS the earnings multiplier
	local earningsPerSec = brainrotConfig.baseEarningsPerSec * size

	-- Construct BrainrotInstance
	local brainrotInstance = {
		id = Utils.generateId(),
		name = brainrotConfig.name,
		rarity = brainrotConfig.rarity,
		size = size,
		sizeLabel = sizeLabel,
		weight = weight,
		baseMutation = nil,
		weatherMutation = nil,
		personality = nil,
		earningsPerSec = earningsPerSec,
	}

	-- Roll stay chance
	if math.random() <= food.stayChance then
		-- Brainrot stays
		table.insert(playerData.ownedBrainrots, brainrotInstance)
		EarningsService.recalculate(player)
		Remotes.BrainrotSpawned:FireClient(player, { brainrotData = brainrotInstance })

		local current, max = BaseService.getCapacity(player)
		Remotes.CapacityUpdated:FireClient(player, { current = current, max = max })
	else
		-- Brainrot ran away
		Remotes.BrainrotRanAway:FireClient(player, {
			brainrotName = brainrotInstance.name,
			rarity = brainrotInstance.rarity,
		})
	end
end

function FoodService.init()
	Remotes.BuyFood.OnServerEvent:Connect(handleBuyFood)
end

return FoodService
