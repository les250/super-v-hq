-- src/ReplicatedStorage/RoomData.luau
local RoomData = {}

-- Each room: id, name, unlockOrder, tiers[], optional defense fields
-- tiers[n] = { cost: number, incomePerTick: number }
RoomData.ROOMS = {
    {
        id           = "lab",
        name         = "Lab",
        unlockOrder  = 1,
        tiers = {
            { cost = 100,    incomePerTick = 5  },
            { cost = 500,    incomePerTick = 12 },
            { cost = 2000,   incomePerTick = 25 },
        },
    },
    {
        id           = "armory",
        name         = "Armory",
        unlockOrder  = 2,
        tiers = {
            { cost = 400,    incomePerTick = 15 },
            { cost = 1500,   incomePerTick = 35 },
            { cost = 5000,   incomePerTick = 70 },
        },
    },
    {
        id                = "minion_barracks",
        name              = "Minion Barracks",
        unlockOrder       = 3,
        raidDefenseBonus  = { 0.02, 0.04, 0.07 }, -- reduces fraction stolen
        tiers = {
            { cost = 1000,   incomePerTick = 20 },
            { cost = 4000,   incomePerTick = 45 },
            { cost = 12000,  incomePerTick = 90 },
        },
    },
    {
        id           = "war_room",
        name         = "War Room",
        unlockOrder  = 4,
        tiers = {
            { cost = 3000,   incomePerTick = 50  },
            { cost = 10000,  incomePerTick = 110 },
            { cost = 30000,  incomePerTick = 220 },
        },
    },
    {
        id               = "vault",
        name             = "Vault",
        unlockOrder      = 5,
        vaultCapBonus    = { 5000, 15000, 50000 }, -- added to BASE_VAULT_CAP
        raidDefenseBonus = { 0.01, 0.03, 0.05  },
        tiers = {
            { cost = 8000,   incomePerTick = 30  },
            { cost = 25000,  incomePerTick = 65  },
            { cost = 80000,  incomePerTick = 130 },
        },
    },
    {
        id           = "escape_pod_bay",
        name         = "Escape Pod Bay",
        unlockOrder  = 6,
        tiers = {
            { cost = 20000,  incomePerTick = 80  },
            { cost = 60000,  incomePerTick = 180 },
            { cost = 200000, incomePerTick = 400 },
        },
    },
}

-- Returns the room table for a given id, or nil
function RoomData.getRoom(id: string)
    for _, room in ipairs(RoomData.ROOMS) do
        if room.id == id then
            return room
        end
    end
    return nil
end

-- Returns the vault capacity for a player given their built rooms
-- builtRooms: { [roomId: string]: tier: number } where tier is 1-3
function RoomData.getVaultCap(builtRooms: {[string]: number}, baseCap: number): number
    local cap = baseCap
    local vault = RoomData.getRoom("vault")
    if vault then
        local tier = builtRooms["vault"]
        if tier and tier > 0 then
            cap += vault.vaultCapBonus[tier]
        end
    end
    return cap
end

-- Returns the total defense reduction fraction for a player's built rooms
-- e.g. 0.07 means 7% is subtracted from RAID_STEAL_PERCENT
function RoomData.getDefenseReduction(builtRooms: {[string]: number}): number
    local reduction = 0
    for _, room in ipairs(RoomData.ROOMS) do
        if room.raidDefenseBonus then
            local tier = builtRooms[room.id]
            if tier and tier > 0 then
                reduction += room.raidDefenseBonus[tier]
            end
        end
    end
    return reduction
end

-- Returns total incomePerTick across all built rooms
function RoomData.getTotalIncome(builtRooms: {[string]: number}): number
    local total = 0
    for _, room in ipairs(RoomData.ROOMS) do
        local tier = builtRooms[room.id]
        if tier and tier > 0 then
            total += room.tiers[tier].incomePerTick
        end
    end
    return total
end

return RoomData
