# Phase 6: Weather System

> **Status:** NOT STARTED
> **Depends on:** Phase 5 (base management, sell store, capacity upgrades complete and tested)
> **Blocks:** Phase 7 (Trading System)

---

## 1. Objective

Implement periodic weather events that apply "weather mutations" to brainrots at the player's base. Each brainrot can have at most ONE weather mutation, which CAN stack multiplicatively with one base mutation (from Phase 4). Weather events cycle automatically on a global timer, ranging from harmless Clear skies to catastrophic Black Hole events. Rarer weather events grant rarer (and more powerful) weather mutations, but with lower application chance per brainrot.

This phase also adds a complete atmospheric system: visual weather effects (particles, lighting changes, screen effects), a weather banner UI with countdown timer, and a music transition system that shifts the soundtrack from joyful (Clear) through gloomy (Rain/Snow) to intense thriller (Nuclear/Black Hole) based on weather severity.

By the end of this phase:
- A global weather cycle runs every 120-300 seconds, rolling a weighted-random weather event.
- Non-Clear weather events last a defined duration and attempt to apply weather mutations to each player's brainrots.
- Each brainrot can receive at most ONE weather mutation ever (higher rarity weather does NOT replace an existing weather mutation).
- Weather mutations multiply earnings and persist in save data after the weather event ends.
- Visual weather effects (particles, lighting, screen effects) match the active weather type.
- A weather banner at the top of the screen shows the current weather and a countdown timer.
- Music transitions smoothly between joyful, gloomy, suspenseful, and intense tracks based on weather severity.
- The full earnings formula becomes: `baseEarnings * sizeMult * baseMutationMult * weatherMutationMult`.

---

## 2. Prerequisites

Phase 5 must be fully complete and tested before starting Phase 6. Specifically:

- `src/server/Services/BaseService.luau` provides base management, capacity upgrades, and the sell system.
- `src/server/Services/EarningsService.luau` already uses Approach B (recompute from base values) with the formula `baseEarnings * sizeMult * baseMutMult * weatherMutMult` where `weatherMutMult` returns `1.0` for `nil` weather mutations.
- `src/shared/Config/Mutations.luau` already defines `WEATHER_MUTATIONS` data table with all 7 weather mutation entries (Soaked, Frozen, Shocked, Starstrucked, Burnt, Radiated, Gravitated) and provides `getWeatherMutationMultiplier()`.
- `src/server/Services/DataService.luau` handles player data persistence including the `weatherMutation` field on BrainrotInstance (currently always `nil`).
- `src/server/Remotes/init.luau` defines all existing remotes.
- `src/server/init.server.luau` boots all server services in order.
- `src/client/init.client.luau` boots all client controllers in order.
- `rojo build` succeeds and the game runs without console errors.

---

## 3. Files to Create/Modify

Every file is listed with its full path relative to the project root.

### New Files to Create (3 files)

| # | File Path | Purpose |
|---|---|---|
| 1 | `src/shared/Config/Weather.luau` | Weather event definitions (types, weights, durations, mutation mappings, mutation chances) |
| 2 | `src/server/Services/WeatherService.luau` | Global weather event cycle, mutation application logic, server-side weather state management |
| 3 | `src/client/Controllers/WeatherUI.luau` | Weather banner with countdown, visual weather effects (particles, lighting, screen effects), music transition system |

### Files to Modify (5 files)

| # | File Path | Change |
|---|---|---|
| 1 | `src/server/Services/EarningsService.luau` | Verify weather mutation multiplier is included in recalculation (should already be there from Phase 4 Approach B) |
| 2 | `src/server/Remotes/init.luau` | Add `WeatherChanged` (S->C) and `BrainrotMutated` (S->C) RemoteEvents |
| 3 | `src/client/Controllers/BaseUI.luau` | Listen for `BrainrotMutated` remote; add weather mutation visual effects to brainrot models; update BillboardGui to show weather mutation name |
| 4 | `src/server/init.server.luau` | Add WeatherService to the server boot order (after EarningsService, DataService) |
| 5 | `src/client/init.client.luau` | Add WeatherUI to the client boot order |

---

## 4. Detailed Spec Per File

---

### 4.1 `src/shared/Config/Weather.luau` (CREATE)

**Purpose:** Defines all weather event types with their spawn weights, durations, associated mutations, and per-brainrot mutation application chances. This is a shared module accessible to both server and client code. It has zero dependencies on other project files.

**Returns:** A table named `Weather` containing the data table and utility constants.

**Data table:**

#### WEATHER_EVENTS

A dictionary keyed by weather event name. Each entry contains the event's properties.

```luau
local WEATHER_EVENTS = {
    Clear = {
        spawnWeight = 40,
        minDuration = 0,            -- N/A: Clear has no active duration
        maxDuration = 0,
        mutation = nil,             -- No mutation applied during Clear
        mutationChance = 0,         -- N/A
        severity = 0,               -- Used for music selection (0 = joyful)
        description = "Clear skies. Nothing happens.",
    },
    Rain = {
        spawnWeight = 25,
        minDuration = 60,
        maxDuration = 120,
        mutation = "Soaked",
        mutationChance = 0.15,      -- 15% per brainrot
        severity = 1,               -- Gloomy
        description = "Rain falls from the sky. Brainrots may get Soaked.",
    },
    Snow = {
        spawnWeight = 15,
        minDuration = 60,
        maxDuration = 120,
        mutation = "Frozen",
        mutationChance = 0.12,      -- 12% per brainrot
        severity = 1,               -- Gloomy
        description = "Snowflakes blanket the world. Brainrots may get Frozen.",
    },
    Storm = {
        spawnWeight = 10,
        minDuration = 45,
        maxDuration = 90,
        mutation = "Shocked",
        mutationChance = 0.10,      -- 10% per brainrot
        severity = 2,               -- Suspenseful
        description = "Lightning strikes! Brainrots may get Shocked.",
    },
    ["Meteor Shower"] = {
        spawnWeight = 5,
        minDuration = 30,
        maxDuration = 60,
        mutation = "Starstrucked",
        mutationChance = 0.08,      -- 8% per brainrot
        severity = 2,               -- Suspenseful
        description = "Meteors streak across the sky. Brainrots may get Starstrucked.",
    },
    ["Solar Flare"] = {
        spawnWeight = 3,
        minDuration = 30,
        maxDuration = 60,
        mutation = "Burnt",
        mutationChance = 0.05,      -- 5% per brainrot
        severity = 3,               -- Intense
        description = "The sun erupts! Brainrots may get Burnt.",
    },
    Nuclear = {
        spawnWeight = 1.5,
        minDuration = 20,
        maxDuration = 45,
        mutation = "Radiated",
        mutationChance = 0.03,      -- 3% per brainrot
        severity = 3,               -- Intense
        description = "Nuclear fallout! Brainrots may get Radiated.",
    },
    ["Black Hole"] = {
        spawnWeight = 0.5,
        minDuration = 15,
        maxDuration = 30,
        mutation = "Gravitated",
        mutationChance = 0.01,      -- 1% per brainrot
        severity = 3,               -- Intense
        description = "A black hole appears! Brainrots may get Gravitated.",
    },
}
```

#### WEATHER_CYCLE_INTERVAL

The time range (in seconds) between weather rolls.

```luau
local WEATHER_CYCLE_MIN = 120   -- minimum seconds between weather rolls
local WEATHER_CYCLE_MAX = 300   -- maximum seconds between weather rolls
```

#### SEVERITY_LABELS

A lookup table mapping severity numbers to human-readable labels (used for music selection).

```luau
local SEVERITY_LABELS = {
    [0] = "Joyful",       -- Clear
    [1] = "Gloomy",       -- Rain, Snow
    [2] = "Suspenseful",  -- Storm, Meteor Shower
    [3] = "Intense",      -- Solar Flare, Nuclear, Black Hole
}
```

#### WEATHER_ORDER

An ordered array of weather event names sorted by spawn weight (most common first). Used for display or iteration purposes.

```luau
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
```

**Functions:**

```luau
function Weather.getEvent(weatherType: string): WeatherEventConfig?
```
- Returns the full event config table for a given weather type name.
- **Step by step:**
  1. Look up `WEATHER_EVENTS[weatherType]`.
  2. If found, return the table.
  3. If not found, warn and return `nil`.

```luau
function Weather.getSeverity(weatherType: string): number
```
- Returns the severity level (0-3) for a given weather type.
- **Step by step:**
  1. Look up `WEATHER_EVENTS[weatherType]`.
  2. If found, return `.severity`.
  3. If not found, return `0` (default to Clear).

```luau
function Weather.getSeverityLabel(severity: number): string
```
- Returns the human-readable severity label ("Joyful", "Gloomy", "Suspenseful", "Intense").
- **Step by step:**
  1. Look up `SEVERITY_LABELS[severity]`.
  2. If found, return it.
  3. If not found, return `"Joyful"`.

**Module return structure:**

```luau
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
```

---

### 4.2 `src/server/Services/WeatherService.luau` (CREATE)

**Purpose:** Manages the global weather event cycle on the server. Periodically rolls a new weather event, applies weather mutations to eligible brainrots across all players, and fires remotes to notify clients of weather changes and individual brainrot mutations.

**Dependencies:**

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Weather = require(ReplicatedStorage.Shared.Config.Weather)
local Mutations = require(ReplicatedStorage.Shared.Config.Mutations)
local DataService = require(script.Parent.DataService)
local EarningsService = require(script.Parent.EarningsService)
local Remotes = require(ReplicatedStorage.Shared.Remotes)  -- adjust path as needed
```

**State:**

```luau
local currentWeather: string = "Clear"
local weatherEndTime: number = 0      -- os.clock() timestamp when current weather ends
local isRunning: boolean = false
```

**Public API:**

```luau
function WeatherService.init()
```
- Starts the weather cycle. Called once during server boot.
- **Step by step:**
  1. Set `isRunning = true`.
  2. Set `currentWeather = "Clear"`.
  3. Fire `Remotes.WeatherChanged:FireAllClients({ weather = "Clear", duration = 0, endTime = 0 })` to initialize all clients.
  4. Spawn the `weatherCycle()` coroutine via `task.spawn`.

```luau
function WeatherService.getCurrentWeather(): string
```
- Returns the current active weather type name.
- Used by other services if they need to query the current weather.

```luau
function WeatherService.getWeatherEndTime(): number
```
- Returns the `os.clock()` timestamp when the current weather event ends.
- Returns `0` if weather is Clear.

**Internal functions (not exported):**

```luau
local function rollWeatherType(): string
```
- Performs a weighted random roll across all `WEATHER_EVENTS` to select the next weather type.
- **Step by step:**
  1. Compute `totalWeight` by summing `.spawnWeight` for all entries in `WEATHER_EVENTS`. (40 + 25 + 15 + 10 + 5 + 3 + 1.5 + 0.5 = 100)
  2. Generate `roll = math.random() * totalWeight`.
  3. Iterate through `Weather.WEATHER_ORDER`. For each weather name:
     a. Get the event config via `Weather.getEvent(name)`.
     b. Subtract `event.spawnWeight` from `roll`.
     c. If `roll <= 0`, return this weather name.
  4. Fallback (should never reach): return `"Clear"`.

```luau
local function rollDuration(weatherType: string): number
```
- Returns a random duration (in seconds) for a given weather type within its defined range.
- **Step by step:**
  1. Get event config via `Weather.getEvent(weatherType)`.
  2. If `event.minDuration == 0` (i.e., Clear), return `0`.
  3. Return `math.random(event.minDuration, event.maxDuration)`.

```luau
local function applyWeatherMutations(weatherType: string)
```
- For each online player, iterates their owned brainrots and rolls for weather mutation application.
- **RULE:** A brainrot can only get ONE weather mutation ever. If `brainrot.weatherMutation` is already non-nil, skip it. Higher rarity weather does NOT replace an existing lower rarity weather mutation.
- **Step by step:**
  1. Get the event config: `local event = Weather.getEvent(weatherType)`.
  2. If `event.mutation == nil` (e.g., Clear), return immediately.
  3. For each player in `Players:GetPlayers()`:
     a. Get player data: `local data = DataService.getData(player)`.
     b. If `data == nil`, skip this player.
     c. For each brainrot in `data.ownedBrainrots`:
        i. If `brainrot.weatherMutation ~= nil`, skip (already has a weather mutation).
        ii. Roll `math.random()`. If the roll is less than `event.mutationChance`:
            - Set `brainrot.weatherMutation = event.mutation`.
            - Recalculate earnings: `EarningsService.recalculate(player)`.
            - Fire client notification: `Remotes.BrainrotMutated:FireClient(player, { brainrotId = brainrot.id, weatherMutation = event.mutation })`.

**Important performance note:** `EarningsService.recalculate(player)` should only be called once per player after all their brainrots have been processed, not once per brainrot. Optimize the loop:

```luau
local function applyWeatherMutations(weatherType: string)
    local event = Weather.getEvent(weatherType)
    if not event or not event.mutation then
        return
    end

    for _, player in Players:GetPlayers() do
        local data = DataService.getData(player)
        if not data then
            continue
        end

        local anyMutated = false
        for _, brainrot in data.ownedBrainrots do
            if brainrot.weatherMutation ~= nil then
                continue  -- already has a weather mutation, skip
            end

            if math.random() < event.mutationChance then
                brainrot.weatherMutation = event.mutation
                anyMutated = true

                -- Notify client about this specific brainrot's new mutation
                Remotes.BrainrotMutated:FireClient(player, {
                    brainrotId = brainrot.id,
                    weatherMutation = event.mutation,
                })
            end
        end

        -- Recalculate earnings once for this player if any brainrots were mutated
        if anyMutated then
            EarningsService.recalculate(player)
        end
    end
end
```

```luau
local function weatherCycle()
```
- The main infinite loop that drives the weather system. Runs as a spawned coroutine.
- **Step by step:**
  1. Loop forever while `isRunning`:
     a. Wait a random interval: `task.wait(math.random(Weather.WEATHER_CYCLE_MIN, Weather.WEATHER_CYCLE_MAX))`.
     b. Roll new weather: `local newWeather = rollWeatherType()`.
     c. Set `currentWeather = newWeather`.
     d. If `newWeather == "Clear"`:
        i. Set `weatherEndTime = 0`.
        ii. Fire `Remotes.WeatherChanged:FireAllClients({ weather = "Clear", duration = 0, endTime = 0 })`.
        iii. Continue to next iteration (back to step a).
     e. If `newWeather ~= "Clear"`:
        i. Roll duration: `local duration = rollDuration(newWeather)`.
        ii. Set `weatherEndTime = os.clock() + duration`.
        iii. Fire `Remotes.WeatherChanged:FireAllClients({ weather = newWeather, duration = duration, endTime = weatherEndTime })`.
        iv. Apply mutations: `applyWeatherMutations(newWeather)`.
        v. Wait for the weather to end: `task.wait(duration)`.
        vi. Set `currentWeather = "Clear"`.
        vii. Set `weatherEndTime = 0`.
        viii. Fire `Remotes.WeatherChanged:FireAllClients({ weather = "Clear", duration = 0, endTime = 0 })`.
  2. End of loop.

**Late-joining players:** When a player joins mid-weather-event, they need to know the current weather. Add a `PlayerAdded` listener:

```luau
Players.PlayerAdded:Connect(function(player)
    -- Send current weather state to the new player
    task.defer(function()
        Remotes.WeatherChanged:FireClient(player, {
            weather = currentWeather,
            duration = 0,  -- don't send original duration
            endTime = weatherEndTime,  -- client can compute remaining time
        })
    end)
end)
```

**Module return structure:**

```luau
return {
    init = WeatherService.init,
    getCurrentWeather = WeatherService.getCurrentWeather,
    getWeatherEndTime = WeatherService.getWeatherEndTime,
}
```

---

### 4.3 `src/server/Services/EarningsService.luau` (MODIFY -- verify)

**What changes:** Verify that the `recalculate()` function already includes the weather mutation multiplier. If Phase 4 was implemented with Approach B (recommended), this should already be in place.

**Expected existing code in `recalculate()` (from Phase 4 Approach B):**

```luau
local weatherMutMult = Mutations.getWeatherMutationMultiplier(brainrot.weatherMutation)
local computed = baseEarnings * sizeMult * baseMutMult * weatherMutMult
```

**If this is NOT present:** Add the weather mutation multiplier to the computation:

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
            local sizeMult = brainrot.size  -- size IS the multiplier (Phase 3)
            local baseMutMult = Mutations.getBaseMutationMultiplier(brainrot.baseMutation)
            local weatherMutMult = Mutations.getWeatherMutationMultiplier(brainrot.weatherMutation)

            local computed = baseEarnings * sizeMult * baseMutMult * weatherMutMult
            brainrot.earningsPerSec = computed  -- update stored value
            total = total + computed
        else
            total = total + brainrot.earningsPerSec
        end
    end

    earningsCache[player] = total
    Remotes.EarningsUpdated:FireClient(player, { earningsPerSec = total })
end
```

**No new dependencies required** -- `Config/Mutations` with `getWeatherMutationMultiplier()` was already added in Phase 4.

**Full earnings formula (Phase 6):**

```
earningsPerSec = baseEarnings * sizeMult * baseMutationMult * weatherMutationMult
```

All four factors are now active. The weather mutation multiplier is no longer always `1.0`.

---

### 4.4 `src/server/Remotes/init.luau` (MODIFY)

**What changes:** Add two new server-to-client RemoteEvents for the weather system.

**New remotes to add:**

```luau
-- Weather System (Phase 6)
local WeatherChanged = Instance.new("RemoteEvent")
WeatherChanged.Name = "WeatherChanged"
WeatherChanged.Parent = remotesFolder

local BrainrotMutated = Instance.new("RemoteEvent")
BrainrotMutated.Name = "BrainrotMutated"
BrainrotMutated.Parent = remotesFolder
```

**Add to the returned module table:**

```luau
return {
    -- ... existing remotes ...

    -- Phase 6: Weather System
    WeatherChanged = WeatherChanged,      -- S->C: { weather: string, duration: number, endTime: number }
    BrainrotMutated = BrainrotMutated,    -- S->C: { brainrotId: string, weatherMutation: string }
}
```

**Payload schemas:**

| Remote | Direction | Payload |
|---|---|---|
| `WeatherChanged` | Server -> Client | `{ weather: string, duration: number, endTime: number }` |
| `BrainrotMutated` | Server -> Client | `{ brainrotId: string, weatherMutation: string }` |

- `WeatherChanged.weather`: The weather type name (e.g., "Rain", "Clear", "Black Hole").
- `WeatherChanged.duration`: The total duration of the weather event in seconds (0 for Clear).
- `WeatherChanged.endTime`: The `os.clock()` timestamp when the weather ends (0 for Clear). Clients use this to compute remaining time.
- `BrainrotMutated.brainrotId`: The unique ID of the brainrot that received a weather mutation.
- `BrainrotMutated.weatherMutation`: The name of the weather mutation applied (e.g., "Soaked", "Frozen").

---

### 4.5 `src/client/Controllers/WeatherUI.luau` (CREATE)

**Purpose:** Manages all client-side weather presentation: the weather banner with countdown timer, visual particle/lighting effects for each weather type, and the music transition system that shifts atmosphere based on weather severity.

**Dependencies:**

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local Weather = require(ReplicatedStorage.Shared.Config.Weather)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
```

**State:**

```luau
local currentWeather: string = "Clear"
local weatherEndTime: number = 0
local activeEffects: { Instance } = {}  -- track all effect instances for cleanup
local currentMusicTrack: Sound? = nil
local bannerFrame: Frame? = nil
local bannerLabel: TextLabel? = nil
local countdownLabel: TextLabel? = nil
local descriptionLabel: TextLabel? = nil
```

#### 4.5.1 Weather Banner UI

Create a ScreenGui with a banner Frame anchored to the top-center of the screen.

```luau
local function createBannerUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "WeatherUI"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 5
    screenGui.Parent = playerGui

    bannerFrame = Instance.new("Frame")
    bannerFrame.Name = "WeatherBanner"
    bannerFrame.Size = UDim2.new(0.4, 0, 0, 80)
    bannerFrame.Position = UDim2.new(0.3, 0, 0, -100)  -- starts offscreen (above)
    bannerFrame.AnchorPoint = Vector2.new(0, 0)
    bannerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    bannerFrame.BackgroundTransparency = 0.3
    bannerFrame.BorderSizePixel = 0
    bannerFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = bannerFrame

    -- Weather name label
    bannerLabel = Instance.new("TextLabel")
    bannerLabel.Name = "WeatherName"
    bannerLabel.Size = UDim2.new(1, -20, 0, 30)
    bannerLabel.Position = UDim2.new(0, 10, 0, 5)
    bannerLabel.BackgroundTransparency = 1
    bannerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    bannerLabel.TextScaled = true
    bannerLabel.Font = Enum.Font.GothamBold
    bannerLabel.Text = ""
    bannerLabel.Parent = bannerFrame

    -- Countdown timer label
    countdownLabel = Instance.new("TextLabel")
    countdownLabel.Name = "Countdown"
    countdownLabel.Size = UDim2.new(1, -20, 0, 20)
    countdownLabel.Position = UDim2.new(0, 10, 0, 32)
    countdownLabel.BackgroundTransparency = 1
    countdownLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    countdownLabel.TextScaled = true
    countdownLabel.Font = Enum.Font.Gotham
    countdownLabel.Text = ""
    countdownLabel.Parent = bannerFrame

    -- Description label
    descriptionLabel = Instance.new("TextLabel")
    descriptionLabel.Name = "Description"
    descriptionLabel.Size = UDim2.new(1, -20, 0, 18)
    descriptionLabel.Position = UDim2.new(0, 10, 0, 54)
    descriptionLabel.BackgroundTransparency = 1
    descriptionLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
    descriptionLabel.TextScaled = true
    descriptionLabel.Font = Enum.Font.Gotham
    descriptionLabel.Text = ""
    descriptionLabel.Parent = bannerFrame
end
```

**Banner behavior:**
- When weather changes to non-Clear: Tween the banner down from offscreen (`Position.Y = -100`) to visible (`Position.Y = 10`) over 0.4 seconds. Update text labels.
- When weather changes to Clear: Tween the banner up offscreen over 0.4 seconds.
- Every frame (via `RunService.RenderStepped`), update the countdown label: `"Time remaining: Xs"` where X = `math.max(0, math.ceil(weatherEndTime - os.clock()))`.

```luau
local function showBanner(weatherType: string)
    local event = Weather.getEvent(weatherType)
    if not event then return end

    bannerLabel.Text = weatherType
    descriptionLabel.Text = event.description
    bannerLabel.TextColor3 = getWeatherColor(weatherType)  -- see color mapping below

    local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(bannerFrame, tweenInfo, { Position = UDim2.new(0.3, 0, 0, 10) }):Play()
end

local function hideBanner()
    local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    TweenService:Create(bannerFrame, tweenInfo, { Position = UDim2.new(0.3, 0, 0, -100) }):Play()
end
```

**Weather-specific banner colors:**

```luau
local WEATHER_COLORS = {
    Clear = Color3.fromRGB(255, 255, 200),        -- Warm yellow
    Rain = Color3.fromRGB(100, 150, 255),          -- Blue
    Snow = Color3.fromRGB(200, 220, 255),          -- Ice blue
    Storm = Color3.fromRGB(255, 255, 100),         -- Electric yellow
    ["Meteor Shower"] = Color3.fromRGB(255, 160, 50),  -- Orange
    ["Solar Flare"] = Color3.fromRGB(255, 100, 30),    -- Hot orange
    Nuclear = Color3.fromRGB(100, 255, 50),        -- Radioactive green
    ["Black Hole"] = Color3.fromRGB(180, 50, 255), -- Purple
}

local function getWeatherColor(weatherType: string): Color3
    return WEATHER_COLORS[weatherType] or Color3.fromRGB(255, 255, 255)
end
```

#### 4.5.2 Visual Weather Effects

Each weather type has a unique set of visual effects. All effects are created when weather starts and destroyed when weather ends (or changes).

**Cleanup function:**

```luau
local function clearAllEffects()
    for _, effect in activeEffects do
        if effect and effect.Parent then
            effect:Destroy()
        end
    end
    table.clear(activeEffects)

    -- Reset lighting to defaults
    Lighting.Ambient = Color3.fromRGB(127, 127, 127)
    Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
    Lighting.Brightness = 2
    Lighting.FogEnd = 100000
    Lighting.FogColor = Color3.fromRGB(192, 192, 192)

    -- Remove any ColorCorrection or Blur effects added by weather
    for _, child in Lighting:GetChildren() do
        if child.Name == "WeatherEffect" then
            child:Destroy()
        end
    end
end
```

**Per-weather effect functions:**

Each function creates the appropriate visual effects and adds them to `activeEffects` for cleanup.

```luau
local function applyRainEffects()
    -- ParticleEmitter attached to workspace.CurrentCamera for rain drops
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "WeatherEffect"
    emitter.Rate = 200
    emitter.Lifetime = NumberRange.new(1, 2)
    emitter.Speed = NumberRange.new(40, 60)
    emitter.SpreadAngle = Vector2.new(10, 10)
    emitter.EmissionDirection = Enum.NormalId.Bottom
    emitter.Color = ColorSequence.new(Color3.fromRGB(150, 180, 255))
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(1, 0.05),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 0.8),
    })
    -- Attach to a Part above the player (or use Lighting atmosphere)
    -- Implementation: Create an invisible Part at camera position + 50 studs up
    local rainPart = Instance.new("Part")
    rainPart.Name = "WeatherEffect"
    rainPart.Anchored = true
    rainPart.CanCollide = false
    rainPart.Transparency = 1
    rainPart.Size = Vector3.new(100, 1, 100)
    rainPart.Position = workspace.CurrentCamera.CFrame.Position + Vector3.new(0, 50, 0)
    rainPart.Parent = workspace
    emitter.Parent = rainPart
    table.insert(activeEffects, rainPart)

    -- Darken lighting slightly
    Lighting.Ambient = Color3.fromRGB(80, 80, 100)
    Lighting.Brightness = 1.2
    Lighting.FogEnd = 500
    Lighting.FogColor = Color3.fromRGB(120, 130, 150)
end

local function applySnowEffects()
    -- Snowflake ParticleEmitter
    local snowPart = Instance.new("Part")
    snowPart.Name = "WeatherEffect"
    snowPart.Anchored = true
    snowPart.CanCollide = false
    snowPart.Transparency = 1
    snowPart.Size = Vector3.new(120, 1, 120)
    snowPart.Position = workspace.CurrentCamera.CFrame.Position + Vector3.new(0, 50, 0)
    snowPart.Parent = workspace

    local emitter = Instance.new("ParticleEmitter")
    emitter.Rate = 150
    emitter.Lifetime = NumberRange.new(3, 5)
    emitter.Speed = NumberRange.new(5, 15)
    emitter.SpreadAngle = Vector2.new(60, 60)
    emitter.EmissionDirection = Enum.NormalId.Bottom
    emitter.Color = ColorSequence.new(Color3.fromRGB(230, 240, 255))
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 0.1),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 0.5),
    })
    emitter.RotSpeed = NumberRange.new(-90, 90)
    emitter.Parent = snowPart
    table.insert(activeEffects, snowPart)

    -- Blue-tinted lighting
    Lighting.Ambient = Color3.fromRGB(100, 110, 140)
    Lighting.Brightness = 1.5
    Lighting.FogEnd = 400
    Lighting.FogColor = Color3.fromRGB(180, 190, 210)

    local colorCorrection = Instance.new("ColorCorrectionEffect")
    colorCorrection.Name = "WeatherEffect"
    colorCorrection.TintColor = Color3.fromRGB(200, 210, 255)
    colorCorrection.Parent = Lighting
    table.insert(activeEffects, colorCorrection)
end

local function applyStormEffects()
    -- Dark lighting
    Lighting.Ambient = Color3.fromRGB(40, 40, 60)
    Lighting.Brightness = 0.8
    Lighting.FogEnd = 300
    Lighting.FogColor = Color3.fromRGB(60, 60, 80)

    -- Rain (reuse rain particles but heavier)
    local stormPart = Instance.new("Part")
    stormPart.Name = "WeatherEffect"
    stormPart.Anchored = true
    stormPart.CanCollide = false
    stormPart.Transparency = 1
    stormPart.Size = Vector3.new(100, 1, 100)
    stormPart.Position = workspace.CurrentCamera.CFrame.Position + Vector3.new(0, 50, 0)
    stormPart.Parent = workspace

    local emitter = Instance.new("ParticleEmitter")
    emitter.Rate = 400
    emitter.Lifetime = NumberRange.new(0.5, 1.0)
    emitter.Speed = NumberRange.new(60, 80)
    emitter.SpreadAngle = Vector2.new(20, 20)
    emitter.EmissionDirection = Enum.NormalId.Bottom
    emitter.Color = ColorSequence.new(Color3.fromRGB(180, 190, 220))
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.15),
        NumberSequenceKeypoint.new(1, 0.05),
    })
    emitter.Parent = stormPart
    table.insert(activeEffects, stormPart)

    -- Lightning flashes: periodic screen flash + camera shake
    task.spawn(function()
        while currentWeather == "Storm" do
            task.wait(math.random(3, 8))  -- random interval between lightning strikes
            if currentWeather ~= "Storm" then break end

            -- Screen flash
            local flash = Instance.new("ColorCorrectionEffect")
            flash.Name = "WeatherEffect"
            flash.Brightness = 1.5
            flash.Parent = Lighting
            table.insert(activeEffects, flash)

            task.wait(0.1)
            flash.Brightness = 0
            task.wait(0.05)
            flash.Brightness = 0.8
            task.wait(0.05)
            flash.Brightness = 0
            task.delay(0.5, function()
                if flash and flash.Parent then
                    flash:Destroy()
                end
            end)

            -- Camera shake (small offset)
            local camera = workspace.CurrentCamera
            if camera then
                local originalCFrame = camera.CFrame
                for i = 1, 5 do
                    local shakeOffset = Vector3.new(
                        math.random(-10, 10) / 50,
                        math.random(-10, 10) / 50,
                        0
                    )
                    camera.CFrame = originalCFrame * CFrame.new(shakeOffset)
                    task.wait(0.02)
                end
                camera.CFrame = originalCFrame
            end
        end
    end)
end

local function applyMeteorShowerEffects()
    -- Orange-tinted lighting
    Lighting.Ambient = Color3.fromRGB(140, 100, 60)
    Lighting.Brightness = 1.8

    local colorCorrection = Instance.new("ColorCorrectionEffect")
    colorCorrection.Name = "WeatherEffect"
    colorCorrection.TintColor = Color3.fromRGB(255, 200, 150)
    colorCorrection.Parent = Lighting
    table.insert(activeEffects, colorCorrection)

    -- Meteor streak particles moving across the sky
    local meteorPart = Instance.new("Part")
    meteorPart.Name = "WeatherEffect"
    meteorPart.Anchored = true
    meteorPart.CanCollide = false
    meteorPart.Transparency = 1
    meteorPart.Size = Vector3.new(200, 1, 200)
    meteorPart.Position = workspace.CurrentCamera.CFrame.Position + Vector3.new(0, 80, 0)
    meteorPart.Parent = workspace

    local emitter = Instance.new("ParticleEmitter")
    emitter.Rate = 8
    emitter.Lifetime = NumberRange.new(1, 2)
    emitter.Speed = NumberRange.new(80, 120)
    emitter.SpreadAngle = Vector2.new(30, 30)
    emitter.EmissionDirection = Enum.NormalId.Left
    emitter.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 80, 20)),
    })
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 2),
        NumberSequenceKeypoint.new(0.5, 1),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.LightEmission = 1
    emitter.Parent = meteorPart
    table.insert(activeEffects, meteorPart)
end

local function applySolarFlareEffects()
    -- Intense warm glow
    Lighting.Ambient = Color3.fromRGB(180, 120, 40)
    Lighting.Brightness = 3.0

    local colorCorrection = Instance.new("ColorCorrectionEffect")
    colorCorrection.Name = "WeatherEffect"
    colorCorrection.TintColor = Color3.fromRGB(255, 180, 100)
    colorCorrection.Saturation = 0.3
    colorCorrection.Parent = Lighting
    table.insert(activeEffects, colorCorrection)

    -- Screen heat shimmer effect (Blur oscillation)
    local blur = Instance.new("BlurEffect")
    blur.Name = "WeatherEffect"
    blur.Size = 0
    blur.Parent = Lighting
    table.insert(activeEffects, blur)

    task.spawn(function()
        while currentWeather == "Solar Flare" do
            -- Oscillate blur to create heat shimmer
            local tweenIn = TweenService:Create(blur, TweenInfo.new(1, Enum.EasingStyle.Sine), { Size = 6 })
            tweenIn:Play()
            tweenIn.Completed:Wait()
            if currentWeather ~= "Solar Flare" then break end
            local tweenOut = TweenService:Create(blur, TweenInfo.new(1, Enum.EasingStyle.Sine), { Size = 2 })
            tweenOut:Play()
            tweenOut.Completed:Wait()
        end
    end)
end

local function applyNuclearEffects()
    -- Green tint
    Lighting.Ambient = Color3.fromRGB(60, 120, 40)
    Lighting.Brightness = 1.0
    Lighting.FogEnd = 250
    Lighting.FogColor = Color3.fromRGB(80, 120, 60)

    local colorCorrection = Instance.new("ColorCorrectionEffect")
    colorCorrection.Name = "WeatherEffect"
    colorCorrection.TintColor = Color3.fromRGB(150, 255, 100)
    colorCorrection.Saturation = -0.3
    colorCorrection.Contrast = 0.2
    colorCorrection.Parent = Lighting
    table.insert(activeEffects, colorCorrection)

    -- Radiation particles rising from the ground
    local radPart = Instance.new("Part")
    radPart.Name = "WeatherEffect"
    radPart.Anchored = true
    radPart.CanCollide = false
    radPart.Transparency = 1
    radPart.Size = Vector3.new(150, 1, 150)
    radPart.Position = workspace.CurrentCamera.CFrame.Position + Vector3.new(0, -5, 0)
    radPart.Parent = workspace

    local emitter = Instance.new("ParticleEmitter")
    emitter.Rate = 50
    emitter.Lifetime = NumberRange.new(2, 4)
    emitter.Speed = NumberRange.new(3, 8)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.EmissionDirection = Enum.NormalId.Top
    emitter.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 255, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 200, 30)),
    })
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.LightEmission = 0.5
    emitter.Parent = radPart
    table.insert(activeEffects, radPart)
end

local function applyBlackHoleEffects()
    -- Purple/dark atmosphere
    Lighting.Ambient = Color3.fromRGB(40, 20, 60)
    Lighting.Brightness = 0.5
    Lighting.FogEnd = 200
    Lighting.FogColor = Color3.fromRGB(30, 10, 50)

    local colorCorrection = Instance.new("ColorCorrectionEffect")
    colorCorrection.Name = "WeatherEffect"
    colorCorrection.TintColor = Color3.fromRGB(150, 80, 255)
    colorCorrection.Saturation = -0.5
    colorCorrection.Contrast = 0.4
    colorCorrection.Parent = Lighting
    table.insert(activeEffects, colorCorrection)

    -- Screen distortion (Blur)
    local blur = Instance.new("BlurEffect")
    blur.Name = "WeatherEffect"
    blur.Size = 8
    blur.Parent = Lighting
    table.insert(activeEffects, blur)

    -- Purple vortex particles spiraling inward
    local vortexPart = Instance.new("Part")
    vortexPart.Name = "WeatherEffect"
    vortexPart.Anchored = true
    vortexPart.CanCollide = false
    vortexPart.Transparency = 1
    vortexPart.Size = Vector3.new(1, 1, 1)
    vortexPart.Position = workspace.CurrentCamera.CFrame.Position + Vector3.new(0, 30, 0)
    vortexPart.Parent = workspace

    local emitter = Instance.new("ParticleEmitter")
    emitter.Rate = 80
    emitter.Lifetime = NumberRange.new(1, 3)
    emitter.Speed = NumberRange.new(10, 30)
    emitter.SpreadAngle = Vector2.new(360, 360)
    emitter.EmissionDirection = Enum.NormalId.Top
    emitter.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 50, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 0, 180)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 0, 40)),
    })
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 3),
        NumberSequenceKeypoint.new(0.5, 1),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.LightEmission = 0.8
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 0.8),
    })
    emitter.RotSpeed = NumberRange.new(180, 360)
    emitter.Parent = vortexPart
    table.insert(activeEffects, vortexPart)

    -- Intense camera pull effect (subtle drift toward center)
    task.spawn(function()
        while currentWeather == "Black Hole" do
            local camera = workspace.CurrentCamera
            if camera then
                local pullDirection = (vortexPart.Position - camera.CFrame.Position).Unit
                camera.CFrame = camera.CFrame * CFrame.new(pullDirection * 0.02)
            end
            task.wait(0.03)
        end
    end)
end
```

**Effect dispatch:**

```luau
local WEATHER_EFFECT_FUNCTIONS = {
    Rain = applyRainEffects,
    Snow = applySnowEffects,
    Storm = applyStormEffects,
    ["Meteor Shower"] = applyMeteorShowerEffects,
    ["Solar Flare"] = applySolarFlareEffects,
    Nuclear = applyNuclearEffects,
    ["Black Hole"] = applyBlackHoleEffects,
}

local function applyWeatherEffects(weatherType: string)
    clearAllEffects()
    local effectFunc = WEATHER_EFFECT_FUNCTIONS[weatherType]
    if effectFunc then
        effectFunc()
    end
end
```

#### 4.5.3 Music System

The music system manages three concurrent music categories that crossfade based on weather severity.

**Music categories by severity:**

| Severity | Label | Weather Types | Music Style |
|---|---|---|---|
| 0 | Joyful | Clear | Upbeat, cheerful background music |
| 1 | Gloomy | Rain, Snow | Calm, melancholic, ambient |
| 2 | Suspenseful | Storm, Meteor Shower | Tense, building, rhythmic |
| 3 | Intense | Solar Flare, Nuclear, Black Hole | Dramatic, thriller, high-energy |

**Music asset IDs:** Placeholder SoundIds are defined below. Replace with actual Roblox audio asset IDs during implementation.

```luau
local MUSIC_TRACKS = {
    [0] = "rbxassetid://JOYFUL_MUSIC_ID",       -- Joyful (Clear)
    [1] = "rbxassetid://GLOOMY_MUSIC_ID",       -- Gloomy (Rain, Snow)
    [2] = "rbxassetid://SUSPENSEFUL_MUSIC_ID",   -- Suspenseful (Storm, Meteor Shower)
    [3] = "rbxassetid://INTENSE_MUSIC_ID",       -- Intense (Solar Flare, Nuclear, Black Hole)
}

local MUSIC_VOLUME = 0.5           -- base volume for all tracks
local MUSIC_FADE_TIME = 2.0        -- seconds to crossfade between tracks
```

**Music transition logic:**

```luau
local currentSeverity: number = 0

local function transitionMusic(newSeverity: number)
    if newSeverity == currentSeverity and currentMusicTrack then
        return  -- already playing the correct track
    end

    currentSeverity = newSeverity
    local newTrackId = MUSIC_TRACKS[newSeverity]
    if not newTrackId then return end

    -- Fade out current track
    if currentMusicTrack then
        local oldTrack = currentMusicTrack
        local fadeOut = TweenService:Create(
            oldTrack,
            TweenInfo.new(MUSIC_FADE_TIME, Enum.EasingStyle.Linear),
            { Volume = 0 }
        )
        fadeOut:Play()
        fadeOut.Completed:Connect(function()
            oldTrack:Stop()
            oldTrack:Destroy()
        end)
    end

    -- Create and fade in new track
    local newTrack = Instance.new("Sound")
    newTrack.Name = "WeatherMusic"
    newTrack.SoundId = newTrackId
    newTrack.Volume = 0
    newTrack.Looped = true
    newTrack.Parent = SoundService
    newTrack:Play()

    currentMusicTrack = newTrack

    local fadeIn = TweenService:Create(
        newTrack,
        TweenInfo.new(MUSIC_FADE_TIME, Enum.EasingStyle.Linear),
        { Volume = MUSIC_VOLUME }
    )
    fadeIn:Play()
end
```

#### 4.5.4 Weather Change Handler

The central handler that responds to `WeatherChanged` remote events:

```luau
local function onWeatherChanged(data: { weather: string, duration: number, endTime: number })
    currentWeather = data.weather
    weatherEndTime = data.endTime

    if data.weather == "Clear" then
        hideBanner()
        clearAllEffects()
        transitionMusic(0)
    else
        showBanner(data.weather)
        applyWeatherEffects(data.weather)

        local severity = Weather.getSeverity(data.weather)
        transitionMusic(severity)
    end
end
```

#### 4.5.5 Countdown Timer Update

```luau
local function updateCountdown(dt: number)
    if currentWeather == "Clear" or weatherEndTime == 0 then
        return
    end

    local remaining = math.max(0, math.ceil(weatherEndTime - os.clock()))
    if countdownLabel then
        if remaining > 0 then
            local minutes = math.floor(remaining / 60)
            local seconds = remaining % 60
            if minutes > 0 then
                countdownLabel.Text = string.format("Time remaining: %d:%02d", minutes, seconds)
            else
                countdownLabel.Text = string.format("Time remaining: %ds", seconds)
            end
        else
            countdownLabel.Text = "Ending..."
        end
    end

    -- Update rain/snow/storm particle positions to follow camera
    for _, effect in activeEffects do
        if effect:IsA("Part") and effect.Name == "WeatherEffect" then
            local cam = workspace.CurrentCamera
            if cam then
                local yPos = effect.Position.Y
                effect.Position = Vector3.new(cam.CFrame.Position.X, yPos, cam.CFrame.Position.Z)
            end
        end
    end
end
```

#### 4.5.6 Public API

```luau
function WeatherUI.init()
    createBannerUI()
    transitionMusic(0)  -- start with joyful music

    Remotes.WeatherChanged.OnClientEvent:Connect(onWeatherChanged)
    RunService.RenderStepped:Connect(updateCountdown)
end
```

**Module return structure:**

```luau
return {
    init = WeatherUI.init,
}
```

---

### 4.6 `src/client/Controllers/BaseUI.luau` (MODIFY)

**What changes:** Listen for the `BrainrotMutated` remote event. When a brainrot receives a weather mutation, add a visual effect matching the weather mutation type and update the BillboardGui to show the weather mutation name.

**New dependency:**

```luau
local Remotes = require(ReplicatedStorage.Shared.Remotes)  -- if not already required
```

**New listener in `BaseUI.init()`:**

```luau
Remotes.BrainrotMutated.OnClientEvent:Connect(function(data)
    onBrainrotMutated(data.brainrotId, data.weatherMutation)
end)
```

**New internal function:**

```luau
local function onBrainrotMutated(brainrotId: string, weatherMutation: string)
    -- Find the visual Part for this brainrot
    local part = brainrotParts[brainrotId]
    if not part or not part.Parent then
        return
    end

    -- Add weather mutation visual effect
    addWeatherMutationEffect(part, weatherMutation)

    -- Update BillboardGui label to include weather mutation
    updateBillboardWithWeatherMutation(brainrotId, weatherMutation)
end
```

**Weather mutation visual effects per type:**

```luau
local WEATHER_MUTATION_EFFECTS = {
    Soaked = {
        color = ColorSequence.new(Color3.fromRGB(100, 150, 255)),
        rate = 20,
        lifetime = NumberRange.new(0.5, 1.5),
        speed = NumberRange.new(1, 3),
        size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(1, 0),
        }),
        direction = Enum.NormalId.Top,
        lightEmission = 0.2,
        description = "Water droplets",
    },
    Frozen = {
        color = ColorSequence.new(Color3.fromRGB(200, 230, 255)),
        rate = 15,
        lifetime = NumberRange.new(1, 2),
        speed = NumberRange.new(0.5, 2),
        size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.4),
            NumberSequenceKeypoint.new(1, 0),
        }),
        direction = Enum.NormalId.Top,
        lightEmission = 0.6,
        description = "Ice crystals",
    },
    Shocked = {
        color = ColorSequence.new(Color3.fromRGB(255, 255, 100)),
        rate = 25,
        lifetime = NumberRange.new(0.2, 0.5),
        speed = NumberRange.new(5, 10),
        size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.3),
            NumberSequenceKeypoint.new(1, 0),
        }),
        direction = Enum.NormalId.Top,
        lightEmission = 1.0,
        description = "Lightning sparks",
    },
    Starstrucked = {
        color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 150)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 50)),
        }),
        rate = 12,
        lifetime = NumberRange.new(1, 3),
        speed = NumberRange.new(1, 4),
        size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(0.5, 0.3),
            NumberSequenceKeypoint.new(1, 0),
        }),
        direction = Enum.NormalId.Top,
        lightEmission = 1.0,
        description = "Floating stars",
    },
    Burnt = {
        color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 20)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 50, 0)),
        }),
        rate = 30,
        lifetime = NumberRange.new(0.3, 1),
        speed = NumberRange.new(3, 8),
        size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.4),
            NumberSequenceKeypoint.new(1, 0),
        }),
        direction = Enum.NormalId.Top,
        lightEmission = 0.8,
        description = "Flames",
    },
    Radiated = {
        color = ColorSequence.new(Color3.fromRGB(100, 255, 50)),
        rate = 18,
        lifetime = NumberRange.new(1, 2.5),
        speed = NumberRange.new(1, 3),
        size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.3),
            NumberSequenceKeypoint.new(1, 0.1),
        }),
        direction = Enum.NormalId.Top,
        lightEmission = 0.7,
        description = "Green glow",
    },
    Gravitated = {
        color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 50, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 0, 200)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 0, 80)),
        }),
        rate = 25,
        lifetime = NumberRange.new(0.5, 1.5),
        speed = NumberRange.new(5, 15),
        size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.6),
            NumberSequenceKeypoint.new(1, 0),
        }),
        direction = Enum.NormalId.Bottom,  -- particles pulled downward (gravity)
        lightEmission = 0.9,
        description = "Purple vortex",
    },
}

local function addWeatherMutationEffect(part: Part, mutation: string)
    -- Remove existing weather mutation emitter if any (should not happen per rules, but defensive)
    local existingEmitter = part:FindFirstChild("WeatherMutationEffect")
    if existingEmitter then
        return  -- already has a weather mutation effect, do not replace
    end

    local config = WEATHER_MUTATION_EFFECTS[mutation]
    if not config then
        warn("Unknown weather mutation for visual effect:", mutation)
        return
    end

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "WeatherMutationEffect"
    emitter.Color = config.color
    emitter.Rate = config.rate
    emitter.Lifetime = config.lifetime
    emitter.Speed = config.speed
    emitter.Size = config.size
    emitter.EmissionDirection = config.direction
    emitter.LightEmission = config.lightEmission
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Parent = part
end
```

**BillboardGui update for weather mutation:**

```luau
local function updateBillboardWithWeatherMutation(brainrotId: string, weatherMutation: string)
    local part = brainrotParts[brainrotId]
    if not part then return end

    local billboard = part:FindFirstChildOfClass("BillboardGui")
    if not billboard then return end

    -- Find or create the weather mutation label
    local weatherLabel = billboard:FindFirstChild("WeatherMutationLabel")
    if not weatherLabel then
        weatherLabel = Instance.new("TextLabel")
        weatherLabel.Name = "WeatherMutationLabel"
        weatherLabel.Size = UDim2.new(1, -20, 0, 16)
        weatherLabel.Position = UDim2.new(0, 10, 1, -18)  -- bottom of billboard
        weatherLabel.BackgroundTransparency = 1
        weatherLabel.TextScaled = true
        weatherLabel.Font = Enum.Font.GothamBold
        weatherLabel.Parent = billboard

        -- Expand billboard to make room
        billboard.Size = billboard.Size + UDim2.new(0, 0, 0, 20)
    end

    -- Set weather mutation text and color
    local mutationColors = {
        Soaked = Color3.fromRGB(100, 150, 255),
        Frozen = Color3.fromRGB(200, 230, 255),
        Shocked = Color3.fromRGB(255, 255, 100),
        Starstrucked = Color3.fromRGB(255, 200, 50),
        Burnt = Color3.fromRGB(255, 100, 20),
        Radiated = Color3.fromRGB(100, 255, 50),
        Gravitated = Color3.fromRGB(180, 50, 255),
    }

    weatherLabel.Text = weatherMutation
    weatherLabel.TextColor3 = mutationColors[weatherMutation] or Color3.fromRGB(255, 255, 255)
end
```

**Also update `spawnBrainrotVisual()` to restore weather mutation visuals on load:**

When spawning brainrot visuals (e.g., on player join when loading saved data), check if the brainrot already has a weather mutation and apply the effect immediately:

```luau
-- At the end of spawnBrainrotVisual(), after all existing Phase 4 visual logic:
if brainrot.weatherMutation then
    addWeatherMutationEffect(part, brainrot.weatherMutation)
    updateBillboardWithWeatherMutation(brainrot.id, brainrot.weatherMutation)
end
```

---

### 4.7 `src/server/init.server.luau` (MODIFY)

**What changes:** Add WeatherService to the server boot sequence. It must be initialized after DataService and EarningsService (since it depends on both).

**Add require:**

```luau
local WeatherService = require(script.Services.WeatherService)
```

**Add init call (after EarningsService.init and DataService.init):**

```luau
WeatherService.init()
```

**Expected boot order (Phase 6):**

```luau
DataService.init()
EarningsService.init()
BaseService.init()
FoodService.init()
SellService.init()      -- Phase 5
WeatherService.init()   -- Phase 6 (NEW)
```

---

### 4.8 `src/client/init.client.luau` (MODIFY)

**What changes:** Add WeatherUI to the client boot sequence.

**Add require:**

```luau
local WeatherUI = require(script.Controllers.WeatherUI)
```

**Add init call:**

```luau
WeatherUI.init()
```

**Expected boot order (Phase 6):**

```luau
MoneyUI.init()
BaseUI.init()
FoodStoreUI.init()
SellUI.init()           -- Phase 5
WeatherUI.init()        -- Phase 6 (NEW)
```

---

## 5. Module Contracts

### New Cross-Module Dependencies (Phase 6)

**WeatherService requires:**

| Module | Function/Field Used | Purpose |
|---|---|---|
| `Config/Weather` | `Weather.WEATHER_EVENTS` | Access weather event definitions |
| `Config/Weather` | `Weather.WEATHER_ORDER` | Iterate weather types in order for weighted roll |
| `Config/Weather` | `Weather.WEATHER_CYCLE_MIN`, `Weather.WEATHER_CYCLE_MAX` | Weather cycle interval range |
| `Config/Weather` | `Weather.getEvent(weatherType)` | Look up event config by name |
| `Config/Mutations` | (implicit, via EarningsService) | Weather mutations already defined in Phase 4 |
| `DataService` | `DataService.getData(player)` | Access player's brainrot data for mutation application |
| `EarningsService` | `EarningsService.recalculate(player)` | Recalculate earnings after weather mutation is applied |
| `Remotes` | `Remotes.WeatherChanged` | Fire to all clients when weather changes |
| `Remotes` | `Remotes.BrainrotMutated` | Fire to specific client when a brainrot gets a weather mutation |

**WeatherUI requires:**

| Module | Function/Field Used | Purpose |
|---|---|---|
| `Config/Weather` | `Weather.getEvent(weatherType)` | Look up event descriptions for banner |
| `Config/Weather` | `Weather.getSeverity(weatherType)` | Determine music category for transitions |
| `Remotes` | `Remotes.WeatherChanged` | Listen for weather change events from server |

**BaseUI now additionally requires:**

| Module | Function/Field Used | Purpose |
|---|---|---|
| `Remotes` | `Remotes.BrainrotMutated` | Listen for weather mutation events on individual brainrots |

**EarningsService (unchanged from Phase 4 Approach B):**

| Module | Function/Field Used | Purpose |
|---|---|---|
| `Config/Mutations` | `Mutations.getWeatherMutationMultiplier(mutation)` | Factor weather mutation into earnings (already present) |

### Existing Contracts (Unchanged)

- WeatherService does NOT modify `brainrot.baseMutation` or `brainrot.size` or any other field. It only sets `brainrot.weatherMutation`.
- DataService persistence automatically saves `weatherMutation` because it is a field on BrainrotInstance (already defined as `nil` in Phase 1).
- The `BrainrotSpawned` remote payload still includes the full BrainrotInstance. New brainrots spawned during a weather event will have `weatherMutation = nil` (mutations are only applied by `applyWeatherMutations`, not at spawn time).
- No changes to FoodService, SellService, or BaseService.

---

## 6. Agent Task Breakdown

Tasks are organized into steps. Steps must be completed in order. Tasks within a step can be done in parallel.

### Step 1 (Parallel -- no inter-dependencies)

| Task | File | Action | Est. Lines |
|---|---|---|---|
| 1.1 | `src/shared/Config/Weather.luau` | CREATE | ~120 |
| 1.2 | `src/server/Remotes/init.luau` | MODIFY | ~10 |

- **1.1 Config/Weather.luau:** Create the complete Weather config module with `WEATHER_EVENTS` table (8 entries), `WEATHER_CYCLE_MIN/MAX`, `SEVERITY_LABELS`, `WEATHER_ORDER`, and utility functions (`getEvent`, `getSeverity`, `getSeverityLabel`).
- **1.2 Remotes/init.luau:** Add `WeatherChanged` and `BrainrotMutated` RemoteEvent instances and include them in the returned table.

### Step 2 (Depends on Step 1)

| Task | File | Action | Est. Lines |
|---|---|---|---|
| 2.1 | `src/server/Services/WeatherService.luau` | CREATE | ~150 |
| 2.2 | `src/server/Services/EarningsService.luau` | VERIFY/MODIFY | ~5 |

- **2.1 WeatherService.luau:** Create the complete weather service with `init()`, `weatherCycle()`, `rollWeatherType()`, `rollDuration()`, `applyWeatherMutations()`, `getCurrentWeather()`, `getWeatherEndTime()`, and `PlayerAdded` handler for late joiners.
- **2.2 EarningsService.luau:** Verify that `Mutations.getWeatherMutationMultiplier(brainrot.weatherMutation)` is already included in the recalculation formula. If not, add it. This should already be present from Phase 4 Approach B.

### Step 3 (Parallel, depends on Step 2)

| Task | File | Action | Est. Lines |
|---|---|---|---|
| 3.1 | `src/client/Controllers/WeatherUI.luau` | CREATE | ~350 |
| 3.2 | `src/client/Controllers/BaseUI.luau` | MODIFY | ~120 |

- **3.1 WeatherUI.luau:** Create the complete client-side weather controller with: banner UI (creation, show/hide, countdown), all 7 weather visual effect functions, music transition system with crossfade, `WeatherChanged` listener, and `RenderStepped` countdown updater.
- **3.2 BaseUI.luau:** Add `BrainrotMutated` listener, `addWeatherMutationEffect()` function with per-mutation ParticleEmitter configs, `updateBillboardWithWeatherMutation()` function, and update `spawnBrainrotVisual()` to restore weather mutations on load.

### Step 4 (Depends on Steps 2 and 3)

| Task | File | Action | Est. Lines Changed |
|---|---|---|---|
| 4.1 | `src/server/init.server.luau` | MODIFY | ~3 |
| 4.2 | `src/client/init.client.luau` | MODIFY | ~3 |

- **4.1 init.server.luau:** Add `require` for WeatherService and call `WeatherService.init()` after EarningsService in the boot order.
- **4.2 init.client.luau:** Add `require` for WeatherUI and call `WeatherUI.init()` after existing controllers.

### Task Dependency Diagram

```
Step 1 (parallel):
  1.1 Config/Weather.luau (CREATE) ---+
  1.2 Remotes/init.luau (MODIFY) -----+
         |
         v
Step 2 (parallel):
  2.1 WeatherService.luau (CREATE) ---+
  2.2 EarningsService.luau (VERIFY) --+
         |
         v
Step 3 (parallel):
  3.1 WeatherUI.luau (CREATE) --------+
  3.2 BaseUI.luau (MODIFY) -----------+
         |
         v
Step 4 (parallel):
  4.1 init.server.luau (MODIFY) ------+
  4.2 init.client.luau (MODIFY) ------+
```

### Total: 3 new files, 5 modified files, ~760 estimated lines of new/changed Luau code.

---

## 7. Data Structures

### 7.1 Weather Config Table Shape

```luau
-- Return value of require(Config.Weather):
{
    WEATHER_EVENTS = {
        Clear = { spawnWeight = 40, minDuration = 0, maxDuration = 0, mutation = nil, mutationChance = 0, severity = 0, description = "..." },
        Rain = { spawnWeight = 25, minDuration = 60, maxDuration = 120, mutation = "Soaked", mutationChance = 0.15, severity = 1, description = "..." },
        Snow = { spawnWeight = 15, minDuration = 60, maxDuration = 120, mutation = "Frozen", mutationChance = 0.12, severity = 1, description = "..." },
        Storm = { spawnWeight = 10, minDuration = 45, maxDuration = 90, mutation = "Shocked", mutationChance = 0.10, severity = 2, description = "..." },
        ["Meteor Shower"] = { spawnWeight = 5, minDuration = 30, maxDuration = 60, mutation = "Starstrucked", mutationChance = 0.08, severity = 2, description = "..." },
        ["Solar Flare"] = { spawnWeight = 3, minDuration = 30, maxDuration = 60, mutation = "Burnt", mutationChance = 0.05, severity = 3, description = "..." },
        Nuclear = { spawnWeight = 1.5, minDuration = 20, maxDuration = 45, mutation = "Radiated", mutationChance = 0.03, severity = 3, description = "..." },
        ["Black Hole"] = { spawnWeight = 0.5, minDuration = 15, maxDuration = 30, mutation = "Gravitated", mutationChance = 0.01, severity = 3, description = "..." },
    },
    WEATHER_CYCLE_MIN = 120,
    WEATHER_CYCLE_MAX = 300,
    SEVERITY_LABELS = { [0] = "Joyful", [1] = "Gloomy", [2] = "Suspenseful", [3] = "Intense" },
    WEATHER_ORDER = { "Clear", "Rain", "Snow", "Storm", "Meteor Shower", "Solar Flare", "Nuclear", "Black Hole" },
    getEvent = function,        -- (string) -> WeatherEventConfig?
    getSeverity = function,     -- (string) -> number
    getSeverityLabel = function, -- (number) -> string
}
```

### 7.2 WeatherChanged Remote Payload Shape

```luau
{
    weather = "Storm",          -- string: weather type name
    duration = 67,              -- number: total duration in seconds (0 for Clear)
    endTime = 1234567.89,       -- number: os.clock() timestamp when weather ends (0 for Clear)
}
```

### 7.3 BrainrotMutated Remote Payload Shape

```luau
{
    brainrotId = "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6",  -- string: unique brainrot ID
    weatherMutation = "Shocked",                         -- string: weather mutation name
}
```

### 7.4 Updated BrainrotInstance (Phase 6 shape)

After Phase 6, the `weatherMutation` field can now be populated (was always `nil` in Phases 1-5).

```luau
-- Example: A Gold Large brainrot with a Soaked weather mutation
{
    id = "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6",
    name = "Tralalero Tralala",
    rarity = "Epic",
    size = 2.10,                     -- from Phase 3
    sizeLabel = "Large",             -- from Phase 3
    weight = 945.0,                  -- baseWeight 450 * 2.10
    baseMutation = "Gold",           -- from Phase 4
    weatherMutation = "Soaked",      -- NEW: populated in Phase 6 (or nil)
    personality = nil,               -- still nil until Phase 8
    earningsPerSec = 5906.25,        -- 1250 * 2.10 * 1.5 * 1.5 = 5906.25
}

-- Example: A Rainbow Massive brainrot with a Gravitated weather mutation (jackpot!)
{
    id = "f9e8d7c6b5a4f3e2d1c0b9a8f7e6d5c4",
    name = "La Vaca Saturno Saturnita",
    rarity = "Unknown",
    size = 2.87,
    sizeLabel = "Massive",
    weight = 2869997.13,             -- 999999 * 2.87
    baseMutation = "Rainbow",
    weatherMutation = "Gravitated",
    personality = nil,
    earningsPerSec = 71750000000.0,  -- 50000000 * 2.87 * 5.0 * 100.0 = 71,750,000,000
}

-- Example: No mutations (most common case)
{
    id = "1234567890abcdef1234567890abcdef",
    name = "Hipocactus",
    rarity = "Common",
    size = 1.0,
    sizeLabel = "Small",
    weight = 85.0,
    baseMutation = nil,
    weatherMutation = nil,
    personality = nil,
    earningsPerSec = 5.0,            -- 5 * 1.0 * 1.0 * 1.0 = 5.0
}
```

### 7.5 Full Earnings Formula (Phase 6)

```
earningsPerSec = baseEarnings * sizeMult * baseMutationMult * weatherMutationMult
```

| Factor | Source | Phase 6 Range |
|---|---|---|
| `baseEarnings` | `Config/Brainrots` (varies by rarity) | $5 to $50,000,000 |
| `sizeMult` | `brainrot.size` (continuous value from Phase 3) | 0.5x to 3.0x |
| `baseMutationMult` | `Config/Mutations` (None/Gold/Diamond/Rainbow) | 1.0x to 5.0x |
| `weatherMutationMult` | `Config/Mutations` (None/Soaked/Frozen/.../Gravitated) | 1.0x to 100.0x |

**Phase 6 effective range:** 0.5x to 1,500.0x multiplier on base earnings (Massive 3.0 * Rainbow 5.0 * Gravitated 100.0 = 1,500.0x max).

**Theoretical maximum earningsPerSec:** $50,000,000 * 3.0 * 5.0 * 100.0 = **$75,000,000,000/sec** (Massive Rainbow Gravitated Unknown rarity brainrot).

### 7.6 Weather Event Probability Table

| Weather | Spawn Weight | Probability | Expected Rolls per 100 |
|---|---|---|---|
| Clear | 40 | 40.0% | 40 |
| Rain | 25 | 25.0% | 25 |
| Snow | 15 | 15.0% | 15 |
| Storm | 10 | 10.0% | 10 |
| Meteor Shower | 5 | 5.0% | 5 |
| Solar Flare | 3 | 3.0% | 3 |
| Nuclear | 1.5 | 1.5% | 1.5 |
| Black Hole | 0.5 | 0.5% | 0.5 |
| **Total** | **100** | **100%** | **100** |

### 7.7 Weather Mutation Multiplier Summary

| Weather | Mutation | Multiplier | Mutation Chance | Expected Mutations per 100 Brainrots |
|---|---|---|---|---|
| Rain | Soaked | 1.5x | 15% | 15 |
| Snow | Frozen | 2.0x | 12% | 12 |
| Storm | Shocked | 2.5x | 10% | 10 |
| Meteor Shower | Starstrucked | 5.0x | 8% | 8 |
| Solar Flare | Burnt | 10.0x | 5% | 5 |
| Nuclear | Radiated | 35.0x | 3% | 3 |
| Black Hole | Gravitated | 100.0x | 1% | 1 |

---

## 8. Testing Criteria

After all files are written, verify the following. Every test must pass.

### Build Test

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T1 | `rojo build` succeeds | Run `rojo build -o "collect-brainrots.rbxlx"` | Exits with code 0, no errors. |

### Weather Cycle Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T2 | Weather events trigger periodically | Wait 2-5 minutes in game, observe weather changes | At least one non-Clear weather event occurs within 5 minutes. |
| T3 | Clear weather is most common | Observe 10+ weather rolls | Approximately 40% of rolls are Clear (no weather effects). |
| T4 | Rare weather events are infrequent | Observe 50+ weather rolls (or use test script to speed up cycle) | Nuclear and Black Hole appear very rarely (combined ~2%). |
| T5 | Weather duration matches config | Time a Rain event with a stopwatch | Rain lasts between 60-120 seconds. |
| T6 | Weather returns to Clear after event ends | Wait for a non-Clear event to finish | After the countdown reaches 0, weather transitions back to Clear. |

### Weather Banner Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T7 | Banner appears during non-Clear weather | Observe screen during Rain/Storm/etc. | Banner slides down from top of screen showing weather name. |
| T8 | Banner shows countdown timer | Read the countdown text during an active event | Countdown decrements every second, shows "Time remaining: Xs" or "M:SS". |
| T9 | Banner hides during Clear weather | Wait for weather to end | Banner slides up offscreen when weather changes to Clear. |
| T10 | Banner shows correct weather description | Read the description text | Matches the description from Config/Weather (e.g., "Rain falls from the sky. Brainrots may get Soaked."). |

### Visual Effects Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T11 | Rain: rain drop particles and darker lighting | Trigger/wait for Rain weather | Water-like particles fall from above; lighting is slightly darker and bluish. |
| T12 | Snow: snowflake particles and blue-tinted lighting | Trigger/wait for Snow weather | White/blue snowflake particles drift slowly; lighting has blue tint. |
| T13 | Storm: lightning flashes, dark lighting, camera shake | Trigger/wait for Storm weather | Screen flashes periodically; very dark atmosphere; camera shakes briefly during flashes. |
| T14 | Meteor Shower: streaks across sky, orange-tinted lighting | Trigger/wait for Meteor Shower | Bright orange/yellow streaks move across sky; warm orange lighting. |
| T15 | Solar Flare: intense warm glow, heat shimmer | Trigger/wait for Solar Flare | Very bright warm lighting; screen blur oscillates to simulate heat shimmer. |
| T16 | Nuclear: green tint, radiation particles | Trigger/wait for Nuclear weather | Green-tinted atmosphere; green particles rise from ground level. |
| T17 | Black Hole: purple/dark vortex, screen distortion | Trigger/wait for Black Hole weather | Very dark purple atmosphere; blur effect; purple vortex particles; subtle camera pull. |
| T18 | Effects clean up when weather ends | Wait for any non-Clear event to finish | All particles disappear; lighting returns to normal defaults; no lingering effects. |

### Weather Mutation Application Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T19 | Some brainrots receive weather mutations during events | Have 10+ brainrots at base; trigger a Rain event; inspect brainrot data | Some brainrots (roughly 15% for Rain) now have `weatherMutation = "Soaked"`. |
| T20 | A brainrot can only get ONE weather mutation | Have brainrots with weather mutations; trigger a second weather event | Brainrots that already have a weather mutation are skipped; their existing mutation is not replaced. |
| T21 | A brainrot CAN have both a base mutation AND a weather mutation | Inspect a Gold/Diamond/Rainbow brainrot that received a weather mutation | Both `baseMutation` and `weatherMutation` are non-nil simultaneously. |
| T22 | Weather mutation persists after weather event ends | Note which brainrots got mutated; wait for Clear weather | The `weatherMutation` field remains set after the weather event ends. |
| T23 | Weather mutation persists in save data | Get a brainrot mutated, leave and rejoin | The `weatherMutation` field is still set on the brainrot after rejoin. |

### Brainrot Visual Mutation Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T24 | Soaked brainrot shows water droplet particles | Observe a brainrot that received Soaked mutation | Blue water-like particles emit from the brainrot Part. |
| T25 | Frozen brainrot shows ice crystal particles | Observe a brainrot that received Frozen mutation | Light blue/white crystal particles emit from the brainrot Part. |
| T26 | Shocked brainrot shows lightning spark particles | Observe a brainrot that received Shocked mutation | Yellow spark particles emit rapidly from the brainrot Part. |
| T27 | Starstrucked brainrot shows star particles | Observe a brainrot that received Starstrucked mutation | Golden star-like particles float upward from the brainrot Part. |
| T28 | Burnt brainrot shows flame particles | Observe a brainrot that received Burnt mutation | Orange/red flame particles emit from the brainrot Part. |
| T29 | Radiated brainrot shows green glow particles | Observe a brainrot that received Radiated mutation | Green glowing particles emit from the brainrot Part. |
| T30 | Gravitated brainrot shows purple vortex particles | Observe a brainrot that received Gravitated mutation | Purple vortex particles swirl around the brainrot Part. |
| T31 | BillboardGui shows weather mutation name | Observe any weather-mutated brainrot's label | A new text label at the bottom of the billboard shows the mutation name in the appropriate color. |

### Earnings Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T32 | Earnings increase when brainrot gets weather mutation | Note earnings before and after a brainrot gets Soaked | Total earnings increase by the difference. Soaked brainrot now earns 1.5x its previous rate. |
| T33 | Earnings formula chains correctly with all 4 factors | Spawn a Gold Large brainrot that gets Soaked; verify earnings | `earningsPerSec = baseEarnings * sizeMult * 1.5 (Gold) * 1.5 (Soaked)`. |
| T34 | Total earnings display updates correctly | Observe MoneyUI after weather mutations are applied | Total earnings/sec matches the sum of all individual brainrot earnings. |

### Music Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T35 | Clear weather plays joyful music | Start game or wait for Clear weather | Upbeat, cheerful music plays. |
| T36 | Rain/Snow plays gloomy music | Trigger Rain or Snow weather | Music transitions to calm, melancholic track. |
| T37 | Storm/Meteor Shower plays suspenseful music | Trigger Storm or Meteor Shower | Music transitions to tense, building track. |
| T38 | Solar Flare/Nuclear/Black Hole plays intense music | Trigger one of these rare events | Music transitions to dramatic, high-energy track. |
| T39 | Music transitions smoothly between states | Observe during weather change | Old track fades out over ~2 seconds while new track fades in. No abrupt cuts or silence gaps. |
| T40 | Music returns to joyful after weather event ends | Wait for a non-Clear event to finish | Music smoothly transitions back to joyful track. |

### Console Cleanliness Test

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T41 | No errors in console | Check Studio Output for red error text during gameplay, including weather events | Zero errors. Warnings from placeholder music IDs are acceptable. |

### Performance Test

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T42 | No lag during weather events with many brainrots | Have 30+ brainrots at base; trigger a weather event | No noticeable frame drops. Mutation application completes quickly. |
| T43 | Weather effects clean up without memory leaks | Run through several weather cycles | No accumulation of orphaned Parts, ParticleEmitters, or Sound instances in the Explorer. |

---

## 9. Acceptance Criteria

All of the following must be true before Phase 6 is considered complete:

| # | Criterion | How to Verify |
|---|---|---|
| 1 | `rojo build` succeeds without errors | Run `rojo build -o "collect-brainrots.rbxlx"` |
| 2 | `Config/Weather.luau` exists with correct data tables and functions | Read the file and verify all 8 weather events, cycle constants, severity labels, and 3 utility functions |
| 3 | Weather system adds dynamic excitement to gameplay | Play the game for 10+ minutes and observe varied weather events with distinct atmospheres |
| 4 | Weather events trigger on a 120-300 second cycle | Observe timing between weather rolls |
| 5 | Weather banner shows at top of screen during non-Clear weather with countdown | Visual check during any active weather event |
| 6 | Visual effects match weather type (particles, lighting, screen effects) | Visual check for each of the 7 non-Clear weather types |
| 7 | Some brainrots receive weather mutations during weather events | Inspect brainrot data after a weather event with 10+ brainrots at base |
| 8 | No brainrot gets more than one weather mutation (not replaced by new weather) | Trigger multiple weather events; verify existing mutations are never overwritten |
| 9 | A brainrot CAN have both a base mutation AND a weather mutation simultaneously | Inspect data of a mutated brainrot |
| 10 | Weather mutations persist in save data after weather event ends and across sessions | Rejoin game and verify weather mutations are still present |
| 11 | Mutation multipliers chain correctly: `baseEarnings * sizeMult * baseMutMult * weatherMutMult` | Verify computed earnings match expected value for known inputs |
| 12 | Earnings update immediately when a brainrot receives a weather mutation | Observe MoneyUI before and after mutation |
| 13 | Weather-mutated brainrots show visual particle effects matching their mutation type | Visual check for each of the 7 weather mutation types |
| 14 | BillboardGui displays weather mutation name on mutated brainrots | Visual check |
| 15 | Music changes: joyful (Clear) -> gloomy (Rain/Snow) -> suspenseful (Storm/Meteor) -> intense (Solar Flare/Nuclear/Black Hole) | Listen to music during weather transitions |
| 16 | Music transitions smoothly between states (crossfade, no abrupt cuts) | Listen during weather change |
| 17 | Clear weather = no visual effects, joyful music, no banner | Visual and audio check during Clear |
| 18 | Late-joining players receive current weather state | Join mid-weather-event and verify banner + effects appear |
| 19 | No errors or warnings in Studio Output console (except placeholder music IDs) | Check for red/yellow text |
| 20 | No performance issues during weather events with 30+ brainrots | FPS remains stable during mutation application and visual effects |
| 21 | All Phase 5 functionality still works (sell system, base management, capacity upgrades) | Regression test |

---

## Appendix A: Weather Event Probability Verification

To verify weather event probabilities are correct, the following test methodology is recommended:

1. **Automated test:** Temporarily add a server-side loop that calls `rollWeatherType()` 10,000 times and tallies results:
   ```luau
   local counts = {}
   for _, name in Weather.WEATHER_ORDER do
       counts[name] = 0
   end
   for i = 1, 10000 do
       local result = rollWeatherType()
       counts[result] = counts[result] + 1
   end
   print("Weather distribution (10,000 rolls):")
   for _, name in Weather.WEATHER_ORDER do
       print(string.format("  %s: %d (%.1f%%)", name, counts[name], counts[name] / 100))
   end
   ```

2. **Expected output (approximately):**
   ```
   Weather distribution (10,000 rolls):
     Clear: 4000 (40.0%)
     Rain: 2500 (25.0%)
     Snow: 1500 (15.0%)
     Storm: 1000 (10.0%)
     Meteor Shower: 500 (5.0%)
     Solar Flare: 300 (3.0%)
     Nuclear: 150 (1.5%)
     Black Hole: 50 (0.5%)
   ```

3. **Acceptable variance:** +/- 2% from expected values is normal for 10,000 samples. Black Hole (0.5%) may vary more due to small absolute numbers.

## Appendix B: Earnings Examples (Phase 6)

| Brainrot | Rarity | Size | Base Mut | Weather Mut | Base $/sec | Size Mult | Base Mut Mult | Weather Mut Mult | Final $/sec |
|---|---|---|---|---|---|---|---|---|---|
| Burbaloni Lulilolli | Common | 1.0 | None | None | $5 | 1.0x | 1.0x | 1.0x | $5.00 |
| Burbaloni Lulilolli | Common | 1.5 | Gold | Soaked | $5 | 1.5x | 1.5x | 1.5x | $16.88 |
| Tralalero Tralala | Epic | 2.10 | Gold | Shocked | $1,250 | 2.1x | 1.5x | 2.5x | $9,843.75 |
| Tralalero Tralala | Epic | 2.87 | Diamond | Starstrucked | $1,250 | 2.87x | 2.5x | 5.0x | $44,843.75 |
| Tralalero Tralala | Epic | 2.87 | Rainbow | Gravitated | $1,250 | 2.87x | 5.0x | 100.0x | $1,793,750.00 |
| La Vaca Saturno Saturnita | Unknown | 3.0 | Rainbow | Gravitated | $50,000,000 | 3.0x | 5.0x | 100.0x | $75,000,000,000.00 |
| Cappuccino Assassino | Mythic | 0.5 | None | Frozen | $100,000 | 0.5x | 1.0x | 2.0x | $100,000.00 |
| Bombombini Gusini | Legendary | 1.8 | Diamond | Radiated | $10,000 | 1.8x | 2.5x | 35.0x | $1,575,000.00 |

## Appendix C: Music Severity Mapping Quick Reference

```
Severity 0 (Joyful):     Clear
Severity 1 (Gloomy):     Rain, Snow
Severity 2 (Suspenseful): Storm, Meteor Shower
Severity 3 (Intense):    Solar Flare, Nuclear, Black Hole
```

## Appendix D: Weather Effect Cleanup Checklist

When transitioning from any weather to Clear (or to a different weather), the following must be cleaned up:

1. All `Part` instances named "WeatherEffect" in `workspace` -- Destroy
2. All `ColorCorrectionEffect` instances named "WeatherEffect" in `Lighting` -- Destroy
3. All `BlurEffect` instances named "WeatherEffect" in `Lighting` -- Destroy
4. `Lighting.Ambient` -- Reset to `Color3.fromRGB(127, 127, 127)`
5. `Lighting.OutdoorAmbient` -- Reset to `Color3.fromRGB(127, 127, 127)`
6. `Lighting.Brightness` -- Reset to `2`
7. `Lighting.FogEnd` -- Reset to `100000`
8. `Lighting.FogColor` -- Reset to `Color3.fromRGB(192, 192, 192)`
9. `activeEffects` table -- `table.clear()`
10. Any running coroutines (Storm lightning, Solar Flare shimmer, Black Hole camera pull) -- terminate via `currentWeather` check

---

*End of Phase 6 Weather System specification.*
