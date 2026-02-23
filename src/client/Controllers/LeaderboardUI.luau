local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Utils = require(ReplicatedStorage.Shared.Utils)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local LEADERBOARD_TABS = { "MostMoney", "MostTime", "MostRobux" }

local TAB_DISPLAY_NAMES = {
	MostMoney = "Most Money",
	MostTime = "Most Time",
	MostRobux = "Most Robux",
}

local TAB_COLORS = {
	MostMoney = Color3.fromRGB(85, 255, 85),
	MostTime = Color3.fromRGB(85, 170, 255),
	MostRobux = Color3.fromRGB(255, 170, 85),
}

local RANK_COLORS = {
	[1] = Color3.fromRGB(255, 215, 0),
	[2] = Color3.fromRGB(192, 192, 192),
	[3] = Color3.fromRGB(205, 127, 50),
}

local MAX_VISIBLE_ENTRIES = 50
local REFRESH_COOLDOWN = 10

local leaderboardData = {}
local currentLeaderboardTab = "MostMoney"
local leaderboardOpen = false
local lastRefreshTime = 0

-- UI references
local leaderboardFrame = nil
local entryList = nil
local tabButtons = {}

local LeaderboardUI = {}

local function formatValue(tab: string, value: number): string
	if tab == "MostMoney" then
		return "$" .. Utils.formatNumber(value)
	elseif tab == "MostTime" then
		local hours = math.floor(value / 3600)
		local minutes = math.floor((value % 3600) / 60)
		return hours .. "h " .. minutes .. "m"
	elseif tab == "MostRobux" then
		return tostring(value) .. " R$"
	end
	return tostring(value)
end

local function updateLeaderboardTabVisuals()
	for tabKey, button in tabButtons do
		if tabKey == currentLeaderboardTab then
			button.BackgroundColor3 = TAB_COLORS[tabKey]
			button.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			button.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
			button.TextColor3 = Color3.fromRGB(150, 150, 150)
		end
	end
end

local function refreshEntryList()
	if not entryList then
		return
	end

	-- Clear existing entries
	for _, child in entryList:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local entries = leaderboardData[currentLeaderboardTab] or {}

	for i, entry in entries do
		if i > MAX_VISIBLE_ENTRIES then
			break
		end

		local entryFrame = Instance.new("Frame")
		entryFrame.Name = "Entry_" .. entry.rank
		entryFrame.Size = UDim2.new(1, 0, 0, 35)
		entryFrame.LayoutOrder = entry.rank
		entryFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
		entryFrame.BackgroundTransparency = 0.3
		entryFrame.Parent = entryList

		local entryCorner = Instance.new("UICorner")
		entryCorner.CornerRadius = UDim.new(0, 6)
		entryCorner.Parent = entryFrame

		-- Rank label
		local rankLabel = Instance.new("TextLabel")
		rankLabel.Name = "RankLabel"
		rankLabel.Position = UDim2.new(0, 8, 0.5, 0)
		rankLabel.AnchorPoint = Vector2.new(0, 0.5)
		rankLabel.Size = UDim2.new(0, 30, 0, 25)
		rankLabel.Text = "#" .. entry.rank
		rankLabel.TextColor3 = RANK_COLORS[entry.rank] or Color3.fromRGB(200, 200, 200)
		rankLabel.TextScaled = true
		rankLabel.Font = Enum.Font.GothamBold
		rankLabel.BackgroundTransparency = 1
		rankLabel.Parent = entryFrame

		-- Name label
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Position = UDim2.new(0, 45, 0.5, 0)
		nameLabel.AnchorPoint = Vector2.new(0, 0.5)
		nameLabel.Size = UDim2.new(0.5, -20, 0, 25)
		nameLabel.Text = entry.name or "Unknown"
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = entryFrame

		-- Value label
		local valueLabel = Instance.new("TextLabel")
		valueLabel.Name = "ValueLabel"
		valueLabel.Position = UDim2.new(1, -8, 0.5, 0)
		valueLabel.AnchorPoint = Vector2.new(1, 0.5)
		valueLabel.Size = UDim2.new(0.35, 0, 0, 25)
		valueLabel.Text = formatValue(currentLeaderboardTab, entry.value or 0)
		valueLabel.TextColor3 = TAB_COLORS[currentLeaderboardTab]
		valueLabel.TextScaled = true
		valueLabel.Font = Enum.Font.GothamBold
		valueLabel.BackgroundTransparency = 1
		valueLabel.TextXAlignment = Enum.TextXAlignment.Right
		valueLabel.Parent = entryFrame
	end

	-- Update canvas size
	local listLayout = entryList:FindFirstChildOfClass("UIListLayout")
	if listLayout then
		entryList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
	end
end

local function onLeaderboardData(data)
	if not data then
		return
	end

	leaderboardData = data
	lastRefreshTime = os.clock()
	refreshEntryList()
end

function LeaderboardUI.Init()
	-- Wait for remotes
	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
	local RequestLeaderboard = remotesFolder:WaitForChild("RequestLeaderboard")
	local LeaderboardData = remotesFolder:WaitForChild("LeaderboardData")

	-- ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LeaderboardGui"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 7
	screenGui.Parent = playerGui

	-- Toggle button
	local toggleButton = Instance.new("TextButton")
	toggleButton.Name = "LeaderboardToggleButton"
	toggleButton.Position = UDim2.new(0, 10, 0, 110)
	toggleButton.Size = UDim2.new(0, 120, 0, 40)
	toggleButton.Text = "Leaderboard"
	toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleButton.BackgroundColor3 = Color3.fromRGB(60, 130, 60)
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.TextScaled = true
	toggleButton.Parent = screenGui

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 8)
	toggleCorner.Parent = toggleButton

	-- Leaderboard frame (sidebar)
	leaderboardFrame = Instance.new("Frame")
	leaderboardFrame.Name = "LeaderboardFrame"
	leaderboardFrame.Position = UDim2.new(1, -10, 0.5, 0)
	leaderboardFrame.AnchorPoint = Vector2.new(1, 0.5)
	leaderboardFrame.Size = UDim2.new(0, 320, 0.7, 0)
	leaderboardFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	leaderboardFrame.BackgroundTransparency = 0.05
	leaderboardFrame.Visible = false
	leaderboardFrame.ZIndex = 8
	leaderboardFrame.Parent = screenGui

	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 12)
	frameCorner.Parent = leaderboardFrame

	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Position = UDim2.new(0.5, 0, 0, 10)
	titleLabel.AnchorPoint = Vector2.new(0.5, 0)
	titleLabel.Size = UDim2.new(1, -20, 0, 30)
	titleLabel.Text = "Leaderboards"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.BackgroundTransparency = 1
	titleLabel.ZIndex = 8
	titleLabel.Parent = leaderboardFrame

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Position = UDim2.new(1, -10, 0, 10)
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.Font = Enum.Font.GothamBold
	closeButton.ZIndex = 9
	closeButton.Parent = leaderboardFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = closeButton

	-- Tab bar
	local tabBar = Instance.new("Frame")
	tabBar.Name = "TabBar"
	tabBar.Position = UDim2.new(0.5, 0, 0, 45)
	tabBar.AnchorPoint = Vector2.new(0.5, 0)
	tabBar.Size = UDim2.new(1, -20, 0, 30)
	tabBar.BackgroundTransparency = 1
	tabBar.ZIndex = 8
	tabBar.Parent = leaderboardFrame

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tabLayout.Padding = UDim.new(0, 5)
	tabLayout.Parent = tabBar

	for _, tabKey in LEADERBOARD_TABS do
		local tabButton = Instance.new("TextButton")
		tabButton.Name = "Tab_" .. tabKey
		tabButton.Size = UDim2.new(0.3, 0, 1, 0)
		tabButton.Text = TAB_DISPLAY_NAMES[tabKey]
		tabButton.TextScaled = true
		tabButton.Font = Enum.Font.GothamBold
		tabButton.ZIndex = 8
		tabButton.Parent = tabBar

		local tabCorner = Instance.new("UICorner")
		tabCorner.CornerRadius = UDim.new(0, 6)
		tabCorner.Parent = tabButton

		tabButtons[tabKey] = tabButton

		tabButton.Activated:Connect(function()
			currentLeaderboardTab = tabKey
			updateLeaderboardTabVisuals()
			refreshEntryList()
		end)
	end

	-- Entry list (scrollable)
	entryList = Instance.new("ScrollingFrame")
	entryList.Name = "EntryList"
	entryList.Position = UDim2.new(0.5, 0, 0, 85)
	entryList.AnchorPoint = Vector2.new(0.5, 0)
	entryList.Size = UDim2.new(1, -20, 1, -95)
	entryList.CanvasSize = UDim2.new(0, 0, 0, 0)
	entryList.ScrollBarThickness = 4
	entryList.BackgroundTransparency = 1
	entryList.ZIndex = 8
	entryList.Parent = leaderboardFrame

	local entryLayout = Instance.new("UIListLayout")
	entryLayout.Padding = UDim.new(0, 4)
	entryLayout.SortOrder = Enum.SortOrder.LayoutOrder
	entryLayout.Parent = entryList

	-- Auto-size canvas
	entryLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		entryList.CanvasSize = UDim2.new(0, 0, 0, entryLayout.AbsoluteContentSize.Y + 8)
	end)

	-- Connect toggle
	toggleButton.Activated:Connect(function()
		leaderboardOpen = not leaderboardOpen
		leaderboardFrame.Visible = leaderboardOpen
		if leaderboardOpen and (os.clock() - lastRefreshTime > REFRESH_COOLDOWN) then
			RequestLeaderboard:FireServer()
		end
	end)

	closeButton.Activated:Connect(function()
		leaderboardOpen = false
		leaderboardFrame.Visible = false
	end)

	-- Connect remotes
	LeaderboardData.OnClientEvent:Connect(onLeaderboardData)

	updateLeaderboardTabVisuals()
	print("[LeaderboardUI] Initialized.")
end

return LeaderboardUI
