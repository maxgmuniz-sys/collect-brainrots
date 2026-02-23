# Phase 8: Advanced Features (Fusion, Lucky Hours, VIP Food, Personalities)

> **Status:** NOT STARTED
> **Depends on:** Phase 7 (Trading System, Gifting, Leaderboards, Index/Codex complete and tested)
> **Blocks:** Phase 9 (Monetization, Gamepasses, DevProducts)

---

## 1. Objective

Implement four advanced features that add strategic depth, time-limited excitement, and personality-driven variety to the gameplay loop:

1. **Brainrot Fusion** -- Combine 3 brainrots of the same name to produce 1 brainrot of the next rarity tier. This gives players a deterministic path to upgrade their collection beyond pure RNG, creating a resource-management metagame where players weigh the tradeoff of keeping three decent earners versus gambling on a single better one.

2. **Lucky Hours** -- Random 5-minute windows (occurring every 30-60 minutes) where all food rarity weights shift toward rarer outcomes (effectively doubling rare+ tier chances). This creates server-wide excitement, encourages players to save premium food for these windows, and rewards players who happen to be online at the right time.

3. **VIP Food** -- Special limited-time food items flagged as `isVIP = true` in the food config. VIP food guarantees a minimum rarity tier (e.g., "Legendary VIP Food" only rolls Legendary or higher brainrots). VIP food costs significantly more than regular food of the same tier. For this phase, the system is built and tested but no events are activated -- Phase 9 can enable VIP food events via a server flag.

4. **Brainrot Personalities** -- Every brainrot spawns with a random personality tag (Lazy, Chill, Grumpy, Hyper) that serves as a 5th multiplier in the earnings formula and affects idle animation speed. This adds another layer of variance to every spawn, making each brainrot feel more unique.

By the end of this phase:
- Players can fuse 3 same-name brainrots into 1 next-tier brainrot via the Fusion UI.
- Lucky Hours trigger randomly every 30-60 minutes, last 5 minutes, and double rare+ rarity weights during food purchases.
- VIP food config entries exist with `isVIP = true` and `guaranteedMinRarity` fields, gated behind an event flag that defaults to `false`.
- Every newly spawned brainrot receives a personality (Lazy 0.9x, Chill 1.0x, Grumpy 0.95x, Hyper 1.2x).
- The full earnings formula becomes: `baseEarnings * sizeMult * baseMutationMult * weatherMutationMult * personalityMult`.
- Personality is displayed in BillboardGui and the spawn reveal message.
- Personality affects idle animation playback speed on the client.

---

## 2. Prerequisites

Phase 7 must be fully complete and tested before starting Phase 8. Specifically:

- `src/server/Services/IndexService.luau` provides the collection codex, discovery registration, and `RequestIndex` remote handling.
- `src/server/Services/GiftService.luau` handles brainrot gifting between players.
- `src/server/Services/LeaderboardService.luau` manages global leaderboards via OrderedDataStores.
- `src/client/Controllers/IndexUI.luau` renders the codex/index screen.
- `src/client/Controllers/LeaderboardUI.luau` renders the global leaderboard screen.
- `src/server/Services/FoodService.luau` handles the core buy-food-to-get-brainrot loop, rolls size, rolls base mutation, and constructs the `BrainrotInstance`.
- `src/server/Services/EarningsService.luau` uses the formula `baseEarnings * sizeMult * baseMutMult * weatherMutMult` where the personality multiplier currently returns `1.0` for `nil` personalities.
- `src/server/Services/WeatherService.luau` manages weather events and weather mutation application.
- `src/shared/Config/Foods.luau` defines 8 food tiers with `rarityWeights` per tier and `RARITY_ORDER`.
- `src/shared/Config/Brainrots.luau` defines all 25 brainrots with `BRAINROTS_BY_RARITY` lookup.
- `src/shared/Config/Mutations.luau` defines base and weather mutations with multiplier functions.
- `src/shared/Types.luau` defines `BrainrotInstance` with the `personality` field (currently always `nil`).
- `src/server/Services/DataService.luau` handles player data persistence and schema reconciliation.
- `src/server/Remotes/init.luau` defines all existing remotes including Phase 8 placeholders `FuseBrainrots` and `FuseResult` (already listed in ARCHITECTURE.md remote registry).
- `src/server/init.server.luau` boots all server services in the correct order.
- `src/client/init.client.luau` boots all client controllers in the correct order.
- `rojo build` succeeds and the game runs without console errors.

---

## 3. Files to Create/Modify

Every file is listed with its full path relative to the project root.

### New Files to Create (3 files)

| # | File Path | Purpose |
|---|---|---|
| 1 | `src/shared/Config/Personalities.luau` | Personality definitions (names, earnings multipliers, animation speed multipliers, spawn weights, display colors) |
| 2 | `src/server/Services/LuckyHourService.luau` | Lucky Hour global timer, random scheduling, rarity weight boosting, start/end remote firing |
| 3 | `src/client/Controllers/FusionUI.luau` | Fusion interface: eligible brainrot selection, preview of output rarity, fuse button, result display |

### Files to Modify (11 files)

| # | File Path | Change |
|---|---|---|
| 1 | `src/shared/Config/Foods.luau` | Add VIP food entries with `isVIP = true`, `guaranteedMinRarity`, and higher costs. Add `VIP_EVENT_ACTIVE` flag (defaults to `false`). |
| 2 | `src/shared/Types.luau` | Verify `personality: string?` field exists on BrainrotInstance type (should already be defined from Phase 1 forward-declaration). |
| 3 | `src/server/Services/FoodService.luau` | Roll personality on brainrot spawn. Handle `FuseBrainrots` remote for fusion logic. Respect Lucky Hour rarity weight boosting. Respect VIP food guaranteed rarity. Include personality multiplier in initial `earningsPerSec` calculation. |
| 4 | `src/server/Services/EarningsService.luau` | Add personality multiplier as 5th factor in `recalculate()`: `baseEarnings * sizeMult * baseMutMult * weatherMutMult * personalityMult`. |
| 5 | `src/server/Services/DataService.luau` | Add `tutorialComplete: boolean` to default PlayerData template (for TutorialUI in this phase). Verify `personality` field on BrainrotInstance is persisted. |
| 6 | `src/server/Remotes/init.luau` | Add `LuckyHourStarted` (S->C), `LuckyHourEnded` (S->C) RemoteEvents. Verify `FuseBrainrots` (C->S) and `FuseResult` (S->C) already exist or add them. |
| 7 | `src/client/Controllers/BaseUI.luau` | Display personality in BillboardGui label. Apply personality-based idle animation speed scaling. Restore personality visuals on brainrot load. |
| 8 | `src/client/Controllers/FoodStoreUI.luau` | Show personality in spawn reveal message. Show VIP food entries when event is active. Show Lucky Hour indicator on the food store screen. |
| 9 | `src/server/init.server.luau` | Add LuckyHourService to server boot order (after WeatherService). |
| 10 | `src/client/init.client.luau` | Add FusionUI to client boot order. |
| 11 | `src/client/Controllers/WeatherUI.luau` | Add Lucky Hour golden banner display (reuse the banner pattern from weather, but with a distinct golden style and "LUCKY HOUR!" text). |

---

## 4. Detailed Spec Per File

---

### 4.1 `src/shared/Config/Personalities.luau` (CREATE)

**Purpose:** Defines all personality types with their earnings multipliers, animation speed modifiers, spawn weights, and display colors. This is a shared module accessible to both server and client code. It has zero dependencies on other project files.

**Returns:** A table named `Personalities` containing the data table and utility functions.

**Data table:**

#### PERSONALITIES

A dictionary keyed by personality name. Each entry contains the personality's properties.

```luau
local PERSONALITIES = {
    Lazy = {
        earningsMultiplier = 0.9,       -- -10% earnings
        animationSpeed = 0.6,           -- 60% of normal animation speed (slow, sluggish)
        spawnWeight = 25,               -- 25% chance
        color = Color3.fromRGB(150, 180, 255),  -- Soft blue
        emoji = "😴",
        description = "Slow movement, frequent sleeping, yawning",
    },
    Chill = {
        earningsMultiplier = 1.0,       -- Neutral (no bonus or penalty)
        animationSpeed = 0.85,          -- 85% of normal (relaxed, slightly slow)
        spawnWeight = 25,               -- 25% chance
        color = Color3.fromRGB(150, 255, 200),  -- Soft green
        emoji = "😎",
        description = "Relaxed posture, slow wandering, vibing",
    },
    Grumpy = {
        earningsMultiplier = 0.95,      -- -5% earnings
        animationSpeed = 0.9,           -- 90% of normal (slightly irritated pace)
        spawnWeight = 25,               -- 25% chance
        color = Color3.fromRGB(255, 150, 150),  -- Soft red
        emoji = "😤",
        description = "Angry idle animations, stomping, huffing",
    },
    Hyper = {
        earningsMultiplier = 1.2,       -- +20% earnings
        animationSpeed = 1.5,           -- 150% of normal (fast, bouncy, energetic)
        spawnWeight = 25,               -- 25% chance
        color = Color3.fromRGB(255, 255, 100),  -- Bright yellow
        emoji = "⚡",
        description = "Fast movement, jumping, zooming around base",
    },
}
```

**PERSONALITY_ORDER constant:**

An ordered array of personality names, used for iteration and display purposes.

```luau
local PERSONALITY_ORDER = { "Lazy", "Chill", "Grumpy", "Hyper" }
```

**Functions:**

```luau
function Personalities.get(personalityName: string): PersonalityConfig?
```
- Returns the full config table for a given personality name.
- **Step by step:**
  1. Look up `PERSONALITIES[personalityName]`.
  2. If found, return the table.
  3. If not found, warn and return `nil`.

```luau
function Personalities.getEarningsMultiplier(personalityName: string?): number
```
- Returns the earnings multiplier for a given personality.
- **Step by step:**
  1. If `personalityName` is `nil`, return `1.0`.
  2. Look up `PERSONALITIES[personalityName]`.
  3. If found, return `.earningsMultiplier`.
  4. If not found, warn and return `1.0`.

```luau
function Personalities.getAnimationSpeed(personalityName: string?): number
```
- Returns the animation speed multiplier for a given personality.
- **Step by step:**
  1. If `personalityName` is `nil`, return `1.0`.
  2. Look up `PERSONALITIES[personalityName]`.
  3. If found, return `.animationSpeed`.
  4. If not found, warn and return `1.0`.

```luau
function Personalities.rollPersonality(): string
```
- Performs a weighted random roll to select a personality.
- **Step by step:**
  1. Compute `totalWeight` by summing `.spawnWeight` for all entries in `PERSONALITIES`. (25 + 25 + 25 + 25 = 100)
  2. Generate `roll = math.random() * totalWeight`.
  3. Iterate through `PERSONALITY_ORDER`. For each personality name:
     a. Get the config via `PERSONALITIES[name]`.
     b. Subtract `config.spawnWeight` from `roll`.
     c. If `roll <= 0`, return this personality name.
  4. Fallback (should never reach): return `"Chill"`.

**Module return structure:**

```luau
return {
    PERSONALITIES = PERSONALITIES,
    PERSONALITY_ORDER = PERSONALITY_ORDER,

    get = Personalities.get,
    getEarningsMultiplier = Personalities.getEarningsMultiplier,
    getAnimationSpeed = Personalities.getAnimationSpeed,
    rollPersonality = Personalities.rollPersonality,
}
```

---

### 4.2 `src/server/Services/LuckyHourService.luau` (CREATE)

**Purpose:** Manages the global Lucky Hour system on the server. Randomly schedules 5-minute Lucky Hour windows every 30-60 minutes. During a Lucky Hour, all food purchases receive boosted rarity weights (rare+ tiers are doubled). Fires remotes to notify all clients when Lucky Hours start and end.

**Dependencies:**

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = require(script.Parent.Parent.Remotes) -- adjust path as needed
```

**Constants:**

```luau
local LUCKY_HOUR_DURATION = 300          -- 5 minutes (in seconds)
local LUCKY_HOUR_INTERVAL_MIN = 1800     -- 30 minutes minimum between Lucky Hours
local LUCKY_HOUR_INTERVAL_MAX = 3600     -- 60 minutes maximum between Lucky Hours
local LUCKY_HOUR_RARITY_BOOST = 2.0      -- Multiply rare+ rarity weights by this factor
```

**State:**

```luau
local isLuckyHourActive: boolean = false
local luckyHourEndTime: number = 0        -- os.clock() timestamp when current Lucky Hour ends
local isRunning: boolean = false
```

**Public API:**

```luau
function LuckyHourService.init()
```
- Starts the Lucky Hour scheduling loop. Called once during server boot.
- **Step by step:**
  1. Set `isRunning = true`.
  2. Set `isLuckyHourActive = false`.
  3. Spawn the `luckyHourCycle()` coroutine via `task.spawn`.

```luau
function LuckyHourService.isActive(): boolean
```
- Returns whether a Lucky Hour is currently active.
- Used by FoodService to check whether to apply rarity weight boosting.

```luau
function LuckyHourService.getRarityBoost(): number
```
- Returns the rarity boost multiplier if Lucky Hour is active, otherwise returns `1.0`.
- **Step by step:**
  1. If `isLuckyHourActive`, return `LUCKY_HOUR_RARITY_BOOST`.
  2. Otherwise, return `1.0`.

```luau
function LuckyHourService.getEndTime(): number
```
- Returns the `os.clock()` timestamp when the current Lucky Hour ends.
- Returns `0` if no Lucky Hour is active.

**Internal functions (not exported):**

```luau
local function startLuckyHour()
```
- Activates a Lucky Hour.
- **Step by step:**
  1. Set `isLuckyHourActive = true`.
  2. Set `luckyHourEndTime = os.clock() + LUCKY_HOUR_DURATION`.
  3. Fire `Remotes.LuckyHourStarted:FireAllClients({ duration = LUCKY_HOUR_DURATION, endTime = luckyHourEndTime })`.
  4. Print to server output: `"[LuckyHour] Lucky Hour started! Duration: 300s"`.

```luau
local function endLuckyHour()
```
- Deactivates the current Lucky Hour.
- **Step by step:**
  1. Set `isLuckyHourActive = false`.
  2. Set `luckyHourEndTime = 0`.
  3. Fire `Remotes.LuckyHourEnded:FireAllClients({})`.
  4. Print to server output: `"[LuckyHour] Lucky Hour ended."`.

```luau
local function luckyHourCycle()
```
- The main infinite loop that drives the Lucky Hour scheduling. Runs as a spawned coroutine.
- **Step by step:**
  1. Loop forever while `isRunning`:
     a. Wait a random interval: `task.wait(math.random(LUCKY_HOUR_INTERVAL_MIN, LUCKY_HOUR_INTERVAL_MAX))`.
     b. Call `startLuckyHour()`.
     c. Wait for Lucky Hour to end: `task.wait(LUCKY_HOUR_DURATION)`.
     d. Call `endLuckyHour()`.
  2. End of loop.

**Late-joining players:** When a player joins during an active Lucky Hour, they need to know:

```luau
Players.PlayerAdded:Connect(function(player)
    if isLuckyHourActive then
        task.defer(function()
            Remotes.LuckyHourStarted:FireClient(player, {
                duration = 0,  -- don't send original duration
                endTime = luckyHourEndTime,  -- client computes remaining time
            })
        end)
    end
end)
```

**Module return structure:**

```luau
return {
    init = LuckyHourService.init,
    isActive = LuckyHourService.isActive,
    getRarityBoost = LuckyHourService.getRarityBoost,
    getEndTime = LuckyHourService.getEndTime,
}
```

---

### 4.3 `src/client/Controllers/FusionUI.luau` (CREATE)

**Purpose:** Provides the client-side Fusion interface where players can select 3 brainrots of the same name to fuse into a higher-rarity brainrot. Shows eligible brainrot groups (those with 3+ of the same name), previews the output rarity tier, and displays the fusion result.

**Dependencies:**

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Foods = require(ReplicatedStorage.Shared.Config.Foods)
local Brainrots = require(ReplicatedStorage.Shared.Config.Brainrots)
local Remotes = require(ReplicatedStorage.Shared.Remotes)  -- adjust path as needed

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
```

**Constants:**

```luau
-- Maps each rarity to the next tier up (used for preview display)
local NEXT_RARITY = {
    Common = "Rare",
    Rare = "Epic",
    Epic = "Legendary",
    Legendary = "Mythic",
    Mythic = "Goldy",
    Goldy = "Secret",
    Secret = "Unknown",
    -- Unknown cannot be fused
}

local RARITY_COLORS = {
    Common = Color3.fromRGB(255, 255, 255),
    Rare = Color3.fromRGB(0, 112, 255),
    Epic = Color3.fromRGB(163, 53, 238),
    Legendary = Color3.fromRGB(255, 128, 0),
    Mythic = Color3.fromRGB(255, 0, 0),
    Goldy = Color3.fromRGB(255, 215, 0),
    Secret = Color3.fromRGB(0, 206, 209),
    Unknown = Color3.fromRGB(30, 30, 30),
}
```

**State:**

```luau
local screenGui: ScreenGui? = nil
local mainFrame: Frame? = nil
local scrollFrame: ScrollingFrame? = nil
local resultFrame: Frame? = nil
local isOpen: boolean = false
local ownedBrainrots: { any } = {}   -- cached copy of player's owned brainrots
```

#### 4.3.1 UI Layout

```luau
local function createFusionUI()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FusionUI"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 8
    screenGui.Enabled = false
    screenGui.Parent = playerGui

    -- Semi-transparent background overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.Parent = screenGui

    -- Main fusion panel (centered)
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "FusionPanel"
    mainFrame.Size = UDim2.new(0, 500, 0, 600)
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -300)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = mainFrame

    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 0, 40)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "BRAINROT FUSION"
    title.TextColor3 = Color3.fromRGB(255, 200, 50)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame

    -- Subtitle
    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Size = UDim2.new(1, -20, 0, 20)
    subtitle.Position = UDim2.new(0, 10, 0, 50)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Combine 3 of the same brainrot to get a higher rarity!"
    subtitle.TextColor3 = Color3.fromRGB(180, 180, 180)
    subtitle.TextScaled = true
    subtitle.Font = Enum.Font.Gotham
    subtitle.Parent = mainFrame

    -- Scrolling frame for eligible fusion groups
    scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "FusionList"
    scrollFrame.Size = UDim2.new(1, -20, 1, -130)
    scrollFrame.Position = UDim2.new(0, 10, 0, 80)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.Parent = mainFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 8)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scrollFrame

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -40, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Text = "X"
    closeBtn.TextScaled = true
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = mainFrame

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        closeFusionUI()
    end)

    -- Result display frame (hidden by default, shown after fusion)
    resultFrame = Instance.new("Frame")
    resultFrame.Name = "ResultFrame"
    resultFrame.Size = UDim2.new(0.8, 0, 0, 120)
    resultFrame.Position = UDim2.new(0.1, 0, 1, -130)
    resultFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    resultFrame.BackgroundTransparency = 0.2
    resultFrame.BorderSizePixel = 0
    resultFrame.Visible = false
    resultFrame.Parent = mainFrame

    local resultCorner = Instance.new("UICorner")
    resultCorner.CornerRadius = UDim.new(0, 12)
    resultCorner.Parent = resultFrame
end
```

#### 4.3.2 Populating Eligible Fusions

```luau
local function updateFusionList(brainrots: { any })
    ownedBrainrots = brainrots

    -- Clear existing entries
    for _, child in scrollFrame:GetChildren() do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    -- Count brainrots by name
    local counts: { [string]: { count: number, rarity: string, brainrots: { any } } } = {}
    for _, brainrot in brainrots do
        if not counts[brainrot.name] then
            counts[brainrot.name] = {
                count = 0,
                rarity = brainrot.rarity,
                brainrots = {},
            }
        end
        counts[brainrot.name].count += 1
        table.insert(counts[brainrot.name].brainrots, brainrot)
    end

    -- Build UI entries for groups with 3+ brainrots (exclude Unknown -- cannot fuse)
    local layoutOrder = 0
    for name, group in counts do
        if group.count >= 3 and group.rarity ~= "Unknown" then
            layoutOrder += 1
            createFusionEntry(name, group.rarity, group.count, layoutOrder)
        end
    end

    -- Update canvas size
    local listLayout = scrollFrame:FindFirstChildOfClass("UIListLayout")
    if listLayout then
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end

    -- Show "no eligible fusions" message if empty
    if layoutOrder == 0 then
        local noFusions = Instance.new("TextLabel")
        noFusions.Name = "NoFusions"
        noFusions.Size = UDim2.new(1, -20, 0, 60)
        noFusions.BackgroundTransparency = 1
        noFusions.Text = "No eligible brainrots for fusion.\nYou need 3+ of the same brainrot (not Unknown tier)."
        noFusions.TextColor3 = Color3.fromRGB(150, 150, 150)
        noFusions.TextScaled = true
        noFusions.TextWrapped = true
        noFusions.Font = Enum.Font.Gotham
        noFusions.Parent = scrollFrame
    end
end
```

#### 4.3.3 Individual Fusion Entry

```luau
local function createFusionEntry(brainrotName: string, rarity: string, count: number, layoutOrder: number)
    local nextRarity = NEXT_RARITY[rarity]
    if not nextRarity then return end  -- Unknown cannot be fused

    local entry = Instance.new("Frame")
    entry.Name = "FusionEntry_" .. brainrotName
    entry.Size = UDim2.new(1, 0, 0, 70)
    entry.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    entry.BackgroundTransparency = 0.3
    entry.BorderSizePixel = 0
    entry.LayoutOrder = layoutOrder
    entry.Parent = scrollFrame

    local entryCorner = Instance.new("UICorner")
    entryCorner.CornerRadius = UDim.new(0, 8)
    entryCorner.Parent = entry

    -- Brainrot name and count
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.5, -10, 0, 25)
    nameLabel.Position = UDim2.new(0, 10, 0, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = brainrotName
    nameLabel.TextColor3 = RARITY_COLORS[rarity] or Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = entry

    local countLabel = Instance.new("TextLabel")
    countLabel.Size = UDim2.new(0.5, -10, 0, 20)
    countLabel.Position = UDim2.new(0, 10, 0, 30)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = string.format("Owned: %d (uses 3)", count)
    countLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
    countLabel.TextScaled = true
    countLabel.TextXAlignment = Enum.TextXAlignment.Left
    countLabel.Font = Enum.Font.Gotham
    countLabel.Parent = entry

    -- Output preview
    local outputLabel = Instance.new("TextLabel")
    outputLabel.Size = UDim2.new(0.3, 0, 0, 20)
    outputLabel.Position = UDim2.new(0.5, 0, 0, 8)
    outputLabel.BackgroundTransparency = 1
    outputLabel.Text = "-> Random " .. nextRarity
    outputLabel.TextColor3 = RARITY_COLORS[nextRarity] or Color3.fromRGB(255, 255, 255)
    outputLabel.TextScaled = true
    outputLabel.Font = Enum.Font.GothamBold
    outputLabel.Parent = entry

    -- Fuse button
    local fuseBtn = Instance.new("TextButton")
    fuseBtn.Name = "FuseButton"
    fuseBtn.Size = UDim2.new(0.2, -10, 0, 40)
    fuseBtn.Position = UDim2.new(0.8, -5, 0.5, -20)
    fuseBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
    fuseBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    fuseBtn.Text = "FUSE"
    fuseBtn.TextScaled = true
    fuseBtn.Font = Enum.Font.GothamBold
    fuseBtn.Parent = entry

    local fuseBtnCorner = Instance.new("UICorner")
    fuseBtnCorner.CornerRadius = UDim.new(0, 8)
    fuseBtnCorner.Parent = fuseBtn

    local fusesAvailable = math.floor(count / 3)
    local fusesLabel = Instance.new("TextLabel")
    fusesLabel.Size = UDim2.new(0.3, 0, 0, 16)
    fusesLabel.Position = UDim2.new(0.5, 0, 0, 35)
    fusesLabel.BackgroundTransparency = 1
    fusesLabel.Text = string.format("(%d fuse%s available)", fusesAvailable, fusesAvailable == 1 and "" or "s")
    fusesLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
    fusesLabel.TextScaled = true
    fusesLabel.Font = Enum.Font.Gotham
    fusesLabel.Parent = entry

    fuseBtn.MouseButton1Click:Connect(function()
        -- Disable button to prevent double-click
        fuseBtn.Active = false
        fuseBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        fuseBtn.Text = "..."

        -- Fire fusion request to server
        Remotes.FuseBrainrots:FireServer({ brainrotName = brainrotName })
    end)
end
```

#### 4.3.4 Fusion Result Handler

```luau
local function onFuseResult(data: { success: boolean, newBrainrot: any?, errorMessage: string? })
    if data.success and data.newBrainrot then
        showFusionResult(data.newBrainrot)
    else
        showFusionError(data.errorMessage or "Fusion failed!")
    end
end

local function showFusionResult(brainrot: any)
    if not resultFrame then return end

    resultFrame.Visible = true

    -- Clear previous result content
    for _, child in resultFrame:GetChildren() do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    local resultTitle = Instance.new("TextLabel")
    resultTitle.Size = UDim2.new(1, -20, 0, 25)
    resultTitle.Position = UDim2.new(0, 10, 0, 5)
    resultTitle.BackgroundTransparency = 1
    resultTitle.Text = "FUSION SUCCESS!"
    resultTitle.TextColor3 = Color3.fromRGB(255, 220, 50)
    resultTitle.TextScaled = true
    resultTitle.Font = Enum.Font.GothamBold
    resultTitle.Parent = resultFrame

    local personalityText = brainrot.personality and (" " .. brainrot.personality) or ""
    local sizeText = brainrot.sizeLabel or ""
    local mutationText = brainrot.baseMutation and (brainrot.baseMutation .. " ") or ""

    local resultName = Instance.new("TextLabel")
    resultName.Size = UDim2.new(1, -20, 0, 30)
    resultName.Position = UDim2.new(0, 10, 0, 30)
    resultName.BackgroundTransparency = 1
    resultName.Text = string.format("%s%s %s%s", mutationText, sizeText, brainrot.name, personalityText)
    resultName.TextColor3 = RARITY_COLORS[brainrot.rarity] or Color3.fromRGB(255, 255, 255)
    resultName.TextScaled = true
    resultName.Font = Enum.Font.GothamBold
    resultName.Parent = resultFrame

    local resultRarity = Instance.new("TextLabel")
    resultRarity.Size = UDim2.new(1, -20, 0, 20)
    resultRarity.Position = UDim2.new(0, 10, 0, 60)
    resultRarity.BackgroundTransparency = 1
    resultRarity.Text = string.format("[%s] - $%s/sec", brainrot.rarity, tostring(math.floor(brainrot.earningsPerSec)))
    resultRarity.TextColor3 = RARITY_COLORS[brainrot.rarity] or Color3.fromRGB(255, 255, 255)
    resultRarity.TextScaled = true
    resultRarity.Font = Enum.Font.Gotham
    resultRarity.Parent = resultFrame

    -- Auto-hide after 5 seconds
    task.delay(5, function()
        if resultFrame then
            resultFrame.Visible = false
        end
    end)
end

local function showFusionError(message: string)
    if not resultFrame then return end

    resultFrame.Visible = true

    for _, child in resultFrame:GetChildren() do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    local errorLabel = Instance.new("TextLabel")
    errorLabel.Size = UDim2.new(1, -20, 0, 40)
    errorLabel.Position = UDim2.new(0, 10, 0, 20)
    errorLabel.BackgroundTransparency = 1
    errorLabel.Text = message
    errorLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    errorLabel.TextScaled = true
    errorLabel.Font = Enum.Font.GothamBold
    errorLabel.Parent = resultFrame

    task.delay(3, function()
        if resultFrame then
            resultFrame.Visible = false
        end
    end)
end
```

#### 4.3.5 Open/Close Functions

```luau
local function openFusionUI()
    if not screenGui then return end
    isOpen = true
    screenGui.Enabled = true
    -- Request fresh brainrot data from BaseUI or listen for BrainrotSpawned updates
    -- For now, use the cached brainrot list provided via FusionUI.updateBrainrots()
end

local function closeFusionUI()
    if not screenGui then return end
    isOpen = false
    screenGui.Enabled = false
    if resultFrame then
        resultFrame.Visible = false
    end
end
```

#### 4.3.6 Public API

```luau
function FusionUI.init()
    createFusionUI()

    -- Listen for fusion results from server
    Remotes.FuseResult.OnClientEvent:Connect(onFuseResult)

    -- Listen for brainrot data updates to refresh the list
    Remotes.BrainrotSpawned.OnClientEvent:Connect(function()
        if isOpen then
            -- Refresh after a short delay to allow data to settle
            task.delay(0.5, function()
                -- Trigger refresh via cached data or request from server
            end)
        end
    end)
end

function FusionUI.open(brainrots: { any })
    updateFusionList(brainrots)
    openFusionUI()
end

function FusionUI.close()
    closeFusionUI()
end

function FusionUI.updateBrainrots(brainrots: { any })
    ownedBrainrots = brainrots
    if isOpen then
        updateFusionList(brainrots)
    end
end
```

**Module return structure:**

```luau
return {
    init = FusionUI.init,
    open = FusionUI.open,
    close = FusionUI.close,
    updateBrainrots = FusionUI.updateBrainrots,
}
```

---

### 4.4 `src/shared/Config/Foods.luau` (MODIFY)

**What changes:** Add VIP food entries and a global event flag. The VIP food system is built but not activated.

**New constant:**

```luau
local VIP_EVENT_ACTIVE = false   -- Set to true during special events (Phase 9 can activate)
```

**New VIP food entries appended to the `FOODS` table:**

```luau
{
    name = "Legendary VIP Food",
    cost = 500000,                  -- 10x the cost of Legendary Feast ($50,000)
    maxRarity = "Mythic",           -- Can attract up to Mythic
    stayChance = 0.35,              -- Same stay chance as Legendary Feast
    isVIP = true,
    guaranteedMinRarity = "Legendary",  -- Only rolls Legendary or higher
    rarityWeights = {
        Legendary = 60,
        Mythic = 30,
        Goldy = 10,
    },
    description = "VIP-tier food that guarantees at least a Legendary brainrot.",
},
{
    name = "Mythic VIP Food",
    cost = 5000000,                 -- 10x the cost of Mythic Meal ($500,000)
    maxRarity = "Goldy",
    stayChance = 0.28,
    isVIP = true,
    guaranteedMinRarity = "Mythic",
    rarityWeights = {
        Mythic = 55,
        Goldy = 35,
        Secret = 10,
    },
    description = "VIP-tier food that guarantees at least a Mythic brainrot.",
},
{
    name = "Secret VIP Food",
    cost = 500000000,               -- 10x the cost of Secret Snack ($50,000,000)
    maxRarity = "Unknown",
    stayChance = 0.18,
    isVIP = true,
    guaranteedMinRarity = "Secret",
    rarityWeights = {
        Secret = 60,
        Unknown = 40,
    },
    description = "VIP-tier food that guarantees at least a Secret brainrot.",
},
```

**Rules for VIP food:**
- VIP food entries have `isVIP = true` and a `guaranteedMinRarity` field.
- VIP food is only shown in the food store when `VIP_EVENT_ACTIVE == true`.
- VIP food `rarityWeights` only contain rarities at or above `guaranteedMinRarity` -- no lower rarities can be rolled.
- VIP food still respects stay chance -- the brainrot can still leave.
- VIP food does NOT guarantee base mutations or specific personalities.

**Existing food entries gain a new field (default values):**

All existing (non-VIP) food entries receive:
```luau
isVIP = false,
guaranteedMinRarity = nil,
```

**Add to module return:**

```luau
return {
    FOODS = FOODS,
    FOOD_BY_NAME = FOOD_BY_NAME,
    RARITY_ORDER = RARITY_ORDER,
    VIP_EVENT_ACTIVE = VIP_EVENT_ACTIVE,
}
```

---

### 4.5 `src/shared/Types.luau` (MODIFY -- verify)

**What changes:** Verify that the `personality` field already exists on the `BrainrotInstance` type definition. Per the ARCHITECTURE.md, it was forward-declared in Phase 1:

```luau
type BrainrotInstance = {
    -- ... existing fields ...

    -- Phase 8: Personality system
    personality: string?,        -- "Lazy" | "Chill" | "Grumpy" | "Hyper" | nil
}
```

**If the `personality` field is NOT present:** Add it to the type definition.

No other changes to Types.luau.

---

### 4.6 `src/server/Services/FoodService.luau` (MODIFY)

**What changes:** This file receives the most modifications in Phase 8. Four changes:

1. **Roll personality on brainrot spawn.**
2. **Handle `FuseBrainrots` remote for fusion logic.**
3. **Apply Lucky Hour rarity weight boosting during food purchases.**
4. **Handle VIP food guaranteed minimum rarity.**

**New dependencies:**

```luau
local Personalities = require(ReplicatedStorage.Shared.Config.Personalities)
local LuckyHourService = require(script.Parent.LuckyHourService)
```

#### 4.6.1 Personality Roll (in brainrot spawn logic)

After rolling size and base mutation, add personality roll:

```luau
-- Roll personality (Phase 8)
local personality = Personalities.rollPersonality()
```

Include personality in the `earningsPerSec` calculation:

```luau
local personalityMult = Personalities.getEarningsMultiplier(personality)
local earningsPerSec = baseEarnings * sizeMult * baseMutMult * weatherMutMult * personalityMult
```

Set the personality field on the BrainrotInstance:

```luau
local brainrot = {
    id = HttpService:GenerateGUID(false),
    name = rolledBrainrot.name,
    rarity = rolledBrainrot.rarity,
    size = size,
    sizeLabel = sizeLabel,
    weight = weight,
    baseMutation = baseMutation,
    weatherMutation = nil,          -- only applied by WeatherService
    personality = personality,       -- NEW: Phase 8
    earningsPerSec = earningsPerSec,
}
```

#### 4.6.2 Lucky Hour Rarity Weight Boosting

When rolling a brainrot from food, apply the Lucky Hour boost to rare+ rarity weights:

```luau
local function getRarityWeightsForFood(foodConfig: any): { [string]: number }
    local baseWeights = foodConfig.rarityWeights
    local boost = LuckyHourService.getRarityBoost()

    if boost == 1.0 then
        return baseWeights  -- no boost active, use original weights
    end

    -- Apply boost: multiply all non-Common rarity weights by the boost factor
    local boostedWeights = {}
    for rarity, weight in baseWeights do
        if rarity == "Common" then
            boostedWeights[rarity] = weight  -- Common is not boosted
        else
            boostedWeights[rarity] = weight * boost  -- Double rare+ weights
        end
    end

    return boostedWeights
end
```

Replace the existing rarity roll call to use `getRarityWeightsForFood(foodConfig)` instead of `foodConfig.rarityWeights` directly.

**How boosting works mathematically:**

Given original weights like `{ Common = 70, Rare = 20, Epic = 8, Legendary = 2 }` (total 100):
- During Lucky Hour (2x boost): `{ Common = 70, Rare = 40, Epic = 16, Legendary = 4 }` (total 130).
- New effective probabilities: Common ~54%, Rare ~31%, Epic ~12%, Legendary ~3%.
- This roughly doubles the chance of getting rare+ while reducing the Common share.

#### 4.6.3 VIP Food Handling

In the `handleBuyFood` function, after validating the food tier:

```luau
-- Check VIP food availability
local Foods = require(ReplicatedStorage.Shared.Config.Foods)
if foodConfig.isVIP and not Foods.VIP_EVENT_ACTIVE then
    warn("[FoodService] VIP food not available: no active event")
    return  -- reject purchase
end
```

VIP food uses its own `rarityWeights` which only contain rarities at or above `guaranteedMinRarity`. No special handling needed beyond the existing rarity roll logic, because the VIP food's `rarityWeights` table already excludes lower rarities. The Lucky Hour boost also applies to VIP food (stacks).

#### 4.6.4 Fusion Handler

Add a new internal function and connect it to the `FuseBrainrots` remote:

```luau
local NEXT_RARITY = {
    Common = "Rare",
    Rare = "Epic",
    Epic = "Legendary",
    Legendary = "Mythic",
    Mythic = "Goldy",
    Goldy = "Secret",
    Secret = "Unknown",
}

local function handleFuseBrainrots(player: Player, data: { brainrotName: string })
    local brainrotName = data.brainrotName
    if not brainrotName or type(brainrotName) ~= "string" then
        Remotes.FuseResult:FireClient(player, {
            success = false,
            errorMessage = "Invalid brainrot name.",
        })
        return
    end

    local playerData = DataService.getData(player)
    if not playerData then
        Remotes.FuseResult:FireClient(player, {
            success = false,
            errorMessage = "Player data not loaded.",
        })
        return
    end

    -- Find 3 brainrots with the specified name
    local matchingIndices: { number } = {}
    local matchingRarity: string? = nil
    for index, brainrot in playerData.ownedBrainrots do
        if brainrot.name == brainrotName then
            matchingRarity = brainrot.rarity
            table.insert(matchingIndices, index)
            if #matchingIndices >= 3 then
                break
            end
        end
    end

    -- Validate we found exactly 3
    if #matchingIndices < 3 then
        Remotes.FuseResult:FireClient(player, {
            success = false,
            errorMessage = string.format("Need 3x %s, but only have %d.", brainrotName, #matchingIndices),
        })
        return
    end

    -- Validate rarity can be fused (Unknown cannot)
    if matchingRarity == "Unknown" then
        Remotes.FuseResult:FireClient(player, {
            success = false,
            errorMessage = "Unknown-tier brainrots cannot be fused.",
        })
        return
    end

    local nextRarity = NEXT_RARITY[matchingRarity]
    if not nextRarity then
        Remotes.FuseResult:FireClient(player, {
            success = false,
            errorMessage = "Cannot determine next rarity tier.",
        })
        return
    end

    -- Remove the 3 brainrots (remove from highest index first to avoid index shifting)
    table.sort(matchingIndices, function(a, b) return a > b end)
    for _, index in matchingIndices do
        table.remove(playerData.ownedBrainrots, index)
    end

    -- Roll a random brainrot from the next rarity tier
    local Brainrots = require(ReplicatedStorage.Shared.Config.Brainrots)
    local nextTierBrainrots = Brainrots.BRAINROTS_BY_RARITY[nextRarity]
    if not nextTierBrainrots or #nextTierBrainrots == 0 then
        Remotes.FuseResult:FireClient(player, {
            success = false,
            errorMessage = "No brainrots found for rarity: " .. nextRarity,
        })
        return
    end

    local rolledBrainrot = nextTierBrainrots[math.random(1, #nextTierBrainrots)]

    -- Roll fresh properties for the new brainrot (size, mutation, personality)
    local Sizes = require(ReplicatedStorage.Shared.Config.Sizes)
    local Mutations = require(ReplicatedStorage.Shared.Config.Mutations)

    local size, sizeLabel = Sizes.rollSize()
    local weight = rolledBrainrot.baseWeight * size
    local baseMutation = Mutations.rollBaseMutation()
    local personality = Personalities.rollPersonality()

    local baseMutMult = Mutations.getBaseMutationMultiplier(baseMutation)
    local personalityMult = Personalities.getEarningsMultiplier(personality)
    local earningsPerSec = rolledBrainrot.baseEarningsPerSec * size * baseMutMult * 1.0 * personalityMult
    -- weatherMutMult is 1.0 because new brainrots start with no weather mutation

    local newBrainrot = {
        id = HttpService:GenerateGUID(false),
        name = rolledBrainrot.name,
        rarity = nextRarity,
        size = size,
        sizeLabel = sizeLabel,
        weight = weight,
        baseMutation = baseMutation,
        weatherMutation = nil,
        personality = personality,
        earningsPerSec = earningsPerSec,
    }

    -- Check base capacity before adding
    local BaseService = require(script.Parent.BaseService)
    if #playerData.ownedBrainrots >= playerData.baseCapacity then
        -- Base is full after removing 3 (should not happen since we removed 3 and add 1, net -2)
        -- But add defensive check anyway
        Remotes.FuseResult:FireClient(player, {
            success = false,
            errorMessage = "Base is full!",
        })
        return
    end

    -- Add the new brainrot
    table.insert(playerData.ownedBrainrots, newBrainrot)

    -- Register discovery in index
    local IndexService = require(script.Parent.IndexService)
    IndexService.registerDiscovery(player, newBrainrot.name, newBrainrot.baseMutation)

    -- Recalculate earnings
    EarningsService.recalculate(player)

    -- Fire result to client
    Remotes.FuseResult:FireClient(player, {
        success = true,
        newBrainrot = newBrainrot,
    })

    -- Fire BrainrotSpawned so BaseUI creates the visual
    Remotes.BrainrotSpawned:FireClient(player, { brainrotData = newBrainrot })

    -- Fire CapacityUpdated
    Remotes.CapacityUpdated:FireClient(player, {
        current = #playerData.ownedBrainrots,
        max = playerData.baseCapacity,
    })

    print(string.format(
        "[FoodService] %s fused 3x %s -> %s %s (%s, %s)",
        player.Name, brainrotName, nextRarity, newBrainrot.name, sizeLabel, personality
    ))
end
```

**Connect to remote in `FoodService.init()`:**

```luau
Remotes.FuseBrainrots.OnServerEvent:Connect(handleFuseBrainrots)
```

---

### 4.7 `src/server/Services/EarningsService.luau` (MODIFY)

**What changes:** Add the personality multiplier as the 5th factor in the `recalculate()` function.

**New dependency:**

```luau
local Personalities = require(ReplicatedStorage.Shared.Config.Personalities)
```

**Updated recalculation formula:**

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
            local sizeMult = brainrot.size
            local baseMutMult = Mutations.getBaseMutationMultiplier(brainrot.baseMutation)
            local weatherMutMult = Mutations.getWeatherMutationMultiplier(brainrot.weatherMutation)
            local personalityMult = Personalities.getEarningsMultiplier(brainrot.personality)  -- NEW: Phase 8

            local computed = baseEarnings * sizeMult * baseMutMult * weatherMutMult * personalityMult
            brainrot.earningsPerSec = computed
            total = total + computed
        else
            total = total + brainrot.earningsPerSec
        end
    end

    earningsCache[player] = total
    Remotes.EarningsUpdated:FireClient(player, { earningsPerSec = total })
end
```

**Full earnings formula (Phase 8):**

```
earningsPerSec = baseEarnings * sizeMult * baseMutationMult * weatherMutationMult * personalityMult
```

All five factors are now active.

---

### 4.8 `src/server/Services/DataService.luau` (MODIFY)

**What changes:** Add `tutorialComplete` field to the default PlayerData template. Verify that the `personality` field on BrainrotInstance is properly persisted (it should be, since ProfileStore saves the full table).

**New field in default PlayerData template:**

```luau
local DEFAULT_DATA = {
    -- ... existing fields ...

    -- Phase 8: Tutorial
    tutorialComplete = false,       -- Set to true after tutorial is finished
}
```

ProfileStore reconciliation ensures existing players automatically receive `tutorialComplete = false` on their next load.

No changes to BrainrotInstance persistence -- the `personality` field is simply a string field on the brainrot table, which ProfileStore saves automatically as part of `ownedBrainrots`.

---

### 4.9 `src/server/Remotes/init.luau` (MODIFY)

**What changes:** Add Lucky Hour remotes. Verify that `FuseBrainrots` and `FuseResult` remotes already exist (per ARCHITECTURE.md remote registry, they are listed as Phase 8 remotes). If not present, add them.

**New/verified remotes:**

```luau
-- Phase 8: Fusion System
local FuseBrainrots = Instance.new("RemoteEvent")
FuseBrainrots.Name = "FuseBrainrots"
FuseBrainrots.Parent = remotesFolder

local FuseResult = Instance.new("RemoteEvent")
FuseResult.Name = "FuseResult"
FuseResult.Parent = remotesFolder

-- Phase 8: Lucky Hour System
local LuckyHourStarted = Instance.new("RemoteEvent")
LuckyHourStarted.Name = "LuckyHourStarted"
LuckyHourStarted.Parent = remotesFolder

local LuckyHourEnded = Instance.new("RemoteEvent")
LuckyHourEnded.Name = "LuckyHourEnded"
LuckyHourEnded.Parent = remotesFolder

-- Phase 8: Tutorial
local TutorialComplete = Instance.new("RemoteEvent")
TutorialComplete.Name = "TutorialComplete"
TutorialComplete.Parent = remotesFolder
```

**Add to the returned module table:**

```luau
return {
    -- ... existing remotes ...

    -- Phase 8: Fusion
    FuseBrainrots = FuseBrainrots,        -- C->S: { brainrotName: string }
    FuseResult = FuseResult,              -- S->C: { success: boolean, newBrainrot: BrainrotInstance?, errorMessage: string? }

    -- Phase 8: Lucky Hour
    LuckyHourStarted = LuckyHourStarted,  -- S->C: { duration: number, endTime: number }
    LuckyHourEnded = LuckyHourEnded,      -- S->C: {}

    -- Phase 8: Tutorial
    TutorialComplete = TutorialComplete,  -- C->S: {} (no payload)
}
```

**Payload schemas:**

| Remote | Direction | Payload |
|---|---|---|
| `FuseBrainrots` | Client -> Server | `{ brainrotName: string }` |
| `FuseResult` | Server -> Client | `{ success: boolean, newBrainrot: BrainrotInstance?, errorMessage: string? }` |
| `LuckyHourStarted` | Server -> Client | `{ duration: number, endTime: number }` |
| `LuckyHourEnded` | Server -> Client | `{}` |
| `TutorialComplete` | Client -> Server | `{}` |

- `FuseBrainrots.brainrotName`: The name of the brainrot to fuse (server finds 3 matching instances).
- `FuseResult.success`: Whether the fusion succeeded.
- `FuseResult.newBrainrot`: The newly created BrainrotInstance (only present on success).
- `FuseResult.errorMessage`: Human-readable error string (only present on failure).
- `LuckyHourStarted.duration`: Total duration of the Lucky Hour in seconds (300). Sent as 0 for late joiners.
- `LuckyHourStarted.endTime`: The `os.clock()` timestamp when the Lucky Hour ends.

---

### 4.10 `src/client/Controllers/BaseUI.luau` (MODIFY)

**What changes:** Display personality in BillboardGui. Apply personality-based idle animation speed scaling. Add a Fusion button to the base UI that opens the FusionUI. Restore personality visuals when loading saved brainrots on join.

**New dependency:**

```luau
local Personalities = require(ReplicatedStorage.Shared.Config.Personalities)
local FusionUI = require(script.Parent.FusionUI)
```

#### 4.10.1 BillboardGui Personality Label

Update `spawnBrainrotVisual()` (or the function that creates the BillboardGui) to include personality:

```luau
-- After existing mutation/size label setup:
if brainrot.personality then
    local personalityConfig = Personalities.get(brainrot.personality)
    if personalityConfig then
        local personalityLabel = Instance.new("TextLabel")
        personalityLabel.Name = "PersonalityLabel"
        personalityLabel.Size = UDim2.new(1, -20, 0, 14)
        personalityLabel.Position = UDim2.new(0, 10, 1, -16)  -- bottom of billboard
        personalityLabel.BackgroundTransparency = 1
        personalityLabel.TextScaled = true
        personalityLabel.Font = Enum.Font.Gotham
        personalityLabel.Text = brainrot.personality
        personalityLabel.TextColor3 = personalityConfig.color
        personalityLabel.Parent = billboard

        -- Expand billboard to make room if not already expanded by weather mutation
        billboard.Size = billboard.Size + UDim2.new(0, 0, 0, 16)
    end
end
```

**Billboard label format (Phase 8):**

The full BillboardGui now shows (from top to bottom):
1. `"[BaseMutation] [SizeLabel] [BrainrotName]"` (main label, colored by rarity)
2. `"[WeatherMutation]"` (if present, colored by weather mutation type)
3. `"[Personality]"` (colored by personality type)

Example: A Gold Large Hyper Tralalero Tralala with Soaked weather mutation would show:
```
Gold Large Tralalero Tralala    (purple, rarity color)
Soaked                          (blue, weather mutation color)
Hyper                           (yellow, personality color)
```

#### 4.10.2 Personality Animation Speed

After placing the brainrot visual Part, adjust idle animation speed based on personality:

```luau
-- Apply personality-based animation speed
if brainrot.personality then
    local animSpeed = Personalities.getAnimationSpeed(brainrot.personality)

    -- If the brainrot model has an AnimationController or uses a simple bob/idle tween:
    -- Adjust the idle animation speed accordingly.
    -- For cube-placeholder brainrots, adjust the bob tween speed:
    local bobTweenDuration = 2.0 / animSpeed  -- base bob duration is 2.0 seconds
    -- Use this duration when creating the idle bob tween for this brainrot
    startIdleBob(part, bobTweenDuration)
end
```

**Idle bob function (adjust existing or add new):**

```luau
local function startIdleBob(part: Part, duration: number)
    -- Simple up-down bob animation
    local startPos = part.Position
    local bobHeight = 0.3

    task.spawn(function()
        while part and part.Parent do
            local tweenUp = TweenService:Create(
                part,
                TweenInfo.new(duration / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                { Position = startPos + Vector3.new(0, bobHeight, 0) }
            )
            tweenUp:Play()
            tweenUp.Completed:Wait()

            if not part or not part.Parent then break end

            local tweenDown = TweenService:Create(
                part,
                TweenInfo.new(duration / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                { Position = startPos }
            )
            tweenDown:Play()
            tweenDown.Completed:Wait()
        end
    end)
end
```

Personality affects the bob speed:
- **Lazy** (0.6x speed): `duration = 2.0 / 0.6 = 3.33s` (slow, sleepy bob)
- **Chill** (0.85x speed): `duration = 2.0 / 0.85 = 2.35s` (relaxed bob)
- **Grumpy** (0.9x speed): `duration = 2.0 / 0.9 = 2.22s` (slightly sluggish bob)
- **Hyper** (1.5x speed): `duration = 2.0 / 1.5 = 1.33s` (fast, bouncy bob)

#### 4.10.3 Fusion Button

Add a "Fusion" button to the base HUD (near the existing "Upgrade Capacity" button):

```luau
local fuseBtn = Instance.new("TextButton")
fuseBtn.Name = "FusionButton"
fuseBtn.Size = UDim2.new(0, 120, 0, 40)
fuseBtn.Position = UDim2.new(0, 10, 0, 160)  -- position below upgrade button
fuseBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
fuseBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
fuseBtn.Text = "FUSION"
fuseBtn.TextScaled = true
fuseBtn.Font = Enum.Font.GothamBold
fuseBtn.Parent = baseHudFrame

fuseBtn.MouseButton1Click:Connect(function()
    -- Pass current brainrot list to FusionUI
    local data = DataService.getData(player)  -- or use cached brainrot list
    if data then
        FusionUI.open(data.ownedBrainrots)
    end
end)
```

---

### 4.11 `src/client/Controllers/FoodStoreUI.luau` (MODIFY)

**What changes:** Three modifications:

1. Show personality in the spawn reveal message.
2. Show VIP food entries when the event is active.
3. Show a Lucky Hour indicator on the food store screen.

#### 4.11.1 Personality in Spawn Reveal

Update the spawn reveal message to include personality:

```luau
-- In the BrainrotSpawned handler, after showing rarity/size/mutation:
local personalityText = ""
if brainrot.personality then
    local personalityConfig = Personalities.get(brainrot.personality)
    if personalityConfig then
        personalityText = string.format(" [%s]", brainrot.personality)
        -- Optionally color the personality text
    end
end

-- Updated reveal text format:
-- "[BaseMutation] [SizeLabel] [BrainrotName] [Personality]"
-- Example: "Gold Large Tralalero Tralala [Hyper]"
local revealText = string.format(
    "%s%s %s%s",
    mutationPrefix,
    brainrot.sizeLabel,
    brainrot.name,
    personalityText
)
```

#### 4.11.2 VIP Food Display

When building the food store list, check for VIP food:

```luau
local Foods = require(ReplicatedStorage.Shared.Config.Foods)

for _, food in Foods.FOODS do
    -- Skip VIP food if event is not active
    if food.isVIP and not Foods.VIP_EVENT_ACTIVE then
        continue
    end

    -- Create food tier entry (existing logic)
    createFoodEntry(food)

    -- If VIP food, add a special visual indicator
    if food.isVIP then
        -- Add golden border or "VIP" badge to the entry
        addVIPBadge(foodEntry)
    end
end
```

#### 4.11.3 Lucky Hour Indicator

Add a status indicator at the top of the food store that shows when a Lucky Hour is active:

```luau
local luckyHourLabel: TextLabel? = nil

local function createLuckyHourIndicator(parent: Frame)
    luckyHourLabel = Instance.new("TextLabel")
    luckyHourLabel.Name = "LuckyHourIndicator"
    luckyHourLabel.Size = UDim2.new(1, -20, 0, 30)
    luckyHourLabel.Position = UDim2.new(0, 10, 0, 5)
    luckyHourLabel.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    luckyHourLabel.BackgroundTransparency = 0.3
    luckyHourLabel.TextColor3 = Color3.fromRGB(40, 40, 0)
    luckyHourLabel.Text = "LUCKY HOUR ACTIVE! 2x Rare Spawns!"
    luckyHourLabel.TextScaled = true
    luckyHourLabel.Font = Enum.Font.GothamBold
    luckyHourLabel.Visible = false
    luckyHourLabel.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = luckyHourLabel
end

-- In FoodStoreUI.init():
Remotes.LuckyHourStarted.OnClientEvent:Connect(function(data)
    if luckyHourLabel then
        luckyHourLabel.Visible = true
    end
end)

Remotes.LuckyHourEnded.OnClientEvent:Connect(function()
    if luckyHourLabel then
        luckyHourLabel.Visible = false
    end
end)
```

---

### 4.12 `src/client/Controllers/WeatherUI.luau` (MODIFY)

**What changes:** Add Lucky Hour golden banner display. The Lucky Hour banner is separate from the weather banner and appears simultaneously if both are active.

**New state:**

```luau
local luckyHourBannerFrame: Frame? = nil
local luckyHourEndTime: number = 0
local isLuckyHourActive: boolean = false
```

**Lucky Hour banner creation (in `WeatherUI.init()` or `createBannerUI()`):**

```luau
local function createLuckyHourBanner()
    local screenGui = playerGui:FindFirstChild("WeatherUI")
    if not screenGui then return end

    luckyHourBannerFrame = Instance.new("Frame")
    luckyHourBannerFrame.Name = "LuckyHourBanner"
    luckyHourBannerFrame.Size = UDim2.new(0.35, 0, 0, 50)
    luckyHourBannerFrame.Position = UDim2.new(0.325, 0, 0, -60)  -- starts offscreen
    luckyHourBannerFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    luckyHourBannerFrame.BackgroundTransparency = 0.15
    luckyHourBannerFrame.BorderSizePixel = 0
    luckyHourBannerFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = luckyHourBannerFrame

    local luckyLabel = Instance.new("TextLabel")
    luckyLabel.Name = "LuckyText"
    luckyLabel.Size = UDim2.new(1, -10, 0, 25)
    luckyLabel.Position = UDim2.new(0, 5, 0, 3)
    luckyLabel.BackgroundTransparency = 1
    luckyLabel.Text = "LUCKY HOUR! 2x Rare Spawns!"
    luckyLabel.TextColor3 = Color3.fromRGB(80, 50, 0)
    luckyLabel.TextScaled = true
    luckyLabel.Font = Enum.Font.GothamBold
    luckyLabel.Parent = luckyHourBannerFrame

    local luckyCountdown = Instance.new("TextLabel")
    luckyCountdown.Name = "LuckyCountdown"
    luckyCountdown.Size = UDim2.new(1, -10, 0, 18)
    luckyCountdown.Position = UDim2.new(0, 5, 0, 28)
    luckyCountdown.BackgroundTransparency = 1
    luckyCountdown.Text = ""
    luckyCountdown.TextColor3 = Color3.fromRGB(100, 70, 0)
    luckyCountdown.TextScaled = true
    luckyCountdown.Font = Enum.Font.Gotham
    luckyCountdown.Parent = luckyHourBannerFrame
end
```

**Lucky Hour banner show/hide:**

```luau
local function showLuckyHourBanner()
    if not luckyHourBannerFrame then return end

    -- Position below weather banner (or at top if no weather active)
    local targetY = 10
    if currentWeather ~= "Clear" then
        targetY = 100  -- below weather banner
    end

    local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(luckyHourBannerFrame, tweenInfo, {
        Position = UDim2.new(0.325, 0, 0, targetY)
    }):Play()
end

local function hideLuckyHourBanner()
    if not luckyHourBannerFrame then return end
    local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    TweenService:Create(luckyHourBannerFrame, tweenInfo, {
        Position = UDim2.new(0.325, 0, 0, -60)
    }):Play()
end
```

**Lucky Hour remote listeners (in `WeatherUI.init()`):**

```luau
Remotes.LuckyHourStarted.OnClientEvent:Connect(function(data)
    isLuckyHourActive = true
    luckyHourEndTime = data.endTime
    showLuckyHourBanner()
end)

Remotes.LuckyHourEnded.OnClientEvent:Connect(function()
    isLuckyHourActive = false
    luckyHourEndTime = 0
    hideLuckyHourBanner()
end)
```

**Lucky Hour countdown (add to existing `updateCountdown()` RenderStepped handler):**

```luau
-- Add at the end of the existing updateCountdown function:
if isLuckyHourActive and luckyHourEndTime > 0 then
    local luckyRemaining = math.max(0, math.ceil(luckyHourEndTime - os.clock()))
    local luckyCountdownLabel = luckyHourBannerFrame and luckyHourBannerFrame:FindFirstChild("LuckyCountdown")
    if luckyCountdownLabel then
        if luckyRemaining > 0 then
            local minutes = math.floor(luckyRemaining / 60)
            local seconds = luckyRemaining % 60
            luckyCountdownLabel.Text = string.format("%d:%02d remaining", minutes, seconds)
        else
            luckyCountdownLabel.Text = "Ending..."
        end
    end
end
```

---

### 4.13 `src/server/init.server.luau` (MODIFY)

**What changes:** Add LuckyHourService to the server boot sequence. It must be initialized after WeatherService (since it is independent but follows the established boot order pattern).

**Add require:**

```luau
local LuckyHourService = require(script.Services.LuckyHourService)
```

**Add init call (after WeatherService.init):**

```luau
LuckyHourService.init()
```

**Expected boot order (Phase 8):**

```luau
DataService.init()
EarningsService.init()
BaseService.init()
FoodService.init()
SellService.init()           -- Phase 5
WeatherService.init()        -- Phase 6
IndexService.init()          -- Phase 7
GiftService.init()           -- Phase 7
LeaderboardService.init()    -- Phase 7
LuckyHourService.init()      -- Phase 8 (NEW)
```

---

### 4.14 `src/client/init.client.luau` (MODIFY)

**What changes:** Add FusionUI to the client boot sequence.

**Add require:**

```luau
local FusionUI = require(script.Controllers.FusionUI)
```

**Add init call:**

```luau
FusionUI.init()
```

**Expected boot order (Phase 8):**

```luau
MoneyUI.init()
BaseUI.init()
FoodStoreUI.init()
SellUI.init()                -- Phase 5
WeatherUI.init()             -- Phase 6
IndexUI.init()               -- Phase 7
LeaderboardUI.init()         -- Phase 7
FusionUI.init()              -- Phase 8 (NEW)
```

---

## 5. Module Contracts

### New Cross-Module Dependencies (Phase 8)

**Config/Personalities requires:**

| Module | Function/Field Used | Purpose |
|---|---|---|
| (none) | N/A | Pure data module with zero dependencies |

**LuckyHourService requires:**

| Module | Function/Field Used | Purpose |
|---|---|---|
| `Remotes` | `Remotes.LuckyHourStarted` | Fire to all clients when Lucky Hour starts |
| `Remotes` | `Remotes.LuckyHourEnded` | Fire to all clients when Lucky Hour ends |

**FoodService now additionally requires:**

| Module | Function/Field Used | Purpose |
|---|---|---|
| `Config/Personalities` | `Personalities.rollPersonality()` | Roll personality on brainrot spawn |
| `Config/Personalities` | `Personalities.getEarningsMultiplier(personality)` | Factor personality into initial earnings computation |
| `LuckyHourService` | `LuckyHourService.getRarityBoost()` | Get rarity weight multiplier for food purchase |
| `Config/Foods` | `Foods.VIP_EVENT_ACTIVE` | Check if VIP food is available |
| `Remotes` | `Remotes.FuseBrainrots` | Listen for fusion requests from client |
| `Remotes` | `Remotes.FuseResult` | Fire fusion result to client |
| `Config/Brainrots` | `Brainrots.BRAINROTS_BY_RARITY` | Roll random brainrot from next tier during fusion |
| `IndexService` | `IndexService.registerDiscovery()` | Register fused brainrot discovery |

**EarningsService now additionally requires:**

| Module | Function/Field Used | Purpose |
|---|---|---|
| `Config/Personalities` | `Personalities.getEarningsMultiplier(personality)` | 5th factor in earnings formula |

**FusionUI requires:**

| Module | Function/Field Used | Purpose |
|---|---|---|
| `Config/Foods` | `Foods.RARITY_ORDER` | Determine next rarity tier for preview |
| `Config/Brainrots` | (display data) | Brainrot names and rarity colors |
| `Remotes` | `Remotes.FuseBrainrots` | Fire fusion request to server |
| `Remotes` | `Remotes.FuseResult` | Listen for fusion results |
| `Remotes` | `Remotes.BrainrotSpawned` | Listen for brainrot updates (refresh list) |

**BaseUI now additionally requires:**

| Module | Function/Field Used | Purpose |
|---|---|---|
| `Config/Personalities` | `Personalities.get(name)` | Look up personality color for BillboardGui |
| `Config/Personalities` | `Personalities.getAnimationSpeed(name)` | Adjust idle bob speed per personality |
| `FusionUI` | `FusionUI.open(brainrots)` | Open fusion panel from base UI button |

**FoodStoreUI now additionally requires:**

| Module | Function/Field Used | Purpose |
|---|---|---|
| `Config/Personalities` | `Personalities.get(name)` | Show personality info in spawn reveal |
| `Config/Foods` | `Foods.VIP_EVENT_ACTIVE` | Determine whether to show VIP food entries |
| `Remotes` | `Remotes.LuckyHourStarted` | Show Lucky Hour indicator |
| `Remotes` | `Remotes.LuckyHourEnded` | Hide Lucky Hour indicator |

**WeatherUI now additionally requires:**

| Module | Function/Field Used | Purpose |
|---|---|---|
| `Remotes` | `Remotes.LuckyHourStarted` | Show Lucky Hour golden banner |
| `Remotes` | `Remotes.LuckyHourEnded` | Hide Lucky Hour golden banner |

### Existing Contracts (Unchanged)

- LuckyHourService does NOT modify any player data. It only provides `isActive()` and `getRarityBoost()` queries for FoodService.
- FoodService handles all fusion server-side logic including validation, brainrot removal, new brainrot creation, and earnings recalculation.
- Fusion does NOT preserve any properties from the 3 input brainrots -- the output is freshly rolled.
- VIP food is gated by `Foods.VIP_EVENT_ACTIVE` on both server (FoodService validation) and client (FoodStoreUI display).
- Personality is permanent once assigned -- no service or remote can change a brainrot's personality.
- WeatherService, SellService, GiftService, IndexService, BaseService, and LeaderboardService are not modified in Phase 8.

---

## 6. Agent Task Breakdown

Tasks are organized into steps. Steps must be completed in order. Tasks within a step can be done in parallel.

### Step 1 (Parallel -- no inter-dependencies)

| Task | File | Action | Est. Lines |
|---|---|---|---|
| 1.1 | `src/shared/Config/Personalities.luau` | CREATE | ~100 |
| 1.2 | `src/shared/Config/Foods.luau` | MODIFY | ~40 |
| 1.3 | `src/server/Remotes/init.luau` | MODIFY | ~20 |
| 1.4 | `src/shared/Types.luau` | VERIFY | ~2 |

- **1.1 Config/Personalities.luau:** Create the complete Personalities config module with `PERSONALITIES` table (4 entries), `PERSONALITY_ORDER`, and utility functions (`get`, `getEarningsMultiplier`, `getAnimationSpeed`, `rollPersonality`).
- **1.2 Config/Foods.luau:** Add `VIP_EVENT_ACTIVE` flag, add 3 VIP food entries, add `isVIP = false` and `guaranteedMinRarity = nil` defaults to existing entries, export `VIP_EVENT_ACTIVE`.
- **1.3 Remotes/init.luau:** Add `FuseBrainrots`, `FuseResult`, `LuckyHourStarted`, `LuckyHourEnded`, and `TutorialComplete` RemoteEvent instances. Include them in the returned table.
- **1.4 Types.luau:** Verify `personality: string?` exists on BrainrotInstance type. Add if missing.

### Step 2 (Depends on Step 1)

| Task | File | Action | Est. Lines |
|---|---|---|---|
| 2.1 | `src/server/Services/LuckyHourService.luau` | CREATE | ~100 |
| 2.2 | `src/server/Services/EarningsService.luau` | MODIFY | ~10 |
| 2.3 | `src/server/Services/DataService.luau` | MODIFY | ~5 |

- **2.1 LuckyHourService.luau:** Create the complete Lucky Hour service with `init()`, `luckyHourCycle()`, `startLuckyHour()`, `endLuckyHour()`, `isActive()`, `getRarityBoost()`, `getEndTime()`, and `PlayerAdded` handler for late joiners.
- **2.2 EarningsService.luau:** Add `require` for `Config/Personalities`. Add `Personalities.getEarningsMultiplier(brainrot.personality)` as 5th factor in `recalculate()`.
- **2.3 DataService.luau:** Add `tutorialComplete = false` to default PlayerData template.

### Step 3 (Depends on Step 2)

| Task | File | Action | Est. Lines |
|---|---|---|---|
| 3.1 | `src/server/Services/FoodService.luau` | MODIFY | ~200 |

- **3.1 FoodService.luau:** Add personality roll on spawn. Add `getRarityWeightsForFood()` with Lucky Hour boosting. Add VIP food validation. Add complete `handleFuseBrainrots()` function. Connect `FuseBrainrots` remote. This task is sequential because it depends on both LuckyHourService and Personalities config.

### Step 4 (Parallel, depends on Step 3)

| Task | File | Action | Est. Lines |
|---|---|---|---|
| 4.1 | `src/client/Controllers/FusionUI.luau` | CREATE | ~350 |
| 4.2 | `src/client/Controllers/BaseUI.luau` | MODIFY | ~100 |
| 4.3 | `src/client/Controllers/FoodStoreUI.luau` | MODIFY | ~60 |
| 4.4 | `src/client/Controllers/WeatherUI.luau` | MODIFY | ~100 |

- **4.1 FusionUI.luau:** Create the complete client-side fusion controller with: panel UI creation, eligible fusion list population, fusion entry creation with rarity preview, fuse button handler, result/error display, open/close/refresh logic.
- **4.2 BaseUI.luau:** Add personality label to BillboardGui. Add personality-based idle animation speed scaling via `startIdleBob()`. Add Fusion button to base HUD. Update `spawnBrainrotVisual()` to handle personality on load.
- **4.3 FoodStoreUI.luau:** Add personality text to spawn reveal. Add VIP food display gating. Add Lucky Hour indicator label with `LuckyHourStarted`/`LuckyHourEnded` listeners.
- **4.4 WeatherUI.luau:** Create Lucky Hour golden banner. Add show/hide/countdown logic. Add `LuckyHourStarted`/`LuckyHourEnded` listeners. Integrate countdown into existing RenderStepped handler.

### Step 5 (Depends on Steps 3 and 4)

| Task | File | Action | Est. Lines Changed |
|---|---|---|---|
| 5.1 | `src/server/init.server.luau` | MODIFY | ~3 |
| 5.2 | `src/client/init.client.luau` | MODIFY | ~3 |

- **5.1 init.server.luau:** Add `require` for LuckyHourService and call `LuckyHourService.init()` after LeaderboardService in the boot order.
- **5.2 init.client.luau:** Add `require` for FusionUI and call `FusionUI.init()` after LeaderboardUI in the boot order.

### Task Dependency Diagram

```
Step 1 (parallel):
  1.1 Config/Personalities.luau (CREATE) -------+
  1.2 Config/Foods.luau (MODIFY) ---------------+
  1.3 Remotes/init.luau (MODIFY) ---------------+
  1.4 Types.luau (VERIFY) ----------------------+
         |
         v
Step 2 (parallel):
  2.1 LuckyHourService.luau (CREATE) -----------+
  2.2 EarningsService.luau (MODIFY) ------------+
  2.3 DataService.luau (MODIFY) ----------------+
         |
         v
Step 3 (sequential):
  3.1 FoodService.luau (MODIFY) ----------------+
         |
         v
Step 4 (parallel):
  4.1 FusionUI.luau (CREATE) -------------------+
  4.2 BaseUI.luau (MODIFY) ---------------------+
  4.3 FoodStoreUI.luau (MODIFY) ----------------+
  4.4 WeatherUI.luau (MODIFY) ------------------+
         |
         v
Step 5 (parallel):
  5.1 init.server.luau (MODIFY) ----------------+
  5.2 init.client.luau (MODIFY) ----------------+
```

### Total: 3 new files, 11 modified files, ~1,100 estimated lines of new/changed Luau code.

---

## 7. Data Structures

### 7.1 Personality Config Table Shape

```luau
-- Return value of require(Config.Personalities):
{
    PERSONALITIES = {
        Lazy = { earningsMultiplier = 0.9, animationSpeed = 0.6, spawnWeight = 25, color = Color3, emoji = "...", description = "..." },
        Chill = { earningsMultiplier = 1.0, animationSpeed = 0.85, spawnWeight = 25, color = Color3, emoji = "...", description = "..." },
        Grumpy = { earningsMultiplier = 0.95, animationSpeed = 0.9, spawnWeight = 25, color = Color3, emoji = "...", description = "..." },
        Hyper = { earningsMultiplier = 1.2, animationSpeed = 1.5, spawnWeight = 25, color = Color3, emoji = "...", description = "..." },
    },
    PERSONALITY_ORDER = { "Lazy", "Chill", "Grumpy", "Hyper" },
    get = function,                     -- (string) -> PersonalityConfig?
    getEarningsMultiplier = function,   -- (string?) -> number
    getAnimationSpeed = function,       -- (string?) -> number
    rollPersonality = function,         -- () -> string
}
```

### 7.2 VIP Food Config Entry Shape

```luau
{
    name = "Legendary VIP Food",
    cost = 500000,
    maxRarity = "Mythic",
    stayChance = 0.35,
    isVIP = true,
    guaranteedMinRarity = "Legendary",
    rarityWeights = { Legendary = 60, Mythic = 30, Goldy = 10 },
    description = "VIP-tier food that guarantees at least a Legendary brainrot.",
}
```

### 7.3 FuseBrainrots Remote Payload Shape

```luau
-- Client -> Server
{
    brainrotName = "Burbaloni Lulilolli",  -- string: name of brainrot to fuse (server finds 3 matching)
}
```

### 7.4 FuseResult Remote Payload Shape

```luau
-- Server -> Client (success)
{
    success = true,
    newBrainrot = {                         -- BrainrotInstance
        id = "a1b2c3d4...",
        name = "Frigo Camelo",
        rarity = "Rare",
        size = 1.35,
        sizeLabel = "Medium",
        weight = 432.0,
        baseMutation = nil,
        weatherMutation = nil,
        personality = "Hyper",
        earningsPerSec = 81.0,              -- 50 * 1.35 * 1.0 * 1.0 * 1.2
    },
}

-- Server -> Client (failure)
{
    success = false,
    errorMessage = "Need 3x Burbaloni Lulilolli, but only have 2.",
}
```

### 7.5 LuckyHourStarted Remote Payload Shape

```luau
{
    duration = 300,               -- number: total Lucky Hour duration in seconds
    endTime = 1234567.89,         -- number: os.clock() timestamp when Lucky Hour ends
}
```

### 7.6 LuckyHourEnded Remote Payload Shape

```luau
{}  -- empty table, no payload needed
```

### 7.7 Updated BrainrotInstance (Phase 8 shape)

After Phase 8, the `personality` field is now populated on all newly spawned brainrots.

```luau
-- Example: A Gold Large Hyper Epic brainrot with Soaked weather mutation
{
    id = "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6",
    name = "Tralalero Tralala",
    rarity = "Epic",
    size = 2.10,
    sizeLabel = "Large",
    weight = 945.0,
    baseMutation = "Gold",
    weatherMutation = "Soaked",
    personality = "Hyper",               -- NEW: populated in Phase 8
    earningsPerSec = 7087.50,           -- 1250 * 2.10 * 1.5 * 1.5 * 1.2 = 7087.50
}

-- Example: A Lazy Common brainrot (worst case)
{
    id = "1234567890abcdef1234567890abcdef",
    name = "Hipocactus",
    rarity = "Common",
    size = 0.50,
    sizeLabel = "Tiny",
    weight = 42.5,
    baseMutation = nil,
    weatherMutation = nil,
    personality = "Lazy",
    earningsPerSec = 2.25,              -- 5 * 0.50 * 1.0 * 1.0 * 0.9 = 2.25
}

-- Example: Fusion result -- Massive Rainbow Hyper Goldy brainrot
{
    id = "f9e8d7c6b5a4f3e2d1c0b9a8f7e6d5c4",
    name = "Lirili Larila",
    rarity = "Goldy",
    size = 2.87,
    sizeLabel = "Massive",
    weight = 7175.0,
    baseMutation = "Rainbow",
    weatherMutation = nil,               -- freshly fused, no weather mutation yet
    personality = "Hyper",
    earningsPerSec = 12870000.0,         -- 750000 * 2.87 * 5.0 * 1.0 * 1.2 = 12,915,000
}

-- Example: Pre-existing brainrot from Phase 7 (personality = nil until re-rolled or kept nil)
{
    id = "aaaa1111bbbb2222cccc3333dddd4444",
    name = "Bobrito Bandito",
    rarity = "Common",
    size = 1.0,
    sizeLabel = "Medium",
    weight = 8.0,
    baseMutation = nil,
    weatherMutation = nil,
    personality = nil,                   -- nil for brainrots spawned before Phase 8
    earningsPerSec = 5.0,               -- 5 * 1.0 * 1.0 * 1.0 * 1.0 (nil personality = 1.0x)
}
```

### 7.8 Full Earnings Formula (Phase 8)

```
earningsPerSec = baseEarnings * sizeMult * baseMutationMult * weatherMutationMult * personalityMult
```

| Factor | Source | Phase 8 Range |
|---|---|---|
| `baseEarnings` | `Config/Brainrots` (varies by rarity) | $5 to $50,000,000 |
| `sizeMult` | `brainrot.size` (continuous value from Phase 3) | 0.5x to 3.0x |
| `baseMutationMult` | `Config/Mutations` (None/Gold/Diamond/Rainbow) | 1.0x to 5.0x |
| `weatherMutationMult` | `Config/Mutations` (None/Soaked/Frozen/.../Gravitated) | 1.0x to 100.0x |
| `personalityMult` | `Config/Personalities` (Lazy/Chill/Grumpy/Hyper/nil) | 0.9x to 1.2x |

**Phase 8 effective range:** 0.45x to 1,800.0x multiplier on base earnings (Massive 3.0 * Rainbow 5.0 * Gravitated 100.0 * Hyper 1.2 = 1,800.0x max).

**Theoretical maximum earningsPerSec:** $50,000,000 * 3.0 * 5.0 * 100.0 * 1.2 = **$90,000,000,000/sec** (Massive Rainbow Gravitated Hyper Unknown rarity brainrot).

**Theoretical minimum earningsPerSec:** $5 * 0.5 * 1.0 * 1.0 * 0.9 = **$2.25/sec** (Tiny Common no-mutation no-weather-mutation Lazy brainrot).

### 7.9 Personality Distribution Table

| Personality | Spawn Weight | Probability | Earnings Multiplier | Animation Speed |
|---|---|---|---|---|
| Lazy | 25 | 25.0% | 0.9x (-10%) | 0.6x (slow) |
| Chill | 25 | 25.0% | 1.0x (neutral) | 0.85x (relaxed) |
| Grumpy | 25 | 25.0% | 0.95x (-5%) | 0.9x (slightly slow) |
| Hyper | 25 | 25.0% | 1.2x (+20%) | 1.5x (fast) |
| **Total** | **100** | **100%** | | |

### 7.10 Fusion Rarity Progression Table

| Input Rarity | Count Required | Output Rarity | # Possible Output Brainrots |
|---|---|---|---|
| Common | 3x same name | Rare | 4 (Frigo Camelo, Blueberrinni Octopussini, Orangutini Ananasini, Tigrrullini Watermellini) |
| Rare | 3x same name | Epic | 4 (Boneca Ambalabu, Chef Crabracadabra, Glorbo Fruttodrillo, Tralalero Tralala) |
| Epic | 3x same name | Legendary | 3 (Shpioniro Golubiro, Ballerina Cappuccina, Bombombini Gusini) |
| Legendary | 3x same name | Mythic | 3 (Chimpanzini Bananini, Brr Brr Patapim, Cappuccino Assassino) |
| Mythic | 3x same name | Goldy | 2 (Lirili Larila, Bombardiro Crocodilo) |
| Goldy | 3x same name | Secret | 2 (Tung Tung Tung Sahur, Trippi Troppi) |
| Secret | 3x same name | Unknown | 2 (Centralucci Nuclearucci, La Vaca Saturno Saturnita) |
| Unknown | **Cannot be fused** | -- | -- |

### 7.11 Lucky Hour Rarity Weight Boost Example

Given "Epic Eats" food tier with original `rarityWeights`:

```
Original:   { Common = 50, Rare = 30, Epic = 15, Legendary = 5 }  (total = 100)
Lucky Hour: { Common = 50, Rare = 60, Epic = 30, Legendary = 10 } (total = 150)

Original probabilities:    Common 50%, Rare 30%, Epic 15%, Legendary 5%
Lucky Hour probabilities:  Common 33%, Rare 40%, Epic 20%, Legendary 7%
```

The Common share drops from 50% to 33% while all rare+ shares increase proportionally.

### 7.12 VIP Food Summary Table

| VIP Food | Cost | Guaranteed Min Rarity | Rarity Weights | Stay Chance |
|---|---|---|---|---|
| Legendary VIP Food | $500,000 | Legendary | Legendary 60, Mythic 30, Goldy 10 | 35% |
| Mythic VIP Food | $5,000,000 | Mythic | Mythic 55, Goldy 35, Secret 10 | 28% |
| Secret VIP Food | $500,000,000 | Secret | Secret 60, Unknown 40 | 18% |

---

## 8. Testing Criteria

After all files are written, verify the following. Every test must pass.

### Build Test

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T1 | `rojo build` succeeds | Run `rojo build -o "collect-brainrots.rbxlx"` | Exits with code 0, no errors. |

### Personality Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T2 | Every new brainrot spawns with a personality | Buy food 10+ times; inspect spawned brainrots | Every brainrot has a non-nil `personality` field ("Lazy", "Chill", "Grumpy", or "Hyper"). |
| T3 | Personality distribution is approximately 25% each | Buy food 40+ times; tally personality counts | Each personality appears roughly 10 times (within reasonable variance). |
| T4 | Personality affects earnings | Compare a Hyper brainrot to an identical Chill brainrot (same name, size, mutation) | Hyper earns 1.2x what Chill earns. |
| T5 | Lazy personality reduces earnings by 10% | Inspect a Lazy brainrot's earningsPerSec | Equals `baseEarnings * sizeMult * baseMutMult * weatherMutMult * 0.9`. |
| T6 | Grumpy personality reduces earnings by 5% | Inspect a Grumpy brainrot's earningsPerSec | Equals `baseEarnings * sizeMult * baseMutMult * weatherMutMult * 0.95`. |
| T7 | Personality shows in BillboardGui | Look at any brainrot's overhead label | Personality name appears below the main label, colored appropriately. |
| T8 | Personality shows in spawn reveal | Buy food and observe the reveal message | Personality name is included in the reveal text (e.g., "[Hyper]"). |
| T9 | Personality affects idle animation speed | Observe a Hyper brainrot and a Lazy brainrot side by side | Hyper bobs/moves noticeably faster than Lazy. |
| T10 | Personality persists in save data | Get a Hyper brainrot, leave, rejoin | The brainrot still has `personality = "Hyper"` after rejoin. |
| T11 | Pre-Phase-8 brainrots have nil personality and earn at 1.0x | Load a save with brainrots spawned before Phase 8 | `personality` is `nil`; earnings unchanged (1.0x personality multiplier). |

### Fusion Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T12 | Fusion button appears on base HUD | Open base UI | A "FUSION" button is visible. |
| T13 | Fusion UI shows eligible groups | Have 3+ of the same brainrot; open Fusion UI | The brainrot name appears in the list with count and "FUSE" button. |
| T14 | Fusion UI hides ineligible groups | Have 2 of one brainrot and 4 of another | Only the one with 4 appears; the one with 2 does not. |
| T15 | Unknown brainrots do not appear in Fusion UI | Have 3+ Unknown brainrots | They do not appear in the fusion list. |
| T16 | Fusing 3 Common brainrots produces 1 Rare | Have 3x same Common; click FUSE | 3 Commons are removed; 1 Rare brainrot is added to base. |
| T17 | Fused brainrot has fresh properties | Fuse 3 brainrots; inspect result | Result has newly rolled size, base mutation, personality (not inherited from inputs). |
| T18 | Fused brainrot is a random brainrot from the next rarity tier | Fuse repeatedly; observe output names | Output brainrot names vary among all brainrots of the next tier. |
| T19 | Fusion updates capacity display | Note capacity before and after fusion (e.g., 5/10) | Capacity decreases by net 2 (remove 3, add 1, so 3/10). |
| T20 | Fusion updates earnings | Note total earnings before and after fusion | Earnings change to reflect removal of 3 brainrots and addition of 1 new one. |
| T21 | Cannot fuse with fewer than 3 | Try to fuse when you have only 2 of a brainrot (via network exploit) | Server returns error: "Need 3x ..., but only have 2." |
| T22 | Fusion result shows in FusionUI | Complete a successful fusion | Result panel appears showing the new brainrot's name, rarity, and earnings. |
| T23 | Fusion registers discovery in codex | Fuse to get a brainrot you never had before; check codex | The new brainrot appears as discovered in the index. |
| T24 | Fusion result brainrot appears on base | Complete a fusion | The new brainrot model appears on the player's plot. |

### Lucky Hour Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T25 | Lucky Hours trigger periodically | Wait 30-60 minutes (or use test script to speed up interval) | A Lucky Hour starts with golden banner and countdown. |
| T26 | Lucky Hour lasts 5 minutes | Time a Lucky Hour from start to end | Lucky Hour ends after exactly 300 seconds. |
| T27 | Golden banner appears during Lucky Hour | Observe screen when Lucky Hour starts | Golden banner slides down showing "LUCKY HOUR! 2x Rare Spawns!" with countdown. |
| T28 | Golden banner hides when Lucky Hour ends | Wait for Lucky Hour to finish | Banner slides up offscreen. |
| T29 | Lucky Hour countdown updates | Watch the countdown during Lucky Hour | Countdown decrements every second (e.g., "4:59 remaining"). |
| T30 | Rarity weights are boosted during Lucky Hour | Buy food 20+ times during Lucky Hour; compare to 20+ purchases outside Lucky Hour | Noticeably more rare+ brainrots appear during Lucky Hour. |
| T31 | Common weight is NOT boosted | Inspect effective weights during Lucky Hour | Common rarity weight remains unchanged; only non-Common weights are doubled. |
| T32 | Late joiners see active Lucky Hour | Join mid-Lucky-Hour | Golden banner appears immediately with correct remaining time. |
| T33 | Lucky Hour and weather can coexist | Trigger Lucky Hour during a weather event | Both banners display simultaneously (weather banner on top, lucky hour below). |
| T34 | Lucky Hour indicator shows in food store | Open food store during Lucky Hour | "LUCKY HOUR ACTIVE! 2x Rare Spawns!" indicator visible at top of food store. |

### VIP Food Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T35 | VIP food entries exist in config | Read `Config/Foods.luau` | 3 VIP food entries with `isVIP = true` and `guaranteedMinRarity` fields. |
| T36 | VIP food not shown when event is inactive | Open food store with `VIP_EVENT_ACTIVE = false` | VIP food entries do not appear in the food store list. |
| T37 | VIP food shown when event is active | Set `VIP_EVENT_ACTIVE = true`; open food store | VIP food entries appear with VIP badge/indicator. |
| T38 | VIP food only rolls guaranteed minimum rarity or above | Set event active; buy "Legendary VIP Food" 10 times | All rolled brainrots are Legendary, Mythic, or Goldy (never Common/Rare/Epic). |
| T39 | VIP food still respects stay chance | Buy VIP food multiple times | Some brainrots run away (stay chance is not 100%). |
| T40 | VIP food costs more than regular equivalent | Compare VIP food cost to regular food of same tier | VIP food costs approximately 10x the regular food. |
| T41 | Server rejects VIP food purchase when event inactive | Attempt to buy VIP food via network exploit when `VIP_EVENT_ACTIVE = false` | Server rejects purchase; no brainrot spawns. |

### Earnings Integration Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T42 | 5-factor earnings formula works correctly | Spawn a brainrot with known values; verify math | `earningsPerSec = baseEarnings * sizeMult * baseMutMult * weatherMutMult * personalityMult` matches manual calculation. |
| T43 | Total earnings display is accurate | Have 5+ brainrots with various personalities; check MoneyUI | Total earnings/sec equals sum of all individual brainrot earningsPerSec values. |
| T44 | Earnings recalculate after fusion | Fuse 3 brainrots; check total earnings | Total earnings reflects removal of 3 and addition of 1 new brainrot. |

### Console Cleanliness Test

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T45 | No errors in console | Check Studio Output for red error text during all Phase 8 feature usage | Zero errors. |

### Performance Test

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T46 | No lag during Lucky Hour with food purchases | Buy food rapidly during Lucky Hour | No noticeable frame drops or server lag. |
| T47 | Fusion completes quickly | Fuse brainrots with 30 brainrots on base | Fusion completes in under 1 second; no perceivable delay. |
| T48 | Personality system adds no measurable overhead | Compare FPS with 30 brainrots (personalities active) vs. Phase 7 baseline | FPS is comparable; no regression. |

### Regression Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T49 | Weather system still works | Observe weather events during gameplay | Weather events trigger, banners show, mutations apply, music transitions all work. |
| T50 | Sell system still works | Sell a brainrot with personality | Sell value is correct; brainrot is removed; money is added. |
| T51 | Gifting still works | Gift a brainrot with personality to another player | Brainrot transfers correctly with personality preserved. |
| T52 | Codex/index still works | Open codex; verify entries | All discovered brainrots display correctly including fused ones. |
| T53 | Base capacity upgrades still work | Buy a capacity upgrade | Capacity increases; cost is correct. |

---

## 9. Acceptance Criteria

All of the following must be true before Phase 8 is considered complete:

| # | Criterion | How to Verify |
|---|---|---|
| 1 | `rojo build` succeeds without errors | Run `rojo build -o "collect-brainrots.rbxlx"` |
| 2 | `Config/Personalities.luau` exists with 4 personality entries and utility functions | Read the file and verify Lazy (0.9x), Chill (1.0x), Grumpy (0.95x), Hyper (1.2x) |
| 3 | Every new brainrot spawns with a personality (25% each) | Buy food 20+ times and tally personalities |
| 4 | Personality multiplier is the 5th factor in the earnings formula | Verify `EarningsService.recalculate()` includes `Personalities.getEarningsMultiplier()` |
| 5 | Personality is displayed in BillboardGui with personality-specific color | Visual check on any brainrot |
| 6 | Personality is included in the spawn reveal message | Buy food and observe reveal text |
| 7 | Personality affects idle animation speed (Lazy=slow, Hyper=fast) | Visual comparison of different-personality brainrots |
| 8 | Personality persists across sessions (save/load) | Rejoin and verify personality fields |
| 9 | Pre-Phase-8 brainrots with `personality = nil` work correctly at 1.0x | Load old save data; verify earnings unchanged |
| 10 | Fusion button is accessible from the base UI | Visual check |
| 11 | Fusion UI shows all eligible groups (3+ same name, not Unknown) | Open Fusion UI with qualifying brainrots |
| 12 | Fusing 3 same-name brainrots produces 1 random next-rarity brainrot | Complete a fusion and verify rarity progression |
| 13 | Fused brainrot has freshly rolled size, base mutation, and personality | Inspect fusion result |
| 14 | Unknown-tier brainrots cannot be fused | Attempt to fuse Unknown brainrots; server rejects |
| 15 | Fusion updates capacity, earnings, codex, and base visual | Verify all side effects after fusion |
| 16 | Lucky Hours trigger randomly every 30-60 minutes and last 5 minutes | Observe timing over extended play session |
| 17 | Golden Lucky Hour banner appears with countdown during Lucky Hour | Visual check |
| 18 | Rarity weights are boosted during Lucky Hour (rare+ doubled, Common unchanged) | Statistical comparison of food purchases during vs. outside Lucky Hour |
| 19 | Lucky Hour indicator shows in food store during active Lucky Hour | Visual check |
| 20 | Late-joining players see active Lucky Hour state | Join mid-Lucky-Hour |
| 21 | VIP food config entries exist with `isVIP = true` and `guaranteedMinRarity` | Read `Config/Foods.luau` |
| 22 | VIP food is hidden in food store when `VIP_EVENT_ACTIVE = false` | Visual check with flag off |
| 23 | VIP food is shown and purchasable when `VIP_EVENT_ACTIVE = true` | Set flag on; buy VIP food |
| 24 | VIP food only rolls brainrots at or above guaranteed minimum rarity | Buy VIP food 10+ times; verify results |
| 25 | Server rejects VIP food purchases when event is inactive | Network exploit test |
| 26 | `DataService` default template includes `tutorialComplete = false` | Read the file |
| 27 | All 5 remotes are registered (FuseBrainrots, FuseResult, LuckyHourStarted, LuckyHourEnded, TutorialComplete) | Read `Remotes/init.luau` |
| 28 | No errors or warnings in Studio Output console | Check for red/yellow text during all feature usage |
| 29 | No performance regression compared to Phase 7 | FPS comparison with 30 brainrots |
| 30 | All Phase 7 functionality still works (gifting, codex, leaderboards, weather, sell, upgrades) | Regression testing |

---

## Appendix A: Fusion Probability Verification

To verify fusion is working correctly, the following test methodology is recommended:

1. **Automated test:** Temporarily add a server-side test that performs 100 fusions and tallies results:
   ```luau
   -- Give test player 300 of the same Common brainrot
   -- Fuse all 300 in groups of 3 (100 fusions)
   -- Tally: how many of each Rare brainrot were produced?
   local results = {}
   for i = 1, 100 do
       -- perform fusion
       results[newBrainrot.name] = (results[newBrainrot.name] or 0) + 1
   end
   print("Fusion distribution (100 fusions):")
   for name, count in results do
       print(string.format("  %s: %d (%.1f%%)", name, count, count))
   end
   ```

2. **Expected output (approximately):**
   ```
   Fusion distribution (100 fusions):
     Frigo Camelo: 25 (25.0%)
     Blueberrinni Octopussini: 25 (25.0%)
     Orangutini Ananasini: 25 (25.0%)
     Tigrrullini Watermellini: 25 (25.0%)
   ```
   Each Rare brainrot should appear roughly equally (uniform random selection within the tier).

## Appendix B: Lucky Hour Rarity Shift Verification

To verify the Lucky Hour rarity boost is applied correctly:

1. **Automated test:** Temporarily add a test that rolls 10,000 brainrots from the same food tier, once with Lucky Hour off and once with Lucky Hour on:
   ```luau
   -- Without Lucky Hour:
   local normalCounts = { Common = 0, Rare = 0, Epic = 0 }
   for i = 1, 10000 do
       local result = rollBrainrotFromFood(epicEatsConfig, 1.0)  -- boost = 1.0
       normalCounts[result.rarity] += 1
   end

   -- With Lucky Hour:
   local boostedCounts = { Common = 0, Rare = 0, Epic = 0 }
   for i = 1, 10000 do
       local result = rollBrainrotFromFood(epicEatsConfig, 2.0)  -- boost = 2.0
       boostedCounts[result.rarity] += 1
   end

   print("Normal distribution:", normalCounts)
   print("Boosted distribution:", boostedCounts)
   ```

2. **Expected:** Rare+ shares approximately double their normal percentage; Common share decreases proportionally.

## Appendix C: Backward Compatibility

Brainrots spawned before Phase 8 will have `personality = nil`. The system handles this gracefully:

- `Personalities.getEarningsMultiplier(nil)` returns `1.0` (no effect on earnings).
- `Personalities.getAnimationSpeed(nil)` returns `1.0` (default animation speed).
- BillboardGui does not show a personality label when `personality` is `nil`.
- FoodStoreUI spawn reveal does not show personality text when `personality` is `nil`.

No data migration is needed. ProfileStore schema reconciliation handles the new `tutorialComplete` field automatically.
