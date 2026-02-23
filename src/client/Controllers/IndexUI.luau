local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Brainrots = require(ReplicatedStorage.Shared.Config.Brainrots)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TOTAL_BRAINROTS = 25
local CELL_SIZE = UDim2.new(0, 120, 0, 140)
local CELL_PADDING = 8

local SECTION_TABS = { "Normal", "Gold", "Diamond", "Rainbow" }

local SECTION_KEYS = {
	Normal = "normal",
	Gold = "gold",
	Diamond = "diamond",
	Rainbow = "rainbow",
}

local SECTION_COLORS = {
	Normal = Color3.fromRGB(200, 200, 200),
	Gold = Color3.fromRGB(255, 215, 0),
	Diamond = Color3.fromRGB(185, 242, 255),
	Rainbow = Color3.fromRGB(255, 100, 200),
}

local FENCE_REWARD_NAMES = {
	normal = "Default Fence",
	gold = "Gold Fence",
	diamond = "Diamond Fence",
	rainbow = "Rainbow Fence",
}

local RARITY_COLORS = {
	Common = Color3.fromRGB(170, 170, 170),
	Rare = Color3.fromRGB(85, 170, 255),
	Epic = Color3.fromRGB(170, 85, 255),
	Legendary = Color3.fromRGB(255, 170, 0),
	Mythic = Color3.fromRGB(255, 85, 85),
	Goldy = Color3.fromRGB(255, 215, 0),
	Secret = Color3.fromRGB(0, 0, 0),
	Unknown = Color3.fromRGB(255, 0, 255),
}

local UNDISCOVERED_COLOR = Color3.fromRGB(40, 40, 40)
local SILHOUETTE_COLOR = Color3.fromRGB(20, 20, 20)

local indexData = { normal = {}, gold = {}, diamond = {}, rainbow = {} }
local unlockedFences = {}
local allBrainrotNames = {}
local currentTab = "Normal"
local codexOpen = false

-- UI references
local codexFrame = nil
local gridFrame = nil
local progressFill = nil
local progressText = nil
local completeBadge = nil
local tabButtons = {}
local brainrotCells = {}

local IndexUI = {}

local function updateTabVisuals()
	for tabName, button in tabButtons do
		if tabName == currentTab then
			button.BackgroundColor3 = SECTION_COLORS[tabName]
			button.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			button.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
			button.TextColor3 = Color3.fromRGB(150, 150, 150)
		end
	end
end

local function refreshGrid()
	local sectionKey = SECTION_KEYS[currentTab]
	local discovered = indexData[sectionKey] or {}

	local discoveredSet = {}
	for _, name in discovered do
		discoveredSet[name] = true
	end

	-- Update progress bar
	if progressFill then
		progressFill.Size = UDim2.new(#discovered / TOTAL_BRAINROTS, 0, 1, 0)
		progressFill.BackgroundColor3 = SECTION_COLORS[currentTab]
	end

	if progressText then
		progressText.Text = #discovered .. "/" .. TOTAL_BRAINROTS .. " Discovered"
	end

	-- Complete badge
	if completeBadge then
		if #discovered >= TOTAL_BRAINROTS then
			completeBadge.Visible = true
			completeBadge.Text = "COMPLETE! Reward: " .. (FENCE_REWARD_NAMES[sectionKey] or "")
		else
			completeBadge.Visible = false
		end
	end

	-- Update each cell
	for _, brainrotName in allBrainrotNames do
		local cell = brainrotCells[brainrotName]
		if not cell then
			continue
		end

		local brainrotConfig = Brainrots.BRAINROT_BY_NAME[brainrotName]
		local isDiscovered = discoveredSet[brainrotName] == true
		local rarityColor = RARITY_COLORS[brainrotConfig.rarity] or Color3.fromRGB(170, 170, 170)

		local iconFrame = cell:FindFirstChild("IconFrame")
		local silhouetteText = iconFrame and iconFrame:FindFirstChild("SilhouetteText")
		local discoveredMark = iconFrame and iconFrame:FindFirstChild("DiscoveredMark")
		local nameLabel = cell:FindFirstChild("NameLabel")
		local rarityLabel = cell:FindFirstChild("RarityLabel")

		if isDiscovered then
			cell.BackgroundColor3 = rarityColor
			cell.BackgroundTransparency = 0.3

			if iconFrame then
				iconFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
				iconFrame.BackgroundTransparency = 0.5
			end
			if silhouetteText then
				silhouetteText.Visible = false
			end
			if discoveredMark then
				discoveredMark.Visible = true
			end
			if nameLabel then
				nameLabel.Text = brainrotName
				nameLabel.TextColor3 = rarityColor
			end
			if rarityLabel then
				rarityLabel.Text = brainrotConfig.rarity
				rarityLabel.TextColor3 = rarityColor
			end
		else
			cell.BackgroundColor3 = UNDISCOVERED_COLOR
			cell.BackgroundTransparency = 0

			if iconFrame then
				iconFrame.BackgroundColor3 = SILHOUETTE_COLOR
				iconFrame.BackgroundTransparency = 0
			end
			if silhouetteText then
				silhouetteText.Visible = true
			end
			if discoveredMark then
				discoveredMark.Visible = false
			end
			if nameLabel then
				nameLabel.Text = "???"
				nameLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
			end
			if rarityLabel then
				rarityLabel.Text = ""
			end
		end
	end
end

local function onIndexUpdated(data)
	if not data then
		return
	end

	-- Full index payload from RequestIndex
	if data.index then
		indexData = data.index
		if data.unlockedFences then
			unlockedFences = data.unlockedFences
		end
		refreshGrid()
		return
	end

	-- Incremental update from registerDiscovery
	if data.section and data.brainrotName then
		if not indexData[data.section] then
			indexData[data.section] = {}
		end

		local alreadyExists = false
		for _, name in indexData[data.section] do
			if name == data.brainrotName then
				alreadyExists = true
				break
			end
		end

		if not alreadyExists then
			table.insert(indexData[data.section], data.brainrotName)
		end

		refreshGrid()
	end

	-- Section completion notification
	if data.sectionComplete and data.fenceReward then
		local alreadyHas = false
		for _, fence in unlockedFences do
			if fence == data.fenceReward then
				alreadyHas = true
				break
			end
		end
		if not alreadyHas then
			table.insert(unlockedFences, data.fenceReward)
		end
	end
end

local function createBrainrotCell(brainrotName: string, layoutOrder: number, parent: Instance)
	local brainrotConfig = Brainrots.BRAINROT_BY_NAME[brainrotName]
	local rarityColor = RARITY_COLORS[brainrotConfig.rarity] or Color3.fromRGB(170, 170, 170)

	local cell = Instance.new("Frame")
	cell.Name = "Cell_" .. brainrotName
	cell.LayoutOrder = layoutOrder
	cell.BackgroundColor3 = UNDISCOVERED_COLOR
	cell.BackgroundTransparency = 0
	cell.Parent = parent

	local cellCorner = Instance.new("UICorner")
	cellCorner.CornerRadius = UDim.new(0, 8)
	cellCorner.Parent = cell

	-- Icon frame
	local iconFrame = Instance.new("Frame")
	iconFrame.Name = "IconFrame"
	iconFrame.Position = UDim2.new(0.5, 0, 0, 5)
	iconFrame.AnchorPoint = Vector2.new(0.5, 0)
	iconFrame.Size = UDim2.new(0.8, 0, 0, 80)
	iconFrame.BackgroundColor3 = SILHOUETTE_COLOR
	iconFrame.BackgroundTransparency = 0
	iconFrame.Parent = cell

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 6)
	iconCorner.Parent = iconFrame

	local silhouetteText = Instance.new("TextLabel")
	silhouetteText.Name = "SilhouetteText"
	silhouetteText.Size = UDim2.new(1, 0, 1, 0)
	silhouetteText.Text = "???"
	silhouetteText.TextColor3 = Color3.fromRGB(60, 60, 60)
	silhouetteText.TextScaled = true
	silhouetteText.Font = Enum.Font.GothamBold
	silhouetteText.BackgroundTransparency = 1
	silhouetteText.Parent = iconFrame

	local discoveredMark = Instance.new("TextLabel")
	discoveredMark.Name = "DiscoveredMark"
	discoveredMark.Size = UDim2.new(1, 0, 1, 0)
	discoveredMark.Text = "\226\156\147"
	discoveredMark.TextColor3 = Color3.fromRGB(85, 255, 85)
	discoveredMark.TextScaled = true
	discoveredMark.Font = Enum.Font.GothamBold
	discoveredMark.BackgroundTransparency = 1
	discoveredMark.Visible = false
	discoveredMark.Parent = iconFrame

	-- Name label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Position = UDim2.new(0.5, 0, 1, -35)
	nameLabel.AnchorPoint = Vector2.new(0.5, 0)
	nameLabel.Size = UDim2.new(1, -10, 0, 16)
	nameLabel.Text = "???"
	nameLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextWrapped = true
	nameLabel.Parent = cell

	-- Rarity label
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Position = UDim2.new(0.5, 0, 1, -18)
	rarityLabel.AnchorPoint = Vector2.new(0.5, 0)
	rarityLabel.Size = UDim2.new(1, -10, 0, 14)
	rarityLabel.Text = ""
	rarityLabel.TextColor3 = rarityColor
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.Gotham
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Parent = cell

	brainrotCells[brainrotName] = cell
end

function IndexUI.Init()
	-- Build allBrainrotNames
	for _, brainrot in Brainrots.BRAINROTS do
		table.insert(allBrainrotNames, brainrot.name)
	end

	-- Wait for remotes
	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
	local RequestIndex = remotesFolder:WaitForChild("RequestIndex")
	local IndexUpdated = remotesFolder:WaitForChild("IndexUpdated")
	local InitialData = remotesFolder:WaitForChild("InitialData")

	-- ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "IndexGui"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 8
	screenGui.Parent = playerGui

	-- Toggle button
	local toggleButton = Instance.new("TextButton")
	toggleButton.Name = "CodexToggleButton"
	toggleButton.Position = UDim2.new(0, 10, 0, 60)
	toggleButton.Size = UDim2.new(0, 120, 0, 40)
	toggleButton.Text = "Codex"
	toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleButton.BackgroundColor3 = Color3.fromRGB(100, 60, 180)
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.TextScaled = true
	toggleButton.Parent = screenGui

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 8)
	toggleCorner.Parent = toggleButton

	-- Codex frame
	codexFrame = Instance.new("Frame")
	codexFrame.Name = "CodexFrame"
	codexFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	codexFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	codexFrame.Size = UDim2.new(0.85, 0, 0.85, 0)
	codexFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	codexFrame.BackgroundTransparency = 0.05
	codexFrame.Visible = false
	codexFrame.ZIndex = 10
	codexFrame.Parent = screenGui

	local codexCorner = Instance.new("UICorner")
	codexCorner.CornerRadius = UDim.new(0, 16)
	codexCorner.Parent = codexFrame

	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Position = UDim2.new(0.5, 0, 0, 15)
	titleLabel.AnchorPoint = Vector2.new(0.5, 0)
	titleLabel.Size = UDim2.new(0.5, 0, 0, 40)
	titleLabel.Text = "Brainrot Codex"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.BackgroundTransparency = 1
	titleLabel.ZIndex = 10
	titleLabel.Parent = codexFrame

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Position = UDim2.new(1, -15, 0, 15)
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Size = UDim2.new(0, 35, 0, 35)
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.Font = Enum.Font.GothamBold
	closeButton.ZIndex = 11
	closeButton.Parent = codexFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = closeButton

	-- Tab bar
	local tabBar = Instance.new("Frame")
	tabBar.Name = "TabBar"
	tabBar.Position = UDim2.new(0.5, 0, 0, 60)
	tabBar.AnchorPoint = Vector2.new(0.5, 0)
	tabBar.Size = UDim2.new(0.8, 0, 0, 40)
	tabBar.BackgroundTransparency = 1
	tabBar.ZIndex = 10
	tabBar.Parent = codexFrame

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tabLayout.Padding = UDim.new(0, 10)
	tabLayout.Parent = tabBar

	for _, tabName in SECTION_TABS do
		local tabButton = Instance.new("TextButton")
		tabButton.Name = "Tab_" .. tabName
		tabButton.Size = UDim2.new(0, 130, 1, 0)
		tabButton.Text = tabName
		tabButton.TextScaled = true
		tabButton.Font = Enum.Font.GothamBold
		tabButton.ZIndex = 10
		tabButton.Parent = tabBar

		local tabCorner = Instance.new("UICorner")
		tabCorner.CornerRadius = UDim.new(0, 8)
		tabCorner.Parent = tabButton

		tabButtons[tabName] = tabButton

		tabButton.Activated:Connect(function()
			currentTab = tabName
			updateTabVisuals()
			refreshGrid()
		end)
	end

	-- Progress frame
	local progressFrame = Instance.new("Frame")
	progressFrame.Name = "ProgressFrame"
	progressFrame.Position = UDim2.new(0.5, 0, 0, 110)
	progressFrame.AnchorPoint = Vector2.new(0.5, 0)
	progressFrame.Size = UDim2.new(0.7, 0, 0, 30)
	progressFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	progressFrame.ZIndex = 10
	progressFrame.Parent = codexFrame

	local progressFrameCorner = Instance.new("UICorner")
	progressFrameCorner.CornerRadius = UDim.new(0, 6)
	progressFrameCorner.Parent = progressFrame

	progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Position = UDim2.new(0, 0, 0, 0)
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	progressFill.BackgroundColor3 = SECTION_COLORS.Normal
	progressFill.ZIndex = 11
	progressFill.Parent = progressFrame

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 6)
	fillCorner.Parent = progressFill

	progressText = Instance.new("TextLabel")
	progressText.Name = "ProgressText"
	progressText.Position = UDim2.new(0.5, 0, 0.5, 0)
	progressText.AnchorPoint = Vector2.new(0.5, 0.5)
	progressText.Size = UDim2.new(1, 0, 1, 0)
	progressText.BackgroundTransparency = 1
	progressText.Text = "0/" .. TOTAL_BRAINROTS .. " Discovered"
	progressText.TextColor3 = Color3.fromRGB(255, 255, 255)
	progressText.TextScaled = true
	progressText.Font = Enum.Font.GothamBold
	progressText.ZIndex = 12
	progressText.Parent = progressFrame

	-- Complete badge
	completeBadge = Instance.new("TextLabel")
	completeBadge.Name = "CompleteBadge"
	completeBadge.Position = UDim2.new(0.5, 0, 0, 145)
	completeBadge.AnchorPoint = Vector2.new(0.5, 0)
	completeBadge.Size = UDim2.new(0.4, 0, 0, 30)
	completeBadge.BackgroundTransparency = 1
	completeBadge.Text = ""
	completeBadge.TextColor3 = Color3.fromRGB(85, 255, 85)
	completeBadge.TextScaled = true
	completeBadge.Font = Enum.Font.GothamBold
	completeBadge.Visible = false
	completeBadge.ZIndex = 10
	completeBadge.Parent = codexFrame

	-- Brainrot grid
	gridFrame = Instance.new("ScrollingFrame")
	gridFrame.Name = "BrainrotGrid"
	gridFrame.Position = UDim2.new(0.5, 0, 0, 180)
	gridFrame.AnchorPoint = Vector2.new(0.5, 0)
	gridFrame.Size = UDim2.new(0.9, 0, 1, -200)
	gridFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	gridFrame.ScrollBarThickness = 6
	gridFrame.BackgroundTransparency = 1
	gridFrame.ZIndex = 10
	gridFrame.Parent = codexFrame

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = CELL_SIZE
	gridLayout.CellPadding = UDim2.new(0, CELL_PADDING, 0, CELL_PADDING)
	gridLayout.FillDirection = Enum.FillDirection.Horizontal
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = gridFrame

	-- Auto-size canvas
	gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		gridFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + CELL_PADDING)
	end)

	-- Create all 25 cells
	for i, brainrotName in allBrainrotNames do
		createBrainrotCell(brainrotName, i, gridFrame)
	end

	-- Toggle codex
	toggleButton.Activated:Connect(function()
		codexOpen = not codexOpen
		codexFrame.Visible = codexOpen
		if codexOpen then
			RequestIndex:FireServer()
		end
	end)

	closeButton.Activated:Connect(function()
		codexOpen = false
		codexFrame.Visible = false
	end)

	-- Connect remotes
	IndexUpdated.OnClientEvent:Connect(onIndexUpdated)

	InitialData.OnClientEvent:Connect(function(data)
		if data.index then
			indexData = data.index
		end
		if data.unlockedFences then
			unlockedFences = data.unlockedFences
		end
	end)

	updateTabVisuals()
	print("[IndexUI] Initialized.")
end

return IndexUI
