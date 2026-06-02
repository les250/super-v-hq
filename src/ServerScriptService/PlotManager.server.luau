-- src/ServerScriptService/PlotManager.server.luau
local Players   = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- { [userId: number]: plotFolder }
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

local function assignPlot(player: Player): Folder?
    for _, plot in ipairs(getPlots()) do
        local occupied = plot:FindFirstChild("IsOccupied")
        if occupied and not occupied.Value then
            occupied.Value = true
            local ownerId = plot:FindFirstChild("OwnerId")
            if ownerId then
                ownerId.Value = player.UserId
            end
            playerPlots[player.UserId] = plot
            return plot
        end
    end
    return nil
end

local function freePlot(player: Player)
    local plot = playerPlots[player.UserId]
    if plot then
        local occupied = plot:FindFirstChild("IsOccupied")
        if occupied then occupied.Value = false end
        local ownerId = plot:FindFirstChild("OwnerId")
        if ownerId then ownerId.Value = 0 end
        playerPlots[player.UserId] = nil
    end
end

-- Public API
local PlotManager = {}

function PlotManager.getPlot(player: Player): Folder?
    return playerPlots[player.UserId]
end

function PlotManager.getPlotByUserId(userId: number): Folder?
    return playerPlots[userId]
end

Players.PlayerAdded:Connect(function(player)
    local plot = assignPlot(player)
    if not plot then
        warn("No free plot for", player.Name)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    freePlot(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
    assignPlot(player)
end

_G.PlotManager = PlotManager
