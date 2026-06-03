-- src/ReplicatedStorage/RoomData.luau
local RoomData = {}

-- ── Lab floor: 5 departments × 10 stations = 50 total ─────────────────────
-- cost(g)           = g × 50          →  50 … 2,500
-- income_per_tick(g)= g               →   1 … 50
-- income/min        = g × 20          →  20 … 1,000
-- Cumulative income/min from N stations = 20 × N×(N+1)/2
-- → unlocking station N+1 takes ≤1 min once N≥7 (starting 2k covers first 7)

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
        local g = (deptIdx - 1) * 10 + i   -- global index 1-50
        table.insert(labStations, {
            id           = "lab_" .. dept.name .. "_" .. i,
            name         = dept.label .. " " .. i,
            unlockOrder  = 1,
            deptIndex    = deptIdx,
            stationIndex = i,
            tiers = {
                { cost = g * 50,        incomePerTick = g           },
                { cost = g * 150,       incomePerTick = math.floor(g * 2.5) },
                { cost = g * 400,       incomePerTick = g * 6       },
            },
        })
    end
end

-- ── Upper floors ───────────────────────────────────────────────────────────
-- Priced so players spend 2-8 vault-fills each (base cap = 15k).
-- After completing all 50 lab stations: ~25,500/min total income.

local upperFloors = {
    {
        id           = "armory",
        name         = "Armory",
        unlockOrder  = 2,
        tiers = {
            { cost = 10000,  incomePerTick = 30  },
            { cost = 30000,  incomePerTick = 80  },
            { cost = 80000,  incomePerTick = 200 },
        },
    },
    {
        id               = "minion_barracks",
        name             = "Minion Barracks",
        unlockOrder      = 3,
        raidDefenseBonus = { 0.02, 0.04, 0.07 },
        tiers = {
            { cost = 20000,  incomePerTick = 50  },
            { cost = 60000,  incomePerTick = 130 },
            { cost = 160000, incomePerTick = 350 },
        },
    },
    {
        id           = "war_room",
        name         = "War Room",
        unlockOrder  = 4,
        tiers = {
            { cost = 40000,  incomePerTick = 90  },
            { cost = 120000, incomePerTick = 240 },
            { cost = 320000, incomePerTick = 640 },
        },
    },
    {
        id               = "vault",
        name             = "Vault",
        unlockOrder      = 5,
        vaultCapBonus    = { 50000, 150000, 500000 },
        raidDefenseBonus = { 0.01, 0.03, 0.05 },
        tiers = {
            { cost = 80000,   incomePerTick = 160  },
            { cost = 240000,  incomePerTick = 430  },
            { cost = 640000,  incomePerTick = 1150 },
        },
    },
    {
        id           = "escape_pod_bay",
        name         = "Escape Pod Bay",
        unlockOrder  = 6,
        tiers = {
            { cost = 160000,  incomePerTick = 300  },
            { cost = 480000,  incomePerTick = 800  },
            { cost = 1280000, incomePerTick = 2200 },
        },
    },
}

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

function RoomData.getLabProgress(builtRooms: {[string]: number}): (number, number)
    local bought = 0
    for _, r in ipairs(RoomData.ROOMS) do
        if r.unlockOrder == 1 then
            if builtRooms[r.id] and builtRooms[r.id] > 0 then
                bought += 1
            end
        end
    end
    return bought, 50
end

RoomData.LAB_DEPTS = LAB_DEPTS

return RoomData
