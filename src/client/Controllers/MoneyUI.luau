local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Shared.Utils)

local player = Players.LocalPlayer

local MoneyUI = {}

function MoneyUI.Init()
	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
	local MoneyUpdated = remotesFolder:WaitForChild("MoneyUpdated")
	local EarningsUpdated = remotesFolder:WaitForChild("EarningsUpdated")
	local InitialData = remotesFolder:WaitForChild("InitialData")

	-- Build UI
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MoneyGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player.PlayerGui

	local moneyFrame = Instance.new("Frame")
	moneyFrame.Name = "MoneyFrame"
	moneyFrame.Position = UDim2.new(0.5, 0, 0, 10)
	moneyFrame.AnchorPoint = Vector2.new(0.5, 0)
	moneyFrame.Size = UDim2.new(0, 300, 0, 80)
	moneyFrame.BackgroundTransparency = 1
	moneyFrame.Parent = screenGui

	local moneyLabel = Instance.new("TextLabel")
	moneyLabel.Name = "MoneyLabel"
	moneyLabel.Position = UDim2.new(0.5, 0, 0, 0)
	moneyLabel.AnchorPoint = Vector2.new(0.5, 0)
	moneyLabel.Size = UDim2.new(1, 0, 0, 45)
	moneyLabel.Text = "$100"
	moneyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	moneyLabel.TextScaled = true
	moneyLabel.Font = Enum.Font.GothamBold
	moneyLabel.BackgroundTransparency = 1
	moneyLabel.Parent = moneyFrame

	local earningsLabel = Instance.new("TextLabel")
	earningsLabel.Name = "EarningsLabel"
	earningsLabel.Position = UDim2.new(0.5, 0, 0, 45)
	earningsLabel.AnchorPoint = Vector2.new(0.5, 0)
	earningsLabel.Size = UDim2.new(1, 0, 0, 30)
	earningsLabel.Text = "+$0/sec"
	earningsLabel.TextColor3 = Color3.fromRGB(85, 255, 85)
	earningsLabel.TextScaled = true
	earningsLabel.Font = Enum.Font.Gotham
	earningsLabel.BackgroundTransparency = 1
	earningsLabel.Parent = moneyFrame

	-- Connect remotes
	InitialData.OnClientEvent:Connect(function(data)
		moneyLabel.Text = "$" .. Utils.formatNumber(data.money)
		earningsLabel.Text = "+$" .. Utils.formatNumber(data.earningsPerSec) .. "/sec"
	end)

	MoneyUpdated.OnClientEvent:Connect(function(data)
		moneyLabel.Text = "$" .. Utils.formatNumber(data.money)
	end)

	EarningsUpdated.OnClientEvent:Connect(function(data)
		earningsLabel.Text = "+$" .. Utils.formatNumber(data.earningsPerSec) .. "/sec"
	end)
end

return MoneyUI
