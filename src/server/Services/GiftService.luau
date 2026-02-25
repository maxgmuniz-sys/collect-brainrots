local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local DataService = require(ServerScriptService.Server.Services.DataService)
local EarningsService = require(ServerScriptService.Server.Services.EarningsService)
local IndexService = require(ServerScriptService.Server.Services.IndexService)
local BaseService = require(ServerScriptService.Server.Services.BaseService)
local Remotes = require(ServerScriptService.Server.Remotes)

local GIFT_COOLDOWN = 5

local lastGiftTime = {}

local GiftService = {}

local function handleGiftBrainrot(player: Player, data: { [string]: any })
	-- 1. Validate cooldown
	if lastGiftTime[player] and os.clock() - lastGiftTime[player] < GIFT_COOLDOWN then
		warn("[GiftService] GiftBrainrot: Cooldown active for " .. player.Name)
		return
	end

	-- 2. Validate payload types
	if type(data) ~= "table" then
		warn("[GiftService] GiftBrainrot: Invalid payload from " .. player.Name)
		return
	end

	local brainrotId = data.brainrotId
	local targetPlayerId = data.targetPlayerId

	if type(brainrotId) ~= "string" or type(targetPlayerId) ~= "number" then
		warn("[GiftService] GiftBrainrot: Invalid payload types from " .. player.Name)
		return
	end

	-- 3. Validate self-gift
	if targetPlayerId == player.UserId then
		warn("[GiftService] GiftBrainrot: Cannot gift to yourself")
		return
	end

	-- 4. Validate sender data
	local senderData = DataService.getData(player)
	if not senderData then
		warn("[GiftService] GiftBrainrot: No sender data for " .. player.Name)
		return
	end

	-- 5. Find brainrot in sender's inventory
	local brainrot = nil
	local brainrotIndex = nil
	for i, owned in senderData.ownedBrainrots do
		if owned.id == brainrotId then
			brainrot = owned
			brainrotIndex = i
			break
		end
	end

	if not brainrot or not brainrotIndex then
		warn("[GiftService] GiftBrainrot: Brainrot not found in sender inventory")
		return
	end

	-- 6. Validate target player is online
	local targetPlayer = Players:GetPlayerByUserId(targetPlayerId)
	if not targetPlayer then
		warn("[GiftService] GiftBrainrot: Target player not online")
		return
	end

	-- 7. Validate target data
	local targetData = DataService.getData(targetPlayer)
	if not targetData then
		warn("[GiftService] GiftBrainrot: No target data for " .. targetPlayer.Name)
		return
	end

	-- 8. Validate target capacity
	if #targetData.ownedBrainrots >= targetData.baseCapacity then
		warn("[GiftService] GiftBrainrot: Target player's base is full")
		return
	end

	-- Transfer brainrot
	table.remove(senderData.ownedBrainrots, brainrotIndex)
	table.insert(targetData.ownedBrainrots, brainrot)

	-- Update cooldown
	lastGiftTime[player] = os.clock()

	-- Recalculate earnings for both
	EarningsService.recalculate(player)
	EarningsService.recalculate(targetPlayer)

	-- Register discovery for recipient
	IndexService.registerDiscovery(targetPlayer, brainrot.name, brainrot.baseMutation)

	-- Fire sender capacity update
	Remotes.CapacityUpdated:FireClient(player, {
		current = #senderData.ownedBrainrots,
		max = senderData.baseCapacity,
	})

	-- Fire recipient brainrot spawned
	Remotes.BrainrotSpawned:FireClient(targetPlayer, { brainrotData = brainrot })

	-- Fire recipient capacity update
	Remotes.CapacityUpdated:FireClient(targetPlayer, {
		current = #targetData.ownedBrainrots,
		max = targetData.baseCapacity,
	})

	-- Fire gift received notification
	Remotes.GiftReceived:FireClient(targetPlayer, {
		fromPlayerName = player.Name,
		brainrotName = brainrot.name,
		brainrotRarity = brainrot.rarity,
		baseMutation = brainrot.baseMutation,
	})

	-- Phase 9: broadcast rival update for both players
	BaseService.broadcastRivalUpdate(player)
	BaseService.broadcastRivalUpdate(targetPlayer)

	print("[GiftService] " .. player.Name .. " gifted " .. brainrot.name .. " to " .. targetPlayer.Name)
end

function GiftService.init()
	Remotes.GiftBrainrot.OnServerEvent:Connect(handleGiftBrainrot)

	Players.PlayerRemoving:Connect(function(player)
		lastGiftTime[player] = nil
	end)

	print("[GiftService] Initialized.")
end

return GiftService
