-- src/ReplicatedStorage/RoomData.luau
local RoomData = {}

-- ── Lab floor: 5 departments × 10 stations = 50 total ─────────────────────
-- All lab stations have unlockOrder=1.
-- Upper floors (unlockOrder 2-6) are gated behind all 50 being bought.

local LAB_DEPTS = {
    { name = "chemistry",   label = "Chem Lab"    },
    { name = "electronics", label = "Electronics" },
    { name = "biology",     label = "Bio Lab"     },
    { name = "physics",     label = "Physics"     },
    { name = "weapons",     label = "Weapons R&D" },
}

local labStations = {}
for deptIdx, dept in ipairs(LAB_DEPTS) do
    for i = 1, 10 do
        local g = (deptIdx - 1) * 10 + i          -- global index 1-50
        local cost   = math.floor(60 * (g ^ 1.45))
        local income = math.max(1, math.floor(g * 0.9))
        table.insert(labStations, {
            id           = "lab_" .. dept.name .. "_" .. i,
            name         = dept.label .. " " .. i,
            unlockOrder  = 1,
            deptIndex    = deptIdx,
            stationIndex = i,
            tiers = {
                { cost = cost,      incomePerTick = income },
                { cost = cost * 3,  incomePerTick = math.floor(income * 2.5) },
                { cost = cost * 8,  incomePerTick = math.floor(income * 6)   },
            },
        })
    end
end

-- ── Upper floors (gated behind all 50 lab stations) ────────────────────────

local upperFloors = {
    {
        id              = "armory",
        name            = "Armory",
        unlockOrder     = 2,
        tiers = {
            { cost = 5000,   incomePerTick = 60  },
            { cost = 18000,  incomePerTick = 140 },
            { cost = 55000,  incomePerTick = 290 },
        },
    },
    {
        id               = "minion_barracks",
        name             = "Minion Barracks",
        unlockOrder      = 3,
        raidDefenseBonus = { 0.02, 0.04, 0.07 },
        tiers = {
            { cost = 12000,  incomePerTick = 90  },
            { cost = 40000,  incomePerTick = 200 },
            { cost = 120000, incomePerTick = 420 },
        },
    },
    {
        id           = "war_room",
        name         = "War Room",
        unlockOrder  = 4,
        tiers = {
            { cost = 30000,  incomePerTick = 150 },
            { cost = 100000, incomePerTick = 350 },
            { cost = 300000, incomePerTick = 750 },
        },
    },
    {
        id               = "vault",
        name             = "Vault",
        unlockOrder      = 5,
        vaultCapBonus    = { 20000, 80000, 250000 },
        raidDefenseBonus = { 0.01, 0.03, 0.05 },
        tiers = {
            { cost = 80000,  incomePerTick = 200 },
            { cost = 250000, incomePerTick = 480 },
            { cost = 800000, incomePerTick = 1000 },
        },
    },
    {
        id           = "escape_pod_bay",
        name         = "Escape Pod Bay",
        unlockOrder  = 6,
        tiers = {
            { cost = 200000,  incomePerTick = 400  },
            { cost = 600000,  incomePerTick = 900  },
            { cost = 2000000, incomePerTick = 2000 },
        },
    },
}

-- Combine into flat ROOMS list (lab stations first, then upper floors)
RoomData.ROOMS = {}
for _, s in ipairs(labStations)  do table.insert(RoomData.ROOMS, s) end
for _, r in ipairs(upperFloors)  do table.insert(RoomData.ROOMS, r) end

-- ── Helpers ────────────────────────────────────────────────────────────────

function RoomData.getRoom(id: string)
    for _, r in ipairs(RoomData.ROOMS) do
        if r.id == id then return r end
    end
    return nil
end

function RoomData.getVaultCap(builtRooms: {[string]: number}, baseCap: number): number
    local cap = baseCap
    local vault = RoomData.getRoom("vault")
    if vault then
        local tier = builtRooms["vault"]
        if tier and tier > 0 then cap += vault.vaultCapBonus[tier] end
    end
    return cap
end

function RoomData.getDefenseReduction(builtRooms: {[string]: number}): number
    local reduction = 0
    for _, r in ipairs(RoomData.ROOMS) do
        if r.raidDefenseBonus then
            local tier = builtRooms[r.id]
            if tier and tier > 0 then
                reduction += r.raidDefenseBonus[tier]
            end
        end
    end
    return reduction
end

function RoomData.getTotalIncome(builtRooms: {[string]: number}): number
    local total = 0
    for _, r in ipairs(RoomData.ROOMS) do
        local tier = builtRooms[r.id]
        if tier and tier > 0 then
            total += r.tiers[tier].incomePerTick
        end
    end
    return total
end

-- How many lab stations are fully unlocked (tier >= 1)
function RoomData.getLabProgress(builtRooms: {[string]: number}): (number, number)
    local bought, total = 0, 50
    for _, r in ipairs(RoomData.ROOMS) do
        if r.unlockOrder == 1 then
            if builtRooms[r.id] and builtRooms[r.id] > 0 then
                bought += 1
            end
        end
    end
    return bought, total
end

-- Lab department names for WorldSetup
RoomData.LAB_DEPTS = LAB_DEPTS

return RoomData
