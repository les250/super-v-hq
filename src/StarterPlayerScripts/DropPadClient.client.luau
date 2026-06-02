-- src/StarterPlayerScripts/DropPadClient.client.luau
local Players          = game:GetService("Players")
local Remotes          = require(game.ReplicatedStorage.Remotes)

local function titleCase(s: string): string
    return (s:gsub("_", " "):gsub("(%a)([%a]*)", function(first, rest)
        return first:upper() .. rest:lower()
    end))
end

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Wait for PlotManager to assign us a plot
local function getMyPlot(): Folder
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

-- Add ProximityPrompt to a drop pad part
local function setupDropPad(part: Part, roomId: string)
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText    = "Build " .. titleCase(roomId)
    prompt.ObjectText    = "Drop Pad"
    prompt.HoldDuration  = 0.5
    prompt.MaxActivationDistance = 8
    prompt.Parent = part

    prompt.Triggered:Connect(function()
        Remotes.BuyRoom:FireServer(roomId)
    end)
end

-- Add upgrade prompt inside a built room model
local function setupUpgradePad(roomModel: Model, roomId: string)
    local upgradePart = Instance.new("Part")
    upgradePart.Name      = "UpgradePad"
    upgradePart.Size      = Vector3.new(4, 0.5, 4)
    upgradePart.Anchored  = true
    upgradePart.BrickColor = BrickColor.new("Bright yellow")
    upgradePart.Parent    = roomModel

    -- Position at room centre, on the floor
    upgradePart.CFrame = roomModel:GetPivot() * CFrame.new(0, -roomModel:GetExtentsSize().Y / 2, 0)

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText   = "Upgrade " .. titleCase(roomId)
    prompt.ObjectText   = "Upgrade Pad"
    prompt.HoldDuration = 0.5
    prompt.MaxActivationDistance = 8
    prompt.Parent = upgradePart

    prompt.Triggered:Connect(function()
        Remotes.UpgradeRoom:FireServer(roomId)
    end)
end

-- Wire up all drop pads found in this plot
for _, obj in ipairs(plot:GetDescendants()) do
    if obj:IsA("Part") then
        local roomId = obj.Name:match("^DropPad_(.+)$")
        if roomId then
            setupDropPad(obj, roomId)
        end
    end
end

-- When a room is built, hide its drop pad, show the pre-placed room model, add upgrade pad
-- Room models are pre-placed in Studio as Model "Room_<roomId>" with all parts set
-- Transparency=1 so they are invisible until bought.
Remotes.RoomBuilt.OnClientEvent:Connect(function(roomId: string, tier: number)
    -- Hide the drop pad for this room
    for _, obj in ipairs(plot:GetDescendants()) do
        if obj.Name == "DropPad_" .. roomId then
            obj.Transparency = 1
            local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
            if prompt then prompt.Enabled = false end
        end
    end

    -- Make the pre-placed room model visible (all parts → Transparency 0)
    local roomModel = plot:FindFirstChild("Room_" .. roomId)
    if roomModel and roomModel:IsA("Model") then
        for _, part in ipairs(roomModel:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 0
            end
        end
        -- If tier 1 just built, add the upgrade proximity prompt
        if tier == 1 then
            setupUpgradePad(roomModel, roomId)
        end
    end
end)
