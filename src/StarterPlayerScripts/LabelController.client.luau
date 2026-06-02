-- src/StarterPlayerScripts/LabelController.client.luau
-- Shows cost labels only on the owning player's plot, only within 20 studs
local Players = game:GetService("Players")
local Remotes = require(game.ReplicatedStorage.Remotes)

local player = Players.LocalPlayer

local costs = {
    lab=100, armory=400, minion_barracks=1000,
    war_room=3000, vault=8000, escape_pod_bay=20000
}
local roomNames = {
    lab="Lab", armory="Armory", minion_barracks="Minion Barracks",
    war_room="War Room", vault="Vault", escape_pod_bay="Escape Pod Bay"
}

task.wait()

local function getMyPlot()
    while true do
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Folder") and obj.Name:match("^Plot_%d+$") then
                local ownerId = obj:FindFirstChild("OwnerId")
                if ownerId and ownerId.Value == player.UserId then
                    return obj
                end
            end
        end
        task.wait(0.5)
    end
end

local plot = getMyPlot()

local function makeLabel(pad, roomId)
    local bb = Instance.new("BillboardGui")
    bb.Name = "CostLabel"
    bb.Size = UDim2.new(0, 170, 0, 65)
    bb.StudsOffset = Vector3.new(0, 5, 0)
    bb.MaxDistance = 20
    bb.AlwaysOnTop = false
    bb.Parent = pad

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(15, 0, 25)
    bg.BackgroundTransparency = 0.2
    bg.Parent = bb

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = bg

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(180, 0, 255)
    stroke.Thickness = 2
    stroke.Parent = bg

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -8, 0.5, 0)
    title.Position = UDim2.new(0, 4, 0, 0)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(255, 220, 50)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Text = roomNames[roomId]
    title.Parent = bg

    local costLabel = Instance.new("TextLabel")
    costLabel.Size = UDim2.new(1, -8, 0.5, 0)
    costLabel.Position = UDim2.new(0, 4, 0.5, 0)
    costLabel.BackgroundTransparency = 1
    costLabel.TextColor3 = Color3.fromRGB(200, 160, 255)
    costLabel.TextScaled = true
    costLabel.Font = Enum.Font.Gotham
    costLabel.Text = "💰 " .. costs[roomId]
    costLabel.Parent = bg
end

-- Create labels on all unbuilt drop pads
for roomId in pairs(costs) do
    local pad = plot:FindFirstChild("DropPad_" .. roomId)
    if pad then
        makeLabel(pad, roomId)
    end
end

-- Remove label when room is bought
Remotes.RoomBuilt.OnClientEvent:Connect(function(roomId)
    local pad = plot:FindFirstChild("DropPad_" .. roomId)
    if pad then
        local label = pad:FindFirstChild("CostLabel")
        if label then label:Destroy() end
    end
end)
