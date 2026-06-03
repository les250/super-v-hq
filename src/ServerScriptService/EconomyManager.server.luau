-- src/ServerScriptService/EconomyManager.server.luau
local Players   = game:GetService("Players")
local Config    = require(game.ReplicatedStorage.Config)
local RoomData  = require(game.ReplicatedStorage.RoomData)
local Remotes   = require(game.ReplicatedStorage.Remotes)

local function getDS(): any
    -- Wait until DataStore is ready (loaded by DataStore.server.luau)
    while not _G.DataStore do task.wait(0.1) end
    return _G.DataStore
end

local TICKS_PER_MIN = 60 / Config.INCOME_TICK_INTERVAL  -- 20 ticks/min at 3s

local function pushCurrencyUpdate(player: Player)
    local ds   = getDS()
    local data = ds.get(player)
    if not data then return end
    local cap       = RoomData.getVaultCap(data.rooms, Config.BASE_VAULT_CAP)
    local incPerMin = math.floor(RoomData.getTotalIncome(data.rooms) * TICKS_PER_MIN)
    Remotes.UpdateCurrency:FireClient(player, data.vaultAmount, cap, incPerMin)
end

-- Passive income tick
task.spawn(function()
    while true do
        task.wait(Config.INCOME_TICK_INTERVAL)
        local ds = getDS()
        for _, player in ipairs(Players:GetPlayers()) do
            local data = ds.get(player)
            if data then
                local income = RoomData.getTotalIncome(data.rooms)
                local cap    = RoomData.getVaultCap(data.rooms, Config.BASE_VAULT_CAP)
                -- Never reduce an above-cap balance (dev/promo overflow).
                -- Only add income when below cap.
                if data.vaultAmount < cap then
                    data.vaultAmount = math.min(data.vaultAmount + income, cap)
                end
                pushCurrencyUpdate(player)
            end
        end
    end
end)

-- Buy a room (drop pad activated)
Remotes.BuyRoom.OnServerEvent:Connect(function(player: Player, roomId: string)
    local ds   = getDS()
    local data = ds.get(player)
    if not data then return end

    local room = RoomData.getRoom(roomId)
    if not room then return end

    -- Must not already own this room
    if data.rooms[roomId] and data.rooms[roomId] > 0 then return end

    -- Must own all previous rooms first
    for _, r in ipairs(RoomData.ROOMS) do
        if r.unlockOrder < room.unlockOrder then
            if not data.rooms[r.id] or data.rooms[r.id] == 0 then
                return -- prerequisite not met
            end
        end
    end

    local cost = room.tiers[1].cost
    if data.vaultAmount < cost then return end

    data.vaultAmount   -= cost
    data.rooms[roomId]  = 1
    pushCurrencyUpdate(player)
    Remotes.RoomBuilt:FireClient(player, roomId, 1)
end)

-- Upgrade a room (room upgrade menu activated)
Remotes.UpgradeRoom.OnServerEvent:Connect(function(player: Player, roomId: string)
    local ds   = getDS()
    local data = ds.get(player)
    if not data then return end

    local room        = RoomData.getRoom(roomId)
    local currentTier = data.rooms[roomId] or 0
    if not room or currentTier == 0 or currentTier >= 3 then return end

    local nextTier = currentTier + 1
    local cost     = room.tiers[nextTier].cost
    if data.vaultAmount < cost then return end

    data.vaultAmount  -= cost
    data.rooms[roomId] = nextTier
    pushCurrencyUpdate(player)
    Remotes.RoomBuilt:FireClient(player, roomId, nextTier)
end)

-- GetPlayerData remote function
Remotes.GetPlayerData.OnServerInvoke = function(player: Player)
    local ds = getDS()
    return ds.get(player)
end

-- GetAllPlotInfo (used by War Room ability)
Remotes.GetAllPlotInfo.OnServerInvoke = function(player: Player)
    local ds       = getDS()
    local data     = ds.get(player)
    -- Only players with War Room built can call this
    if not data or not data.rooms["war_room"] or data.rooms["war_room"] == 0 then
        return {}
    end
    local result = {}
    for _, p in ipairs(Players:GetPlayers()) do
        local pData = ds.get(p)
        if pData then
            table.insert(result, {
                userId      = p.UserId,
                name        = p.Name,
                vaultAmount = pData.vaultAmount,
            })
        end
    end
    return result
end

Remotes.BuyInventorySlot.OnServerEvent:Connect(function(player: Player)
    local ds   = getDS()
    local data = ds.get(player)
    if not data then return end
    local slots = data.inventorySlots or Config.STARTING_SLOTS
    if slots >= Config.MAX_SLOTS then return end
    if data.vaultAmount < Config.SLOT_COST then return end
    data.vaultAmount   -= Config.SLOT_COST
    data.inventorySlots = slots + 1
    pushCurrencyUpdate(player)
    Remotes.SlotCountUpdate:FireClient(player, data.inventorySlots, Config.MAX_SLOTS)
    ds.save(player)
end)
