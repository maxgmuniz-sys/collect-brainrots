local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Mutations = require(ReplicatedStorage.Shared.Config.Mutations)
local Personalities = require(ReplicatedStorage.Shared.Config.Personalities)
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

-- Phase 7: Fence cosmetics
local currentBestFence = nil
local playerSelectionFrame = nil
local activeGiftBrainrotId = nil

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
		color = nil,
		transparency = 0,
	},
}

local FENCE_PRIORITY = {
	["Default Fence"] = 1,
	["Gold Fence"] = 2,
	["Diamond Fence"] = 3,
	["Rainbow Fence"] = 4,
}

-- Set in Init(), used by spawnBrainrotVisual for gift buttons
local giftBrainrotRemote = nil

local WEATHER_MUTATION_EFFECTS = {
	Soaked = {
		color = ColorSequence.new(Color3.fromRGB(100, 150, 255)),
		rate = 20,
		lifetime = NumberRange.new(0.5, 1.5),
		speed = NumberRange.new(1, 3),
		size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(1, 0),
		}),
		direction = Enum.NormalId.Top,
		lightEmission = 0.2,
	},
	Frozen = {
		color = ColorSequence.new(Color3.fromRGB(200, 230, 255)),
		rate = 15,
		lifetime = NumberRange.new(1, 2),
		speed = NumberRange.new(0.5, 2),
		size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(1, 0),
		}),
		direction = Enum.NormalId.Top,
		lightEmission = 0.6,
	},
	Shocked = {
		color = ColorSequence.new(Color3.fromRGB(255, 255, 100)),
		rate = 25,
		lifetime = NumberRange.new(0.2, 0.5),
		speed = NumberRange.new(5, 10),
		size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(1, 0),
		}),
		direction = Enum.NormalId.Top,
		lightEmission = 1.0,
	},
	Starstrucked = {
		color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 150)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 50)),
		}),
		rate = 12,
		lifetime = NumberRange.new(1, 3),
		speed = NumberRange.new(1, 4),
		size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(0.5, 0.3),
			NumberSequenceKeypoint.new(1, 0),
		}),
		direction = Enum.NormalId.Top,
		lightEmission = 1.0,
	},
	Burnt = {
		color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 20)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 50, 0)),
		}),
		rate = 30,
		lifetime = NumberRange.new(0.3, 1),
		speed = NumberRange.new(3, 8),
		size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(1, 0),
		}),
		direction = Enum.NormalId.Top,
		lightEmission = 0.8,
	},
	Radiated = {
		color = ColorSequence.new(Color3.fromRGB(100, 255, 50)),
		rate = 18,
		lifetime = NumberRange.new(1, 2.5),
		speed = NumberRange.new(1, 3),
		size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(1, 0.1),
		}),
		direction = Enum.NormalId.Top,
		lightEmission = 0.7,
	},
	Gravitated = {
		color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 50, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 0, 200)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 0, 80)),
		}),
		rate = 25,
		lifetime = NumberRange.new(0.5, 1.5),
		speed = NumberRange.new(5, 15),
		size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.6),
			NumberSequenceKeypoint.new(1, 0),
		}),
		direction = Enum.NormalId.Bottom,
		lightEmission = 0.9,
	},
}

local WEATHER_MUTATION_COLORS = {
	Soaked = Color3.fromRGB(100, 150, 255),
	Frozen = Color3.fromRGB(200, 230, 255),
	Shocked = Color3.fromRGB(255, 255, 100),
	Starstrucked = Color3.fromRGB(255, 200, 50),
	Burnt = Color3.fromRGB(255, 100, 20),
	Radiated = Color3.fromRGB(100, 255, 50),
	Gravitated = Color3.fromRGB(180, 50, 255),
}

local BaseUI = {}

local function addWeatherMutationEffect(part, mutation: string)
	local existingEmitter = part:FindFirstChild("WeatherMutationEffect")
	if existingEmitter then
		return
	end

	local config = WEATHER_MUTATION_EFFECTS[mutation]
	if not config then
		return
	end

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "WeatherMutationEffect"
	emitter.Color = config.color
	emitter.Rate = config.rate
	emitter.Lifetime = config.lifetime
	emitter.Speed = config.speed
	emitter.Size = config.size
	emitter.EmissionDirection = config.direction
	emitter.LightEmission = config.lightEmission
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Parent = part
end

local function updateBillboardWithWeatherMutation(brainrotId: string, weatherMutation: string)
	local part = brainrotParts[brainrotId]
	if not part then
		return
	end

	local billboard = part:FindFirstChildOfClass("BillboardGui")
	if not billboard then
		return
	end

	local weatherLabel = billboard:FindFirstChild("WeatherMutationLabel")
	if not weatherLabel then
		weatherLabel = Instance.new("TextLabel")
		weatherLabel.Name = "WeatherMutationLabel"
		weatherLabel.Size = UDim2.new(1, -20, 0, 16)
		weatherLabel.Position = UDim2.new(0, 10, 1, -18)
		weatherLabel.BackgroundTransparency = 1
		weatherLabel.TextScaled = true
		weatherLabel.Font = Enum.Font.GothamBold
		weatherLabel.Parent = billboard

		billboard.Size = billboard.Size + UDim2.new(0, 0, 0, 20)
	end

	weatherLabel.Text = weatherMutation
	weatherLabel.TextColor3 = WEATHER_MUTATION_COLORS[weatherMutation] or Color3.fromRGB(255, 255, 255)
end

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
	frame.Parent = player.PlayerGui

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
	title.ZIndex = 15
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
	list.ZIndex = 15
	list.Parent = frame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 4)
	listLayout.Parent = list

	return { Frame = frame, List = list }
end

local function showPlayerSelectionUI(brainrotId: string, GiftBrainrot)
	activeGiftBrainrotId = brainrotId

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
	for _, otherPlayer in Players:GetPlayers() do
		if otherPlayer ~= player then
			local entry = Instance.new("TextButton")
			entry.Name = "Player_" .. otherPlayer.UserId
			entry.Size = UDim2.new(1, 0, 0, 35)
			entry.Text = otherPlayer.Name
			entry.TextColor3 = Color3.fromRGB(255, 255, 255)
			entry.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
			entry.TextScaled = true
			entry.Font = Enum.Font.Gotham
			entry.ZIndex = 15
			entry.Parent = playerSelectionFrame.List

			local entryCorner = Instance.new("UICorner")
			entryCorner.CornerRadius = UDim.new(0, 6)
			entryCorner.Parent = entry

			entry.Activated:Connect(function()
				GiftBrainrot:FireServer({
					brainrotId = activeGiftBrainrotId,
					targetPlayerId = otherPlayer.UserId,
				})
				playerSelectionFrame.Frame.Visible = false
			end)
		end
	end

	playerSelectionFrame.Frame.Visible = true
end

local function addGiftButton(brainrotPart, brainrotId: string, GiftBrainrot)
	local billboard = brainrotPart:FindFirstChildOfClass("BillboardGui")
	if not billboard then
		return
	end

	local giftButton = Instance.new("TextButton")
	giftButton.Name = "GiftButton"
	giftButton.Size = UDim2.new(0, 50, 0, 20)
	giftButton.Position = UDim2.new(1, -30, 1, -25)
	giftButton.Text = "Gift"
	giftButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	giftButton.BackgroundColor3 = Color3.fromRGB(80, 160, 80)
	giftButton.TextScaled = true
	giftButton.Font = Enum.Font.GothamBold
	giftButton.ZIndex = 5
	giftButton.Parent = billboard

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 4)
	btnCorner.Parent = giftButton

	giftButton.Activated:Connect(function()
		showPlayerSelectionUI(brainrotId, GiftBrainrot)
	end)
end

local function startIdleBob(part, speed: number)
	local baseY = part.Position.Y
	local elapsed = 0
	local bobHeight = 0.3
	local bobFrequency = 1.5 * speed

	local connection
	connection = RunService.RenderStepped:Connect(function(dt)
		if not part or not part.Parent then
			connection:Disconnect()
			return
		end

		elapsed += dt
		local offset = math.sin(elapsed * bobFrequency * math.pi * 2) * bobHeight
		part.Position = Vector3.new(part.Position.X, baseY + offset, part.Position.Z)
	end)

	-- Store connection for cleanup
	if not brainrotConnections[part.Name:gsub("Brainrot_", "")] then
		brainrotConnections[part.Name:gsub("Brainrot_", "")] = connection
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
	local yOffset = scaledSize / 2
	local offsetX = math.random(-5, 5)
	local offsetZ = math.random(-5, 5)
	part.Position = Vector3.new(plotPosition.X + offsetX, plotPosition.Y + yOffset, plotPosition.Z + offsetZ)

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
	infoLabel.Size = UDim2.new(1, 0, 0.35, 0)
	infoLabel.Position = UDim2.new(0, 0, 0.45, 0)
	infoLabel.Text = tostring(brainrot.weight) .. " lbs | +$" .. Utils.formatNumber(brainrot.earningsPerSec) .. "/sec"
	infoLabel.TextColor3 = Color3.fromRGB(85, 255, 85)
	infoLabel.Font = Enum.Font.Gotham
	infoLabel.TextScaled = true
	infoLabel.BackgroundTransparency = 1
	infoLabel.Parent = billboard

	-- Personality label (Phase 8)
	if brainrot.personality then
		local personalityColor = Personalities.getColor(brainrot.personality) or Color3.fromRGB(200, 200, 200)
		local personalityLabel = Instance.new("TextLabel")
		personalityLabel.Name = "PersonalityLabel"
		personalityLabel.Size = UDim2.new(1, 0, 0.2, 0)
		personalityLabel.Position = UDim2.new(0, 0, 0.8, 0)
		personalityLabel.Text = brainrot.personality
		personalityLabel.TextColor3 = personalityColor
		personalityLabel.Font = Enum.Font.GothamBold
		personalityLabel.TextScaled = true
		personalityLabel.BackgroundTransparency = 1
		personalityLabel.Parent = billboard
	end

	part.Parent = workspace

	-- Start idle bob animation scaled by personality speed (Phase 8)
	local animSpeed = Personalities.getAnimationSpeed(brainrot.personality)
	startIdleBob(part, animSpeed)

	brainrotParts[brainrot.id] = part

	-- Restore weather mutation visuals on load
	if brainrot.weatherMutation then
		addWeatherMutationEffect(part, brainrot.weatherMutation)
		updateBillboardWithWeatherMutation(brainrot.id, brainrot.weatherMutation)
	end

	-- Add gift button (Phase 7)
	if giftBrainrotRemote then
		addGiftButton(part, brainrot.id, giftBrainrotRemote)
	end
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

local function getBestFenceFromList(fences: { string }): string?
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

local function startRainbowFenceCycle()
	local rainbowColors = Mutations.RAINBOW_COLORS
	local colorIndex = 1

	task.spawn(function()
		while currentBestFence == "Rainbow Fence" do
			local targetColor = rainbowColors[colorIndex]
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
			colorIndex = (colorIndex % #rainbowColors) + 1
			task.wait(0.5)
		end
	end)
end

local function applyFenceCosmetic(fenceName: string)
	local cosmetic = FENCE_COSMETICS[fenceName]
	if not cosmetic then
		return
	end

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

	if fenceName == "Rainbow Fence" then
		startRainbowFenceCycle()
	end
end

local function showGiftNotification(fromPlayer: string, brainrotName: string, rarity: string, mutation: string?)
	local mutationText = mutation and (mutation .. " ") or ""
	local message = fromPlayer .. " gifted you a " .. mutationText .. brainrotName .. "!"

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
	notification.Parent = player.PlayerGui

	local notifCorner = Instance.new("UICorner")
	notifCorner.CornerRadius = UDim.new(0, 10)
	notifCorner.Parent = notification

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

function BaseUI.Init()
	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
	local BrainrotSpawned = remotesFolder:WaitForChild("BrainrotSpawned")
	local CapacityUpdated = remotesFolder:WaitForChild("CapacityUpdated")
	local UpgradeCapacity = remotesFolder:WaitForChild("UpgradeCapacity")
	local InitialData = remotesFolder:WaitForChild("InitialData")
	local SellConfirmed = remotesFolder:WaitForChild("SellConfirmed")
	local BrainrotMutated = remotesFolder:WaitForChild("BrainrotMutated")

	-- Phase 7 remotes
	local GiftBrainrot = remotesFolder:WaitForChild("GiftBrainrot")
	local GiftReceived = remotesFolder:WaitForChild("GiftReceived")
	local IndexUpdated = remotesFolder:WaitForChild("IndexUpdated")

	-- Store remote reference for spawnBrainrotVisual gift buttons
	giftBrainrotRemote = GiftBrainrot

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

		-- Apply best fence cosmetic (Phase 7)
		if data.unlockedFences and #data.unlockedFences > 0 then
			local bestFence = getBestFenceFromList(data.unlockedFences)
			if bestFence then
				applyFenceCosmetic(bestFence)
			end
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

	BrainrotMutated.OnClientEvent:Connect(function(data)
		local part = brainrotParts[data.brainrotId]
		if not part or not part.Parent then
			return
		end
		addWeatherMutationEffect(part, data.weatherMutation)
		updateBillboardWithWeatherMutation(data.brainrotId, data.weatherMutation)
	end)

	-- Phase 7: Gift received notification
	GiftReceived.OnClientEvent:Connect(function(data)
		showGiftNotification(data.fromPlayerName, data.brainrotName, data.brainrotRarity, data.baseMutation)
	end)

	-- Phase 7: Fence reward from index completion
	IndexUpdated.OnClientEvent:Connect(function(data)
		if data.fenceReward then
			applyFenceCosmetic(data.fenceReward)
		end
	end)
end

return BaseUI
