local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Foods = require(ReplicatedStorage.Shared.Config.Foods)
local Utils = require(ReplicatedStorage.Shared.Utils)

local player = Players.LocalPlayer

local currentMoney = 0
local isBaseFull = false
local buyButtons = {}

local FoodStoreUI = {}

function FoodStoreUI.Init()
	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
	local BuyFood = remotesFolder:WaitForChild("BuyFood")
	local BrainrotSpawned = remotesFolder:WaitForChild("BrainrotSpawned")
	local BrainrotRanAway = remotesFolder:WaitForChild("BrainrotRanAway")
	local MoneyUpdated = remotesFolder:WaitForChild("MoneyUpdated")
	local CapacityUpdated = remotesFolder:WaitForChild("CapacityUpdated")
	local InitialData = remotesFolder:WaitForChild("InitialData")

	-- Build UI
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FoodStoreGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player.PlayerGui

	-- Store frame
	local storeFrame = Instance.new("Frame")
	storeFrame.Name = "StoreFrame"
	storeFrame.Position = UDim2.new(0.5, 0, 1, -20)
	storeFrame.AnchorPoint = Vector2.new(0.5, 1)
	storeFrame.Size = UDim2.new(0, 320, 0, 360)
	storeFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	storeFrame.BackgroundTransparency = 0.15
	storeFrame.Parent = screenGui

	local storeCorner = Instance.new("UICorner")
	storeCorner.CornerRadius = UDim.new(0, 16)
	storeCorner.Parent = storeFrame

	-- Title
	local storeTitle = Instance.new("TextLabel")
	storeTitle.Name = "StoreTitle"
	storeTitle.Position = UDim2.new(0.5, 0, 0, 8)
	storeTitle.AnchorPoint = Vector2.new(0.5, 0)
	storeTitle.Size = UDim2.new(1, -20, 0, 30)
	storeTitle.Text = "Food Store"
	storeTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	storeTitle.TextScaled = true
	storeTitle.Font = Enum.Font.GothamBold
	storeTitle.BackgroundTransparency = 1
	storeTitle.Parent = storeFrame

	-- Scrolling food list
	local foodList = Instance.new("ScrollingFrame")
	foodList.Name = "FoodList"
	foodList.Position = UDim2.new(0, 10, 0, 45)
	foodList.Size = UDim2.new(1, -20, 1, -55)
	foodList.BackgroundTransparency = 1
	foodList.ScrollBarThickness = 6
	foodList.CanvasSize = UDim2.new(0, 0, 0, 0)
	foodList.Parent = storeFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 8)
	listLayout.Parent = foodList

	local listPadding = Instance.new("UIPadding")
	listPadding.PaddingTop = UDim.new(0, 4)
	listPadding.PaddingBottom = UDim.new(0, 4)
	listPadding.PaddingLeft = UDim.new(0, 4)
	listPadding.PaddingRight = UDim.new(0, 4)
	listPadding.Parent = foodList

	-- Create food rows
	for i, food in Foods.FOODS do
		local row = Instance.new("Frame")
		row.Name = "FoodRow_" .. i
		row.Size = UDim2.new(1, 0, 0, 72)
		row.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
		row.LayoutOrder = i
		row.Parent = foodList

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 10)
		rowCorner.Parent = row

		local foodName = Instance.new("TextLabel")
		foodName.Name = "FoodName"
		foodName.Position = UDim2.new(0, 12, 0, 6)
		foodName.Size = UDim2.new(0.55, 0, 0, 22)
		foodName.Text = food.name
		foodName.TextColor3 = Color3.fromRGB(255, 255, 255)
		foodName.Font = Enum.Font.GothamBold
		foodName.TextScaled = true
		foodName.TextXAlignment = Enum.TextXAlignment.Left
		foodName.BackgroundTransparency = 1
		foodName.Parent = row

		local foodInfo = Instance.new("TextLabel")
		foodInfo.Name = "FoodInfo"
		foodInfo.Position = UDim2.new(0, 12, 0, 28)
		foodInfo.Size = UDim2.new(0.55, 0, 0, 18)
		foodInfo.Text = "Attracts up to: " .. food.maxRarity
		foodInfo.TextColor3 = Color3.fromRGB(170, 170, 190)
		foodInfo.Font = Enum.Font.Gotham
		foodInfo.TextScaled = true
		foodInfo.TextXAlignment = Enum.TextXAlignment.Left
		foodInfo.BackgroundTransparency = 1
		foodInfo.Parent = row

		local foodCost = Instance.new("TextLabel")
		foodCost.Name = "FoodCost"
		foodCost.Position = UDim2.new(0, 12, 0, 48)
		foodCost.Size = UDim2.new(0.55, 0, 0, 18)
		foodCost.Text = "$" .. Utils.formatNumber(food.cost)
		foodCost.TextColor3 = Color3.fromRGB(85, 255, 85)
		foodCost.Font = Enum.Font.Gotham
		foodCost.TextScaled = true
		foodCost.TextXAlignment = Enum.TextXAlignment.Left
		foodCost.BackgroundTransparency = 1
		foodCost.Parent = row

		local buyButton = Instance.new("TextButton")
		buyButton.Name = "BuyButton"
		buyButton.Position = UDim2.new(1, -12, 0.5, 0)
		buyButton.AnchorPoint = Vector2.new(1, 0.5)
		buyButton.Size = UDim2.new(0, 80, 0, 40)
		buyButton.Text = "Buy"
		buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		buyButton.Font = Enum.Font.GothamBold
		buyButton.TextScaled = true
		buyButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
		buyButton.Parent = row

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 8)
		btnCorner.Parent = buyButton

		buyButtons[food.name] = buyButton

		buyButton.Activated:Connect(function()
			BuyFood:FireServer({ foodTier = food.name })
		end)
	end

	-- Auto-size canvas
	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		foodList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end)
	foodList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)

	-- Base full label
	local baseFullLabel = Instance.new("TextLabel")
	baseFullLabel.Name = "BaseFullLabel"
	baseFullLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	baseFullLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	baseFullLabel.Size = UDim2.new(0.8, 0, 0, 40)
	baseFullLabel.Text = "Base Full!"
	baseFullLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
	baseFullLabel.Font = Enum.Font.GothamBold
	baseFullLabel.TextScaled = true
	baseFullLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	baseFullLabel.BackgroundTransparency = 0.3
	baseFullLabel.Visible = false
	baseFullLabel.Parent = storeFrame

	local fullCorner = Instance.new("UICorner")
	fullCorner.CornerRadius = UDim.new(0, 8)
	fullCorner.Parent = baseFullLabel

	-- Feedback label
	local feedbackLabel = Instance.new("TextLabel")
	feedbackLabel.Name = "FeedbackLabel"
	feedbackLabel.Position = UDim2.new(0.5, 0, 1, -390)
	feedbackLabel.AnchorPoint = Vector2.new(0.5, 1)
	feedbackLabel.Size = UDim2.new(0, 400, 0, 40)
	feedbackLabel.Text = ""
	feedbackLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	feedbackLabel.TextScaled = true
	feedbackLabel.Font = Enum.Font.GothamBold
	feedbackLabel.BackgroundTransparency = 1
	feedbackLabel.TextTransparency = 1
	feedbackLabel.Parent = screenGui

	-- Update button states
	local function updateButtonStates()
		for _, food in Foods.FOODS do
			local btn = buyButtons[food.name]
			if not btn then
				continue
			end

			if isBaseFull then
				btn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
				btn.Active = false
			elseif currentMoney < food.cost then
				btn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
				btn.Active = false
			else
				btn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
				btn.Active = true
			end
		end

		if isBaseFull then
			baseFullLabel.Visible = true
			baseFullLabel.TextTransparency = 0
			baseFullLabel.BackgroundTransparency = 0.3
			task.delay(3, function()
				baseFullLabel.Visible = false
			end)
		else
			baseFullLabel.Visible = false
		end
	end

	-- Connect remotes
	InitialData.OnClientEvent:Connect(function(data)
		currentMoney = data.money
		isBaseFull = data.capacity.current >= data.capacity.max
		updateButtonStates()
	end)

	MoneyUpdated.OnClientEvent:Connect(function(data)
		currentMoney = data.money
		updateButtonStates()
	end)

	CapacityUpdated.OnClientEvent:Connect(function(data)
		isBaseFull = data.current >= data.max
		updateButtonStates()
	end)

	BrainrotSpawned.OnClientEvent:Connect(function(data)
		feedbackLabel.Text = data.brainrotData.name .. " joined your base!"
		feedbackLabel.TextColor3 = Color3.fromRGB(85, 255, 85)
		feedbackLabel.TextTransparency = 0
		task.delay(3, function()
			feedbackLabel.TextTransparency = 1
		end)
	end)

	BrainrotRanAway.OnClientEvent:Connect(function(data)
		feedbackLabel.Text = data.brainrotName .. " ran away!"
		feedbackLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
		feedbackLabel.TextTransparency = 0
		task.delay(3, function()
			feedbackLabel.TextTransparency = 1
		end)
	end)
end

return FoodStoreUI
