local SIZE_TIERS = {
	{ label = "Tiny", minSize = 0.5, maxSize = 0.8, weight = 20 },
	{ label = "Small", minSize = 0.8, maxSize = 1.2, weight = 40 },
	{ label = "Medium", minSize = 1.2, maxSize = 1.8, weight = 29 },
	{ label = "Large", minSize = 1.8, maxSize = 2.4, weight = 10 },
	{ label = "Massive", minSize = 2.4, maxSize = 3.0, weight = 1 },
}

local BASE_WEIGHTS = {
	-- COMMONS
	["Burbaloni Lulilolli"] = 12,
	["Hipocactus"] = 85,
	["Bobrito Bandito"] = 8,
	["Talpa Di Ferro"] = 45,
	["Svinino Bombondino"] = 60,

	-- RARES
	["Frigo Camelo"] = 320,
	["Blueberrinni Octopussini"] = 25,
	["Orangutini Ananasini"] = 150,
	["Tigrrullini Watermellini"] = 180,

	-- EPICS
	["Boneca Ambalabu"] = 30,
	["Chef Crabracadabra"] = 40,
	["Glorbo Fruttodrillo"] = 200,
	["Tralalero Tralala"] = 450,

	-- LEGENDARIES
	["Shpioniro Golubiro"] = 5,
	["Ballerina Cappuccina"] = 15,
	["Bombombini Gusini"] = 35,

	-- MYTHICS
	["Chimpanzini Bananini"] = 90,
	["Brr Brr Patapim"] = 280,
	["Cappuccino Assassino"] = 10,

	-- GOLDYS
	["Lirili Larila"] = 2500,
	["Bombardiro Crocodilo"] = 1800,

	-- SECRETS
	["Tung Tung Tung Sahur"] = 120,
	["Trippi Troppi"] = 7,

	-- UNKNOWNS
	["Centralucci Nuclearucci"] = 50000,
	["La Vaca Saturno Saturnita"] = 999999,
}

local Sizes = {}

function Sizes.rollSize(): (number, string)
	local totalWeight = 0
	for _, tier in SIZE_TIERS do
		totalWeight += tier.weight
	end

	local roll = math.random() * totalWeight
	for _, tier in SIZE_TIERS do
		roll -= tier.weight
		if roll <= 0 then
			local size = tier.minSize + math.random() * (tier.maxSize - tier.minSize)
			size = math.floor(size * 100 + 0.5) / 100
			return size, tier.label
		end
	end

	-- Fallback (should not be reached)
	local lastTier = SIZE_TIERS[#SIZE_TIERS]
	return lastTier.minSize, lastTier.label
end

function Sizes.getWeight(brainrotName: string, size: number): number
	local baseWeight = BASE_WEIGHTS[brainrotName]
	if not baseWeight then
		warn("[Sizes] No base weight for: " .. tostring(brainrotName))
		return 0
	end

	local weight = baseWeight * size
	weight = math.floor(weight * 10 + 0.5) / 10
	return weight
end

function Sizes.getLabel(size: number): string
	if size < 0.5 then
		return "Tiny"
	end
	if size > 3.0 then
		return "Massive"
	end

	for _, tier in SIZE_TIERS do
		if size >= tier.minSize and size <= tier.maxSize then
			return tier.label
		end
	end

	return "Medium"
end

return {
	SIZE_TIERS = SIZE_TIERS,
	BASE_WEIGHTS = BASE_WEIGHTS,
	rollSize = Sizes.rollSize,
	getWeight = Sizes.getWeight,
	getLabel = Sizes.getLabel,
}
