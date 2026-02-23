# Phase 9: Map, Multiplayer, Tutorial, Sound, and Polish

> **Status:** NOT STARTED
> **Depends on:** Phase 8 (Fusion, Personalities, Lucky Hour, TutorialComplete remote, all core systems complete)
> **Blocks:** None (final phase)

---

## 1. Objective

Final phase: expand the single-plot test map into a full 6-plot multiplayer map, implement rival base visibility (other players' brainrots rendered on their plots as view-only), build the guided tutorial system for first-time players, add sound effects and music transitions across the entire game, and perform a final balancing pass on all economic numbers.

By the end of this phase:
- The game world contains 6 distinct plot positions spread across the map. When a player joins, they are assigned the first available plot.
- Each plot is a platform Part with fencing (from Phase 5). Players can walk around the map and see all 6 bases.
- Rival bases: other players' brainrots are visible on their plots (replicated via server) but cannot be interacted with -- view-only.
- A step-by-step tutorial guides first-time players through the core game loop (buying food, getting a brainrot, understanding earnings). The tutorial is skippable and marks `tutorialComplete = true` in PlayerData when finished.
- Sound effects play for every major game event (buying food, brainrot spawned, brainrot ran away, mutations, weather, capacity upgrades, selling, codex discoveries, Lucky Hour).
- The music system from Phase 6 is polished with smoother crossfades, multiple tracks per mood, and volume controls.
- A final balancing pass reviews all economic numbers (food costs, earnings rates, weather frequency, capacity upgrade costs, sell values) with documented adjustments.

---

## 2. Prerequisites

Phase 8 must be fully complete and tested before starting Phase 9. Specifically:

- `src/server/Services/FoodService.luau` handles brainrot fusion (3 same-name, same-rarity brainrots fuse into one of the next rarity tier). Personality is rolled at spawn.
- `src/server/Services/DataService.luau` includes `tutorialComplete: boolean` in the PlayerData schema (defaults to `false`).
- `src/server/Remotes/init.luau` includes the `TutorialComplete` remote (C->S, no payload).
- `src/server/Services/BaseService.luau` manages single-plot assignment and capacity upgrades.
- `src/server/Services/EarningsService.luau` uses the full formula: `baseEarnings * sizeMult * baseMutMult * weatherMutMult * personalityMult`.
- `src/server/Services/WeatherService.luau` runs the global weather cycle and applies weather mutations.
- `src/client/Controllers/WeatherUI.luau` displays weather banner, visual effects, and basic music transitions.
- `src/client/Controllers/BaseUI.luau` renders the player's own brainrots on their plot with fencing.
- All Phase 1-8 features work without errors. `rojo build` succeeds.

---

## 3. Files to Create/Modify

Every file is listed with its full path relative to the project root.

### New Files to Create (2 files)

| # | File Path | Purpose |
|---|---|---|
| 1 | `src/client/Controllers/TutorialUI.luau` | Guided onboarding system for first-time players. Detects `tutorialComplete == false`, runs a step-by-step tutorial flow, and fires `TutorialComplete` when done. |
| 2 | `src/shared/Config/Sounds.luau` | Sound asset ID registry. Maps every game event to its sound asset ID, volume, and playback properties. Single source of truth for all sound configuration. |

### Files to Modify (7 files)

| # | File Path | Change |
|---|---|---|
| 1 | `src/server/Services/BaseService.luau` | Expand from 1 plot position to 6 `PLOT_POSITIONS`. Assign first available plot on player join. Replicate brainrot visual data to all clients for rival base rendering. Add `PlotAssigned` and `RivalBaseUpdate` remote handling. |
| 2 | `src/server/Remotes/init.luau` | Add `PlotAssigned` (S->C), `RivalBaseUpdate` (S->C), and `TutorialStepCompleted` (C->S) RemoteEvents. |
| 3 | `src/client/Controllers/BaseUI.luau` | Render other players' bases (rival bases) as view-only. Listen for `PlotAssigned` and `RivalBaseUpdate`. Create brainrot models on rival plots. Disable click interaction on rival brainrots. Add sound effect playback for base-related events (capacity upgrade, brainrot placed). |
| 4 | `src/client/Controllers/WeatherUI.luau` | Polish music crossfades (1-2 second fade). Support multiple tracks per mood with random selection. Add volume slider control. Ensure music continues smoothly across weather transitions. Add weather-specific ambient sounds. |
| 5 | `src/client/Controllers/FoodStoreUI.luau` | Add sound effects for buying food (cash register), brainrot spawned (happy jingle), and brainrot ran away (sad trombone). |
| 6 | `src/server/init.server.luau` | No structural changes needed; verify boot order is correct for Phase 9. |
| 7 | `src/client/init.client.luau` | Add TutorialUI to the controller initialization list (must be last, after all other UIs are ready). |

---

## 4. Detailed Spec Per File

---

### 4.1 `src/shared/Config/Sounds.luau` (CREATE)

**Purpose:** Centralized registry of all sound asset IDs and playback properties. Both server and client code reference this module to play consistent sounds. This module has zero dependencies.

**Returns:** A table named `Sounds` containing the sound registry.

**Data table:**

```luau
local Sounds = {}

-- Each entry: { assetId: string, volume: number, playbackSpeed: number? }
-- playbackSpeed defaults to 1.0 if omitted

Sounds.SOUND_EFFECTS = {
    -- Food Store events
    BuyFood = {
        assetId = "rbxassetid://0",          -- cash register / coin sound
        volume = 0.5,
    },
    BrainrotSpawned = {
        assetId = "rbxassetid://0",          -- happy celebration jingle
        volume = 0.6,
    },
    BrainrotRanAway = {
        assetId = "rbxassetid://0",          -- sad trombone
        volume = 0.5,
    },

    -- Mutation events
    MutationGold = {
        assetId = "rbxassetid://0",          -- metallic shimmer
        volume = 0.6,
    },
    MutationDiamond = {
        assetId = "rbxassetid://0",          -- crystal chime
        volume = 0.6,
    },
    MutationRainbow = {
        assetId = "rbxassetid://0",          -- magical ascending arpeggio
        volume = 0.7,
    },
    WeatherMutationApplied = {
        assetId = "rbxassetid://0",          -- elemental impact sound
        volume = 0.5,
    },

    -- Base events
    CapacityUpgraded = {
        assetId = "rbxassetid://0",          -- construction hammer + level-up
        volume = 0.6,
    },
    SellBrainrot = {
        assetId = "rbxassetid://0",          -- register beep + coin collection
        volume = 0.5,
    },

    -- Codex events
    CodexDiscovery = {
        assetId = "rbxassetid://0",          -- book page turn + achievement chime
        volume = 0.6,
    },

    -- Lucky Hour
    LuckyHourStart = {
        assetId = "rbxassetid://0",          -- trumpet fanfare
        volume = 0.7,
    },
    LuckyHourEnd = {
        assetId = "rbxassetid://0",          -- fanfare wind-down
        volume = 0.5,
    },

    -- Fusion
    FusionComplete = {
        assetId = "rbxassetid://0",          -- energy buildup + explosion + reveal
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
```

**Design notes:**
- All `assetId` values are placeholder (`rbxassetid://0`). Replace with actual Roblox audio asset IDs before final testing. The placeholder `0` will produce silence, which is safe for development.
- Volume levels are balanced relative to each other. Sound effects are louder than background music to ensure they are audible.
- The `MUSIC_TRACKS` table is indexed by the same severity labels defined in `Config/Weather.luau` (`"Joyful"`, `"Gloomy"`, `"Suspenseful"`, `"Intense"`).

---

### 4.2 `src/server/Services/BaseService.luau` (MODIFY)

**What changes:** Expand from a single hardcoded plot position to 6 plot positions. Implement plot assignment logic. Add server-side rival base replication so all clients can render other players' brainrots.

**New constants (replace existing single plot position):**

```luau
local MAX_PLOTS = 6
local PLOT_SIZE = 30  -- studs per side (must match client-side PLOT_SIZE)

-- 6 plot positions arranged in a 2x3 grid
-- Each position is the center of the plot platform
local PLOT_POSITIONS = {
    Vector3.new(-50, 0, -50),   -- Plot 1 (top-left)
    Vector3.new(50, 0, -50),    -- Plot 2 (top-right)
    Vector3.new(-50, 0, 25),    -- Plot 3 (middle-left)
    Vector3.new(50, 0, 25),     -- Plot 4 (middle-right)
    Vector3.new(-50, 0, 100),   -- Plot 5 (bottom-left)
    Vector3.new(50, 0, 100),    -- Plot 6 (bottom-right)
}
```

**New state:**

```luau
-- Maps plot index (1-6) to the Player who owns it (or nil if unoccupied)
local plotOwners: { [number]: Player? } = {}

-- Maps Player to their assigned plot index
local playerPlots: { [Player]: number } = {}
```

**Updated `onPlayerAdded` function:**

```luau
function BaseService.onPlayerAdded(player: Player)
```
- **Step by step:**
  1. Find the first available plot: iterate `PLOT_POSITIONS` by index (1 to `MAX_PLOTS`). The first index where `plotOwners[i] == nil` is the assigned plot.
  2. If no plot is available (all 6 occupied), warn `"BaseService: No available plots for player"` and return. The player can still be in the game but has no base.
  3. Assign the plot: `plotOwners[plotIndex] = player`, `playerPlots[player] = plotIndex`.
  4. Fire `PlotAssigned` to the joining player: `Remotes.PlotAssigned:FireClient(player, { plotIndex = plotIndex, plotPosition = PLOT_POSITIONS[plotIndex] })`.
  5. Fire `PlotAssigned` to ALL other clients to inform them a new player has taken a plot: `Remotes.PlotAssigned:FireAllClients({ plotIndex = plotIndex, plotPosition = PLOT_POSITIONS[plotIndex], playerName = player.Name, playerId = player.UserId })`.
  6. Send the joining player information about all existing occupied plots and their brainrots (for rival base rendering). For each occupied plot (excluding the joining player's own):
     a. Get the owning player and their data via `DataService.getData(owner)`.
     b. Build a lightweight brainrot summary for each brainrot: `{ name = brainrot.name, baseMutation = brainrot.baseMutation, weatherMutation = brainrot.weatherMutation, size = brainrot.size, sizeLabel = brainrot.sizeLabel, personality = brainrot.personality }`.
     c. Fire `RivalBaseUpdate` to the joining player with: `{ plotIndex = ownerPlotIndex, playerName = owner.Name, brainrots = summaries }`.

**Updated `onPlayerRemoving` function:**

```luau
function BaseService.onPlayerRemoving(player: Player)
```
- **Step by step:**
  1. Get the player's plot index from `playerPlots[player]`.
  2. If found, clear `plotOwners[plotIndex] = nil` and `playerPlots[player] = nil`.
  3. Fire `RivalBaseUpdate` to all remaining clients with an empty brainrots list for that plot: `Remotes.RivalBaseUpdate:FireAllClients({ plotIndex = plotIndex, playerName = nil, brainrots = {} })`. This tells clients to clear the rival base display for that plot.

**New public functions:**

```luau
function BaseService.getPlotPosition(player: Player): Vector3?
```
- Returns the center position of the player's assigned plot.
- **Step by step:**
  1. Look up `playerPlots[player]`.
  2. If found, return `PLOT_POSITIONS[playerPlots[player]]`.
  3. If not found, return `nil`.

```luau
function BaseService.getPlotIndex(player: Player): number?
```
- Returns the plot index (1-6) assigned to the player, or nil.

```luau
function BaseService.getAllPlotPositions(): { Vector3 }
```
- Returns the full `PLOT_POSITIONS` table. Used by client for rendering all plot platforms.

**Rival base replication hook:**

Whenever a brainrot is added or removed from a player's inventory (in `FoodService`, `SellService`, `FusionService`), those services should call:

```luau
function BaseService.broadcastRivalUpdate(player: Player)
```
- **Step by step:**
  1. Get the player's plot index. If nil, return.
  2. Get the player's data. If nil, return.
  3. Build lightweight brainrot summaries (same shape as in `onPlayerAdded`).
  4. Fire `RivalBaseUpdate` to all clients EXCEPT the owning player: iterate `Players:GetPlayers()`, skip `player`, fire to each other client.

**Exposed constants:**

```luau
BaseService.MAX_PLOTS = MAX_PLOTS
BaseService.PLOT_POSITIONS = PLOT_POSITIONS
BaseService.PLOT_SIZE = PLOT_SIZE
```

---

### 4.3 `src/server/Remotes/init.luau` (MODIFY)

**What changes:** Add three new RemoteEvents for the map/tutorial systems.

**New remotes to add:**

```luau
-- Phase 9: Map & Tutorial
local PlotAssigned = Instance.new("RemoteEvent")
PlotAssigned.Name = "PlotAssigned"
PlotAssigned.Parent = remotesFolder

local RivalBaseUpdate = Instance.new("RemoteEvent")
RivalBaseUpdate.Name = "RivalBaseUpdate"
RivalBaseUpdate.Parent = remotesFolder

local TutorialStepCompleted = Instance.new("RemoteEvent")
TutorialStepCompleted.Name = "TutorialStepCompleted"
TutorialStepCompleted.Parent = remotesFolder
```

**Add to the returned module table:**

```luau
return {
    -- ... existing remotes ...

    -- Phase 9: Map & Tutorial
    PlotAssigned = PlotAssigned,                -- S->C: { plotIndex, plotPosition, playerName?, playerId? }
    RivalBaseUpdate = RivalBaseUpdate,          -- S->C: { plotIndex, playerName, brainrots }
    TutorialStepCompleted = TutorialStepCompleted,  -- C->S: { step: number }
}
```

**Payload schemas:**

| Remote | Direction | Payload |
|---|---|---|
| `PlotAssigned` | Server -> Client | `{ plotIndex: number, plotPosition: Vector3, playerName: string?, playerId: number? }` |
| `RivalBaseUpdate` | Server -> Client | `{ plotIndex: number, playerName: string?, brainrots: { RivalBrainrotSummary } }` |
| `TutorialStepCompleted` | Client -> Server | `{ step: number }` |

**RivalBrainrotSummary type:**

```luau
type RivalBrainrotSummary = {
    name: string,
    baseMutation: string?,
    weatherMutation: string?,
    size: number,
    sizeLabel: string,
    personality: string?,
}
```

This is a lightweight subset of `BrainrotInstance` -- no `id`, `rarity`, `earningsPerSec`, or `weight` fields. Only the data needed for visual rendering is included. This minimizes network bandwidth for rival base replication.

---

### 4.4 `src/client/Controllers/TutorialUI.luau` (CREATE)

**Purpose:** Detects first-time players (`tutorialComplete == false` in PlayerData) and runs a guided, step-by-step onboarding flow. The tutorial highlights UI elements, provides instructional text, and waits for the player to complete each action before advancing.

**Dependencies:**

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Utils = require(ReplicatedStorage.Shared.Utils)
local Sounds = require(ReplicatedStorage.Shared.Config.Sounds)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
```

**State:**

```luau
local currentStep: number = 0
local tutorialActive: boolean = false
local tutorialGui: ScreenGui? = nil
local dialogFrame: Frame? = nil
local arrowIndicator: ImageLabel? = nil
local highlightOverlay: Frame? = nil
local skipButton: TextButton? = nil
```

**Tutorial Steps:**

```luau
local TUTORIAL_STEPS = {
    {
        id = 1,
        message = "Welcome to Collect Brainrot's! Let's get your first brainrot.",
        highlight = nil,              -- no highlight, just intro text
        arrow = nil,
        waitFor = "dismiss",          -- player clicks "Next" to continue
    },
    {
        id = 2,
        message = "Here's your base! This is where your brainrots will live.",
        highlight = "plot",           -- highlight the player's plot area
        arrow = "plot",               -- arrow points at the player's base
        waitFor = "dismiss",
    },
    {
        id = 3,
        message = "Buy food to attract brainrots! Open the Food Store and buy Common Chow.",
        highlight = "foodStore",      -- highlight the food store toggle button
        arrow = "foodStore",          -- arrow points at food store button
        waitFor = "dismiss",
    },
    {
        id = 4,
        message = "Click to buy Common Chow!",
        highlight = "buyButton",      -- highlight the Common Chow buy button
        arrow = "buyButton",
        waitFor = "BrainrotSpawned",  -- wait for BrainrotSpawned OR BrainrotRanAway remote
    },
    {
        id = 5,
        message = "",                 -- set dynamically based on outcome
        highlight = nil,
        arrow = nil,
        waitFor = "dismiss",
        -- if brainrot spawned: "A brainrot appeared! It's now earning money for you!"
        -- if brainrot ran away: "It ran away! Don't worry, try buying more food."
    },
    {
        id = 6,
        message = "Brainrots earn you money every second! Watch your balance grow.",
        highlight = "moneyDisplay",   -- highlight the money/earnings UI
        arrow = "moneyDisplay",
        waitFor = "dismiss",
    },
    {
        id = 7,
        message = "You're ready! Keep collecting brainrots and buy better food for rarer ones!",
        highlight = nil,
        arrow = nil,
        waitFor = "dismiss",
    },
}
```

**UI Layout:**

```
ScreenGui "TutorialGui"
  DisplayOrder: 100      -- above all other UIs
  ResetOnSpawn: false

  -- Semi-transparent overlay to dim the screen (optional, only during highlights)
  Frame "DimOverlay"
    Size: UDim2.new(1, 0, 1, 0)
    BackgroundColor3: Color3.fromRGB(0, 0, 0)
    BackgroundTransparency: 0.6
    Visible: false
    ZIndex: 90

  -- Dialog box at bottom-center of screen
  Frame "DialogFrame"
    Position: UDim2.new(0.5, 0, 0.85, 0)
    AnchorPoint: Vector2.new(0.5, 0.5)
    Size: UDim2.new(0.5, 0, 0, 120)
    BackgroundColor3: Color3.fromRGB(25, 25, 35)
    BackgroundTransparency: 0.1
    ZIndex: 100
    -- Add UICorner with CornerRadius 16
    -- Add UIStroke with Color = Color3.fromRGB(85, 170, 255), Thickness = 2

    TextLabel "MessageLabel"
      Position: UDim2.new(0.5, 0, 0, 15)
      AnchorPoint: Vector2.new(0.5, 0)
      Size: UDim2.new(1, -30, 0, 55)
      Text: ""
      TextColor3: Color3.fromRGB(255, 255, 255)
      TextScaled: true
      TextWrapped: true
      Font: Enum.Font.GothamBold
      BackgroundTransparency: 1
      ZIndex: 101

    TextButton "NextButton"
      Position: UDim2.new(0.5, 0, 1, -15)
      AnchorPoint: Vector2.new(0.5, 1)
      Size: UDim2.new(0, 120, 0, 35)
      Text: "Next"
      TextColor3: Color3.fromRGB(255, 255, 255)
      BackgroundColor3: Color3.fromRGB(46, 204, 113)
      Font: Enum.Font.GothamBold
      TextScaled: true
      ZIndex: 101
      -- Add UICorner with CornerRadius 8

  -- Skip button (always visible during tutorial)
  TextButton "SkipButton"
    Position: UDim2.new(1, -15, 0, 15)
    AnchorPoint: Vector2.new(1, 0)
    Size: UDim2.new(0, 80, 0, 30)
    Text: "Skip"
    TextColor3: Color3.fromRGB(200, 200, 200)
    BackgroundColor3: Color3.fromRGB(80, 80, 80)
    BackgroundTransparency: 0.3
    Font: Enum.Font.Gotham
    TextScaled: true
    ZIndex: 101
    -- Add UICorner with CornerRadius 6

  -- Arrow indicator (points at highlighted elements)
  ImageLabel "ArrowIndicator"
    Size: UDim2.new(0, 40, 0, 40)
    BackgroundTransparency: 1
    Image: "rbxassetid://0"           -- downward arrow image asset
    Visible: false
    ZIndex: 100
```

**Public API:**

```luau
function TutorialUI.Init()
```
- **Step by step:**
  1. Listen for `InitialData.OnClientEvent`. When received, check `data.tutorialComplete`.
  2. If `tutorialComplete == true`, do NOT create the tutorial UI. Return immediately.
  3. If `tutorialComplete == false`, build the tutorial UI hierarchy (as described above). Parent `TutorialGui` to `playerGui`.
  4. Set `tutorialActive = true`.
  5. Connect `SkipButton.Activated` to `skipTutorial()`.
  6. Start the tutorial: call `advanceStep()`.

**Internal functions:**

```luau
local function advanceStep()
```
- **Step by step:**
  1. Increment `currentStep`.
  2. If `currentStep > #TUTORIAL_STEPS`, call `completeTutorial()` and return.
  3. Get the step definition: `local step = TUTORIAL_STEPS[currentStep]`.
  4. Update `MessageLabel.Text = step.message`.
  5. If `step.highlight` is set, position the dim overlay and arrow indicator near the target UI element (see `getHighlightPosition()` below).
  6. If `step.waitFor == "dismiss"`:
     a. Show the `NextButton`.
     b. Wait for `NextButton.Activated` (use a one-time connection).
     c. Call `advanceStep()`.
  7. If `step.waitFor == "BrainrotSpawned"`:
     a. Hide the `NextButton` (player must actually buy food).
     b. Connect to both `Remotes.BrainrotSpawned.OnClientEvent` and `Remotes.BrainrotRanAway.OnClientEvent`.
     c. On `BrainrotSpawned`: set step 5 message to `"A brainrot appeared! It's now earning money for you!"`, advance to step 5.
     d. On `BrainrotRanAway`: set step 5 message to `"It ran away! Don't worry, try buying more food."`, advance to step 5. After step 5 dismiss, loop back to step 4 (re-show "Click to buy Common Chow!") to let the player try again.

```luau
local function getHighlightPosition(targetId: string): UDim2?
```
- Returns the screen position for the arrow indicator based on the target element.
- **Mapping:**
  - `"plot"` -- position arrow above the player's base in world space (use `Camera:WorldToScreenPoint()` on the plot center).
  - `"foodStore"` -- position arrow above the Food Store toggle button (find the button in `playerGui`).
  - `"buyButton"` -- position arrow above the Common Chow buy button inside the food store.
  - `"moneyDisplay"` -- position arrow above the MoneyUI display.
- If the target element cannot be found, return `nil` (arrow stays hidden).

```luau
local function completeTutorial()
```
- **Step by step:**
  1. Set `tutorialActive = false`.
  2. Fire `Remotes.TutorialComplete:FireServer()` to mark tutorial as complete in PlayerData.
  3. Tween the dialog frame offscreen (fade out + slide down, 0.5 seconds).
  4. After tween, destroy `TutorialGui`.

```luau
local function skipTutorial()
```
- **Step by step:**
  1. Call `completeTutorial()` directly (skips all remaining steps).

**Tutorial safeguards (per Game Design Section 14.3):**
- First food drop during tutorial has an **increased stay chance** (90%). This is enforced server-side in `FoodService`: check if `data.tutorialComplete == false` and override the stay chance to `0.90` for that player's food drop. This is a **FoodService modification** (see Section 4.8).
- Tutorial progress is NOT saved mid-tutorial. If a player disconnects mid-tutorial, they start from step 1 on rejoin (since `tutorialComplete` is still `false`). This is acceptable because the tutorial is short (~2 minutes).

---

### 4.5 `src/client/Controllers/BaseUI.luau` (MODIFY)

**What changes:** Three additions: (1) render rival players' bases on all 6 plots; (2) render rival brainrots as view-only models; (3) add sound effects for base-related events.

**New dependencies:**

```luau
local Sounds = require(ReplicatedStorage.Shared.Config.Sounds)
local SoundService = game:GetService("SoundService")
```

**New state:**

```luau
-- Rival base data: maps plotIndex -> { playerName: string, brainrotModels: {Model} }
local rivalBases: { [number]: { playerName: string, brainrotModels: { Instance } } } = {}

-- All plot platform Parts (created on init)
local plotPlatforms: { [number]: Part } = {}

-- The local player's assigned plot index
local myPlotIndex: number? = nil
```

#### 4.5.1 Plot Platform Creation

When `PlotAssigned` fires for the local player (identifying their own plot), create platform Parts for ALL 6 plots so the world feels populated even before other players join.

```luau
local function createPlotPlatforms(allPositions: { Vector3 })
    for i, pos in allPositions do
        local platform = Instance.new("Part")
        platform.Name = "PlotPlatform_" .. i
        platform.Anchored = true
        platform.CanCollide = true
        platform.Size = Vector3.new(PLOT_SIZE, 1, PLOT_SIZE)
        platform.Position = pos - Vector3.new(0, 0.5, 0)  -- slightly below ground level
        platform.Color = Color3.fromRGB(76, 153, 76)       -- grass green
        platform.Material = Enum.Material.Grass
        platform.TopSurface = Enum.SurfaceType.Smooth
        platform.BottomSurface = Enum.SurfaceType.Smooth
        platform.Parent = workspace

        plotPlatforms[i] = platform

        -- Add a name plate above each plot
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "PlotLabel"
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 8, 0)
        billboard.Adornee = platform
        billboard.AlwaysOnTop = false
        billboard.Parent = platform

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.Text = "Available"
        nameLabel.Parent = billboard
    end
end
```

#### 4.5.2 Rival Base Rendering

**On `PlotAssigned` remote (when another player joins):**

```luau
local function handlePlotAssigned(data)
    local plotIndex = data.plotIndex
    local playerName = data.playerName

    -- Update the plot's name plate
    if plotPlatforms[plotIndex] then
        local billboard = plotPlatforms[plotIndex]:FindFirstChild("PlotLabel")
        if billboard then
            local label = billboard:FindFirstChild("TextLabel")
            if label then
                if playerName and playerName ~= player.Name then
                    label.Text = playerName .. "'s Base"
                    label.TextColor3 = Color3.fromRGB(255, 200, 100)
                elseif playerName == player.Name then
                    label.Text = "Your Base"
                    label.TextColor3 = Color3.fromRGB(85, 255, 85)
                end
            end
        end
    end
end
```

**On `RivalBaseUpdate` remote:**

```luau
local function handleRivalBaseUpdate(data)
    local plotIndex = data.plotIndex
    local playerName = data.playerName
    local brainrots = data.brainrots

    -- If this is our own plot, ignore (we handle our own brainrots separately)
    if plotIndex == myPlotIndex then
        return
    end

    -- Clear existing rival brainrot models for this plot
    if rivalBases[plotIndex] then
        for _, model in rivalBases[plotIndex].brainrotModels do
            model:Destroy()
        end
    end

    -- If brainrots list is empty (player left), clear the entry and reset name plate
    if #brainrots == 0 then
        rivalBases[plotIndex] = nil
        -- Reset name plate to "Available"
        updatePlotLabel(plotIndex, "Available", Color3.fromRGB(200, 200, 200))
        return
    end

    -- Create new rival brainrot models
    local models = {}
    local plotPos = PLOT_POSITIONS[plotIndex]  -- referenced from BaseService constants
    for i, brainrotSummary in brainrots do
        local model = createRivalBrainrotModel(brainrotSummary, plotPos, i, #brainrots)
        table.insert(models, model)
    end

    rivalBases[plotIndex] = {
        playerName = playerName,
        brainrotModels = models,
    }
end
```

**Rival brainrot model creation:**

```luau
local function createRivalBrainrotModel(summary, plotCenter: Vector3, index: number, total: number): Instance
```
- **Step by step:**
  1. Look up the brainrot config from `Config/Brainrots.BRAINROT_BY_NAME[summary.name]` to get the model asset ID.
  2. Create a Model or Part representing the brainrot. If using asset IDs, call `InsertService:LoadAsset()` or use a pre-loaded model cache. For Phase 9 MVP, use a simple colored Part with a BillboardGui showing the brainrot name.
  3. Set the model's scale based on `summary.size`.
  4. Apply mutation color tint if `summary.baseMutation` is not nil (same color logic as own brainrots).
  5. Position the model on the rival's plot using the same grid layout logic as own brainrots, but offset to `plotCenter` instead of the local player's plot center.
  6. **CRITICAL:** Do NOT connect any click detectors or interaction handlers. Rival brainrots are view-only.
  7. Parent the model to workspace.
  8. Return the model.

#### 4.5.3 Sound Effects for Base Events

Add a utility function for playing sounds:

```luau
local function playSound(soundKey: string)
    local soundData = Sounds.SOUND_EFFECTS[soundKey]
    if not soundData then return end

    local sound = Instance.new("Sound")
    sound.SoundId = soundData.assetId
    sound.Volume = soundData.volume
    sound.PlaybackSpeed = soundData.playbackSpeed or 1.0
    sound.Parent = SoundService
    sound.Ended:Once(function()
        sound:Destroy()
    end)
    sound:Play()
end
```

Add sound calls in existing event handlers:
- In `CapacityUpdated` handler: `playSound("CapacityUpgraded")`
- In `BrainrotSpawned` handler: `playSound("BrainrotSpawned")`
- In `BrainrotMutated` handler: `playSound("WeatherMutationApplied")`

---

### 4.6 `src/client/Controllers/WeatherUI.luau` (MODIFY)

**What changes:** Polish the music system with smoother crossfades, multiple track support per mood, volume controls, and weather-specific ambient sounds.

**New dependency:**

```luau
local Sounds = require(ReplicatedStorage.Shared.Config.Sounds)
```

**New state:**

```luau
local currentMusicSound: Sound? = nil
local targetMusicVolume: number = 0.3
local userVolumeMultiplier: number = 1.0    -- controlled by volume slider (0.0 to 1.0)
local isCrossfading: boolean = false
local currentMood: string = "Joyful"
local ambientSound: Sound? = nil
```

#### 4.6.1 Music Crossfade System

Replace the existing basic music transition with a proper crossfade:

```luau
local function crossfadeToMood(newMood: string)
    if newMood == currentMood and currentMusicSound and currentMusicSound.IsPlaying then
        return  -- already playing this mood
    end

    if isCrossfading then
        return  -- don't interrupt an ongoing crossfade
    end

    currentMood = newMood
    isCrossfading = true

    -- Select a random track from the mood's track list
    local tracks = Sounds.MUSIC_TRACKS[newMood]
    if not tracks or #tracks == 0 then
        isCrossfading = false
        return
    end
    local trackData = tracks[math.random(1, #tracks)]

    -- Create the new music Sound
    local newMusic = Instance.new("Sound")
    newMusic.SoundId = trackData.assetId
    newMusic.Volume = 0  -- start silent, fade in
    newMusic.Looped = true
    newMusic.Parent = SoundService
    newMusic:Play()

    local fadeDuration = Sounds.MUSIC_CROSSFADE_DURATION

    -- Fade out old track (if playing)
    if currentMusicSound and currentMusicSound.IsPlaying then
        local oldMusic = currentMusicSound
        local fadeOutTween = TweenService:Create(
            oldMusic,
            TweenInfo.new(fadeDuration, Enum.EasingStyle.Linear),
            { Volume = 0 }
        )
        fadeOutTween:Play()
        fadeOutTween.Completed:Once(function()
            oldMusic:Stop()
            oldMusic:Destroy()
        end)
    end

    -- Fade in new track
    targetMusicVolume = trackData.volume * userVolumeMultiplier
    local fadeInTween = TweenService:Create(
        newMusic,
        TweenInfo.new(fadeDuration, Enum.EasingStyle.Linear),
        { Volume = targetMusicVolume }
    )
    fadeInTween:Play()
    fadeInTween.Completed:Once(function()
        isCrossfading = false
    end)

    currentMusicSound = newMusic
end
```

#### 4.6.2 Weather-Specific Ambient Sounds

Each non-Clear weather type has an ambient loop (rain sounds, wind, thunder, etc.):

```luau
local AMBIENT_SOUNDS = {
    Rain = "rbxassetid://0",           -- rain ambiance loop
    Snow = "rbxassetid://0",           -- soft wind + snowfall
    Storm = "rbxassetid://0",          -- thunder + heavy rain
    ["Meteor Shower"] = "rbxassetid://0",  -- distant rumbles + streaking
    ["Solar Flare"] = "rbxassetid://0",    -- crackling energy
    Nuclear = "rbxassetid://0",            -- Geiger counter + drones
    ["Black Hole"] = "rbxassetid://0",     -- deep void hum
}

local function setAmbientSound(weatherType: string)
    -- Stop existing ambient
    if ambientSound then
        local oldAmbient = ambientSound
        local fadeOut = TweenService:Create(
            oldAmbient,
            TweenInfo.new(1.0, Enum.EasingStyle.Linear),
            { Volume = 0 }
        )
        fadeOut:Play()
        fadeOut.Completed:Once(function()
            oldAmbient:Stop()
            oldAmbient:Destroy()
        end)
        ambientSound = nil
    end

    -- Start new ambient if applicable
    local ambientId = AMBIENT_SOUNDS[weatherType]
    if not ambientId then return end

    local newAmbient = Instance.new("Sound")
    newAmbient.SoundId = ambientId
    newAmbient.Volume = 0
    newAmbient.Looped = true
    newAmbient.Parent = SoundService
    newAmbient:Play()

    local fadeIn = TweenService:Create(
        newAmbient,
        TweenInfo.new(1.5, Enum.EasingStyle.Linear),
        { Volume = 0.25 * userVolumeMultiplier }
    )
    fadeIn:Play()

    ambientSound = newAmbient
end
```

#### 4.6.3 Volume Control UI

Add a small volume slider to the weather banner (or a separate settings area):

```
Frame "VolumeControl"
  Position: UDim2.new(1, -10, 1, -50)
  AnchorPoint: Vector2.new(1, 1)
  Size: UDim2.new(0, 150, 0, 40)
  BackgroundColor3: Color3.fromRGB(30, 30, 40)
  BackgroundTransparency: 0.5
  -- Add UICorner with CornerRadius 8

  TextLabel "VolumeLabel"
    Position: UDim2.new(0, 5, 0.5, 0)
    AnchorPoint: Vector2.new(0, 0.5)
    Size: UDim2.new(0, 20, 0, 20)
    Text: "♪"
    BackgroundTransparency: 1
    TextColor3: Color3.fromRGB(200, 200, 200)

  Frame "SliderTrack"
    Position: UDim2.new(0, 30, 0.5, 0)
    AnchorPoint: Vector2.new(0, 0.5)
    Size: UDim2.new(0, 100, 0, 6)
    BackgroundColor3: Color3.fromRGB(80, 80, 80)
    -- Add UICorner

    Frame "SliderFill"
      Size: UDim2.new(1, 0, 1, 0)   -- width = userVolumeMultiplier
      BackgroundColor3: Color3.fromRGB(85, 170, 255)
      -- Add UICorner

    TextButton "SliderKnob"
      -- draggable knob for volume adjustment
      Size: UDim2.new(0, 16, 0, 16)
      AnchorPoint: Vector2.new(0.5, 0.5)
      BackgroundColor3: Color3.fromRGB(255, 255, 255)
      -- Use InputBegan/InputChanged for drag behavior
```

**Volume slider behavior:**
- Drag the knob left/right to adjust `userVolumeMultiplier` between 0.0 and 1.0.
- When changed, immediately update `currentMusicSound.Volume = targetMusicVolume * userVolumeMultiplier` and `ambientSound.Volume` if present.
- Persist the volume setting via `PlayerGui:SetAttribute("MusicVolume", userVolumeMultiplier)` for session persistence (not saved to DataStore -- volume resets each session).

#### 4.6.4 Updated Weather Change Handler

Modify the existing `WeatherChanged` handler to incorporate the crossfade and ambient systems:

```luau
local function handleWeatherChanged(data)
    local weatherType = data.weather
    currentWeather = weatherType

    -- Update banner (existing logic)
    if weatherType == "Clear" then
        hideBanner()
    else
        weatherEndTime = data.endTime
        showBanner(weatherType)
    end

    -- Update visual effects (existing logic)
    applyVisualEffects(weatherType)

    -- Crossfade music to matching mood
    local severity = Weather.getSeverity(weatherType)
    local mood = Weather.getSeverityLabel(severity)
    crossfadeToMood(mood)

    -- Update ambient sound
    setAmbientSound(weatherType)
end
```

---

### 4.7 `src/client/Controllers/FoodStoreUI.luau` (MODIFY)

**What changes:** Add sound effects for food purchase events.

**New dependency:**

```luau
local Sounds = require(ReplicatedStorage.Shared.Config.Sounds)
local SoundService = game:GetService("SoundService")
```

**Add the same `playSound` utility function** (or extract it to a shared client utility module to avoid duplication with BaseUI):

```luau
local function playSound(soundKey: string)
    local soundData = Sounds.SOUND_EFFECTS[soundKey]
    if not soundData then return end

    local sound = Instance.new("Sound")
    sound.SoundId = soundData.assetId
    sound.Volume = soundData.volume
    sound.PlaybackSpeed = soundData.playbackSpeed or 1.0
    sound.Parent = SoundService
    sound.Ended:Once(function()
        sound:Destroy()
    end)
    sound:Play()
end
```

**Add sound calls to existing handlers:**

- In the buy button click handler (when `BuyFood` is fired): `playSound("BuyFood")`
- In the `BrainrotSpawned` handler (after reveal animation): `playSound("BrainrotSpawned")`
  - Additionally, check for base mutation and play the appropriate mutation sound:
    - If `brainrotData.baseMutation == "Gold"`: `playSound("MutationGold")`
    - If `brainrotData.baseMutation == "Diamond"`: `playSound("MutationDiamond")`
    - If `brainrotData.baseMutation == "Rainbow"`: `playSound("MutationRainbow")`
- In the `BrainrotRanAway` handler: `playSound("BrainrotRanAway")`

---

### 4.8 `src/server/Services/FoodService.luau` (MODIFY -- tutorial stay chance)

**What changes:** Add a tutorial safeguard that increases the stay chance to 90% for players who have not completed the tutorial.

**Modification to the stay chance roll (inside the `handleBuyFood` function):**

```luau
-- Existing stay chance logic:
local stayChance = foodConfig.stayChance

-- Phase 9 tutorial override:
local data = DataService.getData(player)
if data and data.tutorialComplete == false then
    stayChance = math.max(stayChance, 0.90)  -- at least 90% during tutorial
end

-- Continue with existing roll:
local stays = math.random() < stayChance
```

This is a minimal, targeted change. The `math.max` ensures that if a food tier already has a stay chance above 90% (which none currently do -- Common Chow is 60%), it is not reduced. After the tutorial is marked complete, the normal stay chance applies.

---

### 4.9 `src/client/init.client.luau` (MODIFY)

**What changes:** Add TutorialUI to the controller initialization list. TutorialUI must be initialized LAST so that all other UIs (MoneyUI, FoodStoreUI, BaseUI, etc.) are already present when the tutorial tries to highlight them.

**New lines to add (after all existing controller initializations):**

```luau
-- Phase 9: Tutorial (must be last)
local TutorialUI = require(script.Controllers.TutorialUI)
TutorialUI.Init()
```

**Full updated client bootstrap (showing Phase 9 state):**

```luau
-- init.client.luau
local MoneyUI = require(script.Controllers.MoneyUI)
local FoodStoreUI = require(script.Controllers.FoodStoreUI)
local BaseUI = require(script.Controllers.BaseUI)
local SellUI = require(script.Controllers.SellUI)
local WeatherUI = require(script.Controllers.WeatherUI)
local IndexUI = require(script.Controllers.IndexUI)
local LeaderboardUI = require(script.Controllers.LeaderboardUI)

MoneyUI.Init()
FoodStoreUI.Init()
BaseUI.Init()
SellUI.Init()
WeatherUI.Init()
IndexUI.Init()
LeaderboardUI.Init()

-- Phase 9: Tutorial (must be last so all UIs exist for highlighting)
local TutorialUI = require(script.Controllers.TutorialUI)
TutorialUI.Init()

print("[Client] All Phase 9 controllers initialized.")
```

---

### 4.10 Final Balancing Pass

This is not a code file but a required review activity. After all code changes are complete and tested, perform the following balancing pass.

**Areas to review:**

| Area | What to Check | Current Values | Potential Adjustment |
|---|---|---|---|
| Food costs | Are early tiers affordable? Do later tiers feel rewarding? | Common: $50, varies by tier | Adjust if players feel stuck early or rich too fast |
| Earnings rates | Is passive income progression satisfying? | Common: $5/sec through Unknown: $50M/sec | Verify 30-minute playtest feels smooth |
| Weather event frequency | Are events too frequent or too rare? | 120-300 seconds between rolls | Shorten if players rarely see events; lengthen if disruptive |
| Weather event durations | Do events last long enough to feel impactful? | 15-120 seconds depending on type | Adjust if events feel too fleeting or too long |
| Capacity upgrade costs | Is the cost curve too steep or too shallow? | $500 base, 2.5x multiplier | Check that mid-game players (5-10 slots) are progressing |
| Sell values | Is 60 seconds' earnings a fair sell price? | 60x base earnings | Adjust if selling feels unrewarding or too generous |
| Mutation chances (base) | Do Gold/Diamond/Rainbow appear at satisfying rates? | Gold: 5%, Diamond: 1%, Rainbow: 0.1% | Adjust if mutations feel impossible or too common |
| Weather mutation chances | Per-brainrot chances during weather events | 15% (Rain) down to 1% (Black Hole) | Adjust if players never get weather mutations |
| Stay chances per food tier | Is the risk/reward balance right? | 60% (Common) down to 15% (Unknown) | Adjust if players are frustrated by low stay chances |
| Starting money | Is $100 enough for the tutorial? | $100 (2x Common Chow) | Increase if tutorial flow feels too tight |

**Balancing procedure:**
1. Start a fresh test session with default data.
2. Play through the tutorial.
3. Buy food and observe earnings for 5 minutes. Note how quickly the first upgrade is affordable.
4. Continue playing for 30+ minutes, noting progression milestones.
5. Trigger at least 3 weather events (use a shortened cycle interval for testing).
6. Test with 2+ players to verify rival base rendering and plot assignment.
7. Document any adjustments made (changed values, reasoning) in PROGRESS.md.

---

## 5. Module Contracts

### New Cross-Module Dependencies (Phase 9)

**Config/Sounds (new) -- used by:**

| Consumer Module | What It Uses | Purpose |
|---|---|---|
| `Controllers/FoodStoreUI` | `Sounds.SOUND_EFFECTS` | Play buy/spawn/runaway sounds |
| `Controllers/BaseUI` | `Sounds.SOUND_EFFECTS` | Play capacity upgrade, brainrot placed, mutation sounds |
| `Controllers/WeatherUI` | `Sounds.MUSIC_TRACKS`, `Sounds.MUSIC_CROSSFADE_DURATION` | Crossfade music between moods |
| `Controllers/TutorialUI` | `Sounds.SOUND_EFFECTS` (optional) | Tutorial completion chime |

**BaseService changes (map expansion + rival bases):**

| Module | Function Called | Purpose |
|---|---|---|
| `Services/DataService` | `DataService.getData(player)` | Read brainrot data for rival replication |
| `Remotes/init` | `Remotes.PlotAssigned:FireClient()` | Notify clients of plot assignments |
| `Remotes/init` | `Remotes.PlotAssigned:FireAllClients()` | Broadcast new player plot assignments |
| `Remotes/init` | `Remotes.RivalBaseUpdate:FireAllClients()` | Broadcast brainrot changes to rival viewers |

**FoodService changes (tutorial stay chance):**

| Module | Function Called | Purpose |
|---|---|---|
| `Services/DataService` | `DataService.getData(player)` | Check `tutorialComplete` for stay chance override |

**TutorialUI requires:**

| Module | Function Called | Purpose |
|---|---|---|
| `shared/Config/Sounds` | `Sounds.SOUND_EFFECTS` | Tutorial completion sound |
| `shared/Utils` | `Utils.formatNumber(n)` | Format any displayed numbers |
| `Remotes` (via ReplicatedStorage) | `InitialData.OnClientEvent` | Check `tutorialComplete` flag |
| `Remotes` (via ReplicatedStorage) | `TutorialComplete:FireServer()` | Mark tutorial as done |
| `Remotes` (via ReplicatedStorage) | `BrainrotSpawned.OnClientEvent` | Detect when player gets first brainrot |
| `Remotes` (via ReplicatedStorage) | `BrainrotRanAway.OnClientEvent` | Detect when brainrot runs away during tutorial |

**BaseUI changes (rival bases + sound):**

| Module | Function Called | Purpose |
|---|---|---|
| `shared/Config/Brainrots` | `BRAINROT_BY_NAME[name]` | Look up model data for rival brainrots |
| `shared/Config/Sounds` | `Sounds.SOUND_EFFECTS` | Play base event sounds |
| `Remotes` (via ReplicatedStorage) | `PlotAssigned.OnClientEvent` | Receive plot assignment data |
| `Remotes` (via ReplicatedStorage) | `RivalBaseUpdate.OnClientEvent` | Receive rival base brainrot updates |

### Existing Contracts (Unchanged)

- All Phase 1-8 module contracts remain unchanged.
- `BrainrotSpawned` remote payload is unchanged.
- `WeatherChanged` remote payload is unchanged.
- `TutorialComplete` remote (created in Phase 8) is reused -- no new remote needed for the actual completion signal.
- The earnings formula is unchanged: `baseEarnings * sizeMult * baseMutMult * weatherMutMult * personalityMult`.

---

## 6. Agent Task Breakdown

Tasks are organized into steps. Steps must be completed in order. Tasks within a step can be done in parallel.

### Step 1 (Parallel -- foundation, no inter-dependencies)

| Task | File | Action | Est. Lines |
|---|---|---|---|
| 1.1 | `src/shared/Config/Sounds.luau` | CREATE | ~100 |
| 1.2 | `src/server/Remotes/init.luau` | MODIFY | ~15 |

These two modifications are independent. Sounds creates the shared sound registry. Remotes adds three new remote names to the array.

- **1.1 Sounds:** Create the full sound configuration module with `SOUND_EFFECTS`, `MUSIC_TRACKS`, and `MUSIC_CROSSFADE_DURATION`.
- **1.2 Remotes:** Add `"PlotAssigned"`, `"RivalBaseUpdate"`, `"TutorialStepCompleted"` to the remote names array.

### Step 2 (Sequential -- depends on Step 1)

| Task | File | Action | Est. Lines Changed |
|---|---|---|---|
| 2.1 | `src/server/Services/BaseService.luau` | MODIFY | ~150 |

Depends on Remotes (for `PlotAssigned`, `RivalBaseUpdate` remote references). Expand to 6 plots, implement plot assignment, add rival base replication.

### Step 3 (Parallel -- depends on Steps 1-2)

| Task | File | Action | Est. Lines |
|---|---|---|---|
| 3.1 | `src/client/Controllers/TutorialUI.luau` | CREATE | ~300 |
| 3.2 | `src/client/Controllers/BaseUI.luau` | MODIFY | ~200 |
| 3.3 | `src/client/Controllers/WeatherUI.luau` | MODIFY | ~180 |
| 3.4 | `src/client/Controllers/FoodStoreUI.luau` | MODIFY | ~40 |

These four client-side tasks are independent of each other (they all depend on `Config/Sounds` and Remotes from Steps 1-2, but not on each other).

- **3.1 TutorialUI:** Create the complete tutorial system with step-by-step flow, highlighting, arrow indicator, skip button, and `TutorialComplete` remote fire.
- **3.2 BaseUI:** Add rival base rendering (plot platforms, rival brainrot models, `PlotAssigned` and `RivalBaseUpdate` listeners), add sound effects.
- **3.3 WeatherUI:** Implement music crossfade system, multiple tracks per mood, volume slider, ambient weather sounds.
- **3.4 FoodStoreUI:** Add `playSound` calls for buy/spawn/runaway events and mutation sounds.

### Step 4 (Sequential -- depends on Step 3)

| Task | File | Action | Est. Lines Changed |
|---|---|---|---|
| 4.1 | `src/server/Services/FoodService.luau` | MODIFY | ~5 |
| 4.2 | `src/client/init.client.luau` | MODIFY | ~5 |

- **4.1 FoodService:** Add tutorial stay chance override (check `tutorialComplete == false`, set stay chance to 90%).
- **4.2 init.client.luau:** Add TutorialUI to client controller initialization (must be last).

### Step 5 (Manual -- depends on all above)

| Task | Action |
|---|---|
| 5.1 | Final balancing pass: playtest for 30+ minutes, document adjustments in PROGRESS.md |
| 5.2 | Replace placeholder sound asset IDs (`rbxassetid://0`) with real Roblox audio asset IDs |

### Task Dependency Diagram

```
Step 1 (parallel):
  1.1 Config/Sounds.luau --------+
  1.2 Remotes/init.luau ---------+
         |
         v
Step 2 (sequential):
  2.1 BaseService.luau -----------+
         |
         v
Step 3 (parallel):
  3.1 TutorialUI.luau -----------+
  3.2 BaseUI.luau ---------------+
  3.3 WeatherUI.luau ------------+
  3.4 FoodStoreUI.luau ----------+
         |
         v
Step 4 (sequential):
  4.1 FoodService.luau ----------+
  4.2 init.client.luau ----------+
         |
         v
Step 5 (manual):
  5.1 Balancing pass ------------+
  5.2 Sound asset replacement ---+
```

### Total: 2 new files, 7 modified files, ~995 estimated lines of new/changed Luau code.

---

## 7. Data Structures

### 7.1 Plot Assignment State

**Server-side (BaseService):**

```luau
-- plotOwners: maps plot index to owning player
{ [1] = Player1, [2] = nil, [3] = Player2, [4] = nil, [5] = nil, [6] = nil }

-- playerPlots: maps player to their assigned plot index
{ [Player1] = 1, [Player2] = 3 }
```

**Plot positions (2x3 grid layout):**

| Plot Index | Position (X, Y, Z) | Grid Location |
|---|---|---|
| 1 | (-50, 0, -50) | Top-left |
| 2 | (50, 0, -50) | Top-right |
| 3 | (-50, 0, 25) | Middle-left |
| 4 | (50, 0, 25) | Middle-right |
| 5 | (-50, 0, 100) | Bottom-left |
| 6 | (50, 0, 100) | Bottom-right |

Plots are spaced 100 studs apart on X and 75 studs apart on Z. Each plot is 30x30 studs, leaving 70+ studs of walkable space between plots.

### 7.2 RivalBrainrotSummary Type

```luau
type RivalBrainrotSummary = {
    name: string,              -- brainrot display name
    baseMutation: string?,     -- "Gold" | "Diamond" | "Rainbow" | nil
    weatherMutation: string?,  -- weather mutation name | nil
    size: number,              -- scale factor (0.5 to 3.0)
    sizeLabel: string,         -- "Tiny" | "Small" | "Medium" | "Large" | "Massive"
    personality: string?,      -- "Lazy" | "Chill" | "Grumpy" | "Hyper" | nil
}
```

**Design rationale:** This is intentionally a lightweight subset of `BrainrotInstance`. The fields `id`, `rarity`, `earningsPerSec`, and `weight` are omitted because:
- `id` is meaningless to other players (they cannot interact with the brainrot).
- `rarity` can be inferred from `name` (look up in `Config/Brainrots`).
- `earningsPerSec` and `weight` are not displayed on rival bases.
- This reduces network bandwidth by ~40% per brainrot compared to sending the full `BrainrotInstance`.

### 7.3 Remote Payload Shapes (Phase 9 additions)

```luau
-- PlotAssigned (S->C) -- sent to the assigned player
{ plotIndex = 1, plotPosition = Vector3.new(-50, 0, -50) }

-- PlotAssigned (S->C) -- broadcast to all other clients
{ plotIndex = 1, plotPosition = Vector3.new(-50, 0, -50), playerName = "Player1", playerId = 12345678 }

-- RivalBaseUpdate (S->C)
{
    plotIndex = 3,
    playerName = "Player2",
    brainrots = {
        { name = "Tralalero Tralala", baseMutation = "Gold", weatherMutation = nil, size = 1.2, sizeLabel = "Medium", personality = "Hyper" },
        { name = "Burbaloni Lulilolli", baseMutation = nil, weatherMutation = "Soaked", size = 0.8, sizeLabel = "Small", personality = "Chill" },
    },
}

-- RivalBaseUpdate (S->C) -- player left, clear plot
{ plotIndex = 3, playerName = nil, brainrots = {} }

-- TutorialStepCompleted (C->S)
{ step = 4 }
```

### 7.4 Tutorial State

The tutorial does NOT add any new PlayerData fields. It relies on the existing `tutorialComplete: boolean` field added in Phase 8. Tutorial step progress is transient (in-memory only) -- if the player disconnects mid-tutorial, they restart from step 1.

### 7.5 No New PlayerData Fields

Phase 9 does not add any new fields to the `PlayerData` schema. All required fields already exist:
- `tutorialComplete` (Phase 8) -- used by TutorialUI to detect first-time players.
- `ownedBrainrots` (Phase 1) -- brainrot data replicated to rivals.
- `baseCapacity` (Phase 1) -- unchanged.

---

## 8. Testing Criteria

After all files are written, verify the following. Every test must pass.

### Build Test

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T1 | `rojo build` succeeds | Run `rojo build -o "collect-brainrots.rbxlx"` | Exits with code 0, no errors. |

### Map and Plot Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T2 | 6 plot platforms visible | Join game, look around the map | 6 grass-green square platforms arranged in a 2x3 grid. Each has a name plate billboard. |
| T3 | Player assigned to first available plot | Join with 1 player | Player's base is on Plot 1. Name plate shows "Your Base" in green. |
| T4 | Second player gets Plot 2 | Join with 2 players | First player on Plot 1, second player on Plot 2. |
| T5 | Plots recycle when player leaves | Player 1 leaves, Player 3 joins | Player 3 is assigned Plot 1 (the freed plot). |
| T6 | 7th player handled gracefully | Fill all 6 plots, then a 7th player joins | 7th player gets no plot. Warning in server console. No crash. |
| T7 | Players can walk between plots | Walk from own plot to another player's plot | Character can freely walk the map. No invisible walls between plots. |
| T8 | Plot fencing appears on all occupied plots | Join with 2+ players | Wooden fences (from Phase 5) appear around each occupied plot. |

### Rival Base Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T9 | Rival brainrots visible on other player's plot | Player 1 has brainrots, Player 2 looks at Plot 1 | Player 2 can see Player 1's brainrots rendered on Plot 1. |
| T10 | Rival brainrots are view-only | Walk up to rival brainrot, attempt to click | No click detector fires. No interaction possible. |
| T11 | Rival base updates when brainrot added | Player 1 buys food and gets a brainrot | Player 2 sees the new brainrot appear on Player 1's plot within ~1 second. |
| T12 | Rival base updates when brainrot sold | Player 1 sells a brainrot | Player 2 sees the brainrot disappear from Player 1's plot. |
| T13 | Rival base clears when player leaves | Player 1 leaves the game | Player 2 sees Plot 1's brainrots disappear. Name plate reverts to "Available". |
| T14 | Rival brainrot shows correct mutation colors | Player 1 has a Gold mutated brainrot | Player 2 sees the golden color tint on the rival's brainrot model. |
| T15 | Late-joining player sees existing rivals | Player 2 joins after Player 1 already has 3 brainrots | Player 2 immediately sees Player 1's 3 brainrots on their plot. |

### Tutorial Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T16 | Tutorial starts for new player | Create fresh account (or clear `tutorialComplete`), join | Tutorial dialog appears: "Welcome to Collect Brainrot's!" |
| T17 | Tutorial does NOT start for returning player | Join with `tutorialComplete == true` | No tutorial UI appears. Normal gameplay immediately. |
| T18 | Tutorial step progression | Follow tutorial instructions, click Next | Steps advance: Welcome -> Base intro -> Food Store -> Buy food -> Result -> Earnings -> Complete. |
| T19 | Tutorial responds to brainrot spawning | During tutorial, buy Common Chow and brainrot stays | Tutorial shows "A brainrot appeared!" message. |
| T20 | Tutorial responds to brainrot running away | During tutorial, buy Common Chow and brainrot leaves | Tutorial shows "It ran away!" message. Player is prompted to try again. |
| T21 | Tutorial increased stay chance | Buy food during tutorial 10 times | ~9/10 brainrots should stay (90% chance). Exact number varies but should be noticeably higher than the normal 60%. |
| T22 | Skip button works | During any tutorial step, click "Skip" | Tutorial immediately closes. `TutorialComplete` fires to server. Tutorial does not appear on rejoin. |
| T23 | Tutorial marks completion | Complete the full tutorial or skip it | `playerData.tutorialComplete` is `true`. Tutorial does not appear on next join. |
| T24 | Tutorial UI is above all other UIs | During tutorial, check if dialog and overlay are visible above food store, money display, etc. | Tutorial dialog and overlay have higher ZIndex / DisplayOrder than all other UIs. |

### Sound Effect Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T25 | Buy food plays sound | Buy any food tier | Cash register / coin sound plays. |
| T26 | Brainrot spawned plays sound | Get a brainrot from food | Happy jingle plays. |
| T27 | Brainrot ran away plays sound | Brainrot leaves after food purchase | Sad trombone plays. |
| T28 | Gold mutation plays sound | Get a Gold mutation brainrot | Metallic shimmer sound plays. |
| T29 | Diamond mutation plays sound | Get a Diamond mutation brainrot | Crystal chime sound plays. |
| T30 | Rainbow mutation plays sound | Get a Rainbow mutation brainrot | Magical arpeggio sound plays. |
| T31 | Weather mutation plays sound | Brainrot receives weather mutation | Elemental impact sound plays. |
| T32 | Capacity upgrade plays sound | Upgrade base capacity | Construction + level-up sound plays. |
| T33 | Sell brainrot plays sound | Sell a brainrot | Register beep + coin sound plays. |
| T34 | Codex discovery plays sound | Discover a new codex entry | Achievement chime plays. |
| T35 | Lucky Hour start plays sound | Lucky Hour event begins | Trumpet fanfare plays. |

### Music System Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T36 | Joyful music on Clear weather | Join game during Clear weather | Light, upbeat background music playing. |
| T37 | Music crossfades on weather change | Wait for weather to change from Clear to Rain | Music smoothly crossfades over 1-2 seconds from joyful to gloomy. No abrupt cut. |
| T38 | Music crossfades back to joyful | Weather event ends, returns to Clear | Music smoothly crossfades back to joyful track. |
| T39 | Multiple tracks per mood | Trigger the same mood multiple times | Different tracks play on different occasions (random selection). |
| T40 | Volume slider works | Drag the volume slider | Music volume changes in real-time. Slider position reflects current volume. |
| T41 | Ambient sounds match weather | Rain weather active | Rain ambient loop plays alongside the gloomy music. |
| T42 | Ambient sounds fade on weather end | Weather changes from Rain to Clear | Rain ambient fades out smoothly over ~1 second. |

### Security Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T43 | Cannot interact with rival brainrots via remotes | Fire `SellBrainrot` with a brainrot ID from another player | Server rejects. No brainrot sold from rival's inventory. |
| T44 | Cannot fire TutorialComplete repeatedly | Fire `TutorialComplete` after already completing | Server handles gracefully (sets `true` again, no error). Idempotent. |
| T45 | Plot assignment is server-authoritative | Client sends fake `PlotAssigned` | Server ignores client-sent `PlotAssigned` (it is a S->C only remote). |

### Console Cleanliness Test

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T46 | No errors in console | Check Studio Output for red error text during a full playthrough with 2+ players | Zero errors. Warnings about placeholder sound IDs (`rbxassetid://0`) are acceptable during development. |

### Regression Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T47 | All Phase 1-8 features still work | Run through: buy food, get brainrot, check earnings, upgrade capacity, sell brainrot, weather event, codex, fusion, gifting, leaderboard | All features work identically to before Phase 9 changes. |
| T48 | Earnings formula unchanged | Verify a brainrot's earningsPerSec matches `baseEarnings * sizeMult * baseMutMult * weatherMutMult * personalityMult` | Values match exactly. |
| T49 | Data persistence works | Play, collect brainrots, leave, rejoin | All brainrots, money, capacity, codex progress, and tutorialComplete persist correctly. |

---

## 9. Acceptance Criteria

All of the following must be true before Phase 9 is considered complete:

| # | Criterion | How to Verify |
|---|---|---|
| 1 | `rojo build` succeeds without errors | Run `rojo build -o "collect-brainrots.rbxlx"` |
| 2 | 6 plot positions are defined and visible in the game world | Visual check -- 6 grass platforms in a 2x3 grid |
| 3 | Players are assigned to the first available plot on join | Join with multiple players and verify sequential assignment |
| 4 | Rival bases show other players' brainrots in view-only mode | Player 2 can see Player 1's brainrots but cannot interact |
| 5 | Rival base updates in real-time when brainrots change | Buy/sell/fuse brainrots and verify rival view updates |
| 6 | Rival base clears when a player leaves | Player leaves, their plot reverts to "Available" |
| 7 | Tutorial starts automatically for new players | Fresh player sees the guided onboarding flow |
| 8 | Tutorial does NOT start for players with `tutorialComplete == true` | Returning player skips directly to gameplay |
| 9 | Tutorial guides player through buying food and getting a brainrot | Walk through all 7 tutorial steps successfully |
| 10 | Tutorial skip button works and marks completion | Click "Skip" during any step; tutorial does not reappear on rejoin |
| 11 | Tutorial increased stay chance (90%) works for first-time players | Buy food during tutorial; brainrots stay at ~90% rate |
| 12 | Sound effects play for all major game events | Verify each sound from the SOUND_EFFECTS table fires at the correct time |
| 13 | Music crossfades smoothly between weather moods | Weather transitions produce 1-2 second crossfade, no abrupt cuts |
| 14 | Multiple music tracks per mood with random selection | Trigger same mood multiple times, hear different tracks |
| 15 | Volume slider adjusts music and ambient volume in real-time | Drag slider, volume changes immediately |
| 16 | Weather ambient sounds play during non-Clear weather | Rain/Snow/Storm etc. have ambient loops |
| 17 | All Phase 1-8 features work correctly (regression) | Full playthrough of all existing features |
| 18 | No exploits: rival brainrots cannot be interacted with | Attempt click/sell/gift on rival brainrot -- all fail |
| 19 | 6-player test: all 6 plots occupied simultaneously | Join with 6 test accounts; all see each other's bases |
| 20 | Final balancing pass completed and documented | PROGRESS.md updated with balancing notes |
| 21 | No errors in Studio Output console | Zero red errors during full multiplayer playtest |

---

## Appendix A: Sound Effect Selection Guide

When replacing placeholder asset IDs (`rbxassetid://0`), use the following criteria:

| Sound Key | Duration | Style | Notes |
|---|---|---|---|
| BuyFood | 0.3-0.5s | Cash register click or coin drop | Short, satisfying, non-intrusive. Players hear this frequently. |
| BrainrotSpawned | 1.0-1.5s | Celebration jingle | Should feel rewarding. Musical, ascending notes. |
| BrainrotRanAway | 1.0-1.5s | Sad trombone / deflation | Comical disappointment. Not too long. |
| MutationGold | 0.8-1.2s | Metallic shimmer | Sparkling, golden tone. |
| MutationDiamond | 0.8-1.2s | Crystal chime | High, clear, crystalline. |
| MutationRainbow | 1.0-1.5s | Magical ascending arpeggio | Most impressive of the three mutation sounds. |
| WeatherMutationApplied | 0.5-0.8s | Elemental impact | Varies per weather but one generic sound suffices for Phase 9. |
| CapacityUpgraded | 0.8-1.0s | Construction + level-up | Hammer hit followed by ascending chime. |
| SellBrainrot | 0.5-0.8s | Register beep + coins | Coin collection, ka-ching. |
| CodexDiscovery | 1.0-1.5s | Book turn + achievement | Page flip followed by a discovery chime. |
| LuckyHourStart | 1.5-2.0s | Trumpet fanfare | Announcement-style. Should grab attention. |
| LuckyHourEnd | 0.8-1.0s | Fanfare wind-down | Subtle, signaling end of event. |
| FusionComplete | 1.5-2.5s | Energy buildup + explosion + reveal | Multi-stage sound for the fusion animation. |

## Appendix B: Map Layout Diagram

```
        Z = -50                 Z = -50
        X = -50                 X = +50
     +-----------+           +-----------+
     |           |           |           |
     |  Plot 1   |           |  Plot 2   |
     |  30x30    |           |  30x30    |
     +-----------+           +-----------+


        Z = +25                 Z = +25
        X = -50                 X = +50
     +-----------+           +-----------+
     |           |           |           |
     |  Plot 3   |           |  Plot 4   |
     |  30x30    |           |  30x30    |
     +-----------+           +-----------+


        Z = +100                Z = +100
        X = -50                 X = +50
     +-----------+           +-----------+
     |           |           |           |
     |  Plot 5   |           |  Plot 6   |
     |  30x30    |           |  30x30    |
     +-----------+           +-----------+

     <-- 100 studs between column centers -->
     <-- 75 studs between row centers -->

     Spawn point: (0, 5, -120) -- north of all plots
```

The spawn point is positioned north of the plot grid so players look south toward the bases on arrival. The 2x3 layout ensures all 6 plots are visible from a moderate camera distance, encouraging social comparison.

## Appendix C: Rival Base Bandwidth Estimate

Each `RivalBrainrotSummary` is approximately 80-120 bytes when serialized (6 fields, mostly short strings and numbers). A player with 30 brainrots sends ~3,000 bytes per `RivalBaseUpdate`. With 5 other players, a single player receives up to 15,000 bytes of rival data on join.

Updates are only sent when a brainrot is added, removed, or mutated -- not on a timer. During normal gameplay, a player might buy food every few seconds, triggering an update of ~3KB to 5 other clients. This is well within Roblox's RemoteEvent bandwidth limits.

---

*End of Phase 9 Map, Multiplayer, Tutorial, Sound, and Polish specification.*
