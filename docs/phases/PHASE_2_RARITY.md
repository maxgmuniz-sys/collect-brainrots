# Phase 2: Full Rarity and Food System

> **Status:** NOT STARTED
> **Depends on:** Phase 1 (MVP Core Loop complete and tested)
> **Estimated scope:** 4 files modified, 0 new files

---

## 1. Objective

Unlock all 8 food tiers and all 25 brainrots. Implement rarity-weighted spawning so higher-tier food has a better chance of attracting rarer brainrots. Balance food costs so progression feels right -- players should feel each tier is a meaningful milestone that requires real time investment. Add rarity-colored brainrot models with BillboardGui labels that display the rarity name in the corresponding rarity color.

**Phase 2 scope:**

- All 8 food tiers purchasable (remove the Phase 1 `ALLOWED_FOODS_PHASE1` gate).
- All 25 brainrots rollable through the rarity-weighted food system.
- Each food tier has a `rarityWeights` table that controls the probability distribution of rolled rarities.
- Food costs are balanced around expected earnings rates and time-to-afford.
- Brainrot visuals (Parts and BillboardGui) are color-coded by rarity.
- BillboardGui shows rarity name alongside brainrot name in the matching rarity color.

**Phase 2 does NOT include:**

- Size system (all brainrots still spawn at size 1.0, label "Medium").
- Base mutations (all brainrots still spawn with `baseMutation = nil`).
- Weather mutations, weather events.
- Personality system.
- Sell system, fusion, gifting, leaderboards, index/codex.
- Base capacity upgrades (button remains non-functional).
- 3D brainrot meshes (still using cube Parts as placeholders).

---

## 2. Prerequisites

Phase 1 must be fully complete and tested before starting Phase 2. Specifically:

- All 14 Phase 1 files exist at their correct paths.
- `rojo build` succeeds with no errors.
- The core loop works end-to-end: buy Common Chow, brainrot rolls, stay/run-away, passive income.
- DataService persistence works (ProfileStore loads/saves).
- All 8 Phase 1 testing criteria pass.
- All 20 Phase 1 acceptance criteria pass.
- No errors in the Studio Output console.

---

## 3. Files to Create/Modify

No new files are created in Phase 2. All changes are modifications to existing Phase 1 files.

### Files to Modify (4 files)

| # | File Path | Change Summary |
|---|---|---|
| 1 | `src/shared/Config/Foods.luau` | Replace placeholder costs with balanced values. Add `rarityWeights` field to each food tier entry with real probability distributions. |
| 2 | `src/server/Services/FoodService.luau` | Remove `ALLOWED_FOODS_PHASE1` restriction. Implement full rarity-weighted rolling using each food tier's `rarityWeights` table instead of the global `RARITY_WEIGHTS` lookup. |
| 3 | `src/client/Controllers/FoodStoreUI.luau` | Replace single "Buy Common Chow" button with a scrolling frame showing all 8 food tiers. Each tier shows name, cost, max rarity info, and a buy button. Gray out tiers the player cannot afford. Show "Base Full" message when base is at capacity. |
| 4 | `src/client/Controllers/BaseUI.luau` | Color-code brainrot Part models by rarity. Update BillboardGui to display `"[Rarity] BrainrotName"` in the rarity's assigned color. Use updated rarity color palette. |

---

## 4. Detailed Spec Per File

---

### 4.1 `src/shared/Config/Foods.luau` Changes

**What changes:**

1. Each food tier entry gains a new field: `rarityWeights`, a dictionary keyed by rarity string with numeric weight values. This replaces the global `RARITY_WEIGHTS` table.
2. Food costs are updated from placeholder values to balanced values based on earnings-rate analysis.
3. The global `RARITY_WEIGHTS` table is **removed** (its data is now embedded in each food entry's `rarityWeights` field).

**Updated food tier data shape:**

```luau
{
    name: string,              -- Display name, e.g. "Common Chow"
    cost: number,              -- Price in in-game money (balanced)
    maxRarity: string,         -- Highest rarity this food can attract
    stayChance: number,        -- Probability (0.0 to 1.0) that an attracted brainrot stays
    rarityWeights: {[string]: number},  -- NEW: probability weights per rarity
}
```

**Rarity weight tables per food tier:**

These weights define the probability distribution when rolling a rarity after purchasing a food tier. The weights are relative (not percentages) and are used with `Utils.weightedRandom()`.

| Food Tier | Common | Rare | Epic | Legendary | Mythic | Goldy | Secret | Unknown |
|---|---|---|---|---|---|---|---|---|
| Common Chow | 90 | 10 | - | - | - | - | - | - |
| Rare Rations | 60 | 30 | 10 | - | - | - | - | - |
| Epic Eats | 30 | 35 | 25 | 10 | - | - | - | - |
| Legendary Feast | 15 | 25 | 30 | 20 | 10 | - | - | - |
| Mythic Meal | - | 20 | 25 | 25 | 20 | 10 | - | - |
| Goldy Grub | - | - | 15 | 25 | 25 | 25 | 10 | - |
| Secret Snack | - | - | - | 15 | 25 | 25 | 25 | 10 |
| Unknown Elixir | - | - | - | - | 15 | 20 | 25 | 40 |

Dashes indicate that rarity is not in the food tier's attraction pool (weight of 0, omitted from the table).

**Design rationale for rarity weights:**

- Each food tier's weight table is concentrated around its "target" rarity with a tail toward adjacent rarities.
- Common Chow still mostly gives commons (90%) with a 10% rare chance -- identical to Phase 1.
- Rare Rations shifts the center toward Rare, with Commons still possible as the majority.
- As tiers increase, the lowest rarities drop out entirely. Mythic Meal cannot roll Common or Rare -- the floor is Epic.
- Unknown Elixir has a 40% chance at Unknown (the highest weight in any tier for its target rarity), making it the most efficient path to the rarest brainrots.
- The progressive floor-raising means expensive food never feels "wasted" on low-rarity rolls.

**Balanced food costs:**

The costs are designed around the earnings curve. The key metric is **time-to-afford**: how long a player earning at the previous tier's rate needs to accumulate enough money to buy the next tier's food.

Earnings rate assumptions (approximate, based on brainrots at each tier with base capacity of 1):

| Tier | Typical Brainrot Earnings | Assumed Base $/sec |
|---|---|---|
| Common | $5/sec | $5 |
| Rare | $50/sec | $50 |
| Epic | $1,250/sec | $1,250 |
| Legendary | $10,000/sec | $10,000 |
| Mythic | $100,000/sec | $100,000 |
| Goldy | $750,000/sec | $750,000 |
| Secret | $5,000,000/sec | $5,000,000 |
| Unknown | $50,000,000/sec | $50,000,000 |

Target time-to-afford for each food tier (buying one unit):

| Food Tier | Cost | Earned By | Time to Afford | Notes |
|---|---|---|---|---|
| Common Chow | $50 | Starting money ($100) | Immediate | Players start with $100, enough for 2 buys. |
| Rare Rations | $500 | 1 Common brainrot ($5/sec) | ~100 sec (~1.7 min) | Quick first upgrade. Feels rewarding. |
| Epic Eats | $7,500 | 1 Rare brainrot ($50/sec) | ~150 sec (~2.5 min) | Slightly longer grind. Player is engaged. |
| Legendary Feast | $100,000 | 1 Epic brainrot ($1,250/sec) | ~80 sec (~1.3 min) | Faster relative to income -- rewards rarity jump. |
| Mythic Meal | $1,500,000 | 1 Legendary brainrot ($10,000/sec) | ~150 sec (~2.5 min) | Moderate grind. High anticipation. |
| Goldy Grub | $20,000,000 | 1 Mythic brainrot ($100,000/sec) | ~200 sec (~3.3 min) | The grind lengthens. Patience required. |
| Secret Snack | $300,000,000 | 1 Goldy brainrot ($750,000/sec) | ~400 sec (~6.7 min) | Meaningful wait. Late-game feel. |
| Unknown Elixir | $5,000,000,000 | 1 Secret brainrot ($5,000,000/sec) | ~1000 sec (~16.7 min) | Endgame grind. Requires serious time investment. |

These times assume the player has exactly one brainrot of the previous tier. In practice, players may have multiple brainrots or lower-tier ones contributing, which shortens the effective wait. The times also assume continuous play (idle accumulation).

> **Note:** These costs should be tuned during playtesting. The values above are the initial proposal. If progression feels too fast, multiply higher-tier costs by 1.5-2x. If too slow, reduce by 0.5-0.75x.

**Complete updated food data:**

```luau
local FOODS = {
    {
        name = "Common Chow",
        cost = 50,
        maxRarity = "Rare",
        stayChance = 0.60,
        rarityWeights = { Common = 90, Rare = 10 },
    },
    {
        name = "Rare Rations",
        cost = 500,
        maxRarity = "Epic",
        stayChance = 0.55,
        rarityWeights = { Common = 60, Rare = 30, Epic = 10 },
    },
    {
        name = "Epic Eats",
        cost = 7500,
        maxRarity = "Legendary",
        stayChance = 0.45,
        rarityWeights = { Common = 30, Rare = 35, Epic = 25, Legendary = 10 },
    },
    {
        name = "Legendary Feast",
        cost = 100000,
        maxRarity = "Mythic",
        stayChance = 0.35,
        rarityWeights = { Common = 15, Rare = 25, Epic = 30, Legendary = 20, Mythic = 10 },
    },
    {
        name = "Mythic Meal",
        cost = 1500000,
        maxRarity = "Goldy",
        stayChance = 0.28,
        rarityWeights = { Rare = 20, Epic = 25, Legendary = 25, Mythic = 20, Goldy = 10 },
    },
    {
        name = "Goldy Grub",
        cost = 20000000,
        maxRarity = "Secret",
        stayChance = 0.22,
        rarityWeights = { Epic = 15, Legendary = 25, Mythic = 25, Goldy = 25, Secret = 10 },
    },
    {
        name = "Secret Snack",
        cost = 300000000,
        maxRarity = "Unknown",
        stayChance = 0.18,
        rarityWeights = { Legendary = 15, Mythic = 25, Goldy = 25, Secret = 25, Unknown = 10 },
    },
    {
        name = "Unknown Elixir",
        cost = 5000000000,
        maxRarity = "Unknown",
        stayChance = 0.15,
        rarityWeights = { Mythic = 15, Goldy = 20, Secret = 25, Unknown = 40 },
    },
}
```

**What to remove:**

Delete the global `RARITY_WEIGHTS` table that was defined in Phase 1. It is now redundant because each food entry carries its own `rarityWeights`.

**Updated module return structure:**

```luau
return {
    FOODS = FOODS,                     -- {FoodConfig} ordered array
    FOOD_BY_NAME = FOOD_BY_NAME,       -- {[string]: FoodConfig}
    RARITY_ORDER = RARITY_ORDER,       -- {string} ordered array (unchanged)
    -- RARITY_WEIGHTS removed (data is now per-food-entry)
}
```

**FoodTier type update (in Types.luau):**

While Types.luau is not listed as a file to modify (it does not require code changes since Luau types are structural), the conceptual type shape for FoodTier now includes `rarityWeights`:

```luau
export type FoodTier = {
    name: string,
    cost: number,
    maxRarity: string,
    stayChance: number,
    rarityWeights: {[string]: number},  -- NEW
}
```

This does not require a code change since Luau types are duck-typed, but agents should be aware of the expanded shape.

---

### 4.2 `src/server/Services/FoodService.luau` Changes

**What changes:**

1. Remove the `ALLOWED_FOODS_PHASE1` constant and the Phase 1 gate check in `handleBuyFood`.
2. Change the rarity rolling logic to read `rarityWeights` directly from the food tier entry instead of looking up the global `RARITY_WEIGHTS` table.

**Detailed changes:**

**Step 1: Remove the Phase 1 gate.**

Delete this constant:

```luau
-- DELETE THIS:
local ALLOWED_FOODS_PHASE1 = { ["Common Chow"] = true }
```

Delete this check from `handleBuyFood`:

```luau
-- DELETE THIS:
-- 4. Phase 1 gate: Check ALLOWED_FOODS_PHASE1[data.foodTier]. If not true, warn and return.
if not ALLOWED_FOODS_PHASE1[data.foodTier] then
    warn("[FoodService] Food tier not available in Phase 1: " .. tostring(data.foodTier))
    return
end
```

**Step 2: Update rarity rolling to use per-food rarityWeights.**

Replace the rarity roll step in `handleBuyFood`. The old code looks up `Foods.RARITY_WEIGHTS[data.foodTier]`. The new code reads `food.rarityWeights` directly from the food entry:

```luau
-- OLD (Phase 1):
-- local rarityWeights = Foods.RARITY_WEIGHTS[data.foodTier]

-- NEW (Phase 2):
local rarityWeights = food.rarityWeights
```

The rest of the rarity rolling logic remains identical:

```luau
local rolledRarity = Utils.weightedRandom(rarityWeights)
local rarityPool = Brainrots.BRAINROTS_BY_RARITY[rolledRarity]
local rolledName = rarityPool[math.random(1, #rarityPool)]
local brainrotConfig = Brainrots.BRAINROT_BY_NAME[rolledName]
```

**Step 3: Verify stay chance source.**

Confirm that the stay chance is already read from `food.stayChance` (not from the brainrot rarity). This should already be the case from Phase 1:

```luau
local stayRoll = math.random()
if stayRoll <= food.stayChance then
    -- brainrot stays
else
    -- brainrot runs away
end
```

No change needed here -- just verify it is correct.

**Updated handleBuyFood flow (complete):**

```luau
local function handleBuyFood(player: Player, data: {[string]: any})
    -- 1. Validate player data
    local playerData = DataService.getData(player)
    if not playerData then
        warn("[FoodService] No data for player: " .. player.Name)
        return
    end

    -- 2. Validate food tier name
    local foodTierName = data.foodTier
    if type(foodTierName) ~= "string" then
        warn("[FoodService] Invalid food tier type")
        return
    end

    -- 3. Validate food tier exists
    local food = Foods.FOOD_BY_NAME[foodTierName]
    if not food then
        warn("[FoodService] Unknown food tier: " .. foodTierName)
        return
    end

    -- 4. (Phase 1 gate REMOVED in Phase 2)

    -- 5. Validate money
    if playerData.money < food.cost then
        warn("[FoodService] Not enough money for " .. foodTierName)
        return
    end

    -- 6. Validate capacity
    if not BaseService.canAddBrainrot(player) then
        warn("[FoodService] Base is full for " .. player.Name)
        return
    end

    -- 7. Deduct money
    if not DataService.subtractMoney(player, food.cost) then
        warn("[FoodService] Failed to deduct money")
        return
    end

    -- 8. Roll rarity using the food tier's own rarityWeights
    local rarityWeights = food.rarityWeights
    local rolledRarity = Utils.weightedRandom(rarityWeights)

    -- 9. Roll brainrot from the rolled rarity
    local rarityPool = Brainrots.BRAINROTS_BY_RARITY[rolledRarity]
    local rolledName = rarityPool[math.random(1, #rarityPool)]

    -- 10. Get brainrot config
    local brainrotConfig = Brainrots.BRAINROT_BY_NAME[rolledName]

    -- 11. Construct BrainrotInstance
    local brainrotInstance = {
        id = Utils.generateId(),
        name = brainrotConfig.name,
        rarity = brainrotConfig.rarity,
        size = 1.0,
        sizeLabel = "Medium",
        weight = brainrotConfig.baseWeight,
        baseMutation = nil,
        weatherMutation = nil,
        personality = nil,
        earningsPerSec = brainrotConfig.baseEarningsPerSec,
    }

    -- 12. Roll stay chance (from food tier, not brainrot rarity)
    local stayRoll = math.random()
    if stayRoll <= food.stayChance then
        -- 13. Brainrot stays
        table.insert(playerData.ownedBrainrots, brainrotInstance)
        EarningsService.recalculate(player)
        Remotes.BrainrotSpawned:FireClient(player, { brainrotData = brainrotInstance })
        local current, max = BaseService.getCapacity(player)
        Remotes.CapacityUpdated:FireClient(player, { current = current, max = max })
    else
        -- 14. Brainrot runs away
        Remotes.BrainrotRanAway:FireClient(player, {
            brainrotName = brainrotInstance.name,
            rarity = brainrotInstance.rarity,
        })
    end
end
```

---

### 4.3 `src/client/Controllers/FoodStoreUI.luau` Changes

**What changes:**

1. Replace the single "Buy Common Chow" button with a scrolling frame listing all 8 food tiers.
2. Each food tier row displays: food name, cost (formatted), "Attracts up to: [maxRarity]", and a buy button.
3. Buy buttons are grayed out and disabled when the player cannot afford the food.
4. All buy buttons are grayed out with a "Base Full" overlay message when the player's base is at capacity.
5. Listen for `MoneyUpdated` and `CapacityUpdated` to dynamically update button states.

**Dependencies (new):**

- `src/shared/Config/Foods` (for `FOODS` array -- all 8 tier entries)
- `src/shared/Utils` (for `formatNumber`)

**UI Layout (complete replacement of Phase 1 layout):**

```
ScreenGui "FoodStoreGui"
  Frame "StoreFrame"
    Position: UDim2.new(0.5, 0, 1, -20)
    AnchorPoint: Vector2.new(0.5, 1)
    Size: UDim2.new(0, 320, 0, 360)
    BackgroundColor3: Color3.fromRGB(30, 30, 40)
    BackgroundTransparency: 0.15
    -- Add UICorner with CornerRadius 16

    TextLabel "StoreTitle"
      Position: UDim2.new(0.5, 0, 0, 8)
      AnchorPoint: Vector2.new(0.5, 0)
      Size: UDim2.new(1, -20, 0, 30)
      Text: "Food Store"
      TextColor3: Color3.fromRGB(255, 255, 255)
      TextScaled: true
      Font: Enum.Font.GothamBold
      BackgroundTransparency: 1

    ScrollingFrame "FoodList"
      Position: UDim2.new(0, 10, 0, 45)
      Size: UDim2.new(1, -20, 1, -55)
      BackgroundTransparency: 1
      ScrollBarThickness: 6
      CanvasSize: UDim2.new(0, 0, 0, 0)  -- auto-set based on content
      -- Add UIListLayout (Vertical, Padding 8)
      -- Add UIPadding (4px all sides)

      -- FOR EACH FOOD TIER (generated programmatically):
      Frame "FoodRow_[index]"
        Size: UDim2.new(1, 0, 0, 72)
        BackgroundColor3: Color3.fromRGB(45, 45, 60)
        -- Add UICorner with CornerRadius 10

        TextLabel "FoodName"
          Position: UDim2.new(0, 12, 0, 6)
          Size: UDim2.new(0.55, 0, 0, 22)
          Text: "[Food Name]"
          TextColor3: Color3.fromRGB(255, 255, 255)
          Font: Enum.Font.GothamBold
          TextScaled: true
          TextXAlignment: Enum.TextXAlignment.Left
          BackgroundTransparency: 1

        TextLabel "FoodInfo"
          Position: UDim2.new(0, 12, 0, 28)
          Size: UDim2.new(0.55, 0, 0, 18)
          Text: "Attracts up to: [maxRarity]"
          TextColor3: Color3.fromRGB(170, 170, 190)
          Font: Enum.Font.Gotham
          TextScaled: true
          TextXAlignment: Enum.TextXAlignment.Left
          BackgroundTransparency: 1

        TextLabel "FoodCost"
          Position: UDim2.new(0, 12, 0, 48)
          Size: UDim2.new(0.55, 0, 0, 18)
          Text: "$[formatted cost]"
          TextColor3: Color3.fromRGB(85, 255, 85)
          Font: Enum.Font.Gotham
          TextScaled: true
          TextXAlignment: Enum.TextXAlignment.Left
          BackgroundTransparency: 1

        TextButton "BuyButton"
          Position: UDim2.new(1, -12, 0.5, 0)
          AnchorPoint: Vector2.new(1, 0.5)
          Size: UDim2.new(0, 80, 0, 40)
          Text: "Buy"
          TextColor3: Color3.fromRGB(255, 255, 255)
          Font: Enum.Font.GothamBold
          TextScaled: true
          BackgroundColor3: Color3.fromRGB(46, 204, 113)  -- green when affordable
          -- Add UICorner with CornerRadius 8
          -- When not affordable: BackgroundColor3 = Color3.fromRGB(100, 100, 100), Active = false

    TextLabel "BaseFullLabel"
      Position: UDim2.new(0.5, 0, 0.5, 0)
      AnchorPoint: Vector2.new(0.5, 0.5)
      Size: UDim2.new(0.8, 0, 0, 40)
      Text: "Base Full!"
      TextColor3: Color3.fromRGB(255, 85, 85)
      Font: Enum.Font.GothamBold
      TextScaled: true
      BackgroundColor3: Color3.fromRGB(40, 40, 40)
      BackgroundTransparency: 0.3
      Visible: false  -- shown only when base is at capacity
      -- Add UICorner with CornerRadius 8

  TextLabel "FeedbackLabel"
    Position: UDim2.new(0.5, 0, 1, -390)
    AnchorPoint: Vector2.new(0.5, 1)
    Size: UDim2.new(0, 400, 0, 40)
    Text: ""
    TextColor3: Color3.fromRGB(255, 255, 255)
    TextScaled: true
    Font: Enum.Font.GothamBold
    BackgroundTransparency: 1
    TextTransparency: 1  -- starts invisible
```

**Internal state:**

```luau
local currentMoney = 0           -- updated via MoneyUpdated and InitialData
local isBaseFull = false          -- updated via CapacityUpdated and InitialData
local buyButtons = {}            -- {[string]: TextButton} maps food name to its buy button
local foodRows = {}              -- {[string]: Frame} maps food name to its row frame
```

**Updated Init() step-by-step:**

1. Get `player` from `Players.LocalPlayer`.
2. Wait for `ReplicatedStorage:WaitForChild("Remotes")`.
3. Get references to `BuyFood`, `BrainrotSpawned`, `BrainrotRanAway`, `MoneyUpdated`, `CapacityUpdated`, `InitialData` remotes.
4. Require `Config/Foods` for `FOODS` array.
5. Require `Utils` for `formatNumber`.
6. Build the UI hierarchy described above.
7. For each food tier in `Foods.FOODS`:
   a. Create a `FoodRow` frame with the food's name, cost, max rarity info, and buy button.
   b. Store references in `buyButtons[food.name]` and `foodRows[food.name]`.
   c. Connect `BuyButton.Activated`:
      - Fire `BuyFood:FireServer({ foodTier = food.name })`.
8. Define `updateButtonStates()` function:
   a. For each food in `Foods.FOODS`:
      - If `isBaseFull`:
        - Set button `BackgroundColor3` to gray `Color3.fromRGB(100, 100, 100)`.
        - Set button `Active` to false.
        - Show `BaseFullLabel`.
      - Else if `currentMoney < food.cost`:
        - Set button `BackgroundColor3` to gray `Color3.fromRGB(100, 100, 100)`.
        - Set button `Active` to false.
      - Else:
        - Set button `BackgroundColor3` to green `Color3.fromRGB(46, 204, 113)`.
        - Set button `Active` to true.
   b. If not `isBaseFull`, hide `BaseFullLabel`.
9. Connect `InitialData.OnClientEvent`:
   a. Set `currentMoney = data.money`.
   b. Set `isBaseFull = (data.capacity.current >= data.capacity.max)`.
   c. Call `updateButtonStates()`.
10. Connect `MoneyUpdated.OnClientEvent`:
    a. Set `currentMoney = data.money`.
    b. Call `updateButtonStates()`.
11. Connect `CapacityUpdated.OnClientEvent`:
    a. Set `isBaseFull = (data.current >= data.max)`.
    b. Call `updateButtonStates()`.
12. Connect `BrainrotSpawned.OnClientEvent`:
    a. Set `FeedbackLabel.Text` to the brainrot name .. `" joined your base!"`.
    b. Set `FeedbackLabel.TextColor3` to green `Color3.fromRGB(85, 255, 85)`.
    c. Set `FeedbackLabel.TextTransparency` to 0.
    d. `task.delay(3, function() FeedbackLabel.TextTransparency = 1 end)`.
13. Connect `BrainrotRanAway.OnClientEvent`:
    a. Set `FeedbackLabel.Text` to the brainrot name .. `" ran away!"`.
    b. Set `FeedbackLabel.TextColor3` to red `Color3.fromRGB(255, 85, 85)`.
    c. Set `FeedbackLabel.TextTransparency` to 0.
    d. `task.delay(3, function() FeedbackLabel.TextTransparency = 1 end)`.

**ScrollingFrame auto-sizing:**

After creating all food rows, set the ScrollingFrame's `CanvasSize` based on the UIListLayout's `AbsoluteContentSize`:

```luau
local listLayout = -- reference to UIListLayout
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    foodList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end)
```

---

### 4.4 `src/client/Controllers/BaseUI.luau` Changes

**What changes:**

1. Update the `RARITY_COLORS` constant to use the new color palette specified for Phase 2.
2. Modify `spawnBrainrotVisual()` so the BillboardGui displays `"[Rarity] BrainrotName"` instead of just the brainrot name.
3. Color the Part model to match the rarity color.
4. Add special handling for the Secret rarity (black background with white text in the BillboardGui).

**Updated RARITY_COLORS constant:**

```luau
local RARITY_COLORS = {
    Common    = Color3.fromRGB(170, 170, 170),    -- #AAAAAA - Gray
    Rare      = Color3.fromRGB(85, 170, 255),     -- #55AAFF - Blue
    Epic      = Color3.fromRGB(170, 85, 255),     -- #AA55FF - Purple
    Legendary = Color3.fromRGB(255, 170, 0),      -- #FFAA00 - Orange
    Mythic    = Color3.fromRGB(255, 85, 85),      -- #FF5555 - Red
    Goldy     = Color3.fromRGB(255, 215, 0),      -- #FFD700 - Gold
    Secret    = Color3.fromRGB(0, 0, 0),          -- #000000 - Black
    Unknown   = Color3.fromRGB(255, 0, 255),      -- #FF00FF - Magenta/Void
}
```

**Comparison with Phase 1 colors:**

| Rarity | Phase 1 RGB | Phase 2 RGB | Change Reason |
|---|---|---|---|
| Common | 255, 255, 255 (white) | 170, 170, 170 (gray) | White was too bright, gray reads better as "common" |
| Rare | 52, 152, 219 | 85, 170, 255 | Brighter blue for better contrast |
| Epic | 155, 89, 182 | 170, 85, 255 | Shifted more purple, higher saturation |
| Legendary | 230, 126, 34 | 255, 170, 0 | More vivid orange-gold |
| Mythic | 231, 76, 60 | 255, 85, 85 | Cleaner red |
| Goldy | 241, 196, 15 | 255, 215, 0 | Standard gold (#FFD700) |
| Secret | 26, 188, 156 (teal) | 0, 0, 0 (black) | Black feels more "secret"/hidden |
| Unknown | 44, 62, 80 (dark gray) | 255, 0, 255 (magenta) | Void/alien feel, much more visible |

**Updated spawnBrainrotVisual() function:**

```luau
local function spawnBrainrotVisual(brainrot: Types.BrainrotInstance)
    -- 1. Create Part
    local part = Instance.new("Part")
    part.Anchored = true
    part.CanCollide = false
    part.Size = Vector3.new(3, 3, 3)

    -- 2. Color the Part by rarity
    local rarityColor = RARITY_COLORS[brainrot.rarity] or Color3.fromRGB(170, 170, 170)
    part.Color = rarityColor

    -- 3. Position with random offset
    local xOffset = math.random(-5, 5)
    local zOffset = math.random(-5, 5)
    part.Position = Vector3.new(
        plotPosition.X + xOffset,
        plotPosition.Y + 1.5,
        plotPosition.Z + zOffset
    )

    -- 4. Create BillboardGui
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 220, 0, 80)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = part

    -- 5. Rarity label (NEW in Phase 2)
    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Size = UDim2.new(1, 0, 0, 20)
    rarityLabel.Position = UDim2.new(0, 0, 0, 0)
    rarityLabel.Text = brainrot.rarity
    rarityLabel.Font = Enum.Font.GothamBold
    rarityLabel.TextScaled = true
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.Parent = billboard

    -- Special handling for Secret rarity: white text (since color is black)
    if brainrot.rarity == "Secret" then
        rarityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        rarityLabel.TextColor3 = rarityColor
    end

    -- 6. Name label (updated position)
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 25)
    nameLabel.Position = UDim2.new(0, 0, 0, 20)
    nameLabel.Text = brainrot.name
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextScaled = true
    nameLabel.BackgroundTransparency = 1
    nameLabel.Parent = billboard

    -- Name label also uses rarity color (with Secret exception)
    if brainrot.rarity == "Secret" then
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        nameLabel.TextColor3 = rarityColor
    end

    -- 7. Earnings label (shifted down)
    local earningsLabel = Instance.new("TextLabel")
    earningsLabel.Size = UDim2.new(1, 0, 0, 20)
    earningsLabel.Position = UDim2.new(0, 0, 0, 45)
    earningsLabel.Text = "+$" .. Utils.formatNumber(brainrot.earningsPerSec) .. "/sec"
    earningsLabel.TextColor3 = Color3.fromRGB(85, 255, 85)
    earningsLabel.Font = Enum.Font.Gotham
    earningsLabel.TextScaled = true
    earningsLabel.BackgroundTransparency = 1
    earningsLabel.Parent = billboard

    -- 8. Parent to Workspace
    part.Parent = workspace

    -- 9. Store reference
    brainrotParts[brainrot.id] = part
end
```

**Key differences from Phase 1:**

| Aspect | Phase 1 | Phase 2 |
|---|---|---|
| BillboardGui content | Name only + earnings | Rarity label + Name + earnings (3 lines) |
| BillboardGui size | 200x60 | 220x80 (taller for 3 lines) |
| Text color | Rarity color for name | Rarity color for both rarity label and name |
| Secret rarity handling | N/A (secrets unreachable) | Black Part, white text labels |
| Part color | Rarity color | Rarity color (same, but new palette) |

---

## 5. Module Contracts

Phase 2 does not introduce any new module dependencies. All existing contracts from Phase 1 remain intact.

**Changes to existing contracts:**

| Contract | Change |
|---|---|
| FoodService reads `Foods.RARITY_WEIGHTS[foodTierName]` | **Replaced with** `food.rarityWeights` (read from the food entry directly) |
| FoodStoreUI reads `Config/Foods` for cost display | **Expanded:** now reads `FOODS` array (all 8 tiers) instead of just the name/cost of Common Chow |
| FoodStoreUI listens for `MoneyUpdated` | **New listener** (Phase 1 FoodStoreUI did not listen for money updates) |
| FoodStoreUI listens for `CapacityUpdated` | **New listener** (Phase 1 FoodStoreUI did not listen for capacity updates) |

**Unchanged contracts:**

- FoodService still calls DataService.getData(), DataService.subtractMoney(), BaseService.canAddBrainrot(), BaseService.getCapacity(), EarningsService.recalculate().
- FoodService still fires BrainrotSpawned, BrainrotRanAway, CapacityUpdated remotes.
- BaseUI still listens for BrainrotSpawned, CapacityUpdated, InitialData.
- MoneyUI is completely unchanged.
- EarningsService is completely unchanged.
- DataService is completely unchanged.
- BaseService is completely unchanged.
- Remotes/init is completely unchanged (no new remotes needed).

---

## 6. Agent Task Breakdown

Tasks are organized into batches. All tasks within a batch can be done in parallel. Batches must be completed in order.

### Batch 1 -- Config and UI (independent changes)

These two files have no dependencies on each other and can be modified simultaneously.

| Task | File | Change Summary | Est. Lines Changed |
|---|---|---|---|
| 1.1 | `src/shared/Config/Foods.luau` | Update costs, add `rarityWeights` to each food entry, remove global `RARITY_WEIGHTS` | ~40 lines modified |
| 1.2 | `src/client/Controllers/FoodStoreUI.luau` | Replace single button with scrolling frame, show all 8 tiers, implement affordability/capacity gating | ~150 lines rewritten |

### Batch 2 -- Server Logic (depends on Foods.luau changes)

| Task | File | Change Summary | Est. Lines Changed |
|---|---|---|---|
| 2.1 | `src/server/Services/FoodService.luau` | Remove Phase 1 gate, read `food.rarityWeights` instead of `RARITY_WEIGHTS` | ~10 lines removed/modified |

### Batch 3 -- Client Visuals (independent of Batches 1 and 2, but listed last for clarity)

| Task | File | Change Summary | Est. Lines Changed |
|---|---|---|---|
| 3.1 | `src/client/Controllers/BaseUI.luau` | Update `RARITY_COLORS`, modify `spawnBrainrotVisual` for rarity label display | ~40 lines modified |

> **Note:** Batch 3 is technically independent of Batches 1 and 2 and could run in parallel with Batch 1. It is listed separately for clarity since it has no dependency on the food config changes.

### Task Dependency Diagram

```
Batch 1 (parallel):
  1.1 Foods.luau --------+
  1.2 FoodStoreUI.luau --+---> Batch 1 complete
                                    |
                                    v
Batch 2 (depends on 1.1):
  2.1 FoodService.luau ----------> Batch 2 complete

Batch 3 (independent, can run any time):
  3.1 BaseUI.luau ----------------> Batch 3 complete
```

### Total: 4 files modified, ~240 estimated lines changed.

---

## 7. Data Structures

### 7.1 Updated Food Config Entry Shape (Phase 2)

```luau
-- A concrete Phase 2 food entry example (Epic Eats):
{
    name = "Epic Eats",
    cost = 7500,
    maxRarity = "Legendary",
    stayChance = 0.45,
    rarityWeights = {
        Common = 30,
        Rare = 35,
        Epic = 25,
        Legendary = 10,
    },
}
```

### 7.2 BrainrotInstance (unchanged from Phase 1)

The BrainrotInstance shape does not change in Phase 2. All brainrots still spawn with:

```luau
{
    id = "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6",
    name = "Tralalero Tralala",
    rarity = "Epic",
    size = 1.0,              -- Still 1.0 (no size system yet)
    sizeLabel = "Medium",    -- Still "Medium"
    weight = 450,            -- Still baseWeight (no size scaling)
    baseMutation = nil,      -- Still nil (no mutations yet)
    weatherMutation = nil,   -- Still nil
    personality = nil,       -- Still nil
    earningsPerSec = 1250,   -- Still baseEarningsPerSec
}
```

### 7.3 Complete Food Cost Table (Phase 2 Balanced)

For quick reference, here is the full cost table with time-to-afford estimates:

```
Food Tier           | Cost           | Previous Tier $/sec | Time to Afford
--------------------|----------------|---------------------|---------------
Common Chow         | $50            | N/A (start $100)    | Immediate
Rare Rations        | $500           | $5/sec              | ~100 sec
Epic Eats           | $7,500         | $50/sec             | ~150 sec
Legendary Feast     | $100,000       | $1,250/sec          | ~80 sec
Mythic Meal         | $1,500,000     | $10,000/sec         | ~150 sec
Goldy Grub          | $20,000,000    | $100,000/sec        | ~200 sec
Secret Snack        | $300,000,000   | $750,000/sec        | ~400 sec
Unknown Elixir      | $5,000,000,000 | $5,000,000/sec      | ~1000 sec
```

### 7.4 Rarity Color Palette (Phase 2)

```
Rarity      | Hex       | RGB             | Text Color
------------|-----------|-----------------|------------
Common      | #AAAAAA   | 170, 170, 170   | Same
Rare        | #55AAFF   | 85, 170, 255    | Same
Epic        | #AA55FF   | 170, 85, 255    | Same
Legendary   | #FFAA00   | 255, 170, 0     | Same
Mythic      | #FF5555   | 255, 85, 85     | Same
Goldy       | #FFD700   | 255, 215, 0     | Same
Secret      | #000000   | 0, 0, 0         | White (#FFFFFF)
Unknown     | #FF00FF   | 255, 0, 255     | Same
```

---

## 8. Testing Criteria

After all 4 files are modified, verify the following step by step. Every step must pass.

### Build Test

1. Run `rojo build -o "collect-brainrots.rbxlx"` from the project root. Verify it succeeds with no errors.

### Studio Playtest

2. Open the built `.rbxlx` file in Roblox Studio. Start Rojo serve and connect.
3. Press Play in Studio (solo test mode).

### Food Store Display

4. Verify the food store UI appears at the bottom of the screen with a scrolling list.
5. Verify all 8 food tiers are visible in the list (scroll to see all).
6. Verify each tier shows: food name, cost, "Attracts up to: [maxRarity]", and a buy button.
7. Verify Common Chow's buy button is green (player starts with $100, cost is $50).
8. Verify all other food tiers' buy buttons are grayed out (player cannot afford them at start).

### Buying Common Food

9. Buy Common Chow. Verify money drops from $100 to $50.
10. Observe spawn/run-away feedback as in Phase 1.
11. If a Common brainrot spawns, verify it displays with a gray-colored Part and BillboardGui showing "Common" above the brainrot name in gray text.
12. If a Rare brainrot spawns (10% chance), verify it displays with a blue-colored Part and BillboardGui showing "Rare" above the brainrot name in blue text.

### Buying Higher-Tier Food (requires earning money first)

13. Wait until money accumulates sufficiently (or temporarily modify starting money for testing).
14. Buy Rare Rations ($500). Verify it deducts the correct amount.
15. Verify the rolled brainrot is one of: Common (60%), Rare (30%), or Epic (10%) -- no other rarity should appear.
16. Buy Epic Eats ($7,500). Verify rolled brainrots are from the correct rarity pool (Common/Rare/Epic/Legendary).
17. Repeat for all 8 tiers, verifying each tier's rarity distribution looks reasonable (exact probabilities are hard to verify with small samples, but the range of rarities should match the weight tables).

### Rarity Distribution Verification

18. Buy Common Chow at least 20 times (adjust starting money for testing). Verify that the vast majority of results are Common, with occasional Rares. No Epics or above should appear.
19. Buy Rare Rations at least 20 times. Verify Commons and Rares dominate, with occasional Epics. No Legendaries or above should appear.
20. Buy Unknown Elixir at least 10 times. Verify results include Mythic, Goldy, Secret, and Unknown rarities. No Common, Rare, Epic, or Legendary should appear.

### Rarity Color Display

21. Verify that each rarity tier's brainrot Part is colored correctly per the RARITY_COLORS palette.
22. Verify that each brainrot's BillboardGui shows the rarity name ("Common", "Rare", etc.) on its own line above the brainrot name.
23. Verify that the rarity text and name text are both colored in the rarity color.
24. If a Secret brainrot is spawned, verify the Part is black and the BillboardGui text is white (not black-on-transparent).

### Button State Management

25. When the player cannot afford a food tier, verify the buy button for that tier is grayed out and non-clickable.
26. When money increases (via earnings) past a food tier's cost, verify the button dynamically becomes green and clickable.
27. When the base is full (1/1), verify ALL buy buttons are grayed out and a "Base Full!" message is visible.
28. After a brainrot runs away (capacity drops below max), verify buttons re-enable for affordable tiers.

### Regression Tests (Phase 1 functionality preserved)

29. Verify money display still works correctly (top of screen).
30. Verify earnings/sec display still updates correctly.
31. Verify capacity display still shows correct values.
32. Verify passive income still works (money increases every second).
33. Verify capacity enforcement still works (cannot buy when full).
34. Verify data persistence still works (rejoin restores money, brainrots, earnings).

### Progression Feel

35. Play through the game from fresh start to at least Tier 3 (Epic Eats). Verify that progression feels meaningful -- each tier upgrade requires waiting and earning, but not so long that it becomes boring. The target is roughly 1-3 minutes per tier for the first few tiers, increasing to 5-15 minutes for the highest tiers.

### Console Cleanliness

36. Check the Studio Output console for any errors (red text). There should be zero errors. The Phase 1 warning about "Capacity upgrade not available in Phase 1" is still acceptable.

---

## 9. Acceptance Criteria

All of the following must be true before Phase 2 is considered complete:

| # | Criterion | How to Verify |
|---|---|---|
| 1 | `rojo build` succeeds | Run `rojo build -o "collect-brainrots.rbxlx"` -- no errors |
| 2 | All 8 food tiers visible in the food store UI | Visual check -- scroll through the list |
| 3 | All 25 brainrots are obtainable through the food system | Verify by buying each food tier multiple times -- all rarities from Common through Unknown can be rolled with appropriate food |
| 4 | Buying Common Chow mostly gives Commons (occasionally Rare) | Buy 20+ times -- ~90% Common, ~10% Rare, 0% anything else |
| 5 | Buying Rare Rations gives mix of Commons/Rares/occasional Epics | Buy 20+ times -- distribution roughly matches 60/30/10 |
| 6 | Buying expensive food gives rarer brainrots more often | Higher-tier food produces higher-rarity brainrots at increased rates |
| 7 | Unknown Elixir never produces Common, Rare, Epic, or Legendary | Buy 10+ times -- only Mythic/Goldy/Secret/Unknown appear |
| 8 | Rarity distribution matches weight tables | Statistical verification with 20+ rolls per tier |
| 9 | Brainrot display shows correct rarity color | Each rarity's Part and BillboardGui text uses the correct color from RARITY_COLORS |
| 10 | BillboardGui shows "[Rarity]" above brainrot name | Visual check -- both rarity and name text visible |
| 11 | Secret rarity displays with white text on black Part | Visual check when a Secret brainrot spawns |
| 12 | Cannot buy food you cannot afford (button grayed out) | Try clicking grayed-out buttons -- nothing happens |
| 13 | Buttons dynamically update when money changes | Watch buttons change from gray to green as money accumulates past thresholds |
| 14 | Base full state disables all buy buttons | Fill base to capacity, verify all buttons gray out with "Base Full!" message |
| 15 | Food costs create good progression pacing | Play through at least 3 tiers -- each tier takes meaningful (but not excessive) time to reach |
| 16 | Progression from Common to Rare Rations takes ~1-2 min | Timed playthrough |
| 17 | Progression from Rare to Epic Eats takes ~2-3 min | Timed playthrough |
| 18 | Phase 1 gate removed from FoodService | Code inspection -- `ALLOWED_FOODS_PHASE1` no longer exists |
| 19 | `RARITY_WEIGHTS` global table removed from Foods.luau | Code inspection -- each food entry has its own `rarityWeights` field instead |
| 20 | No errors in Studio Output console | Check for red error text -- zero errors |
| 21 | All Phase 1 functionality preserved (regression) | Money display, earnings, capacity, persistence, feedback messages all still work |
| 22 | Stay chance comes from food tier, not brainrot rarity | Code inspection -- `food.stayChance` is used in the stay roll |

---

## Appendix A: Phase 2 Limitations (What Is NOT Included)

These features are intentionally absent from Phase 2. They will be added in later phases. Do not implement them.

| Feature | Deferred To |
|---|---|
| Size system (size tiers, size multipliers, weight scaling) | Phase 3+ |
| Base mutations (Gold, Diamond, Rainbow) | Phase 3+ |
| Weather events and weather mutations | Phase 6 |
| Personality system | Phase 8 |
| Sell system (individual + bulk sell) | Phase 5 |
| Brainrot fusion (3-to-1 upgrade) | Phase 8 |
| Collection index / codex | Phase 7 |
| Base capacity upgrades (functional) | Phase 3+ |
| Multiple plots | Future phase |
| Gifting system | Phase 7 |
| Leaderboards | Phase 7 |
| Tutorial UI | Phase 8 |
| 3D brainrot models (real meshes instead of cubes) | Phase 3+ |
| Sound effects and music | Phase 4 |
| Map building and environment art | Phase 3 |
| Lucky Hours | Future phase |
| VIP Food | Future phase |

## Appendix B: Food Cost Balancing Methodology

The food cost curve was designed with the following principles:

1. **Each tier should require earning from the previous tier.** A player with only Common brainrots should not be able to quickly skip to Legendary Feast. They need to buy Rare Rations first, get Rare brainrots, then earn toward Epic Eats, and so on.

2. **Time-to-afford increases gradually.** Early tiers (Common -> Rare) are fast (~1-2 min) to hook players. Mid tiers (Epic -> Legendary) feel like meaningful progress (~2-3 min each). Late tiers (Goldy -> Unknown) are serious grinds (~5-17 min) that reward dedication.

3. **The cost ratio between tiers is not constant.** Early tiers use a ~10x multiplier (50 -> 500 -> 7,500). Later tiers use a ~13-15x multiplier (20M -> 300M -> 5B). This creates an accelerating cost curve that prevents players from "running away" with progression.

4. **Multiple brainrots speed up progression.** The times listed assume 1 brainrot earning at base rate. Players with 2-3 brainrots (once base capacity upgrades are added in a later phase) will progress faster. The costs are balanced around single-brainrot income to ensure progression works even with minimum capacity.

5. **Costs can be adjusted post-launch.** Changing a number in `Foods.luau` is trivial. If playtesting reveals that any tier feels too fast or too slow, adjust the `cost` field. The rest of the system (rarity weights, stay chances) is independent of costs.

## Appendix C: Rarity Weight Design Rationale

The rarity weight tables follow a "sliding window" pattern:

- **Common Chow** has a 2-rarity window: Common (90%) and Rare (10%).
- **Rare Rations** has a 3-rarity window: Common (60%), Rare (30%), Epic (10%).
- **Epic Eats** has a 4-rarity window: Common (30%), Rare (35%), Epic (25%), Legendary (10%).
- **Legendary Feast** has a 5-rarity window: Common (15%), Rare (25%), Epic (30%), Legendary (20%), Mythic (10%).

Starting from Mythic Meal, the floor rarity rises (no more Commons):

- **Mythic Meal** drops Commons entirely. Floor is Rare (20%).
- **Goldy Grub** drops Commons and Rares. Floor is Epic (15%).
- **Secret Snack** drops Commons, Rares, and Epics. Floor is Legendary (15%).
- **Unknown Elixir** drops everything below Mythic. Floor is Mythic (15%).

This ensures that expensive food always feels "worth it" -- you never get a Common from a $5 billion Unknown Elixir. The top rarity always has the highest single weight at the top tier (Unknown = 40% on Unknown Elixir), making it the most efficient path to endgame content.

The 10% "tail" for the next-tier-up rarity on most food tiers creates exciting "lucky roll" moments where a player using Epic Eats suddenly gets a Legendary. These moments are a key engagement driver.

---

*End of Phase 2 Full Rarity and Food System specification.*
