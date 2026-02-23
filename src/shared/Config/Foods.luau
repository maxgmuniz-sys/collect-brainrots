local RARITY_ORDER = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Goldy", "Secret", "Unknown" }

local FOODS = {
	{
		name = "Common Chow",
		cost = 50,
		maxRarity = "Rare",
		stayChance = 0.60,
		rarityWeights = { Common = 90, Rare = 10 },
	},
	{
		name = "Rare Rations",
		cost = 500,
		maxRarity = "Epic",
		stayChance = 0.55,
		rarityWeights = { Common = 60, Rare = 30, Epic = 10 },
	},
	{
		name = "Epic Eats",
		cost = 7500,
		maxRarity = "Legendary",
		stayChance = 0.45,
		rarityWeights = { Common = 30, Rare = 35, Epic = 25, Legendary = 10 },
	},
	{
		name = "Legendary Feast",
		cost = 100000,
		maxRarity = "Mythic",
		stayChance = 0.35,
		rarityWeights = { Common = 15, Rare = 25, Epic = 30, Legendary = 20, Mythic = 10 },
	},
	{
		name = "Mythic Meal",
		cost = 1500000,
		maxRarity = "Goldy",
		stayChance = 0.28,
		rarityWeights = { Rare = 20, Epic = 25, Legendary = 25, Mythic = 20, Goldy = 10 },
	},
	{
		name = "Goldy Grub",
		cost = 20000000,
		maxRarity = "Secret",
		stayChance = 0.22,
		rarityWeights = { Epic = 15, Legendary = 25, Mythic = 25, Goldy = 25, Secret = 10 },
	},
	{
		name = "Secret Snack",
		cost = 300000000,
		maxRarity = "Unknown",
		stayChance = 0.18,
		rarityWeights = { Legendary = 15, Mythic = 25, Goldy = 25, Secret = 25, Unknown = 10 },
	},
	{
		name = "Unknown Elixir",
		cost = 5000000000,
		maxRarity = "Unknown",
		stayChance = 0.15,
		rarityWeights = { Mythic = 15, Goldy = 20, Secret = 25, Unknown = 40 },
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
}
