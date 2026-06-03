-- src/ServerScriptService/RaidManager.server.luau
local Players            = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local Config             = require(game.ReplicatedStorage.Config)
local RoomData           = require(game.ReplicatedStorage.RoomData)
local Remotes            = require(game.ReplicatedStorage.Remotes)

local function getDS(): any
    while not _G.DataStore do task.wait(0.1) end
    return _G.DataStore
end

local function pushCooldown(player: Player)
    local ds   = getDS()
    local data = ds.get(player)
    if not data then return end
    local remaining = math.max(0, Config.RAID_COOLDOWN - (os.time() - (data.lastRaidedAt or 0)))
    Remotes.RaidCooldownUpdate:FireClient(player, remaining)
end

-- Stores which player each raider is targeting
-- { [raiderUserId: number]: targetUserId: number }
local pendingRaids: {[number]: number} = {}

-- Client signals intent to raid before prompting purchase
Remotes.PrepareRaid.OnServerEvent:Connect(function(raider: Player, targetUserId: number)
    -- Validate target exists in server
    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
    if not targetPlayer or targetPlayer == raider then return end
    pendingRaids[raider.UserId] = targetUserId
end)

local function executeRaid(raider: Player, targetUserId: number)
    local ds           = getDS()
    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
    if not targetPlayer then return end

    local targetData = ds.get(targetPlayer)
    if not targetData then return end

    -- Check cooldown
    local now = os.time()
    if (now - targetData.lastRaidedAt) < Config.RAID_COOLDOWN then
        return
    end

    local defense      = RoomData.getDefenseReduction(targetData.rooms)
    local stealPercent = math.max(0, Config.RAID_STEAL_PERCENT - defense)
    local stolen       = math.floor(targetData.vaultAmount * stealPercent)

    targetData.vaultAmount  = math.max(0, targetData.vaultAmount - stolen)
    targetData.lastRaidedAt = now

    -- Give stolen amount to raider
    local raiderData = ds.get(raider)
    if raiderData then
        local cap = RoomData.getVaultCap(raiderData.rooms, Config.BASE_VAULT_CAP)
        if raiderData.vaultAmount < cap then
            raiderData.vaultAmount = math.min(raiderData.vaultAmount + stolen, cap)
        end
        Remotes.UpdateCurrency:FireClient(raider, raiderData.vaultAmount, cap)
    end

    -- Notify victim
    local targetCap = RoomData.getVaultCap(targetData.rooms, Config.BASE_VAULT_CAP)
    Remotes.UpdateCurrency:FireClient(targetPlayer, targetData.vaultAmount, targetCap)
    Remotes.RaidNotification:FireClient(targetPlayer, raider.Name, stolen)
    pushCooldown(targetPlayer)

    -- Save both sides immediately so a server crash can't desync raider gain vs victim loss
    ds.save(targetPlayer)
end

-- Handle currency product purchases and raid purchases
MarketplaceService.ProcessReceipt = function(receiptInfo)
    local ds     = getDS()
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local data = ds.get(player)
    if not data then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local productId = receiptInfo.ProductId

    -- Currency purchases
    local currencyAmount = Config.PRODUCT_CURRENCY_AMOUNTS[productId]
    if currencyAmount then
        local cap = RoomData.getVaultCap(data.rooms, Config.BASE_VAULT_CAP)
        data.vaultAmount = math.min(data.vaultAmount + currencyAmount, cap)
        Remotes.UpdateCurrency:FireClient(player, data.vaultAmount, cap)
        ds.save(player)
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end

    -- Raid purchase
    if productId == Config.PRODUCT_RAID then
        local targetUserId = pendingRaids[player.UserId]
        if targetUserId then
            pendingRaids[player.UserId] = nil
            executeRaid(player, targetUserId)
        end
        ds.save(player)
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end

    return Enum.ProductPurchaseDecision.NotProcessedYet
end

game:GetService("Players").PlayerAdded:Connect(function(player)
    task.wait(2)  -- wait for data to load
    pushCooldown(player)
end)
