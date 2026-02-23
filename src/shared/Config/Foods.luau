local RARITY_ORDER = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Goldy", "Secret", "Unknown" }

local VIP_EVENT_ACTIVE = false

local FOODS = {
	{
		name = "Common Chow",
		cost = 50,
		maxRarity = "Rare",
		stayChance = 0.60,
		isVIP = false,
		guaranteedMinRarity = nil,
		rarityWeights = { Common = 90, Rare = 10 },
	},
	{
		name = "Rare Rations",
		cost = 500,
		maxRarity = "Epic",
		stayChance = 0.55,
		isVIP = false,
		guaranteedMinRarity = nil,
		rarityWeights = { Common = 60, Rare = 30, Epic = 10 },
	},
	{
		name = "Epic Eats",
		cost = 7500,
		maxRarity = "Legendary",
		stayChance = 0.45,
		isVIP = false,
		guaranteedMinRarity = nil,
		rarityWeights = { Common = 30, Rare = 35, Epic = 25, Legendary = 10 },
	},
	{
		name = "Legendary Feast",
		cost = 100000,
		maxRarity = "Mythic",
		stayChance = 0.35,
		isVIP = false,
		guaranteedMinRarity = nil,
		rarityWeights = { Common = 15, Rare = 25, Epic = 30, Legendary = 20, Mythic = 10 },
	},
	{
		name = "Mythic Meal",
		cost = 1500000,
		maxRarity = "Goldy",
		stayChance = 0.28,
		isVIP = false,
		guaranteedMinRarity = nil,
		rarityWeights = { Rare = 20, Epic = 25, Legendary = 25, Mythic = 20, Goldy = 10 },
	},
	{
		name = "Goldy Grub",
		cost = 20000000,
		maxRarity = "Secret",
		stayChance = 0.22,
		isVIP = false,
		guaranteedMinRarity = nil,
		rarityWeights = { Epic = 15, Legendary = 25, Mythic = 25, Goldy = 25, Secret = 10 },
	},
	{
		name = "Secret Snack",
		cost = 300000000,
		maxRarity = "Unknown",
		stayChance = 0.18,
		isVIP = false,
		guaranteedMinRarity = nil,
		rarityWeights = { Legendary = 15, Mythic = 25, Goldy = 25, Secret = 25, Unknown = 10 },
	},
	{
		name = "Unknown Elixir",
		cost = 5000000000,
		maxRarity = "Unknown",
		stayChance = 0.15,
		isVIP = false,
		guaranteedMinRarity = nil,
		rarityWeights = { Mythic = 15, Goldy = 20, Secret = 25, Unknown = 40 },
	},

	-- VIP Foods (only shown when VIP_EVENT_ACTIVE = true)
	{
		name = "VIP Common Feast",
		cost = 100000,
		maxRarity = "Mythic",
		stayChance = 0.50,
		isVIP = true,
		guaranteedMinRarity = "Rare",
		rarityWeights = { Rare = 40, Epic = 30, Legendary = 20, Mythic = 10 },
	},
	{
		name = "VIP Legendary Banquet",
		cost = 5000000,
		maxRarity = "Secret",
		stayChance = 0.35,
		isVIP = true,
		guaranteedMinRarity = "Legendary",
		rarityWeights = { Legendary = 40, Mythic = 30, Goldy = 20, Secret = 10 },
	},
	{
		name = "VIP Ultimate Platter",
		cost = 500000000,
		maxRarity = "Unknown",
		stayChance = 0.20,
		isVIP = true,
		guaranteedMinRarity = "Goldy",
		rarityWeights = { Goldy = 40, Secret = 35, Unknown = 25 },
	},
}

-- Build lookup table
local FOOD_BY_NAME = {}
for _, food in FOODS do
	FOOD_BY_NAME[food.name] = food
end

return {
	FOODS = FOODS,
	FOOD_BY_NAME = FOOD_BY_NAME,
	RARITY_ORDER = RARITY_ORDER,
	VIP_EVENT_ACTIVE = VIP_EVENT_ACTIVE,
}
