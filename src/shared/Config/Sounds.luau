local Sounds = {}

-- Each entry: { assetId: string, volume: number, playbackSpeed: number? }
-- playbackSpeed defaults to 1.0 if omitted

Sounds.SOUND_EFFECTS = {
	-- Food Store events
	BuyFood = {
		assetId = "rbxassetid://0",
		volume = 0.5,
	},
	BrainrotSpawned = {
		assetId = "rbxassetid://0",
		volume = 0.6,
	},
	BrainrotRanAway = {
		assetId = "rbxassetid://0",
		volume = 0.5,
	},

	-- Mutation events
	MutationGold = {
		assetId = "rbxassetid://0",
		volume = 0.6,
	},
	MutationDiamond = {
		assetId = "rbxassetid://0",
		volume = 0.6,
	},
	MutationRainbow = {
		assetId = "rbxassetid://0",
		volume = 0.7,
	},
	WeatherMutationApplied = {
		assetId = "rbxassetid://0",
		volume = 0.5,
	},

	-- Base events
	CapacityUpgraded = {
		assetId = "rbxassetid://0",
		volume = 0.6,
	},
	SellBrainrot = {
		assetId = "rbxassetid://0",
		volume = 0.5,
	},

	-- Codex events
	CodexDiscovery = {
		assetId = "rbxassetid://0",
		volume = 0.6,
	},

	-- Lucky Hour
	LuckyHourStart = {
		assetId = "rbxassetid://0",
		volume = 0.7,
	},
	LuckyHourEnd = {
		assetId = "rbxassetid://0",
		volume = 0.5,
	},

	-- Fusion
	FusionComplete = {
		assetId = "rbxassetid://0",
		volume = 0.7,
	},
}

-- Background music tracks, organized by severity / mood
-- Multiple tracks per mood for variety; one is selected randomly on transition
Sounds.MUSIC_TRACKS = {
	Joyful = {
		{ assetId = "rbxassetid://0", volume = 0.3 },
		{ assetId = "rbxassetid://0", volume = 0.3 },
	},
	Gloomy = {
		{ assetId = "rbxassetid://0", volume = 0.3 },
		{ assetId = "rbxassetid://0", volume = 0.3 },
	},
	Suspenseful = {
		{ assetId = "rbxassetid://0", volume = 0.35 },
		{ assetId = "rbxassetid://0", volume = 0.35 },
	},
	Intense = {
		{ assetId = "rbxassetid://0", volume = 0.4 },
		{ assetId = "rbxassetid://0", volume = 0.4 },
	},
}

-- Crossfade duration in seconds for music transitions
Sounds.MUSIC_CROSSFADE_DURATION = 1.5

return Sounds
