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
}

local Remotes = {}

for _, name in REMOTE_NAMES do
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotesFolder
	Remotes[name] = remote
end

return Remotes
