# Phase 7: Index, Gifting, and Leaderboards

> **Status:** NOT STARTED
> **Depends on:** Phase 6 (weather system, weather mutations, full earnings formula complete and tested)
> **Blocks:** Phase 8 (Personality System)

---

## 1. Objective

Implement the collection index (codex) with 4 sections (Normal, Gold, Diamond, Rainbow), codex completion rewards (fence cosmetics), brainrot gifting between players, and global leaderboards (most money, most time, most Robux spent).

By the end of this phase:
- A full-screen codex overlay shows all 25 brainrots across 4 sections: Normal, Gold, Diamond, Rainbow.
- Discovered brainrots appear in full color with their name; undiscovered ones appear as dark silhouettes with "???".
- Each section tracks progress (e.g., "15/25 discovered") with a visual progress bar.
- Completing an entire section awards a fence cosmetic that visually upgrades the player's base perimeter fence.
- Players can gift individual brainrots to other online players via a gift button on each brainrot's info panel.
- Three global leaderboards display the top 50 players for: Most Money Earned, Most Time Played, and Most Robux Spent.
- Leaderboard data is persisted via OrderedDataStores and updated every 60 seconds for online players.
- All new data fields persist across sessions via ProfileStore.

---

## 2. Prerequisites

Phase 6 must be fully complete and tested before starting Phase 7. Specifically:

- `src/server/Services/WeatherService.luau` handles weather events and weather mutation application.
- `src/server/Services/EarningsService.luau` uses the full earnings formula: `baseEarnings * sizeMult * baseMutationMult * weatherMutationMult`.
- `src/server/Services/DataService.luau` handles player data persistence including `weatherMutation` field on BrainrotInstance.
- `src/server/Services/FoodService.luau` handles food purchases, brainrot spawning, mutation rolling, and base insertion.
- `src/server/Services/BaseService.luau` handles plot assignment, capacity upgrades, and provides `getCapacity()`.
- `src/client/Controllers/BaseUI.luau` renders brainrot visuals, BillboardGuis, fence Parts, and mutation effects.
- `src/server/Remotes/init.luau` defines all Phase 1-6 remotes.
- `src/server/init.server.luau` boots all server services in order.
- `src/client/init.client.luau` boots all client controllers in order.
- `rojo build` succeeds and the game runs without console errors.

---

## 3. Files to Create/Modify

Every file is listed with its full path relative to the project root.

### New Files to Create (5 files)

| # | File Path | Purpose |
|---|---|---|
| 1 | `src/server/Services/IndexService.luau` | Tracks brainrot discoveries per player, manages index sections (Normal/Gold/Diamond/Rainbow), awards fence cosmetics on section completion |
| 2 | `src/server/Services/GiftService.luau` | Handles brainrot gifting between players with full validation, ownership transfer, and earnings recalculation |
| 3 | `src/server/Services/LeaderboardService.luau` | Manages three global leaderboards via OrderedDataStores, periodic stat pushing, and top-50 retrieval |
| 4 | `src/client/Controllers/IndexUI.luau` | Full-screen codex overlay with 4 tabbed sections, brainrot grid, progress bars, and fence reward display |
| 5 | `src/client/Controllers/LeaderboardUI.luau` | Sidebar leaderboard display with tabs for each leaderboard type and top-player entries |

### Files to Modify (6 files)

| # | File Path | Change |
|---|---|---|
| 1 | `src/server/Services/DataService.luau` | Add `index`, `unlockedFences`, `totalTimePlayed`, `totalRobuxSpent` fields to DEFAULT_DATA template (if not already present from Phase 1 forward declarations). Update `onPlayerRemoving` to accumulate `totalTimePlayed` from session duration. |
| 2 | `src/server/Services/FoodService.luau` | After a brainrot successfully stays at the player's base, call `IndexService.registerDiscovery(player, brainrot.name, brainrot.baseMutation)`. |
| 3 | `src/server/Remotes/init.luau` | Add 6 new remotes: `RequestIndex` (C->S), `IndexUpdated` (S->C), `GiftBrainrot` (C->S), `GiftReceived` (S->C), `RequestLeaderboard` (C->S), `LeaderboardData` (S->C). |
| 4 | `src/client/Controllers/BaseUI.luau` | Add "Gift" button to each brainrot's info panel. When clicked, show a player-selection list. Apply unlocked fence cosmetics (swap fence material/color based on best unlocked fence). |
| 5 | `src/server/init.server.luau` | Add IndexService, GiftService, and LeaderboardService to the server boot order. |
| 6 | `src/client/init.client.luau` | Add IndexUI and LeaderboardUI to the client boot order. |

---

## 4. Detailed Spec Per File

---

### 4.1 `src/server/Services/IndexService.luau` (CREATE)

**Purpose:** Tracks which brainrots a player has discovered, organized into 4 sections based on mutation type. When a section is completed (all 25 brainrots discovered in that mutation category), a fence cosmetic reward is automatically awarded.

**Dependencies:**

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Brainrots = require(ReplicatedStorage.Shared.Config.Brainrots)
local DataService = require(script.Parent.DataService)
local Remotes = require(ReplicatedStorage.Remotes)
```

**Constants:**

```luau
local TOTAL_BRAINROTS = 25  -- Total unique brainrots in the game

-- Maps index section names to the baseMutation value that qualifies
local SECTION_MUTATION_MAP = {
    normal = nil,           -- No mutation = normal section
    gold = "Gold",
    diamond = "Diamond",
    rainbow = "Rainbow",
}

-- Fence reward for completing each section
local FENCE_REWARDS = {
    normal  = "Default Fence",    -- Upgrade from basic to nicer fence
    gold    = "Gold Fence",       -- Gold-colored fence
    diamond = "Diamond Fence",    -- Diamond/crystal fence
    rainbow = "Rainbow Fence",    -- Rainbow-colored fence
}

-- Priority order for fence display (highest priority = best fence shown)
local FENCE_PRIORITY = {
    ["Default Fence"]  = 1,
    ["Gold Fence"]     = 2,
    ["Diamond Fence"]  = 3,
    ["Rainbow Fence"]  = 4,
}
```

**Module structure:**

```luau
local IndexService = {}
```

**Public API:**

```luau
function IndexService.init()
```
- **Step by step:**
  1. Connect `Remotes.RequestIndex.OnServerEvent` to `handleRequestIndex`.

```luau
function IndexService.registerDiscovery(player: Player, brainrotName: string, baseMutation: string?)
```
- Called by FoodService when a brainrot successfully stays at the player's base. Also called by GiftService when a brainrot is gifted to a player.
- **Step by step:**
  1. Get data via `DataService.getData(player)`. If nil, warn and return.
  2. Determine the section: if `baseMutation == nil`, section is `"normal"`. If `baseMutation == "Gold"`, section is `"gold"`. If `baseMutation == "Diamond"`, section is `"diamond"`. If `baseMutation == "Rainbow"`, section is `"rainbow"`.
  3. Get the section table: `local sectionTable = data.index[section]`.
  4. Check if `brainrotName` is already in `sectionTable`. If it is, return (already discovered, no-op).
  5. Insert `brainrotName` into `sectionTable`: `table.insert(sectionTable, brainrotName)`.
  6. Print `"[IndexService] " .. player.Name .. " discovered " .. brainrotName .. " in " .. section .. " section (" .. #sectionTable .. "/" .. TOTAL_BRAINROTS .. ")"`.
  7. Check if section is now complete: if `#sectionTable >= TOTAL_BRAINROTS`, call `awardFenceReward(player, section)`.
  8. Fire index update to client: `Remotes.IndexUpdated:FireClient(player, { section = section, brainrotName = brainrotName, sectionCount = #sectionTable, totalRequired = TOTAL_BRAINROTS })`.

```luau
function IndexService.getIndexData(player: Player): { normal: {string}, gold: {string}, diamond: {string}, rainbow: {string} }?
```
- Returns the player's full index data table.
- **Step by step:**
  1. Get data via `DataService.getData(player)`. If nil, return nil.
  2. Return `data.index`.

```luau
function IndexService.getBestFence(player: Player): string?
```
- Returns the name of the highest-priority unlocked fence, or nil if none.
- **Step by step:**
  1. Get data via `DataService.getData(player)`. If nil, return nil.
  2. If `#data.unlockedFences == 0`, return nil.
  3. Iterate `data.unlockedFences`, find the one with the highest value in `FENCE_PRIORITY`.
  4. Return that fence name.

**Internal functions:**

```luau
local function awardFenceReward(player: Player, section: string)
```
- **Step by step:**
  1. Get data via `DataService.getData(player)`. If nil, return.
  2. Get the fence reward name: `local fenceName = FENCE_REWARDS[section]`.
  3. Check if already unlocked: iterate `data.unlockedFences`, if `fenceName` is already present, return.
  4. Insert `fenceName` into `data.unlockedFences`: `table.insert(data.unlockedFences, fenceName)`.
  5. Print `"[IndexService] " .. player.Name .. " completed " .. section .. " section! Awarded " .. fenceName`.
  6. Fire notification to client: `Remotes.IndexUpdated:FireClient(player, { sectionComplete = true, section = section, fenceReward = fenceName })`.

```luau
local function handleRequestIndex(player: Player)
```
- **Step by step:**
  1. Get data via `DataService.getData(player)`. If nil, return.
  2. Compile full index response:
     ```luau
     local response = {
         index = data.index,
         unlockedFences = data.unlockedFences,
         allBrainrotNames = {},  -- ordered list of all 25 names
         totalRequired = TOTAL_BRAINROTS,
     }
     ```
  3. Populate `allBrainrotNames` by iterating `Brainrots.BRAINROTS` and collecting each `.name`.
  4. Fire `Remotes.IndexUpdated:FireClient(player, response)`.

**Module return:**

```luau
return IndexService
```

---

### 4.2 `src/server/Services/GiftService.luau` (CREATE)

**Purpose:** Handles the transfer of a brainrot from one player to another. Validates ownership, target player status, and capacity. Removes the brainrot from the sender's inventory, adds it to the recipient's inventory, recalculates earnings for both players, and registers the discovery for the recipient's index.

**Dependencies:**

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DataService = require(script.Parent.DataService)
local EarningsService = require(script.Parent.EarningsService)
local IndexService = require(script.Parent.IndexService)
local BaseService = require(script.Parent.BaseService)
local Remotes = require(ReplicatedStorage.Remotes)
```

**Constants:**

```luau
local GIFT_COOLDOWN = 5  -- seconds between gifts per player (anti-spam)
```

**Internal state:**

```luau
local lastGiftTime = {}  -- {[Player]: number} os.clock() of last gift sent
```

**Module structure:**

```luau
local GiftService = {}
```

**Public API:**

```luau
function GiftService.init()
```
- **Step by step:**
  1. Connect `Remotes.GiftBrainrot.OnServerEvent` to `handleGiftBrainrot`.
  2. Connect `Players.PlayerRemoving` to clean up `lastGiftTime` for leaving players.

**Internal functions:**

```luau
local function handleGiftBrainrot(player: Player, data: { brainrotId: string, targetPlayerId: number })
```
- **Step by step:**
  1. **Validate cooldown:** Check `lastGiftTime[player]`. If `os.clock() - lastGiftTime[player] < GIFT_COOLDOWN`, warn `"GiftBrainrot: Cooldown active"` and return.
  2. **Validate payload:** Extract `data.brainrotId` (string) and `data.targetPlayerId` (number). If either is missing or wrong type, warn and return.
  3. **Validate self-gift:** If `data.targetPlayerId == player.UserId`, warn `"GiftBrainrot: Cannot gift to yourself"` and return.
  4. **Validate sender data:** Get sender data via `DataService.getData(player)`. If nil, warn and return.
  5. **Find brainrot in sender's inventory:** Iterate `senderData.ownedBrainrots` to find the entry where `brainrot.id == data.brainrotId`. Store both the brainrot table and its index. If not found, warn `"GiftBrainrot: Brainrot not found in sender inventory"` and return.
  6. **Validate target player is online:** Get target Player object via `Players:GetPlayerByUserId(data.targetPlayerId)`. If nil (target not online), warn `"GiftBrainrot: Target player not online"` and return.
  7. **Validate target data:** Get target data via `DataService.getData(targetPlayer)`. If nil, warn and return.
  8. **Validate target capacity:** If `#targetData.ownedBrainrots >= targetData.baseCapacity`, warn `"GiftBrainrot: Target player's base is full"` and return.
  9. **Remove from sender:** `table.remove(senderData.ownedBrainrots, brainrotIndex)`.
  10. **Add to recipient:** `table.insert(targetData.ownedBrainrots, brainrot)`.
  11. **Update cooldown:** `lastGiftTime[player] = os.clock()`.
  12. **Recalculate sender earnings:** `EarningsService.recalculate(player)`.
  13. **Recalculate recipient earnings:** `EarningsService.recalculate(targetPlayer)`.
  14. **Register discovery for recipient:** `IndexService.registerDiscovery(targetPlayer, brainrot.name, brainrot.baseMutation)`.
  15. **Fire sender update -- capacity:** Get sender capacity via `BaseService.getCapacity(player)`. Fire `Remotes.CapacityUpdated:FireClient(player, { current = #senderData.ownedBrainrots, max = senderData.baseCapacity })`.
  16. **Fire recipient update -- new brainrot:** Fire `Remotes.BrainrotSpawned:FireClient(targetPlayer, { brainrotData = brainrot })`.
  17. **Fire recipient update -- capacity:** Get target capacity via `BaseService.getCapacity(targetPlayer)`. Fire `Remotes.CapacityUpdated:FireClient(targetPlayer, { current = #targetData.ownedBrainrots, max = targetData.baseCapacity })`.
  18. **Fire gift received notification:** Fire `Remotes.GiftReceived:FireClient(targetPlayer, { fromPlayerName = player.Name, brainrotName = brainrot.name, brainrotRarity = brainrot.rarity, baseMutation = brainrot.baseMutation })`.
  19. **Fire sender confirmation (reuse CapacityUpdated to refresh their UI).**
  20. Print `"[GiftService] " .. player.Name .. " gifted " .. brainrot.name .. " to " .. targetPlayer.Name`.

**Cleanup on player leave:**

```luau
Players.PlayerRemoving:Connect(function(player)
    lastGiftTime[player] = nil
end)
```

**Module return:**

```luau
return GiftService
```

---

### 4.3 `src/server/Services/LeaderboardService.luau` (CREATE)

**Purpose:** Manages three global leaderboards using Roblox OrderedDataStores. Periodically pushes online players' stats to the data stores and serves top-50 results to clients on request.

**Dependencies:**

```luau
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DataService = require(script.Parent.DataService)
local Remotes = require(ReplicatedStorage.Remotes)
```

**Constants:**

```luau
local UPDATE_INTERVAL = 60          -- Push stats every 60 seconds
local LEADERBOARD_SIZE = 50         -- Top 50 per leaderboard
local LEADERBOARD_VERSION = "v1"    -- Append to store name for versioning

-- OrderedDataStore names
local STORE_NAMES = {
    MostMoney  = "Leaderboard_MostMoney_" .. LEADERBOARD_VERSION,
    MostTime   = "Leaderboard_MostTime_" .. LEADERBOARD_VERSION,
    MostRobux  = "Leaderboard_MostRobux_" .. LEADERBOARD_VERSION,
}

-- Maps leaderboard key to the PlayerData field name
local STAT_FIELDS = {
    MostMoney = "totalMoneyEarned",
    MostTime  = "totalTimePlayed",
    MostRobux = "totalRobuxSpent",
}

-- Display names for each leaderboard (used in UI)
local DISPLAY_NAMES = {
    MostMoney = "Most Money Earned",
    MostTime  = "Most Time Played",
    MostRobux = "Most Robux Spent",
}
```

**Internal state:**

```luau
local orderedStores = {}   -- {[string]: OrderedDataStore} keyed by leaderboard key
local cachedResults = {}   -- {[string]: {{rank: number, name: string, value: number}}} cached top-50
local isRunning = false
```

**Module structure:**

```luau
local LeaderboardService = {}
```

**Public API:**

```luau
function LeaderboardService.init()
```
- **Step by step:**
  1. For each key in `STORE_NAMES`:
     a. Call `DataStoreService:GetOrderedDataStore(STORE_NAMES[key])`.
     b. Store the result in `orderedStores[key]`.
  2. Initialize `cachedResults` with empty tables for each key.
  3. Connect `Remotes.RequestLeaderboard.OnServerEvent` to `handleRequestLeaderboard`.
  4. Set `isRunning = true`.
  5. Spawn the periodic update loop via `task.spawn(updateLoop)`.
  6. Print `"[LeaderboardService] Initialized with " .. UPDATE_INTERVAL .. "s update interval"`.

**Internal functions:**

```luau
local function updateLeaderboards()
```
- Pushes all online players' stats to OrderedDataStores and refreshes the cached top-50 results.
- **Step by step:**
  1. **Push phase:** For each player in `Players:GetPlayers()`:
     a. Get data via `DataService.getData(player)`. If nil, skip.
     b. For each leaderboard key in `STAT_FIELDS`:
        i. Get the stat value: `local value = data[STAT_FIELDS[key]]`.
        ii. If key is `"MostTime"`, add current session time: `value = value + (os.clock() - sessionStartTime)`. Get session start from DataService if exposed, otherwise use the stored value.
        iii. Convert to integer (OrderedDataStores require integers): `value = math.floor(value)`.
        iv. If `value > 0`, call `orderedStores[key]:SetAsync(tostring(player.UserId), value)` wrapped in `pcall`.
        v. If `pcall` fails, warn `"[LeaderboardService] Failed to push " .. key .. " for " .. player.Name .. ": " .. err`.
  2. **Fetch phase:** For each leaderboard key:
     a. Call `orderedStores[key]:GetSortedAsync(false, LEADERBOARD_SIZE)` wrapped in `pcall`. `false` = descending order.
     b. If `pcall` fails, warn and skip this leaderboard.
     c. Get the first page: `local page = result:GetCurrentPage()`.
     d. Build entries array:
        ```luau
        local entries = {}
        for rank, entry in ipairs(page) do
            table.insert(entries, {
                rank = rank,
                userId = tonumber(entry.key),
                value = entry.value,
                name = "",  -- filled below
            })
        end
        ```
     e. For each entry, attempt to resolve the player name:
        i. Check if the player is currently online via `Players:GetPlayerByUserId(entry.userId)`. If so, use `player.Name`.
        ii. If not online, call `Players:GetNameFromUserIdAsync(entry.userId)` wrapped in `pcall`. If fails, set name to `"Player_" .. entry.userId`.
     f. Store in cache: `cachedResults[key] = entries`.

```luau
local function updateLoop()
```
- Infinite loop that calls `updateLeaderboards()` every `UPDATE_INTERVAL` seconds.
- **Step by step:**
  1. While `isRunning`:
     a. `task.wait(UPDATE_INTERVAL)`.
     b. Call `updateLeaderboards()` wrapped in a `pcall` for safety.
     c. If `pcall` fails, warn `"[LeaderboardService] Update cycle failed: " .. err`.

```luau
local function handleRequestLeaderboard(player: Player)
```
- **Step by step:**
  1. Compile the response from cached results:
     ```luau
     local response = {
         MostMoney = cachedResults.MostMoney or {},
         MostTime = cachedResults.MostTime or {},
         MostRobux = cachedResults.MostRobux or {},
         displayNames = DISPLAY_NAMES,
     }
     ```
  2. Fire `Remotes.LeaderboardData:FireClient(player, response)`.

**Module return:**

```luau
return LeaderboardService
```

---

### 4.4 `src/client/Controllers/IndexUI.luau` (CREATE)

**Purpose:** Renders the full-screen codex overlay that shows all 25 brainrots organized into 4 tabbed sections (Normal, Gold, Diamond, Rainbow). Discovered brainrots are shown in full color with their name; undiscovered ones appear as dark silhouettes with "???". Each section has a progress bar. Completed sections display the fence reward.

**Dependencies:**

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Brainrots = require(ReplicatedStorage.Shared.Config.Brainrots)
local Utils = require(ReplicatedStorage.Shared.Utils)
local Remotes = require(ReplicatedStorage.Remotes)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
```

**Constants:**

```luau
local TOTAL_BRAINROTS = 25
local GRID_COLUMNS = 5
local GRID_ROWS = 5
local CELL_SIZE = UDim2.new(0, 120, 0, 140)
local CELL_PADDING = 8

local SECTION_TABS = { "Normal", "Gold", "Diamond", "Rainbow" }

-- Maps section tab names to data.index keys
local SECTION_KEYS = {
    Normal  = "normal",
    Gold    = "gold",
    Diamond = "diamond",
    Rainbow = "rainbow",
}

local SECTION_COLORS = {
    Normal  = Color3.fromRGB(200, 200, 200),    -- Gray/white
    Gold    = Color3.fromRGB(255, 215, 0),       -- Gold
    Diamond = Color3.fromRGB(185, 242, 255),     -- Light cyan
    Rainbow = Color3.fromRGB(255, 100, 200),     -- Pink (represents rainbow)
}

local FENCE_REWARD_NAMES = {
    normal  = "Default Fence",
    gold    = "Gold Fence",
    diamond = "Diamond Fence",
    rainbow = "Rainbow Fence",
}

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

local UNDISCOVERED_COLOR = Color3.fromRGB(40, 40, 40)
local SILHOUETTE_COLOR = Color3.fromRGB(20, 20, 20)
```

**Internal state:**

```luau
local indexData = { normal = {}, gold = {}, diamond = {}, rainbow = {} }
local unlockedFences = {}
local allBrainrotNames = {}   -- ordered list, populated from Brainrots.BRAINROTS
local currentTab = "Normal"
local codexOpen = false

-- UI references
local screenGui = nil
local codexFrame = nil
local gridFrame = nil
local progressBar = nil
local progressLabel = nil
local completeBadge = nil
local tabButtons = {}
local brainrotCells = {}      -- {[string]: Frame} keyed by brainrot name
```

**UI Layout:**

```
ScreenGui "IndexGui"
  ResetOnSpawn = false
  DisplayOrder = 8

  -- Toggle button on HUD (always visible)
  TextButton "CodexToggleButton"
    Position: UDim2.new(0, 10, 0, 60)
    AnchorPoint: Vector2.new(0, 0)
    Size: UDim2.new(0, 120, 0, 40)
    Text: "Codex"
    TextColor3: Color3.fromRGB(255, 255, 255)
    BackgroundColor3: Color3.fromRGB(100, 60, 180)
    Font: Enum.Font.GothamBold
    TextScaled: true
    -- Add UICorner with CornerRadius 8

  -- Full-screen codex overlay (hidden by default)
  Frame "CodexFrame"
    Position: UDim2.new(0.5, 0, 0.5, 0)
    AnchorPoint: Vector2.new(0.5, 0.5)
    Size: UDim2.new(0.85, 0, 0.85, 0)
    BackgroundColor3: Color3.fromRGB(20, 20, 30)
    BackgroundTransparency: 0.05
    Visible: false
    ZIndex: 10
    -- Add UICorner with CornerRadius 16

    -- Title
    TextLabel "TitleLabel"
      Position: UDim2.new(0.5, 0, 0, 15)
      AnchorPoint: Vector2.new(0.5, 0)
      Size: UDim2.new(0.5, 0, 0, 40)
      Text: "Brainrot Codex"
      TextColor3: Color3.fromRGB(255, 255, 255)
      TextScaled: true
      Font: Enum.Font.GothamBold
      BackgroundTransparency: 1

    -- Close button
    TextButton "CloseButton"
      Position: UDim2.new(1, -15, 0, 15)
      AnchorPoint: Vector2.new(1, 0)
      Size: UDim2.new(0, 35, 0, 35)
      Text: "X"
      TextColor3: Color3.fromRGB(255, 255, 255)
      BackgroundColor3: Color3.fromRGB(200, 50, 50)
      Font: Enum.Font.GothamBold
      -- Add UICorner with CornerRadius 6

    -- Tab bar
    Frame "TabBar"
      Position: UDim2.new(0.5, 0, 0, 60)
      AnchorPoint: Vector2.new(0.5, 0)
      Size: UDim2.new(0.8, 0, 0, 40)
      BackgroundTransparency: 1
      -- Add UIListLayout (Horizontal, Center, 10px padding)

      -- 4 tab buttons (Normal, Gold, Diamond, Rainbow)
      TextButton "Tab_Normal" / "Tab_Gold" / "Tab_Diamond" / "Tab_Rainbow"
        Size: UDim2.new(0, 130, 1, 0)
        TextScaled: true
        Font: Enum.Font.GothamBold
        -- Active tab: BackgroundColor3 = SECTION_COLORS[tab], TextColor3 = white
        -- Inactive tab: BackgroundColor3 = Color3.fromRGB(60, 60, 70), TextColor3 = gray
        -- Add UICorner with CornerRadius 8

    -- Progress section
    Frame "ProgressFrame"
      Position: UDim2.new(0.5, 0, 0, 110)
      AnchorPoint: Vector2.new(0.5, 0)
      Size: UDim2.new(0.7, 0, 0, 30)
      BackgroundColor3: Color3.fromRGB(40, 40, 50)
      -- Add UICorner with CornerRadius 6

      -- Progress fill bar (inner)
      Frame "ProgressFill"
        Position: UDim2.new(0, 0, 0, 0)
        Size: UDim2.new(0, 0, 1, 0)  -- width set dynamically as fraction
        BackgroundColor3: SECTION_COLORS[currentTab]
        -- Add UICorner with CornerRadius 6

      -- Progress text
      TextLabel "ProgressText"
        Position: UDim2.new(0.5, 0, 0.5, 0)
        AnchorPoint: Vector2.new(0.5, 0.5)
        Size: UDim2.new(1, 0, 1, 0)
        BackgroundTransparency: 1
        Text: "0/25 Discovered"
        TextColor3: Color3.fromRGB(255, 255, 255)
        TextScaled: true
        Font: Enum.Font.GothamBold
        ZIndex: 3

    -- COMPLETE badge (hidden unless section is 25/25)
    TextLabel "CompleteBadge"
      Position: UDim2.new(0.5, 0, 0, 145)
      AnchorPoint: Vector2.new(0.5, 0)
      Size: UDim2.new(0.4, 0, 0, 30)
      BackgroundTransparency: 1
      Text: "COMPLETE! Reward: Gold Fence"
      TextColor3: Color3.fromRGB(85, 255, 85)
      TextScaled: true
      Font: Enum.Font.GothamBold
      Visible: false

    -- Brainrot grid (scrollable)
    ScrollingFrame "BrainrotGrid"
      Position: UDim2.new(0.5, 0, 0, 180)
      AnchorPoint: Vector2.new(0.5, 0)
      Size: UDim2.new(0.9, 0, 1, -200)
      CanvasSize: UDim2.new(0, 0, 0, 0)  -- auto-sized by UIGridLayout
      ScrollBarThickness: 6
      BackgroundTransparency: 1

      -- UIGridLayout
      UIGridLayout
        CellSize: CELL_SIZE
        CellPadding: UDim2.new(0, CELL_PADDING, 0, CELL_PADDING)
        FillDirection: Enum.FillDirection.Horizontal
        SortOrder: Enum.SortOrder.LayoutOrder
```

**Each brainrot cell in the grid (created dynamically per brainrot):**

```
Frame "Cell_[brainrotName]"
  LayoutOrder: (index in BRAINROTS array)
  BackgroundColor3: RARITY_COLORS[rarity] if discovered, UNDISCOVERED_COLOR if not
  BackgroundTransparency: 0.3 if discovered, 0 if not
  -- Add UICorner with CornerRadius 8

  -- Brainrot icon/silhouette area
  Frame "IconFrame"
    Position: UDim2.new(0.5, 0, 0, 5)
    AnchorPoint: Vector2.new(0.5, 0)
    Size: UDim2.new(0.8, 0, 0, 80)
    BackgroundColor3: SILHOUETTE_COLOR if undiscovered, Color3.fromRGB(60, 60, 70) if discovered
    BackgroundTransparency: 0 if undiscovered, 0.5 if discovered
    -- Add UICorner with CornerRadius 6

    -- Question marks for undiscovered
    TextLabel "SilhouetteText"
      Size: UDim2.new(1, 0, 1, 0)
      Text: "???" if undiscovered, "" if discovered
      TextColor3: Color3.fromRGB(60, 60, 60)
      TextScaled: true
      Font: Enum.Font.GothamBold
      BackgroundTransparency: 1
      Visible: NOT discovered

    -- Checkmark for discovered
    TextLabel "DiscoveredMark"
      Size: UDim2.new(1, 0, 1, 0)
      Text: checkmark symbol
      TextColor3: Color3.fromRGB(85, 255, 85)
      TextScaled: true
      Font: Enum.Font.GothamBold
      BackgroundTransparency: 1
      Visible: discovered

  -- Brainrot name label
  TextLabel "NameLabel"
    Position: UDim2.new(0.5, 0, 1, -35)
    AnchorPoint: Vector2.new(0.5, 0)
    Size: UDim2.new(1, -10, 0, 16)
    Text: brainrotName if discovered, "???" if not
    TextColor3: RARITY_COLORS[rarity] if discovered, Color3.fromRGB(80, 80, 80) if not
    TextScaled: true
    Font: Enum.Font.GothamBold
    BackgroundTransparency: 1
    TextWrapped: true

  -- Rarity label
  TextLabel "RarityLabel"
    Position: UDim2.new(0.5, 0, 1, -18)
    AnchorPoint: Vector2.new(0.5, 0)
    Size: UDim2.new(1, -10, 0, 14)
    Text: rarity if discovered, "" if not
    TextColor3: RARITY_COLORS[rarity] if discovered, transparent
    TextScaled: true
    Font: Enum.Font.Gotham
    BackgroundTransparency: 1
```

**Public API:**

```luau
function IndexUI.init()
```
- **Step by step:**
  1. Build the ordered `allBrainrotNames` list from `Brainrots.BRAINROTS`.
  2. Create the complete UI hierarchy described above. Parent `IndexGui` to `playerGui`.
  3. Create all 25 brainrot cells in the grid (initially all undiscovered).
  4. Connect `CodexToggleButton.Activated`:
     a. Toggle `codexOpen`.
     b. Set `CodexFrame.Visible = codexOpen`.
     c. If opening, fire `Remotes.RequestIndex:FireServer()` to get latest data.
  5. Connect `CloseButton.Activated`:
     a. Set `codexOpen = false`.
     b. Set `CodexFrame.Visible = false`.
  6. For each tab button, connect `Activated`:
     a. Set `currentTab` to the tab name.
     b. Call `updateTabVisuals()` to highlight the active tab.
     c. Call `refreshGrid()` to show the correct section's discoveries.
  7. Connect `Remotes.IndexUpdated.OnClientEvent` to `onIndexUpdated`.
  8. Connect `Remotes.InitialData.OnClientEvent` to load initial index data (extract `data.index` and `data.unlockedFences` if present).

**Internal functions:**

```luau
local function onIndexUpdated(data)
```
- **Step by step:**
  1. If `data.index` exists (full index payload from RequestIndex):
     a. Set `indexData = data.index`.
     b. If `data.unlockedFences`, set `unlockedFences = data.unlockedFences`.
     c. Call `refreshGrid()`.
  2. If `data.section` and `data.brainrotName` (incremental update from registerDiscovery):
     a. Ensure `indexData[data.section]` exists.
     b. If brainrot name not already in the section table, insert it.
     c. Call `refreshGrid()`.
  3. If `data.sectionComplete` (section completion notification):
     a. Show a celebration animation or notification text.
     b. If `data.fenceReward`, insert into local `unlockedFences` if not already present.

```luau
local function refreshGrid()
```
- **Step by step:**
  1. Get the active section key: `local sectionKey = SECTION_KEYS[currentTab]`.
  2. Get the discovered list: `local discovered = indexData[sectionKey] or {}`.
  3. Build a lookup set: `local discoveredSet = {}; for _, name in discovered do discoveredSet[name] = true end`.
  4. Update progress bar:
     a. Set `ProgressFill.Size = UDim2.new(#discovered / TOTAL_BRAINROTS, 0, 1, 0)`.
     b. Set `ProgressFill.BackgroundColor3 = SECTION_COLORS[currentTab]`.
     c. Set `ProgressText.Text = #discovered .. "/" .. TOTAL_BRAINROTS .. " Discovered"`.
  5. Show/hide complete badge:
     a. If `#discovered >= TOTAL_BRAINROTS`:
        - Set `CompleteBadge.Visible = true`.
        - Set `CompleteBadge.Text = "COMPLETE! Reward: " .. FENCE_REWARD_NAMES[sectionKey]`.
     b. Else: Set `CompleteBadge.Visible = false`.
  6. For each brainrot cell (iterate `allBrainrotNames`):
     a. Get the brainrot config from `Brainrots.BRAINROT_BY_NAME[name]`.
     b. Determine if discovered: `local isDiscovered = discoveredSet[name] == true`.
     c. Update cell appearance:
        - If discovered: show full color background (rarity tint), show name, show rarity, show checkmark, hide "???".
        - If undiscovered: show dark silhouette, show "???", hide name/rarity, hide checkmark.

```luau
local function updateTabVisuals()
```
- **Step by step:**
  1. For each tab button:
     a. If this tab is `currentTab`: set `BackgroundColor3 = SECTION_COLORS[tab]`, `TextColor3 = white`.
     b. Else: set `BackgroundColor3 = Color3.fromRGB(60, 60, 70)`, `TextColor3 = Color3.fromRGB(150, 150, 150)`.

**Module return:**

```luau
return {
    init = IndexUI.init,
}
```

---

### 4.5 `src/client/Controllers/LeaderboardUI.luau` (CREATE)

**Purpose:** Renders a sidebar leaderboard display with tabs for each of the three leaderboard types (Most Money, Most Time, Most Robux). Shows ranked entries with player name and stat value.

**Dependencies:**

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Utils = require(ReplicatedStorage.Shared.Utils)
local Remotes = require(ReplicatedStorage.Remotes)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
```

**Constants:**

```luau
local LEADERBOARD_TABS = { "MostMoney", "MostTime", "MostRobux" }

local TAB_DISPLAY_NAMES = {
    MostMoney = "Most Money",
    MostTime  = "Most Time",
    MostRobux = "Most Robux",
}

local TAB_COLORS = {
    MostMoney = Color3.fromRGB(85, 255, 85),     -- Green
    MostTime  = Color3.fromRGB(85, 170, 255),     -- Blue
    MostRobux = Color3.fromRGB(255, 170, 85),     -- Orange
}

local RANK_COLORS = {
    [1] = Color3.fromRGB(255, 215, 0),    -- Gold
    [2] = Color3.fromRGB(192, 192, 192),  -- Silver
    [3] = Color3.fromRGB(205, 127, 50),   -- Bronze
}

local MAX_VISIBLE_ENTRIES = 50
local REFRESH_COOLDOWN = 10  -- seconds between manual refreshes
```

**Internal state:**

```luau
local leaderboardData = {}          -- {[string]: {{rank, name, value}}}
local currentLeaderboardTab = "MostMoney"
local leaderboardOpen = false
local lastRefreshTime = 0

-- UI references
local screenGui = nil
local leaderboardFrame = nil
local entryList = nil
local tabButtons = {}
```

**UI Layout:**

```
ScreenGui "LeaderboardGui"
  ResetOnSpawn = false
  DisplayOrder = 7

  -- Toggle button on HUD
  TextButton "LeaderboardToggleButton"
    Position: UDim2.new(0, 10, 0, 110)
    AnchorPoint: Vector2.new(0, 0)
    Size: UDim2.new(0, 120, 0, 40)
    Text: "Leaderboard"
    TextColor3: Color3.fromRGB(255, 255, 255)
    BackgroundColor3: Color3.fromRGB(60, 130, 60)
    Font: Enum.Font.GothamBold
    TextScaled: true
    -- Add UICorner with CornerRadius 8

  -- Sidebar leaderboard panel (hidden by default)
  Frame "LeaderboardFrame"
    Position: UDim2.new(1, -10, 0.5, 0)
    AnchorPoint: Vector2.new(1, 0.5)
    Size: UDim2.new(0, 320, 0.7, 0)
    BackgroundColor3: Color3.fromRGB(25, 25, 35)
    BackgroundTransparency: 0.05
    Visible: false
    ZIndex: 8
    -- Add UICorner with CornerRadius 12

    -- Title
    TextLabel "TitleLabel"
      Position: UDim2.new(0.5, 0, 0, 10)
      AnchorPoint: Vector2.new(0.5, 0)
      Size: UDim2.new(1, -20, 0, 30)
      Text: "Leaderboards"
      TextColor3: Color3.fromRGB(255, 255, 255)
      TextScaled: true
      Font: Enum.Font.GothamBold
      BackgroundTransparency: 1

    -- Close button
    TextButton "CloseButton"
      Position: UDim2.new(1, -10, 0, 10)
      AnchorPoint: Vector2.new(1, 0)
      Size: UDim2.new(0, 30, 0, 30)
      Text: "X"
      TextColor3: Color3.fromRGB(255, 255, 255)
      BackgroundColor3: Color3.fromRGB(200, 50, 50)
      Font: Enum.Font.GothamBold
      -- Add UICorner with CornerRadius 6

    -- Tab bar
    Frame "TabBar"
      Position: UDim2.new(0.5, 0, 0, 45)
      AnchorPoint: Vector2.new(0.5, 0)
      Size: UDim2.new(1, -20, 0, 30)
      BackgroundTransparency: 1
      -- Add UIListLayout (Horizontal, Center, 5px padding)

      -- 3 tab buttons
      TextButton "Tab_MostMoney" / "Tab_MostTime" / "Tab_MostRobux"
        Size: UDim2.new(0.3, 0, 1, 0)
        TextScaled: true
        Font: Enum.Font.GothamBold
        -- Active: BackgroundColor3 = TAB_COLORS[tab]
        -- Inactive: BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        -- Add UICorner with CornerRadius 6

    -- Entry list (scrollable)
    ScrollingFrame "EntryList"
      Position: UDim2.new(0.5, 0, 0, 85)
      AnchorPoint: Vector2.new(0.5, 0)
      Size: UDim2.new(1, -20, 1, -95)
      CanvasSize: UDim2.new(0, 0, 0, 0)  -- auto-sized
      ScrollBarThickness: 4
      BackgroundTransparency: 1
      -- Add UIListLayout (Vertical, 4px padding)
```

**Each leaderboard entry (created dynamically per ranked player):**

```
Frame "Entry_[rank]"
  Size: UDim2.new(1, 0, 0, 35)
  BackgroundColor3: Color3.fromRGB(35, 35, 45)
  BackgroundTransparency: 0.3
  -- Add UICorner with CornerRadius 6

  -- Rank number
  TextLabel "RankLabel"
    Position: UDim2.new(0, 8, 0.5, 0)
    AnchorPoint: Vector2.new(0, 0.5)
    Size: UDim2.new(0, 30, 0, 25)
    Text: "#1"
    TextColor3: RANK_COLORS[rank] or Color3.fromRGB(200, 200, 200)
    TextScaled: true
    Font: Enum.Font.GothamBold
    BackgroundTransparency: 1

  -- Player name
  TextLabel "NameLabel"
    Position: UDim2.new(0, 45, 0.5, 0)
    AnchorPoint: Vector2.new(0, 0.5)
    Size: UDim2.new(0.5, -20, 0, 25)
    Text: "PlayerName"
    TextColor3: Color3.fromRGB(255, 255, 255)
    TextScaled: true
    Font: Enum.Font.Gotham
    BackgroundTransparency: 1
    TextXAlignment: Enum.TextXAlignment.Left

  -- Stat value
  TextLabel "ValueLabel"
    Position: UDim2.new(1, -8, 0.5, 0)
    AnchorPoint: Vector2.new(1, 0.5)
    Size: UDim2.new(0.35, 0, 0, 25)
    Text: "$1.5M" or "2h 30m" or "500R$"
    TextColor3: TAB_COLORS[currentTab]
    TextScaled: true
    Font: Enum.Font.GothamBold
    BackgroundTransparency: 1
    TextXAlignment: Enum.TextXAlignment.Right
```

**Public API:**

```luau
function LeaderboardUI.init()
```
- **Step by step:**
  1. Create the complete UI hierarchy described above. Parent `LeaderboardGui` to `playerGui`.
  2. Connect `LeaderboardToggleButton.Activated`:
     a. Toggle `leaderboardOpen`.
     b. Set `LeaderboardFrame.Visible = leaderboardOpen`.
     c. If opening and enough time has passed since last refresh (`os.clock() - lastRefreshTime > REFRESH_COOLDOWN`), fire `Remotes.RequestLeaderboard:FireServer()`.
  3. Connect `CloseButton.Activated`:
     a. Set `leaderboardOpen = false`.
     b. Set `LeaderboardFrame.Visible = false`.
  4. For each tab button, connect `Activated`:
     a. Set `currentLeaderboardTab` to the tab key.
     b. Call `updateLeaderboardTabVisuals()`.
     c. Call `refreshEntryList()`.
  5. Connect `Remotes.LeaderboardData.OnClientEvent` to `onLeaderboardData`.

**Internal functions:**

```luau
local function onLeaderboardData(data)
```
- **Step by step:**
  1. Store `leaderboardData = data` (contains `MostMoney`, `MostTime`, `MostRobux` arrays).
  2. Set `lastRefreshTime = os.clock()`.
  3. Call `refreshEntryList()`.

```luau
local function refreshEntryList()
```
- **Step by step:**
  1. Clear all existing entry Frames from `EntryList`.
  2. Get entries for current tab: `local entries = leaderboardData[currentLeaderboardTab] or {}`.
  3. For each entry in `entries` (up to `MAX_VISIBLE_ENTRIES`):
     a. Create the entry Frame as described above.
     b. Set `RankLabel.Text = "#" .. entry.rank`.
     c. Set `RankLabel.TextColor3 = RANK_COLORS[entry.rank] or Color3.fromRGB(200, 200, 200)`.
     d. Set `NameLabel.Text = entry.name`.
     e. Format the value based on current tab:
        - `MostMoney`: `"$" .. Utils.formatNumber(entry.value)`.
        - `MostTime`: Format as hours and minutes: `math.floor(entry.value / 3600) .. "h " .. math.floor((entry.value % 3600) / 60) .. "m"`.
        - `MostRobux`: `entry.value .. " R$"`.
     f. Set `ValueLabel.TextColor3 = TAB_COLORS[currentLeaderboardTab]`.
  4. Update `EntryList.CanvasSize` based on number of entries.

```luau
local function updateLeaderboardTabVisuals()
```
- **Step by step:**
  1. For each tab button:
     a. If this tab matches `currentLeaderboardTab`: set `BackgroundColor3 = TAB_COLORS[tab]`, `TextColor3 = white`.
     b. Else: set `BackgroundColor3 = Color3.fromRGB(50, 50, 60)`, `TextColor3 = Color3.fromRGB(150, 150, 150)`.

**Module return:**

```luau
return {
    init = LeaderboardUI.init,
}
```

---

### 4.6 `src/server/Services/DataService.luau` (MODIFY)

**What changes:** Ensure the DEFAULT_DATA template includes all Phase 7 fields. Update `onPlayerRemoving` to accumulate session play time. These fields may already be forward-declared from Phase 1 (see Types.luau), but verify they exist in the actual DEFAULT_DATA.

**Verify/update DEFAULT_DATA:**

```luau
local DEFAULT_DATA = {
    money = 100,
    ownedBrainrots = {},
    baseCapacity = 1,
    totalMoneyEarned = 0,
    totalTimePlayed = 0,        -- Phase 7: tracked for leaderboard
    totalRobuxSpent = 0,        -- Phase 7: tracked for leaderboard
    index = {                   -- Phase 7: codex tracking
        normal = {},            -- {string} array of discovered brainrot names
        gold = {},
        diamond = {},
        rainbow = {},
    },
    unlockedFences = {},        -- Phase 7: {string} array of unlocked fence names
    tutorialComplete = false,
}
```

**Verify sessionStartTimes tracking:**

The `sessionStartTimes` table was added in Phase 1. Verify that `onPlayerRemoving` accumulates play time:

```luau
function DataService.onPlayerRemoving(player: Player)
    local profile = activeProfiles[player]
    if not profile then return end

    -- Accumulate session play time
    if sessionStartTimes[player] then
        local sessionDuration = os.clock() - sessionStartTimes[player]
        profile.Data.totalTimePlayed = profile.Data.totalTimePlayed + sessionDuration
    end

    profile:Release()
    activeProfiles[player] = nil
    sessionStartTimes[player] = nil
end
```

**New public function (if not already present):**

```luau
function DataService.getSessionStartTime(player: Player): number?
```
- Returns the `os.clock()` timestamp when the player's session started.
- Used by LeaderboardService to compute current session time for accurate leaderboard pushes.
- **Step by step:**
  1. Return `sessionStartTimes[player]` (may be nil if player data not loaded).

**Add to module return if not already present:**

```luau
DataService.getSessionStartTime = DataService.getSessionStartTime
```

---

### 4.7 `src/server/Services/FoodService.luau` (MODIFY)

**What changes:** After a brainrot successfully stays at the player's base and is added to `data.ownedBrainrots`, call `IndexService.registerDiscovery()` to record the discovery.

**New dependency (add at top of file):**

```luau
local IndexService = require(script.Parent.IndexService)
```

**Modification in the brainrot stay logic:**

Find the section of code where a brainrot is confirmed as "staying" and is inserted into `data.ownedBrainrots`. After the insertion (and after firing `BrainrotSpawned` to the client), add:

```luau
-- Register discovery in the codex (Phase 7)
IndexService.registerDiscovery(player, brainrot.name, brainrot.baseMutation)
```

**Context (expected location in FoodService):**

```luau
-- ... after deciding the brainrot stays ...
table.insert(data.ownedBrainrots, brainrot)
EarningsService.recalculate(player)

-- Notify client
Remotes.BrainrotSpawned:FireClient(player, { brainrotData = brainrot })
Remotes.CapacityUpdated:FireClient(player, {
    current = #data.ownedBrainrots,
    max = data.baseCapacity,
})

-- Register discovery in the codex (Phase 7 -- NEW)
IndexService.registerDiscovery(player, brainrot.name, brainrot.baseMutation)
```

---

### 4.8 `src/server/Remotes/init.luau` (MODIFY)

**What changes:** Add 6 new RemoteEvents for the index, gift, and leaderboard systems.

**New remotes to add:**

```luau
-- Index System (Phase 7)
local RequestIndex = Instance.new("RemoteEvent")
RequestIndex.Name = "RequestIndex"
RequestIndex.Parent = remotesFolder

local IndexUpdated = Instance.new("RemoteEvent")
IndexUpdated.Name = "IndexUpdated"
IndexUpdated.Parent = remotesFolder

-- Gifting System (Phase 7)
local GiftBrainrot = Instance.new("RemoteEvent")
GiftBrainrot.Name = "GiftBrainrot"
GiftBrainrot.Parent = remotesFolder

local GiftReceived = Instance.new("RemoteEvent")
GiftReceived.Name = "GiftReceived"
GiftReceived.Parent = remotesFolder

-- Leaderboard System (Phase 7)
local RequestLeaderboard = Instance.new("RemoteEvent")
RequestLeaderboard.Name = "RequestLeaderboard"
RequestLeaderboard.Parent = remotesFolder

local LeaderboardData = Instance.new("RemoteEvent")
LeaderboardData.Name = "LeaderboardData"
LeaderboardData.Parent = remotesFolder
```

**Add to the returned module table:**

```luau
return {
    -- ... existing remotes from Phases 1-6 ...

    -- Phase 7: Index System
    RequestIndex = RequestIndex,          -- C->S: {} (no payload, just request)
    IndexUpdated = IndexUpdated,          -- S->C: { index?, section?, brainrotName?, sectionComplete?, fenceReward? }

    -- Phase 7: Gifting System
    GiftBrainrot = GiftBrainrot,          -- C->S: { brainrotId: string, targetPlayerId: number }
    GiftReceived = GiftReceived,          -- S->C: { fromPlayerName: string, brainrotName: string, brainrotRarity: string, baseMutation: string? }

    -- Phase 7: Leaderboard System
    RequestLeaderboard = RequestLeaderboard,  -- C->S: {} (no payload, just request)
    LeaderboardData = LeaderboardData,        -- S->C: { MostMoney: {}, MostTime: {}, MostRobux: {}, displayNames: {} }
}
```

**Payload schemas:**

| Remote | Direction | Payload |
|---|---|---|
| `RequestIndex` | Client -> Server | `{}` (no payload) |
| `IndexUpdated` | Server -> Client | Full: `{ index: IndexData, unlockedFences: {string}, allBrainrotNames: {string}, totalRequired: number }` or Incremental: `{ section: string, brainrotName: string, sectionCount: number, totalRequired: number }` or Completion: `{ sectionComplete: true, section: string, fenceReward: string }` |
| `GiftBrainrot` | Client -> Server | `{ brainrotId: string, targetPlayerId: number }` |
| `GiftReceived` | Server -> Client | `{ fromPlayerName: string, brainrotName: string, brainrotRarity: string, baseMutation: string? }` |
| `RequestLeaderboard` | Client -> Server | `{}` (no payload) |
| `LeaderboardData` | Server -> Client | `{ MostMoney: {{rank, userId, value, name}}, MostTime: {{...}}, MostRobux: {{...}}, displayNames: {[string]: string} }` |

---

### 4.9 `src/client/Controllers/BaseUI.luau` (MODIFY)

**What changes:** Add a "Gift" button to each brainrot's info panel or BillboardGui interaction. When clicked, show a player-selection list. Apply unlocked fence cosmetics to the base perimeter fence.

**New dependencies (add at top of file if not already present):**

```luau
local Players = game:GetService("Players")
local Remotes = require(ReplicatedStorage.Remotes)
```

**New state:**

```luau
local currentBestFence = nil  -- string: name of the best unlocked fence
local fenceParts = {}         -- {Part} references to fence perimeter parts
```

#### 4.9.1 Gift Button

Add to each brainrot's BillboardGui or info panel (whichever is used for interaction):

```luau
local function addGiftButton(brainrotPart: Part, brainrotId: string)
    local billboard = brainrotPart:FindFirstChildOfClass("BillboardGui")
    if not billboard then return end

    local giftButton = Instance.new("TextButton")
    giftButton.Name = "GiftButton"
    giftButton.Size = UDim2.new(0, 50, 0, 20)
    giftButton.Position = UDim2.new(1, -55, 1, -25)
    giftButton.Text = "Gift"
    giftButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    giftButton.BackgroundColor3 = Color3.fromRGB(80, 160, 80)
    giftButton.TextScaled = true
    giftButton.Font = Enum.Font.GothamBold
    giftButton.ZIndex = 5
    giftButton.Parent = billboard

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = giftButton

    giftButton.Activated:Connect(function()
        showPlayerSelectionUI(brainrotId)
    end)
end
```

#### 4.9.2 Player Selection UI

When the Gift button is clicked, display a small overlay listing all online players (excluding self) to select a recipient:

```luau
local playerSelectionFrame = nil  -- created once, reused
local activeGiftBrainrotId = nil

local function showPlayerSelectionUI(brainrotId: string)
    activeGiftBrainrotId = brainrotId

    -- Create or show the selection frame
    if not playerSelectionFrame then
        playerSelectionFrame = createPlayerSelectionFrame()
    end

    -- Clear existing entries
    for _, child in playerSelectionFrame.List:GetChildren() do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    -- Populate with online players (excluding self)
    local localPlayer = Players.LocalPlayer
    for _, otherPlayer in Players:GetPlayers() do
        if otherPlayer ~= localPlayer then
            local entry = Instance.new("TextButton")
            entry.Name = "Player_" .. otherPlayer.UserId
            entry.Size = UDim2.new(1, 0, 0, 35)
            entry.Text = otherPlayer.Name
            entry.TextColor3 = Color3.fromRGB(255, 255, 255)
            entry.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            entry.TextScaled = true
            entry.Font = Enum.Font.Gotham
            entry.Parent = playerSelectionFrame.List

            local entryCorner = Instance.new("UICorner")
            entryCorner.CornerRadius = UDim.new(0, 6)
            entryCorner.Parent = entry

            entry.Activated:Connect(function()
                -- Send gift request to server
                Remotes.GiftBrainrot:FireServer({
                    brainrotId = activeGiftBrainrotId,
                    targetPlayerId = otherPlayer.UserId,
                })
                playerSelectionFrame.Frame.Visible = false
            end)
        end
    end

    playerSelectionFrame.Frame.Visible = true
end

local function createPlayerSelectionFrame()
    local frame = Instance.new("Frame")
    frame.Name = "PlayerSelectionFrame"
    frame.Size = UDim2.new(0, 250, 0, 300)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    frame.BackgroundTransparency = 0.05
    frame.ZIndex = 15
    frame.Visible = false
    frame.Parent = playerGui:FindFirstChild("BaseUI") or playerGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 5)
    title.Text = "Gift to:"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.BackgroundTransparency = 1
    title.Parent = frame

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 25, 0, 25)
    closeBtn.Position = UDim2.new(1, -8, 0, 5)
    closeBtn.AnchorPoint = Vector2.new(1, 0)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.ZIndex = 16
    closeBtn.Parent = frame

    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 4)
    closeBtnCorner.Parent = closeBtn

    closeBtn.Activated:Connect(function()
        frame.Visible = false
    end)

    local list = Instance.new("ScrollingFrame")
    list.Name = "List"
    list.Size = UDim2.new(1, -20, 1, -45)
    list.Position = UDim2.new(0, 10, 0, 40)
    list.BackgroundTransparency = 1
    list.ScrollBarThickness = 4
    list.Parent = frame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 4)
    listLayout.Parent = list

    return { Frame = frame, List = list }
end
```

#### 4.9.3 Fence Cosmetics

When fence Parts are created (during BaseUI.init, which creates the base perimeter), apply the best unlocked fence cosmetic.

**Fence cosmetic definitions:**

```luau
local FENCE_COSMETICS = {
    ["Default Fence"] = {
        material = Enum.Material.WoodPlanks,
        color = Color3.fromRGB(139, 90, 43),
        transparency = 0,
    },
    ["Gold Fence"] = {
        material = Enum.Material.SmoothPlastic,
        color = Color3.fromRGB(255, 215, 0),
        transparency = 0,
    },
    ["Diamond Fence"] = {
        material = Enum.Material.Glass,
        color = Color3.fromRGB(185, 242, 255),
        transparency = 0.3,
    },
    ["Rainbow Fence"] = {
        material = Enum.Material.Neon,
        color = nil,  -- cycles through rainbow colors
        transparency = 0,
    },
}
```

**Apply fence cosmetic function:**

```luau
local function applyFenceCosmetic(fenceName: string)
    local cosmetic = FENCE_COSMETICS[fenceName]
    if not cosmetic then return end

    currentBestFence = fenceName

    for _, fencePart in fenceParts do
        if fencePart and fencePart.Parent then
            fencePart.Material = cosmetic.material
            fencePart.Transparency = cosmetic.transparency

            if cosmetic.color then
                fencePart.Color = cosmetic.color
            end
        end
    end

    -- If Rainbow, start color cycling
    if fenceName == "Rainbow Fence" then
        startRainbowFenceCycle()
    end
end

local function startRainbowFenceCycle()
    -- Uses the same RAINBOW_COLORS from Mutations config
    local Mutations = require(ReplicatedStorage.Shared.Config.Mutations)
    local colorIndex = 1

    task.spawn(function()
        while currentBestFence == "Rainbow Fence" do
            local targetColor = Mutations.RAINBOW_COLORS[colorIndex]
            for _, fencePart in fenceParts do
                if fencePart and fencePart.Parent then
                    local tween = TweenService:Create(
                        fencePart,
                        TweenInfo.new(0.5, Enum.EasingStyle.Linear),
                        { Color = targetColor }
                    )
                    tween:Play()
                end
            end
            colorIndex = (colorIndex % #Mutations.RAINBOW_COLORS) + 1
            task.wait(0.5)
        end
    end)
end
```

**Listen for fence updates:**

In BaseUI.init(), listen for `IndexUpdated` to detect new fence unlocks:

```luau
Remotes.IndexUpdated.OnClientEvent:Connect(function(data)
    if data.fenceReward then
        applyFenceCosmetic(data.fenceReward)
    end
end)
```

Also, on initial data load, apply the best fence:

```luau
Remotes.InitialData.OnClientEvent:Connect(function(data)
    -- ... existing logic ...

    -- Apply best fence cosmetic (Phase 7)
    if data.unlockedFences and #data.unlockedFences > 0 then
        local bestFence = getBestFenceFromList(data.unlockedFences)
        if bestFence then
            applyFenceCosmetic(bestFence)
        end
    end
end)

local FENCE_PRIORITY = {
    ["Default Fence"]  = 1,
    ["Gold Fence"]     = 2,
    ["Diamond Fence"]  = 3,
    ["Rainbow Fence"]  = 4,
}

local function getBestFenceFromList(fences: {string}): string?
    local bestPriority = 0
    local bestFence = nil
    for _, fence in fences do
        local priority = FENCE_PRIORITY[fence] or 0
        if priority > bestPriority then
            bestPriority = priority
            bestFence = fence
        end
    end
    return bestFence
end
```

**Also update `spawnBrainrotVisual()` to add the Gift button:**

At the end of `spawnBrainrotVisual()`, after creating the BillboardGui and all existing visual effects:

```luau
-- Add gift button (Phase 7)
addGiftButton(part, brainrot.id)
```

**Listen for GiftReceived to show notification:**

```luau
Remotes.GiftReceived.OnClientEvent:Connect(function(data)
    -- Show a brief notification to the recipient
    showGiftNotification(data.fromPlayerName, data.brainrotName, data.brainrotRarity, data.baseMutation)
end)

local function showGiftNotification(fromPlayer: string, brainrotName: string, rarity: string, mutation: string?)
    local mutationText = mutation and (mutation .. " ") or ""
    local message = fromPlayer .. " gifted you a " .. mutationText .. brainrotName .. "!"

    -- Create a temporary notification label
    local notification = Instance.new("TextLabel")
    notification.Name = "GiftNotification"
    notification.Size = UDim2.new(0.4, 0, 0, 50)
    notification.Position = UDim2.new(0.3, 0, 0.15, 0)
    notification.BackgroundColor3 = Color3.fromRGB(80, 160, 80)
    notification.BackgroundTransparency = 0.2
    notification.TextColor3 = Color3.fromRGB(255, 255, 255)
    notification.TextScaled = true
    notification.Font = Enum.Font.GothamBold
    notification.Text = message
    notification.ZIndex = 20
    notification.Parent = playerGui

    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 10)
    notifCorner.Parent = notification

    -- Fade out after 4 seconds
    task.delay(4, function()
        local fadeOut = TweenService:Create(
            notification,
            TweenInfo.new(1, Enum.EasingStyle.Linear),
            { BackgroundTransparency = 1, TextTransparency = 1 }
        )
        fadeOut:Play()
        fadeOut.Completed:Connect(function()
            notification:Destroy()
        end)
    end)
end
```

---

### 4.10 `src/server/init.server.luau` (MODIFY)

**What changes:** Add IndexService, GiftService, and LeaderboardService to the server boot sequence. IndexService must be initialized before FoodService (since FoodService calls IndexService.registerDiscovery). GiftService depends on IndexService, EarningsService, BaseService, and DataService. LeaderboardService depends on DataService.

**Add requires:**

```luau
local IndexService = require(script.Services.IndexService)
local GiftService = require(script.Services.GiftService)
local LeaderboardService = require(script.Services.LeaderboardService)
```

**Expected boot order (Phase 7):**

```luau
DataService.init()
EarningsService.init()
BaseService.init()
IndexService.init()         -- Phase 7 (NEW, before FoodService)
FoodService.init()
SellService.init()          -- Phase 5
WeatherService.init()       -- Phase 6
GiftService.init()          -- Phase 7 (NEW, after all core services)
LeaderboardService.init()   -- Phase 7 (NEW, last)
```

**Note:** IndexService.init() is placed before FoodService.init() because FoodService requires IndexService at module load time. All `require` calls happen before any `.init()` calls, so the actual dependency is on the require, not the init order. However, placing IndexService.init() before FoodService.init() is a good practice for clarity.

---

### 4.11 `src/client/init.client.luau` (MODIFY)

**What changes:** Add IndexUI and LeaderboardUI to the client boot sequence.

**Add requires:**

```luau
local IndexUI = require(script.Controllers.IndexUI)
local LeaderboardUI = require(script.Controllers.LeaderboardUI)
```

**Add init calls:**

```luau
IndexUI.init()
LeaderboardUI.init()
```

**Expected boot order (Phase 7):**

```luau
MoneyUI.init()
BaseUI.init()
FoodStoreUI.init()
SellUI.init()               -- Phase 5
WeatherUI.init()            -- Phase 6
IndexUI.init()              -- Phase 7 (NEW)
LeaderboardUI.init()        -- Phase 7 (NEW)
```

---

## 5. Module Contracts

### New Cross-Module Dependencies (Phase 7)

**IndexService requires:**

| Module | Function/Field Used | Purpose |
|---|---|---|
| `Config/Brainrots` | `Brainrots.BRAINROTS` | Iterate all brainrots to build the `allBrainrotNames` list |
| `DataService` | `DataService.getData(player)` | Read/write `data.index` and `data.unlockedFences` |
| `Remotes` | `Remotes.RequestIndex` | Listen for client codex requests |
| `Remotes` | `Remotes.IndexUpdated` | Fire index updates and section completion notifications to client |

**GiftService requires:**

| Module | Function/Field Used | Purpose |
|---|---|---|
| `DataService` | `DataService.getData(player)` | Read/write sender and recipient brainrot inventories |
| `EarningsService` | `EarningsService.recalculate(player)` | Recalculate earnings for both sender and recipient after transfer |
| `IndexService` | `IndexService.registerDiscovery(player, name, mutation)` | Register the gifted brainrot in the recipient's codex |
| `BaseService` | `BaseService.getCapacity(player)` | Check recipient's capacity before allowing gift |
| `Remotes` | `Remotes.GiftBrainrot` | Listen for gift requests from clients |
| `Remotes` | `Remotes.GiftReceived` | Notify recipient about the received gift |
| `Remotes` | `Remotes.BrainrotSpawned` | Fire to recipient to add the brainrot to their visual base |
| `Remotes` | `Remotes.CapacityUpdated` | Update both sender and recipient capacity displays |

**LeaderboardService requires:**

| Module | Function/Field Used | Purpose |
|---|---|---|
| `DataStoreService` | `:GetOrderedDataStore(name)` | Create/access the 3 OrderedDataStores |
| `DataService` | `DataService.getData(player)` | Read `totalMoneyEarned`, `totalTimePlayed`, `totalRobuxSpent` |
| `DataService` | `DataService.getSessionStartTime(player)` | Compute live session time for accurate leaderboard stats |
| `Remotes` | `Remotes.RequestLeaderboard` | Listen for leaderboard data requests |
| `Remotes` | `Remotes.LeaderboardData` | Send top-50 data to requesting client |

**IndexUI requires:**

| Module | Function/Field Used | Purpose |
|---|---|---|
| `Config/Brainrots` | `Brainrots.BRAINROTS`, `Brainrots.BRAINROT_BY_NAME` | Build grid cells with brainrot names and rarity info |
| `Utils` | `Utils.formatNumber()` | Format numbers in UI if needed |
| `Remotes` | `Remotes.RequestIndex` | Request full index data from server |
| `Remotes` | `Remotes.IndexUpdated` | Receive index updates (full, incremental, completion) |
| `Remotes` | `Remotes.InitialData` | Load initial index data on join |

**LeaderboardUI requires:**

| Module | Function/Field Used | Purpose |
|---|---|---|
| `Utils` | `Utils.formatNumber()` | Format money values with suffixes |
| `Remotes` | `Remotes.RequestLeaderboard` | Request leaderboard data from server |
| `Remotes` | `Remotes.LeaderboardData` | Receive top-50 leaderboard data |

**BaseUI now additionally requires:**

| Module | Function/Field Used | Purpose |
|---|---|---|
| `Remotes` | `Remotes.GiftBrainrot` | Fire gift request to server |
| `Remotes` | `Remotes.GiftReceived` | Listen for gift received notifications |
| `Remotes` | `Remotes.IndexUpdated` | Listen for fence unlock notifications |
| `Config/Mutations` | `Mutations.RAINBOW_COLORS` | Rainbow fence color cycling |

**FoodService now additionally requires:**

| Module | Function/Field Used | Purpose |
|---|---|---|
| `IndexService` | `IndexService.registerDiscovery(player, name, mutation)` | Register brainrot discovery in codex on spawn |

### Existing Contracts (Unchanged)

- IndexService does NOT modify any brainrot fields. It only reads `brainrot.name` and `brainrot.baseMutation`.
- GiftService does NOT modify the brainrot data itself. It moves the brainrot object intact from one player's inventory to another's.
- LeaderboardService is read-only with respect to player data. It reads stats but never modifies them.
- The `BrainrotSpawned` remote payload is reused for gifted brainrots (same payload shape).
- No changes to EarningsService, SellService, or WeatherService.

---

## 6. Agent Task Breakdown

Tasks are organized into steps. Steps must be completed in order. Tasks within a step can be done in parallel.

### Step 1 (Parallel -- no inter-dependencies)

| Task | File | Action | Est. Lines |
|---|---|---|---|
| 1.1 | `src/server/Remotes/init.luau` | MODIFY | ~25 |
| 1.2 | `src/server/Services/DataService.luau` | MODIFY | ~15 |

- **1.1 Remotes/init.luau:** Add 6 new RemoteEvent instances (`RequestIndex`, `IndexUpdated`, `GiftBrainrot`, `GiftReceived`, `RequestLeaderboard`, `LeaderboardData`) and include them in the returned table.
- **1.2 DataService.luau:** Verify DEFAULT_DATA includes `index`, `unlockedFences`, `totalTimePlayed`, `totalRobuxSpent` fields. Add `getSessionStartTime()` public function. Verify `onPlayerRemoving` accumulates session play time.

### Step 2 (Depends on Step 1)

| Task | File | Action | Est. Lines |
|---|---|---|---|
| 2.1 | `src/server/Services/IndexService.luau` | CREATE | ~130 |
| 2.2 | `src/server/Services/LeaderboardService.luau` | CREATE | ~170 |

- **2.1 IndexService.luau:** Create the complete index service with `init()`, `registerDiscovery()`, `getIndexData()`, `getBestFence()`, `awardFenceReward()`, and `handleRequestIndex()`.
- **2.2 LeaderboardService.luau:** Create the complete leaderboard service with `init()`, `updateLeaderboards()`, `updateLoop()`, and `handleRequestLeaderboard()`. Set up 3 OrderedDataStores with periodic push/fetch.

### Step 3 (Depends on Step 2)

| Task | File | Action | Est. Lines |
|---|---|---|---|
| 3.1 | `src/server/Services/GiftService.luau` | CREATE | ~120 |
| 3.2 | `src/server/Services/FoodService.luau` | MODIFY | ~5 |

- **3.1 GiftService.luau:** Create the complete gift service with `init()`, `handleGiftBrainrot()`, cooldown tracking, and player cleanup. Depends on IndexService for `registerDiscovery()`.
- **3.2 FoodService.luau:** Add `require(IndexService)` and insert `IndexService.registerDiscovery()` call after brainrot stays.

### Step 4 (Parallel, depends on Step 2)

| Task | File | Action | Est. Lines |
|---|---|---|---|
| 4.1 | `src/client/Controllers/IndexUI.luau` | CREATE | ~350 |
| 4.2 | `src/client/Controllers/LeaderboardUI.luau` | CREATE | ~250 |
| 4.3 | `src/client/Controllers/BaseUI.luau` | MODIFY | ~250 |

- **4.1 IndexUI.luau:** Create the full-screen codex overlay with 4 tabs, brainrot grid, progress bars, complete badges, and fence reward display. Connect to `RequestIndex` and `IndexUpdated` remotes.
- **4.2 LeaderboardUI.luau:** Create the sidebar leaderboard panel with 3 tabs, ranked entry list, and refresh logic. Connect to `RequestLeaderboard` and `LeaderboardData` remotes.
- **4.3 BaseUI.luau:** Add gift button per brainrot, player selection UI, fence cosmetic system (Default/Gold/Diamond/Rainbow with material/color changes), rainbow fence cycling, and gift notification display.

### Step 5 (Depends on Steps 3 and 4)

| Task | File | Action | Est. Lines Changed |
|---|---|---|---|
| 5.1 | `src/server/init.server.luau` | MODIFY | ~6 |
| 5.2 | `src/client/init.client.luau` | MODIFY | ~4 |

- **5.1 init.server.luau:** Add `require` for IndexService, GiftService, LeaderboardService. Add `.init()` calls in correct boot order.
- **5.2 init.client.luau:** Add `require` for IndexUI, LeaderboardUI. Add `.init()` calls after existing controllers.

### Task Dependency Diagram

```
Step 1 (parallel):
  1.1 Remotes/init.luau (MODIFY) -------+
  1.2 DataService.luau (MODIFY) --------+
         |
         v
Step 2 (parallel):
  2.1 IndexService.luau (CREATE) -------+
  2.2 LeaderboardService.luau (CREATE) -+
         |
         v
Step 3 (parallel):
  3.1 GiftService.luau (CREATE) --------+
  3.2 FoodService.luau (MODIFY) --------+
         |
         v
Step 4 (parallel):
  4.1 IndexUI.luau (CREATE) ------------+
  4.2 LeaderboardUI.luau (CREATE) ------+
  4.3 BaseUI.luau (MODIFY) ------------+
         |
         v
Step 5 (parallel):
  5.1 init.server.luau (MODIFY) --------+
  5.2 init.client.luau (MODIFY) --------+
```

### Total: 5 new files, 6 modified files, ~1,325 estimated lines of new/changed Luau code.

---

## 7. Data Structures

### 7.1 Updated PlayerData (Phase 7 shape)

```luau
{
    money = 15000,
    ownedBrainrots = { ... },       -- {BrainrotInstance}
    baseCapacity = 10,
    totalMoneyEarned = 500000,
    totalTimePlayed = 7200,         -- seconds (2 hours)
    totalRobuxSpent = 0,
    index = {
        normal = {
            "Burbaloni Lulilolli",
            "Hipocactus",
            "Bobrito Bandito",
            "Tralalero Tralala",
            -- ... discovered brainrot names in normal (no mutation) form
        },
        gold = {
            "Burbaloni Lulilolli",
            -- ... discovered brainrot names in Gold mutation form
        },
        diamond = {},               -- no Diamond-mutated brainrots discovered yet
        rainbow = {},               -- no Rainbow-mutated brainrots discovered yet
    },
    unlockedFences = {},            -- e.g. {"Default Fence"} when normal section complete
    tutorialComplete = false,
}
```

### 7.2 IndexData Type

```luau
type IndexData = {
    normal: {string},      -- Array of brainrot names discovered without mutation
    gold: {string},        -- Array of brainrot names discovered with Gold mutation
    diamond: {string},     -- Array of brainrot names discovered with Diamond mutation
    rainbow: {string},     -- Array of brainrot names discovered with Rainbow mutation
}
```

Each section is an array of strings (brainrot names). A section is complete when it contains all 25 unique brainrot names.

### 7.3 Fence Reward Mapping

| Section | Completion Condition | Fence Reward | Visual Effect |
|---|---|---|---|
| Normal | Discover all 25 brainrots in normal form (no base mutation) | "Default Fence" | Upgraded wood planks fence, warm brown color |
| Gold | Discover all 25 brainrots with Gold mutation | "Gold Fence" | Smooth gold-colored fence |
| Diamond | Discover all 25 brainrots with Diamond mutation | "Diamond Fence" | Translucent glass/crystal fence, light cyan color |
| Rainbow | Discover all 25 brainrots with Rainbow mutation | "Rainbow Fence" | Neon fence that cycles through rainbow colors |

**Fence priority (for display when multiple are unlocked):**

| Fence | Priority | Material | Color | Transparency |
|---|---|---|---|---|
| Default Fence | 1 | WoodPlanks | RGB(139, 90, 43) | 0 |
| Gold Fence | 2 | SmoothPlastic | RGB(255, 215, 0) | 0 |
| Diamond Fence | 3 | Glass | RGB(185, 242, 255) | 0.3 |
| Rainbow Fence | 4 | Neon | Cycling | 0 |

The player's base always displays the highest-priority fence they have unlocked. If no fences are unlocked, the base uses the Phase 5 default wooden fence (basic wood material).

### 7.4 Leaderboard Entry Shape

```luau
type LeaderboardEntry = {
    rank: number,           -- 1-50
    userId: number,         -- Roblox UserId
    name: string,           -- Display name
    value: number,          -- Stat value (money, seconds, or Robux amount)
}
```

### 7.5 Remote Payload Shapes

**IndexUpdated -- Full response (from RequestIndex):**

```luau
{
    index = {
        normal = { "Burbaloni Lulilolli", "Hipocactus", ... },
        gold = { "Burbaloni Lulilolli" },
        diamond = {},
        rainbow = {},
    },
    unlockedFences = { "Default Fence" },
    allBrainrotNames = {
        "Burbaloni Lulilolli", "Hipocactus", "Bobrito Bandito",
        "Talpa Di Ferro", "Svinino Bombondino", "Frigo Camelo",
        -- ... all 25 names in BRAINROTS array order
    },
    totalRequired = 25,
}
```

**IndexUpdated -- Incremental update (from registerDiscovery):**

```luau
{
    section = "gold",
    brainrotName = "Tralalero Tralala",
    sectionCount = 3,
    totalRequired = 25,
}
```

**IndexUpdated -- Section completion:**

```luau
{
    sectionComplete = true,
    section = "normal",
    fenceReward = "Default Fence",
}
```

**GiftBrainrot (C->S):**

```luau
{
    brainrotId = "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6",
    targetPlayerId = 123456789,
}
```

**GiftReceived (S->C):**

```luau
{
    fromPlayerName = "Player1",
    brainrotName = "Tralalero Tralala",
    brainrotRarity = "Epic",
    baseMutation = "Gold",      -- or nil
}
```

**LeaderboardData (S->C):**

```luau
{
    MostMoney = {
        { rank = 1, userId = 111, name = "TopPlayer", value = 50000000 },
        { rank = 2, userId = 222, name = "SecondPlace", value = 35000000 },
        -- ... up to 50 entries
    },
    MostTime = {
        { rank = 1, userId = 333, name = "Dedicated", value = 360000 },  -- 100 hours in seconds
        -- ...
    },
    MostRobux = {
        { rank = 1, userId = 444, name = "Whale", value = 10000 },
        -- ...
    },
    displayNames = {
        MostMoney = "Most Money Earned",
        MostTime = "Most Time Played",
        MostRobux = "Most Robux Spent",
    },
}
```

### 7.6 Section Completion Requirements

For any section to be marked complete, it must contain exactly these 25 brainrot names (regardless of order):

```luau
{
    "Burbaloni Lulilolli",
    "Hipocactus",
    "Bobrito Bandito",
    "Talpa Di Ferro",
    "Svinino Bombondino",
    "Frigo Camelo",
    "Blueberrinni Octopussini",
    "Orangutini Ananasini",
    "Tigrrullini Watermellini",
    "Boneca Ambalabu",
    "Chef Crabracadabra",
    "Glorbo Fruttodrillo",
    "Tralalero Tralala",
    "Shpioniro Golubiro",
    "Ballerina Cappuccina",
    "Bombombini Gusini",
    "Chimpanzini Bananini",
    "Brr Brr Patapim",
    "Cappuccino Assassino",
    "Lirili Larila",
    "Bombardiro Crocodilo",
    "Tung Tung Tung Sahur",
    "Trippi Troppi",
    "Centralucci Nuclearucci",
    "La Vaca Saturno Saturnita",
}
```

The Normal section tracks these with `baseMutation == nil`. The Gold section tracks these with `baseMutation == "Gold"`. And so on for Diamond and Rainbow.

### 7.7 Gift Validation Checklist

Every gift attempt must pass ALL of these checks (in order):

| # | Check | Failure Response |
|---|---|---|
| 1 | Cooldown: `os.clock() - lastGiftTime[player] >= GIFT_COOLDOWN` | Reject, warn "Cooldown active" |
| 2 | Payload: `brainrotId` is a string, `targetPlayerId` is a number | Reject, warn "Invalid payload" |
| 3 | Self-gift: `targetPlayerId ~= player.UserId` | Reject, warn "Cannot gift to yourself" |
| 4 | Sender data: `DataService.getData(player) ~= nil` | Reject, warn "No sender data" |
| 5 | Ownership: brainrot with matching id exists in sender's `ownedBrainrots` | Reject, warn "Brainrot not found" |
| 6 | Target online: `Players:GetPlayerByUserId(targetPlayerId) ~= nil` | Reject, warn "Target not online" |
| 7 | Target data: `DataService.getData(targetPlayer) ~= nil` | Reject, warn "No target data" |
| 8 | Target capacity: `#targetData.ownedBrainrots < targetData.baseCapacity` | Reject, warn "Target base full" |

---

## 8. Testing Criteria

After all files are written, verify the following. Every test must pass.

### Build Test

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T1 | `rojo build` succeeds | Run `rojo build -o "collect-brainrots.rbxlx"` | Exits with code 0, no errors. |

### Index / Codex Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T2 | Codex opens via button | Click the "Codex" button on the HUD | Full-screen overlay appears with 4 tabs and a brainrot grid. |
| T3 | Normal tab shows discoveries | Spawn brainrots without mutations, open codex | Spawned brainrots appear in full color; unspawned ones appear as dark silhouettes with "???". |
| T4 | Gold tab tracks Gold mutations | Spawn a Gold-mutated brainrot, switch to Gold tab | The brainrot appears as discovered in the Gold section. |
| T5 | Diamond tab tracks Diamond mutations | Spawn a Diamond-mutated brainrot, switch to Diamond tab | The brainrot appears as discovered in the Diamond section. |
| T6 | Rainbow tab tracks Rainbow mutations | Spawn a Rainbow-mutated brainrot, switch to Rainbow tab | The brainrot appears as discovered in the Rainbow section. |
| T7 | Progress bar updates correctly | Discover several brainrots in a section | Progress bar fills proportionally (e.g., "5/25 Discovered"), text updates. |
| T8 | A brainrot in multiple sections | Spawn "Hipocactus" normally and also as Gold | "Hipocactus" appears discovered in BOTH Normal and Gold tabs. |
| T9 | Duplicate discoveries are ignored | Spawn the same normal brainrot twice | The discovery count does not increment the second time. |
| T10 | Index data persists across sessions | Discover brainrots, leave and rejoin | All discoveries are still shown in the codex after rejoin. |

### Fence Reward Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T11 | Normal section complete awards Default Fence | Complete the Normal section (all 25 in normal form) | "COMPLETE!" badge appears, "Default Fence" is awarded. Base fence changes to upgraded wood. |
| T12 | Gold section complete awards Gold Fence | Complete the Gold section (all 25 in Gold form) | Gold Fence awarded. Base fence turns gold-colored with SmoothPlastic material. |
| T13 | Diamond section complete awards Diamond Fence | Complete the Diamond section | Diamond Fence awarded. Base fence turns translucent cyan Glass material. |
| T14 | Rainbow section complete awards Rainbow Fence | Complete the Rainbow section | Rainbow Fence awarded. Base fence cycles through rainbow colors with Neon material. |
| T15 | Best fence is displayed | Unlock both Default and Gold fences | Base displays Gold Fence (higher priority), not Default. |
| T16 | Fence persists across sessions | Unlock a fence, leave and rejoin | Fence cosmetic is still applied after rejoin. |

### Gifting Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T17 | Gift button appears on brainrots | Look at a brainrot's BillboardGui | A "Gift" button is visible on the brainrot's info panel. |
| T18 | Player selection shows online players | Click "Gift" button | A list of online players (excluding self) appears. |
| T19 | Gifting transfers ownership | Gift a brainrot to another player | Brainrot disappears from sender's base; appears on recipient's base. |
| T20 | Sender earnings decrease after gift | Note sender's earnings/sec before and after gifting | Earnings decrease by the gifted brainrot's contribution. |
| T21 | Recipient earnings increase after gift | Note recipient's earnings/sec before and after receiving | Earnings increase by the gifted brainrot's contribution. |
| T22 | Recipient's codex updates | Gift a brainrot the recipient hasn't discovered | The brainrot appears as discovered in the recipient's codex. |
| T23 | Cannot gift to yourself | Attempt to gift (should not be possible, self excluded from list) | Self does not appear in the player selection list. |
| T24 | Cannot gift to a full base | Gift to a player whose base is at max capacity | Server rejects the gift; brainrot stays with sender. |
| T25 | Gift cooldown works | Gift a brainrot, then immediately try to gift another | Second gift is rejected; must wait 5 seconds. |
| T26 | Recipient sees notification | Gift a brainrot to another player | Recipient sees a notification: "Player1 gifted you a Gold Tralalero Tralala!" |
| T27 | Cannot gift brainrot you don't own | Attempt to send a fake brainrotId | Server rejects; warns "Brainrot not found in sender inventory". |

### Leaderboard Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T28 | Leaderboard opens via button | Click the "Leaderboard" button on the HUD | Sidebar panel appears with 3 tabs. |
| T29 | Most Money tab shows ranked players | Open leaderboard after earning money | Players ranked by total money earned, descending. |
| T30 | Most Time tab shows ranked players | Open leaderboard after playing for some time | Players ranked by total time played, descending. Format: "Xh Ym". |
| T31 | Most Robux tab shows ranked players | Open leaderboard (may be empty if no one spent Robux) | Players ranked by total Robux spent, or empty list. |
| T32 | Top 3 have special colors | Have 3+ entries on a leaderboard | #1 is gold, #2 is silver, #3 is bronze colored text. |
| T33 | Leaderboards update periodically | Play for 2+ minutes, refresh leaderboard | Stats reflect recent activity (within 60-second update window). |
| T34 | Leaderboard data survives rejoin | Earn significant money, leave and rejoin, check leaderboard | Your stats still appear on the leaderboard. |
| T35 | Leaderboards show up to 50 entries | Have many players (or use test data) | Leaderboard shows a maximum of 50 ranked entries. |

### Integration Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T36 | Gifted brainrot retains all properties | Gift a Gold Large Soaked brainrot; inspect on recipient's side | All properties (name, rarity, size, sizeLabel, weight, baseMutation, weatherMutation, earningsPerSec) are preserved. |
| T37 | Sell still works after Phase 7 | Sell a brainrot via the Sell Store | Brainrot is sold for correct value; money added. |
| T38 | Weather mutations still work after Phase 7 | Trigger a weather event | Weather mutations still apply to brainrots correctly. |
| T39 | Capacity upgrades still work after Phase 7 | Upgrade base capacity | Capacity increases; cost is deducted. |

### Console Cleanliness Test

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T40 | No errors in console | Check Studio Output for red error text during gameplay | Zero errors. |

### Performance Test

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T41 | No lag from leaderboard updates | Play with leaderboard service running | No noticeable frame drops or stutters from periodic DataStore calls. |
| T42 | Codex opens quickly with all 25 brainrots rendered | Open codex with many discoveries | Grid renders in under 0.5 seconds; no visible lag. |

---

## 9. Acceptance Criteria

All of the following must be true before Phase 7 is considered complete:

| # | Criterion | How to Verify |
|---|---|---|
| 1 | `rojo build` succeeds without errors | Run `rojo build -o "collect-brainrots.rbxlx"` |
| 2 | Codex overlay opens and displays all 25 brainrots across 4 tabs (Normal, Gold, Diamond, Rainbow) | Visual check |
| 3 | Discovered brainrots appear in full color with name; undiscovered ones appear as dark silhouettes with "???" | Visual check in each section |
| 4 | Progress bar per section shows correct count (X/25) and fills proportionally | Visual check after discoveries |
| 5 | Discoveries register correctly: normal brainrot to Normal section, Gold-mutated to Gold section, etc. | Spawn brainrots with various mutations and verify codex sections |
| 6 | Duplicate discoveries are ignored (spawning the same brainrot twice does not increment count) | Spawn same brainrot twice, verify count is 1 |
| 7 | Completing Normal section awards "Default Fence"; Gold section awards "Gold Fence"; Diamond awards "Diamond Fence"; Rainbow awards "Rainbow Fence" | Complete a section and verify fence is awarded and visually applied |
| 8 | Fence cosmetics visually change the base perimeter fence (material, color, transparency match spec) | Visual check after unlocking each fence |
| 9 | Best fence is always displayed (highest priority) when multiple fences are unlocked | Unlock multiple fences and verify highest priority is shown |
| 10 | Rainbow Fence cycles through rainbow colors | Visual check |
| 11 | Gift button appears on every brainrot's info panel | Visual check |
| 12 | Clicking Gift shows a list of online players (excluding self) | Click Gift and verify list |
| 13 | Gifting transfers the brainrot from sender to recipient with all properties intact | Gift a brainrot and inspect on both sides |
| 14 | Earnings recalculate correctly for both sender and recipient after a gift | Check earnings/sec before and after |
| 15 | Gifted brainrots register as discoveries in the recipient's codex | Gift an undiscovered brainrot and check recipient's codex |
| 16 | Gift validation prevents: self-gift, gifting unowned brainrots, gifting to offline players, gifting to full bases | Test each invalid scenario |
| 17 | Gift cooldown of 5 seconds prevents spam | Gift rapidly and verify rejection |
| 18 | Recipient receives a visible notification when gifted a brainrot | Visual check on recipient's screen |
| 19 | Three leaderboards display correctly: Most Money, Most Time, Most Robux | Open leaderboard and check each tab |
| 20 | Leaderboard entries show rank, player name, and formatted stat value | Visual check |
| 21 | Top 3 entries have gold/silver/bronze colored rank numbers | Visual check |
| 22 | Leaderboards update every 60 seconds for online players | Wait 60+ seconds and verify data refresh |
| 23 | Leaderboard data persists via OrderedDataStores across server restarts | Check leaderboard after server restart |
| 24 | All index, fence, and leaderboard data persists across player sessions | Leave and rejoin, verify all data intact |
| 25 | No errors or warnings in Studio Output console | Check for red/yellow text |
| 26 | No performance issues from periodic leaderboard updates or codex rendering | FPS remains stable |
| 27 | All Phase 6 functionality still works (weather events, weather mutations, earnings formula) | Regression test |
| 28 | All Phase 5 functionality still works (sell system, base management, capacity upgrades) | Regression test |

---

## Appendix A: Index Section Mutation Mapping

```
baseMutation == nil       ->  Section: "normal"
baseMutation == "Gold"    ->  Section: "gold"
baseMutation == "Diamond" ->  Section: "diamond"
baseMutation == "Rainbow" ->  Section: "rainbow"
```

A single brainrot species (e.g., "Tralalero Tralala") can appear in all 4 sections if the player discovers it in all 4 forms. Each discovery is tracked independently.

## Appendix B: Leaderboard OrderedDataStore Keys

```
Store: "Leaderboard_MostMoney_v1"
  Key format: "123456789" (player UserId as string)
  Value: integer (total money earned, floor'd)

Store: "Leaderboard_MostTime_v1"
  Key format: "123456789"
  Value: integer (total seconds played, floor'd)

Store: "Leaderboard_MostRobux_v1"
  Key format: "123456789"
  Value: integer (total Robux spent)
```

All values are integers because Roblox OrderedDataStores only support integer values. Fractional values are floor'd before storage.

## Appendix C: Gift Flow Sequence Diagram

```
Sender Client                Server                     Recipient Client
     |                          |                              |
     |--[Click Gift button]---->|                              |
     |--[Select player]-------->|                              |
     |--GiftBrainrot----------->|                              |
     |                          |--[Validate all 8 checks]     |
     |                          |--[Remove from sender inv]    |
     |                          |--[Add to recipient inv]      |
     |                          |--[Recalculate earnings x2]   |
     |                          |--[Register discovery]        |
     |<--CapacityUpdated--------|                              |
     |                          |--BrainrotSpawned------------>|
     |                          |--CapacityUpdated------------>|
     |                          |--GiftReceived--------------->|
     |                          |                              |--[Show notification]
     |                          |                              |--[Render brainrot]
```

## Appendix D: Codex Completion Difficulty Estimate

| Section | Difficulty | Reasoning |
|---|---|---|
| Normal | Medium | Requires discovering all 25 brainrots in normal form. Unknown-rarity brainrots are very rare. |
| Gold | Hard | Same as Normal, but every brainrot must also roll Gold mutation (8% chance). |
| Diamond | Very Hard | Every brainrot must roll Diamond mutation (5% chance). Combined with Unknown rarity being rare. |
| Rainbow | Extremely Hard | Every brainrot must roll Rainbow mutation (2% chance). The rarest combination possible. |

Expected time to complete all 4 sections scales exponentially with mutation rarity. The Rainbow section is intended as an endgame completionist goal.

## Appendix E: Fence Priority Quick Reference

```
No fence unlocked       -> Phase 5 default wooden fence (basic Wood material, brown)
Default Fence (P=1)     -> WoodPlanks, RGB(139,90,43), opaque
Gold Fence (P=2)        -> SmoothPlastic, RGB(255,215,0), opaque
Diamond Fence (P=3)     -> Glass, RGB(185,242,255), 30% transparent
Rainbow Fence (P=4)     -> Neon, cycling rainbow colors, opaque
```

The highest-priority unlocked fence is always displayed. Lower-priority fences are unlocked but not visually active.

---

*End of Phase 7 Index, Gifting, and Leaderboards specification.*
