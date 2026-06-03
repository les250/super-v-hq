-- src/ServerScriptService/TradeManager.server.luau
local Players  = game:GetService("Players")
local Remotes  = require(game.ReplicatedStorage.Remotes)
local ItemData = require(game.ReplicatedStorage.ItemData)

local function getDS()
    while not _G.DataStore do task.wait(0.1) end
    return _G.DataStore
end

-- pending: { [senderUserId]: {targetUserId, itemId, expireAt} }
local pending: {[number]: any} = {}

Remotes.SendTrade.OnServerEvent:Connect(function(sender, targetUserId, itemId)
    local ds         = getDS()
    local senderData = ds.get(sender)
    if not senderData then return end

    -- Validate sender has the item
    local inv = senderData.inventory or {}
    local hasItem = false
    for _, id in ipairs(inv) do
        if id == itemId then hasItem = true; break end
    end
    if not hasItem then return end

    -- Validate target is online
    local target = Players:GetPlayerByUserId(targetUserId)
    if not target then
        Remotes.TradeCancelled:FireClient(sender, "Player not online")
        return
    end

    -- Cancel any existing pending trade from this sender
    pending[sender.UserId] = nil

    pending[sender.UserId] = {
        targetUserId = targetUserId,
        itemId       = itemId,
        expireAt     = os.time() + 30,
    }

    -- Notify target
    local def = ItemData.get(itemId)
    Remotes.TradeRequest:FireClient(target,
        sender.UserId, sender.DisplayName,
        itemId, def and def.name or itemId)

    -- Auto-cancel after 30 seconds
    task.delay(30, function()
        local t = pending[sender.UserId]
        if t and t.itemId == itemId and t.targetUserId == targetUserId then
            pending[sender.UserId] = nil
            Remotes.TradeCancelled:FireClient(sender, "Trade expired (30s)")
        end
    end)
end)

Remotes.TradeResponse.OnServerEvent:Connect(function(target, senderUserId, accepted)
    local trade = pending[senderUserId]
    if not trade or trade.targetUserId ~= target.UserId then return end
    if os.time() > trade.expireAt then
        pending[senderUserId] = nil; return
    end

    local sender = Players:GetPlayerByUserId(senderUserId)
    pending[senderUserId] = nil

    if not accepted then
        if sender then
            Remotes.TradeCancelled:FireClient(sender, target.DisplayName .. " declined")
        end
        return
    end

    -- Execute transfer
    local ds         = getDS()
    local senderData = sender and ds.get(sender)
    local targetData = ds.get(target)
    if not senderData or not targetData then return end

    -- Remove item from sender
    local sInv = senderData.inventory or {}
    local found = false
    for i, id in ipairs(sInv) do
        if id == trade.itemId then
            table.remove(sInv, i); found = true; break
        end
    end
    if not found then return end

    -- Check target has space
    local tSlots = targetData.inventorySlots or 3
    local tInv   = targetData.inventory or {}
    if #tInv >= tSlots then
        if sender then
            Remotes.TradeCancelled:FireClient(sender, "Target inventory full")
        end
        return
    end

    senderData.inventory = sInv
    table.insert(tInv, trade.itemId)
    targetData.inventory = tInv

    ds.save(sender); ds.save(target)

    Remotes.InventoryUpdate:FireClient(sender, sInv)
    Remotes.InventoryUpdate:FireClient(target, tInv)

    local def = ItemData.get(trade.itemId)
    local itemName = def and def.name or trade.itemId
    if sender then
        Remotes.TradeComplete:FireClient(sender, itemName, target.DisplayName)
    end
    Remotes.TradeComplete:FireClient(target, itemName, sender and sender.DisplayName or "?")
end)
