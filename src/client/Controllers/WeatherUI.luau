local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local Weather = require(ReplicatedStorage.Shared.Config.Weather)

local player = Players.LocalPlayer

local currentWeather: string = "Clear"
local weatherEndTime: number = 0
local activeEffects = {}
local bannerFrame = nil
local bannerLabel = nil
local countdownLabel = nil
local descriptionLabel = nil
local activeSound: Sound? = nil

local WEATHER_COLORS = {
	Clear = Color3.fromRGB(255, 255, 200),
	Rain = Color3.fromRGB(100, 150, 255),
	Snow = Color3.fromRGB(200, 220, 255),
	Storm = Color3.fromRGB(255, 255, 100),
	["Meteor Shower"] = Color3.fromRGB(255, 160, 50),
	["Solar Flare"] = Color3.fromRGB(255, 100, 30),
	Nuclear = Color3.fromRGB(100, 255, 50),
	["Black Hole"] = Color3.fromRGB(180, 50, 255),
}

local WeatherUI = {}

local function getWeatherColor(weatherType: string): Color3
	return WEATHER_COLORS[weatherType] or Color3.fromRGB(255, 255, 255)
end

-- ============================================================
-- SOUND SYSTEM
-- ============================================================

local function stopWeatherSound()
	if activeSound then
		activeSound:Stop()
		activeSound:Destroy()
		activeSound = nil
	end
end

local function playWeatherSound(id: number, volume: number, pitch: number, looped: boolean)
	stopWeatherSound()

	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. tostring(id)
	sound.Volume = volume
	sound.PlaybackSpeed = pitch
	sound.Looped = looped
	sound.Name = "WeatherSound"
	sound.Parent = SoundService
	sound:Play()

	activeSound = sound
end

-- ============================================================
-- CLEANUP
-- ============================================================

local function clearAllEffects()
	stopWeatherSound()

	for _, effect in activeEffects do
		if effect and effect.Parent then
			effect:Destroy()
		end
	end
	table.clear(activeEffects)

	Lighting.Ambient = Color3.fromRGB(127, 127, 127)
	Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
	Lighting.Brightness = 2
	Lighting.FogEnd = 100000
	Lighting.FogColor = Color3.fromRGB(192, 192, 192)

	for _, child in Lighting:GetChildren() do
		if child.Name == "WeatherEffect" then
			child:Destroy()
		end
	end

	-- Clean up any stray weather parts in workspace
	for _, child in workspace:GetChildren() do
		if
			child.Name == "WeatherEffect"
			or child.Name == "LightningBolt"
			or child.Name == "MeteorPart"
			or child.Name == "BlackHoleSphere"
			or child.Name == "AccretionDisk"
		then
			child:Destroy()
		end
	end
end

-- Helper: create an emitter part at a given Y offset from camera
local function makeEmitterPart(size: Vector3, yOffset: number)
	local part = Instance.new("Part")
	part.Name = "WeatherEffect"
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Size = size
	part.Position = workspace.CurrentCamera.CFrame.Position + Vector3.new(0, yOffset, 0)
	part.Parent = workspace
	table.insert(activeEffects, part)
	return part
end

-- ============================================================
-- RAIN — Heavy downpour with angled wind rain + ground splashes
-- ============================================================
local function applyRainEffects()
	Lighting.Ambient = Color3.fromRGB(55, 55, 75)
	Lighting.Brightness = 0.5
	Lighting.FogEnd = 180
	Lighting.FogColor = Color3.fromRGB(90, 95, 110)

	-- Blue tint color correction
	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = "WeatherEffect"
	colorCorrection.TintColor = Color3.fromRGB(170, 190, 255)
	colorCorrection.Saturation = -0.15
	colorCorrection.Parent = Lighting
	table.insert(activeEffects, colorCorrection)

	-- Main rain — angled to simulate wind
	local rainPart = makeEmitterPart(Vector3.new(200, 1, 200), 70)
	-- Tilt the part so emission goes at an angle (wind from one side)
	rainPart.CFrame = rainPart.CFrame * CFrame.Angles(0, 0, math.rad(15))

	local rain = Instance.new("ParticleEmitter")
	rain.Rate = 4000
	rain.Lifetime = NumberRange.new(0.6, 1.2)
	rain.Speed = NumberRange.new(80, 120)
	rain.SpreadAngle = Vector2.new(10, 10)
	rain.EmissionDirection = Enum.NormalId.Bottom
	rain.Color = ColorSequence.new(Color3.fromRGB(140, 170, 255))
	rain.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(1, 0.15),
	})
	rain.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.0),
		NumberSequenceKeypoint.new(1, 0.5),
	})
	rain.LightEmission = 0.05
	rain.Parent = rainPart

	-- Ground splash
	local splashPart = makeEmitterPart(Vector3.new(200, 1, 200), 0.3)
	local splash = Instance.new("ParticleEmitter")
	splash.Rate = 400
	splash.Lifetime = NumberRange.new(0.15, 0.4)
	splash.Speed = NumberRange.new(3, 8)
	splash.SpreadAngle = Vector2.new(180, 180)
	splash.EmissionDirection = Enum.NormalId.Top
	splash.Color = ColorSequence.new(Color3.fromRGB(180, 200, 255))
	splash.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	splash.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	splash.Parent = splashPart

	playWeatherSound(184352854, 0.6, 1.0, true)
end

-- ============================================================
-- SNOW — Blizzard of big snowflakes (10x previous)
-- ============================================================
local function applySnowEffects()
	Lighting.Ambient = Color3.fromRGB(75, 85, 120)
	Lighting.Brightness = 1.1
	Lighting.FogEnd = 200
	Lighting.FogColor = Color3.fromRGB(180, 190, 215)

	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = "WeatherEffect"
	colorCorrection.TintColor = Color3.fromRGB(180, 200, 255)
	colorCorrection.Saturation = -0.3
	colorCorrection.Parent = Lighting
	table.insert(activeEffects, colorCorrection)

	local snowPart = makeEmitterPart(Vector3.new(200, 1, 200), 70)
	local snow = Instance.new("ParticleEmitter")
	snow.Rate = 3000
	snow.Lifetime = NumberRange.new(4, 8)
	snow.Speed = NumberRange.new(5, 20)
	snow.SpreadAngle = Vector2.new(90, 90)
	snow.EmissionDirection = Enum.NormalId.Bottom
	snow.Color = ColorSequence.new(Color3.fromRGB(240, 245, 255))
	snow.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.2),
		NumberSequenceKeypoint.new(1, 0.4),
	})
	snow.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.8, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	snow.RotSpeed = NumberRange.new(-150, 150)
	snow.LightEmission = 0.3
	snow.Parent = snowPart

	playWeatherSound(184352854, 0.25, 1.0, true)
end

-- ============================================================
-- STORM — Torrential sideways rain + lightning BOLT Parts + shake
-- ============================================================

local function spawnLightningBolt()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local camPos = camera.CFrame.Position
	local baseX = camPos.X + math.random(-80, 80)
	local baseZ = camPos.Z + math.random(-80, 80)

	local segments = math.random(6, 8)
	local segmentHeight = 80 / segments
	local boltParts = {}

	local currentX = baseX
	local currentZ = baseZ

	for i = 1, segments do
		local startY = 80 - (i - 1) * segmentHeight
		local endY = 80 - i * segmentHeight

		local nextX = currentX + math.random(-5, 5)
		local nextZ = currentZ + math.random(-5, 5)

		local startPos = Vector3.new(currentX, startY, currentZ)
		local endPos = Vector3.new(nextX, endY, nextZ)
		local midPoint = (startPos + endPos) / 2
		local direction = endPos - startPos
		local length = direction.Magnitude

		local part = Instance.new("Part")
		part.Name = "LightningBolt"
		part.Anchored = true
		part.CanCollide = false
		part.Material = Enum.Material.Neon
		part.Color = Color3.fromRGB(200, 220, 255)
		part.Size = Vector3.new(0.5, length, 0.5)
		part.CFrame = CFrame.lookAt(midPoint, endPos) * CFrame.Angles(math.rad(-90), 0, 0)
		part.Parent = workspace
		table.insert(boltParts, part)

		currentX = nextX
		currentZ = nextZ
	end

	-- Ground illumination at impact point
	local impactPos = Vector3.new(currentX, 2, currentZ)
	local lightPart = Instance.new("Part")
	lightPart.Name = "LightningBolt"
	lightPart.Anchored = true
	lightPart.CanCollide = false
	lightPart.Transparency = 1
	lightPart.Size = Vector3.new(1, 1, 1)
	lightPart.Position = impactPos
	lightPart.Parent = workspace

	local pointLight = Instance.new("PointLight")
	pointLight.Color = Color3.fromRGB(200, 220, 255)
	pointLight.Range = 40
	pointLight.Brightness = 8
	pointLight.Parent = lightPart
	table.insert(boltParts, lightPart)

	-- Subtle brightness bump during strike
	local flash = Instance.new("ColorCorrectionEffect")
	flash.Name = "WeatherEffect"
	flash.Brightness = 0.5
	flash.Parent = Lighting

	-- Destroy everything after 0.15 seconds
	task.delay(0.15, function()
		for _, p in boltParts do
			if p and p.Parent then
				p:Destroy()
			end
		end
		if flash and flash.Parent then
			flash:Destroy()
		end
	end)
end

local function applyStormEffects()
	Lighting.Ambient = Color3.fromRGB(15, 15, 30)
	Lighting.Brightness = 0.2
	Lighting.FogEnd = 120
	Lighting.FogColor = Color3.fromRGB(30, 30, 50)

	-- Torrential angled rain
	local stormPart = makeEmitterPart(Vector3.new(200, 1, 200), 70)
	stormPart.CFrame = stormPart.CFrame * CFrame.Angles(0, 0, math.rad(25))

	local rain = Instance.new("ParticleEmitter")
	rain.Rate = 5000
	rain.Lifetime = NumberRange.new(0.3, 0.7)
	rain.Speed = NumberRange.new(100, 160)
	rain.SpreadAngle = Vector2.new(15, 15)
	rain.EmissionDirection = Enum.NormalId.Bottom
	rain.Color = ColorSequence.new(Color3.fromRGB(150, 160, 200))
	rain.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 0.15),
	})
	rain.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(1, 0.4),
	})
	rain.Parent = stormPart

	-- Ground splash
	local splashPart = makeEmitterPart(Vector3.new(200, 1, 200), 0.3)
	local splash = Instance.new("ParticleEmitter")
	splash.Rate = 800
	splash.Lifetime = NumberRange.new(0.1, 0.3)
	splash.Speed = NumberRange.new(4, 10)
	splash.SpreadAngle = Vector2.new(180, 180)
	splash.EmissionDirection = Enum.NormalId.Top
	splash.Color = ColorSequence.new(Color3.fromRGB(160, 170, 200))
	splash.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(1, 0),
	})
	splash.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	splash.Parent = splashPart

	-- Lightning bolts + reduced camera shake
	task.spawn(function()
		while currentWeather == "Storm" do
			task.wait(1.5 + math.random() * 2.5)
			if currentWeather ~= "Storm" then
				break
			end

			spawnLightningBolt()

			-- Reduced camera shake (6 iterations instead of 12)
			local camera = workspace.CurrentCamera
			if camera then
				local originalCFrame = camera.CFrame
				for _ = 1, 6 do
					local shakeOffset = Vector3.new(math.random(-10, 10) / 12, math.random(-10, 10) / 15, 0)
					camera.CFrame = originalCFrame * CFrame.new(shakeOffset)
					task.wait(0.02)
				end
				camera.CFrame = originalCFrame
			end
		end
	end)

	playWeatherSound(4305545740, 0.7, 1.0, true)
end

-- ============================================================
-- METEOR SHOWER — Actual Part meteors falling + explosions
-- ============================================================

local function spawnMeteor()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local camPos = camera.CFrame.Position
	local targetX = camPos.X + math.random(-120, 120)
	local targetZ = camPos.Z + math.random(-120, 120)

	-- Create meteor Part
	local meteor = Instance.new("Part")
	meteor.Name = "MeteorPart"
	meteor.Anchored = true
	meteor.CanCollide = false
	meteor.Material = Enum.Material.Neon
	meteor.Color = Color3.fromRGB(255, 140, 30)
	meteor.Size = Vector3.new(3, 3, 3)
	meteor.Shape = Enum.PartType.Ball
	meteor.Position = Vector3.new(targetX + math.random(-30, 30), 100, targetZ + math.random(-30, 30))
	meteor.Parent = workspace

	-- Fire trail
	local fire = Instance.new("Fire")
	fire.Size = 5
	fire.Heat = 10
	fire.Color = Color3.fromRGB(255, 170, 30)
	fire.SecondaryColor = Color3.fromRGB(255, 80, 0)
	fire.Parent = meteor

	-- Smoke trail
	local smoke = Instance.new("Smoke")
	smoke.Size = 3
	smoke.Opacity = 0.5
	smoke.Color = Color3.fromRGB(80, 60, 40)
	smoke.RiseVelocity = 2
	smoke.Parent = meteor

	-- Tween to ground
	local fallTime = 1.0 + math.random() * 0.5
	local groundPos = Vector3.new(targetX, 2, targetZ)
	local tweenInfo = TweenInfo.new(fallTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local tween = TweenService:Create(meteor, tweenInfo, { Position = groundPos })
	tween:Play()

	tween.Completed:Connect(function()
		if not meteor or not meteor.Parent then
			return
		end

		-- Visual-only explosion
		local explosion = Instance.new("Explosion")
		explosion.Position = groundPos
		explosion.BlastRadius = 10
		explosion.BlastPressure = 0
		explosion.DestroyJointRadiusPercent = 0
		explosion.Parent = workspace

		-- Small camera shake on impact (4 iterations)
		local cam = workspace.CurrentCamera
		if cam and currentWeather == "Meteor Shower" then
			task.spawn(function()
				local originalCFrame = cam.CFrame
				for _ = 1, 4 do
					local shakeOffset = Vector3.new(math.random(-10, 10) / 15, math.random(-5, 5) / 15, 0)
					cam.CFrame = originalCFrame * CFrame.new(shakeOffset)
					task.wait(0.025)
				end
				cam.CFrame = originalCFrame
			end)
		end

		-- Destroy meteor after brief delay
		task.delay(0.3, function()
			if meteor and meteor.Parent then
				meteor:Destroy()
			end
		end)
	end)
end

local function applyMeteorShowerEffects()
	Lighting.Ambient = Color3.fromRGB(160, 90, 30)
	Lighting.Brightness = 2.0
	Lighting.FogEnd = 500
	Lighting.FogColor = Color3.fromRGB(160, 100, 50)

	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = "WeatherEffect"
	colorCorrection.TintColor = Color3.fromRGB(255, 170, 100)
	colorCorrection.Contrast = 0.15
	colorCorrection.Parent = Lighting
	table.insert(activeEffects, colorCorrection)

	-- Ground fire impacts (ambient)
	local firePart = makeEmitterPart(Vector3.new(250, 1, 250), 0.5)
	local fire = Instance.new("ParticleEmitter")
	fire.Rate = 100
	fire.Lifetime = NumberRange.new(0.5, 2)
	fire.Speed = NumberRange.new(8, 25)
	fire.SpreadAngle = Vector2.new(180, 180)
	fire.EmissionDirection = Enum.NormalId.Top
	fire.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 100)),
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 150, 20)),
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(255, 60, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 20, 0)),
	})
	fire.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 5),
		NumberSequenceKeypoint.new(0.3, 4),
		NumberSequenceKeypoint.new(1, 0),
	})
	fire.LightEmission = 1
	fire.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	fire.Parent = firePart

	-- Smoke from impacts (ambient)
	local smokePart = makeEmitterPart(Vector3.new(250, 1, 250), 0.5)
	local smoke = Instance.new("ParticleEmitter")
	smoke.Rate = 60
	smoke.Lifetime = NumberRange.new(2, 4)
	smoke.Speed = NumberRange.new(3, 10)
	smoke.SpreadAngle = Vector2.new(180, 180)
	smoke.EmissionDirection = Enum.NormalId.Top
	smoke.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 60, 40)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 40, 30)),
	})
	smoke.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 3),
		NumberSequenceKeypoint.new(1, 8),
	})
	smoke.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	smoke.Parent = smokePart

	-- Spawn actual meteor Parts periodically
	task.spawn(function()
		while currentWeather == "Meteor Shower" do
			task.wait(0.8 + math.random() * 1.2)
			if currentWeather ~= "Meteor Shower" then
				break
			end
			spawnMeteor()
		end
	end)

	playWeatherSound(3636730677, 0.5, 1.0, true)
end

-- ============================================================
-- SOLAR FLARE — Blinding heat, intense shimmer, ground flames
-- ============================================================
local function applySolarFlareEffects()
	Lighting.Ambient = Color3.fromRGB(200, 140, 40)
	Lighting.Brightness = 4.5
	Lighting.FogEnd = 300
	Lighting.FogColor = Color3.fromRGB(255, 200, 80)

	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = "WeatherEffect"
	colorCorrection.TintColor = Color3.fromRGB(255, 150, 60)
	colorCorrection.Saturation = 0.5
	colorCorrection.Brightness = 0.3
	colorCorrection.Parent = Lighting
	table.insert(activeEffects, colorCorrection)

	-- Heat shimmer blur
	local blur = Instance.new("BlurEffect")
	blur.Name = "WeatherEffect"
	blur.Size = 0
	blur.Parent = Lighting
	table.insert(activeEffects, blur)

	-- Heat wave particles rising from ground
	local heatPart = makeEmitterPart(Vector3.new(200, 1, 200), 0.5)
	local heat = Instance.new("ParticleEmitter")
	heat.Rate = 150
	heat.Lifetime = NumberRange.new(1.5, 3)
	heat.Speed = NumberRange.new(5, 15)
	heat.SpreadAngle = Vector2.new(80, 80)
	heat.EmissionDirection = Enum.NormalId.Top
	heat.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 80)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 150, 30)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 80, 0)),
	})
	heat.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 3),
		NumberSequenceKeypoint.new(1, 0),
	})
	heat.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	heat.LightEmission = 0.9
	heat.Parent = heatPart

	-- Sun beams from above
	local sunPart = makeEmitterPart(Vector3.new(100, 1, 100), 80)
	local sun = Instance.new("ParticleEmitter")
	sun.Rate = 20
	sun.Lifetime = NumberRange.new(1, 2)
	sun.Speed = NumberRange.new(40, 60)
	sun.SpreadAngle = Vector2.new(15, 15)
	sun.EmissionDirection = Enum.NormalId.Bottom
	sun.Color = ColorSequence.new(Color3.fromRGB(255, 230, 100))
	sun.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 8),
		NumberSequenceKeypoint.new(1, 2),
	})
	sun.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	sun.LightEmission = 1
	sun.Parent = sunPart

	-- Oscillating blur shimmer
	task.spawn(function()
		while currentWeather == "Solar Flare" do
			local tweenIn = TweenService:Create(blur, TweenInfo.new(0.8, Enum.EasingStyle.Sine), { Size = 12 })
			tweenIn:Play()
			tweenIn.Completed:Wait()
			if currentWeather ~= "Solar Flare" then
				break
			end
			local tweenOut = TweenService:Create(blur, TweenInfo.new(0.8, Enum.EasingStyle.Sine), { Size = 4 })
			tweenOut:Play()
			tweenOut.Completed:Wait()
		end
	end)

	playWeatherSound(184352854, 0.35, 1.5, true)
end

-- ============================================================
-- NUCLEAR — Eerie green fog, radiation, falling ash
-- ============================================================
local function applyNuclearEffects()
	Lighting.Ambient = Color3.fromRGB(30, 90, 15)
	Lighting.Brightness = 0.4
	Lighting.FogEnd = 100
	Lighting.FogColor = Color3.fromRGB(50, 90, 30)

	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = "WeatherEffect"
	colorCorrection.TintColor = Color3.fromRGB(100, 255, 60)
	colorCorrection.Saturation = -0.5
	colorCorrection.Contrast = 0.4
	colorCorrection.Parent = Lighting
	table.insert(activeEffects, colorCorrection)

	-- Thick radiation particles rising
	local radPart = makeEmitterPart(Vector3.new(200, 1, 200), 0.5)
	local rad = Instance.new("ParticleEmitter")
	rad.Rate = 200
	rad.Lifetime = NumberRange.new(2, 5)
	rad.Speed = NumberRange.new(4, 12)
	rad.SpreadAngle = Vector2.new(180, 180)
	rad.EmissionDirection = Enum.NormalId.Top
	rad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 255, 20)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40, 200, 10)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 80, 5)),
	})
	rad.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 3),
		NumberSequenceKeypoint.new(0.5, 2),
		NumberSequenceKeypoint.new(1, 0),
	})
	rad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	rad.LightEmission = 0.9
	rad.Parent = radPart

	-- Falling ash/debris
	local ashPart = makeEmitterPart(Vector3.new(200, 1, 200), 60)
	local ash = Instance.new("ParticleEmitter")
	ash.Rate = 150
	ash.Lifetime = NumberRange.new(3, 7)
	ash.Speed = NumberRange.new(3, 10)
	ash.SpreadAngle = Vector2.new(70, 70)
	ash.EmissionDirection = Enum.NormalId.Bottom
	ash.Color = ColorSequence.new(Color3.fromRGB(70, 70, 50))
	ash.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.0),
		NumberSequenceKeypoint.new(1, 0.4),
	})
	ash.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	ash.RotSpeed = NumberRange.new(-80, 80)
	ash.Parent = ashPart

	-- Slight blur for haze
	local blur = Instance.new("BlurEffect")
	blur.Name = "WeatherEffect"
	blur.Size = 4
	blur.Parent = Lighting
	table.insert(activeEffects, blur)

	playWeatherSound(6456981311, 0.6, 1.0, true)
end

-- ============================================================
-- BLACK HOLE — Dark void, sphere + accretion disk, vortex, debris
-- ============================================================
local function applyBlackHoleEffects()
	Lighting.Ambient = Color3.fromRGB(10, 3, 25)
	Lighting.Brightness = 0.3
	Lighting.FogEnd = 200
	Lighting.FogColor = Color3.fromRGB(10, 3, 20)

	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = "WeatherEffect"
	colorCorrection.TintColor = Color3.fromRGB(100, 40, 255)
	colorCorrection.Saturation = -0.7
	colorCorrection.Contrast = 0.3
	colorCorrection.Brightness = 0
	colorCorrection.Parent = Lighting
	table.insert(activeEffects, colorCorrection)

	-- Reduced distortion
	local blur = Instance.new("BlurEffect")
	blur.Name = "WeatherEffect"
	blur.Size = 5
	blur.Parent = Lighting
	table.insert(activeEffects, blur)

	-- ---- Actual black hole sphere ----
	local camera = workspace.CurrentCamera
	local camCF = camera.CFrame
	local spherePos = camCF.Position + Vector3.new(0, 150, 0) + camCF.LookVector * 50

	local sphere = Instance.new("Part")
	sphere.Name = "BlackHoleSphere"
	sphere.Anchored = true
	sphere.CanCollide = false
	sphere.Shape = Enum.PartType.Ball
	sphere.Size = Vector3.new(30, 30, 30)
	sphere.Material = Enum.Material.SmoothPlastic
	sphere.Color = Color3.fromRGB(5, 0, 10)
	sphere.Position = spherePos
	sphere.Parent = workspace
	table.insert(activeEffects, sphere)

	-- Dim purple glow on sphere
	local sphereLight = Instance.new("PointLight")
	sphereLight.Color = Color3.fromRGB(120, 40, 200)
	sphereLight.Range = 40
	sphereLight.Brightness = 1
	sphereLight.Parent = sphere

	-- ---- Accretion disk (thin cylinder ring) ----
	local disk = Instance.new("Part")
	disk.Name = "AccretionDisk"
	disk.Anchored = true
	disk.CanCollide = false
	disk.Shape = Enum.PartType.Cylinder
	disk.Size = Vector3.new(1, 60, 60)
	disk.Material = Enum.Material.Neon
	disk.Color = Color3.fromRGB(160, 50, 220)
	disk.Position = spherePos
	-- Orient cylinder horizontally (cylinder axis is X, so rotate to make it flat)
	disk.CFrame = CFrame.new(spherePos) * CFrame.Angles(0, 0, math.rad(90))
	disk.Parent = workspace
	table.insert(activeEffects, disk)

	-- Purple glow on accretion disk
	local diskLight = Instance.new("PointLight")
	diskLight.Color = Color3.fromRGB(160, 50, 220)
	diskLight.Range = 60
	diskLight.Brightness = 2
	diskLight.Parent = disk

	-- Slowly rotate the accretion disk
	task.spawn(function()
		while currentWeather == "Black Hole" and disk and disk.Parent do
			disk.CFrame = disk.CFrame * CFrame.Angles(0, math.rad(1), 0)
			task.wait(0.03)
		end
	end)

	-- Vortex particles overhead
	local vortexPart = makeEmitterPart(Vector3.new(1, 1, 1), 50)
	local vortex = Instance.new("ParticleEmitter")
	vortex.Rate = 250
	vortex.Lifetime = NumberRange.new(1, 3)
	vortex.Speed = NumberRange.new(20, 50)
	vortex.SpreadAngle = Vector2.new(360, 360)
	vortex.EmissionDirection = Enum.NormalId.Top
	vortex.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 100, 255)),
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(140, 30, 230)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 0, 60)),
	})
	vortex.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 8),
		NumberSequenceKeypoint.new(0.5, 4),
		NumberSequenceKeypoint.new(1, 0),
	})
	vortex.LightEmission = 1.0
	vortex.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	vortex.RotSpeed = NumberRange.new(250, 500)
	vortex.Parent = vortexPart

	-- Debris pulled upward from ground
	local debrisPart = makeEmitterPart(Vector3.new(250, 1, 250), 0.5)
	local debris = Instance.new("ParticleEmitter")
	debris.Rate = 100
	debris.Lifetime = NumberRange.new(2, 4)
	debris.Speed = NumberRange.new(15, 35)
	debris.SpreadAngle = Vector2.new(50, 50)
	debris.EmissionDirection = Enum.NormalId.Top
	debris.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 70, 180)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 20, 100)),
	})
	debris.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2),
		NumberSequenceKeypoint.new(1, 0),
	})
	debris.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	debris.LightEmission = 0.6
	debris.RotSpeed = NumberRange.new(-200, 200)
	debris.Parent = debrisPart

	-- Camera pull toward vortex
	task.spawn(function()
		while currentWeather == "Black Hole" do
			local cam = workspace.CurrentCamera
			if cam then
				local pullDirection = (vortexPart.Position - cam.CFrame.Position).Unit
				cam.CFrame = cam.CFrame * CFrame.new(pullDirection * 0.04)
			end
			task.wait(0.03)
		end
	end)

	playWeatherSound(184352854, 0.7, 0.3, true)
end

local WEATHER_EFFECT_FUNCTIONS = {
	Rain = applyRainEffects,
	Snow = applySnowEffects,
	Storm = applyStormEffects,
	["Meteor Shower"] = applyMeteorShowerEffects,
	["Solar Flare"] = applySolarFlareEffects,
	Nuclear = applyNuclearEffects,
	["Black Hole"] = applyBlackHoleEffects,
}

local function applyWeatherEffects(weatherType: string)
	clearAllEffects()
	local effectFunc = WEATHER_EFFECT_FUNCTIONS[weatherType]
	if effectFunc then
		effectFunc()
	end
end

-- ============================================================
-- BANNER UI (below money/upgrade buttons)
-- ============================================================

local function createBannerUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "WeatherUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 5
	screenGui.Parent = player.PlayerGui

	bannerFrame = Instance.new("Frame")
	bannerFrame.Name = "WeatherBanner"
	bannerFrame.Size = UDim2.new(0.4, 0, 0, 80)
	bannerFrame.Position = UDim2.new(0.3, 0, 0, -100)
	bannerFrame.AnchorPoint = Vector2.new(0, 0)
	bannerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	bannerFrame.BackgroundTransparency = 0.3
	bannerFrame.BorderSizePixel = 0
	bannerFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = bannerFrame

	bannerLabel = Instance.new("TextLabel")
	bannerLabel.Name = "WeatherName"
	bannerLabel.Size = UDim2.new(1, -20, 0, 30)
	bannerLabel.Position = UDim2.new(0, 10, 0, 5)
	bannerLabel.BackgroundTransparency = 1
	bannerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	bannerLabel.TextScaled = true
	bannerLabel.Font = Enum.Font.GothamBold
	bannerLabel.Text = ""
	bannerLabel.Parent = bannerFrame

	countdownLabel = Instance.new("TextLabel")
	countdownLabel.Name = "Countdown"
	countdownLabel.Size = UDim2.new(1, -20, 0, 20)
	countdownLabel.Position = UDim2.new(0, 10, 0, 32)
	countdownLabel.BackgroundTransparency = 1
	countdownLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	countdownLabel.TextScaled = true
	countdownLabel.Font = Enum.Font.Gotham
	countdownLabel.Text = ""
	countdownLabel.Parent = bannerFrame

	descriptionLabel = Instance.new("TextLabel")
	descriptionLabel.Name = "Description"
	descriptionLabel.Size = UDim2.new(1, -20, 0, 18)
	descriptionLabel.Position = UDim2.new(0, 10, 0, 54)
	descriptionLabel.BackgroundTransparency = 1
	descriptionLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
	descriptionLabel.TextScaled = true
	descriptionLabel.Font = Enum.Font.Gotham
	descriptionLabel.Text = ""
	descriptionLabel.Parent = bannerFrame
end

local function showBanner(weatherType: string)
	local event = Weather.getEvent(weatherType)
	if not event then
		return
	end

	bannerLabel.Text = weatherType
	descriptionLabel.Text = event.description
	bannerLabel.TextColor3 = getWeatherColor(weatherType)

	local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(bannerFrame, tweenInfo, { Position = UDim2.new(0.3, 0, 0, 110) }):Play()
end

local function hideBanner()
	local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	TweenService:Create(bannerFrame, tweenInfo, { Position = UDim2.new(0.3, 0, 0, -100) }):Play()
end

-- ============================================================
-- HANDLERS
-- ============================================================

local function onWeatherChanged(data)
	currentWeather = data.weather
	weatherEndTime = data.endTime

	if data.weather == "Clear" then
		hideBanner()
		clearAllEffects()
	else
		showBanner(data.weather)
		applyWeatherEffects(data.weather)
	end
end

local function updateCountdown()
	if currentWeather == "Clear" or weatherEndTime == 0 then
		return
	end

	local remaining = math.max(0, math.ceil(weatherEndTime - os.clock()))
	if countdownLabel then
		if remaining > 0 then
			local minutes = math.floor(remaining / 60)
			local seconds = remaining % 60
			if minutes > 0 then
				countdownLabel.Text = string.format("Time remaining: %d:%02d", minutes, seconds)
			else
				countdownLabel.Text = string.format("Time remaining: %ds", seconds)
			end
		else
			countdownLabel.Text = "Ending..."
		end
	end

	-- Move weather particle Parts to follow camera
	for _, effect in activeEffects do
		if effect:IsA("Part") and effect.Name == "WeatherEffect" then
			local cam = workspace.CurrentCamera
			if cam then
				local yPos = effect.Position.Y
				effect.Position = Vector3.new(cam.CFrame.Position.X, yPos, cam.CFrame.Position.Z)
			end
		end
	end
end

function WeatherUI.Init()
	createBannerUI()

	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
	local WeatherChanged = remotesFolder:WaitForChild("WeatherChanged")

	WeatherChanged.OnClientEvent:Connect(onWeatherChanged)
	RunService.RenderStepped:Connect(updateCountdown)
end

return WeatherUI
