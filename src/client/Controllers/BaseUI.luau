local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Shared.Utils)

local player = Players.LocalPlayer

local RARITY_COLORS = {
	Common = Color3.fromRGB(255, 255, 255),
	Rare = Color3.fromRGB(52, 152, 219),
	Epic = Color3.fromRGB(155, 89, 182),
	Legendary = Color3.fromRGB(230, 126, 34),
	Mythic = Color3.fromRGB(231, 76, 60),
	Goldy = Color3.fromRGB(241, 196, 15),
	Secret = Color3.fromRGB(26, 188, 156),
	Unknown = Color3.fromRGB(44, 62, 80),
}

local brainrotParts = {}
local plotPosition = nil
local capacityLabel = nil

local BaseUI = {}

local function spawnBrainrotVisual(brainrot)
	if not plotPosition then
		return
	end

	local part = Instance.new("Part")
	part.Name = "Brainrot_" .. brainrot.id
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(3, 3, 3)
	part.Color = RARITY_COLORS[brainrot.rarity] or Color3.fromRGB(255, 255, 255)

	local offsetX = math.random(-5, 5)
	local offsetZ = math.random(-5, 5)
	part.Position = Vector3.new(
		plotPosition.X + offsetX,
		plotPosition.Y + 1.5,
		plotPosition.Z + offsetZ
	)

	-- BillboardGui for name and earnings
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 200, 0, 60)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = part

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
	nameLabel.Text = brainrot.name
	nameLabel.TextColor3 = RARITY_COLORS[brainrot.rarity] or Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.BackgroundTransparency = 1
	nameLabel.Parent = billboard

	local earningsLabel = Instance.new("TextLabel")
	earningsLabel.Size = UDim2.new(1, 0, 0.5, 0)
	earningsLabel.Position = UDim2.new(0, 0, 0.5, 0)
	earningsLabel.Text = "+$" .. Utils.formatNumber(brainrot.earningsPerSec) .. "/sec"
	earningsLabel.TextColor3 = Color3.fromRGB(85, 255, 85)
	earningsLabel.TextScaled = true
	earningsLabel.BackgroundTransparency = 1
	earningsLabel.Parent = billboard

	part.Parent = workspace

	brainrotParts[brainrot.id] = part
end

function BaseUI.Init()
	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
	local BrainrotSpawned = remotesFolder:WaitForChild("BrainrotSpawned")
	local CapacityUpdated = remotesFolder:WaitForChild("CapacityUpdated")
	local InitialData = remotesFolder:WaitForChild("InitialData")

	-- Build capacity UI
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CapacityGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player.PlayerGui

	capacityLabel = Instance.new("TextLabel")
	capacityLabel.Name = "CapacityLabel"
	capacityLabel.Position = UDim2.new(1, -10, 0, 10)
	capacityLabel.AnchorPoint = Vector2.new(1, 0)
	capacityLabel.Size = UDim2.new(0, 200, 0, 40)
	capacityLabel.Text = "0/1 Brainrots"
	capacityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	capacityLabel.TextScaled = true
	capacityLabel.Font = Enum.Font.GothamBold
	capacityLabel.BackgroundTransparency = 1
	capacityLabel.Parent = screenGui

	-- Connect remotes
	InitialData.OnClientEvent:Connect(function(data)
		capacityLabel.Text = data.capacity.current .. "/" .. data.capacity.max .. " Brainrots"
		plotPosition = Vector3.new(0, 1, 0)

		for _, brainrot in data.brainrots do
			spawnBrainrotVisual(brainrot)
		end
	end)

	BrainrotSpawned.OnClientEvent:Connect(function(data)
		spawnBrainrotVisual(data.brainrotData)
	end)

	CapacityUpdated.OnClientEvent:Connect(function(data)
		capacityLabel.Text = data.current .. "/" .. data.max .. " Brainrots"
	end)
end

return BaseUI
