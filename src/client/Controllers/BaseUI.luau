local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Mutations = require(ReplicatedStorage.Shared.Config.Mutations)
local Utils = require(ReplicatedStorage.Shared.Utils)

local player = Players.LocalPlayer

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

local MAX_CAPACITY = 30
local UPGRADE_BASE_COST = 500
local UPGRADE_COST_MULTIPLIER = 2.5

local FENCE_COLOR = Color3.fromRGB(139, 90, 43)
local FENCE_POST_SIZE = Vector3.new(0.5, 4, 0.5)
local FENCE_RAIL_HEIGHT = 3
local FENCE_RAIL_THICKNESS = 0.3
local PLOT_SIZE = 30

local brainrotParts = {}
local brainrotConnections = {}
local fenceParts = {}
local plotPosition = nil
local capacityLabel = nil
local upgradeButton = nil

local BaseUI = {}

local function removeBrainrotVisual(brainrotId)
	local connection = brainrotConnections[brainrotId]
	if connection then
		connection:Disconnect()
		brainrotConnections[brainrotId] = nil
	end

	local part = brainrotParts[brainrotId]
	if part then
		part:Destroy()
		brainrotParts[brainrotId] = nil
	end
end

local function spawnBrainrotVisual(brainrot)
	if not plotPosition then
		return
	end

	local rarityColor = RARITY_COLORS[brainrot.rarity] or Color3.fromRGB(170, 170, 170)

	local part = Instance.new("Part")
	part.Name = "Brainrot_" .. brainrot.id
	part.Anchored = true
	part.CanCollide = false

	-- Scale the Part by the brainrot's size value
	local basePartSize = 3
	local scaledSize = basePartSize * brainrot.size
	part.Size = Vector3.new(scaledSize, scaledSize, scaledSize)
	part.Color = rarityColor

	-- Apply mutation color tint (replaces rarity color if mutation is present)
	local mutationColor = Mutations.getBaseMutationColor(brainrot.baseMutation)
	if mutationColor then
		part.Color = mutationColor
	end

	-- Y offset adjusts for scaled Part so it sits on the surface
	local yOffset = (scaledSize / 2) + 0.1
	local offsetX = math.random(-5, 5)
	local offsetZ = math.random(-5, 5)
	part.Position = Vector3.new(
		plotPosition.X + offsetX,
		plotPosition.Y + yOffset,
		plotPosition.Z + offsetZ
	)

	-- Particle emitter for mutated brainrots
	if brainrot.baseMutation then
		local emitter = Instance.new("ParticleEmitter")
		emitter.Rate = 15
		emitter.Lifetime = NumberRange.new(0.5, 1.5)
		emitter.Speed = NumberRange.new(1, 3)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(1, 0),
		})

		if brainrot.baseMutation == "Gold" then
			emitter.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
			emitter.LightEmission = 0.5
			emitter.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			})
		elseif brainrot.baseMutation == "Diamond" then
			emitter.Color = ColorSequence.new(Color3.fromRGB(185, 242, 255))
			emitter.LightEmission = 0.8
			emitter.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.2),
				NumberSequenceKeypoint.new(1, 1),
			})
		elseif brainrot.baseMutation == "Rainbow" then
			local rainbowColors = Mutations.RAINBOW_COLORS
			emitter.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, rainbowColors[1]),
				ColorSequenceKeypoint.new(0.167, rainbowColors[2]),
				ColorSequenceKeypoint.new(0.333, rainbowColors[3]),
				ColorSequenceKeypoint.new(0.5, rainbowColors[4]),
				ColorSequenceKeypoint.new(0.667, rainbowColors[5]),
				ColorSequenceKeypoint.new(0.833, rainbowColors[6]),
				ColorSequenceKeypoint.new(1, rainbowColors[7]),
			})
			emitter.LightEmission = 1.0
			emitter.Rate = 25
			emitter.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 0.8),
			})
		end

		emitter.Parent = part
	end

	-- Rainbow color cycling animation
	if Mutations.isRainbow(brainrot.baseMutation) then
		local rainbowColors = Mutations.RAINBOW_COLORS
		local elapsed = 0
		local cycleSpeed = 2

		local connection
		connection = RunService.RenderStepped:Connect(function(dt)
			if not part or not part.Parent then
				connection:Disconnect()
				brainrotConnections[brainrot.id] = nil
				return
			end

			elapsed = elapsed + dt
			local t = (elapsed / cycleSpeed) % 1
			local totalColors = #rainbowColors
			local scaledT = t * totalColors
			local index = math.floor(scaledT) % totalColors + 1
			local nextIndex = index % totalColors + 1
			local alpha = scaledT - math.floor(scaledT)

			part.Color = rainbowColors[index]:Lerp(rainbowColors[nextIndex], alpha)
		end)

		brainrotConnections[brainrot.id] = connection
	end

	-- BillboardGui for name and info
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 300, 0, 70)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = part

	-- Build name text: "[Mutation] [SizeLabel] [Rarity] [Name]"
	local labelParts = {}
	if brainrot.baseMutation then
		table.insert(labelParts, brainrot.baseMutation)
	end
	table.insert(labelParts, brainrot.sizeLabel)
	table.insert(labelParts, brainrot.rarity)
	table.insert(labelParts, brainrot.name)
	local nameText = table.concat(labelParts, " ")

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.Text = nameText
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.BackgroundTransparency = 1
	nameLabel.Parent = billboard

	-- Label color: mutation color > rarity color
	if brainrot.baseMutation then
		local mutColor = Mutations.getBaseMutationColor(brainrot.baseMutation)
		if mutColor then
			nameLabel.TextColor3 = mutColor
		elseif Mutations.isRainbow(brainrot.baseMutation) then
			nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	elseif brainrot.rarity == "Secret" then
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	else
		nameLabel.TextColor3 = rarityColor
	end

	-- Info label: "[Weight] lbs | +$[Earnings]/sec"
	local infoLabel = Instance.new("TextLabel")
	infoLabel.Size = UDim2.new(1, 0, 0.5, 0)
	infoLabel.Position = UDim2.new(0, 0, 0.5, 0)
	infoLabel.Text = tostring(brainrot.weight) .. " lbs | +$" .. Utils.formatNumber(brainrot.earningsPerSec) .. "/sec"
	infoLabel.TextColor3 = Color3.fromRGB(85, 255, 85)
	infoLabel.Font = Enum.Font.Gotham
	infoLabel.TextScaled = true
	infoLabel.BackgroundTransparency = 1
	infoLabel.Parent = billboard

	part.Parent = workspace

	brainrotParts[brainrot.id] = part
end

local function createFence(center: Vector3)
	for _, part in fenceParts do
		part:Destroy()
	end
	table.clear(fenceParts)

	local halfSize = PLOT_SIZE / 2

	local corners = {
		Vector3.new(center.X - halfSize, center.Y, center.Z - halfSize),
		Vector3.new(center.X + halfSize, center.Y, center.Z - halfSize),
		Vector3.new(center.X + halfSize, center.Y, center.Z + halfSize),
		Vector3.new(center.X - halfSize, center.Y, center.Z + halfSize),
	}

	-- Corner posts
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

	-- Rails between consecutive corners
	for i = 1, 4 do
		local startCorner = corners[i]
		local endCorner = corners[(i % 4) + 1]
		local midpoint = (startCorner + endCorner) / 2
		local direction = (endCorner - startCorner).Unit
		local length = (endCorner - startCorner).Magnitude

		-- Determine rail size based on direction
		local railSize
		if math.abs(direction.X) > 0.5 then
			railSize = Vector3.new(length, FENCE_RAIL_THICKNESS, FENCE_RAIL_THICKNESS)
		else
			railSize = Vector3.new(FENCE_RAIL_THICKNESS, FENCE_RAIL_THICKNESS, length)
		end

		-- Top rail
		local topRail = Instance.new("Part")
		topRail.Anchored = true
		topRail.CanCollide = false
		topRail.Material = Enum.Material.Wood
		topRail.Color = FENCE_COLOR
		topRail.Size = railSize
		topRail.Position = midpoint + Vector3.new(0, FENCE_RAIL_HEIGHT, 0)
		topRail.Parent = workspace
		table.insert(fenceParts, topRail)

		-- Bottom rail
		local bottomRail = Instance.new("Part")
		bottomRail.Anchored = true
		bottomRail.CanCollide = false
		bottomRail.Material = Enum.Material.Wood
		bottomRail.Color = FENCE_COLOR
		bottomRail.Size = railSize
		bottomRail.Position = midpoint + Vector3.new(0, FENCE_RAIL_HEIGHT / 2, 0)
		bottomRail.Parent = workspace
		table.insert(fenceParts, bottomRail)
	end
end

local function updateUpgradeButton(maxCapacity: number)
	if not upgradeButton then
		return
	end
	if maxCapacity >= MAX_CAPACITY then
		upgradeButton.Text = "MAX CAPACITY (30/30)"
		upgradeButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	else
		local cost = math.floor(UPGRADE_BASE_COST * UPGRADE_COST_MULTIPLIER ^ (maxCapacity - 1))
		upgradeButton.Text = "Upgrade (" .. maxCapacity .. "/" .. MAX_CAPACITY .. ") - $" .. Utils.formatNumber(cost)
		upgradeButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
	end
end

function BaseUI.Init()
	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
	local BrainrotSpawned = remotesFolder:WaitForChild("BrainrotSpawned")
	local CapacityUpdated = remotesFolder:WaitForChild("CapacityUpdated")
	local UpgradeCapacity = remotesFolder:WaitForChild("UpgradeCapacity")
	local InitialData = remotesFolder:WaitForChild("InitialData")
	local SellConfirmed = remotesFolder:WaitForChild("SellConfirmed")

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

	-- Upgrade button
	upgradeButton = Instance.new("TextButton")
	upgradeButton.Name = "UpgradeButton"
	upgradeButton.Position = UDim2.new(1, -10, 0, 55)
	upgradeButton.AnchorPoint = Vector2.new(1, 0)
	upgradeButton.Size = UDim2.new(0, 250, 0, 40)
	upgradeButton.Text = "Upgrade (1/30) - $500"
	upgradeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	upgradeButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
	upgradeButton.TextScaled = true
	upgradeButton.Font = Enum.Font.GothamBold
	upgradeButton.Parent = screenGui

	local upgradeCorner = Instance.new("UICorner")
	upgradeCorner.CornerRadius = UDim.new(0, 8)
	upgradeCorner.Parent = upgradeButton

	upgradeButton.Activated:Connect(function()
		UpgradeCapacity:FireServer()
	end)

	-- Connect remotes
	InitialData.OnClientEvent:Connect(function(data)
		capacityLabel.Text = data.capacity.current .. "/" .. data.capacity.max .. " Brainrots"
		updateUpgradeButton(data.capacity.max)
		plotPosition = Vector3.new(0, 0, 0)

		createFence(plotPosition)

		for _, brainrot in data.brainrots do
			spawnBrainrotVisual(brainrot)
		end
	end)

	BrainrotSpawned.OnClientEvent:Connect(function(data)
		spawnBrainrotVisual(data.brainrotData)
	end)

	CapacityUpdated.OnClientEvent:Connect(function(data)
		capacityLabel.Text = data.current .. "/" .. data.max .. " Brainrots"
		updateUpgradeButton(data.max)
	end)

	SellConfirmed.OnClientEvent:Connect(function(data)
		if data.soldIds then
			for _, id in data.soldIds do
				removeBrainrotVisual(id)
			end
		end
	end)
end

return BaseUI
