# Phase 3: Size System

> **Status:** NOT STARTED
> **Depends on:** Phase 2 (complete and tested)
> **Estimated scope:** 5 files (1 new, 4 modified)

---

## 1. Objective

Implement the size system where brainrots spawn with random weighted sizes that affect earnings and visual scale. Bigger brainrots earn more but are rarer. Each brainrot has a specific weight in lbs that varies by size.

In Phase 1, all brainrots spawned at size 1.0 with label "Medium" and base weight. Phase 3 replaces those hardcoded defaults with a full size tier roll that produces a continuous size value within one of five tiers, each with distinct spawn probability. The size value directly serves as the earnings multiplier (a size of 1.5 means 1.5x earnings), and it scales the 3D model proportionally.

**Phase 3 scope:**

- Five size tiers (Tiny, Small, Medium, Large, Massive) with weighted spawn chances.
- Each tier defines a continuous range of possible size values; a uniform random value is picked within the rolled tier's range.
- The size value IS the earnings multiplier (no separate multiplier lookup).
- Each brainrot has a base weight in lbs; actual weight = baseWeight * size.
- Visual scale of the brainrot model is set to the size value.
- BillboardGui and spawn feedback updated to display size label and weight.

---

## 2. Prerequisites

Phase 2 must be fully complete and tested before starting Phase 3. Specifically:

- All Phase 1 files exist and work correctly (core loop functional).
- Phase 2 deliverables (3D models, visual polish, food tier gates removed, base mutation system, capacity upgrades) are complete and tested.
- `rojo build -o "collect-brainrots.rbxlx"` succeeds with zero errors.
- The BrainrotInstance type in `Types.luau` already contains `size`, `sizeLabel`, and `weight` fields (added in Phase 1 with placeholder values).
- `Config/Brainrots.luau` already contains `baseWeight` for every brainrot entry.

---

## 3. Files to Create/Modify

Every file is listed with its full path relative to the project root.

### New Files to Create (1 file)

| # | File Path | Purpose |
|---|---|---|
| 1 | `src/shared/Config/Sizes.luau` | Size tiers, spawn weights, per-brainrot base weights, and size utility functions |

### Files to Modify (4 files)

| # | File Path | Change |
|---|---|---|
| 1 | `src/server/Services/FoodService.luau` | Roll size on brainrot spawn using `Sizes.rollSize()`, compute weight, apply size as earnings multiplier |
| 2 | `src/server/Services/EarningsService.luau` | Factor `brainrot.size` into earnings recalculation |
| 3 | `src/client/Controllers/BaseUI.luau` | Scale brainrot model Part by size value, update BillboardGui to show size label and weight |
| 4 | `src/client/Controllers/FoodStoreUI.luau` | Show size label and weight in spawn result feedback |

---

## 4. Detailed Spec Per File

---

### 4.1 `src/shared/Config/Sizes.luau` (CREATE)

**Purpose:** Defines the size tier system, base weight lookup table, and provides utility functions for rolling sizes and computing weights. This is a shared module accessible to both server and client code.

**Dependencies:** None (pure data + pure functions).

**Constants:**

**SIZE_TIERS (ordered list):**

| Tier | Label | Size Range (multiplier) | Spawn Chance | Earnings Multiplier |
|------|-------|------------------------|--------------|---------------------|
| 1 | Tiny | 0.5 - 0.8 | 20% | 0.5x - 0.8x (linear within range) |
| 2 | Small | 0.8 - 1.2 | 40% | 0.8x - 1.2x |
| 3 | Medium | 1.2 - 1.8 | 29% | 1.2x - 1.8x |
| 4 | Large | 1.8 - 2.4 | 10% | 1.8x - 2.4x |
| 5 | Massive | 2.4 - 3.0 | 1% | 2.4x - 3.0x |

> **Key design note:** The size multiplier IS the size value. A brainrot with size 1.5 earns 1.5x its base earnings per second. There is no separate lookup -- the size field on BrainrotInstance directly serves as the earnings multiplier.

```luau
local SIZE_TIERS = {
    { label = "Tiny",    minSize = 0.5, maxSize = 0.8, weight = 20 },
    { label = "Small",   minSize = 0.8, maxSize = 1.2, weight = 40 },
    { label = "Medium",  minSize = 1.2, maxSize = 1.8, weight = 29 },
    { label = "Large",   minSize = 1.8, maxSize = 2.4, weight = 10 },
    { label = "Massive", minSize = 2.4, maxSize = 3.0, weight = 1  },
}
```

**BASE_WEIGHTS:**

A dictionary mapping each of the 25 brainrot names to their base weight in lbs at size 1.0. The actual displayed weight = `baseWeight * size`.

These values are sourced directly from `Config/Brainrots.luau` (the `baseWeight` field on each brainrot entry). They are duplicated here as a flat lookup table for convenience and to keep `Sizes.luau` self-contained with zero dependencies.

```luau
local BASE_WEIGHTS = {
    -- COMMONS (small to medium creatures)
    ["Burbaloni Lulilolli"]       = 12,    -- Bubble creature (light, floaty)
    ["Hipocactus"]                = 85,    -- Hippo-cactus hybrid (chunky)
    ["Bobrito Bandito"]           = 8,     -- Sentient burrito (tiny)
    ["Talpa Di Ferro"]            = 45,    -- Iron mole (dense metal)
    ["Svinino Bombondino"]        = 60,    -- Pig bomber (round piglet + bombs)

    -- RARES (medium to large creatures)
    ["Frigo Camelo"]              = 320,   -- Camel fridge (two humps = two fridges)
    ["Blueberrinni Octopussini"]  = 25,    -- Blueberry octopus (squishy, light)
    ["Orangutini Ananasini"]      = 150,   -- Orangutan pineapple (stocky ape)
    ["Tigrrullini Watermellini"]  = 180,   -- Tiger watermelon (big cat)

    -- EPICS (varied sizes)
    ["Boneca Ambalabu"]           = 30,    -- Surreal doll (porcelain, light)
    ["Chef Crabracadabra"]        = 40,    -- Magic crab chef (crab + hat + pans)
    ["Glorbo Fruttodrillo"]       = 200,   -- Fruit crocodile (full croc body)
    ["Tralalero Tralala"]         = 450,   -- Shark with Nikes (great white sized)

    -- LEGENDARIES (small-bodied but special)
    ["Shpioniro Golubiro"]        = 5,     -- Spy pigeon (tiny bird)
    ["Ballerina Cappuccina"]      = 15,    -- Cappuccino ballerina (foam-light)
    ["Bombombini Gusini"]         = 35,    -- Goose with bombs (goose + arsenal)

    -- MYTHICS (medium creatures)
    ["Chimpanzini Bananini"]      = 90,    -- Monkey-banana hybrid (chimp-sized)
    ["Brr Brr Patapim"]           = 280,   -- Refrigerator DJ (walking fridge)
    ["Cappuccino Assassino"]      = 10,    -- Killer coffee cup (espresso-sized)

    -- GOLDYS (massive creatures)
    ["Lirili Larila"]             = 2500,  -- Cactus elephant (elephant-scale)
    ["Bombardiro Crocodilo"]      = 1800,  -- Crocodile bomber plane (croc + wings)

    -- SECRETS (unusual weights)
    ["Tung Tung Tung Sahur"]      = 120,   -- Log creature with bat (solid wood)
    ["Trippi Troppi"]             = 7,     -- Brain creature (exposed brain, tiny)

    -- UNKNOWNS (extreme weights)
    ["Centralucci Nuclearucci"]   = 50000,  -- Nuclear reactor creature (industrial)
    ["La Vaca Saturno Saturnita"] = 999999, -- Saturn cow (cosmic mass)
}
```

**Public API:**

```luau
function Sizes.rollSize(): (number, string)
```
- Rolls a random size tier using weighted random selection, then picks a uniform random value within that tier's size range.
- **Step by step:**
  1. Compute `totalWeight` by summing all tier weights (20 + 40 + 29 + 10 + 1 = 100).
  2. Generate `roll = math.random() * totalWeight`.
  3. Iterate through `SIZE_TIERS`. For each tier, subtract `tier.weight` from `roll`. If `roll <= 0`, this tier is selected.
  4. Within the selected tier, generate a uniform random size: `size = tier.minSize + math.random() * (tier.maxSize - tier.minSize)`.
  5. Round `size` to 2 decimal places: `size = math.floor(size * 100 + 0.5) / 100`.
  6. Return `size, tier.label`.

```luau
function Sizes.getWeight(brainrotName: string, size: number): number
```
- Returns the weight in lbs for a given brainrot at a given size.
- **Step by step:**
  1. Look up `BASE_WEIGHTS[brainrotName]`. If nil, warn and return 0.
  2. Compute `weight = baseWeight * size`.
  3. Round to 1 decimal place: `weight = math.floor(weight * 10 + 0.5) / 10`.
  4. Return `weight`.

```luau
function Sizes.getLabel(size: number): string
```
- Returns the size label ("Tiny", "Small", "Medium", "Large", "Massive") for a given numeric size value.
- **Step by step:**
  1. Iterate through `SIZE_TIERS` in order.
  2. For each tier, if `size >= tier.minSize and size <= tier.maxSize`, return `tier.label`.
  3. Edge case: if `size < 0.5`, return `"Tiny"`. If `size > 3.0`, return `"Massive"`.
  4. Fallback (should not be reached): return `"Medium"`.

**Module return structure:**

```luau
return {
    SIZE_TIERS = SIZE_TIERS,        -- {{label: string, minSize: number, maxSize: number, weight: number}}
    BASE_WEIGHTS = BASE_WEIGHTS,    -- {[string]: number}
    rollSize = Sizes.rollSize,      -- () -> (number, string)
    getWeight = Sizes.getWeight,    -- (string, number) -> number
    getLabel = Sizes.getLabel,      -- (number) -> string
}
```

---

### 4.2 `src/server/Services/FoodService.luau` (MODIFY)

**Purpose of change:** After rolling the brainrot name and rarity, roll a random size using `Sizes.rollSize()` instead of hardcoding size = 1.0. Compute the actual weight and apply the size as the earnings multiplier.

**New dependency to add:**

```luau
local Sizes = require(ReplicatedStorage.Shared.Config.Sizes)
```

**Changes to `handleBuyFood` (step 11 in Phase 1 spec):**

Replace the hardcoded BrainrotInstance construction with size-aware logic. The changes are localized to the section after the brainrot config is looked up (after step 10) and before the stay chance roll (step 12).

**Old code (Phase 1):**

```luau
local brainrotInstance = {
    id = Utils.generateId(),
    name = brainrotConfig.name,
    rarity = brainrotConfig.rarity,
    size = 1.0,                         -- Phase 1: no size system
    sizeLabel = "Medium",               -- Phase 1: always Medium
    weight = brainrotConfig.baseWeight,  -- Phase 1: base weight (no size scaling)
    baseMutation = nil,
    weatherMutation = nil,
    personality = nil,
    earningsPerSec = brainrotConfig.baseEarningsPerSec,
}
```

**New code (Phase 3):**

```luau
-- Roll size tier and get a random size value within that tier's range
local size, sizeLabel = Sizes.rollSize()

-- Compute weight based on brainrot's base weight scaled by size
local weight = Sizes.getWeight(brainrotConfig.name, size)

-- Size IS the earnings multiplier
local earningsPerSec = brainrotConfig.baseEarningsPerSec * size

local brainrotInstance = {
    id = Utils.generateId(),
    name = brainrotConfig.name,
    rarity = brainrotConfig.rarity,
    size = size,
    sizeLabel = sizeLabel,
    weight = weight,
    baseMutation = nil,                 -- Phase 4+ (or whenever mutations are added)
    weatherMutation = nil,
    personality = nil,
    earningsPerSec = earningsPerSec,
}
```

**Key behavioral changes:**

1. `Sizes.rollSize()` replaces the hardcoded `size = 1.0` and `sizeLabel = "Medium"`.
2. `Sizes.getWeight(name, size)` replaces the hardcoded `weight = brainrotConfig.baseWeight`.
3. `earningsPerSec` is now `baseEarningsPerSec * size` instead of just `baseEarningsPerSec`.
4. All other steps in `handleBuyFood` remain unchanged.

---

### 4.3 `src/server/Services/EarningsService.luau` (MODIFY)

**Purpose of change:** Ensure that `recalculate()` properly accounts for the size multiplier when summing earnings. In Phase 1, `earningsPerSec` was pre-computed and stored on each BrainrotInstance, so `recalculate()` simply summed `.earningsPerSec` across all brainrots. This behavior does not need to change because FoodService now stores the size-adjusted value in `brainrotInstance.earningsPerSec` at spawn time.

**However**, to be robust and future-proof, `recalculate()` should recompute earnings from source data rather than trusting the stored value. This is important because future phases (mutations, weather, personality) will also modify earnings, and a single recompute function is cleaner than relying on every system to pre-compute correctly.

**New dependency to add:**

```luau
local Brainrots = require(ReplicatedStorage.Shared.Config.Brainrots)
```

(Note: `Config/Sizes` is not needed here because the size value stored on the BrainrotInstance IS the multiplier. No lookup is required.)

**Changes to `recalculate()`:**

**Old code (Phase 1):**

```luau
function EarningsService.recalculate(player: Player)
    local data = DataService.getData(player)
    if not data then
        earningsCache[player] = 0
        return
    end
    local total = 0
    for _, brainrot in data.ownedBrainrots do
        total += brainrot.earningsPerSec
    end
    earningsCache[player] = total
    Remotes.EarningsUpdated:FireClient(player, { earningsPerSec = total })
end
```

**New code (Phase 3):**

```luau
function EarningsService.recalculate(player: Player)
    local data = DataService.getData(player)
    if not data then
        earningsCache[player] = 0
        return
    end
    local total = 0
    for _, brainrot in data.ownedBrainrots do
        -- Recompute earnings from base data: baseEarnings * size
        local brainrotConfig = Brainrots.BRAINROT_BY_NAME[brainrot.name]
        if brainrotConfig then
            local baseEarnings = brainrotConfig.baseEarningsPerSec
            local sizeMultiplier = brainrot.size  -- size IS the multiplier
            local computed = baseEarnings * sizeMultiplier
            -- Update the stored value to stay in sync
            brainrot.earningsPerSec = computed
            total += computed
        else
            -- Fallback: use stored value if config lookup fails
            total += brainrot.earningsPerSec
        end
    end
    earningsCache[player] = total
    Remotes.EarningsUpdated:FireClient(player, { earningsPerSec = total })
end
```

**Key behavioral changes:**

1. Earnings are now recomputed from `baseEarningsPerSec * brainrot.size` rather than trusting the stored `earningsPerSec` value.
2. The stored `brainrot.earningsPerSec` is updated in place to keep the BrainrotInstance consistent (important for the client, which reads this field for display).
3. If a brainrot name is not found in the config (should never happen), falls back to the stored value with a warning.
4. This pattern is future-proof: when base mutations (Phase 4+) and weather mutations (Phase 6) are added, additional multipliers can be inserted into the `computed` calculation.

---

### 4.4 `src/client/Controllers/BaseUI.luau` (MODIFY)

**Purpose of change:** Scale brainrot model Parts by the size value and update the BillboardGui to display size label and weight alongside the existing name and earnings info.

**Changes to `spawnBrainrotVisual()`:**

**Change 1 -- Scale the Part by size:**

**Old code (Phase 1, step 2):**

```luau
-- 2. Set Size to Vector3.new(3, 3, 3) (simple cube placeholder for Phase 1).
part.Size = Vector3.new(3, 3, 3)
```

**New code (Phase 3):**

```luau
-- 2. Scale the Part by the brainrot's size value.
--    Base cube is 3x3x3; multiply by size to get visual scaling.
local basePartSize = 3
local scaledSize = basePartSize * brainrot.size
part.Size = Vector3.new(scaledSize, scaledSize, scaledSize)
```

**Change 2 -- Adjust Y position for scaled Part:**

**Old code (Phase 1, step 4):**

```luau
-- Y = plotPosition.Y + 1.5 (so the cube sits on the surface).
```

**New code (Phase 3):**

```luau
-- Y offset adjusts for scaled Part so it sits on the surface.
local yOffset = (scaledSize / 2) + 0.1
-- Use yOffset instead of hardcoded 1.5
```

**Change 3 -- Update BillboardGui text layout:**

The BillboardGui currently shows two TextLabels: one for the name and one for earnings. Phase 3 changes this to show:

1. **NameLabel** -- `"[SizeLabel] [Rarity] [Name]"` (e.g., "Massive Epic Tralalero Tralala")
2. **InfoLabel** -- `"[Weight] lbs | +$[Earnings]/sec"` (e.g., "342.5 lbs | +$1.3K/sec")

**Old BillboardGui code (Phase 1, steps 6-8):**

```luau
-- TextLabel for name
nameLabel.Text = brainrot.name
nameLabel.TextColor3 = RARITY_COLORS[brainrot.rarity]

-- TextLabel for earnings
earningsLabel.Text = "+$" .. Utils.formatNumber(brainrot.earningsPerSec) .. "/sec"
```

**New BillboardGui code (Phase 3):**

```luau
-- Expand BillboardGui to accommodate 2 lines of richer info
billboard.Size = UDim2.new(0, 300, 0, 70)

-- TextLabel for name with size label and rarity prefix
nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
nameLabel.Text = brainrot.sizeLabel .. " " .. brainrot.rarity .. " " .. brainrot.name
nameLabel.TextColor3 = RARITY_COLORS[brainrot.rarity]
nameLabel.TextScaled = true
nameLabel.Font = Enum.Font.GothamBold
nameLabel.BackgroundTransparency = 1

-- TextLabel for weight and earnings
infoLabel.Size = UDim2.new(1, 0, 0.5, 0)
infoLabel.Position = UDim2.new(0, 0, 0.5, 0)
infoLabel.Text = tostring(brainrot.weight) .. " lbs | +$" .. Utils.formatNumber(brainrot.earningsPerSec) .. "/sec"
infoLabel.TextColor3 = Color3.fromRGB(85, 255, 85)
infoLabel.TextScaled = true
infoLabel.Font = Enum.Font.Gotham
infoLabel.BackgroundTransparency = 1
```

**Display format examples:**

| Size | Rarity | Name | Weight | BillboardGui Line 1 | BillboardGui Line 2 |
|------|--------|------|--------|---------------------|---------------------|
| 0.52 | Common | Burbaloni Lulilolli | 6.2 | Tiny Common Burbaloni Lulilolli | 6.2 lbs | +$2.6/sec |
| 1.05 | Rare | Frigo Camelo | 336.0 | Small Rare Frigo Camelo | 336.0 lbs | +$52.5/sec |
| 1.55 | Epic | Tralalero Tralala | 697.5 | Medium Epic Tralalero Tralala | 697.5 lbs | +$1.9K/sec |
| 2.10 | Legendary | Bombombini Gusini | 73.5 | Large Legendary Bombombini Gusini | 73.5 lbs | +$21.0K/sec |
| 2.87 | Common | Hipocactus | 244.0 | Massive Common Hipocactus | 244.0 lbs | +$14.4/sec |

---

### 4.5 `src/client/Controllers/FoodStoreUI.luau` (MODIFY)

**Purpose of change:** Include size label and weight in the spawn result feedback message shown to the player.

**Changes to `BrainrotSpawned.OnClientEvent` handler:**

**Old code (Phase 1):**

```luau
FeedbackLabel.Text = data.brainrotData.name .. " joined your base!"
```

**New code (Phase 3):**

```luau
local b = data.brainrotData
FeedbackLabel.Text = "You got a " .. b.sizeLabel .. " " .. b.rarity .. " " .. b.name .. "! (" .. tostring(b.weight) .. " lbs)"
```

**Display format examples:**

- `"You got a Tiny Common Burbaloni Lulilolli! (6.2 lbs)"`
- `"You got a Small Rare Frigo Camelo! (336.0 lbs)"`
- `"You got a Large Legendary Bombombini Gusini! (73.5 lbs)"`
- `"You got a Massive Epic Tralalero Tralala! (1293.8 lbs)"`

**Changes to `BrainrotRanAway.OnClientEvent` handler:**

No changes. The run-away message does not include size info because the brainrot was never fully constructed from the player's perspective (it appeared briefly and fled). The existing message format remains:

```luau
FeedbackLabel.Text = data.brainrotName .. " ran away!"
```

---

## 5. Module Contracts

### New Dependencies Added by Phase 3

**FoodService now requires:**

| Module | Function Used | Purpose |
|---|---|---|
| `Config/Sizes` | `Sizes.rollSize()` | Roll a random size tier and value when spawning a brainrot |
| `Config/Sizes` | `Sizes.getWeight(name, size)` | Compute the brainrot's weight at the rolled size |

**EarningsService now requires:**

| Module | Function Used | Purpose |
|---|---|---|
| `Config/Brainrots` | `Brainrots.BRAINROT_BY_NAME[name]` | Look up base earnings per sec for recomputation |

(Note: `EarningsService` reads `brainrot.size` directly from the BrainrotInstance stored in player data. It does not need to require `Config/Sizes`.)

**BaseUI reads from BrainrotInstance:**

| Field | Purpose |
|---|---|
| `brainrot.size` | Scale the 3D Part model |
| `brainrot.sizeLabel` | Display in BillboardGui name line |
| `brainrot.weight` | Display in BillboardGui info line |
| `brainrot.rarity` | Display in BillboardGui name line (already used in Phase 1 for color) |
| `brainrot.earningsPerSec` | Display in BillboardGui info line (already used in Phase 1) |

**FoodStoreUI reads from BrainrotInstance:**

| Field | Purpose |
|---|---|
| `brainrot.sizeLabel` | Include in spawn feedback message |
| `brainrot.rarity` | Include in spawn feedback message |
| `brainrot.name` | Include in spawn feedback message (already used in Phase 1) |
| `brainrot.weight` | Include in spawn feedback message |

### Remote Payload Changes

No new remotes are added in Phase 3. The existing `BrainrotSpawned` remote already carries the full `BrainrotInstance` as its payload, which now naturally includes non-default `size`, `sizeLabel`, and `weight` fields. No payload schema changes required.

---

## 6. Agent Task Breakdown

Tasks are organized into sequential steps. Each step depends on the previous one unless noted otherwise.

### Step 1 -- Create Config/Sizes.luau (pure data, no dependencies)

| Task | Description | Est. Lines |
|---|---|---|
| 1.1 | Create `src/shared/Config/Sizes.luau` with SIZE_TIERS table, BASE_WEIGHTS table, and three functions (`rollSize`, `getWeight`, `getLabel`) | ~120 |

**Verification:** Require the module in a test script. Call `rollSize()` 100 times and verify the distribution roughly matches 20/40/29/10/1. Call `getWeight("Tralalero Tralala", 2.0)` and verify it returns 900.0. Call `getLabel(0.6)` and verify it returns "Tiny".

### Step 2 -- Update FoodService.luau (depends on Sizes)

| Task | Description | Est. Lines Changed |
|---|---|---|
| 2.1 | Add `require` for `Config/Sizes` at the top of the file | ~1 |
| 2.2 | Replace hardcoded size/weight/earnings in `handleBuyFood` step 11 with `Sizes.rollSize()`, `Sizes.getWeight()`, and `baseEarningsPerSec * size` | ~10 |

**Verification:** Buy food multiple times. Verify that brainrots spawn with varying sizes (not all 1.0). Check the server console for the brainrotInstance being constructed with different size/weight values.

### Step 3 -- Update EarningsService.luau (depends on Sizes via brainrot data)

| Task | Description | Est. Lines Changed |
|---|---|---|
| 3.1 | Add `require` for `Config/Brainrots` at the top of the file | ~1 |
| 3.2 | Update `recalculate()` to recompute `earningsPerSec` from `baseEarningsPerSec * brainrot.size` instead of trusting the stored value | ~15 |

**Verification:** Spawn two brainrots of the same rarity at different sizes. Verify that the earnings display shows different $/sec values and that the total earnings per second is the correct sum.

### Step 4 -- Update BaseUI.luau (depends on BrainrotInstance shape)

| Task | Description | Est. Lines Changed |
|---|---|---|
| 4.1 | Scale Part size by `brainrot.size` instead of hardcoded `Vector3.new(3, 3, 3)` | ~5 |
| 4.2 | Adjust Y position offset to account for scaled Part height | ~3 |
| 4.3 | Update BillboardGui to show `"[SizeLabel] [Rarity] [Name]"` on line 1 | ~5 |
| 4.4 | Update BillboardGui to show `"[Weight] lbs | +$[Earnings]/sec"` on line 2 | ~5 |

### Step 5 -- Update FoodStoreUI.luau (depends on BrainrotInstance shape)

| Task | Description | Est. Lines Changed |
|---|---|---|
| 5.1 | Update BrainrotSpawned feedback to include size label, rarity, name, and weight | ~5 |

> **Note:** Steps 4 and 5 are independent of each other and can be done in parallel.

### Task Dependency Diagram

```
Step 1: Create Config/Sizes.luau
    |
    v
Step 2: Update FoodService.luau
    |
    v
Step 3: Update EarningsService.luau
    |
    +-------+-------+
    |               |
    v               v
Step 4:         Step 5:
BaseUI.luau     FoodStoreUI.luau
(parallel)      (parallel)
```

### Total: 1 new file, 4 modified files, ~170 estimated lines of new/changed Luau code.

---

## 7. Data Structures

### 7.1 BrainrotInstance (Phase 3 shape -- updated from Phase 1)

In Phase 3, the `size`, `sizeLabel`, and `weight` fields are no longer hardcoded defaults. They vary per brainrot based on the random size roll at spawn time.

```luau
-- A concrete Phase 3 BrainrotInstance example (Massive Epic brainrot):
{
    id = "f7a3b2c1d4e5f6a7b8c9d0e1f2a3b4c5",
    name = "Tralalero Tralala",
    rarity = "Epic",
    size = 2.87,                 -- Rolled within Massive tier (2.4 - 3.0)
    sizeLabel = "Massive",       -- Determined by size tier
    weight = 1291.5,             -- 450 (baseWeight) * 2.87 (size) = 1291.5 lbs
    baseMutation = nil,          -- Phase 4+ (not yet implemented)
    weatherMutation = nil,       -- Phase 6 (not yet implemented)
    personality = nil,           -- Phase 8 (not yet implemented)
    earningsPerSec = 3587.5,     -- 1250 (baseEarningsPerSec) * 2.87 (size)
}

-- A concrete Phase 3 BrainrotInstance example (Tiny Common brainrot):
{
    id = "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6",
    name = "Bobrito Bandito",
    rarity = "Common",
    size = 0.53,                 -- Rolled within Tiny tier (0.5 - 0.8)
    sizeLabel = "Tiny",          -- Determined by size tier
    weight = 4.2,                -- 8 (baseWeight) * 0.53 (size) = 4.24, rounded to 4.2 lbs
    baseMutation = nil,
    weatherMutation = nil,
    personality = nil,
    earningsPerSec = 2.65,       -- 5 (baseEarningsPerSec) * 0.53 (size)
}
```

### 7.2 Sizes Config Table Shape

```luau
-- Return value of require(Config.Sizes):
{
    SIZE_TIERS = {
        { label = "Tiny",    minSize = 0.5, maxSize = 0.8, weight = 20 },
        { label = "Small",   minSize = 0.8, maxSize = 1.2, weight = 40 },
        { label = "Medium",  minSize = 1.2, maxSize = 1.8, weight = 29 },
        { label = "Large",   minSize = 1.8, maxSize = 2.4, weight = 10 },
        { label = "Massive", minSize = 2.4, maxSize = 3.0, weight = 1  },
    },
    BASE_WEIGHTS = {
        ["Burbaloni Lulilolli"]       = 12,
        ["Hipocactus"]                = 85,
        ["Bobrito Bandito"]           = 8,
        ["Talpa Di Ferro"]            = 45,
        ["Svinino Bombondino"]        = 60,
        ["Frigo Camelo"]              = 320,
        ["Blueberrinni Octopussini"]  = 25,
        ["Orangutini Ananasini"]      = 150,
        ["Tigrrullini Watermellini"]  = 180,
        ["Boneca Ambalabu"]           = 30,
        ["Chef Crabracadabra"]        = 40,
        ["Glorbo Fruttodrillo"]       = 200,
        ["Tralalero Tralala"]         = 450,
        ["Shpioniro Golubiro"]        = 5,
        ["Ballerina Cappuccina"]      = 15,
        ["Bombombini Gusini"]         = 35,
        ["Chimpanzini Bananini"]      = 90,
        ["Brr Brr Patapim"]           = 280,
        ["Cappuccino Assassino"]      = 10,
        ["Lirili Larila"]             = 2500,
        ["Bombardiro Crocodilo"]      = 1800,
        ["Tung Tung Tung Sahur"]      = 120,
        ["Trippi Troppi"]             = 7,
        ["Centralucci Nuclearucci"]   = 50000,
        ["La Vaca Saturno Saturnita"] = 999999,
    },
    rollSize = function,   -- () -> (number, string)
    getWeight = function,  -- (string, number) -> number
    getLabel = function,   -- (number) -> string
}
```

### 7.3 BASE_WEIGHTS Reference Table (all 25 brainrots with example weights at each size tier)

For reference during testing. Actual weight = baseWeight * size. The size values below use the midpoint of each tier's range.

| # | Name | Base (lbs) | Tiny (0.65) | Small (1.0) | Medium (1.5) | Large (2.1) | Massive (2.7) |
|---|---|---|---|---|---|---|---|
| 1 | Burbaloni Lulilolli | 12 | 7.8 | 12.0 | 18.0 | 25.2 | 32.4 |
| 2 | Hipocactus | 85 | 55.3 | 85.0 | 127.5 | 178.5 | 229.5 |
| 3 | Bobrito Bandito | 8 | 5.2 | 8.0 | 12.0 | 16.8 | 21.6 |
| 4 | Talpa Di Ferro | 45 | 29.3 | 45.0 | 67.5 | 94.5 | 121.5 |
| 5 | Svinino Bombondino | 60 | 39.0 | 60.0 | 90.0 | 126.0 | 162.0 |
| 6 | Frigo Camelo | 320 | 208.0 | 320.0 | 480.0 | 672.0 | 864.0 |
| 7 | Blueberrinni Octopussini | 25 | 16.3 | 25.0 | 37.5 | 52.5 | 67.5 |
| 8 | Orangutini Ananasini | 150 | 97.5 | 150.0 | 225.0 | 315.0 | 405.0 |
| 9 | Tigrrullini Watermellini | 180 | 117.0 | 180.0 | 270.0 | 378.0 | 486.0 |
| 10 | Boneca Ambalabu | 30 | 19.5 | 30.0 | 45.0 | 63.0 | 81.0 |
| 11 | Chef Crabracadabra | 40 | 26.0 | 40.0 | 60.0 | 84.0 | 108.0 |
| 12 | Glorbo Fruttodrillo | 200 | 130.0 | 200.0 | 300.0 | 420.0 | 540.0 |
| 13 | Tralalero Tralala | 450 | 292.5 | 450.0 | 675.0 | 945.0 | 1215.0 |
| 14 | Shpioniro Golubiro | 5 | 3.3 | 5.0 | 7.5 | 10.5 | 13.5 |
| 15 | Ballerina Cappuccina | 15 | 9.8 | 15.0 | 22.5 | 31.5 | 40.5 |
| 16 | Bombombini Gusini | 35 | 22.8 | 35.0 | 52.5 | 73.5 | 94.5 |
| 17 | Chimpanzini Bananini | 90 | 58.5 | 90.0 | 135.0 | 189.0 | 243.0 |
| 18 | Brr Brr Patapim | 280 | 182.0 | 280.0 | 420.0 | 588.0 | 756.0 |
| 19 | Cappuccino Assassino | 10 | 6.5 | 10.0 | 15.0 | 21.0 | 27.0 |
| 20 | Lirili Larila | 2500 | 1625.0 | 2500.0 | 3750.0 | 5250.0 | 6750.0 |
| 21 | Bombardiro Crocodilo | 1800 | 1170.0 | 1800.0 | 2700.0 | 3780.0 | 4860.0 |
| 22 | Tung Tung Tung Sahur | 120 | 78.0 | 120.0 | 180.0 | 252.0 | 324.0 |
| 23 | Trippi Troppi | 7 | 4.6 | 7.0 | 10.5 | 14.7 | 18.9 |
| 24 | Centralucci Nuclearucci | 50000 | 32500.0 | 50000.0 | 75000.0 | 105000.0 | 135000.0 |
| 25 | La Vaca Saturno Saturnita | 999999 | 649999.4 | 999999.0 | 1499998.5 | 2099997.9 | 2699997.3 |

---

## 8. Testing Criteria

After all files are written, verify the following step by step. Every step must pass.

### Build Test

1. Run `rojo build -o "collect-brainrots.rbxlx"` from the project root. Verify it succeeds with no errors.

### Size Distribution Test

2. Open the game in Roblox Studio. Buy Common Chow at least 50 times (use a test script or temporarily set money very high).
3. Verify that brainrots spawn with varying sizes -- they should NOT all be 1.0 or the same size.
4. Over 50+ spawns, verify the approximate distribution:
   - Most spawns are Small (~40%) or Tiny (~20%).
   - Medium spawns appear regularly (~29%).
   - Large spawns are uncommon (~10%).
   - Massive spawns are very rare (~1%). It is acceptable to not see any Massive in 50 rolls, but if you roll 200+ times, at least one Massive should appear.

### Visual Scale Test

5. Spawn a Tiny brainrot (size ~0.5-0.8). Verify its 3D Part is noticeably smaller than the base size.
6. Spawn a Large or Massive brainrot (size ~1.8-3.0). Verify its 3D Part is noticeably larger.
7. Verify that the Part sits correctly on the ground surface (not floating, not buried) regardless of size.

### Earnings Variance Test

8. Spawn two brainrots of the same rarity but different sizes (may require multiple attempts). Verify they show different $/sec values in the BillboardGui.
9. Verify that a Massive brainrot earns approximately 6x what a Tiny one does at the same rarity. The ratio of max Massive (3.0) to min Tiny (0.5) is 6:1.
10. Verify the total earnings/sec display (MoneyUI) updates correctly and matches the sum of individual brainrot earnings.

### Weight Display Test

11. Verify the BillboardGui shows weight in lbs (e.g., "342.5 lbs").
12. Verify weight scales correctly: a size-2.0 brainrot should show roughly 2x the base weight for that brainrot.
13. Spot-check a known brainrot: Tralalero Tralala at size 1.0 should show 450.0 lbs; at size 2.0 should show 900.0 lbs.

### BillboardGui Format Test

14. Verify the BillboardGui shows the format: `"[SizeLabel] [Rarity] [Name]"` on the first line.
15. Verify the second line shows: `"[Weight] lbs | +$[Earnings]/sec"`.
16. Example: A Medium Epic Tralalero Tralala at size 1.5 should show:
    - Line 1: "Medium Epic Tralalero Tralala"
    - Line 2: "675.0 lbs | +$1.9K/sec"

### Spawn Feedback Test

17. Verify the FoodStoreUI feedback shows: `"You got a [SizeLabel] [Rarity] [Name]! ([Weight] lbs)"`.
18. Example: `"You got a Large Common Hipocactus! (156.2 lbs)"`

### Persistence Test

19. Spawn a brainrot, note its size and weight. Stop and restart the playtest. Verify the brainrot retains its size, weight, and earnings on rejoin.

### Console Cleanliness Test

20. Check the Studio Output console for any errors (red text). There should be zero errors related to the size system. No warnings except expected placeholder messages from unimplemented systems.

---

## 9. Acceptance Criteria

All of the following must be true before Phase 3 is considered complete:

| # | Criterion | How to Verify |
|---|---|---|
| 1 | `rojo build` succeeds | Run `rojo build -o "collect-brainrots.rbxlx"` -- no errors |
| 2 | `Config/Sizes.luau` exists at `src/shared/Config/Sizes.luau` | Check file tree |
| 3 | `Sizes.rollSize()` returns a size value between 0.5 and 3.0 and a valid label | Call function, verify range and label |
| 4 | `Sizes.getWeight()` returns correct weight for known brainrots | `getWeight("Tralalero Tralala", 2.0)` returns 900.0 |
| 5 | `Sizes.getLabel()` returns correct label for boundary values | `getLabel(0.5)` = "Tiny", `getLabel(1.2)` = "Medium", `getLabel(3.0)` = "Massive" |
| 6 | Brainrots spawn with varying sizes (not all 1.0) | Buy food 10+ times, observe different sizes |
| 7 | Size distribution approximately matches 20/40/29/10/1 weights | Over 100+ spawns, distribution is roughly correct |
| 8 | Visual size of brainrot model scales with the size value | Tiny brainrots visually smaller, Massive brainrots visually larger |
| 9 | Earnings display shows different $/sec for same rarity at different sizes | Compare two brainrots of same rarity |
| 10 | A Massive brainrot earns ~6x what a Tiny one does (3.0/0.5 ratio) | Compare earnings of size 3.0 vs size 0.5 |
| 11 | Weight displays correctly as `baseWeight * size` | Spot-check against BASE_WEIGHTS table |
| 12 | BillboardGui shows `"[SizeLabel] [Rarity] [Name]"` on first line | Visual check |
| 13 | BillboardGui shows `"[Weight] lbs | +$[Earnings]/sec"` on second line | Visual check |
| 14 | FoodStoreUI feedback shows `"You got a [SizeLabel] [Rarity] [Name]! ([Weight] lbs)"` | Visual check after buying food |
| 15 | Size, weight, and earnings persist across sessions | Rejoin and verify saved brainrot data |
| 16 | No errors in Studio Output console | Check for red error text |
| 17 | Size system adds meaningful variance to earnings | Two brainrots of same rarity have noticeably different income |
| 18 | Weight values feel reasonable for each brainrot | Tiny spy pigeon < 5 lbs, Massive Saturn cow > 2 million lbs |
| 19 | All 25 brainrots have entries in BASE_WEIGHTS | Count entries in Config/Sizes.luau |
| 20 | `EarningsService.recalculate()` correctly recomputes earnings from base data * size | Earnings match `baseEarningsPerSec * size` for each brainrot |

---

## Appendix A: Earnings Examples by Size Tier

These examples show how size affects earnings for each rarity tier. The size value shown is the midpoint of each tier's range.

| Rarity | Base $/sec | Tiny (0.65) | Small (1.0) | Medium (1.5) | Large (2.1) | Massive (2.7) |
|--------|-----------|-------------|-------------|--------------|-------------|---------------|
| Common | $5 | $3.25 | $5.00 | $7.50 | $10.50 | $13.50 |
| Rare | $50 | $32.50 | $50.00 | $75.00 | $105.00 | $135.00 |
| Epic | $1,250 | $812.50 | $1,250.00 | $1,875.00 | $2,625.00 | $3,375.00 |
| Legendary | $10,000 | $6,500.00 | $10,000.00 | $15,000.00 | $21,000.00 | $27,000.00 |
| Mythic | $100,000 | $65,000.00 | $100,000.00 | $150,000.00 | $210,000.00 | $270,000.00 |
| Goldy | $750,000 | $487,500.00 | $750,000.00 | $1,125,000.00 | $1,575,000.00 | $2,025,000.00 |
| Secret | $5,000,000 | $3,250,000.00 | $5,000,000.00 | $7,500,000.00 | $10,500,000.00 | $13,500,000.00 |
| Unknown | $50,000,000 | $32,500,000.00 | $50,000,000.00 | $75,000,000.00 | $105,000,000.00 | $135,000,000.00 |

**Extreme cases:**

- Worst possible: Tiny Common at size 0.50 = $5 * 0.50 = **$2.50/sec**
- Best possible: Massive Unknown at size 3.00 = $50,000,000 * 3.00 = **$150,000,000/sec**

## Appendix B: Relationship to GAME_DESIGN.md Size Tiers

The GAME_DESIGN.md (Section 4) defines size tiers with fixed multipliers (Tiny = 0.5x, Small = 0.75x, Medium = 1.0x, Large = 1.75x, Massive = 3.0x) and fixed visual scales. Phase 3 extends this into a **continuous range** system where each tier defines a min/max size and the actual size is a uniform random value within that range.

**Key differences from GAME_DESIGN.md's original design:**

| Aspect | GAME_DESIGN.md (original) | Phase 3 (implementation) |
|--------|--------------------------|--------------------------|
| Size values | Fixed per tier (0.5, 0.75, 1.0, 1.75, 3.0) | Continuous range per tier (e.g., Tiny = 0.5-0.8) |
| Earnings multiplier | Separate lookup per tier | Size value IS the multiplier directly |
| Weight formula | Separate weight modifiers per tier (0.4, 0.7, 1.0, 1.5, 2.5) | Simple formula: baseWeight * size |
| Visual scale | Fixed percentages per tier (60%, 80%, 100%, 130%, 175%) | Proportional to size value |

The continuous range approach provides more variety (no two brainrots are exactly the same size) while maintaining the same overall feel and rarity distribution. The spawn chance weights (20/40/29/10/1) match the GAME_DESIGN.md exactly.

---

*End of Phase 3 Size System specification.*
