local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Brainrots = require(ReplicatedStorage.Shared.Config.Brainrots)
local Foods = require(ReplicatedStorage.Shared.Config.Foods)
local Mutations = require(ReplicatedStorage.Shared.Config.Mutations)
local Personalities = require(ReplicatedStorage.Shared.Config.Personalities)
local Sizes = require(ReplicatedStorage.Shared.Config.Sizes)
local Utils = require(ReplicatedStorage.Shared.Utils)
local DataService = require(ServerScriptService.Server.Services.DataService)
local BaseService = require(ServerScriptService.Server.Services.BaseService)
local EarningsService = require(ServerScriptService.Server.Services.EarningsService)
local IndexService = require(ServerScriptService.Server.Services.IndexService)
local LuckyHourService = require(ServerScriptService.Server.Services.LuckyHourService)
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
	-- Apply Lucky Hour boost to Rare+ weights before rolling
	local rarityWeights = {}
	local RARE_AND_ABOVE =
		{ Rare = true, Epic = true, Legendary = true, Mythic = true, Goldy = true, Secret = true, Unknown = true }
	for rarity, weight in food.rarityWeights do
		if RARE_AND_ABOVE[rarity] and LuckyHourService.isActive() then
			rarityWeights[rarity] = weight * LuckyHourService.getRarityBoost()
		else
			rarityWeights[rarity] = weight
		end
	end
	local rolledRarity = Utils.weightedRandom(rarityWeights)

	-- Roll brainrot
	local nameList = Brainrots.BRAINROTS_BY_RARITY[rolledRarity]
	local rolledName = nameList[math.random(1, #nameList)]
	local brainrotConfig = Brainrots.BRAINROT_BY_NAME[rolledName]

	-- Roll size tier and get a random size value within that tier's range
	local size, sizeLabel = Sizes.rollSize()

	-- Compute weight based on brainrot's base weight scaled by size
	local weight = Sizes.getWeight(brainrotConfig.name, size)

	-- Roll base mutation
	local baseMutation = Mutations.rollBaseMutation()
	local baseMutationMult = Mutations.getBaseMutationMultiplier(baseMutation)

	-- Roll personality
	local personality = Personalities.rollPersonality()
	local personalityMult = Personalities.getEarningsMultiplier(personality)

	-- Earnings = base * size * mutation * personality
	local earningsPerSec = brainrotConfig.baseEarningsPerSec * size * baseMutationMult * personalityMult

	-- Construct BrainrotInstance
	local brainrotInstance = {
		id = Utils.generateId(),
		name = brainrotConfig.name,
		rarity = brainrotConfig.rarity,
		size = size,
		sizeLabel = sizeLabel,
		weight = weight,
		baseMutation = baseMutation,
		weatherMutation = nil,
		personality = personality,
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

		-- Register discovery in the codex (Phase 7)
		IndexService.registerDiscovery(player, brainrotInstance.name, brainrotInstance.baseMutation)
	else
		-- Brainrot ran away
		Remotes.BrainrotRanAway:FireClient(player, {
			brainrotName = brainrotInstance.name,
			rarity = brainrotInstance.rarity,
		})
	end
end

local NEXT_RARITY = {
	Common = "Rare",
	Rare = "Epic",
	Epic = "Legendary",
	Legendary = "Mythic",
	Mythic = "Goldy",
	Goldy = "Secret",
	Secret = "Unknown",
}

local function handleFuseBrainrots(player: Player, data: { [string]: any })
	-- Validate payload
	if type(data) ~= "table" or type(data.brainrotName) ~= "string" then
		warn("[FoodService] Invalid fusion payload from " .. player.Name)
		return
	end

	local playerData = DataService.getData(player)
	if not playerData then
		warn("[FoodService] No data for " .. player.Name)
		return
	end

	local brainrotName = data.brainrotName

	-- Validate the brainrot exists in config
	local brainrotConfig = Brainrots.BRAINROT_BY_NAME[brainrotName]
	if not brainrotConfig then
		warn("[FoodService] Unknown brainrot for fusion: " .. brainrotName)
		return
	end

	-- Cannot fuse Unknown rarity
	if brainrotConfig.rarity == "Unknown" then
		warn("[FoodService] Cannot fuse Unknown rarity brainrots")
		return
	end

	-- Find the next rarity tier
	local nextRarity = NEXT_RARITY[brainrotConfig.rarity]
	if not nextRarity then
		warn("[FoodService] No next rarity for: " .. brainrotConfig.rarity)
		return
	end

	-- Find 3 matching brainrots in inventory
	local matchingIndices = {}
	for i, brainrot in playerData.ownedBrainrots do
		if brainrot.name == brainrotName then
			table.insert(matchingIndices, i)
			if #matchingIndices >= 3 then
				break
			end
		end
	end

	if #matchingIndices < 3 then
		warn("[FoodService] Not enough brainrots to fuse: " .. brainrotName .. " (" .. #matchingIndices .. "/3)")
		return
	end

	-- Remove the 3 brainrots (iterate in reverse to avoid shifting issues)
	table.sort(matchingIndices, function(a, b)
		return a > b
	end)
	for _, idx in matchingIndices do
		table.remove(playerData.ownedBrainrots, idx)
	end

	-- Roll a random brainrot from the next rarity tier
	local nextRarityList = Brainrots.BRAINROTS_BY_RARITY[nextRarity]
	if not nextRarityList or #nextRarityList == 0 then
		warn("[FoodService] No brainrots in rarity: " .. nextRarity)
		return
	end
	local newBrainrotName = nextRarityList[math.random(1, #nextRarityList)]
	local newBrainrotConfig = Brainrots.BRAINROT_BY_NAME[newBrainrotName]

	-- Roll fresh size, mutation, personality
	local size, sizeLabel = Sizes.rollSize()
	local weight = Sizes.getWeight(newBrainrotConfig.name, size)
	local baseMutation = Mutations.rollBaseMutation()
	local baseMutationMult = Mutations.getBaseMutationMultiplier(baseMutation)
	local personality = Personalities.rollPersonality()
	local personalityMult = Personalities.getEarningsMultiplier(personality)

	local earningsPerSec = newBrainrotConfig.baseEarningsPerSec * size * baseMutationMult * personalityMult

	local newBrainrot = {
		id = Utils.generateId(),
		name = newBrainrotConfig.name,
		rarity = newBrainrotConfig.rarity,
		size = size,
		sizeLabel = sizeLabel,
		weight = weight,
		baseMutation = baseMutation,
		weatherMutation = nil,
		personality = personality,
		earningsPerSec = earningsPerSec,
	}

	-- Insert new brainrot into inventory
	table.insert(playerData.ownedBrainrots, newBrainrot)

	-- Recalculate earnings
	EarningsService.recalculate(player)

	-- Register discovery in codex
	IndexService.registerDiscovery(player, newBrainrot.name, newBrainrot.baseMutation)

	-- Fire result to client
	Remotes.FuseResult:FireClient(player, { brainrotData = newBrainrot })
	Remotes.BrainrotSpawned:FireClient(player, { brainrotData = newBrainrot })

	-- Update capacity (net -2: removed 3, added 1)
	local current, max = BaseService.getCapacity(player)
	Remotes.CapacityUpdated:FireClient(player, { current = current, max = max })

	print(
		"[FoodService] "
			.. player.Name
			.. " fused 3x "
			.. brainrotName
			.. " -> "
			.. newBrainrot.personality
			.. " "
			.. newBrainrot.rarity
			.. " "
			.. newBrainrot.name
	)
end

function FoodService.init()
	Remotes.BuyFood.OnServerEvent:Connect(handleBuyFood)
	Remotes.FuseBrainrots.OnServerEvent:Connect(handleFuseBrainrots)
end

return FoodService
