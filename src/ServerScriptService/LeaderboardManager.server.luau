-- src/ServerScriptService/LeaderboardManager.server.luau
local Players = game:GetService("Players")
local Remotes = require(game.ReplicatedStorage.Remotes)

local function getDS()
    while not _G.DataStore do task.wait(0.1) end
    return _G.DataStore
end

local function formatTime(secs: number): string
    local h = math.floor(secs / 3600)
    local m = math.floor((secs % 3600) / 60)
    if h > 0 then
        return string.format("%dh %dm", h, m)
    else
        return string.format("%dm", m)
    end
end

local function buildAndBroadcast()
    local ds   = getDS()
    local moneyRows = {}
    local timeRows  = {}

    for _, player in ipairs(Players:GetPlayers()) do
        local data = ds.get(player)
        if data then
            table.insert(moneyRows, {name=player.DisplayName, value=data.vaultAmount or 0})
            table.insert(timeRows,  {name=player.DisplayName, value=data.timePlayed  or 0})
        end
    end

    table.sort(moneyRows, function(a,b) return a.value > b.value end)
    table.sort(timeRows,  function(a,b) return a.value > b.value end)

    local moneyTop, timeTop = {}, {}
    for i = 1, math.min(10, #moneyRows) do
        moneyTop[i] = {rank=i, name=moneyRows[i].name, value=moneyRows[i].value}
    end
    for i = 1, math.min(10, #timeRows) do
        timeTop[i]  = {rank=i, name=timeRows[i].name,  value=formatTime(timeRows[i].value)}
    end

    Remotes.LeaderboardUpdate:FireAllClients(moneyTop, timeTop)
end

-- Update every 60 seconds
task.spawn(function()
    while true do task.wait(60); buildAndBroadcast() end
end)

-- Update on join/leave
Players.PlayerAdded:Connect(function()   task.wait(3); buildAndBroadcast() end)
Players.PlayerRemoving:Connect(function() task.wait(1); buildAndBroadcast() end)
