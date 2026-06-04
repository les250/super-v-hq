-- src/ServerScriptService/EconomyManager.server.luau
local Players   = game:GetService("Players")
local Config    = require(game.ReplicatedStorage.Config)
local RoomData  = require(game.ReplicatedStorage.RoomData)
local Remotes   = require(game.ReplicatedStorage.Remotes)
local ItemData  = require(game.ReplicatedStorage.ItemData)

local function getDS(): any
    -- Wait until DataStore is ready (loaded by DataStore.server.luau)
    while not _G.DataStore do task.wait(0.1) end
    return _G.DataStore
end

local TICKS_PER_MIN = 60 / Config.INCOME_TICK_INTERVAL  -- 20 ticks/min at 3s

-- Per-player debounce to rate-limit purchase events (prevents rapid-fire exploits)
local buyDebounce: {[number]: number} = {}

local function getItemIncomeBoost(data): number
    local boost = 0
    for _, itemId in ipairs(data.inventory or {}) do
        local item = ItemData.get(itemId)
        if item and item.incomeBoostPct then
            boost += item.incomeBoostPct
        end
    end
    return boost
end

local function getEffectiveCap(data): number
    -- Vault cap from progressive dept system + Vault room bonus + Vault Override item
    return RoomData.getVaultCap(data.rooms, Config.BASE_VAULT_CAP)
         + RoomData.getInventoryCapBonus(data.inventory)
end

local function pushCurrencyUpdate(player: Player)
    local ds   = getDS()
    local data = ds.get(player)
    if not data then return end
    local cap       = getEffectiveCap(data)
    local baseInc   = RoomData.getTotalIncome(data.rooms)
    local incPerMin = math.floor(baseInc * (1 + getItemIncomeBoost(data)) * TICKS_PER_MIN)
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
                local baseIncome = RoomData.getTotalIncome(data.rooms)
                local income     = math.floor(baseIncome * (1 + getItemIncomeBoost(data)))
                local cap        = getEffectiveCap(data)  -- includes Vault Override item
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

    -- Rate limit: ignore events faster than 0.5s
    local now = os.clock()
    if buyDebounce[player.UserId] and now - buyDebounce[player.UserId] < 0.5 then return end
    buyDebounce[player.UserId] = now

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
    data.vaultAmount = math.max(0, data.vaultAmount)  -- floor at 0, no negative balance
    pushCurrencyUpdate(player)
    Remotes.RoomBuilt:FireClient(player, roomId, 1)
    -- Notify MinionManager when barracks is first built
    if roomId == "minion_barracks" then
        local mm = _G.MinionManager
        if mm then mm.onBarracksBuilt(player, 1) end
    end
end)

-- Upgrade a room (room upgrade menu activated)
Remotes.UpgradeRoom.OnServerEvent:Connect(function(player: Player, roomId: string)
    local ds   = getDS()
    local data = ds.get(player)
    if not data then return end

    -- Rate limit
    local now = os.clock()
    if buyDebounce[player.UserId] and now - buyDebounce[player.UserId] < 0.5 then return end
    buyDebounce[player.UserId] = now

    local room        = RoomData.getRoom(roomId)
    local currentTier = data.rooms[roomId] or 0
    if not room or currentTier == 0 or currentTier >= 3 then return end

    local nextTier = currentTier + 1
    -- Validate tier is sequential (anti-exploit: prevent skipping tiers)
    if nextTier > 3 then return end
    local cost     = room.tiers[nextTier].cost
    if data.vaultAmount < cost then return end

    data.vaultAmount  -= cost
    data.vaultAmount = math.max(0, data.vaultAmount)
    data.rooms[roomId] = nextTier
    pushCurrencyUpdate(player)
    Remotes.RoomBuilt:FireClient(player, roomId, nextTier)
    -- Notify MinionManager when barracks is upgraded
    if roomId == "minion_barracks" then
        local mm = _G.MinionManager
        if mm then mm.onBarracksBuilt(player, nextTier) end
    end
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

local CRAFT_RECIPES = {
    chemistry   = {itemId="stim_pack",      cost=2000},
    electronics = {itemId="emp_grenade",    cost=3000},
    biology     = {itemId="armor_chip",     cost=4000},
    physics     = {itemId="vault_override", cost=6000},
    weapons     = {itemId="minion_core",    cost=5000},
}

Remotes.CraftItem.OnServerInvoke = function(player: Player, deptKey: string)
    local ds   = getDS()
    local data = ds.get(player)
    if not data then return {ok=false, message="Data not ready"} end

    -- Must have all 5 lab departments complete
    local deptsDone = RoomData.getDeptsDone(data.rooms)
    if deptsDone < 5 then
        return {ok=false, message="Complete all Lab departments first"}
    end

    local recipe = CRAFT_RECIPES[deptKey]
    if not recipe then return {ok=false, message="Unknown recipe"} end

    -- Check inventory space
    local slots = data.inventorySlots or Config.STARTING_SLOTS
    local inv   = data.inventory or {}
    if #inv >= slots then
        return {ok=false, message="Inventory full! Buy more slots."}
    end

    if data.vaultAmount < recipe.cost then
        return {ok=false, message=string.format("Need 💰%d to craft", recipe.cost)}
    end

    data.vaultAmount -= recipe.cost
    table.insert(inv, recipe.itemId)
    data.inventory = inv

    pushCurrencyUpdate(player)
    Remotes.InventoryUpdate:FireClient(player, inv)
    ds.save(player)

    local itemName = recipe.itemId:gsub("_", " ")
    return {ok=true, message="Crafted " .. itemName}
end
