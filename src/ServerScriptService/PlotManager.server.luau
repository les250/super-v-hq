-- src/ServerScriptService/PlotManager.server.luau
local Players   = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Remotes
task.spawn(function()
    task.wait(0.2)
    Remotes = require(game.ReplicatedStorage.Remotes)
end)

local function getDS()
    while not _G.DataStore do task.wait(0.1) end
    return _G.DataStore
end

local playerPlots: {[number]: Folder} = {}

local function getPlots(): {Folder}
    local plots = {}
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Folder") and obj.Name:match("^Plot_%d+$") then
            table.insert(plots, obj)
        end
    end
    table.sort(plots, function(a, b) return a.Name < b.Name end)
    return plots
end

local function getFreePlots(): {Folder}
    local free = {}
    for _, plot in ipairs(getPlots()) do
        local occ = plot:FindFirstChild("IsOccupied")
        if occ and not occ.Value then
            table.insert(free, plot)
        end
    end
    return free
end

local function setPlotOccupied(plot: Folder, player: Player)
    local occ = plot:FindFirstChild("IsOccupied")
    if occ then occ.Value = true end
    local oid = plot:FindFirstChild("OwnerId")
    if oid then oid.Value = player.UserId end
    playerPlots[player.UserId] = plot
    local spawn = plot:FindFirstChild("PlotSpawn")
    if spawn then
        player.RespawnLocation = spawn
        -- Teleport character to spawn immediately (don't wait for death)
        local char = player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = spawn.CFrame * CFrame.new(0, 3, 0)
            end
        end
    end
end

local function clearPlot(plot: Folder)
    local occ = plot:FindFirstChild("IsOccupied")
    if occ then occ.Value = false end
    local oid = plot:FindFirstChild("OwnerId")
    if oid then oid.Value = 0 end
end

local function freePlot(player: Player)
    local plot = playerPlots[player.UserId]
    if plot then
        clearPlot(plot)
        playerPlots[player.UserId] = nil
    end
    player.RespawnLocation = nil
end

local PlotManager = {}

function PlotManager.getPlot(player: Player): Folder?
    return playerPlots[player.UserId]
end

function PlotManager.getPlotByUserId(userId: number): Folder?
    return playerPlots[userId]
end

local function tryAutoAssign(player: Player)
    task.wait(1) -- wait for WorldSetup to finish building plots
    if playerPlots[player.UserId] then return end
    local free = getFreePlots()
    if #free == 1 then
        setPlotOccupied(free[1], player)
        while not Remotes do task.wait(0.1) end
        Remotes.BaseAssigned:FireClient(player, free[1].Name)
    elseif #free == 0 then
        warn("No free plots for", player.Name)
    end
    -- if #free > 1: client selection screen handles it via ClaimBase
end

Players.PlayerAdded:Connect(function(player)
    task.spawn(tryAutoAssign, player)
end)

Players.PlayerRemoving:Connect(function(player)
    freePlot(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(tryAutoAssign, player)
end

-- Remote handlers
task.spawn(function()
    while not Remotes do task.wait(0.1) end

    Remotes.GetFreePlots.OnServerInvoke = function(_player)
        local result = {}
        for _, plot in ipairs(getFreePlots()) do
            local pad = plot:FindFirstChild("DropPad_lab")
            table.insert(result, {
                name     = plot.Name,
                index    = tonumber(plot.Name:match("%d+")) or 0,
                position = pad and pad.Position or Vector3.new(0, 0, 0),
            })
        end
        return result
    end

    Remotes.ClaimBase.OnServerEvent:Connect(function(player, plotName)
        if playerPlots[player.UserId] then return end
        local plot = Workspace:FindFirstChild(plotName)
        if not plot then return end
        local occ = plot:FindFirstChild("IsOccupied")
        if occ and occ.Value then return end
        setPlotOccupied(plot, player)
        Remotes.BaseAssigned:FireClient(player, plot.Name)
    end)

    Remotes.MoveBase.OnServerEvent:Connect(function(player, plotName)
        local newPlot = Workspace:FindFirstChild(plotName)
        if not newPlot then return end
        local occ = newPlot:FindFirstChild("IsOccupied")
        if occ and occ.Value then return end
        -- Reset room data, keep currency and inventory
        local ds = getDS()
        local data = ds.get(player)
        if data then data.rooms = {} end
        -- Clear minions from old base
        local mm = _G.MinionManager
        if mm then mm.onBarracksBuilt(player, 0) end
        -- Hide rooms on old plot for this client
        Remotes.ResetPlot:FireClient(player)
        freePlot(player)
        setPlotOccupied(newPlot, player)
        Remotes.BaseAssigned:FireClient(player, newPlot.Name)
    end)

    Remotes.TeleportToPlot.OnServerEvent:Connect(function(player, targetUserId)
        -- Validate: player must have Escape Pod Bay built
        local ds = getDS()
        local data = ds.get(player)
        if not data or not data.rooms["escape_pod_bay"] or data.rooms["escape_pod_bay"] == 0 then return end

        local targetPlot = playerPlots[targetUserId]
        if not targetPlot then return end

        local spawn = targetPlot:FindFirstChild("PlotSpawn")
        if not spawn then return end

        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = spawn.CFrame * CFrame.new(0, 4, 0)
        end
    end)
end)

_G.PlotManager = PlotManager
