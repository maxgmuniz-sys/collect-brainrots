local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "Remotes"
remotesFolder.Parent = ReplicatedStorage

local REMOTE_NAMES = {
	"BuyFood",
	"BrainrotSpawned",
	"BrainrotRanAway",
	"MoneyUpdated",
	"EarningsUpdated",
	"UpgradeCapacity",
	"CapacityUpdated",
	"InitialData",

	-- Phase 5 remotes
	"SellBrainrot",
	"SellAll",
	"SellConfirmed",

	-- Phase 6 remotes
	"WeatherChanged",
	"BrainrotMutated",

	-- Phase 7 remotes
	"RequestIndex",
	"IndexUpdated",
	"GiftBrainrot",
	"GiftReceived",
	"RequestLeaderboard",
	"LeaderboardData",

	-- Phase 8 remotes
	"FuseBrainrots",
	"FuseResult",
	"LuckyHourStarted",
	"LuckyHourEnded",
	"TutorialComplete",

	-- Phase 9 remotes
	"PlotAssigned",
	"RivalBaseUpdate",
	"TutorialStepCompleted",
}

local Remotes = {}

for _, name in REMOTE_NAMES do
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotesFolder
	Remotes[name] = remote
end

return Remotes
