# Phase 4: Base Mutations

> **Status:** NOT STARTED
> **Depends on:** Phase 3 (size system complete and tested)
> **Blocks:** Phase 5 (Sell System), Phase 6 (Weather Events)

---

## 1. Objective

Implement base mutations (Gold, Diamond, Rainbow) that are rolled when food is purchased and a brainrot stays at the player's base. Each brainrot can have at most ONE base mutation. Mutations multiply earnings and add visual effects (color tint and particle emitters). This phase adds a second layer of earnings variance on top of the size system from Phase 3, making every brainrot spawn more exciting due to the chance of a rare mutation.

By the end of this phase:
- Every brainrot spawn includes a mutation roll (85% None, 8% Gold, 5% Diamond, 2% Rainbow).
- Mutated brainrots earn more (Gold 1.5x, Diamond 2.5x, Rainbow 5.0x).
- Mutated brainrots are visually distinct (color tint + particle effects).
- The BillboardGui label includes the mutation name.
- The spawn reveal message includes the mutation with colored text.
- Weather mutation data is defined in config (for Phase 6) but not yet active.

---

## 2. Prerequisites

Phase 3 must be fully complete before starting Phase 4. Specifically:

- `src/shared/Config/Sizes.luau` exists and defines the 5 size tiers (Tiny, Small, Medium, Large, Massive) with spawn weights, earnings multipliers, visual scales, and weight modifiers.
- `src/server/Services/FoodService.luau` rolls a size tier when a brainrot spawns and sets `size`, `sizeLabel`, `weight`, and `earningsPerSec` accordingly.
- `src/server/Services/EarningsService.luau` factors in the size multiplier when recalculating earnings.
- `src/client/Controllers/BaseUI.luau` displays the size label in the BillboardGui (e.g., "Large Epic Tralalero Tralala") and scales the brainrot Part by the visual scale.
- `src/client/Controllers/FoodStoreUI.luau` shows the size label in the spawn reveal message.
- The earnings formula at the end of Phase 3 is: `baseEarnings * sizeMult`.
- `rojo build` succeeds and the game runs without console errors.

---

## 3. Files to Create/Modify

| # | File Path | Action | Purpose |
|---|---|---|---|
| 1 | `src/shared/Config/Mutations.luau` | **CREATE** | Base mutation definitions (chance, multiplier, color, particle data) and weather mutation definitions (data only, used in Phase 6). Provides roll and lookup functions. |
| 2 | `src/server/Services/FoodService.luau` | **MODIFY** | Roll base mutation on brainrot spawn. Set `baseMutation` field. Update `earningsPerSec` to include base mutation multiplier. |
| 3 | `src/server/Services/EarningsService.luau` | **MODIFY** | Include `Mutations.getBaseMutationMultiplier()` in the earnings recalculation formula. |
| 4 | `src/client/Controllers/BaseUI.luau` | **MODIFY** | Apply mutation color tint to brainrot Part. Add ParticleEmitter for visual flair. Update BillboardGui format to include mutation name. |
| 5 | `src/client/Controllers/FoodStoreUI.luau` | **MODIFY** | Show mutation name in spawn reveal with mutation-specific text color. Rainbow mutation gets animated cycling text. |

---

## 4. Detailed Spec Per File

---

### 4.1 `src/shared/Config/Mutations.luau` (CREATE)

**Purpose:** Defines all mutation data tables and provides utility functions for rolling mutations and looking up multipliers/colors. This is a shared module accessible to both server and client code. It has zero dependencies on other project files.

**Returns:** A table named `Mutations` containing data tables and functions.

**Data tables:**

#### BASE_MUTATIONS

A dictionary keyed by mutation name. Each entry contains the mutation's properties.

```luau
local BASE_MUTATIONS = {
    Gold = {
        chance = 0.08,              -- 8% chance
        multiplier = 1.5,           -- 1.5x earnings
        color = Color3.fromRGB(255, 215, 0),  -- #FFD700
        particleEffect = "GoldSparkles",
    },
    Diamond = {
        chance = 0.05,              -- 5% chance
        multiplier = 2.5,           -- 2.5x earnings
        color = Color3.fromRGB(185, 242, 255),  -- #B9F2FF
        particleEffect = "DiamondSparkles",
    },
    Rainbow = {
        chance = 0.02,              -- 2% chance
        multiplier = 5.0,           -- 5.0x earnings
        color = nil,                -- nil because Rainbow cycles through colors
        particleEffect = "RainbowParticles",
    },
}
```

**RULE:** Only ONE base mutation per brainrot. They are mutually exclusive. The roll distribution is: 85% None, 8% Gold, 5% Diamond, 2% Rainbow. If a mutation is rolled, the brainrot gets that specific one and no others.

#### WEATHER_MUTATIONS (Phase 6 data, defined now)

A dictionary keyed by weather mutation name. Each entry contains the mutation's properties. These are not actively used until Phase 6 but are defined here so that the config is complete and `getWeatherMutationMultiplier()` is available for forward-compatibility.

```luau
local WEATHER_MUTATIONS = {
    Soaked = {
        weather = "Rain",
        multiplier = 1.5,
    },
    Frozen = {
        weather = "Snow",
        multiplier = 2.0,
    },
    Shocked = {
        weather = "Storm",
        multiplier = 2.5,
    },
    Starstrucked = {
        weather = "Meteor Shower",
        multiplier = 5.0,
    },
    Burnt = {
        weather = "Solar Flare",
        multiplier = 10.0,
    },
    Radiated = {
        weather = "Nuclear",
        multiplier = 35.0,
    },
    Gravitated = {
        weather = "Black Hole",
        multiplier = 100.0,
    },
}
```

#### RAINBOW_COLORS

An ordered array of Color3 values used for cycling the Rainbow mutation's visual effect. The BaseUI controller uses this array to animate the rainbow tint.

```luau
local RAINBOW_COLORS = {
    Color3.fromRGB(255, 0, 0),      -- Red
    Color3.fromRGB(255, 127, 0),    -- Orange
    Color3.fromRGB(255, 255, 0),    -- Yellow
    Color3.fromRGB(0, 255, 0),      -- Green
    Color3.fromRGB(0, 0, 255),      -- Blue
    Color3.fromRGB(75, 0, 130),     -- Indigo
    Color3.fromRGB(148, 0, 211),    -- Violet
}
```

**Functions:**

```luau
function Mutations.rollBaseMutation(): string?
```
- Rolls a base mutation using `math.random()`.
- **Step by step:**
  1. Generate `roll = math.random()` (a float between 0 and 1).
  2. If `roll < 0.02`, return `"Rainbow"` (bottom 2%).
  3. If `roll < 0.02 + 0.05` (i.e., `roll < 0.07`), return `"Diamond"` (next 5%).
  4. If `roll < 0.07 + 0.08` (i.e., `roll < 0.15`), return `"Gold"` (next 8%).
  5. Otherwise, return `nil` (remaining 85%, no mutation).
- **Note:** Mutations are checked rarest-first so that the rarest mutation occupies the lowest portion of the random range. This ensures the probability distribution is correct regardless of floating-point edge cases.

```luau
function Mutations.getBaseMutationMultiplier(mutation: string?): number
```
- Returns the earnings multiplier for a given base mutation.
- **Step by step:**
  1. If `mutation` is `nil`, return `1.0`.
  2. Look up `BASE_MUTATIONS[mutation]`. If found, return `.multiplier`.
  3. If not found (invalid mutation name), warn and return `1.0`.

```luau
function Mutations.getBaseMutationColor(mutation: string?): Color3?
```
- Returns the tint color for a given base mutation.
- **Step by step:**
  1. If `mutation` is `nil`, return `nil` (no tint for normal brainrots).
  2. If `mutation == "Rainbow"`, return `nil` (Rainbow does not have a static color; the client handles cycling).
  3. Look up `BASE_MUTATIONS[mutation]`. If found, return `.color`.
  4. If not found, return `nil`.

```luau
function Mutations.getWeatherMutationMultiplier(mutation: string?): number
```
- Returns the earnings multiplier for a given weather mutation. Used by Phase 6 but available now.
- **Step by step:**
  1. If `mutation` is `nil`, return `1.0`.
  2. Look up `WEATHER_MUTATIONS[mutation]`. If found, return `.multiplier`.
  3. If not found, warn and return `1.0`.

```luau
function Mutations.isRainbow(mutation: string?): boolean
```
- Convenience function that returns `true` if the mutation is `"Rainbow"`, `false` otherwise.
- Used by the client to determine whether to run the rainbow color cycling animation.

**Module return structure:**

```luau
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
```

---

### 4.2 `src/server/Services/FoodService.luau` (MODIFY)

**What changes:** After rolling the size tier (added in Phase 3), FoodService now also rolls a base mutation and factors it into the brainrot's earnings.

**New dependency:**
- Add `require` for `Config/Mutations` at the top of the file:
  ```luau
  local Mutations = require(ReplicatedStorage.Shared.Config.Mutations)
  ```

**Changes to `handleBuyFood` internal function:**

After the existing step that rolls and applies the size tier (Phase 3), insert the following new steps:

1. **Roll base mutation:**
   ```luau
   local baseMutation = Mutations.rollBaseMutation()
   ```
   This returns `"Gold"`, `"Diamond"`, `"Rainbow"`, or `nil`.

2. **Get base mutation multiplier:**
   ```luau
   local baseMutationMult = Mutations.getBaseMutationMultiplier(baseMutation)
   ```

3. **Set `baseMutation` on the BrainrotInstance:**
   ```luau
   brainrotInstance.baseMutation = baseMutation
   ```

4. **Update `earningsPerSec` calculation:**
   The Phase 3 formula was:
   ```luau
   earningsPerSec = brainrotConfig.baseEarningsPerSec * sizeMult
   ```
   Update it to include the base mutation multiplier:
   ```luau
   earningsPerSec = brainrotConfig.baseEarningsPerSec * sizeMult * baseMutationMult
   ```

**Updated BrainrotInstance construction (showing the full table after Phase 4):**

```luau
local brainrotInstance = {
    id = Utils.generateId(),
    name = brainrotConfig.name,
    rarity = brainrotConfig.rarity,
    size = rolledSize,                                  -- from Phase 3
    sizeLabel = rolledSizeLabel,                        -- from Phase 3
    weight = brainrotConfig.baseWeight * weightModifier, -- from Phase 3
    baseMutation = baseMutation,                        -- NEW in Phase 4
    weatherMutation = nil,                              -- Phase 6
    personality = nil,                                  -- Phase 8
    earningsPerSec = brainrotConfig.baseEarningsPerSec * sizeMult * baseMutationMult,  -- UPDATED in Phase 4
}
```

**No other changes to FoodService.** The stay chance roll, money deduction, capacity check, remote fires, and everything else remain the same.

---

### 4.3 `src/server/Services/EarningsService.luau` (MODIFY)

**What changes:** The `recalculate` function must now factor in the base mutation multiplier when recomputing a player's total earnings per second.

**New dependency:**
- Add `require` for `Config/Mutations` at the top of the file:
  ```luau
  local Mutations = require(ReplicatedStorage.Shared.Config.Mutations)
  ```

**Changes to `recalculate(player)` function:**

The Phase 3 implementation sums `brainrot.earningsPerSec` for each brainrot in `data.ownedBrainrots`. Since `earningsPerSec` is already computed with the mutation multiplier at spawn time (in FoodService), this sum is already correct. However, EarningsService should still be aware of the mutation multiplier for cases where earnings need to be recomputed from base values (e.g., if a brainrot's data is modified after spawn).

**Approach A (simple, recommended for Phase 4):** Since `brainrot.earningsPerSec` is pre-computed at spawn time and stored on the instance, `recalculate` can continue to simply sum `brainrot.earningsPerSec` for all owned brainrots. No formula change is needed in `recalculate` itself because the stored value already includes the mutation multiplier.

**Approach B (robust, for future-proofing):** Recompute `earningsPerSec` from base values during recalculation. This is useful if any multiplier changes after spawn (e.g., weather mutations in Phase 6). If using this approach, the recalculation loop becomes:

```luau
function EarningsService.recalculate(player: Player)
    local data = DataService.getData(player)
    if not data then
        earningsCache[player] = 0
        return
    end

    local total = 0
    for _, brainrot in data.ownedBrainrots do
        local brainrotConfig = Brainrots.BRAINROT_BY_NAME[brainrot.name]
        if brainrotConfig then
            local baseEarnings = brainrotConfig.baseEarningsPerSec
            local sizeMult = Sizes.getSizeMultiplier(brainrot.sizeLabel)
            local baseMutMult = Mutations.getBaseMutationMultiplier(brainrot.baseMutation)
            local weatherMutMult = Mutations.getWeatherMutationMultiplier(brainrot.weatherMutation)

            local computed = baseEarnings * sizeMult * baseMutMult * weatherMutMult
            brainrot.earningsPerSec = computed  -- update stored value
            total = total + computed
        end
    end

    earningsCache[player] = total
    Remotes.EarningsUpdated:FireClient(player, { earningsPerSec = total })
end
```

**Recommendation:** Use Approach B. It is only slightly more complex and it ensures that earnings are always consistent with the current multiplier values, which is essential for Phase 6 when weather mutations can change a brainrot's `weatherMutation` field after spawn.

**New dependencies for Approach B:**
- Add `require` for `Config/Brainrots`:
  ```luau
  local Brainrots = require(ReplicatedStorage.Shared.Config.Brainrots)
  ```
- Add `require` for `Config/Sizes`:
  ```luau
  local Sizes = require(ReplicatedStorage.Shared.Config.Sizes)
  ```
- `Config/Mutations` is already added above.

**Formula (Phase 4):**

```
earningsPerSec = baseEarnings * sizeMult * baseMutationMult * weatherMutationMult
```

Where `weatherMutationMult` is always `1.0` in Phase 4 (no weather mutations yet), making the effective formula:

```
earningsPerSec = baseEarnings * sizeMult * baseMutationMult
```

---

### 4.4 `src/client/Controllers/BaseUI.luau` (MODIFY)

**What changes:** Brainrots with a base mutation now receive a visual color tint, a ParticleEmitter for visual flair, and an updated BillboardGui label format that includes the mutation name.

**New dependency:**
- Add `require` for `Config/Mutations` at the top of the file:
  ```luau
  local Mutations = require(ReplicatedStorage.Shared.Config.Mutations)
  ```
- Add `RunService` for the Rainbow cycling animation:
  ```luau
  local RunService = game:GetService("RunService")
  ```

**Changes to `spawnBrainrotVisual(brainrot)` internal function:**

After creating the Part and setting its base rarity color (existing Phase 1/3 behavior), add the following mutation visual logic:

#### 4.4.1 Color Tint

```luau
-- Apply mutation color tint (replaces rarity color if mutation is present)
local mutationColor = Mutations.getBaseMutationColor(brainrot.baseMutation)
if mutationColor then
    part.Color = mutationColor
end
```

For Rainbow mutations, `getBaseMutationColor` returns `nil`, so the rarity color is kept as the initial color. Instead, a cycling animation is set up (see section 4.4.3).

#### 4.4.2 Particle Emitter

If the brainrot has a base mutation, attach a ParticleEmitter to the Part for visual distinction.

```luau
if brainrot.baseMutation then
    local emitter = Instance.new("ParticleEmitter")
    emitter.Rate = 15
    emitter.Lifetime = NumberRange.new(0.5, 1.5)
    emitter.Speed = NumberRange.new(1, 3)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 0),
    })

    if brainrot.baseMutation == "Gold" then
        emitter.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
        emitter.LightEmission = 0.5
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        })

    elseif brainrot.baseMutation == "Diamond" then
        emitter.Color = ColorSequence.new(Color3.fromRGB(185, 242, 255))
        emitter.LightEmission = 0.8
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(1, 1),
        })

    elseif brainrot.baseMutation == "Rainbow" then
        -- Rainbow particles cycle through the rainbow color array
        local rainbowColors = Mutations.RAINBOW_COLORS
        emitter.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, rainbowColors[1]),
            ColorSequenceKeypoint.new(0.167, rainbowColors[2]),
            ColorSequenceKeypoint.new(0.333, rainbowColors[3]),
            ColorSequenceKeypoint.new(0.5, rainbowColors[4]),
            ColorSequenceKeypoint.new(0.667, rainbowColors[5]),
            ColorSequenceKeypoint.new(0.833, rainbowColors[6]),
            ColorSequenceKeypoint.new(1, rainbowColors[7]),
        })
        emitter.LightEmission = 1.0
        emitter.Rate = 25  -- more particles for rainbow
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 0.8),
        })
    end

    emitter.Parent = part
end
```

#### 4.4.3 Rainbow Color Cycling

For Rainbow-mutated brainrots, set up a RenderStepped connection that cycles the Part's color through the RAINBOW_COLORS array.

```luau
if Mutations.isRainbow(brainrot.baseMutation) then
    local rainbowColors = Mutations.RAINBOW_COLORS
    local colorIndex = 1
    local cycleSpeed = 2  -- seconds per full cycle
    local elapsed = 0

    local connection = RunService.RenderStepped:Connect(function(dt)
        if not part or not part.Parent then
            -- Part was destroyed, disconnect
            connection:Disconnect()
            return
        end

        elapsed = elapsed + dt
        local t = (elapsed / cycleSpeed) % 1  -- 0 to 1 continuously
        local totalColors = #rainbowColors
        local scaledT = t * totalColors
        local index = math.floor(scaledT) % totalColors + 1
        local nextIndex = index % totalColors + 1
        local alpha = scaledT - math.floor(scaledT)

        part.Color = rainbowColors[index]:Lerp(rainbowColors[nextIndex], alpha)
    end)

    -- Store connection for cleanup
    -- (Use a table to track connections alongside brainrotParts)
end
```

**Implementation note:** Store the RenderStepped connection in a parallel table (e.g., `brainrotConnections[brainrot.id] = connection`) so it can be disconnected when the brainrot is removed or the player leaves.

#### 4.4.4 Updated BillboardGui Label Format

The BillboardGui name label currently shows (after Phase 3):
```
[SizeLabel] [Rarity] [Name]
e.g., "Large Epic Tralalero Tralala"
```

Update it to include the mutation name if present:
```
[Mutation] [SizeLabel] [Rarity] [Name] - [Weight] lbs
e.g., "Gold Large Epic Tralalero Tralala - 342.5 lbs"
e.g., "Diamond Tiny Common Burbaloni Lulilolli - 4.8 lbs"
e.g., "Rainbow Massive Legendary Bombombini Gusini - 87.5 lbs"
e.g., "Large Epic Tralalero Tralala - 675.0 lbs"  (no mutation)
```

**Step by step for constructing the label text:**

```luau
local labelParts = {}
if brainrot.baseMutation then
    table.insert(labelParts, brainrot.baseMutation)
end
table.insert(labelParts, brainrot.sizeLabel)
table.insert(labelParts, brainrot.rarity)
table.insert(labelParts, brainrot.name)

local nameText = table.concat(labelParts, " ")
local weightText = string.format("%.1f lbs", brainrot.weight)
nameLabel.Text = nameText .. " - " .. weightText
```

If the brainrot has a mutation, color the name label with the mutation color instead of the rarity color:

```luau
local labelColor
if brainrot.baseMutation then
    local mutColor = Mutations.getBaseMutationColor(brainrot.baseMutation)
    if mutColor then
        labelColor = mutColor
    elseif Mutations.isRainbow(brainrot.baseMutation) then
        -- For Rainbow, use a bright white or cycle (simplified: use white)
        labelColor = Color3.fromRGB(255, 255, 255)
    end
else
    labelColor = RARITY_COLORS[brainrot.rarity] or Color3.fromRGB(255, 255, 255)
end
nameLabel.TextColor3 = labelColor
```

---

### 4.5 `src/client/Controllers/FoodStoreUI.luau` (MODIFY)

**What changes:** The spawn reveal feedback message now includes the mutation name (if present) with mutation-specific text coloring.

**New dependency:**
- Add `require` for `Config/Mutations` at the top of the file:
  ```luau
  local Mutations = require(ReplicatedStorage.Shared.Config.Mutations)
  ```

**Changes to `BrainrotSpawned.OnClientEvent` handler:**

Currently the handler shows:
```
"[Name] joined your base!"
```

Update it to include the full descriptor with mutation, size, and rarity:

```luau
-- Construct the reveal text
local revealParts = {}
if brainrotData.baseMutation then
    table.insert(revealParts, string.upper(brainrotData.baseMutation))
end
table.insert(revealParts, brainrotData.sizeLabel)
table.insert(revealParts, brainrotData.rarity)
table.insert(revealParts, brainrotData.name)

local descriptor = table.concat(revealParts, " ")
FeedbackLabel.Text = "You got a " .. descriptor .. "!"
```

**Examples:**
- `"You got a GOLD Large Epic Tralalero Tralala!"`
- `"You got a RAINBOW Massive Common Hipocactus!"`
- `"You got a DIAMOND Tiny Legendary Shpioniro Golubiro!"`
- `"You got a Medium Common Burbaloni Lulilolli!"` (no mutation)

**Text color based on mutation:**

```luau
if brainrotData.baseMutation then
    local mutColor = Mutations.getBaseMutationColor(brainrotData.baseMutation)
    if mutColor then
        FeedbackLabel.TextColor3 = mutColor
    elseif Mutations.isRainbow(brainrotData.baseMutation) then
        -- Start a brief rainbow text animation
        FeedbackLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        -- Animate: cycle through RAINBOW_COLORS over the 3-second display duration
        task.spawn(function()
            local rainbowColors = Mutations.RAINBOW_COLORS
            local startTime = os.clock()
            while os.clock() - startTime < 3 do
                local t = ((os.clock() - startTime) * 3) % #rainbowColors
                local idx = math.floor(t) % #rainbowColors + 1
                local nextIdx = idx % #rainbowColors + 1
                local alpha = t - math.floor(t)
                FeedbackLabel.TextColor3 = rainbowColors[idx]:Lerp(rainbowColors[nextIdx], alpha)
                task.wait()
            end
        end)
    end
else
    FeedbackLabel.TextColor3 = Color3.fromRGB(85, 255, 85)  -- default green for non-mutated
end
```

**The existing 3-second display + fade-out logic remains unchanged.** The mutation text color is applied before the timer starts.

---

## 5. Module Contracts

### New Cross-Module Dependencies (Phase 4)

**FoodService now requires:**

| Module | Function Called | Purpose |
|---|---|---|
| `Config/Mutations` | `Mutations.rollBaseMutation()` | Roll a base mutation (or nil) when a brainrot spawns |
| `Config/Mutations` | `Mutations.getBaseMutationMultiplier(mutation)` | Get the earnings multiplier for the rolled mutation |

**EarningsService now requires:**

| Module | Function Called | Purpose |
|---|---|---|
| `Config/Mutations` | `Mutations.getBaseMutationMultiplier(mutation)` | Factor base mutation into earnings recalculation |
| `Config/Mutations` | `Mutations.getWeatherMutationMultiplier(mutation)` | Factor weather mutation into earnings recalculation (always 1.0 in Phase 4) |
| `Config/Brainrots` | `Brainrots.BRAINROT_BY_NAME[name]` | Look up base earnings for recomputation |
| `Config/Sizes` | `Sizes.getSizeMultiplier(sizeLabel)` | Look up size multiplier for recomputation |

**BaseUI now requires:**

| Module | Function Called | Purpose |
|---|---|---|
| `Config/Mutations` | `Mutations.getBaseMutationColor(mutation)` | Get tint color for mutated brainrots |
| `Config/Mutations` | `Mutations.isRainbow(mutation)` | Check if rainbow cycling animation is needed |
| `Config/Mutations` | `Mutations.RAINBOW_COLORS` | Color array for rainbow cycling |

**FoodStoreUI now requires:**

| Module | Function Called | Purpose |
|---|---|---|
| `Config/Mutations` | `Mutations.getBaseMutationColor(mutation)` | Color the spawn reveal text by mutation |
| `Config/Mutations` | `Mutations.isRainbow(mutation)` | Determine if rainbow text animation is needed |
| `Config/Mutations` | `Mutations.RAINBOW_COLORS` | Color array for rainbow text cycling |

### Existing Contracts (Unchanged)

- FoodService still calls `DataService.getData()`, `DataService.subtractMoney()`, `BaseService.canAddBrainrot()`, `BaseService.getCapacity()`, `EarningsService.recalculate()`, and fires `BrainrotSpawned`, `BrainrotRanAway`, `CapacityUpdated` remotes.
- EarningsService still calls `DataService.getData()`, `DataService.addMoney()`, and fires `EarningsUpdated`.
- BaseUI still reads `brainrotInstance.baseMutation` for visual effects (this field existed since Phase 1 as `nil`; now it can be populated).
- No new RemoteEvents are needed. The existing `BrainrotSpawned` remote payload already includes the full `BrainrotInstance` table, which now has `baseMutation` populated.

---

## 6. Agent Task Breakdown

Tasks are organized into steps. Steps must be completed in order. Tasks within a step can be done in parallel.

### Step 1 (Independent -- no dependencies on other Phase 4 files)

| Task | File | Action | Est. Lines |
|---|---|---|---|
| 1.1 | `src/shared/Config/Mutations.luau` | CREATE | ~130 |

Create the complete Mutations config module with all data tables (BASE_MUTATIONS, WEATHER_MUTATIONS, RAINBOW_COLORS) and all functions (rollBaseMutation, getBaseMutationMultiplier, getBaseMutationColor, getWeatherMutationMultiplier, isRainbow).

### Step 2 (Parallel -- depends on Step 1)

| Task | File | Action | Est. Lines Changed |
|---|---|---|---|
| 2.1 | `src/server/Services/FoodService.luau` | MODIFY | ~15 |
| 2.2 | `src/server/Services/EarningsService.luau` | MODIFY | ~25 |

These two modifications are independent of each other and can be done in parallel. Both require `Config/Mutations` which was created in Step 1.

- **2.1 FoodService:** Add the `require` for Mutations. Add the mutation roll and multiplier application inside `handleBuyFood`, after the size roll and before the BrainrotInstance construction.
- **2.2 EarningsService:** Add the `require` for Mutations (and Brainrots, Sizes). Refactor the `recalculate` function to recompute earnings from base values using the full formula: `baseEarnings * sizeMult * baseMutMult * weatherMutMult`.

### Step 3 (Parallel -- depends on Step 2)

| Task | File | Action | Est. Lines Changed |
|---|---|---|---|
| 3.1 | `src/client/Controllers/BaseUI.luau` | MODIFY | ~80 |
| 3.2 | `src/client/Controllers/FoodStoreUI.luau` | MODIFY | ~40 |

These two modifications are independent of each other and can be done in parallel.

- **3.1 BaseUI:** Add the `require` for Mutations and RunService. Modify `spawnBrainrotVisual` to apply color tint, add ParticleEmitter, set up rainbow cycling, and update the BillboardGui label format.
- **3.2 FoodStoreUI:** Add the `require` for Mutations. Modify the `BrainrotSpawned` handler to show mutation name in uppercase with mutation-colored text, including rainbow text animation.

### Task Dependency Diagram

```
Step 1:
  1.1 Config/Mutations.luau (CREATE)
         |
         v
Step 2 (parallel):
  2.1 FoodService.luau ----+
  2.2 EarningsService.luau -+
         |
         v
Step 3 (parallel):
  3.1 BaseUI.luau ----------+
  3.2 FoodStoreUI.luau -----+
```

### Total: 1 new file, 4 modified files, ~290 estimated lines of new/changed Luau code.

---

## 7. Data Structures

### 7.1 Updated BrainrotInstance (Phase 4 shape)

After Phase 4, the `baseMutation` field is now populated (was always `nil` in Phases 1-3).

```luau
-- Example: A Gold Diamond brainrot
{
    id = "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6",
    name = "Tralalero Tralala",
    rarity = "Epic",
    size = 1.3,                  -- from Phase 3
    sizeLabel = "Large",         -- from Phase 3
    weight = 675.0,              -- baseWeight 450 * 1.5 (Large weight modifier)
    baseMutation = "Gold",       -- NEW: populated in Phase 4 (or nil for 85% of brainrots)
    weatherMutation = nil,       -- still nil until Phase 6
    personality = nil,           -- still nil until Phase 8
    earningsPerSec = 3281.25,    -- 1250 * 1.75 * 1.5 = 3281.25
}

-- Example: A Rainbow Massive brainrot
{
    id = "f9e8d7c6b5a4f3e2d1c0b9a8f7e6d5c4",
    name = "Burbaloni Lulilolli",
    rarity = "Common",
    size = 1.75,
    sizeLabel = "Massive",
    weight = 30.0,               -- baseWeight 12 * 2.5 (Massive weight modifier)
    baseMutation = "Rainbow",
    weatherMutation = nil,
    personality = nil,
    earningsPerSec = 75.0,       -- 5 * 3.0 * 5.0 = 75.0
}

-- Example: No mutation (85% of brainrots)
{
    id = "1234567890abcdef1234567890abcdef",
    name = "Hipocactus",
    rarity = "Common",
    size = 1.0,
    sizeLabel = "Medium",
    weight = 85.0,
    baseMutation = nil,          -- no mutation
    weatherMutation = nil,
    personality = nil,
    earningsPerSec = 5.0,        -- 5 * 1.0 * 1.0 = 5.0
}
```

### 7.2 Mutations Config Table Shapes

#### BASE_MUTATIONS entry shape

```luau
{
    chance = number,            -- spawn probability (0.0 to 1.0)
    multiplier = number,        -- earnings multiplier
    color = Color3?,            -- tint color (nil for Rainbow)
    particleEffect = string,    -- particle effect identifier
}
```

#### WEATHER_MUTATIONS entry shape

```luau
{
    weather = string,           -- weather event name that triggers this mutation
    multiplier = number,        -- earnings multiplier
}
```

### 7.3 Earnings Formula (Phase 4)

```
earningsPerSec = baseEarnings * sizeMult * baseMutationMult * weatherMutationMult
```

| Factor | Source | Phase 4 Range |
|---|---|---|
| `baseEarnings` | `Config/Brainrots` (varies by rarity) | $5 to $50,000,000 |
| `sizeMult` | `Config/Sizes` (varies by size label) | 0.5x to 3.0x |
| `baseMutationMult` | `Config/Mutations` (varies by mutation) | 1.0x to 5.0x |
| `weatherMutationMult` | `Config/Mutations` (always 1.0 in Phase 4) | 1.0x |

**Phase 4 effective formula:** `baseEarnings * sizeMult * baseMutationMult`

**Phase 4 effective range:** 0.5x to 15.0x multiplier on base earnings (Massive 3.0 * Rainbow 5.0 = 15.0x max).

---

## 8. Testing Criteria

After all files are written, verify the following. Every test must pass.

### Build Test

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T1 | `rojo build` succeeds | Run `rojo build -o "collect-brainrots.rbxlx"` | Exits with code 0, no errors. |

### Mutation Distribution Tests

These tests require multiple food purchases (20+ attempts) to observe the statistical distribution. Use a testing approach: either temporarily increase mutation chances for faster testing, or perform many purchases and tally results.

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T2 | Most brainrots spawn with no mutation | Buy 20+ foods, count mutations | ~85% of spawns have `baseMutation = nil`. |
| T3 | Gold mutations appear at ~8% rate | Buy 50+ foods, count Gold mutations | Roughly 4 out of 50 should be Gold (statistical variance expected). |
| T4 | Diamond mutations appear at ~5% rate | Buy 50+ foods, count Diamond mutations | Roughly 2-3 out of 50 should be Diamond (statistical variance expected). |
| T5 | Rainbow mutations appear at ~2% rate | Buy 100+ foods, count Rainbow mutations | Roughly 2 out of 100 should be Rainbow (very rare; may need many attempts). |
| T6 | Only ONE mutation per brainrot | Inspect any mutated brainrot's data | `baseMutation` is either nil or exactly one of "Gold", "Diamond", "Rainbow". Never two mutations. |

### Earnings Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T7 | Gold brainrot earns 1.5x normal | Compare earnings of a Gold brainrot vs. same-name, same-size normal brainrot | Gold earns exactly 1.5x the normal version's earnings. |
| T8 | Diamond brainrot earns 2.5x normal | Compare earnings of a Diamond brainrot vs. same-name, same-size normal brainrot | Diamond earns exactly 2.5x the normal version's earnings. |
| T9 | Rainbow brainrot earns 5.0x normal | Compare earnings of a Rainbow brainrot vs. same-name, same-size normal brainrot | Rainbow earns exactly 5.0x the normal version's earnings. |
| T10 | Earnings formula chains correctly | Spawn a Gold Large brainrot and verify earnings | `earningsPerSec = baseEarnings * 1.75 * 1.5` (size Large * mutation Gold). |

### Visual Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T11 | Gold brainrot has gold color tint | Spawn a Gold brainrot, observe its Part | Part color is gold (#FFD700 / RGB 255, 215, 0). |
| T12 | Diamond brainrot has diamond color tint | Spawn a Diamond brainrot, observe its Part | Part color is light blue (#B9F2FF / RGB 185, 242, 255). |
| T13 | Rainbow brainrot cycles colors | Spawn a Rainbow brainrot, observe its Part | Part color continuously cycles through red, orange, yellow, green, blue, indigo, violet. |
| T14 | Gold brainrot has gold particle sparkles | Spawn a Gold brainrot, observe particles | Gold-colored particles emit from the Part. |
| T15 | Diamond brainrot has diamond particle sparkles | Spawn a Diamond brainrot, observe particles | Light blue particles emit from the Part with higher light emission. |
| T16 | Rainbow brainrot has rainbow particles | Spawn a Rainbow brainrot, observe particles | Multi-colored particles emit from the Part. |
| T17 | Normal brainrot has no particles | Spawn a normal (no mutation) brainrot | No ParticleEmitter attached to the Part. |

### BillboardGui Label Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T18 | BillboardGui shows mutation name | Spawn a Gold brainrot, read the label | Label reads "Gold [Size] [Rarity] [Name] - [Weight] lbs", e.g., "Gold Large Epic Tralalero Tralala - 675.0 lbs". |
| T19 | BillboardGui omits mutation for normal brainrots | Spawn a normal brainrot, read the label | Label reads "[Size] [Rarity] [Name] - [Weight] lbs" with no mutation prefix. |

### Spawn Reveal Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T20 | Spawn reveal shows mutation in uppercase | Spawn a Gold brainrot, read the feedback message | Message reads "You got a GOLD Large Epic Tralalero Tralala!" |
| T21 | Gold spawn reveal text is gold colored | Spawn a Gold brainrot, observe feedback text color | Text color is gold (#FFD700). |
| T22 | Diamond spawn reveal text is diamond colored | Spawn a Diamond brainrot, observe feedback text color | Text color is light blue (#B9F2FF). |
| T23 | Rainbow spawn reveal text cycles colors | Spawn a Rainbow brainrot, observe feedback text | Text color cycles through rainbow colors during the 3-second display. |
| T24 | Normal spawn reveal text is green | Spawn a normal brainrot, observe feedback text color | Text color is green (RGB 85, 255, 85) as in Phase 1. |

### Console Cleanliness Test

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T25 | No errors in console | Check Studio Output for red error text | Zero errors. Warnings from placeholder features are acceptable. |

---

## 9. Acceptance Criteria

All of the following must be true before Phase 4 is considered complete:

| # | Criterion | How to Verify |
|---|---|---|
| 1 | `rojo build` succeeds without errors | Run `rojo build -o "collect-brainrots.rbxlx"` |
| 2 | `Config/Mutations.luau` exists with correct data tables and functions | Read the file and verify BASE_MUTATIONS, WEATHER_MUTATIONS, RAINBOW_COLORS, and all 5 functions |
| 3 | Mutation system adds another layer of earnings variance | Buy multiple foods and observe varied earnings due to mutation rolls |
| 4 | Visual distinction is clear between normal, Gold, Diamond, and Rainbow brainrots | Observe color tints and particle effects on each mutation type |
| 5 | Mutation rates match the config (85% None, 8% Gold, 5% Diamond, 2% Rainbow) | Statistical observation over many purchases |
| 6 | Earnings formula correctly chains: `baseEarnings * sizeMult * baseMutationMult` | Verify computed `earningsPerSec` matches expected value for known inputs |
| 7 | Only ONE base mutation per brainrot (never Gold AND Diamond simultaneously) | Inspect brainrot data; `baseMutation` is always a single string or nil |
| 8 | BillboardGui label includes mutation name when present | Visual check of floating labels on mutated brainrots |
| 9 | Spawn reveal message includes mutation name with correct coloring | Visual check of feedback label on spawn |
| 10 | Rainbow mutation has cycling color animation on both the Part and the spawn reveal text | Visual check |
| 11 | Weather mutation data is defined in config (for Phase 6 forward-compatibility) | Read `Config/Mutations.luau` and verify WEATHER_MUTATIONS table with all 7 entries |
| 12 | `getWeatherMutationMultiplier()` returns correct values | Call function with each weather mutation name and verify against spec |
| 13 | EarningsService recalculate uses the full formula including mutation multipliers | Read the code and verify the recalculation loop |
| 14 | No errors in Studio Output console | Check for red error text during gameplay |
| 15 | All Phase 3 functionality still works (size system, size labels, weight display) | Regression test: verify sizes still appear correctly |

---

## Appendix A: Mutation Probability Verification

To verify mutation probabilities are correct, the following test methodology is recommended:

1. **Automated test:** Temporarily add a server-side loop that calls `Mutations.rollBaseMutation()` 10,000 times and tallies results. Print the distribution.
   ```luau
   local counts = { None = 0, Gold = 0, Diamond = 0, Rainbow = 0 }
   for i = 1, 10000 do
       local result = Mutations.rollBaseMutation()
       if result then
           counts[result] = counts[result] + 1
       else
           counts.None = counts.None + 1
       end
   end
   print("Mutation distribution (10,000 rolls):")
   for name, count in counts do
       print(string.format("  %s: %d (%.1f%%)", name, count, count / 100))
   end
   ```

2. **Expected output (approximately):**
   ```
   Mutation distribution (10,000 rolls):
     None: 8500 (85.0%)
     Gold: 800 (8.0%)
     Diamond: 500 (5.0%)
     Rainbow: 200 (2.0%)
   ```

3. **Acceptable variance:** +/- 2% from expected values is normal for 10,000 samples. If any category is off by more than 5%, investigate the roll logic.

## Appendix B: Earnings Examples (Phase 4)

| Brainrot | Rarity | Size | Base Mutation | Base $/sec | Size Mult | Mut Mult | Final $/sec |
|---|---|---|---|---|---|---|---|
| Burbaloni Lulilolli | Common | Medium | None | $5 | 1.0x | 1.0x | $5.00 |
| Burbaloni Lulilolli | Common | Large | Gold | $5 | 1.75x | 1.5x | $13.13 |
| Tralalero Tralala | Epic | Medium | Gold | $1,250 | 1.0x | 1.5x | $1,875.00 |
| Tralalero Tralala | Epic | Massive | Diamond | $1,250 | 3.0x | 2.5x | $9,375.00 |
| Tralalero Tralala | Epic | Massive | Rainbow | $1,250 | 3.0x | 5.0x | $18,750.00 |
| La Vaca Saturno Saturnita | Unknown | Massive | Rainbow | $50,000,000 | 3.0x | 5.0x | $750,000,000.00 |

---

*End of Phase 4 Base Mutations specification.*
