local BASE_MUTATIONS = {
	Gold = {
		chance = 0.08,
		multiplier = 1.5,
		color = Color3.fromRGB(255, 215, 0),
		particleEffect = "GoldSparkles",
	},
	Diamond = {
		chance = 0.05,
		multiplier = 2.5,
		color = Color3.fromRGB(185, 242, 255),
		particleEffect = "DiamondSparkles",
	},
	Rainbow = {
		chance = 0.02,
		multiplier = 5.0,
		color = nil,
		particleEffect = "RainbowParticles",
	},
}

local WEATHER_MUTATIONS = {
	Soaked = { weather = "Rain", multiplier = 1.5 },
	Frozen = { weather = "Snow", multiplier = 2.0 },
	Shocked = { weather = "Storm", multiplier = 2.5 },
	Starstrucked = { weather = "Meteor Shower", multiplier = 5.0 },
	Burnt = { weather = "Solar Flare", multiplier = 10.0 },
	Radiated = { weather = "Nuclear", multiplier = 35.0 },
	Gravitated = { weather = "Black Hole", multiplier = 100.0 },
}

local RAINBOW_COLORS = {
	Color3.fromRGB(255, 0, 0),
	Color3.fromRGB(255, 127, 0),
	Color3.fromRGB(255, 255, 0),
	Color3.fromRGB(0, 255, 0),
	Color3.fromRGB(0, 0, 255),
	Color3.fromRGB(75, 0, 130),
	Color3.fromRGB(148, 0, 211),
}

local Mutations = {}

function Mutations.rollBaseMutation(): string?
	local roll = math.random()
	if roll < 0.02 then
		return "Rainbow"
	elseif roll < 0.07 then
		return "Diamond"
	elseif roll < 0.15 then
		return "Gold"
	end
	return nil
end

function Mutations.getBaseMutationMultiplier(mutation: string?): number
	if mutation == nil then
		return 1.0
	end
	local entry = BASE_MUTATIONS[mutation]
	if entry then
		return entry.multiplier
	end
	warn("[Mutations] Unknown base mutation: " .. tostring(mutation))
	return 1.0
end

function Mutations.getBaseMutationColor(mutation: string?): Color3?
	if mutation == nil then
		return nil
	end
	if mutation == "Rainbow" then
		return nil
	end
	local entry = BASE_MUTATIONS[mutation]
	if entry then
		return entry.color
	end
	return nil
end

function Mutations.getWeatherMutationMultiplier(mutation: string?): number
	if mutation == nil then
		return 1.0
	end
	local entry = WEATHER_MUTATIONS[mutation]
	if entry then
		return entry.multiplier
	end
	warn("[Mutations] Unknown weather mutation: " .. tostring(mutation))
	return 1.0
end

function Mutations.isRainbow(mutation: string?): boolean
	return mutation == "Rainbow"
end

return {
	BASE_MUTATIONS = BASE_MUTATIONS,
	WEATHER_MUTATIONS = WEATHER_MUTATIONS,
	RAINBOW_COLORS = RAINBOW_COLORS,

	rollBaseMutation = Mutations.rollBaseMutation,
	getBaseMutationMultiplier = Mutations.getBaseMutationMultiplier,
	getBaseMutationColor = Mutations.getBaseMutationColor,
	getWeatherMutationMultiplier = Mutations.getWeatherMutationMultiplier,
	isRainbow = Mutations.isRainbow,
}
