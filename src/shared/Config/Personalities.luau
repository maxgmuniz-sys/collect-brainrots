local PERSONALITIES = {
	{
		name = "Lazy",
		earningsMultiplier = 0.9,
		animationSpeed = 0.6,
		spawnWeight = 25,
		color = Color3.fromRGB(100, 149, 237),
		description = "Moves slowly but is easy to manage.",
	},
	{
		name = "Chill",
		earningsMultiplier = 1.0,
		animationSpeed = 1.0,
		spawnWeight = 25,
		color = Color3.fromRGB(144, 238, 144),
		description = "Balanced temperament, nothing special.",
	},
	{
		name = "Grumpy",
		earningsMultiplier = 0.95,
		animationSpeed = 1.3,
		spawnWeight = 25,
		color = Color3.fromRGB(255, 99, 71),
		description = "Slightly lower earnings but moves faster.",
	},
	{
		name = "Hyper",
		earningsMultiplier = 1.2,
		animationSpeed = 1.8,
		spawnWeight = 25,
		color = Color3.fromRGB(255, 215, 0),
		description = "High earnings and fast movement!",
	},
}

-- Build lookup table
local PERSONALITY_BY_NAME = {}
for _, personality in PERSONALITIES do
	PERSONALITY_BY_NAME[personality.name] = personality
end

-- Build total weight once
local TOTAL_WEIGHT = 0
for _, personality in PERSONALITIES do
	TOTAL_WEIGHT += personality.spawnWeight
end

local Personalities = {}

function Personalities.rollPersonality(): string
	local roll = math.random() * TOTAL_WEIGHT
	for _, personality in PERSONALITIES do
		roll -= personality.spawnWeight
		if roll <= 0 then
			return personality.name
		end
	end
	return PERSONALITIES[#PERSONALITIES].name
end

function Personalities.getEarningsMultiplier(name: string?): number
	if name == nil then
		return 1.0
	end
	local entry = PERSONALITY_BY_NAME[name]
	if entry then
		return entry.earningsMultiplier
	end
	return 1.0
end

function Personalities.getAnimationSpeed(name: string?): number
	if name == nil then
		return 1.0
	end
	local entry = PERSONALITY_BY_NAME[name]
	if entry then
		return entry.animationSpeed
	end
	return 1.0
end

function Personalities.getColor(name: string?): Color3?
	if name == nil then
		return nil
	end
	local entry = PERSONALITY_BY_NAME[name]
	if entry then
		return entry.color
	end
	return nil
end

return {
	PERSONALITIES = PERSONALITIES,
	PERSONALITY_BY_NAME = PERSONALITY_BY_NAME,
	rollPersonality = Personalities.rollPersonality,
	getEarningsMultiplier = Personalities.getEarningsMultiplier,
	getAnimationSpeed = Personalities.getAnimationSpeed,
	getColor = Personalities.getColor,
}
