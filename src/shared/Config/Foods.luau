local RARITY_ORDER = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Goldy", "Secret", "Unknown" }

local FOODS = {
	{ name = "Common Chow", cost = 50, maxRarity = "Rare", stayChance = 0.60 },
	{ name = "Rare Rations", cost = 500, maxRarity = "Epic", stayChance = 0.55 },
	{ name = "Epic Eats", cost = 5000, maxRarity = "Legendary", stayChance = 0.45 },
	{ name = "Legendary Feast", cost = 50000, maxRarity = "Legendary", stayChance = 0.35 },
	{ name = "Mythic Meal", cost = 500000, maxRarity = "Goldy", stayChance = 0.28 },
	{ name = "Goldy Grub", cost = 5000000, maxRarity = "Secret", stayChance = 0.22 },
	{ name = "Secret Snack", cost = 50000000, maxRarity = "Unknown", stayChance = 0.18 },
	{ name = "Unknown Elixir", cost = 500000000, maxRarity = "Unknown", stayChance = 0.15 },
}

local RARITY_WEIGHTS = {
	["Common Chow"] = { Common = 90, Rare = 10 },
	["Rare Rations"] = { Common = 50, Rare = 40, Epic = 10 },
	["Epic Eats"] = { Common = 30, Rare = 35, Epic = 25, Legendary = 10 },
	["Legendary Feast"] = { Common = 20, Rare = 25, Epic = 25, Legendary = 30 },
	["Mythic Meal"] = { Common = 10, Rare = 15, Epic = 20, Legendary = 25, Mythic = 20, Goldy = 10 },
	["Goldy Grub"] = { Common = 5, Rare = 10, Epic = 15, Legendary = 20, Mythic = 20, Goldy = 20, Secret = 10 },
	["Secret Snack"] = { Common = 3, Rare = 5, Epic = 10, Legendary = 15, Mythic = 17, Goldy = 20, Secret = 20, Unknown = 10 },
	["Unknown Elixir"] = { Common = 1, Rare = 2, Epic = 5, Legendary = 7, Mythic = 10, Goldy = 15, Secret = 25, Unknown = 35 },
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
	RARITY_WEIGHTS = RARITY_WEIGHTS,
}
