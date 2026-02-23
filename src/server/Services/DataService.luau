local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileStore = require(ServerScriptService.ServerPackages.ProfileStore)
local Remotes = require(ServerScriptService.Server.Remotes)

local PROFILE_STORE_NAME = "PlayerData_v1"

local DEFAULT_DATA = {
	money = 100,
	ownedBrainrots = {},
	baseCapacity = 1,
	totalMoneyEarned = 0,
	totalTimePlayed = 0,
	totalRobuxSpent = 0,
	index = {
		normal = {},
		gold = {},
		diamond = {},
		rainbow = {},
	},
	unlockedFences = {},
	tutorialComplete = false,
}

local profileStore = nil
local activeProfiles = {}
local sessionStartTimes = {}

local DataService = {}

function DataService.init()
	profileStore = ProfileStore.New(PROFILE_STORE_NAME, DEFAULT_DATA)
end

function DataService.onPlayerAdded(player: Player)
	local profile = profileStore:StartSessionAsync("Player_" .. player.UserId)

	if not profile then
		player:Kick("Failed to load your data. Please rejoin.")
		return
	end

	if not player.Parent then
		profile:EndSession()
		return
	end

	profile:Reconcile()

	profile.OnSessionEnd:Connect(function()
		if player.Parent then
			player:Kick("Your data session ended. Please rejoin.")
		end
	end)

	activeProfiles[player] = profile
	sessionStartTimes[player] = os.clock()

	-- Compute initial earnings
	local earningsPerSec = 0
	for _, brainrot in profile.Data.ownedBrainrots do
		earningsPerSec += brainrot.earningsPerSec
	end

	Remotes.InitialData:FireClient(player, {
		money = profile.Data.money,
		earningsPerSec = earningsPerSec,
		capacity = {
			current = #profile.Data.ownedBrainrots,
			max = profile.Data.baseCapacity,
		},
		brainrots = profile.Data.ownedBrainrots,
	})
end

function DataService.onPlayerRemoving(player: Player)
	local profile = activeProfiles[player]
	if not profile then
		return
	end

	if sessionStartTimes[player] then
		local elapsed = os.clock() - sessionStartTimes[player]
		profile.Data.totalTimePlayed += elapsed
	end

	profile:EndSession()
	activeProfiles[player] = nil
	sessionStartTimes[player] = nil
end

function DataService.getData(player: Player): { [string]: any }?
	local profile = activeProfiles[player]
	if not profile then
		return nil
	end
	return profile.Data
end

function DataService.addMoney(player: Player, amount: number)
	local data = DataService.getData(player)
	if not data then
		return
	end

	data.money += amount
	data.totalMoneyEarned += amount
	Remotes.MoneyUpdated:FireClient(player, { money = data.money })
end

function DataService.subtractMoney(player: Player, amount: number): boolean
	local data = DataService.getData(player)
	if not data then
		return false
	end

	if data.money < amount then
		return false
	end

	data.money -= amount
	Remotes.MoneyUpdated:FireClient(player, { money = data.money })
	return true
end

return DataService
