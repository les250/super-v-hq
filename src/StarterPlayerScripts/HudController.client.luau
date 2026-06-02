-- src/StarterPlayerScripts/HudController.client.luau
local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local Remotes        = require(game.ReplicatedStorage.Remotes)

local player     = Players.LocalPlayer
local playerGui  = player:WaitForChild("PlayerGui")

-- Build ScreenGui
local gui = Instance.new("ScreenGui")
gui.Name            = "SuperVHQ_HUD"
gui.ResetOnSpawn    = false
gui.Parent          = playerGui

-- Currency bar (top-left)
local currencyFrame = Instance.new("Frame")
currencyFrame.Size              = UDim2.new(0, 260, 0, 50)
currencyFrame.Position          = UDim2.new(0, 16, 0, 16)
currencyFrame.BackgroundColor3  = Color3.fromRGB(20, 20, 30)
currencyFrame.BackgroundTransparency = 0.3
currencyFrame.Parent            = gui

local corner1 = Instance.new("UICorner")
corner1.CornerRadius = UDim.new(0, 8)
corner1.Parent = currencyFrame

local currencyLabel = Instance.new("TextLabel")
currencyLabel.Size              = UDim2.new(1, -12, 1, 0)
currencyLabel.Position          = UDim2.new(0, 12, 0, 0)
currencyLabel.BackgroundTransparency = 1
currencyLabel.TextColor3        = Color3.fromRGB(255, 220, 50)
currencyLabel.TextScaled        = true
currencyLabel.Font              = Enum.Font.GothamBold
currencyLabel.Text              = "💰 100 / 1000"
currencyLabel.TextXAlignment    = Enum.TextXAlignment.Left
currencyLabel.Parent            = currencyFrame

-- Raid notification toast (centre-top, hidden by default)
local toastFrame = Instance.new("Frame")
toastFrame.Size             = UDim2.new(0, 400, 0, 60)
toastFrame.Position         = UDim2.new(0.5, -200, 0, -70) -- starts off-screen
toastFrame.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
toastFrame.Parent           = gui

local corner2 = Instance.new("UICorner")
corner2.CornerRadius = UDim.new(0, 8)
corner2.Parent = toastFrame

local toastLabel = Instance.new("TextLabel")
toastLabel.Size             = UDim2.new(1, -16, 1, 0)
toastLabel.Position         = UDim2.new(0, 8, 0, 0)
toastLabel.BackgroundTransparency = 1
toastLabel.TextColor3       = Color3.fromRGB(255, 255, 255)
toastLabel.TextScaled       = true
toastLabel.Font             = Enum.Font.Gotham
toastLabel.Text             = ""
toastLabel.Parent           = toastFrame

local function showToast(message: string)
    toastLabel.Text = message
    -- Slide in
    TweenService:Create(toastFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Position = UDim2.new(0.5, -200, 0, 16) }
    ):Play()
    -- Slide out after 3.5 seconds
    task.delay(3.5, function()
        TweenService:Create(toastFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { Position = UDim2.new(0.5, -200, 0, -70) }
        ):Play()
    end)
end

-- Update currency label
Remotes.UpdateCurrency.OnClientEvent:Connect(function(amount: number, cap: number)
    currencyLabel.Text = string.format("💰 %d / %d", math.floor(amount), cap)
end)

-- Raid notification
Remotes.RaidNotification.OnClientEvent:Connect(function(raiderName: string, stolen: number)
    showToast(string.format("⚠️ %s raided your HQ! -%d currency", raiderName, stolen))
end)

-- Fetch initial data on load
task.spawn(function()
    local data = Remotes.GetPlayerData:InvokeServer()
    if data then
        local Config   = require(game.ReplicatedStorage.Config)
        local RoomData = require(game.ReplicatedStorage.RoomData)
        local cap      = RoomData.getVaultCap(data.rooms, Config.BASE_VAULT_CAP)
        currencyLabel.Text = string.format("💰 %d / %d", math.floor(data.vaultAmount), cap)
    end
end)
