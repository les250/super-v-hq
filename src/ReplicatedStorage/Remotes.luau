-- src/ReplicatedStorage/Remotes.luau
-- Creates RemoteEvents/Functions on first require (server), returns them on client.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function getOrCreate(className: string, name: string)
    local existing = ReplicatedStorage:FindFirstChild(name)
    if existing then
        return existing
    end
    local obj = Instance.new(className)
    obj.Name = name
    obj.Parent = ReplicatedStorage
    return obj
end

local Remotes = {}

-- Server → Client events
Remotes.UpdateCurrency    = getOrCreate("RemoteEvent",    "UpdateCurrency")    -- (amount: number, vaultCap: number)
Remotes.RaidNotification  = getOrCreate("RemoteEvent",    "RaidNotification")  -- (raiderName: string, stolen: number)
Remotes.RoomBuilt         = getOrCreate("RemoteEvent",    "RoomBuilt")         -- (roomId: string, tier: number)

-- Client → Server events
Remotes.BuyRoom           = getOrCreate("RemoteEvent",    "BuyRoom")           -- (roomId: string)
Remotes.UpgradeRoom       = getOrCreate("RemoteEvent",    "UpgradeRoom")       -- (roomId: string)
Remotes.PrepareRaid       = getOrCreate("RemoteEvent",    "PrepareRaid")       -- (targetUserId: number)

-- Client → Server with return
Remotes.GetPlayerData     = getOrCreate("RemoteFunction", "GetPlayerData")     -- () → playerData table
Remotes.GetAllPlotInfo    = getOrCreate("RemoteFunction", "GetAllPlotInfo")    -- () → list of {userId, name, vaultAmount}

return Remotes
