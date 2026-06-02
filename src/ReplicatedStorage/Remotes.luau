-- src/ReplicatedStorage/Remotes.luau
-- Server: creates RemoteEvents/Functions. Client: waits for them to exist.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local isServer = RunService:IsServer()

local function get(className: string, name: string)
    if isServer then
        local existing = ReplicatedStorage:FindFirstChild(name)
        if existing then
            return existing
        end
        local obj = Instance.new(className)
        obj.Name = name
        obj.Parent = ReplicatedStorage
        return obj
    else
        return ReplicatedStorage:WaitForChild(name)
    end
end

local Remotes = {}

-- Server → Client events
Remotes.UpdateCurrency    = get("RemoteEvent",    "UpdateCurrency")    -- (amount: number, vaultCap: number)
Remotes.RaidNotification  = get("RemoteEvent",    "RaidNotification")  -- (raiderName: string, stolen: number)
Remotes.RoomBuilt         = get("RemoteEvent",    "RoomBuilt")         -- (roomId: string, tier: number)

-- Client → Server events
Remotes.BuyRoom           = get("RemoteEvent",    "BuyRoom")           -- (roomId: string)
Remotes.UpgradeRoom       = get("RemoteEvent",    "UpgradeRoom")       -- (roomId: string)
Remotes.PrepareRaid       = get("RemoteEvent",    "PrepareRaid")       -- (targetUserId: number)

-- Client → Server with return
Remotes.GetPlayerData     = get("RemoteFunction", "GetPlayerData")     -- () → playerData table
Remotes.GetAllPlotInfo    = get("RemoteFunction", "GetAllPlotInfo")    -- () → list of {userId, name, vaultAmount}
Remotes.GetFreePlots      = get("RemoteFunction", "GetFreePlots")      -- () → list of {name, index, position}

-- Base selection / movement
Remotes.ClaimBase         = get("RemoteEvent",    "ClaimBase")         -- (plotName: string)
Remotes.MoveBase          = get("RemoteEvent",    "MoveBase")          -- (plotName: string)
Remotes.BaseAssigned      = get("RemoteEvent",    "BaseAssigned")      -- (plotName: string) server→client
Remotes.ResetPlot         = get("RemoteEvent",    "ResetPlot")         -- () server→client: hide all rooms

return Remotes
