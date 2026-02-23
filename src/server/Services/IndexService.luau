local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Brainrots = require(ReplicatedStorage.Shared.Config.Brainrots)
local DataService = require(ServerScriptService.Server.Services.DataService)
local Remotes = require(ServerScriptService.Server.Remotes)

local TOTAL_BRAINROTS = 25

local FENCE_REWARDS = {
	normal = "Default Fence",
	gold = "Gold Fence",
	diamond = "Diamond Fence",
	rainbow = "Rainbow Fence",
}

local FENCE_PRIORITY = {
	["Default Fence"] = 1,
	["Gold Fence"] = 2,
	["Diamond Fence"] = 3,
	["Rainbow Fence"] = 4,
}

local IndexService = {}

local function getMutationSection(baseMutation: string?): string
	if baseMutation == "Gold" then
		return "gold"
	elseif baseMutation == "Diamond" then
		return "diamond"
	elseif baseMutation == "Rainbow" then
		return "rainbow"
	end
	return "normal"
end

local function awardFenceReward(player: Player, section: string)
	local data = DataService.getData(player)
	if not data then
		return
	end

	local fenceName = FENCE_REWARDS[section]
	if not fenceName then
		return
	end

	for _, existing in data.unlockedFences do
		if existing == fenceName then
			return
		end
	end

	table.insert(data.unlockedFences, fenceName)
	print("[IndexService] " .. player.Name .. " completed " .. section .. " section! Awarded " .. fenceName)
	Remotes.IndexUpdated:FireClient(player, { sectionComplete = true, section = section, fenceReward = fenceName })
end

local function handleRequestIndex(player: Player)
	local data = DataService.getData(player)
	if not data then
		return
	end

	local allBrainrotNames = {}
	for _, brainrot in Brainrots.BRAINROTS do
		table.insert(allBrainrotNames, brainrot.name)
	end

	local response = {
		index = data.index,
		unlockedFences = data.unlockedFences,
		allBrainrotNames = allBrainrotNames,
		totalRequired = TOTAL_BRAINROTS,
	}

	Remotes.IndexUpdated:FireClient(player, response)
end

function IndexService.registerDiscovery(player: Player, brainrotName: string, baseMutation: string?)
	local data = DataService.getData(player)
	if not data then
		warn("[IndexService] No data for " .. player.Name)
		return
	end

	local section = getMutationSection(baseMutation)
	local sectionTable = data.index[section]

	for _, existing in sectionTable do
		if existing == brainrotName then
			return
		end
	end

	table.insert(sectionTable, brainrotName)
	print("[IndexService] " .. player.Name .. " discovered " .. brainrotName .. " in " .. section .. " section (" .. #sectionTable .. "/" .. TOTAL_BRAINROTS .. ")")

	if #sectionTable >= TOTAL_BRAINROTS then
		awardFenceReward(player, section)
	end

	Remotes.IndexUpdated:FireClient(player, {
		section = section,
		brainrotName = brainrotName,
		sectionCount = #sectionTable,
		totalRequired = TOTAL_BRAINROTS,
	})
end

function IndexService.getIndexData(player: Player)
	local data = DataService.getData(player)
	if not data then
		return nil
	end
	return data.index
end

function IndexService.getBestFence(player: Player): string?
	local data = DataService.getData(player)
	if not data then
		return nil
	end

	if #data.unlockedFences == 0 then
		return nil
	end

	local bestPriority = 0
	local bestFence = nil
	for _, fence in data.unlockedFences do
		local priority = FENCE_PRIORITY[fence] or 0
		if priority > bestPriority then
			bestPriority = priority
			bestFence = fence
		end
	end

	return bestFence
end

function IndexService.init()
	Remotes.RequestIndex.OnServerEvent:Connect(handleRequestIndex)
	print("[IndexService] Initialized.")
end

return IndexService
