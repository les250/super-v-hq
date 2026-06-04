-- src/ServerScriptService/DataStore.server.luau
local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")
local Config           = require(game.ReplicatedStorage.Config)

-- In Studio without API services enabled, GetDataStore throws — fall back to memory-only
local store = nil
local storeAvailable = false
local storeOk, storeErr = pcall(function()
    store = DataStoreService:GetDataStore("SuperVHQ_v1")
    storeAvailable = true
end)
if not storeOk then
    warn("DataStore unavailable (publish the place to enable persistence): " .. tostring(storeErr))
end

-- In-memory cache: { [userId: number]: playerData }
local cache: {[number]: any} = {}

local DEFAULT_DATA = {
    currency       = Config.STARTING_CURRENCY,
    rooms          = {},
    vaultAmount    = Config.STARTING_CURRENCY,
    lastRaidedAt   = 0,
    inventorySlots = Config.STARTING_SLOTS,
    inventory      = {},
    timePlayed     = 0,   -- seconds played total
}

local function deepCopy(t)
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = type(v) == "table" and deepCopy(v) or v
    end
    return copy
end

local function loadData(player: Player)
    local key = "Player_" .. player.UserId
    if storeAvailable then
        local success, data = pcall(function()
            return store:GetAsync(key)
        end)
        if success and data then
            local merged = deepCopy(DEFAULT_DATA)
            for k, v in pairs(data) do
                merged[k] = v
            end
            cache[player.UserId] = merged
            return
        end
    end
    cache[player.UserId] = deepCopy(DEFAULT_DATA)
end

local function saveData(player: Player)
    local data = cache[player.UserId]
    if not data or not storeAvailable then return end
    local key = "Player_" .. player.UserId
    local success, err = pcall(function()
        store:SetAsync(key, data)
    end)
    if not success then
        warn("DataStore save failed for", player.Name, err)
    end
end

-- Public API used by other server scripts
local DataStore = {}

function DataStore.get(player: Player)
    return cache[player.UserId]
end

function DataStore.save(player: Player)
    saveData(player)
end

-- Auto-load on join, auto-save on leave and every 60 seconds
Players.PlayerAdded:Connect(function(player)
    loadData(player)
end)

Players.PlayerRemoving:Connect(function(player)
    saveData(player)
    cache[player.UserId] = nil
end)

-- Time-played ticker (adds 60s every minute per online player)
task.spawn(function()
    while true do
        task.wait(60)
        for _, player in ipairs(Players:GetPlayers()) do
            local data = cache[player.UserId]
            if data then
                data.timePlayed = (data.timePlayed or 0) + 60
            end
        end
    end
end)

-- Periodic auto-save
task.spawn(function()
    while true do
        task.wait(60)
        for _, player in ipairs(Players:GetPlayers()) do
            saveData(player)
        end
    end
end)

-- Load data for anyone already in the game (Studio playtest scenario)
for _, player in ipairs(Players:GetPlayers()) do
    loadData(player)
end

_G.DataStore = DataStore
