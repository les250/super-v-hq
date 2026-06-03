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

-- Currency bar (top-left) — includes currency, income, and promo button
local currencyFrame = Instance.new("Frame")
currencyFrame.Size              = UDim2.new(0, 260, 0, 112)
currencyFrame.Position          = UDim2.new(0, 16, 0, 16)
currencyFrame.BackgroundColor3  = Color3.fromRGB(20, 20, 30)
currencyFrame.BackgroundTransparency = 0.3
currencyFrame.Parent            = gui

local corner1 = Instance.new("UICorner")
corner1.CornerRadius = UDim.new(0, 8)
corner1.Parent = currencyFrame

local currencyLabel = Instance.new("TextLabel")
currencyLabel.Size              = UDim2.new(1, -12, 0, 42)
currencyLabel.Position          = UDim2.new(0, 12, 0, 0)
currencyLabel.BackgroundTransparency = 1
currencyLabel.TextColor3        = Color3.fromRGB(255, 220, 50)
currencyLabel.TextScaled        = true
currencyLabel.Font              = Enum.Font.GothamBold
currencyLabel.Text              = "💰 100 / 1000"
currencyLabel.TextXAlignment    = Enum.TextXAlignment.Left
currencyLabel.Parent            = currencyFrame

-- Income per minute (below currency)
local incomeLabel = Instance.new("TextLabel")
incomeLabel.Size              = UDim2.new(1, -12, 0, 26)
incomeLabel.Position          = UDim2.new(0, 12, 0, 44)
incomeLabel.BackgroundTransparency = 1
incomeLabel.TextColor3        = Color3.fromRGB(100, 255, 140)
incomeLabel.TextScaled        = true
incomeLabel.Font              = Enum.Font.Gotham
incomeLabel.Text              = "📈 +0 /min"
incomeLabel.TextXAlignment    = Enum.TextXAlignment.Left
incomeLabel.Parent            = currencyFrame

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

-- Update currency + income labels
Remotes.UpdateCurrency.OnClientEvent:Connect(function(amount: number, cap: number, incPerMin: number)
    currencyLabel.Text = string.format("💰 %d / %d", math.floor(amount), cap)
    if incomeLabel then
        incomeLabel.Text = string.format("📈 +%d /min", incPerMin or 0)
    end
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

-- ── Promo code UI ──────────────────────────────────────────────────────────

-- Promo button lives INSIDE the currency frame (always visible, no clipping issues)
local promoBtn = Instance.new("TextButton")
promoBtn.Size     = UDim2.new(1, -16, 0, 30)
promoBtn.Position = UDim2.new(0, 8, 0, 76)
promoBtn.BackgroundColor3 = Color3.fromRGB(60, 0, 100)
promoBtn.BackgroundTransparency = 0.1
promoBtn.TextColor3 = Color3.fromRGB(220, 170, 255)
promoBtn.TextScaled = true; promoBtn.Font = Enum.Font.GothamBold
promoBtn.Text = "🎁  Enter Promo Code"
promoBtn.Parent = currencyFrame   -- child of currency frame, always visible
Instance.new("UICorner", promoBtn).CornerRadius = UDim.new(0, 6)
local pbs = Instance.new("UIStroke", promoBtn)
pbs.Color = Color3.fromRGB(160, 0, 220); pbs.Thickness = 1.5

-- Input panel (pops up below currency block)
local promoPanel = Instance.new("Frame")
promoPanel.Size     = UDim2.new(0, 260, 0, 100)
promoPanel.Position = UDim2.new(0, 0, 1, 4)   -- anchored below currencyFrame
promoPanel.BackgroundColor3 = Color3.fromRGB(12, 0, 22)
promoPanel.BackgroundTransparency = 0.1
promoPanel.Visible  = false
promoPanel.Parent   = currencyFrame
Instance.new("UICorner", promoPanel).CornerRadius = UDim.new(0, 10)
local pps = Instance.new("UIStroke", promoPanel); pps.Color = Color3.fromRGB(160,0,220); pps.Thickness=1.5

local promoTitle = Instance.new("TextLabel")
promoTitle.Size = UDim2.new(1,0,0,28); promoTitle.BackgroundTransparency=1
promoTitle.TextColor3=Color3.fromRGB(255,220,50); promoTitle.TextScaled=true
promoTitle.Font=Enum.Font.GothamBold; promoTitle.Text="🎁  Enter Promo Code"
promoTitle.Parent=promoPanel

local promoInput = Instance.new("TextBox")
promoInput.Size     = UDim2.new(1,-100,0,34)
promoInput.Position = UDim2.new(0,8,0,32)
promoInput.BackgroundColor3 = Color3.fromRGB(30,0,50)
promoInput.TextColor3 = Color3.fromRGB(255,255,255)
promoInput.PlaceholderText = "Enter code..."
promoInput.PlaceholderColor3 = Color3.fromRGB(120,90,150)
promoInput.TextScaled = true; promoInput.Font = Enum.Font.Gotham
promoInput.ClearTextOnFocus = false
promoInput.Parent = promoPanel
Instance.new("UICorner", promoInput).CornerRadius = UDim.new(0, 6)

local promoSubmit = Instance.new("TextButton")
promoSubmit.Size     = UDim2.new(0,80,0,34)
promoSubmit.Position = UDim2.new(1,-88,0,32)
promoSubmit.BackgroundColor3 = Color3.fromRGB(80,0,140)
promoSubmit.TextColor3 = Color3.fromRGB(255,255,255)
promoSubmit.TextScaled = true; promoSubmit.Font = Enum.Font.GothamBold
promoSubmit.Text = "Redeem"
promoSubmit.Parent = promoPanel
Instance.new("UICorner", promoSubmit).CornerRadius = UDim.new(0, 6)

local promoStatus = Instance.new("TextLabel")
promoStatus.Size = UDim2.new(1,-16,0,24); promoStatus.Position=UDim2.new(0,8,0,70)
promoStatus.BackgroundTransparency=1; promoStatus.TextScaled=true
promoStatus.Font=Enum.Font.Gotham; promoStatus.Text=""
promoStatus.TextXAlignment=Enum.TextXAlignment.Left
promoStatus.Parent=promoPanel

-- Toggle panel
promoBtn.Activated:Connect(function()
    promoPanel.Visible = not promoPanel.Visible
    if promoPanel.Visible then promoInput:CaptureFocus() end
end)

-- Submit
local function redeem()
    local code = promoInput.Text
    if code == "" then return end
    promoSubmit.Active = false; promoSubmit.Text = "..."
    promoStatus.TextColor3 = Color3.fromRGB(200,200,200)
    promoStatus.Text = "Checking..."

    local result = Remotes.RedeemCode:InvokeServer(code)
    promoSubmit.Active = true; promoSubmit.Text = "Redeem"

    if result.ok then
        promoStatus.TextColor3 = Color3.fromRGB(100,255,120)
        promoStatus.Text = result.message
        promoInput.Text = ""
        showToast(result.message)
        task.delay(2, function() promoPanel.Visible = false end)
    else
        promoStatus.TextColor3 = Color3.fromRGB(255,100,100)
        promoStatus.Text = result.message
    end
end

promoSubmit.Activated:Connect(redeem)
promoInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then redeem() end
end)
