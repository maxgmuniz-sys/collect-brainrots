# Phase 1: MVP Core Loop

> **Status:** NOT STARTED
> **Depends on:** Phase 0 (project scaffolding complete)
> **Estimated scope:** 14 files (12 new, 2 modified)

---

## 1. Objective

Implement the core game loop: player buys common food, a common brainrot is attracted, there is a chance it stays at the player's base, brainrots that stay earn money per second, and the player can use accumulated money to buy more food. This proves the fundamental game mechanic works end-to-end.

**Phase 1 scope is intentionally minimal:**

- Only Common food tier is purchasable (the other 7 tiers are defined in config but gated).
- Only the 5 Common brainrots can spawn (all 25 are defined in config but only commons are rollable).
- No size system yet (all brainrots spawn at size 1.0, label "Medium", base weight).
- No base mutations (all brainrots spawn with `baseMutation = nil`).
- No weather mutations, no weather events.
- No personality system.
- No sell system, no fusion, no gifting, no leaderboards, no index/codex.
- Base capacity starts at 1 and cannot be upgraded (upgrade button exists but is non-functional in Phase 1).
- Starting money: $100.

The goal is the simplest possible playable version that proves the loop works.

---

## 2. Prerequisites

Phase 0 must be fully complete before starting Phase 1. Specifically:

- `aftman.toml` exists and pins Rojo 7.7.0-rc.1 and Wally.
- `wally.toml` exists and declares the ProfileStore dependency.
- `wally install` has been run and `Packages/` directory is populated with ProfileStore.
- `default.project.json` exists with the correct Rojo mappings (see ARCHITECTURE.md Section 3).
- The directory structure `src/shared/Config/`, `src/server/Services/`, `src/server/Remotes/`, `src/client/Controllers/` exists.
- `rojo build -o "collect-brainrots.rbxlx"` succeeds on the empty scaffolding.

---

## 3. Files to Create/Modify

Every file is listed with its full path relative to the project root.

### New Files to Create (12 files)

| # | File Path | Purpose |
|---|---|---|
| 1 | `src/shared/Config/Brainrots.luau` | Master table of all 25 brainrots with stats, plus a BRAINROTS_BY_RARITY lookup |
| 2 | `src/shared/Config/Foods.luau` | Table of all 8 food tiers with costs, max rarity, and stay chances |
| 3 | `src/shared/Types.luau` | Central type definitions for BrainrotInstance, PlayerData, FoodTier |
| 4 | `src/shared/Utils.luau` | Utility functions: weighted random, ID generation, number formatting, deep copy |
| 5 | `src/server/Remotes/init.luau` | Creates all Phase 1 RemoteEvents under ReplicatedStorage/Remotes |
| 6 | `src/server/Services/DataService.luau` | ProfileStore player data management |
| 7 | `src/server/Services/BaseService.luau` | Plot assignment and capacity tracking |
| 8 | `src/server/Services/FoodService.luau` | Core buy-food-to-get-brainrot logic |
| 9 | `src/server/Services/EarningsService.luau` | 1-second passive income loop |
| 10 | `src/client/Controllers/MoneyUI.luau` | HUD money display and earnings/sec display |
| 11 | `src/client/Controllers/FoodStoreUI.luau` | Buy food button and spawn/run-away feedback |
| 12 | `src/client/Controllers/BaseUI.luau` | Plot visuals, brainrot placement, capacity display |

### Files to Modify (2 files)

| # | File Path | Change |
|---|---|---|
| 1 | `src/server/init.server.luau` | Require and boot all Phase 1 services; connect PlayerAdded/PlayerRemoving |
| 2 | `src/client/init.client.luau` | Require and init all Phase 1 UI controllers |

---

## 4. Detailed Spec Per File

---

### 4.1 `src/shared/Config/Brainrots.luau`

**Purpose:** Defines the master data table for all 25 brainrots and provides a rarity-grouped lookup table. This is a pure data module with zero dependencies.

**Returns:** A table with two keys: `BRAINROTS` (the ordered list) and `BRAINROTS_BY_RARITY` (the rarity-grouped lookup).

**Data shape per brainrot entry:**

```luau
{
    name: string,            -- Display name, e.g. "Burbaloni Lulilolli"
    rarity: string,          -- "Common" | "Rare" | "Epic" | "Legendary" | "Mythic" | "Goldy" | "Secret" | "Unknown"
    baseEarningsPerSec: number,  -- Base $/sec before any multipliers
    description: string,     -- Flavor text description
    baseWeight: number,      -- Weight in lbs at Medium size
}
```

**Complete brainrot data (all 25):**

```luau
-- COMMONS (5) - $5/sec base
{ name = "Burbaloni Lulilolli",       rarity = "Common",    baseEarningsPerSec = 5,         description = "Bubble creature -- a wobbly, translucent blob that floats around leaving a trail of tiny bubbles. Pops if you look at it wrong.", baseWeight = 12 },
{ name = "Hipocactus",                rarity = "Common",    baseEarningsPerSec = 5,         description = "Hippo-cactus hybrid -- a stubby green hippo covered in cactus spines. Friendly but hugging it is not recommended.", baseWeight = 85 },
{ name = "Bobrito Bandito",           rarity = "Common",    baseEarningsPerSec = 5,         description = "Burrito bandit -- a sentient burrito wearing a tiny sombrero and bandana. Will steal your salsa without remorse.", baseWeight = 8 },
{ name = "Talpa Di Ferro",            rarity = "Common",    baseEarningsPerSec = 5,         description = "Iron mole -- a mechanical mole made of rusted iron plates. Digs tunnels at alarming speed and eats metal scraps.", baseWeight = 45 },
{ name = "Svinino Bombondino",        rarity = "Common",    baseEarningsPerSec = 5,         description = "Pig bomber -- a round piglet strapped with comically large cartoon bombs. Oinks menacingly before every explosion.", baseWeight = 60 },

-- RARES (4) - $50/sec base
{ name = "Frigo Camelo",              rarity = "Rare",      baseEarningsPerSec = 50,        description = "Camel fridge -- a two-humped camel whose humps are actually mini-fridges stocked with cold beverages. Always chill.", baseWeight = 320 },
{ name = "Blueberrinni Octopussini",  rarity = "Rare",      baseEarningsPerSec = 50,        description = "Blueberry octopus -- a deep-blue octopus made entirely of blueberries. Each tentacle ends in a juicy berry cluster.", baseWeight = 25 },
{ name = "Orangutini Ananasini",      rarity = "Rare",      baseEarningsPerSec = 50,        description = "Orangutan pineapple -- an orangutan with pineapple-textured fur and a leafy green crown on its head. Tropical vibes only.", baseWeight = 150 },
{ name = "Tigrrullini Watermellini",  rarity = "Rare",      baseEarningsPerSec = 50,        description = "Tiger watermelon -- a fierce tiger with watermelon-striped fur. Seeds fly out when it roars.", baseWeight = 180 },

-- EPICS (4) - $1,250/sec base
{ name = "Boneca Ambalabu",           rarity = "Epic",      baseEarningsPerSec = 1250,      description = "Surreal doll animal -- a haunting porcelain doll fused with an unidentifiable animal. Its eyes follow you. Nobody knows what it is.", baseWeight = 30 },
{ name = "Chef Crabracadabra",        rarity = "Epic",      baseEarningsPerSec = 1250,      description = "Magic crab chef -- a crab in a chef hat that performs cooking magic. Pulls full meals out of its shell like a culinary magician.", baseWeight = 40 },
{ name = "Glorbo Fruttodrillo",       rarity = "Epic",      baseEarningsPerSec = 1250,      description = "Fruit crocodile -- a crocodile whose entire body is made of mixed tropical fruits. Bites are surprisingly nutritious.", baseWeight = 200 },
{ name = "Tralalero Tralala",         rarity = "Epic",      baseEarningsPerSec = 1250,      description = "Shark with Nikes -- a great white shark wearing fresh Nike sneakers. Walks on land like it owns the place. Absolutely dripped out.", baseWeight = 450 },

-- LEGENDARIES (3) - $10,000/sec base
{ name = "Shpioniro Golubiro",        rarity = "Legendary",  baseEarningsPerSec = 10000,    description = "Spy pigeon -- a pigeon in a tiny trench coat and sunglasses. Carries classified documents in its beak. Trust no one.", baseWeight = 5 },
{ name = "Ballerina Cappuccina",      rarity = "Legendary",  baseEarningsPerSec = 10000,    description = "Cappuccino ballerina -- a graceful ballerina made entirely of cappuccino foam. Pirouettes leave latte art on the ground.", baseWeight = 15 },
{ name = "Bombombini Gusini",         rarity = "Legendary",  baseEarningsPerSec = 10000,    description = "Goose with bombs -- an angry goose carrying an absurd arsenal of cartoon bombs. Honks before detonation. Do not provoke.", baseWeight = 35 },

-- MYTHICS (3) - $100,000/sec base
{ name = "Chimpanzini Bananini",      rarity = "Mythic",    baseEarningsPerSec = 100000,    description = "Monkey-banana hybrid -- a chimpanzee fused with a giant banana. Peels its own skin to reveal another banana underneath. Infinite layers.", baseWeight = 90 },
{ name = "Brr Brr Patapim",           rarity = "Mythic",    baseEarningsPerSec = 100000,    description = "Refrigerator DJ -- a walking refrigerator with turntables on top. Drops ice-cold beats and literal ice cubes simultaneously.", baseWeight = 280 },
{ name = "Cappuccino Assassino",      rarity = "Mythic",    baseEarningsPerSec = 100000,    description = "Killer coffee cup -- a sentient espresso cup with a tiny assassin cloak and twin dagger stirring spoons. Deadly and caffeinated.", baseWeight = 10 },

-- GOLDYS (2) - $750,000/sec base
{ name = "Lirili Larila",             rarity = "Goldy",     baseEarningsPerSec = 750000,    description = "Cactus elephant -- a massive elephant covered entirely in cactus skin. Trumpets cause a rain of cactus needles. Majestic and painful.", baseWeight = 2500 },
{ name = "Bombardiro Crocodilo",      rarity = "Goldy",     baseEarningsPerSec = 750000,    description = "Crocodile bomber plane -- a crocodile with airplane wings and jet engines. Carpet-bombs the area with eggs on every flyby.", baseWeight = 1800 },

-- SECRETS (2) - $5,000,000/sec base
{ name = "Tung Tung Tung Sahur",      rarity = "Secret",    baseEarningsPerSec = 5000000,   description = "Log creature with bat -- a sentient wooden log wielding a baseball bat. Wakes everyone up at 3 AM by banging on things. Relentless.", baseWeight = 120 },
{ name = "Trippi Troppi",             rarity = "Secret",    baseEarningsPerSec = 5000000,   description = "Brain-like creature -- a pulsating, exposed brain on tiny legs. Thinks thoughts so powerful they generate visible shockwaves.", baseWeight = 7 },

-- UNKNOWNS (2) - $50,000,000/sec base
{ name = "Centralucci Nuclearucci",   rarity = "Unknown",   baseEarningsPerSec = 50000000,  description = "Nuclear reactor creature -- a walking nuclear power plant with cooling towers for horns. Glows green. Geiger counters hate this thing.", baseWeight = 50000 },
{ name = "La Vaca Saturno Saturnita", rarity = "Unknown",   baseEarningsPerSec = 50000000,  description = "Saturn cow -- a cosmic cow with Saturn's rings orbiting its midsection. Moos in frequencies that bend spacetime.", baseWeight = 999999 },
```

**BRAINROTS_BY_RARITY table:**

A dictionary keyed by rarity string, where each value is an array of brainrot names belonging to that rarity. Built programmatically by iterating the BRAINROTS list.

```luau
BRAINROTS_BY_RARITY = {
    Common    = { "Burbaloni Lulilolli", "Hipocactus", "Bobrito Bandito", "Talpa Di Ferro", "Svinino Bombondino" },
    Rare      = { "Frigo Camelo", "Blueberrinni Octopussini", "Orangutini Ananasini", "Tigrrullini Watermellini" },
    Epic      = { "Boneca Ambalabu", "Chef Crabracadabra", "Glorbo Fruttodrillo", "Tralalero Tralala" },
    Legendary = { "Shpioniro Golubiro", "Ballerina Cappuccina", "Bombombini Gusini" },
    Mythic    = { "Chimpanzini Bananini", "Brr Brr Patapim", "Cappuccino Assassino" },
    Goldy     = { "Lirili Larila", "Bombardiro Crocodilo" },
    Secret    = { "Tung Tung Tung Sahur", "Trippi Troppi" },
    Unknown   = { "Centralucci Nuclearucci", "La Vaca Saturno Saturnita" },
}
```

Also provide a `BRAINROT_BY_NAME` dictionary keyed by brainrot name, where each value is the full brainrot data entry. Built programmatically from BRAINROTS.

**Module return structure:**

```luau
return {
    BRAINROTS = BRAINROTS,                -- {BrainrotConfig} ordered array
    BRAINROTS_BY_RARITY = BRAINROTS_BY_RARITY,  -- {[string]: {string}}
    BRAINROT_BY_NAME = BRAINROT_BY_NAME,         -- {[string]: BrainrotConfig}
}
```

---

### 4.2 `src/shared/Config/Foods.luau`

**Purpose:** Defines the 8 food tiers with their costs, maximum rarity attracted, and stay chances. Pure data module with zero dependencies.

**Returns:** A table with key `FOODS` containing the ordered food tier array, and `FOOD_BY_NAME` keyed by food tier name.

**Data shape per food entry:**

```luau
{
    name: string,        -- Display name, e.g. "Common Chow"
    cost: number,        -- Price in in-game money
    maxRarity: string,   -- Highest rarity this food can attract (e.g. "Rare")
    stayChance: number,  -- Probability (0.0 to 1.0) that an attracted brainrot stays
}
```

**Complete food data (all 8 tiers):**

```luau
-- Costs are TBD placeholders -- will be balanced in Phase 2
{ name = "Common Chow",     cost = 50,          maxRarity = "Rare",      stayChance = 0.60 },
{ name = "Rare Rations",    cost = 500,         maxRarity = "Epic",      stayChance = 0.55 },
{ name = "Epic Eats",       cost = 5000,        maxRarity = "Legendary", stayChance = 0.45 },
{ name = "Legendary Feast", cost = 50000,       maxRarity = "Legendary", stayChance = 0.35 },
{ name = "Mythic Meal",     cost = 500000,      maxRarity = "Goldy",     stayChance = 0.28 },
{ name = "Goldy Grub",      cost = 5000000,     maxRarity = "Secret",    stayChance = 0.22 },
{ name = "Secret Snack",    cost = 50000000,    maxRarity = "Unknown",   stayChance = 0.18 },
{ name = "Unknown Elixir",  cost = 500000000,   maxRarity = "Unknown",   stayChance = 0.15 },
```

> **Phase 1 note:** Only "Common Chow" is purchasable in Phase 1. FoodService must reject purchases of any other tier. The other tiers are defined here so future phases can simply remove the gate.

**RARITY_ORDER constant:**

Also define a `RARITY_ORDER` array that establishes the canonical ordering of rarity tiers. This is used by FoodService to determine which rarities fall within a food's attraction pool (all rarities from Common up to and including the food's `maxRarity`).

```luau
local RARITY_ORDER = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Goldy", "Secret", "Unknown" }
```

**RARITY_WEIGHTS constant:**

Define rarity roll weights for each food tier. When a food is used, a rarity is rolled from all rarities in its attraction pool using these weights. Higher rarities within the pool are progressively less likely.

For Phase 1 (Common Chow only), the weights are:

```luau
-- Common Chow attraction pool: Common and Rare
-- Weights (used with Utils.weightedRandom):
RARITY_WEIGHTS = {
    ["Common Chow"] = { Common = 90, Rare = 10 },
    ["Rare Rations"] = { Common = 50, Rare = 40, Epic = 10 },
    ["Epic Eats"] = { Common = 30, Rare = 35, Epic = 25, Legendary = 10 },
    ["Legendary Feast"] = { Common = 20, Rare = 25, Epic = 25, Legendary = 30 },
    ["Mythic Meal"] = { Common = 10, Rare = 15, Epic = 20, Legendary = 25, Mythic = 20, Goldy = 10 },
    ["Goldy Grub"] = { Common = 5, Rare = 10, Epic = 15, Legendary = 20, Mythic = 20, Goldy = 20, Secret = 10 },
    ["Secret Snack"] = { Common = 3, Rare = 5, Epic = 10, Legendary = 15, Mythic = 17, Goldy = 20, Secret = 20, Unknown = 10 },
    ["Unknown Elixir"] = { Common = 1, Rare = 2, Epic = 5, Legendary = 7, Mythic = 10, Goldy = 15, Secret = 25, Unknown = 35 },
}
```

> **These weights are TBD placeholders** -- they will be balanced in Phase 2. The exact numbers do not matter for Phase 1 since only Common Chow is active.

**Module return structure:**

```luau
return {
    FOODS = FOODS,                     -- {FoodConfig} ordered array
    FOOD_BY_NAME = FOOD_BY_NAME,       -- {[string]: FoodConfig}
    RARITY_ORDER = RARITY_ORDER,       -- {string} ordered array
    RARITY_WEIGHTS = RARITY_WEIGHTS,   -- {[string]: {[string]: number}}
}
```

---

### 4.3 `src/shared/Types.luau`

**Purpose:** Central type definitions file. Exports Luau type aliases used across the entire codebase. Pure type definitions, zero dependencies, zero runtime logic.

**Exported types:**

```luau
export type BrainrotInstance = {
    id: string,                  -- Unique ID via HttpService:GenerateGUID()
    name: string,                -- Display name, e.g. "Burbaloni Lulilolli"
    rarity: string,              -- "Common" | "Rare" | "Epic" | "Legendary" | "Mythic" | "Goldy" | "Secret" | "Unknown"
    size: number,                -- Scale factor (Phase 1: always 1.0)
    sizeLabel: string,           -- "Tiny"|"Small"|"Medium"|"Large"|"Massive" (Phase 1: always "Medium")
    weight: number,              -- Weight in lbs (Phase 1: always baseWeight)
    baseMutation: string?,       -- "Gold"|"Diamond"|"Rainbow"|nil (Phase 1: always nil)
    weatherMutation: string?,    -- Phase 6+ only (Phase 1: always nil)
    personality: string?,        -- Phase 8+ only (Phase 1: always nil)
    earningsPerSec: number,      -- Computed earnings (Phase 1: always baseEarningsPerSec since all multipliers are 1.0)
}

export type PlayerData = {
    money: number,                         -- Current balance (starts at 100)
    ownedBrainrots: {BrainrotInstance},    -- Array of brainrots on the base
    baseCapacity: number,                  -- Max brainrots allowed (starts at 1)
    totalMoneyEarned: number,              -- Lifetime money earned
    totalTimePlayed: number,               -- Total seconds played
    totalRobuxSpent: number,               -- Lifetime Robux spent
    index: {
        normal: {string},
        gold: {string},
        diamond: {string},
        rainbow: {string},
    },
    unlockedFences: {string},
    tutorialComplete: boolean,
}

export type FoodTier = {
    name: string,          -- Display name
    cost: number,          -- Price
    maxRarity: string,     -- Highest rarity attracted
    stayChance: number,    -- 0.0 to 1.0
}

export type BrainrotConfig = {
    name: string,
    rarity: string,
    baseEarningsPerSec: number,
    description: string,
    baseWeight: number,
}
```

**Module return:**

```luau
-- Types.luau does not return a value at runtime.
-- It exists solely for type exports.
-- Return an empty table to satisfy ModuleScript requirements.
return {}
```

> **Implementation note:** Other modules access these types via `local Types = require(ReplicatedStorage.Shared.Types)` and then use `Types.BrainrotInstance` etc. in type annotations.

---

### 4.4 `src/shared/Utils.luau`

**Purpose:** Shared utility functions used by both server and client code. Pure function library with zero external dependencies (uses only Roblox services directly).

**Public API:**

```luau
function Utils.weightedRandom(weights: {[string]: number}): string
```
- Takes a dictionary where keys are option names and values are numeric weights.
- Sums all weights, generates a random number between 0 and the total, iterates through entries subtracting weights until the random number is exhausted, returns the corresponding key.
- Uses `math.random()` seeded by Roblox's built-in randomization.
- **Step by step:**
  1. Compute `totalWeight` by summing all values in the `weights` table.
  2. Generate `roll = math.random() * totalWeight` (a float between 0 and totalWeight).
  3. For each key-value pair in `weights`: subtract the value from `roll`. If `roll <= 0`, return the key.
  4. As a fallback (floating point edge case), return the last key iterated.

```luau
function Utils.generateId(): string
```
- Generates a unique identifier string using `game:GetService("HttpService"):GenerateGUID(false)`.
- Returns the GUID string (32 hex characters, no hyphens).
- **Step by step:**
  1. Call `HttpService:GenerateGUID(false)`.
  2. Return the result.

```luau
function Utils.formatNumber(n: number): string
```
- Formats large numbers with suffixes for readability.
- **Rules:**
  - `n < 1,000` -> return as-is with no decimal, e.g. `"500"`
  - `n >= 1,000 and n < 1,000,000` -> format as `"X.XK"`, e.g. `1500` -> `"1.5K"`
  - `n >= 1,000,000 and n < 1,000,000,000` -> format as `"X.XM"`, e.g. `2500000` -> `"2.5M"`
  - `n >= 1,000,000,000 and n < 1,000,000,000,000` -> format as `"X.XB"`, e.g. `5000000000` -> `"5B"`
  - `n >= 1,000,000,000,000` -> format as `"X.XT"`, e.g. `1500000000000` -> `"1.5T"`
- Show one decimal place. If the decimal is `.0`, still show it (e.g. `"5.0K"`).
- **Step by step:**
  1. Define suffixes array: `{ {1e12, "T"}, {1e9, "B"}, {1e6, "M"}, {1e3, "K"} }`.
  2. Iterate from largest to smallest. If `n >= threshold`, compute `value = n / threshold`, format as `string.format("%.1f%s", value, suffix)`, return.
  3. If no suffix applies, return `tostring(math.floor(n))`.

```luau
function Utils.deepCopy(t: {[any]: any}): {[any]: any}
```
- Creates a deep copy of a table (recursively copies nested tables).
- **Step by step:**
  1. If `t` is not a table, return `t` as-is.
  2. Create a new empty table `copy`.
  3. For each key-value pair in `t`: set `copy[key] = Utils.deepCopy(value)`.
  4. Return `copy`.

**Module return:**

```luau
return Utils
```

---

### 4.5 `src/server/Remotes/init.luau`

**Purpose:** Creates all RemoteEvent instances inside a Folder called `"Remotes"` under `ReplicatedStorage`. This module runs at boot time before any service, so services can immediately reference remotes. Returns a table keyed by remote name for easy access.

**Phase 1 remotes to create (all RemoteEvent):**

| Remote Name | Direction | Payload |
|---|---|---|
| `BuyFood` | C->S | `{ foodTier: string }` |
| `BrainrotSpawned` | S->C | `{ brainrotData: BrainrotInstance }` |
| `BrainrotRanAway` | S->C | `{ brainrotName: string, rarity: string }` |
| `MoneyUpdated` | S->C | `{ money: number }` |
| `EarningsUpdated` | S->C | `{ earningsPerSec: number }` |
| `UpgradeCapacity` | C->S | `{}` |
| `CapacityUpdated` | S->C | `{ current: number, max: number }` |
| `InitialData` | S->C | `{ money: number, earningsPerSec: number, capacity: { current: number, max: number }, brainrots: {BrainrotInstance} }` |

**Internal logic:**

1. Get `ReplicatedStorage` service.
2. Create a `Folder` named `"Remotes"`, parent it to `ReplicatedStorage`.
3. Define an array of remote names: `{ "BuyFood", "BrainrotSpawned", "BrainrotRanAway", "MoneyUpdated", "EarningsUpdated", "UpgradeCapacity", "CapacityUpdated", "InitialData" }`.
4. For each name in the array:
   a. Create a new `Instance.new("RemoteEvent")`.
   b. Set its `Name` to the remote name.
   c. Parent it to the Remotes folder.
   d. Store it in a dictionary: `Remotes[name] = remoteInstance`.
5. Return the `Remotes` dictionary.

**Module return:**

```luau
return Remotes  -- { BuyFood = RemoteEvent, MoneyUpdated = RemoteEvent, ... }
```

---

### 4.6 `src/server/Services/DataService.luau`

**Purpose:** Manages all player data persistence using ProfileStore. Loads player profiles on join, provides read/write access to other services, handles saving on leave.

**Dependencies:**

- `Packages/ProfileStore` (via `ReplicatedStorage.Packages.profilestore`)
- `src/shared/Types` (for type annotations)
- `src/server/Remotes/init` (for firing MoneyUpdated and InitialData)

**Constants:**

```luau
local PROFILE_STORE_NAME = "PlayerData_v1"

local DEFAULT_DATA = {
    money = 100,
    ownedBrainrots = {},
    baseCapacity = 1,
    totalMoneyEarned = 0,
    totalTimePlayed = 0,
    totalRobuxSpent = 0,
    index = {
        normal = {},
        gold = {},
        diamond = {},
        rainbow = {},
    },
    unlockedFences = {},
    tutorialComplete = false,
}
```

**Internal state:**

```luau
local profileStore = nil           -- ProfileStore instance (set in init)
local activeProfiles = {}          -- {[Player]: Profile}
local sessionStartTimes = {}       -- {[Player]: number} for tracking play time
```

**Public API:**

```luau
function DataService.init()
```
- **Step by step:**
  1. Require ProfileStore from `ReplicatedStorage.Packages.profilestore`.
  2. Call `ProfileStore.New(PROFILE_STORE_NAME, DEFAULT_DATA)` to create/get the profile store.
  3. Store the result in `profileStore`.

```luau
function DataService.onPlayerAdded(player: Player)
```
- **Step by step:**
  1. Call `profileStore:LoadProfileAsync("Player_" .. player.UserId)`.
  2. If the profile is `nil` (failed to load), kick the player with message `"Failed to load your data. Please rejoin."` and return.
  3. Check if `player.Parent` is nil (player left during load). If so, call `profile:Release()` and return.
  4. Call `profile:Reconcile()` to fill in any missing fields from DEFAULT_DATA.
  5. Connect `profile.OnSessionEnd` to kick the player if the profile is released externally.
  6. Store `activeProfiles[player] = profile`.
  7. Store `sessionStartTimes[player] = os.clock()`.
  8. Get the Remotes table (require the Remotes module).
  9. Compute `earningsPerSec` by summing `brainrot.earningsPerSec` for all brainrots in `profile.Data.ownedBrainrots`.
  10. Fire `Remotes.InitialData:FireClient(player, { money = profile.Data.money, earningsPerSec = earningsPerSec, capacity = { current = #profile.Data.ownedBrainrots, max = profile.Data.baseCapacity }, brainrots = profile.Data.ownedBrainrots })`.

```luau
function DataService.onPlayerRemoving(player: Player)
```
- **Step by step:**
  1. Get the profile from `activeProfiles[player]`. If nil, return.
  2. If `sessionStartTimes[player]` exists, calculate elapsed time and add to `profile.Data.totalTimePlayed`.
  3. Call `profile:Release()` (this triggers auto-save).
  4. Set `activeProfiles[player] = nil`.
  5. Set `sessionStartTimes[player] = nil`.

```luau
function DataService.getData(player: Player): {[string]: any}?
```
- **Step by step:**
  1. Get the profile from `activeProfiles[player]`. If nil, return nil.
  2. Return `profile.Data` (this is the live data table that ProfileStore auto-saves).

```luau
function DataService.addMoney(player: Player, amount: number)
```
- **Step by step:**
  1. Get data via `DataService.getData(player)`. If nil, return.
  2. Add `amount` to `data.money`.
  3. Add `amount` to `data.totalMoneyEarned`.
  4. Fire `Remotes.MoneyUpdated:FireClient(player, { money = data.money })`.

```luau
function DataService.subtractMoney(player: Player, amount: number): boolean
```
- **Step by step:**
  1. Get data via `DataService.getData(player)`. If nil, return false.
  2. If `data.money < amount`, return false.
  3. Subtract `amount` from `data.money`.
  4. Fire `Remotes.MoneyUpdated:FireClient(player, { money = data.money })`.
  5. Return true.

---

### 4.7 `src/server/Services/BaseService.luau`

**Purpose:** Manages plot assignment for players and tracks brainrot capacity. In Phase 1, there is a single plot at a fixed position and capacity starts at 1.

**Dependencies:**

- `src/server/Services/DataService` (for getData, subtractMoney)
- `src/server/Remotes/init` (for UpgradeCapacity, CapacityUpdated)

**Constants:**

```luau
local PLOT_POSITIONS = {
    Vector3.new(0, 1, 0),     -- Plot 1 position (slightly above baseplate)
}
local MAX_PLOTS = 1  -- Phase 1: only 1 plot
```

**Internal state:**

```luau
local playerPlots = {}   -- {[Player]: number} mapping player to plot index
local occupiedPlots = {}  -- {[number]: boolean} which plots are taken
```

**Public API:**

```luau
function BaseService.init()
```
- **Step by step:**
  1. Get the Remotes table.
  2. Connect `Remotes.UpgradeCapacity.OnServerEvent` to `handleUpgradeCapacity`.
  3. (The handler is a placeholder in Phase 1 -- it does nothing or warns "Not available yet".)

```luau
function BaseService.onPlayerAdded(player: Player)
```
- **Step by step:**
  1. Iterate `PLOT_POSITIONS` by index. Find the first index not in `occupiedPlots`.
  2. If no plot is available, warn and return (should not happen with 1 plot and 1-player testing).
  3. Set `occupiedPlots[plotIndex] = true`.
  4. Set `playerPlots[player] = plotIndex`.

```luau
function BaseService.onPlayerRemoving(player: Player)
```
- **Step by step:**
  1. Get the plot index from `playerPlots[player]`. If nil, return.
  2. Set `occupiedPlots[plotIndex] = nil`.
  3. Set `playerPlots[player] = nil`.

```luau
function BaseService.getPlotPosition(player: Player): Vector3?
```
- **Step by step:**
  1. Get the plot index from `playerPlots[player]`. If nil, return nil.
  2. Return `PLOT_POSITIONS[plotIndex]`.

```luau
function BaseService.canAddBrainrot(player: Player): boolean
```
- **Step by step:**
  1. Get data via `DataService.getData(player)`. If nil, return false.
  2. Return `#data.ownedBrainrots < data.baseCapacity`.

```luau
function BaseService.getCapacity(player: Player): (number, number)
```
- **Step by step:**
  1. Get data via `DataService.getData(player)`. If nil, return `0, 0`.
  2. Return `#data.ownedBrainrots, data.baseCapacity`.

**Internal function (placeholder for Phase 1):**

```luau
local function handleUpgradeCapacity(player: Player)
```
- **Phase 1:** Print a warning `"Capacity upgrade not available in Phase 1"`. Return without doing anything.
- **Future phases** will implement the exponential cost formula: `baseCost * 2^(currentCapacity - 1)`.

---

### 4.8 `src/server/Services/FoodService.luau`

**Purpose:** Handles the core "buy food to get a brainrot" loop. This is the most important service -- it implements the primary game mechanic. Listens for the `BuyFood` remote and executes the full buy/roll/stay pipeline.

**Dependencies:**

- `src/shared/Config/Brainrots` (for BRAINROTS_BY_RARITY, BRAINROT_BY_NAME)
- `src/shared/Config/Foods` (for FOOD_BY_NAME, RARITY_WEIGHTS)
- `src/shared/Utils` (for weightedRandom, generateId)
- `src/server/Services/DataService` (for getData, subtractMoney)
- `src/server/Services/BaseService` (for canAddBrainrot)
- `src/server/Services/EarningsService` (for recalculate)
- `src/server/Remotes/init` (for BuyFood, BrainrotSpawned, BrainrotRanAway, CapacityUpdated)

**Constants:**

```luau
-- Phase 1 gate: only these food tiers are allowed
local ALLOWED_FOODS_PHASE1 = { ["Common Chow"] = true }
```

**Public API:**

```luau
function FoodService.init()
```
- **Step by step:**
  1. Get the Remotes table.
  2. Connect `Remotes.BuyFood.OnServerEvent` to `handleBuyFood`.

**Internal function:**

```luau
local function handleBuyFood(player: Player, data: {[string]: any})
```
- **Step by step:**
  1. **Validate player data:** Call `DataService.getData(player)`. If nil, warn and return.
  2. **Validate food tier name:** Extract `data.foodTier` (should be a string). If not a string, warn and return.
  3. **Validate food tier exists:** Look up `Foods.FOOD_BY_NAME[data.foodTier]`. If nil, warn and return.
  4. **Phase 1 gate:** Check `ALLOWED_FOODS_PHASE1[data.foodTier]`. If not true, warn and return.
  5. **Validate money:** Get `food.cost`. If `playerData.money < food.cost`, warn and return.
  6. **Validate capacity:** Call `BaseService.canAddBrainrot(player)`. If false, warn and return.
  7. **Deduct money:** Call `DataService.subtractMoney(player, food.cost)`. If returns false, warn and return (double-check).
  8. **Roll rarity:** Get the rarity weights for this food tier from `Foods.RARITY_WEIGHTS[data.foodTier]`. Call `Utils.weightedRandom(rarityWeights)` to get a rarity string (e.g. "Common").
  9. **Roll brainrot:** Get the list of brainrot names for the rolled rarity from `Brainrots.BRAINROTS_BY_RARITY[rolledRarity]`. Pick a random name from the list using `math.random(1, #nameList)`.
  10. **Get brainrot config:** Look up `Brainrots.BRAINROT_BY_NAME[rolledName]` to get the full config entry.
  11. **Construct BrainrotInstance:**
      ```luau
      local brainrotInstance = {
          id = Utils.generateId(),
          name = brainrotConfig.name,
          rarity = brainrotConfig.rarity,
          size = 1.0,                         -- Phase 1: no size system
          sizeLabel = "Medium",               -- Phase 1: always Medium
          weight = brainrotConfig.baseWeight,  -- Phase 1: base weight (no size scaling)
          baseMutation = nil,                 -- Phase 1: no mutations
          weatherMutation = nil,              -- Phase 1: no weather
          personality = nil,                  -- Phase 1: no personalities
          earningsPerSec = brainrotConfig.baseEarningsPerSec,  -- Phase 1: base earnings only
      }
      ```
  12. **Roll stay chance:** Generate `math.random()`. If the random value `<= food.stayChance`, the brainrot stays. Otherwise it runs away.
  13. **If stays:**
      a. Append `brainrotInstance` to `playerData.ownedBrainrots` via `table.insert(playerData.ownedBrainrots, brainrotInstance)`.
      b. Call `EarningsService.recalculate(player)`.
      c. Fire `Remotes.BrainrotSpawned:FireClient(player, { brainrotData = brainrotInstance })`.
      d. Get capacity via `BaseService.getCapacity(player)`. Fire `Remotes.CapacityUpdated:FireClient(player, { current = current, max = max })`.
  14. **If runs away:**
      a. Fire `Remotes.BrainrotRanAway:FireClient(player, { brainrotName = brainrotInstance.name, rarity = brainrotInstance.rarity })`.

---

### 4.9 `src/server/Services/EarningsService.luau`

**Purpose:** Runs the passive income loop. Every 1 second, iterates over all online players, sums their brainrot earnings, adds the total to their money, and fires update remotes.

**Dependencies:**

- `src/server/Services/DataService` (for getData, addMoney)
- `src/server/Remotes/init` (for EarningsUpdated)
- `Players` service (to get online players)

**Internal state:**

```luau
local earningsCache = {}  -- {[Player]: number} cached total earningsPerSec per player
```

**Public API:**

```luau
function EarningsService.init()
```
- **Step by step:**
  1. Start the earnings loop by calling `task.spawn(earningsLoop)`.

```luau
function EarningsService.recalculate(player: Player)
```
- **Step by step:**
  1. Get data via `DataService.getData(player)`. If nil, set `earningsCache[player] = 0` and return.
  2. Sum `earningsPerSec` for every brainrot in `data.ownedBrainrots`.
  3. Store the sum in `earningsCache[player]`.
  4. Fire `Remotes.EarningsUpdated:FireClient(player, { earningsPerSec = earningsCache[player] })`.

**Internal function:**

```luau
local function earningsLoop()
```
- **Step by step:**
  1. Enter an infinite loop: `while true do`.
  2. Call `task.wait(1)` (yields for 1 second).
  3. For each player in `game:GetService("Players"):GetPlayers()`:
     a. Get `totalEarnings` from `earningsCache[player]`. If nil or 0, skip.
     b. Call `DataService.addMoney(player, totalEarnings)`.
     (Note: `addMoney` already fires `MoneyUpdated` to the client.)

**Cleanup:**

When a player leaves, `earningsCache[player]` should be cleaned up. This can be done by listening to `Players.PlayerRemoving` inside `init()` or by the init.server.luau bootstrap calling a cleanup function. Simplest approach: in `init()`, connect `Players.PlayerRemoving` to set `earningsCache[player] = nil`.

---

### 4.10 `src/client/Controllers/MoneyUI.luau`

**Purpose:** Creates the heads-up display showing the player's current money balance and earnings per second. Listens for `MoneyUpdated`, `EarningsUpdated`, and `InitialData` remotes to keep the display current.

**Dependencies:**

- `src/shared/Utils` (for formatNumber)
- `ReplicatedStorage.Remotes` (the Folder created by server's Remotes/init.luau)

**UI Layout:**

Create a `ScreenGui` named `"MoneyGui"` parented to `player.PlayerGui`. Inside it, create a `Frame` positioned at the top-center of the screen containing:

1. **MoneyLabel** (TextLabel): Shows current money, e.g. `"$100"`. Large font, white text, positioned prominently.
2. **EarningsLabel** (TextLabel): Shows earnings rate, e.g. `"+$0/sec"`. Smaller font, green text, positioned below MoneyLabel.

**Detailed UI properties:**

```
ScreenGui "MoneyGui"
  Frame "MoneyFrame"
    Position: UDim2.new(0.5, 0, 0, 10)  -- top center
    AnchorPoint: Vector2.new(0.5, 0)
    Size: UDim2.new(0, 300, 0, 80)
    BackgroundTransparency: 1

    TextLabel "MoneyLabel"
      Position: UDim2.new(0.5, 0, 0, 0)
      AnchorPoint: Vector2.new(0.5, 0)
      Size: UDim2.new(1, 0, 0, 45)
      Text: "$100"
      TextColor3: Color3.fromRGB(255, 255, 255)
      TextScaled: true
      Font: Enum.Font.GothamBold
      BackgroundTransparency: 1

    TextLabel "EarningsLabel"
      Position: UDim2.new(0.5, 0, 0, 45)
      AnchorPoint: Vector2.new(0.5, 0)
      Size: UDim2.new(1, 0, 0, 30)
      Text: "+$0/sec"
      TextColor3: Color3.fromRGB(85, 255, 85)
      TextScaled: true
      Font: Enum.Font.Gotham
      BackgroundTransparency: 1
```

**Public API:**

```luau
function MoneyUI.Init()
```
- **Step by step:**
  1. Get `player` from `Players.LocalPlayer`.
  2. Wait for `ReplicatedStorage:WaitForChild("Remotes")`.
  3. Get references to `MoneyUpdated`, `EarningsUpdated`, and `InitialData` remote events.
  4. Build the UI hierarchy described above. Parent `ScreenGui` to `player.PlayerGui`.
  5. Store references to `MoneyLabel` and `EarningsLabel` for updating.
  6. Connect `InitialData.OnClientEvent` handler:
     - Update `MoneyLabel.Text` to `"$" .. Utils.formatNumber(data.money)`.
     - Update `EarningsLabel.Text` to `"+$" .. Utils.formatNumber(data.earningsPerSec) .. "/sec"`.
  7. Connect `MoneyUpdated.OnClientEvent` handler:
     - Update `MoneyLabel.Text` to `"$" .. Utils.formatNumber(data.money)`.
  8. Connect `EarningsUpdated.OnClientEvent` handler:
     - Update `EarningsLabel.Text` to `"+$" .. Utils.formatNumber(data.earningsPerSec) .. "/sec"`.

---

### 4.11 `src/client/Controllers/FoodStoreUI.luau`

**Purpose:** Creates the food store interface with a buy button. In Phase 1, this is a single button for "Common Chow" at $50. Fires `BuyFood` when clicked. Displays feedback when a brainrot spawns or runs away.

**Dependencies:**

- `ReplicatedStorage.Remotes` (for BuyFood, BrainrotSpawned, BrainrotRanAway)
- `src/shared/Config/Foods` (for food cost display)

**UI Layout:**

Create a `ScreenGui` named `"FoodStoreGui"` parented to `player.PlayerGui`. Inside it:

1. **BuyButton** (TextButton): Positioned at the bottom-center of the screen. Text: `"Buy Common Chow - $50"`. Visible green button.
2. **FeedbackLabel** (TextLabel): Positioned above the buy button. Shows temporary messages like "Burbaloni Lulilolli spawned!" or "It ran away!". Starts hidden (transparent).

**Detailed UI properties:**

```
ScreenGui "FoodStoreGui"
  TextButton "BuyButton"
    Position: UDim2.new(0.5, 0, 1, -80)
    AnchorPoint: Vector2.new(0.5, 1)
    Size: UDim2.new(0, 280, 0, 60)
    Text: "Buy Common Chow - $50"
    TextColor3: Color3.fromRGB(255, 255, 255)
    BackgroundColor3: Color3.fromRGB(46, 204, 113)
    TextScaled: true
    Font: Enum.Font.GothamBold
    -- Add UICorner with CornerRadius 12

  TextLabel "FeedbackLabel"
    Position: UDim2.new(0.5, 0, 1, -150)
    AnchorPoint: Vector2.new(0.5, 1)
    Size: UDim2.new(0, 400, 0, 40)
    Text: ""
    TextColor3: Color3.fromRGB(255, 255, 255)
    TextScaled: true
    Font: Enum.Font.GothamBold
    BackgroundTransparency: 1
    TextTransparency: 1   -- starts invisible
```

**Public API:**

```luau
function FoodStoreUI.Init()
```
- **Step by step:**
  1. Get `player` from `Players.LocalPlayer`.
  2. Wait for `ReplicatedStorage:WaitForChild("Remotes")`.
  3. Get references to `BuyFood`, `BrainrotSpawned`, `BrainrotRanAway` remotes.
  4. Build the UI hierarchy described above.
  5. Connect `BuyButton.Activated` (or `MouseButton1Click`):
     a. Fire `BuyFood:FireServer({ foodTier = "Common Chow" })`.
  6. Connect `BrainrotSpawned.OnClientEvent` handler:
     a. Set `FeedbackLabel.Text` to the brainrot name .. `" joined your base!"`.
     b. Set `FeedbackLabel.TextColor3` to green (`Color3.fromRGB(85, 255, 85)`).
     c. Set `FeedbackLabel.TextTransparency` to 0 (visible).
     d. Wait 3 seconds (`task.delay(3, ...)`), then fade out by setting `TextTransparency` to 1.
  7. Connect `BrainrotRanAway.OnClientEvent` handler:
     a. Set `FeedbackLabel.Text` to the brainrot name .. `" ran away!"`.
     b. Set `FeedbackLabel.TextColor3` to red (`Color3.fromRGB(255, 85, 85)`).
     c. Set `FeedbackLabel.TextTransparency` to 0 (visible).
     d. Wait 3 seconds, then fade out.

---

### 4.12 `src/client/Controllers/BaseUI.luau`

**Purpose:** Manages the visual representation of brainrots on the player's plot. When a brainrot spawns, creates a simple Part with a BillboardGui showing the brainrot's name. Displays capacity text. Also handles the InitialData remote to place existing brainrots on rejoin.

**Dependencies:**

- `ReplicatedStorage.Remotes` (for BrainrotSpawned, CapacityUpdated, InitialData)
- `src/shared/Utils` (for formatNumber)
- `Players` service

**UI elements:**

1. **Capacity ScreenGui** -- A simple text at the top-right showing "1/1 Brainrots" (or "0/1 Brainrots").
2. **3D brainrot Parts** -- For each brainrot on the base, a Part in Workspace with a BillboardGui displaying the name and rarity.

**ScreenGui layout for capacity display:**

```
ScreenGui "CapacityGui"
  TextLabel "CapacityLabel"
    Position: UDim2.new(1, -10, 0, 10)
    AnchorPoint: Vector2.new(1, 0)
    Size: UDim2.new(0, 200, 0, 40)
    Text: "0/1 Brainrots"
    TextColor3: Color3.fromRGB(255, 255, 255)
    TextScaled: true
    Font: Enum.Font.GothamBold
    BackgroundTransparency: 1
```

**Rarity color map (constant):**

```luau
local RARITY_COLORS = {
    Common    = Color3.fromRGB(255, 255, 255),
    Rare      = Color3.fromRGB(52, 152, 219),
    Epic      = Color3.fromRGB(155, 89, 182),
    Legendary = Color3.fromRGB(230, 126, 34),
    Mythic    = Color3.fromRGB(231, 76, 60),
    Goldy     = Color3.fromRGB(241, 196, 15),
    Secret    = Color3.fromRGB(26, 188, 156),
    Unknown   = Color3.fromRGB(44, 62, 80),
}
```

**Internal state:**

```luau
local brainrotParts = {}  -- {[string]: Part} maps brainrot id to its 3D Part in Workspace
local plotPosition = nil   -- Vector3, received via InitialData or computed
```

**Public API:**

```luau
function BaseUI.Init()
```
- **Step by step:**
  1. Get `player` from `Players.LocalPlayer`.
  2. Wait for `ReplicatedStorage:WaitForChild("Remotes")`.
  3. Get references to `BrainrotSpawned`, `CapacityUpdated`, `InitialData` remotes.
  4. Build the CapacityGui described above. Parent to `player.PlayerGui`.
  5. Connect `InitialData.OnClientEvent` handler:
     a. Update `CapacityLabel.Text` to `data.capacity.current .. "/" .. data.capacity.max .. " Brainrots"`.
     b. Set `plotPosition` to `Vector3.new(0, 1, 0)` (matching server's PLOT_POSITIONS[1]).
     c. For each brainrot in `data.brainrots`, call `spawnBrainrotVisual(brainrot)`.
  6. Connect `BrainrotSpawned.OnClientEvent` handler:
     a. Call `spawnBrainrotVisual(data.brainrotData)`.
  7. Connect `CapacityUpdated.OnClientEvent` handler:
     a. Update `CapacityLabel.Text` to `data.current .. "/" .. data.max .. " Brainrots"`.

**Internal function:**

```luau
local function spawnBrainrotVisual(brainrot: Types.BrainrotInstance)
```
- **Step by step:**
  1. Create a `Part` (Anchored = true, CanCollide = false).
  2. Set `Size` to `Vector3.new(3, 3, 3)` (simple cube placeholder for Phase 1).
  3. Set `Color` to `RARITY_COLORS[brainrot.rarity]` or white as fallback.
  4. Compute position: use `plotPosition` plus a random small X/Z offset (e.g., `math.random(-5, 5)`) so multiple brainrots don't stack on top of each other. Y = `plotPosition.Y + 1.5` (so the cube sits on the surface).
  5. Set `Part.Position` to the computed position.
  6. Create a `BillboardGui` parented to the Part:
     - `Size = UDim2.new(0, 200, 0, 60)`
     - `StudsOffset = Vector3.new(0, 3, 0)` (floats above the Part)
     - `AlwaysOnTop = true`
  7. Create a `TextLabel` inside the BillboardGui:
     - `Size = UDim2.new(1, 0, 0.5, 0)`
     - `Text = brainrot.name`
     - `TextColor3 = RARITY_COLORS[brainrot.rarity]`
     - `TextScaled = true`
     - `Font = Enum.Font.GothamBold`
     - `BackgroundTransparency = 1`
  8. Create a second `TextLabel` for earnings:
     - `Size = UDim2.new(1, 0, 0.5, 0)`
     - `Position = UDim2.new(0, 0, 0.5, 0)`
     - `Text = "+$" .. Utils.formatNumber(brainrot.earningsPerSec) .. "/sec"`
     - `TextColor3 = Color3.fromRGB(85, 255, 85)`
     - `TextScaled = true`
     - `BackgroundTransparency = 1`
  9. Parent the Part to `Workspace`.
  10. Store `brainrotParts[brainrot.id] = part` for future cleanup.

---

### 4.13 `src/server/init.server.luau`

**Purpose:** Server bootstrap script. Requires and initializes all Phase 1 services in the correct dependency order. Connects `PlayerAdded` and `PlayerRemoving` lifecycle events.

**Full implementation spec:**

```luau
-- init.server.luau
-- Server bootstrap: load services in dependency order

local Players = game:GetService("Players")

-- 1. Create all remotes first (must exist before services connect listeners)
local Remotes = require(script.Remotes)

-- 2. Initialize services in dependency order
local DataService = require(script.Services.DataService)
DataService.init()

local BaseService = require(script.Services.BaseService)
BaseService.init()

local EarningsService = require(script.Services.EarningsService)
EarningsService.init()

local FoodService = require(script.Services.FoodService)
FoodService.init()

-- Connect player lifecycle events
Players.PlayerAdded:Connect(function(player)
    DataService.onPlayerAdded(player)
    BaseService.onPlayerAdded(player)
end)

Players.PlayerRemoving:Connect(function(player)
    BaseService.onPlayerRemoving(player)
    DataService.onPlayerRemoving(player)
end)

-- Handle players who joined before the script loaded (Studio edge case)
for _, player in Players:GetPlayers() do
    task.spawn(function()
        DataService.onPlayerAdded(player)
        BaseService.onPlayerAdded(player)
    end)
end

print("[Server] All Phase 1 services initialized.")
```

**Key notes:**

- `Remotes` is required first (step 1 of boot order).
- DataService is initialized before BaseService because BaseService may query player data.
- EarningsService is initialized before FoodService because FoodService calls `EarningsService.recalculate()`.
- The `for _, player` loop at the bottom handles a Studio edge case where the player may join before the server script fully loads.
- PlayerRemoving calls `BaseService.onPlayerRemoving` before `DataService.onPlayerRemoving` so that the base cleanup happens while data is still accessible.

---

### 4.14 `src/client/init.client.luau`

**Purpose:** Client bootstrap script. Requires and initializes all Phase 1 UI controllers.

**Full implementation spec:**

```luau
-- init.client.luau
-- Client bootstrap: load all UI controllers

local MoneyUI = require(script.Controllers.MoneyUI)
local FoodStoreUI = require(script.Controllers.FoodStoreUI)
local BaseUI = require(script.Controllers.BaseUI)

MoneyUI.Init()
FoodStoreUI.Init()
BaseUI.Init()

print("[Client] All Phase 1 controllers initialized.")
```

---

## 5. Module Contracts

This section lists exactly how each module communicates with other modules. Every cross-module call is documented here.

### Server-Side Contracts

**FoodService calls:**

| Calls | Function | Purpose |
|---|---|---|
| DataService | `.getData(player)` | Get player data to validate money and modify brainrot list |
| DataService | `.subtractMoney(player, amount)` | Deduct food cost |
| BaseService | `.canAddBrainrot(player)` | Check capacity before rolling |
| BaseService | `.getCapacity(player)` | Get current/max for CapacityUpdated remote |
| EarningsService | `.recalculate(player)` | Recompute earnings after a brainrot is added |
| Remotes | `.BrainrotSpawned:FireClient()` | Notify client of new brainrot |
| Remotes | `.BrainrotRanAway:FireClient()` | Notify client that brainrot fled |
| Remotes | `.CapacityUpdated:FireClient()` | Update capacity display |

**EarningsService calls:**

| Calls | Function | Purpose |
|---|---|---|
| DataService | `.getData(player)` | Read brainrot list to sum earnings |
| DataService | `.addMoney(player, amount)` | Add passive income each second |
| Remotes | `.EarningsUpdated:FireClient()` | Update earnings/sec display |

**DataService calls:**

| Calls | Function | Purpose |
|---|---|---|
| ProfileStore | `.New()`, `:LoadProfileAsync()`, `:Release()` | Manage player profiles |
| Remotes | `.MoneyUpdated:FireClient()` | Update money display on add/subtract |
| Remotes | `.InitialData:FireClient()` | Send initial state on join |

**BaseService calls:**

| Calls | Function | Purpose |
|---|---|---|
| DataService | `.getData(player)` | Read capacity and brainrot count |

### Client-Side Contracts

**FoodStoreUI:**

| Remote | Direction | Purpose |
|---|---|---|
| `BuyFood` | Fires to server | Player clicked buy button |
| `BrainrotSpawned` | Listens from server | Show "spawned!" feedback |
| `BrainrotRanAway` | Listens from server | Show "ran away!" feedback |

**MoneyUI:**

| Remote | Direction | Purpose |
|---|---|---|
| `MoneyUpdated` | Listens from server | Update money text |
| `EarningsUpdated` | Listens from server | Update earnings/sec text |
| `InitialData` | Listens from server | Set initial money and earnings display |

**BaseUI:**

| Remote | Direction | Purpose |
|---|---|---|
| `BrainrotSpawned` | Listens from server | Place brainrot visual in world |
| `CapacityUpdated` | Listens from server | Update capacity text |
| `InitialData` | Listens from server | Place existing brainrots and set capacity |

---

## 6. Agent Task Breakdown

Tasks are organized into batches. All tasks within a batch can be done in parallel. Batches must be completed in order.

### Batch 1 -- Pure Data (no dependencies)

These files have zero imports from other project files. They can all be written simultaneously.

| Task | File | Est. Lines |
|---|---|---|
| 1.1 | `src/shared/Config/Brainrots.luau` | ~120 |
| 1.2 | `src/shared/Config/Foods.luau` | ~70 |
| 1.3 | `src/shared/Types.luau` | ~50 |
| 1.4 | `src/shared/Utils.luau` | ~70 |

### Batch 2 -- Remotes (depends on knowing remote names from Section 4.5)

| Task | File | Est. Lines |
|---|---|---|
| 2.1 | `src/server/Remotes/init.luau` | ~30 |

### Batch 3 -- Core Services (depends on Batch 1 + 2)

DataService and BaseService have minimal cross-dependencies and can be written in parallel.

| Task | File | Est. Lines |
|---|---|---|
| 3.1 | `src/server/Services/DataService.luau` | ~100 |
| 3.2 | `src/server/Services/BaseService.luau` | ~80 |

### Batch 4 -- Dependent Services (depends on Batch 3)

These services depend on DataService and/or BaseService. Write them sequentially.

| Task | File | Depends On | Est. Lines |
|---|---|---|---|
| 4.1 | `src/server/Services/EarningsService.luau` | DataService | ~60 |
| 4.2 | `src/server/Services/FoodService.luau` | DataService, BaseService, EarningsService | ~120 |

### Batch 5 -- Client Controllers (depends on Batch 2 for remote names)

All three controllers are independent of each other and can be written in parallel.

| Task | File | Est. Lines |
|---|---|---|
| 5.1 | `src/client/Controllers/MoneyUI.luau` | ~80 |
| 5.2 | `src/client/Controllers/FoodStoreUI.luau` | ~90 |
| 5.3 | `src/client/Controllers/BaseUI.luau` | ~120 |

### Batch 6 -- Bootstrap Scripts (depends on all above)

| Task | File | Est. Lines |
|---|---|---|
| 6.1 | `src/server/init.server.luau` | ~35 |
| 6.2 | `src/client/init.client.luau` | ~12 |

### Total: 14 files, ~1,000 estimated lines of Luau code.

---

## 7. Data Structures

Exact Luau table shapes for Phase 1. These are the concrete values, not just type definitions.

### 7.1 BrainrotInstance (Phase 1 shape)

In Phase 1, several fields are always set to their default/nil values since the corresponding systems are not yet implemented.

```luau
-- A concrete Phase 1 BrainrotInstance example:
{
    id = "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6",  -- 32-char hex GUID
    name = "Burbaloni Lulilolli",
    rarity = "Common",
    size = 1.0,              -- ALWAYS 1.0 in Phase 1 (no size system)
    sizeLabel = "Medium",    -- ALWAYS "Medium" in Phase 1
    weight = 12,             -- ALWAYS baseWeight in Phase 1 (no size scaling)
    baseMutation = nil,      -- ALWAYS nil in Phase 1 (no mutation system)
    weatherMutation = nil,   -- ALWAYS nil in Phase 1 (no weather system)
    personality = nil,       -- ALWAYS nil in Phase 1 (no personality system)
    earningsPerSec = 5,      -- ALWAYS baseEarningsPerSec in Phase 1 (all multipliers are 1.0)
}
```

### 7.2 PlayerData (Phase 1 shape)

All fields exist from Phase 1 (due to ProfileStore reconciliation), but only the first three are actively used.

```luau
-- A concrete Phase 1 PlayerData for a new player:
{
    -- Actively used in Phase 1:
    money = 100,              -- Starting balance
    ownedBrainrots = {},      -- Empty array, fills as brainrots are acquired
    baseCapacity = 1,         -- Starting capacity (1 slot)

    -- Present but unused in Phase 1 (set by DEFAULT_DATA for future phases):
    totalMoneyEarned = 0,
    totalTimePlayed = 0,
    totalRobuxSpent = 0,
    index = {
        normal = {},
        gold = {},
        diamond = {},
        rainbow = {},
    },
    unlockedFences = {},
    tutorialComplete = false,
}
```

### 7.3 Brainrot Config Entry Shape

Each entry in the `BRAINROTS` array:

```luau
{
    name = "Burbaloni Lulilolli",       -- string: unique display name
    rarity = "Common",                  -- string: one of 8 rarity tiers
    baseEarningsPerSec = 5,             -- number: base $/sec
    description = "Bubble creature...", -- string: flavor text
    baseWeight = 12,                    -- number: weight in lbs at Medium size
}
```

### 7.4 Food Config Entry Shape

Each entry in the `FOODS` array:

```luau
{
    name = "Common Chow",     -- string: display name
    cost = 50,                -- number: price in dollars
    maxRarity = "Rare",       -- string: highest rarity attracted
    stayChance = 0.60,        -- number: 0.0 to 1.0, probability of staying
}
```

### 7.5 Remote Payload Shapes (Phase 1)

```luau
-- BuyFood (C->S)
{ foodTier = "Common Chow" }

-- BrainrotSpawned (S->C)
{ brainrotData = {BrainrotInstance} }

-- BrainrotRanAway (S->C)
{ brainrotName = "Burbaloni Lulilolli", rarity = "Common" }

-- MoneyUpdated (S->C)
{ money = 50 }

-- EarningsUpdated (S->C)
{ earningsPerSec = 5 }

-- CapacityUpdated (S->C)
{ current = 1, max = 1 }

-- InitialData (S->C)
{
    money = 100,
    earningsPerSec = 0,
    capacity = { current = 0, max = 1 },
    brainrots = {}
}
```

---

## 8. Testing Criteria

After all files are written, verify the following step by step. Every step must pass.

### Build Test

1. Run `rojo build -o "collect-brainrots.rbxlx"` from the project root. Verify it succeeds with no errors.

### Studio Playtest

2. Open the built `.rbxlx` file in Roblox Studio.
3. Start the Rojo plugin and connect to `rojo serve`.
4. Press **Play** in Studio (solo test mode).

### Initial State Verification

5. Verify the Output console shows `"[Server] All Phase 1 services initialized."` with no errors.
6. Verify the Output console shows `"[Client] All Phase 1 controllers initialized."` with no errors.
7. Verify the money display appears at the top of the screen showing `"$100"`.
8. Verify the earnings display shows `"+$0/sec"`.
9. Verify the capacity display shows `"0/1 Brainrots"`.
10. Verify the `"Buy Common Chow - $50"` button appears at the bottom of the screen.

### Core Loop Test -- Successful Spawn

11. Click the `"Buy Common Chow - $50"` button.
12. Verify money decreases from `$100` to `$50`.
13. Observe one of two outcomes:
    - **Brainrot spawned:** A green feedback message appears with the brainrot's name + "joined your base!". A colored cube appears on the plot with the brainrot's name floating above it. Capacity updates to "1/1 Brainrots". Earnings display updates to "+$5.0/sec" (or "+$50.0/sec" if a rare was rolled).
    - **Brainrot ran away:** A red feedback message appears with the brainrot's name + "ran away!". No cube appears. Capacity stays at "0/1 Brainrots". Earnings remain "+$0/sec".

### Passive Income Test

14. If a brainrot is on the base, wait 5 seconds. Verify the money display increments by approximately $5 per second (the exact number depends on which brainrot spawned).

### Capacity Enforcement Test

15. If a brainrot is on the base (capacity is "1/1"), click the buy button again. Verify the purchase is rejected (money should not decrease). This validates the capacity check.

### Buy-When-Broke Test

16. If money is $0 (or less than $50), click the buy button. Verify nothing happens (money does not go negative).

### Persistence Test

17. Stop the playtest in Studio. Press Play again. Verify that:
    - Money is restored to the value it was at before stopping.
    - The brainrot (if one was spawned) appears on the base again.
    - Earnings/sec is correct based on the saved brainrot.
    - (Note: In Studio with API access disabled, ProfileStore may not persist across sessions. This test may only pass with Studio API Services enabled or in a published place.)

### Console Cleanliness Test

18. Check the Studio Output console for any errors (red text). There should be zero errors. Warnings from placeholder features (like "Capacity upgrade not available in Phase 1") are acceptable.

---

## 9. Acceptance Criteria

All of the following must be true before Phase 1 is considered complete:

| # | Criterion | How to Verify |
|---|---|---|
| 1 | `rojo build` succeeds | Run `rojo build -o "collect-brainrots.rbxlx"` -- no errors |
| 2 | All 14 files exist at their correct paths | Check file tree |
| 3 | Server boots without errors | Check Studio Output for `"[Server] All Phase 1 services initialized."` |
| 4 | Client boots without errors | Check Studio Output for `"[Client] All Phase 1 controllers initialized."` |
| 5 | Money display shows $100 on first join | Visual check |
| 6 | Buy button is visible and clickable | Visual check |
| 7 | Buying food deducts the correct amount ($50) | Observe money display |
| 8 | Brainrot spawn feedback appears (name + "joined your base!") | Visual check |
| 9 | Brainrot run-away feedback appears (name + "ran away!") | Visual check (may need multiple attempts due to 60% stay chance) |
| 10 | Spawned brainrot appears as a 3D Part on the plot | Visual check |
| 11 | BillboardGui shows brainrot name and earnings/sec above the Part | Visual check |
| 12 | Earnings/sec updates correctly after a brainrot spawns | Observe earnings display change from +$0/sec |
| 13 | Passive income works (money increases every second) | Wait and observe money display |
| 14 | Capacity is enforced (cannot buy when base is full at 1/1) | Try buying when full |
| 15 | Money check is enforced (cannot buy when broke) | Try buying with insufficient money |
| 16 | Data persists across sessions (with DataStore access enabled) | Rejoin and verify data |
| 17 | No errors in Studio Output console | Check for red error text |
| 18 | All 25 brainrots are defined in Config/Brainrots.luau | Read the file |
| 19 | All 8 food tiers are defined in Config/Foods.luau | Read the file |
| 20 | Only Common Chow is purchasable (other tiers are gated) | Try buying non-common food (should fail silently) |

---

## Appendix A: Phase 1 Limitations (What Is NOT Included)

These features are intentionally absent from Phase 1. They will be added in later phases. Do not implement them.

| Feature | Deferred To |
|---|---|
| Size system (size tiers, size multipliers, weight scaling) | Phase 2 |
| Base mutations (Gold, Diamond, Rainbow) | Phase 2 |
| Weather events and weather mutations | Phase 6 |
| Personality system | Phase 8 |
| Sell system (individual + bulk sell) | Phase 5 |
| Brainrot fusion (3-to-1 upgrade) | Phase 8 |
| Collection index / codex | Phase 7 |
| Base capacity upgrades (functional) | Phase 2 |
| Multiple plots | Future phase |
| Gifting system | Phase 7 |
| Leaderboards | Phase 7 |
| Tutorial UI | Phase 8 |
| 3D brainrot models (using real meshes instead of cubes) | Phase 2 |
| Sound effects and music | Phase 4 |
| Map building and environment art | Phase 3 |
| Food tiers beyond Common Chow | Phase 2 (gates removed) |
| Rarity weighting beyond commons/rares | Phase 2 (gates removed) |
| Lucky Hours | Future phase |
| VIP Food | Future phase |

## Appendix B: ProfileStore Integration Notes

ProfileStore is the Wally package that wraps Roblox DataStoreService with session-locking, auto-saving, and data reconciliation.

**How to require ProfileStore:**

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProfileStore = require(ReplicatedStorage.Packages.profilestore)
```

> **Important:** The exact module path inside `Packages/` depends on how Wally structures the download. It may be `ReplicatedStorage.Packages.profilestore` or `ReplicatedStorage.Packages.ProfileStore`. Check the actual `Packages/` directory contents after `wally install` to determine the correct require path. If the path is different, adjust DataService accordingly.

**Key ProfileStore API used in Phase 1:**

| Call | Purpose |
|---|---|
| `ProfileStore.New(storeName, defaultData)` | Create/get a profile store with the default template |
| `store:LoadProfileAsync(key)` | Load a player's profile (session-locked) |
| `profile:Reconcile()` | Fill in missing fields from the default template |
| `profile:Release()` | Save and unlock the profile |
| `profile.Data` | The live data table (read/write directly) |
| `profile.OnSessionEnd` | Signal that fires if the profile is released externally |

**Studio testing note:** DataStoreService does not work in Studio by default. To test persistence:
1. In Studio, go to **Home > Game Settings > Security**.
2. Enable **"Enable Studio Access to API Services"**.
3. This allows ProfileStore to use DataStoreService in Studio test mode.
4. Without this setting enabled, ProfileStore will fail to load profiles and players will be kicked.

---

*End of Phase 1 MVP specification.*
