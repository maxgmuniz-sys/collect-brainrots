local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Weather = require(ReplicatedStorage.Shared.Config.Weather)
local DataService = require(ServerScriptService.Server.Services.DataService)
local EarningsService = require(ServerScriptService.Server.Services.EarningsService)
local Remotes = require(ServerScriptService.Server.Remotes)

local currentWeather: string = "Clear"
local weatherEndTime: number = 0
local isRunning: boolean = false

local WeatherService = {}

local function rollWeatherType(): string
	local totalWeight = 0
	for _, name in Weather.WEATHER_ORDER do
		local event = Weather.getEvent(name)
		if event then
			totalWeight += event.spawnWeight
		end
	end

	local roll = math.random() * totalWeight
	for _, name in Weather.WEATHER_ORDER do
		local event = Weather.getEvent(name)
		if event then
			roll -= event.spawnWeight
			if roll <= 0 then
				return name
			end
		end
	end

	return "Clear"
end

local function rollDuration(weatherType: string): number
	local event = Weather.getEvent(weatherType)
	if not event or event.minDuration == 0 then
		return 0
	end
	return math.random(event.minDuration, event.maxDuration)
end

local function applyWeatherMutations(weatherType: string)
	local event = Weather.getEvent(weatherType)
	if not event or not event.mutation then
		return
	end

	for _, player in Players:GetPlayers() do
		local data = DataService.getData(player)
		if not data then
			continue
		end

		local anyMutated = false
		for _, brainrot in data.ownedBrainrots do
			if brainrot.weatherMutation ~= nil then
				continue
			end

			if math.random() < event.mutationChance then
				brainrot.weatherMutation = event.mutation
				anyMutated = true

				Remotes.BrainrotMutated:FireClient(player, {
					brainrotId = brainrot.id,
					weatherMutation = event.mutation,
				})
			end
		end

		if anyMutated then
			EarningsService.recalculate(player)
		end
	end
end

-- TODO: Set TEST_MODE = false for production. When true, cycles through all weather types sequentially.
local TEST_MODE = false
local TEST_DURATION = 15

local function weatherCycleTest()
	-- Sequential: show each non-Clear weather for TEST_DURATION seconds
	local testOrder = { "Rain", "Snow", "Storm", "Meteor Shower", "Solar Flare", "Nuclear", "Black Hole" }
	while isRunning do
		for _, weatherName in testOrder do
			local duration = TEST_DURATION
			currentWeather = weatherName
			weatherEndTime = os.clock() + duration
			Remotes.WeatherChanged:FireAllClients({
				weather = weatherName,
				duration = duration,
				endTime = weatherEndTime,
			})
			applyWeatherMutations(weatherName)
			task.wait(duration)

			-- Brief clear between events
			currentWeather = "Clear"
			weatherEndTime = 0
			Remotes.WeatherChanged:FireAllClients({ weather = "Clear", duration = 0, endTime = 0 })
			task.wait(3)
		end
	end
end

local function weatherCycleNormal()
	while isRunning do
		task.wait(math.random(Weather.WEATHER_CYCLE_MIN, Weather.WEATHER_CYCLE_MAX))

		local newWeather = rollWeatherType()
		currentWeather = newWeather

		if newWeather == "Clear" then
			weatherEndTime = 0
			Remotes.WeatherChanged:FireAllClients({ weather = "Clear", duration = 0, endTime = 0 })
		else
			local duration = rollDuration(newWeather)
			weatherEndTime = os.clock() + duration
			Remotes.WeatherChanged:FireAllClients({
				weather = newWeather,
				duration = duration,
				endTime = weatherEndTime,
			})

			applyWeatherMutations(newWeather)

			task.wait(duration)

			currentWeather = "Clear"
			weatherEndTime = 0
			Remotes.WeatherChanged:FireAllClients({ weather = "Clear", duration = 0, endTime = 0 })
		end
	end
end

function WeatherService.init()
	isRunning = true
	currentWeather = "Clear"
	Remotes.WeatherChanged:FireAllClients({ weather = "Clear", duration = 0, endTime = 0 })
	if TEST_MODE then
		task.spawn(weatherCycleTest)
	else
		task.spawn(weatherCycleNormal)
	end

	Players.PlayerAdded:Connect(function(player)
		task.defer(function()
			Remotes.WeatherChanged:FireClient(player, {
				weather = currentWeather,
				duration = 0,
				endTime = weatherEndTime,
			})
		end)
	end)
end

function WeatherService.getCurrentWeather(): string
	return currentWeather
end

function WeatherService.getWeatherEndTime(): number
	return weatherEndTime
end

return {
	init = WeatherService.init,
	getCurrentWeather = WeatherService.getCurrentWeather,
	getWeatherEndTime = WeatherService.getWeatherEndTime,
}
