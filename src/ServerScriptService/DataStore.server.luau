-- src/ServerScriptService/DataStore.server.luau
local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")
local Config           = require(game.ReplicatedStorage.Config)

local store = DataStoreService:GetDataStore("SuperVHQ_v1")

-- In-memory cache: { [userId: number]: playerData }
local cache: {[number]: any} = {}

local DEFAULT_DATA = {
    currency     = Config.STARTING_CURRENCY,
    rooms        = {},
    vaultAmount  = 0,
    lastRaidedAt = 0,
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
    local success, data = pcall(function()
        return store:GetAsync(key)
    end)
    if success and data then
        -- Merge with defaults so new fields appear for existing players
        local merged = deepCopy(DEFAULT_DATA)
        for k, v in pairs(data) do
            merged[k] = v
        end
        cache[player.UserId] = merged
    else
        cache[player.UserId] = deepCopy(DEFAULT_DATA)
    end
end

local function saveData(player: Player)
    local data = cache[player.UserId]
    if not data then return end
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
