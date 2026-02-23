local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Brainrots = require(ReplicatedStorage.Shared.Config.Brainrots)
local Mutations = require(ReplicatedStorage.Shared.Config.Mutations)
local Utils = require(ReplicatedStorage.Shared.Utils)

local player = Players.LocalPlayer

local SELL_SECONDS = 60

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

local ownedBrainrots = {}
local sellStoreOpen = false
local pendingSellId = nil

local SellUI = {}

local function calculateClientSellValue(brainrot): number
	local config = Brainrots.BRAINROT_BY_NAME[brainrot.name]
	if not config then
		return 0
	end
	local baseEarnings = config.baseEarningsPerSec
	local sizeMult = brainrot.size
	local baseMutMult = Mutations.getBaseMutationMultiplier(brainrot.baseMutation)
	return math.floor(baseEarnings * SELL_SECONDS * sizeMult * baseMutMult)
end

function SellUI.Init()
	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
	local SellBrainrot = remotesFolder:WaitForChild("SellBrainrot")
	local SellAll = remotesFolder:WaitForChild("SellAll")
	local SellConfirmed = remotesFolder:WaitForChild("SellConfirmed")
	local BrainrotSpawned = remotesFolder:WaitForChild("BrainrotSpawned")
	local InitialData = remotesFolder:WaitForChild("InitialData")

	-- ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SellStoreGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player.PlayerGui

	-- Toggle button
	local toggleButton = Instance.new("TextButton")
	toggleButton.Name = "SellToggleButton"
	toggleButton.Position = UDim2.new(0, 10, 0.5, 0)
	toggleButton.AnchorPoint = Vector2.new(0, 0.5)
	toggleButton.Size = UDim2.new(0, 120, 0, 40)
	toggleButton.Text = "Sell Store"
	toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleButton.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.TextScaled = true
	toggleButton.Parent = screenGui

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 8)
	toggleCorner.Parent = toggleButton

	-- Main sell store frame
	local storeFrame = Instance.new("Frame")
	storeFrame.Name = "SellStoreFrame"
	storeFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	storeFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	storeFrame.Size = UDim2.new(0, 500, 0, 450)
	storeFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	storeFrame.BackgroundTransparency = 0.1
	storeFrame.Visible = false
	storeFrame.Parent = screenGui

	local storeCorner = Instance.new("UICorner")
	storeCorner.CornerRadius = UDim.new(0, 12)
	storeCorner.Parent = storeFrame

	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Position = UDim2.new(0.5, 0, 0, 10)
	titleLabel.AnchorPoint = Vector2.new(0.5, 0)
	titleLabel.Size = UDim2.new(1, -20, 0, 35)
	titleLabel.Text = "Sell Store"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.BackgroundTransparency = 1
	titleLabel.Parent = storeFrame

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
	closeButton.TextScaled = true
	closeButton.Parent = storeFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = closeButton

	-- Scrolling brainrot list
	local brainrotList = Instance.new("ScrollingFrame")
	brainrotList.Name = "BrainrotList"
	brainrotList.Position = UDim2.new(0.5, 0, 0, 50)
	brainrotList.AnchorPoint = Vector2.new(0.5, 0)
	brainrotList.Size = UDim2.new(1, -20, 1, -120)
	brainrotList.CanvasSize = UDim2.new(0, 0, 0, 0)
	brainrotList.ScrollBarThickness = 6
	brainrotList.BackgroundTransparency = 1
	brainrotList.Parent = storeFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 5)
	listLayout.Parent = brainrotList

	-- Sell All section
	local sellAllFrame = Instance.new("Frame")
	sellAllFrame.Name = "SellAllFrame"
	sellAllFrame.Position = UDim2.new(0.5, 0, 1, -60)
	sellAllFrame.AnchorPoint = Vector2.new(0.5, 1)
	sellAllFrame.Size = UDim2.new(1, -20, 0, 50)
	sellAllFrame.BackgroundTransparency = 1
	sellAllFrame.Parent = storeFrame

	local totalValueLabel = Instance.new("TextLabel")
	totalValueLabel.Name = "TotalValueLabel"
	totalValueLabel.Position = UDim2.new(0, 0, 0.5, 0)
	totalValueLabel.AnchorPoint = Vector2.new(0, 0.5)
	totalValueLabel.Size = UDim2.new(0.5, 0, 1, 0)
	totalValueLabel.Text = "Total: $0"
	totalValueLabel.TextColor3 = Color3.fromRGB(85, 255, 85)
	totalValueLabel.TextScaled = true
	totalValueLabel.Font = Enum.Font.GothamBold
	totalValueLabel.BackgroundTransparency = 1
	totalValueLabel.Parent = sellAllFrame

	local sellAllButton = Instance.new("TextButton")
	sellAllButton.Name = "SellAllButton"
	sellAllButton.Position = UDim2.new(1, 0, 0.5, 0)
	sellAllButton.AnchorPoint = Vector2.new(1, 0.5)
	sellAllButton.Size = UDim2.new(0.45, 0, 0, 40)
	sellAllButton.Text = "Sell All"
	sellAllButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	sellAllButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	sellAllButton.Font = Enum.Font.GothamBold
	sellAllButton.TextScaled = true
	sellAllButton.Parent = sellAllFrame

	local sellAllCorner = Instance.new("UICorner")
	sellAllCorner.CornerRadius = UDim.new(0, 8)
	sellAllCorner.Parent = sellAllButton

	-- Confirmation dialog
	local confirmDialog = Instance.new("Frame")
	confirmDialog.Name = "ConfirmDialog"
	confirmDialog.Position = UDim2.new(0.5, 0, 0.5, 0)
	confirmDialog.AnchorPoint = Vector2.new(0.5, 0.5)
	confirmDialog.Size = UDim2.new(0, 350, 0, 180)
	confirmDialog.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	confirmDialog.Visible = false
	confirmDialog.ZIndex = 10
	confirmDialog.Parent = screenGui

	local confirmCorner = Instance.new("UICorner")
	confirmCorner.CornerRadius = UDim.new(0, 12)
	confirmCorner.Parent = confirmDialog

	local confirmText = Instance.new("TextLabel")
	confirmText.Name = "ConfirmText"
	confirmText.Position = UDim2.new(0.5, 0, 0, 20)
	confirmText.AnchorPoint = Vector2.new(0.5, 0)
	confirmText.Size = UDim2.new(1, -20, 0, 80)
	confirmText.Text = "Sell all brainrots?"
	confirmText.TextColor3 = Color3.fromRGB(255, 255, 255)
	confirmText.TextScaled = true
	confirmText.TextWrapped = true
	confirmText.Font = Enum.Font.GothamBold
	confirmText.BackgroundTransparency = 1
	confirmText.ZIndex = 10
	confirmText.Parent = confirmDialog

	local confirmYes = Instance.new("TextButton")
	confirmYes.Name = "ConfirmYes"
	confirmYes.Position = UDim2.new(0.3, 0, 1, -20)
	confirmYes.AnchorPoint = Vector2.new(0.5, 1)
	confirmYes.Size = UDim2.new(0, 120, 0, 40)
	confirmYes.Text = "Yes, Sell All"
	confirmYes.TextColor3 = Color3.fromRGB(255, 255, 255)
	confirmYes.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	confirmYes.Font = Enum.Font.GothamBold
	confirmYes.TextScaled = true
	confirmYes.ZIndex = 10
	confirmYes.Parent = confirmDialog

	local confirmYesCorner = Instance.new("UICorner")
	confirmYesCorner.CornerRadius = UDim.new(0, 8)
	confirmYesCorner.Parent = confirmYes

	local confirmNo = Instance.new("TextButton")
	confirmNo.Name = "ConfirmNo"
	confirmNo.Position = UDim2.new(0.7, 0, 1, -20)
	confirmNo.AnchorPoint = Vector2.new(0.5, 1)
	confirmNo.Size = UDim2.new(0, 120, 0, 40)
	confirmNo.Text = "Cancel"
	confirmNo.TextColor3 = Color3.fromRGB(255, 255, 255)
	confirmNo.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	confirmNo.Font = Enum.Font.GothamBold
	confirmNo.TextScaled = true
	confirmNo.ZIndex = 10
	confirmNo.Parent = confirmDialog

	local confirmNoCorner = Instance.new("UICorner")
	confirmNoCorner.CornerRadius = UDim.new(0, 8)
	confirmNoCorner.Parent = confirmNo

	-- Feedback label for sell confirmations
	local sellFeedback = Instance.new("TextLabel")
	sellFeedback.Name = "SellFeedback"
	sellFeedback.Position = UDim2.new(0.5, 0, 0, 60)
	sellFeedback.AnchorPoint = Vector2.new(0.5, 0)
	sellFeedback.Size = UDim2.new(0, 400, 0, 30)
	sellFeedback.Text = ""
	sellFeedback.TextColor3 = Color3.fromRGB(85, 255, 85)
	sellFeedback.TextScaled = true
	sellFeedback.Font = Enum.Font.GothamBold
	sellFeedback.BackgroundTransparency = 1
	sellFeedback.TextTransparency = 1
	sellFeedback.Parent = screenGui

	-- Refresh brainrot list
	local function refreshBrainrotList()
		-- Clear existing entries (keep UIListLayout)
		for _, child in brainrotList:GetChildren() do
			if child:IsA("UIListLayout") then
				continue
			end
			child:Destroy()
		end

		local totalSellValue = 0

		if #ownedBrainrots == 0 then
			local emptyLabel = Instance.new("TextLabel")
			emptyLabel.Name = "EmptyLabel"
			emptyLabel.Size = UDim2.new(1, 0, 0, 60)
			emptyLabel.Text = "No brainrots to sell"
			emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
			emptyLabel.TextScaled = true
			emptyLabel.Font = Enum.Font.Gotham
			emptyLabel.BackgroundTransparency = 1
			emptyLabel.Parent = brainrotList
		end

		for i, brainrot in ownedBrainrots do
			local sellValue = calculateClientSellValue(brainrot)
			totalSellValue += sellValue

			local entry = Instance.new("Frame")
			entry.Name = "BrainrotEntry_" .. brainrot.id
			entry.Size = UDim2.new(1, 0, 0, 60)
			entry.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			entry.LayoutOrder = i
			entry.Parent = brainrotList

			local entryCorner = Instance.new("UICorner")
			entryCorner.CornerRadius = UDim.new(0, 8)
			entryCorner.Parent = entry

			-- Name label
			local nameParts = {}
			if brainrot.baseMutation then
				table.insert(nameParts, brainrot.baseMutation)
			end
			table.insert(nameParts, brainrot.sizeLabel)
			table.insert(nameParts, brainrot.rarity)
			table.insert(nameParts, brainrot.name)
			local nameText = table.concat(nameParts, " ")

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Name = "NameLabel"
			nameLabel.Position = UDim2.new(0, 10, 0, 5)
			nameLabel.Size = UDim2.new(0.55, 0, 0, 20)
			nameLabel.Text = nameText
			nameLabel.TextScaled = true
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.BackgroundTransparency = 1
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Parent = entry

			-- Name color
			if brainrot.baseMutation then
				local mutColor = Mutations.getBaseMutationColor(brainrot.baseMutation)
				if mutColor then
					nameLabel.TextColor3 = mutColor
				elseif Mutations.isRainbow(brainrot.baseMutation) then
					nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				end
			else
				nameLabel.TextColor3 = RARITY_COLORS[brainrot.rarity] or Color3.fromRGB(170, 170, 170)
			end

			-- Stats label
			local statsLabel = Instance.new("TextLabel")
			statsLabel.Name = "StatsLabel"
			statsLabel.Position = UDim2.new(0, 10, 0, 28)
			statsLabel.Size = UDim2.new(0.55, 0, 0, 20)
			statsLabel.Text = "+$" .. Utils.formatNumber(brainrot.earningsPerSec) .. "/sec | Sell: $" .. Utils.formatNumber(sellValue)
			statsLabel.TextColor3 = Color3.fromRGB(85, 255, 85)
			statsLabel.TextScaled = true
			statsLabel.Font = Enum.Font.Gotham
			statsLabel.BackgroundTransparency = 1
			statsLabel.TextXAlignment = Enum.TextXAlignment.Left
			statsLabel.Parent = entry

			-- Sell button
			local sellButton = Instance.new("TextButton")
			sellButton.Name = "SellButton"
			sellButton.Position = UDim2.new(1, -10, 0.5, 0)
			sellButton.AnchorPoint = Vector2.new(1, 0.5)
			sellButton.Size = UDim2.new(0, 80, 0, 35)
			sellButton.Text = "Sell"
			sellButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			sellButton.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
			sellButton.Font = Enum.Font.GothamBold
			sellButton.TextScaled = true
			sellButton.Parent = entry

			local sellBtnCorner = Instance.new("UICorner")
			sellBtnCorner.CornerRadius = UDim.new(0, 6)
			sellBtnCorner.Parent = sellButton

			sellButton.Activated:Connect(function()
				pendingSellId = brainrot.id
				SellBrainrot:FireServer({ brainrotId = brainrot.id })
			end)
		end

		totalValueLabel.Text = "Total: $" .. Utils.formatNumber(totalSellValue)
		brainrotList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end

	-- Toggle button
	toggleButton.Activated:Connect(function()
		sellStoreOpen = not sellStoreOpen
		storeFrame.Visible = sellStoreOpen
		if sellStoreOpen then
			refreshBrainrotList()
		end
		confirmDialog.Visible = false
	end)

	-- Close button
	closeButton.Activated:Connect(function()
		sellStoreOpen = false
		storeFrame.Visible = false
		confirmDialog.Visible = false
	end)

	-- Sell All button
	sellAllButton.Activated:Connect(function()
		if #ownedBrainrots == 0 then
			return
		end
		local totalValue = 0
		for _, brainrot in ownedBrainrots do
			totalValue += calculateClientSellValue(brainrot)
		end
		confirmText.Text = "Sell all " .. #ownedBrainrots .. " brainrots for $" .. Utils.formatNumber(totalValue) .. "?"
		confirmDialog.Visible = true
	end)

	-- Confirm Yes
	confirmYes.Activated:Connect(function()
		SellAll:FireServer()
		confirmDialog.Visible = false
	end)

	-- Confirm No
	confirmNo.Activated:Connect(function()
		confirmDialog.Visible = false
	end)

	-- Remote connections
	InitialData.OnClientEvent:Connect(function(data)
		ownedBrainrots = data.brainrots
		if sellStoreOpen then
			refreshBrainrotList()
		end
	end)

	BrainrotSpawned.OnClientEvent:Connect(function(data)
		table.insert(ownedBrainrots, data.brainrotData)
		if sellStoreOpen then
			refreshBrainrotList()
		end
	end)

	SellConfirmed.OnClientEvent:Connect(function(data)
		-- Update local brainrot list
		if data.soldCount == 1 and pendingSellId then
			for i, b in ownedBrainrots do
				if b.id == pendingSellId then
					table.remove(ownedBrainrots, i)
					break
				end
			end
			pendingSellId = nil
		else
			ownedBrainrots = {}
		end

		refreshBrainrotList()

		-- Show feedback
		sellFeedback.Text = "Sold " .. data.soldCount .. " brainrot(s) for $" .. Utils.formatNumber(data.totalValue)
		sellFeedback.TextTransparency = 0
		task.delay(3, function()
			sellFeedback.TextTransparency = 1
		end)
	end)
end

return SellUI
