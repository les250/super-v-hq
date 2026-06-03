-- src/StarterPlayerScripts/InventoryHudController.client.luau
local Players = game:GetService("Players")
local Remotes = require(game.ReplicatedStorage.Remotes)
local Config  = require(game.ReplicatedStorage.Config)

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

task.wait(2)

local screen = Instance.new("ScreenGui")
screen.Name = "InventorySlotUI"; screen.ResetOnSpawn = false; screen.Parent = playerGui

-- Slot counter shown below the HUD currency block
local slotFrame = Instance.new("Frame")
slotFrame.Size = UDim2.new(0, 260, 0, 28)
slotFrame.Position = UDim2.new(0, 16, 0, 162)
slotFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
slotFrame.BackgroundTransparency = 0.3
slotFrame.Parent = screen
Instance.new("UICorner", slotFrame).CornerRadius = UDim.new(0, 6)

local slotLabel = Instance.new("TextLabel")
slotLabel.Size = UDim2.new(1, -8, 1, 0)
slotLabel.Position = UDim2.new(0, 4, 0, 0)
slotLabel.BackgroundTransparency = 1
slotLabel.TextColor3 = Color3.fromRGB(200, 160, 255)
slotLabel.TextScaled = true
slotLabel.Font = Enum.Font.Gotham
slotLabel.TextXAlignment = Enum.TextXAlignment.Left
slotLabel.Text = string.format("🎒 Item Slots: %d / %d", Config.STARTING_SLOTS, Config.MAX_SLOTS)
slotLabel.Parent = slotFrame

-- Load initial slot count
task.spawn(function()
    local data = Remotes.GetPlayerData:InvokeServer()
    if data then
        local s = data.inventorySlots or Config.STARTING_SLOTS
        slotLabel.Text = string.format("🎒 Item Slots: %d / %d", s, Config.MAX_SLOTS)
    end
end)

-- Update when slots are purchased
Remotes.SlotCountUpdate.OnClientEvent:Connect(function(current, max)
    slotLabel.Text = string.format("🎒 Item Slots: %d / %d", current, max)
end)

-- Wire ProximityPrompt on SlotKiosk in player's plot
local function getMyPlot()
    while true do
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Folder") and obj.Name:match("^Plot_%d+$") then
                local oid = obj:FindFirstChild("OwnerId")
                if oid and oid.Value == player.UserId then return obj end
            end
        end
        task.wait(0.5)
    end
end

task.spawn(function()
    local plot = getMyPlot()
    local function wireKiosk(obj)
        if obj.Name ~= "SlotKiosk" or not obj:IsA("Part") then return end
        if obj:FindFirstChildOfClass("ProximityPrompt") then return end
        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = string.format("Buy Slot (💰%d)", Config.SLOT_COST)
        prompt.ObjectText = "Item Slots"
        prompt.HoldDuration = 0.5
        prompt.MaxActivationDistance = 8
        prompt.Parent = obj
        prompt.Triggered:Connect(function()
            Remotes.BuyInventorySlot:FireServer()
        end)
    end
    for _, obj in ipairs(plot:GetDescendants()) do wireKiosk(obj) end
    plot.DescendantAdded:Connect(wireKiosk)
end)
