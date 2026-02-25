local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local currentStep: number = 0
local tutorialActive: boolean = false
local tutorialGui = nil
local dialogFrame = nil
local messageLabel = nil
local nextButton = nil
local dimOverlay = nil

local TUTORIAL_STEPS = {
	{
		id = 1,
		message = "Welcome to Collect Brainrot's! Let's get your first brainrot.",
		waitFor = "dismiss",
	},
	{
		id = 2,
		message = "Here's your base! This is where your brainrots will live.",
		waitFor = "dismiss",
	},
	{
		id = 3,
		message = "Buy food to attract brainrots! Look at the Food Store at the bottom and buy Common Chow.",
		waitFor = "dismiss",
	},
	{
		id = 4,
		message = "Click to buy Common Chow!",
		waitFor = "BrainrotSpawned",
	},
	{
		id = 5,
		message = "",
		waitFor = "dismiss",
	},
	{
		id = 6,
		message = "Brainrots earn you money every second! Watch your balance grow.",
		waitFor = "dismiss",
	},
	{
		id = 7,
		message = "You're ready! Keep collecting brainrots and buy better food for rarer ones!",
		waitFor = "dismiss",
	},
}

local TutorialUI = {}

local function completeTutorial()
	tutorialActive = false

	-- Fire TutorialComplete to server
	local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
	if remotesFolder then
		local TutorialComplete = remotesFolder:FindFirstChild("TutorialComplete")
		if TutorialComplete then
			TutorialComplete:FireServer()
		end
	end

	-- Tween dialog offscreen and destroy
	if dialogFrame then
		local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local tween = TweenService:Create(dialogFrame, tweenInfo, {
			Position = UDim2.new(0.5, 0, 1.2, 0),
		})
		tween:Play()
		tween.Completed:Once(function()
			if tutorialGui and tutorialGui.Parent then
				tutorialGui:Destroy()
				tutorialGui = nil
			end
		end)
	end

	if dimOverlay then
		dimOverlay.Visible = false
	end
end

local function advanceStep()
	currentStep += 1

	if currentStep > #TUTORIAL_STEPS then
		completeTutorial()
		return
	end

	local step = TUTORIAL_STEPS[currentStep]
	messageLabel.Text = step.message

	if step.waitFor == "dismiss" then
		nextButton.Visible = true
		local conn
		conn = nextButton.Activated:Once(function()
			advanceStep()
		end)
	elseif step.waitFor == "BrainrotSpawned" then
		nextButton.Visible = false

		local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
		local BrainrotSpawned = remotesFolder:WaitForChild("BrainrotSpawned")
		local BrainrotRanAway = remotesFolder:WaitForChild("BrainrotRanAway")

		local spawnConn
		local ranAwayConn

		spawnConn = BrainrotSpawned.OnClientEvent:Once(function()
			if ranAwayConn then
				ranAwayConn:Disconnect()
			end
			-- Set step 5 message for success
			TUTORIAL_STEPS[5].message = "A brainrot appeared! It's now earning money for you!"
			advanceStep()
		end)

		ranAwayConn = BrainrotRanAway.OnClientEvent:Once(function()
			if spawnConn then
				spawnConn:Disconnect()
			end
			-- Set step 5 message for failure, then loop back to step 4
			TUTORIAL_STEPS[5].message = "It ran away! Don't worry, try buying more food."
			-- Advance to step 5 (dismiss), then after dismiss go back to step 4
			currentStep += 1 -- now at step 5
			messageLabel.Text = TUTORIAL_STEPS[5].message
			nextButton.Visible = true
			nextButton.Activated:Once(function()
				-- Loop back to step 4
				currentStep = 3 -- advanceStep will increment to 4
				advanceStep()
			end)
		end)
	end
end

local function createTutorialUI()
	tutorialGui = Instance.new("ScreenGui")
	tutorialGui.Name = "TutorialGui"
	tutorialGui.DisplayOrder = 100
	tutorialGui.ResetOnSpawn = false
	tutorialGui.Parent = playerGui

	-- Dim overlay
	dimOverlay = Instance.new("Frame")
	dimOverlay.Name = "DimOverlay"
	dimOverlay.Size = UDim2.new(1, 0, 1, 0)
	dimOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	dimOverlay.BackgroundTransparency = 0.6
	dimOverlay.Visible = true
	dimOverlay.ZIndex = 90
	dimOverlay.Parent = tutorialGui

	-- Dialog frame at bottom-center
	dialogFrame = Instance.new("Frame")
	dialogFrame.Name = "DialogFrame"
	dialogFrame.Position = UDim2.new(0.5, 0, 0.85, 0)
	dialogFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	dialogFrame.Size = UDim2.new(0.5, 0, 0, 120)
	dialogFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	dialogFrame.BackgroundTransparency = 0.1
	dialogFrame.ZIndex = 100
	dialogFrame.Parent = tutorialGui

	local dialogCorner = Instance.new("UICorner")
	dialogCorner.CornerRadius = UDim.new(0, 16)
	dialogCorner.Parent = dialogFrame

	local dialogStroke = Instance.new("UIStroke")
	dialogStroke.Color = Color3.fromRGB(85, 170, 255)
	dialogStroke.Thickness = 2
	dialogStroke.Parent = dialogFrame

	-- Message label
	messageLabel = Instance.new("TextLabel")
	messageLabel.Name = "MessageLabel"
	messageLabel.Position = UDim2.new(0.5, 0, 0, 15)
	messageLabel.AnchorPoint = Vector2.new(0.5, 0)
	messageLabel.Size = UDim2.new(1, -30, 0, 55)
	messageLabel.Text = ""
	messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	messageLabel.TextScaled = true
	messageLabel.TextWrapped = true
	messageLabel.Font = Enum.Font.GothamBold
	messageLabel.BackgroundTransparency = 1
	messageLabel.ZIndex = 101
	messageLabel.Parent = dialogFrame

	-- Next button
	nextButton = Instance.new("TextButton")
	nextButton.Name = "NextButton"
	nextButton.Position = UDim2.new(0.5, 0, 1, -15)
	nextButton.AnchorPoint = Vector2.new(0.5, 1)
	nextButton.Size = UDim2.new(0, 120, 0, 35)
	nextButton.Text = "Next"
	nextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	nextButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
	nextButton.Font = Enum.Font.GothamBold
	nextButton.TextScaled = true
	nextButton.ZIndex = 101
	nextButton.Parent = dialogFrame

	local nextCorner = Instance.new("UICorner")
	nextCorner.CornerRadius = UDim.new(0, 8)
	nextCorner.Parent = nextButton

	-- Skip button (top-right of screen)
	local skipButton = Instance.new("TextButton")
	skipButton.Name = "SkipButton"
	skipButton.Position = UDim2.new(1, -15, 0, 15)
	skipButton.AnchorPoint = Vector2.new(1, 0)
	skipButton.Size = UDim2.new(0, 80, 0, 30)
	skipButton.Text = "Skip"
	skipButton.TextColor3 = Color3.fromRGB(200, 200, 200)
	skipButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	skipButton.BackgroundTransparency = 0.3
	skipButton.Font = Enum.Font.Gotham
	skipButton.TextScaled = true
	skipButton.ZIndex = 101
	skipButton.Parent = tutorialGui

	local skipCorner = Instance.new("UICorner")
	skipCorner.CornerRadius = UDim.new(0, 6)
	skipCorner.Parent = skipButton

	skipButton.Activated:Connect(function()
		completeTutorial()
	end)
end

function TutorialUI.Init()
	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
	local InitialData = remotesFolder:WaitForChild("InitialData")

	InitialData.OnClientEvent:Connect(function(data)
		if data.tutorialComplete == true then
			return
		end

		-- First-time player: start tutorial
		createTutorialUI()
		tutorialActive = true
		advanceStep()
	end)
end

return TutorialUI
