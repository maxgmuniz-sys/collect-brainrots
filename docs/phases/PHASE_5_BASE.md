# Phase 5: Base Management and Sell Store

> **Status:** NOT STARTED
> **Depends on:** Phase 4 (mutations working, earnings formula includes size and mutation multipliers)
> **Estimated scope:** 7 files (2 new, 5 modified)

---

## 1. Objective

Implement base capacity upgrades and the sell store, completing the core economic loop. Players start with 1 brainrot slot and can upgrade their base capacity up to 30 slots using an exponentially scaling cost curve. Players can sell individual brainrots or their entire inventory for in-game money. Visual fencing is added around the player's plot to create a clear boundary and sense of ownership.

By the end of this phase:
- Base capacity is upgradeable from 1 to 30 slots with exponentially scaling costs.
- The upgrade button displays the current capacity, max capacity, and next upgrade cost.
- Players can sell individual brainrots for 60 seconds' worth of their earnings (factoring in size and base mutation, but NOT weather mutation).
- Players can sell all brainrots at once with a confirmation prompt.
- Sell values are displayed per-brainrot in the sell store interface.
- A wooden fence perimeter is rendered around the player's plot.
- All sell and upgrade operations are validated server-side to prevent exploits.

---

## 2. Prerequisites

Phase 4 must be fully complete before starting Phase 5. Specifically:

- `src/shared/Config/Mutations.luau` exists and defines base mutations (Gold, Diamond, Rainbow) with chances, multipliers, colors, and particle data.
- `src/server/Services/FoodService.luau` rolls a base mutation on brainrot spawn and factors it into `earningsPerSec`.
- `src/server/Services/EarningsService.luau` recalculates earnings using the full formula: `baseEarnings * sizeMult * baseMutationMult * weatherMutationMult`.
- `src/client/Controllers/BaseUI.luau` applies mutation color tints, particle emitters, and updated BillboardGui labels.
- `src/client/Controllers/FoodStoreUI.luau` shows mutation info in spawn reveal messages.
- The earnings formula at the end of Phase 4 is: `baseEarnings * sizeMult * baseMutationMult`.
- `rojo build` succeeds and the game runs without console errors.

---

## 3. Files to Create/Modify

Every file is listed with its full path relative to the project root.

### New Files to Create (2 files)

| # | File Path | Purpose |
|---|---|---|
| 1 | `src/server/Services/SellService.luau` | Handles selling individual brainrots and bulk sell-all operations. Calculates sell values, removes brainrots from inventory, adds money, triggers earnings recalculation. |
| 2 | `src/client/Controllers/SellUI.luau` | Renders the sell store interface with a scrolling list of owned brainrots, individual sell buttons, a Sell All button with confirmation prompt, and total sell value display. |

### Files to Modify (5 files)

| # | File Path | Change |
|---|---|---|
| 1 | `src/server/Services/BaseService.luau` | Replace the Phase 1 placeholder `handleUpgradeCapacity` with full capacity upgrade logic using exponential cost scaling. Add `MAX_CAPACITY` constant and `getUpgradeCost` function. |
| 2 | `src/server/Remotes/init.luau` | Add three new RemoteEvents: `SellBrainrot` (C->S), `SellAll` (C->S), `SellConfirmed` (S->C). |
| 3 | `src/server/init.server.luau` | Add SellService to the boot order (position 6, after FoodService). |
| 4 | `src/client/init.client.luau` | Add SellUI to the controller initialization list. |
| 5 | `src/client/Controllers/BaseUI.luau` | Add functional "Upgrade Capacity" button with cost display. Add fence Part instances forming a perimeter around the player's plot. |

---

## 4. Detailed Spec Per File

---

### 4.1 `src/server/Services/BaseService.luau` (MODIFY)

**What changes:** The Phase 1 placeholder `handleUpgradeCapacity` function is replaced with a full implementation. New constants and a public utility function are added for the capacity upgrade cost system.

**New constants:**

```luau
local MAX_CAPACITY = 30
local UPGRADE_BASE_COST = 500
local UPGRADE_COST_MULTIPLIER = 2.5
```

**Upgrade cost formula:**

```
upgradeCost(currentCapacity) = math.floor(UPGRADE_BASE_COST * UPGRADE_COST_MULTIPLIER ^ (currentCapacity - 1))
```

This produces the following cost curve:

| Current Capacity | Upgrade To | Cost |
|---|---|---|
| 1 | 2 | $500 |
| 2 | 3 | $1,250 |
| 3 | 4 | $3,125 |
| 4 | 5 | $7,812 |
| 5 | 6 | $19,531 |
| 6 | 7 | $48,828 |
| 7 | 8 | $122,070 |
| 8 | 9 | $305,175 |
| 9 | 10 | $762,939 |
| 10 | 11 | $1,907,348 |
| 11 | 12 | $4,768,371 |
| 12 | 13 | $11,920,928 |
| 13 | 14 | $29,802,322 |
| 14 | 15 | $74,505,805 |
| 15 | 16 | $186,264,514 |
| 16 | 17 | $465,661,287 |
| 17 | 18 | $1,164,153,218 |
| 18 | 19 | $2,910,383,045 |
| 19 | 20 | $7,275,957,614 |
| 20 | 21 | $18,189,894,035 |
| 21 | 22 | $45,474,735,088 |
| 22 | 23 | $113,686,837,722 |
| 23 | 24 | $284,217,094,304 |
| 24 | 25 | $710,542,735,760 |
| 25 | 26 | $1,776,356,839,400 |
| 26 | 27 | $4,440,892,098,500 |
| 27 | 28 | $11,102,230,246,251 |
| 28 | 29 | $27,755,575,615,628 |
| 29 | 30 | $69,388,939,039,072 |

**Design rationale:** The exponential curve ensures that early upgrades (1 to 5 slots) are achievable quickly with common brainrots, while later upgrades (20+ slots) require significant earnings from rare, large, and mutated brainrots. The curve aligns with the game's earnings progression -- a player with a base full of Epic+ brainrots with mutations can realistically reach the mid-to-high upgrade tiers, while maxing out at 30 requires endgame-level income.

**New public function:**

```luau
function BaseService.getUpgradeCost(player: Player): number?
```
- **Step by step:**
  1. Get data via `DataService.getData(player)`. If nil, return nil.
  2. If `data.baseCapacity >= MAX_CAPACITY`, return nil (already at max).
  3. Return `math.floor(UPGRADE_BASE_COST * UPGRADE_COST_MULTIPLIER ^ (data.baseCapacity - 1))`.

**Updated `handleUpgradeCapacity` function (replaces Phase 1 placeholder):**

```luau
local function handleUpgradeCapacity(player: Player)
```
- **Step by step:**
  1. Get data via `DataService.getData(player)`. If nil, warn `"UpgradeCapacity: No data for player"` and return.
  2. If `data.baseCapacity >= MAX_CAPACITY`, warn `"UpgradeCapacity: Already at max capacity"` and return.
  3. Calculate upgrade cost: `local cost = math.floor(UPGRADE_BASE_COST * UPGRADE_COST_MULTIPLIER ^ (data.baseCapacity - 1))`.
  4. Attempt to deduct money: `local success = DataService.subtractMoney(player, cost)`. If `success` is false, warn `"UpgradeCapacity: Insufficient money"` and return.
  5. Increment capacity: `data.baseCapacity = data.baseCapacity + 1`.
  6. Fire `CapacityUpdated` to client: `Remotes.CapacityUpdated:FireClient(player, { current = #data.ownedBrainrots, max = data.baseCapacity })`.
  7. Print `"[BaseService] Player " .. player.Name .. " upgraded capacity to " .. data.baseCapacity`.

**New public constant exposed in module return:**

Add `MAX_CAPACITY` to the module's return table so SellUI and other modules can reference it:

```luau
BaseService.MAX_CAPACITY = MAX_CAPACITY
```

---

### 4.2 `src/server/Services/SellService.luau` (CREATE)

**Purpose:** Handles all sell operations. Listens for `SellBrainrot` (sell one) and `SellAll` (sell all) remotes. Calculates sell values based on the brainrot's properties. Removes brainrots from player data, adds money, recalculates earnings, and fires confirmation remotes.

**Dependencies:**

- `src/shared/Config/Brainrots` (for `BRAINROT_BY_NAME` to look up base earnings)
- `src/shared/Config/Sizes` (for `getSizeMultiplier` to factor size into sell price)
- `src/shared/Config/Mutations` (for `getBaseMutationMultiplier` to factor base mutation into sell price)
- `src/server/Services/DataService` (for `getData`, `addMoney`)
- `src/server/Services/EarningsService` (for `recalculate`)
- `src/server/Remotes/init` (for `SellBrainrot`, `SellAll`, `SellConfirmed`, `CapacityUpdated`, `MoneyUpdated`)

**Constants:**

```luau
local SELL_SECONDS = 60  -- Sell price = 60 seconds worth of earnings
```

**Module structure:**

```luau
local SellService = {}
```

**Public API:**

```luau
function SellService.init()
```
- **Step by step:**
  1. Get the Remotes table.
  2. Connect `Remotes.SellBrainrot.OnServerEvent` to `handleSellBrainrot`.
  3. Connect `Remotes.SellAll.OnServerEvent` to `handleSellAll`.

**Internal functions:**

```luau
local function calculateSellValue(brainrot): number
```
- **Step by step:**
  1. Look up the brainrot config: `local config = Brainrots.BRAINROT_BY_NAME[brainrot.name]`.
  2. If config is nil (should not happen), warn and return 0.
  3. Get the base earnings: `local baseEarnings = config.baseEarningsPerSec`.
  4. Get the size multiplier: `local sizeMult = Sizes.getSizeMultiplier(brainrot.sizeLabel)`.
  5. Get the base mutation multiplier: `local baseMutMult = Mutations.getBaseMutationMultiplier(brainrot.baseMutation)`.
  6. Compute sell value: `local sellValue = math.floor(baseEarnings * SELL_SECONDS * sizeMult * baseMutMult)`.
  7. Return `sellValue`.

**IMPORTANT: Weather mutations are NOT included in the sell price.** Per the game design document (Section 9.2), sell price factors in base earnings, size, and base mutation only. Weather mutations are lost on sale and do not affect the sell price. This means a brainrot with a Gravitated weather mutation sells for the same price as the same brainrot without one. This is intentional -- weather mutations are temporary and luck-based, so they should not inflate sell value.

```luau
local function handleSellBrainrot(player: Player, data: {[string]: any})
```
- **Step by step:**
  1. **Validate player data:** Call `DataService.getData(player)`. If nil, warn and return.
  2. **Validate payload:** Extract `data.brainrotId`. If not a string, warn and return.
  3. **Find brainrot:** Iterate `playerData.ownedBrainrots` to find the entry where `brainrot.id == data.brainrotId`. Store both the brainrot table and its index.
  4. **Validate ownership:** If no matching brainrot found, warn `"SellBrainrot: Brainrot not found"` and return. This prevents the exploit of selling brainrots you do not own.
  5. **Calculate sell value:** Call `calculateSellValue(brainrot)`.
  6. **Remove from inventory:** `table.remove(playerData.ownedBrainrots, brainrotIndex)`.
  7. **Add money:** Call `DataService.addMoney(player, sellValue)`. (This also fires `MoneyUpdated` internally.)
  8. **Recalculate earnings:** Call `EarningsService.recalculate(player)`.
  9. **Fire capacity update:** Get current/max via `BaseService.getCapacity(player)`. Fire `Remotes.CapacityUpdated:FireClient(player, { current = current, max = max })`.
  10. **Fire sell confirmation:** Fire `Remotes.SellConfirmed:FireClient(player, { soldCount = 1, totalValue = sellValue })`.

```luau
local function handleSellAll(player: Player)
```
- **Step by step:**
  1. **Validate player data:** Call `DataService.getData(player)`. If nil, warn and return.
  2. **Check inventory:** If `#playerData.ownedBrainrots == 0`, warn `"SellAll: No brainrots to sell"` and return.
  3. **Calculate total value:** Iterate all brainrots in `playerData.ownedBrainrots`, sum `calculateSellValue(brainrot)` for each. Track `soldCount`.
  4. **Clear inventory:** Set `playerData.ownedBrainrots = {}` (replace with empty table).
  5. **Add money:** Call `DataService.addMoney(player, totalValue)`.
  6. **Recalculate earnings:** Call `EarningsService.recalculate(player)`. (Earnings will become 0 since inventory is empty.)
  7. **Fire capacity update:** Fire `Remotes.CapacityUpdated:FireClient(player, { current = 0, max = playerData.baseCapacity })`.
  8. **Fire sell confirmation:** Fire `Remotes.SellConfirmed:FireClient(player, { soldCount = soldCount, totalValue = totalValue })`.

**Module return:**

```luau
return SellService
```

---

### 4.3 `src/client/Controllers/SellUI.luau` (CREATE)

**Purpose:** Renders the sell store interface. Shows a scrolling list of all owned brainrots with their stats and sell values. Provides individual sell buttons and a Sell All button with a confirmation dialog. Opens and closes via a toggle button on the HUD.

**Dependencies:**

- `ReplicatedStorage.Remotes` (for `SellBrainrot`, `SellAll`, `SellConfirmed`, `BrainrotSpawned`, `CapacityUpdated`, `InitialData`)
- `src/shared/Config/Brainrots` (for `BRAINROT_BY_NAME` to compute sell values on client)
- `src/shared/Config/Sizes` (for `getSizeMultiplier`)
- `src/shared/Config/Mutations` (for `getBaseMutationMultiplier`)
- `src/shared/Utils` (for `formatNumber`)

**Constants:**

```luau
local SELL_SECONDS = 60  -- Must match server-side constant

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
local ownedBrainrots = {}  -- {BrainrotInstance} local copy of player's brainrots, updated via remotes
local sellStoreOpen = false
```

**UI Layout:**

```
ScreenGui "SellStoreGui"

  -- Toggle button on HUD (always visible)
  TextButton "SellToggleButton"
    Position: UDim2.new(0, 10, 0.5, 0)
    AnchorPoint: Vector2.new(0, 0.5)
    Size: UDim2.new(0, 120, 0, 40)
    Text: "Sell Store"
    TextColor3: Color3.fromRGB(255, 255, 255)
    BackgroundColor3: Color3.fromRGB(231, 76, 60)
    Font: Enum.Font.GothamBold
    TextScaled: true
    -- Add UICorner with CornerRadius 8

  -- Main sell store frame (hidden by default)
  Frame "SellStoreFrame"
    Position: UDim2.new(0.5, 0, 0.5, 0)
    AnchorPoint: Vector2.new(0.5, 0.5)
    Size: UDim2.new(0, 500, 0, 450)
    BackgroundColor3: Color3.fromRGB(30, 30, 30)
    BackgroundTransparency: 0.1
    Visible: false
    -- Add UICorner with CornerRadius 12

    -- Title bar
    TextLabel "TitleLabel"
      Position: UDim2.new(0.5, 0, 0, 10)
      AnchorPoint: Vector2.new(0.5, 0)
      Size: UDim2.new(1, -20, 0, 35)
      Text: "Sell Store"
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

    -- Scrolling frame for brainrot list
    ScrollingFrame "BrainrotList"
      Position: UDim2.new(0.5, 0, 0, 50)
      AnchorPoint: Vector2.new(0.5, 0)
      Size: UDim2.new(1, -20, 1, -120)
      CanvasSize: UDim2.new(0, 0, 0, 0)  -- auto-resized
      ScrollBarThickness: 6
      BackgroundTransparency: 1
      -- Add UIListLayout (Vertical, 5px padding)

    -- Sell All section at bottom
    Frame "SellAllFrame"
      Position: UDim2.new(0.5, 0, 1, -60)
      AnchorPoint: Vector2.new(0.5, 1)
      Size: UDim2.new(1, -20, 0, 50)
      BackgroundTransparency: 1

      TextLabel "TotalValueLabel"
        Position: UDim2.new(0, 0, 0.5, 0)
        AnchorPoint: Vector2.new(0, 0.5)
        Size: UDim2.new(0.5, 0, 1, 0)
        Text: "Total: $0"
        TextColor3: Color3.fromRGB(85, 255, 85)
        TextScaled: true
        Font: Enum.Font.GothamBold
        BackgroundTransparency: 1

      TextButton "SellAllButton"
        Position: UDim2.new(1, 0, 0.5, 0)
        AnchorPoint: Vector2.new(1, 0.5)
        Size: UDim2.new(0.45, 0, 0, 40)
        Text: "Sell All"
        TextColor3: Color3.fromRGB(255, 255, 255)
        BackgroundColor3: Color3.fromRGB(200, 50, 50)
        Font: Enum.Font.GothamBold
        TextScaled: true
        -- Add UICorner with CornerRadius 8

  -- Confirmation dialog (hidden by default, shown before Sell All)
  Frame "ConfirmDialog"
    Position: UDim2.new(0.5, 0, 0.5, 0)
    AnchorPoint: Vector2.new(0.5, 0.5)
    Size: UDim2.new(0, 350, 0, 180)
    BackgroundColor3: Color3.fromRGB(40, 40, 40)
    Visible: false
    ZIndex: 10
    -- Add UICorner with CornerRadius 12

    TextLabel "ConfirmText"
      Position: UDim2.new(0.5, 0, 0, 20)
      AnchorPoint: Vector2.new(0.5, 0)
      Size: UDim2.new(1, -20, 0, 80)
      Text: "Sell all brainrots for $X?"
      TextColor3: Color3.fromRGB(255, 255, 255)
      TextScaled: true
      TextWrapped: true
      Font: Enum.Font.GothamBold
      BackgroundTransparency: 1

    TextButton "ConfirmYes"
      Position: UDim2.new(0.3, 0, 1, -20)
      AnchorPoint: Vector2.new(0.5, 1)
      Size: UDim2.new(0, 120, 0, 40)
      Text: "Yes, Sell All"
      TextColor3: Color3.fromRGB(255, 255, 255)
      BackgroundColor3: Color3.fromRGB(200, 50, 50)
      Font: Enum.Font.GothamBold
      TextScaled: true
      -- Add UICorner with CornerRadius 8

    TextButton "ConfirmNo"
      Position: UDim2.new(0.7, 0, 1, -20)
      AnchorPoint: Vector2.new(0.5, 1)
      Size: UDim2.new(0, 120, 0, 40)
      Text: "Cancel"
      TextColor3: Color3.fromRGB(255, 255, 255)
      BackgroundColor3: Color3.fromRGB(100, 100, 100)
      Font: Enum.Font.GothamBold
      TextScaled: true
      -- Add UICorner with CornerRadius 8
```

**Each brainrot entry in the ScrollingFrame (created dynamically per brainrot):**

```
Frame "BrainrotEntry_[id]"
  Size: UDim2.new(1, 0, 0, 60)
  BackgroundColor3: Color3.fromRGB(50, 50, 50)
  -- Add UICorner with CornerRadius 8

  TextLabel "NameLabel"
    Position: UDim2.new(0, 10, 0, 5)
    Size: UDim2.new(0.55, 0, 0, 20)
    Text: "[Mutation] [Size] [Rarity] [Name]"
    TextColor3: RARITY_COLORS[rarity] or mutation color
    TextScaled: true
    Font: Enum.Font.GothamBold
    BackgroundTransparency: 1
    TextXAlignment: Enum.TextXAlignment.Left

  TextLabel "StatsLabel"
    Position: UDim2.new(0, 10, 0, 28)
    Size: UDim2.new(0.55, 0, 0, 20)
    Text: "+$X/sec | Sell: $Y"
    TextColor3: Color3.fromRGB(85, 255, 85)
    TextScaled: true
    Font: Enum.Font.Gotham
    BackgroundTransparency: 1
    TextXAlignment: Enum.TextXAlignment.Left

  TextButton "SellButton"
    Position: UDim2.new(1, -10, 0.5, 0)
    AnchorPoint: Vector2.new(1, 0.5)
    Size: UDim2.new(0, 80, 0, 35)
    Text: "Sell"
    TextColor3: Color3.fromRGB(255, 255, 255)
    BackgroundColor3: Color3.fromRGB(231, 76, 60)
    Font: Enum.Font.GothamBold
    TextScaled: true
    -- Add UICorner with CornerRadius 6
```

**Public API:**

```luau
function SellUI.Init()
```
- **Step by step:**
  1. Get `player` from `Players.LocalPlayer`.
  2. Wait for `ReplicatedStorage:WaitForChild("Remotes")`.
  3. Get references to `SellBrainrot`, `SellAll`, `SellConfirmed`, `BrainrotSpawned`, `BrainrotRanAway`, `CapacityUpdated`, `InitialData` remotes.
  4. Build the complete UI hierarchy described above. Parent `SellStoreGui` to `player.PlayerGui`.
  5. Connect `SellToggleButton.Activated`:
     a. Toggle `sellStoreOpen`.
     b. Set `SellStoreFrame.Visible = sellStoreOpen`.
     c. If opening, call `refreshBrainrotList()` to update the displayed entries.
  6. Connect `CloseButton.Activated`:
     a. Set `sellStoreOpen = false`.
     b. Set `SellStoreFrame.Visible = false`.
     c. Set `ConfirmDialog.Visible = false`.
  7. Connect `SellAllButton.Activated`:
     a. If `#ownedBrainrots == 0`, return (nothing to sell).
     b. Calculate total sell value (sum `calculateClientSellValue(brainrot)` for each).
     c. Set `ConfirmText.Text` to `"Sell all " .. #ownedBrainrots .. " brainrots for $" .. Utils.formatNumber(totalValue) .. "?"`.
     d. Set `ConfirmDialog.Visible = true`.
  8. Connect `ConfirmYes.Activated`:
     a. Fire `Remotes.SellAll:FireServer()`.
     b. Set `ConfirmDialog.Visible = false`.
  9. Connect `ConfirmNo.Activated`:
     a. Set `ConfirmDialog.Visible = false`.
  10. Connect `InitialData.OnClientEvent`:
      a. Set `ownedBrainrots = data.brainrots` (store the initial brainrot list).
      b. If the sell store is currently open, call `refreshBrainrotList()`.
  11. Connect `BrainrotSpawned.OnClientEvent`:
      a. Append `data.brainrotData` to `ownedBrainrots`.
      b. If the sell store is open, call `refreshBrainrotList()`.
  12. Connect `SellConfirmed.OnClientEvent`:
      a. Display a brief feedback message showing `"Sold " .. data.soldCount .. " brainrot(s) for $" .. Utils.formatNumber(data.totalValue)`.
      b. Remove the sold brainrot(s) from the local `ownedBrainrots` list.
      c. Call `refreshBrainrotList()`.
      d. **Note:** For individual sells, the specific brainrot is removed by id. For sell-all, the entire list is cleared.

**Internal functions:**

```luau
local function calculateClientSellValue(brainrot): number
```
- Mirrors the server-side `calculateSellValue` logic exactly.
- **Step by step:**
  1. Look up `Brainrots.BRAINROT_BY_NAME[brainrot.name]`.
  2. Get `baseEarnings`, `sizeMult` via `Sizes.getSizeMultiplier(brainrot.sizeLabel)`, `baseMutMult` via `Mutations.getBaseMutationMultiplier(brainrot.baseMutation)`.
  3. Return `math.floor(baseEarnings * SELL_SECONDS * sizeMult * baseMutMult)`.

```luau
local function refreshBrainrotList()
```
- **Step by step:**
  1. Clear all existing children of `BrainrotList` (except the UIListLayout).
  2. Initialize `totalSellValue = 0`.
  3. For each brainrot in `ownedBrainrots`:
     a. Calculate `sellValue = calculateClientSellValue(brainrot)`.
     b. Add to `totalSellValue`.
     c. Build the brainrot entry Frame with NameLabel, StatsLabel, and SellButton as described in the UI layout.
     d. **NameLabel text construction:**
        - Build parts: `{brainrot.baseMutation, brainrot.sizeLabel, brainrot.rarity, brainrot.name}` (skip nil/empty values).
        - Join with spaces.
     e. **StatsLabel text:** `"+$" .. Utils.formatNumber(brainrot.earningsPerSec) .. "/sec | Sell: $" .. Utils.formatNumber(sellValue)`.
     f. **NameLabel color:** Use mutation color if present (via `Mutations.getBaseMutationColor`), otherwise use `RARITY_COLORS[brainrot.rarity]`. Rainbow uses white.
     g. **SellButton click handler:** Fire `Remotes.SellBrainrot:FireServer({ brainrotId = brainrot.id })`.
     h. Parent the entry to `BrainrotList`.
  4. Update `TotalValueLabel.Text` to `"Total: $" .. Utils.formatNumber(totalSellValue)`.
  5. If `#ownedBrainrots == 0`, show a centered "No brainrots to sell" text inside the list.
  6. Update `BrainrotList.CanvasSize` based on the number of entries (entry height 60 + 5px padding per entry).

**Handling sell confirmation for individual sells:**

When `SellConfirmed` fires with `soldCount == 1`, the client needs to know which brainrot was sold. Since the server does not send the specific brainrot id in `SellConfirmed`, the client should track the last individual sell request. Alternatively, the client can simply re-request its brainrot list. The simplest approach: after firing `SellBrainrot`, mark the brainrot id as "pending sell." When `SellConfirmed` arrives with `soldCount == 1`, remove the pending brainrot from `ownedBrainrots` and refresh. If `soldCount > 1` (from SellAll), clear the entire list.

**Implementation approach for tracking sells:**

```luau
local pendingSellId = nil  -- tracks the last individual sell request

-- In SellButton click handler:
pendingSellId = brainrot.id
Remotes.SellBrainrot:FireServer({ brainrotId = brainrot.id })

-- In SellConfirmed handler:
if data.soldCount == 1 and pendingSellId then
    -- Remove the specific brainrot from ownedBrainrots
    for i, b in ownedBrainrots do
        if b.id == pendingSellId then
            table.remove(ownedBrainrots, i)
            break
        end
    end
    pendingSellId = nil
else
    -- Sell All: clear the entire list
    ownedBrainrots = {}
end
refreshBrainrotList()
```

---

### 4.4 `src/client/Controllers/BaseUI.luau` (MODIFY)

**What changes:** Two additions: (1) a functional "Upgrade Capacity" button that displays current capacity, max capacity, and the cost of the next upgrade; (2) a fence perimeter made of Part instances around the player's plot.

**New dependency:**

- Add `require` for `Config/Brainrots` if not already present (for computing upgrade cost display).
- No new shared module dependencies for the fence -- it uses only Roblox primitives.

**New constants:**

```luau
local MAX_CAPACITY = 30
local UPGRADE_BASE_COST = 500
local UPGRADE_COST_MULTIPLIER = 2.5

-- Fence configuration
local FENCE_COLOR = Color3.fromRGB(139, 90, 43)  -- Wooden brown
local FENCE_POST_SIZE = Vector3.new(0.5, 4, 0.5)
local FENCE_RAIL_HEIGHT = 3
local FENCE_RAIL_THICKNESS = 0.3
local PLOT_SIZE = 30  -- studs per side (square plot)
```

#### 4.4.1 Upgrade Capacity Button

Add a TextButton to the existing CapacityGui:

```
TextButton "UpgradeButton"
  Position: UDim2.new(1, -10, 0, 55)
  AnchorPoint: Vector2.new(1, 0)
  Size: UDim2.new(0, 250, 0, 40)
  Text: "Upgrade (1/30) - $500"
  TextColor3: Color3.fromRGB(255, 255, 255)
  BackgroundColor3: Color3.fromRGB(46, 204, 113)
  TextScaled: true
  Font: Enum.Font.GothamBold
  -- Add UICorner with CornerRadius 8
```

**Behavior:**

- The button text dynamically displays the current capacity and upgrade cost:
  - Format: `"Upgrade (" .. currentMax .. "/" .. MAX_CAPACITY .. ") - $" .. Utils.formatNumber(upgradeCost)`
  - Example: `"Upgrade (3/30) - $3.1K"`
- When `currentMax >= MAX_CAPACITY`, the button text changes to `"MAX CAPACITY (30/30)"` and the button is disabled (greyed out, `BackgroundColor3 = Color3.fromRGB(100, 100, 100)`, click handler returns early).
- Clicking the button fires `Remotes.UpgradeCapacity:FireServer()`.
- The button text is updated whenever `CapacityUpdated` or `InitialData` fires.

**Update function for the upgrade button:**

```luau
local function updateUpgradeButton(currentCount: number, maxCapacity: number)
    if maxCapacity >= MAX_CAPACITY then
        UpgradeButton.Text = "MAX CAPACITY (30/30)"
        UpgradeButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    else
        local cost = math.floor(UPGRADE_BASE_COST * UPGRADE_COST_MULTIPLIER ^ (maxCapacity - 1))
        UpgradeButton.Text = "Upgrade (" .. maxCapacity .. "/" .. MAX_CAPACITY .. ") - $" .. Utils.formatNumber(cost)
        UpgradeButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    end
end
```

**Connection in Init:**

```luau
-- In CapacityUpdated handler (existing):
updateUpgradeButton(data.current, data.max)

-- In InitialData handler (existing):
updateUpgradeButton(data.capacity.current, data.capacity.max)

-- UpgradeButton click:
UpgradeButton.Activated:Connect(function()
    Remotes.UpgradeCapacity:FireServer()
end)
```

#### 4.4.2 Fence Perimeter

Create a visual fence around the player's plot when the plot position is established (in the `InitialData` handler). The fence is purely cosmetic -- it does not block movement (CanCollide = false).

**Fence structure:**

The fence forms a square perimeter centered on `plotPosition`. Each side has:
- 2 corner posts (shared with adjacent sides)
- 1 horizontal rail connecting the posts at the top
- 1 horizontal rail connecting the posts at the bottom (optional, for a two-rail fence look)

**Total: 4 corner posts + 4 top rails + 4 bottom rails = 12 Parts.**

**Implementation function:**

```luau
local fenceParts = {}  -- stores all fence Part instances for cleanup

local function createFence(center: Vector3)
    -- Clear any existing fence
    for _, part in fenceParts do
        part:Destroy()
    end
    table.clear(fenceParts)

    local halfSize = PLOT_SIZE / 2

    -- Define the 4 corner positions (at ground level)
    local corners = {
        Vector3.new(center.X - halfSize, center.Y, center.Z - halfSize),
        Vector3.new(center.X + halfSize, center.Y, center.Z - halfSize),
        Vector3.new(center.X + halfSize, center.Y, center.Z + halfSize),
        Vector3.new(center.X - halfSize, center.Y, center.Z + halfSize),
    }

    -- Create corner posts
    for _, cornerPos in corners do
        local post = Instance.new("Part")
        post.Anchored = true
        post.CanCollide = false
        post.Size = FENCE_POST_SIZE
        post.Position = cornerPos + Vector3.new(0, FENCE_POST_SIZE.Y / 2, 0)
        post.Color = FENCE_COLOR
        post.Material = Enum.Material.Wood
        post.Parent = workspace
        table.insert(fenceParts, post)
    end

    -- Create rails between consecutive corners
    for i = 1, 4 do
        local startCorner = corners[i]
        local endCorner = corners[(i % 4) + 1]
        local midpoint = (startCorner + endCorner) / 2
        local length = (endCorner - startCorner).Magnitude

        -- Determine orientation (rails run along X or Z axis)
        local direction = (endCorner - startCorner).Unit

        -- Top rail
        local topRail = Instance.new("Part")
        topRail.Anchored = true
        topRail.CanCollide = false
        topRail.Material = Enum.Material.Wood
        topRail.Color = FENCE_COLOR

        -- Size: length along the rail direction, thin height and depth
        topRail.Size = Vector3.new(length, FENCE_RAIL_THICKNESS, FENCE_RAIL_THICKNESS)
        topRail.Position = midpoint + Vector3.new(0, FENCE_RAIL_HEIGHT, 0)

        -- Orient the rail to face the correct direction
        topRail.CFrame = CFrame.lookAt(
            midpoint + Vector3.new(0, FENCE_RAIL_HEIGHT, 0),
            midpoint + Vector3.new(0, FENCE_RAIL_HEIGHT, 0) + direction
        ) * CFrame.Angles(0, 0, math.rad(90))

        -- Simplified: set CFrame based on direction
        -- For axis-aligned fences, we can just set position and size directly
        if math.abs(direction.X) > 0.5 then
            -- Rail runs along X axis
            topRail.Size = Vector3.new(length, FENCE_RAIL_THICKNESS, FENCE_RAIL_THICKNESS)
        else
            -- Rail runs along Z axis
            topRail.Size = Vector3.new(FENCE_RAIL_THICKNESS, FENCE_RAIL_THICKNESS, length)
        end
        topRail.Position = midpoint + Vector3.new(0, FENCE_RAIL_HEIGHT, 0)

        topRail.Parent = workspace
        table.insert(fenceParts, topRail)

        -- Bottom rail (at half the fence height)
        local bottomRail = topRail:Clone()
        bottomRail.Position = midpoint + Vector3.new(0, FENCE_RAIL_HEIGHT / 2, 0)
        bottomRail.Parent = workspace
        table.insert(fenceParts, bottomRail)
    end
end
```

**Call site:** In the `InitialData` handler, after setting `plotPosition`:

```luau
createFence(plotPosition)
```

**Cleanup:** When the player leaves or the client script is destroyed, iterate `fenceParts` and call `:Destroy()` on each. This is handled naturally by the client script lifecycle (LocalScripts and their spawned objects are cleaned up when the player leaves).

**Fence upgrade note:** The default fence uses wooden brown parts with `Enum.Material.Wood`. In Phase 7 (Codex rewards), the fence material and color will be upgraded based on which Codex sections the player has completed (Normal = Wood, Gold = Gold metallic, Diamond = Crystal, Rainbow = cycling colors). For Phase 5, only the default wooden fence is implemented. The fence creation function is structured so that color and material can be easily parameterized in future phases.

---

### 4.5 `src/server/Remotes/init.luau` (MODIFY)

**What changes:** Add three new RemoteEvent entries to the remote creation list.

**New remotes to add:**

| Remote Name | Type | Direction | Payload | Purpose |
|---|---|---|---|---|
| `SellBrainrot` | RemoteEvent | C->S | `{ brainrotId: string }` | Client requests to sell a specific brainrot |
| `SellAll` | RemoteEvent | C->S | `{}` (no payload) | Client requests to sell all brainrots |
| `SellConfirmed` | RemoteEvent | S->C | `{ soldCount: number, totalValue: number }` | Server confirms a sell operation completed |

**Implementation:** Add `"SellBrainrot"`, `"SellAll"`, and `"SellConfirmed"` to the existing array of remote names in the module's initialization loop. No other changes.

**Updated remote name array (showing addition):**

```luau
local remoteNames = {
    -- Phase 1 remotes (existing)
    "BuyFood",
    "BrainrotSpawned",
    "BrainrotRanAway",
    "MoneyUpdated",
    "EarningsUpdated",
    "UpgradeCapacity",
    "CapacityUpdated",
    "InitialData",

    -- Phase 5 remotes (NEW)
    "SellBrainrot",
    "SellAll",
    "SellConfirmed",
}
```

---

### 4.6 `src/server/init.server.luau` (MODIFY)

**What changes:** Add SellService to the boot order. SellService is initialized at position 6, after FoodService (position 5) and before WeatherService (position 7, Phase 6).

**New lines to add (after FoodService initialization):**

```luau
local SellService = require(script.Services.SellService)
SellService.init()                                    -- 6. Connect sell remotes
```

**Updated print message:**

```luau
print("[Server] All Phase 5 services initialized.")
```

**Full updated boot sequence (showing Phase 5 state):**

```luau
-- init.server.luau
local Players = game:GetService("Players")

-- 1. Create all remotes first
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

-- Phase 5: Sell system
local SellService = require(script.Services.SellService)
SellService.init()

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

print("[Server] All Phase 5 services initialized.")
```

---

### 4.7 `src/client/init.client.luau` (MODIFY)

**What changes:** Add SellUI to the controller initialization list.

**New lines to add (after BaseUI initialization):**

```luau
local SellUI = require(script.Controllers.SellUI)
SellUI.Init()
```

**Updated print message:**

```luau
print("[Client] All Phase 5 controllers initialized.")
```

**Full updated client bootstrap:**

```luau
-- init.client.luau
local MoneyUI = require(script.Controllers.MoneyUI)
local FoodStoreUI = require(script.Controllers.FoodStoreUI)
local BaseUI = require(script.Controllers.BaseUI)
local SellUI = require(script.Controllers.SellUI)

MoneyUI.Init()
FoodStoreUI.Init()
BaseUI.Init()
SellUI.Init()

print("[Client] All Phase 5 controllers initialized.")
```

---

## 5. Module Contracts

### New Cross-Module Dependencies (Phase 5)

**SellService requires:**

| Module | Function Called | Purpose |
|---|---|---|
| `Config/Brainrots` | `BRAINROT_BY_NAME[name]` | Look up base earnings for sell value calculation |
| `Config/Sizes` | `Sizes.getSizeMultiplier(sizeLabel)` | Factor size into sell value |
| `Config/Mutations` | `Mutations.getBaseMutationMultiplier(mutation)` | Factor base mutation into sell value |
| `Services/DataService` | `DataService.getData(player)` | Read player's brainrot inventory |
| `Services/DataService` | `DataService.addMoney(player, amount)` | Add sell proceeds to player's balance |
| `Services/EarningsService` | `EarningsService.recalculate(player)` | Recompute earnings after brainrot removal |
| `Services/BaseService` | `BaseService.getCapacity(player)` | Get current/max for CapacityUpdated fire |
| `Remotes/init` | `Remotes.SellBrainrot.OnServerEvent` | Listen for individual sell requests |
| `Remotes/init` | `Remotes.SellAll.OnServerEvent` | Listen for sell-all requests |
| `Remotes/init` | `Remotes.SellConfirmed:FireClient()` | Confirm sell operation to client |
| `Remotes/init` | `Remotes.CapacityUpdated:FireClient()` | Update capacity display after sell |

**BaseService changes (upgrade system):**

| Module | Function Called | Purpose |
|---|---|---|
| `Services/DataService` | `DataService.getData(player)` | Read current capacity |
| `Services/DataService` | `DataService.subtractMoney(player, cost)` | Deduct upgrade cost |
| `Remotes/init` | `Remotes.CapacityUpdated:FireClient()` | Notify client of new capacity |

**SellUI requires:**

| Module | Function Called | Purpose |
|---|---|---|
| `Config/Brainrots` | `BRAINROT_BY_NAME[name]` | Client-side sell value calculation |
| `Config/Sizes` | `Sizes.getSizeMultiplier(sizeLabel)` | Client-side sell value calculation |
| `Config/Mutations` | `Mutations.getBaseMutationMultiplier(mutation)` | Client-side sell value calculation |
| `Config/Mutations` | `Mutations.getBaseMutationColor(mutation)` | Color brainrot names by mutation |
| `shared/Utils` | `Utils.formatNumber(n)` | Format money amounts for display |
| `Remotes` (via ReplicatedStorage) | `SellBrainrot:FireServer()` | Send sell request |
| `Remotes` (via ReplicatedStorage) | `SellAll:FireServer()` | Send sell-all request |
| `Remotes` (via ReplicatedStorage) | `SellConfirmed.OnClientEvent` | Receive sell confirmation |
| `Remotes` (via ReplicatedStorage) | `BrainrotSpawned.OnClientEvent` | Track new brainrots in local list |
| `Remotes` (via ReplicatedStorage) | `InitialData.OnClientEvent` | Initialize local brainrot list |

**BaseUI changes (upgrade button + fence):**

| Module | Function Called | Purpose |
|---|---|---|
| `shared/Utils` | `Utils.formatNumber(n)` | Format upgrade cost for button text |
| `Remotes` (via ReplicatedStorage) | `UpgradeCapacity:FireServer()` | Fire upgrade request |
| `Remotes` (via ReplicatedStorage) | `CapacityUpdated.OnClientEvent` | Update button text after upgrade |

### Existing Contracts (Unchanged)

- FoodService still calls `DataService.getData()`, `DataService.subtractMoney()`, `BaseService.canAddBrainrot()`, `BaseService.getCapacity()`, `EarningsService.recalculate()`, and fires `BrainrotSpawned`, `BrainrotRanAway`, `CapacityUpdated` remotes.
- EarningsService still runs the 1-second loop and calls `DataService.addMoney()`.
- MoneyUI still listens for `MoneyUpdated` and `EarningsUpdated`.
- The `BrainrotSpawned` remote payload is unchanged (full `BrainrotInstance` table).
- No changes to `Config/Brainrots`, `Config/Foods`, `Config/Mutations`, `Config/Sizes`, `Types.luau`, or `Utils.luau`.

---

## 6. Agent Task Breakdown

Tasks are organized into steps. Steps must be completed in order. Tasks within a step can be done in parallel.

### Step 1 (Parallel -- no inter-dependencies)

| Task | File | Action | Est. Lines Changed |
|---|---|---|---|
| 1.1 | `src/server/Remotes/init.luau` | MODIFY | ~5 |
| 1.2 | `src/server/Services/BaseService.luau` | MODIFY | ~40 |

These two modifications are independent. Remotes adds three new remote names to the array. BaseService replaces the placeholder upgrade handler with the full implementation.

- **1.1 Remotes:** Add `"SellBrainrot"`, `"SellAll"`, `"SellConfirmed"` to the remote names array.
- **1.2 BaseService:** Add `MAX_CAPACITY`, `UPGRADE_BASE_COST`, `UPGRADE_COST_MULTIPLIER` constants. Add `getUpgradeCost()` public function. Replace `handleUpgradeCapacity` placeholder with full validation, money deduction, and capacity increment logic.

### Step 2 (Sequential -- depends on Step 1)

| Task | File | Action | Est. Lines |
|---|---|---|---|
| 2.1 | `src/server/Services/SellService.luau` | CREATE | ~100 |

Depends on Remotes (for SellBrainrot, SellAll, SellConfirmed remote references) and BaseService (for getCapacity). Create the complete SellService module with `init`, `calculateSellValue`, `handleSellBrainrot`, and `handleSellAll`.

### Step 3 (Parallel -- depends on Steps 1-2)

| Task | File | Action | Est. Lines Changed |
|---|---|---|---|
| 3.1 | `src/client/Controllers/SellUI.luau` | CREATE | ~250 |
| 3.2 | `src/client/Controllers/BaseUI.luau` | MODIFY | ~120 |

These two client-side tasks are independent of each other.

- **3.1 SellUI:** Create the complete sell store interface with toggle button, scrolling brainrot list, individual sell buttons, Sell All with confirmation dialog, and all remote connections.
- **3.2 BaseUI:** Add the Upgrade Capacity button with dynamic text and cost display. Add the fence perimeter creation function and call it from the InitialData handler.

### Step 4 (Sequential -- depends on all above)

| Task | File | Action | Est. Lines Changed |
|---|---|---|---|
| 4.1 | `src/server/init.server.luau` | MODIFY | ~5 |
| 4.2 | `src/client/init.client.luau` | MODIFY | ~5 |

Add SellService to server boot order and SellUI to client controller initialization.

### Task Dependency Diagram

```
Step 1 (parallel):
  1.1 Remotes/init.luau ------+
  1.2 BaseService.luau -------+
         |
         v
Step 2 (sequential):
  2.1 SellService.luau -------+
         |
         v
Step 3 (parallel):
  3.1 SellUI.luau ------------+
  3.2 BaseUI.luau ------------+
         |
         v
Step 4 (sequential):
  4.1 init.server.luau -------+
  4.2 init.client.luau -------+
```

### Total: 2 new files, 5 modified files, ~525 estimated lines of new/changed Luau code.

---

## 7. Data Structures

### 7.1 Upgrade Cost Table / Formula

**Formula:**

```
upgradeCost(n) = floor(500 * 2.5^(n - 1))
```

Where `n` is the current capacity (before upgrade). The player pays this amount to go from `n` slots to `n + 1` slots.

**Complete cost table:**

| From | To | Cost | Cumulative Cost |
|---|---|---|---|
| 1 | 2 | $500 | $500 |
| 2 | 3 | $1,250 | $1,750 |
| 3 | 4 | $3,125 | $4,875 |
| 4 | 5 | $7,812 | $12,687 |
| 5 | 6 | $19,531 | $32,218 |
| 6 | 7 | $48,828 | $81,046 |
| 7 | 8 | $122,070 | $203,116 |
| 8 | 9 | $305,175 | $508,291 |
| 9 | 10 | $762,939 | $1,271,230 |
| 10 | 11 | $1,907,348 | $3,178,578 |
| 11 | 12 | $4,768,371 | $7,946,949 |
| 12 | 13 | $11,920,928 | $19,867,877 |
| 13 | 14 | $29,802,322 | $49,670,199 |
| 14 | 15 | $74,505,805 | $124,176,004 |
| 15 | 16 | $186,264,514 | $310,440,518 |
| 16 | 17 | $465,661,287 | $776,101,805 |
| 17 | 18 | $1,164,153,218 | $1,940,255,023 |
| 18 | 19 | $2,910,383,045 | $4,850,638,068 |
| 19 | 20 | $7,275,957,614 | $12,126,595,682 |
| 20 | 21 | $18,189,894,035 | $30,316,489,717 |
| 21 | 22 | $45,474,735,088 | $75,791,224,805 |
| 22 | 23 | $113,686,837,722 | $189,478,062,527 |
| 23 | 24 | $284,217,094,304 | $473,695,156,831 |
| 24 | 25 | $710,542,735,760 | $1,184,237,892,591 |
| 25 | 26 | $1,776,356,839,400 | $2,960,594,731,991 |
| 26 | 27 | $4,440,892,098,500 | $7,401,486,830,491 |
| 27 | 28 | $11,102,230,246,251 | $18,503,717,076,742 |
| 28 | 29 | $27,755,575,615,628 | $46,259,292,692,370 |
| 29 | 30 | $69,388,939,039,072 | $115,648,231,731,442 |

### 7.2 Sell Value Calculation

**Formula:**

```
sellValue = floor(baseEarningsPerSec * 60 * sizeMult * baseMutationMult)
```

**Key rule:** Weather mutations are NOT included in the sell price. This is by design (Game Design Section 9.2). Weather mutations are temporary and luck-based -- including them would create perverse incentives to sell during weather events rather than enjoying the earnings boost.

**Sell value examples:**

| Brainrot | Rarity | Base $/sec | Size | Size Mult | Mutation | Mut Mult | Sell Value |
|---|---|---|---|---|---|---|---|
| Burbaloni Lulilolli | Common | $5 | Small | 0.75x | None | 1.0x | $225 |
| Burbaloni Lulilolli | Common | $5 | Medium | 1.0x | Gold | 1.5x | $450 |
| Hipocactus | Common | $5 | Massive | 3.0x | Rainbow | 5.0x | $4,500 |
| Tralalero Tralala | Epic | $1,250 | Medium | 1.0x | None | 1.0x | $75,000 |
| Tralalero Tralala | Epic | $1,250 | Medium | 1.0x | Gold | 1.5x | $112,500 |
| Tralalero Tralala | Epic | $1,250 | Large | 1.75x | Diamond | 2.5x | $328,125 |
| Bombombini Gusini | Legendary | $10,000 | Massive | 3.0x | Rainbow | 5.0x | $9,000,000 |
| La Vaca Saturno Saturnita | Unknown | $50,000,000 | Massive | 3.0x | Rainbow | 5.0x | $45,000,000,000 |

### 7.3 Remote Payload Shapes (Phase 5 additions)

```luau
-- SellBrainrot (C->S)
{ brainrotId = "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6" }

-- SellAll (C->S)
{}  -- no payload

-- SellConfirmed (S->C)
{ soldCount = 1, totalValue = 75000 }
-- or for sell all:
{ soldCount = 5, totalValue = 350000 }
```

### 7.4 No New PlayerData Fields

Phase 5 does not add any new fields to the `PlayerData` schema. All required fields already exist from Phase 1:
- `money` (current balance -- updated by sell proceeds)
- `ownedBrainrots` (brainrot array -- entries removed on sell)
- `baseCapacity` (max slots -- incremented on upgrade)
- `totalMoneyEarned` (lifetime money -- updated via `DataService.addMoney()`)

---

## 8. Testing Criteria

After all files are written, verify the following. Every test must pass.

### Build Test

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T1 | `rojo build` succeeds | Run `rojo build -o "collect-brainrots.rbxlx"` | Exits with code 0, no errors. |

### Capacity Upgrade Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T2 | Upgrade button visible with correct cost | Open game, look at top-right area of screen | Button reads "Upgrade (1/30) - $500". |
| T3 | Clicking upgrade deducts money and increases capacity | Click the upgrade button when player has >= $500 | Money decreases by $500. Capacity display changes from "X/1 Brainrots" to "X/2 Brainrots". Button text updates to show new cost ($1,250). |
| T4 | Cost scales with each upgrade | Upgrade capacity from 1 to 5, note costs each time | Costs are $500, $1,250, $3,125, $7,812 (matching the formula). |
| T5 | Cannot upgrade past 30 | Set capacity to 30 (via repeated upgrades or test data) | Button shows "MAX CAPACITY (30/30)" and is greyed out. Clicking does nothing. |
| T6 | Cannot upgrade with insufficient money | Attempt upgrade when player has less money than the cost | Nothing happens. Money and capacity remain unchanged. No errors in console. |
| T7 | Upgrade persists across sessions | Upgrade capacity, leave, rejoin | Capacity is still at the upgraded level. Upgrade button shows correct next cost. |

### Sell Store Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T8 | Sell store toggle button visible | Open game | Red "Sell Store" button visible on the left side of the screen. |
| T9 | Clicking toggle opens/closes sell store | Click the Sell Store button | Store frame appears with brainrot list. Click again or click X to close. |
| T10 | Sell store shows all owned brainrots | Have 3+ brainrots, open sell store | All brainrots appear in the scrolling list with correct names, rarities, sizes, mutations, earnings, and sell values. |
| T11 | Sell values are correct | Compare displayed sell value to manual calculation | Sell value = `floor(baseEarnings * 60 * sizeMult * baseMutMult)`. |
| T12 | Selling individual brainrot works | Click "Sell" next to a brainrot | Brainrot is removed from list. Money increases by the sell value. Earnings/sec decreases. Capacity current count decreases by 1. |
| T13 | Sell All button shows total value | Open sell store with multiple brainrots | "Total: $X" label shows the sum of all individual sell values. |
| T14 | Sell All shows confirmation prompt | Click "Sell All" | Confirmation dialog appears: "Sell all N brainrots for $X?" with Yes and Cancel buttons. |
| T15 | Confirming Sell All clears inventory | Click "Yes, Sell All" in confirmation dialog | All brainrots removed. Money increases by total sell value. Earnings/sec drops to $0/sec. Capacity shows "0/N Brainrots". |
| T16 | Canceling Sell All does nothing | Click "Cancel" in confirmation dialog | Dialog closes. No brainrots sold. Money unchanged. |
| T17 | Cannot sell with empty inventory | Open sell store with no brainrots | "No brainrots to sell" message. Sell All button does nothing. |
| T18 | After selling, can buy more food | Sell a brainrot to free a slot, then buy food | Food purchase succeeds (assuming capacity is now available and money is sufficient). Brainrot can spawn into the freed slot. |

### Sell Value Accuracy Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T19 | Common brainrot sell value | Sell a Medium/None Common brainrot | Sell value = $5 * 60 * 1.0 * 1.0 = $300. |
| T20 | Mutated brainrot sell value | Sell a Medium/Gold Epic brainrot | Sell value = $1,250 * 60 * 1.0 * 1.5 = $112,500. |
| T21 | Sized brainrot sell value | Sell a Large/None Common brainrot | Sell value = $5 * 60 * 1.75 * 1.0 = $525. |
| T22 | Weather mutation NOT in sell price | Get a weather-mutated brainrot (Phase 6+), check sell value | Sell value is the same regardless of weather mutation. Only base mutation and size affect price. |

### Fence Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T23 | Fence appears around plot | Join game, look at the player's base area | Wooden fence perimeter visible around the plot. 4 corner posts and horizontal rails. |
| T24 | Fence does not block movement | Walk through the fence | Player can walk through (CanCollide = false). |
| T25 | Fence uses correct material | Inspect fence parts | Material is Wood, color is brown (#8B5A2B / RGB 139, 90, 43). |

### Security Tests

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T26 | Cannot sell brainrots you do not own | Fire SellBrainrot with a fake/invalid brainrotId | Server warns and rejects. No money added, no brainrot removed. |
| T27 | Cannot upgrade with insufficient money | Fire UpgradeCapacity when money < cost | Server warns and rejects. Capacity unchanged. |
| T28 | Cannot exploit sell-all on empty inventory | Fire SellAll with no brainrots | Server warns and returns. No money added. |

### Console Cleanliness Test

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T29 | No errors in console | Check Studio Output for red error text | Zero errors. Warnings from placeholder features (Phase 6+) are acceptable. |

---

## 9. Acceptance Criteria

All of the following must be true before Phase 5 is considered complete:

| # | Criterion | How to Verify |
|---|---|---|
| 1 | `rojo build` succeeds without errors | Run `rojo build -o "collect-brainrots.rbxlx"` |
| 2 | `SellService.luau` exists with correct sell logic | Read the file and verify `calculateSellValue`, `handleSellBrainrot`, `handleSellAll` |
| 3 | `SellUI.luau` exists with complete sell store interface | Read the file and verify toggle, scrolling list, individual sell, Sell All, confirmation |
| 4 | Capacity upgrade system creates meaningful progression | Costs scale exponentially from $500 to ~$69 trillion for the final upgrade |
| 5 | Upgrade button displays correct capacity and cost at all levels | Visual check at various capacity levels |
| 6 | Upgrade button shows "MAX CAPACITY" at 30 | Visual check after reaching max |
| 7 | Sell prices feel fair (60 seconds of base earnings) | Verify sell values match the formula for several brainrots of different rarities/sizes/mutations |
| 8 | Weather mutations do NOT affect sell price | Compare sell value of identical brainrots with and without weather mutation |
| 9 | Sell All requires confirmation before executing | Click Sell All and verify dialog appears |
| 10 | Fence visuals look clean around the plot | Visual check -- 4 corner posts, horizontal rails, wooden material |
| 11 | No exploits: cannot sell brainrots you do not own | Attempt to sell with fake brainrotId from client |
| 12 | No exploits: cannot upgrade with insufficient money | Attempt to upgrade when broke |
| 13 | After selling, freed capacity allows buying more food | Sell brainrot, verify food purchase works to fill the freed slot |
| 14 | All Phase 4 functionality still works (mutations, size, earnings) | Regression test: verify mutations still appear, earnings still calculate correctly |
| 15 | No errors in Studio Output console | Check for red error text during gameplay |

---

## Appendix A: Sell Value vs. Earnings Breakeven Analysis

The sell price formula (`60 * earningsPerSec`) means a brainrot's sell value equals exactly 60 seconds (1 minute) of its earnings. This has the following economic implications:

- **Breakeven time:** A brainrot "pays for itself" in sell value after 1 minute. After that, keeping it is pure profit.
- **This makes selling a deliberate choice:** Players sell when they need cash now (e.g., to upgrade capacity or buy better food), accepting the loss of future passive income.
- **Sell-and-rebuy loop:** A player who sells a brainrot and immediately buys food to replace it is gambling that the replacement will earn more. This creates interesting decision-making.

**Example scenario:** A player has 5 Common brainrots earning $5/sec each ($25/sec total). They could sell all 5 for $300 each ($1,500 total) and use the money to buy better food, hoping for rarer brainrots that earn more.

## Appendix B: Upgrade Cost Formula Derivation

The upgrade cost formula `500 * 2.5^(n-1)` was chosen for the following reasons:

1. **Base cost of $500:** Achievable after ~100 seconds with a single Common brainrot ($5/sec). This means a new player can upgrade from 1 to 2 slots within their first few minutes.

2. **Multiplier of 2.5x:** Each upgrade costs 2.5x the previous one. This creates a steep but not insurmountable curve. The multiplier was chosen so that:
   - Slots 1-5 ($500 to $7,812) are achievable with Common brainrots.
   - Slots 5-10 ($19,531 to $762,939) require Rare or Epic brainrots.
   - Slots 10-15 ($1.9M to $74.5M) require Epic or Legendary brainrots.
   - Slots 15-20 ($186M to $7.3B) require Legendary or Mythic brainrots with mutations.
   - Slots 20-25 ($18.2B to $710B) require Mythic or higher brainrots with size/mutation rolls.
   - Slots 25-30 ($1.8T to $69.4T) require endgame brainrots (Secret/Unknown) with favorable mutations.

3. **`math.floor()` rounding:** Ensures costs are always whole numbers, which looks cleaner in the UI and avoids floating-point display issues.

---

*End of Phase 5 Base Management and Sell Store specification.*
