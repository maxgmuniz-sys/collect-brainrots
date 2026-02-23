local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Utils = require(ReplicatedStorage.Shared.Utils)

local player = Players.LocalPlayer

local ownedBrainrots = {}
local selectedBrainrotName = nil
local fusionListFrame = nil
local fuseButton = nil
local resultLabel = nil

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

local NEXT_RARITY = {
	Common = "Rare",
	Rare = "Epic",
	Epic = "Legendary",
	Legendary = "Mythic",
	Mythic = "Goldy",
	Goldy = "Secret",
	Secret = "Unknown",
}

local FusionUI = {}

local function countBrainrotsByName(): { [string]: { count: number, rarity: string } }
	local counts = {}
	for _, brainrot in ownedBrainrots do
		if not counts[brainrot.name] then
			counts[brainrot.name] = { count = 0, rarity = brainrot.rarity }
		end
		counts[brainrot.name].count += 1
	end
	return counts
end

local function refreshFusionList()
	if not fusionListFrame then
		return
	end

	-- Clear existing entries
	for _, child in fusionListFrame:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local counts = countBrainrotsByName()

	-- Sort by name for consistent display
	local names = {}
	for name in counts do
		table.insert(names, name)
	end
	table.sort(names)

	local order = 0
	for _, name in names do
		local info = counts[name]
		-- Skip Unknown rarity (can't fuse)
		if info.rarity == "Unknown" then
			continue
		end

		local canFuse = info.count >= 3
		local nextRarity = NEXT_RARITY[info.rarity] or "???"
		local rarityColor = RARITY_COLORS[info.rarity] or Color3.fromRGB(170, 170, 170)

		order += 1

		local entry = Instance.new("TextButton")
		entry.Name = "Fusion_" .. name
		entry.Size = UDim2.new(1, -10, 0, 50)
		entry.LayoutOrder = order
		entry.Font = Enum.Font.Gotham
		entry.TextScaled = true
		entry.TextXAlignment = Enum.TextXAlignment.Left
		entry.BackgroundColor3 = canFuse and Color3.fromRGB(50, 70, 50) or Color3.fromRGB(45, 45, 60)
		entry.TextColor3 = rarityColor
		entry.Text = "  " .. name .. "  (" .. info.count .. "/3) → " .. nextRarity
		entry.Parent = fusionListFrame

		local entryCorner = Instance.new("UICorner")
		entryCorner.CornerRadius = UDim.new(0, 8)
		entryCorner.Parent = entry

		-- Count label on right side
		local countLabel = Instance.new("TextLabel")
		countLabel.Name = "CountLabel"
		countLabel.Size = UDim2.new(0, 40, 1, 0)
		countLabel.Position = UDim2.new(1, -45, 0, 0)
		countLabel.BackgroundTransparency = 1
		countLabel.TextColor3 = canFuse and Color3.fromRGB(85, 255, 85) or Color3.fromRGB(200, 200, 200)
		countLabel.TextScaled = true
		countLabel.Font = Enum.Font.GothamBold
		countLabel.Text = tostring(info.count)
		countLabel.Parent = entry

		-- Selection highlight
		if selectedBrainrotName == name then
			entry.BackgroundColor3 = canFuse and Color3.fromRGB(70, 120, 70) or Color3.fromRGB(70, 70, 90)
		end

		entry.Activated:Connect(function()
			if canFuse then
				selectedBrainrotName = name
				refreshFusionList()
				if fuseButton then
					fuseButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
					fuseButton.Active = true
					fuseButton.Text = "Fuse 3x " .. name .. "!"
				end
			end
		end)
	end

	-- Update canvas size
	local layout = fusionListFrame:FindFirstChildOfClass("UIListLayout")
	if layout then
		fusionListFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
	end

	-- Deselect if the selected name no longer has 3+
	if selectedBrainrotName then
		local info = counts[selectedBrainrotName]
		if not info or info.count < 3 then
			selectedBrainrotName = nil
			if fuseButton then
				fuseButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
				fuseButton.Active = false
				fuseButton.Text = "Select 3+ to Fuse"
			end
		end
	end
end

function FusionUI.Init()
	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
	local FuseBrainrots = remotesFolder:WaitForChild("FuseBrainrots")
	local FuseResult = remotesFolder:WaitForChild("FuseResult")
	local BrainrotSpawned = remotesFolder:WaitForChild("BrainrotSpawned")
	local SellConfirmed = remotesFolder:WaitForChild("SellConfirmed")
	local InitialData = remotesFolder:WaitForChild("InitialData")

	-- ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FusionGui"
	screenGui.DisplayOrder = 9
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player.PlayerGui

	-- Toggle button
	local toggleButton = Instance.new("TextButton")
	toggleButton.Name = "FusionToggle"
	toggleButton.Position = UDim2.new(0, 10, 0, 160)
	toggleButton.Size = UDim2.new(0, 120, 0, 40)
	toggleButton.Text = "Fusion"
	toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
	toggleButton.TextScaled = true
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.Parent = screenGui

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 8)
	toggleCorner.Parent = toggleButton

	-- Main fusion frame
	local fusionFrame = Instance.new("Frame")
	fusionFrame.Name = "FusionFrame"
	fusionFrame.Size = UDim2.new(0.6, 0, 0.7, 0)
	fusionFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	fusionFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	fusionFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	fusionFrame.BackgroundTransparency = 0.05
	fusionFrame.Visible = false
	fusionFrame.ZIndex = 10
	fusionFrame.Parent = screenGui

	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 16)
	frameCorner.Parent = fusionFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -60, 0, 40)
	title.Position = UDim2.new(0, 15, 0, 10)
	title.Text = "Brainrot Fusion"
	title.TextColor3 = Color3.fromRGB(255, 200, 50)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.BackgroundTransparency = 1
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 10
	title.Parent = fusionFrame

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 35, 0, 35)
	closeButton.Position = UDim2.new(1, -10, 0, 10)
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.GothamBold
	closeButton.ZIndex = 11
	closeButton.Parent = fusionFrame

	local closeBtnCorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(0, 6)
	closeBtnCorner.Parent = closeButton

	-- Description
	local description = Instance.new("TextLabel")
	description.Name = "Description"
	description.Size = UDim2.new(1, -30, 0, 25)
	description.Position = UDim2.new(0, 15, 0, 52)
	description.Text = "Combine 3 of the same brainrot to get 1 from the next rarity!"
	description.TextColor3 = Color3.fromRGB(200, 200, 200)
	description.TextScaled = true
	description.Font = Enum.Font.Gotham
	description.BackgroundTransparency = 1
	description.TextXAlignment = Enum.TextXAlignment.Left
	description.ZIndex = 10
	description.Parent = fusionFrame

	-- Scrollable list
	fusionListFrame = Instance.new("ScrollingFrame")
	fusionListFrame.Name = "FusionList"
	fusionListFrame.Size = UDim2.new(1, -30, 1, -160)
	fusionListFrame.Position = UDim2.new(0, 15, 0, 82)
	fusionListFrame.BackgroundTransparency = 1
	fusionListFrame.ScrollBarThickness = 6
	fusionListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	fusionListFrame.ZIndex = 10
	fusionListFrame.Parent = fusionFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 6)
	listLayout.Parent = fusionListFrame

	local listPadding = Instance.new("UIPadding")
	listPadding.PaddingTop = UDim.new(0, 4)
	listPadding.PaddingBottom = UDim.new(0, 4)
	listPadding.PaddingLeft = UDim.new(0, 4)
	listPadding.PaddingRight = UDim.new(0, 4)
	listPadding.Parent = fusionListFrame

	-- Fuse button
	fuseButton = Instance.new("TextButton")
	fuseButton.Name = "FuseButton"
	fuseButton.Size = UDim2.new(0.5, 0, 0, 45)
	fuseButton.Position = UDim2.new(0.25, 0, 1, -60)
	fuseButton.Text = "Select 3+ to Fuse"
	fuseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	fuseButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	fuseButton.TextScaled = true
	fuseButton.Font = Enum.Font.GothamBold
	fuseButton.Active = false
	fuseButton.ZIndex = 10
	fuseButton.Parent = fusionFrame

	local fuseCorner = Instance.new("UICorner")
	fuseCorner.CornerRadius = UDim.new(0, 10)
	fuseCorner.Parent = fuseButton

	-- Result label
	resultLabel = Instance.new("TextLabel")
	resultLabel.Name = "ResultLabel"
	resultLabel.Size = UDim2.new(1, -30, 0, 25)
	resultLabel.Position = UDim2.new(0, 15, 1, -30)
	resultLabel.Text = ""
	resultLabel.TextColor3 = Color3.fromRGB(85, 255, 85)
	resultLabel.TextScaled = true
	resultLabel.Font = Enum.Font.GothamBold
	resultLabel.BackgroundTransparency = 1
	resultLabel.TextTransparency = 1
	resultLabel.ZIndex = 10
	resultLabel.Parent = fusionFrame

	-- Toggle logic
	toggleButton.Activated:Connect(function()
		fusionFrame.Visible = not fusionFrame.Visible
		if fusionFrame.Visible then
			refreshFusionList()
		end
	end)

	closeButton.Activated:Connect(function()
		fusionFrame.Visible = false
	end)

	-- Fuse button logic
	fuseButton.Activated:Connect(function()
		if not selectedBrainrotName then
			return
		end
		FuseBrainrots:FireServer({ brainrotName = selectedBrainrotName })

		-- Disable button briefly to prevent spam
		fuseButton.Active = false
		fuseButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		fuseButton.Text = "Fusing..."
		task.delay(1, function()
			if selectedBrainrotName then
				fuseButton.Active = true
				fuseButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
				fuseButton.Text = "Fuse 3x " .. selectedBrainrotName .. "!"
			end
		end)
	end)

	-- Track owned brainrots from initial data
	InitialData.OnClientEvent:Connect(function(data)
		ownedBrainrots = data.brainrots or {}
		if fusionFrame.Visible then
			refreshFusionList()
		end
	end)

	-- Update on new brainrot spawned
	BrainrotSpawned.OnClientEvent:Connect(function(data)
		table.insert(ownedBrainrots, data.brainrotData)
		if fusionFrame.Visible then
			refreshFusionList()
		end
	end)

	-- Update on sell confirmed
	SellConfirmed.OnClientEvent:Connect(function(data)
		if data.soldIds then
			local soldSet = {}
			for _, id in data.soldIds do
				soldSet[id] = true
			end
			local newList = {}
			for _, brainrot in ownedBrainrots do
				if not soldSet[brainrot.id] then
					table.insert(newList, brainrot)
				end
			end
			ownedBrainrots = newList
			if fusionFrame.Visible then
				refreshFusionList()
			end
		end
	end)

	-- Show fusion result
	FuseResult.OnClientEvent:Connect(function(data)
		local b = data.brainrotData

		-- Remove 3 of the fused name from local tracking
		-- (BrainrotSpawned will add the new one)
		local removed = 0
		local newList = {}
		for _, brainrot in ownedBrainrots do
			if brainrot.name == selectedBrainrotName and removed < 3 then
				removed += 1
			else
				table.insert(newList, brainrot)
			end
		end
		ownedBrainrots = newList

		-- Show result
		local personalityText = b.personality and (b.personality .. " ") or ""
		local mutationText = b.baseMutation and (b.baseMutation .. " ") or ""
		resultLabel.Text = "Fused into: " .. mutationText .. personalityText .. b.rarity .. " " .. b.name .. "!"
		resultLabel.TextColor3 = RARITY_COLORS[b.rarity] or Color3.fromRGB(85, 255, 85)
		resultLabel.TextTransparency = 0

		task.delay(4, function()
			resultLabel.TextTransparency = 1
		end)

		-- Reset selection
		selectedBrainrotName = nil
		fuseButton.Text = "Select 3+ to Fuse"
		fuseButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		fuseButton.Active = false

		refreshFusionList()
	end)

	-- Auto-size canvas on layout change
	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		fusionListFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end)
end

return FusionUI
