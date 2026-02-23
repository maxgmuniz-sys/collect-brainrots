local BRAINROTS = {
	-- COMMONS (5) - $5/sec base
	{ name = "Burbaloni Lulilolli", rarity = "Common", baseEarningsPerSec = 5, description = "Bubble creature -- a wobbly, translucent blob that floats around leaving a trail of tiny bubbles. Pops if you look at it wrong.", baseWeight = 12 },
	{ name = "Hipocactus", rarity = "Common", baseEarningsPerSec = 5, description = "Hippo-cactus hybrid -- a stubby green hippo covered in cactus spines. Friendly but hugging it is not recommended.", baseWeight = 85 },
	{ name = "Bobrito Bandito", rarity = "Common", baseEarningsPerSec = 5, description = "Burrito bandit -- a sentient burrito wearing a tiny sombrero and bandana. Will steal your salsa without remorse.", baseWeight = 8 },
	{ name = "Talpa Di Ferro", rarity = "Common", baseEarningsPerSec = 5, description = "Iron mole -- a mechanical mole made of rusted iron plates. Digs tunnels at alarming speed and eats metal scraps.", baseWeight = 45 },
	{ name = "Svinino Bombondino", rarity = "Common", baseEarningsPerSec = 5, description = "Pig bomber -- a round piglet strapped with comically large cartoon bombs. Oinks menacingly before every explosion.", baseWeight = 60 },

	-- RARES (4) - $50/sec base
	{ name = "Frigo Camelo", rarity = "Rare", baseEarningsPerSec = 50, description = "Camel fridge -- a two-humped camel whose humps are actually mini-fridges stocked with cold beverages. Always chill.", baseWeight = 320 },
	{ name = "Blueberrinni Octopussini", rarity = "Rare", baseEarningsPerSec = 50, description = "Blueberry octopus -- a deep-blue octopus made entirely of blueberries. Each tentacle ends in a juicy berry cluster.", baseWeight = 25 },
	{ name = "Orangutini Ananasini", rarity = "Rare", baseEarningsPerSec = 50, description = "Orangutan pineapple -- an orangutan with pineapple-textured fur and a leafy green crown on its head. Tropical vibes only.", baseWeight = 150 },
	{ name = "Tigrrullini Watermellini", rarity = "Rare", baseEarningsPerSec = 50, description = "Tiger watermelon -- a fierce tiger with watermelon-striped fur. Seeds fly out when it roars.", baseWeight = 180 },

	-- EPICS (4) - $1,250/sec base
	{ name = "Boneca Ambalabu", rarity = "Epic", baseEarningsPerSec = 1250, description = "Surreal doll animal -- a haunting porcelain doll fused with an unidentifiable animal. Its eyes follow you. Nobody knows what it is.", baseWeight = 30 },
	{ name = "Chef Crabracadabra", rarity = "Epic", baseEarningsPerSec = 1250, description = "Magic crab chef -- a crab in a chef hat that performs cooking magic. Pulls full meals out of its shell like a culinary magician.", baseWeight = 40 },
	{ name = "Glorbo Fruttodrillo", rarity = "Epic", baseEarningsPerSec = 1250, description = "Fruit crocodile -- a crocodile whose entire body is made of mixed tropical fruits. Bites are surprisingly nutritious.", baseWeight = 200 },
	{ name = "Tralalero Tralala", rarity = "Epic", baseEarningsPerSec = 1250, description = "Shark with Nikes -- a great white shark wearing fresh Nike sneakers. Walks on land like it owns the place. Absolutely dripped out.", baseWeight = 450 },

	-- LEGENDARIES (3) - $10,000/sec base
	{ name = "Shpioniro Golubiro", rarity = "Legendary", baseEarningsPerSec = 10000, description = "Spy pigeon -- a pigeon in a tiny trench coat and sunglasses. Carries classified documents in its beak. Trust no one.", baseWeight = 5 },
	{ name = "Ballerina Cappuccina", rarity = "Legendary", baseEarningsPerSec = 10000, description = "Cappuccino ballerina -- a graceful ballerina made entirely of cappuccino foam. Pirouettes leave latte art on the ground.", baseWeight = 15 },
	{ name = "Bombombini Gusini", rarity = "Legendary", baseEarningsPerSec = 10000, description = "Goose with bombs -- an angry goose carrying an absurd arsenal of cartoon bombs. Honks before detonation. Do not provoke.", baseWeight = 35 },

	-- MYTHICS (3) - $100,000/sec base
	{ name = "Chimpanzini Bananini", rarity = "Mythic", baseEarningsPerSec = 100000, description = "Monkey-banana hybrid -- a chimpanzee fused with a giant banana. Peels its own skin to reveal another banana underneath. Infinite layers.", baseWeight = 90 },
	{ name = "Brr Brr Patapim", rarity = "Mythic", baseEarningsPerSec = 100000, description = "Refrigerator DJ -- a walking refrigerator with turntables on top. Drops ice-cold beats and literal ice cubes simultaneously.", baseWeight = 280 },
	{ name = "Cappuccino Assassino", rarity = "Mythic", baseEarningsPerSec = 100000, description = "Killer coffee cup -- a sentient espresso cup with a tiny assassin cloak and twin dagger stirring spoons. Deadly and caffeinated.", baseWeight = 10 },

	-- GOLDYS (2) - $750,000/sec base
	{ name = "Lirili Larila", rarity = "Goldy", baseEarningsPerSec = 750000, description = "Cactus elephant -- a massive elephant covered entirely in cactus skin. Trumpets cause a rain of cactus needles. Majestic and painful.", baseWeight = 2500 },
	{ name = "Bombardiro Crocodilo", rarity = "Goldy", baseEarningsPerSec = 750000, description = "Crocodile bomber plane -- a crocodile with airplane wings and jet engines. Carpet-bombs the area with eggs on every flyby.", baseWeight = 1800 },

	-- SECRETS (2) - $5,000,000/sec base
	{ name = "Tung Tung Tung Sahur", rarity = "Secret", baseEarningsPerSec = 5000000, description = "Log creature with bat -- a sentient wooden log wielding a baseball bat. Wakes everyone up at 3 AM by banging on things. Relentless.", baseWeight = 120 },
	{ name = "Trippi Troppi", rarity = "Secret", baseEarningsPerSec = 5000000, description = "Brain-like creature -- a pulsating, exposed brain on tiny legs. Thinks thoughts so powerful they generate visible shockwaves.", baseWeight = 7 },

	-- UNKNOWNS (2) - $50,000,000/sec base
	{ name = "Centralucci Nuclearucci", rarity = "Unknown", baseEarningsPerSec = 50000000, description = "Nuclear reactor creature -- a walking nuclear power plant with cooling towers for horns. Glows green. Geiger counters hate this thing.", baseWeight = 50000 },
	{ name = "La Vaca Saturno Saturnita", rarity = "Unknown", baseEarningsPerSec = 50000000, description = "Saturn cow -- a cosmic cow with Saturn's rings orbiting its midsection. Moos in frequencies that bend spacetime.", baseWeight = 999999 },
}

-- Build lookup tables
local BRAINROTS_BY_RARITY = {}
local BRAINROT_BY_NAME = {}

for _, brainrot in BRAINROTS do
	BRAINROT_BY_NAME[brainrot.name] = brainrot

	if not BRAINROTS_BY_RARITY[brainrot.rarity] then
		BRAINROTS_BY_RARITY[brainrot.rarity] = {}
	end
	table.insert(BRAINROTS_BY_RARITY[brainrot.rarity], brainrot.name)
end

return {
	BRAINROTS = BRAINROTS,
	BRAINROTS_BY_RARITY = BRAINROTS_BY_RARITY,
	BRAINROT_BY_NAME = BRAINROT_BY_NAME,
}
