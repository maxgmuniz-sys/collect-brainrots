export type BrainrotInstance = {
	id: string,
	name: string,
	rarity: string,
	size: number,
	sizeLabel: string,
	weight: number,
	baseMutation: string?,
	weatherMutation: string?,
	personality: string?,
	earningsPerSec: number,
}

export type PlayerData = {
	money: number,
	ownedBrainrots: { BrainrotInstance },
	baseCapacity: number,
	totalMoneyEarned: number,
	totalTimePlayed: number,
	totalRobuxSpent: number,
	index: {
		normal: { string },
		gold: { string },
		diamond: { string },
		rainbow: { string },
	},
	unlockedFences: { string },
	tutorialComplete: boolean,
}

export type FoodTier = {
	name: string,
	cost: number,
	maxRarity: string,
	stayChance: number,
}

export type BrainrotConfig = {
	name: string,
	rarity: string,
	baseEarningsPerSec: number,
	description: string,
	baseWeight: number,
}

return {}
