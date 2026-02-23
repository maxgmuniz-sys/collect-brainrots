local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local FoodStoreUI = {}

function FoodStoreUI.Init()
	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
	local BuyFood = remotesFolder:WaitForChild("BuyFood")
	local BrainrotSpawned = remotesFolder:WaitForChild("BrainrotSpawned")
	local BrainrotRanAway = remotesFolder:WaitForChild("BrainrotRanAway")

	-- Build UI
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FoodStoreGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player.PlayerGui

	local buyButton = Instance.new("TextButton")
	buyButton.Name = "BuyButton"
	buyButton.Position = UDim2.new(0.5, 0, 1, -80)
	buyButton.AnchorPoint = Vector2.new(0.5, 1)
	buyButton.Size = UDim2.new(0, 280, 0, 60)
	buyButton.Text = "Buy Common Chow - $50"
	buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
	buyButton.TextScaled = true
	buyButton.Font = Enum.Font.GothamBold
	buyButton.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = buyButton

	local feedbackLabel = Instance.new("TextLabel")
	feedbackLabel.Name = "FeedbackLabel"
	feedbackLabel.Position = UDim2.new(0.5, 0, 1, -150)
	feedbackLabel.AnchorPoint = Vector2.new(0.5, 1)
	feedbackLabel.Size = UDim2.new(0, 400, 0, 40)
	feedbackLabel.Text = ""
	feedbackLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	feedbackLabel.TextScaled = true
	feedbackLabel.Font = Enum.Font.GothamBold
	feedbackLabel.BackgroundTransparency = 1
	feedbackLabel.TextTransparency = 1
	feedbackLabel.Parent = screenGui

	-- Connect buy button
	buyButton.Activated:Connect(function()
		BuyFood:FireServer({ foodTier = "Common Chow" })
	end)

	-- Brainrot spawned feedback
	BrainrotSpawned.OnClientEvent:Connect(function(data)
		feedbackLabel.Text = data.brainrotData.name .. " joined your base!"
		feedbackLabel.TextColor3 = Color3.fromRGB(85, 255, 85)
		feedbackLabel.TextTransparency = 0

		task.delay(3, function()
			feedbackLabel.TextTransparency = 1
		end)
	end)

	-- Brainrot ran away feedback
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
