local WEATHER_EVENTS = {
	Clear = {
		spawnWeight = 40,
		minDuration = 0,
		maxDuration = 0,
		mutation = nil,
		mutationChance = 0,
		severity = 0,
		description = "Clear skies. Nothing happens.",
	},
	Rain = {
		spawnWeight = 25,
		minDuration = 60,
		maxDuration = 120,
		mutation = "Soaked",
		mutationChance = 0.15,
		severity = 1,
		description = "Rain falls from the sky. Brainrots may get Soaked.",
	},
	Snow = {
		spawnWeight = 15,
		minDuration = 60,
		maxDuration = 120,
		mutation = "Frozen",
		mutationChance = 0.12,
		severity = 1,
		description = "Snowflakes blanket the world. Brainrots may get Frozen.",
	},
	Storm = {
		spawnWeight = 10,
		minDuration = 45,
		maxDuration = 90,
		mutation = "Shocked",
		mutationChance = 0.10,
		severity = 2,
		description = "Lightning strikes! Brainrots may get Shocked.",
	},
	["Meteor Shower"] = {
		spawnWeight = 5,
		minDuration = 30,
		maxDuration = 60,
		mutation = "Starstrucked",
		mutationChance = 0.08,
		severity = 2,
		description = "Meteors streak across the sky. Brainrots may get Starstrucked.",
	},
	["Solar Flare"] = {
		spawnWeight = 3,
		minDuration = 30,
		maxDuration = 60,
		mutation = "Burnt",
		mutationChance = 0.05,
		severity = 3,
		description = "The sun erupts! Brainrots may get Burnt.",
	},
	Nuclear = {
		spawnWeight = 1.5,
		minDuration = 20,
		maxDuration = 45,
		mutation = "Radiated",
		mutationChance = 0.03,
		severity = 3,
		description = "Nuclear fallout! Brainrots may get Radiated.",
	},
	["Black Hole"] = {
		spawnWeight = 0.5,
		minDuration = 15,
		maxDuration = 30,
		mutation = "Gravitated",
		mutationChance = 0.01,
		severity = 3,
		description = "A black hole appears! Brainrots may get Gravitated.",
	},
}

local WEATHER_CYCLE_MIN = 120
local WEATHER_CYCLE_MAX = 300

local SEVERITY_LABELS = {
	[0] = "Joyful",
	[1] = "Gloomy",
	[2] = "Suspenseful",
	[3] = "Intense",
}

local WEATHER_ORDER = {
	"Clear",
	"Rain",
	"Snow",
	"Storm",
	"Meteor Shower",
	"Solar Flare",
	"Nuclear",
	"Black Hole",
}

local Weather = {}

function Weather.getEvent(weatherType: string)
	local event = WEATHER_EVENTS[weatherType]
	if not event then
		warn("[Weather] Unknown weather type: " .. tostring(weatherType))
		return nil
	end
	return event
end

function Weather.getSeverity(weatherType: string): number
	local event = WEATHER_EVENTS[weatherType]
	if event then
		return event.severity
	end
	return 0
end

function Weather.getSeverityLabel(severity: number): string
	return SEVERITY_LABELS[severity] or "Joyful"
end

return {
	WEATHER_EVENTS = WEATHER_EVENTS,
	WEATHER_CYCLE_MIN = WEATHER_CYCLE_MIN,
	WEATHER_CYCLE_MAX = WEATHER_CYCLE_MAX,
	SEVERITY_LABELS = SEVERITY_LABELS,
	WEATHER_ORDER = WEATHER_ORDER,

	getEvent = Weather.getEvent,
	getSeverity = Weather.getSeverity,
	getSeverityLabel = Weather.getSeverityLabel,
}
