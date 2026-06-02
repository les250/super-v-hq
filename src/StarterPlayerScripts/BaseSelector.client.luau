-- src/StarterPlayerScripts/BaseSelector.client.luau
-- Base selection screen on join + "Move Base Here" signs on empty plots
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Remotes      = require(game.ReplicatedStorage.Remotes)

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

task.wait(1.5)  -- let WorldSetup finish

-- ── Selection screen ────────────────────────────────────────────────────────

local function showSelectionScreen(freePlots)
    local screen = Instance.new("ScreenGui")
    screen.Name = "BaseSelector"
    screen.ResetOnSpawn = false
    screen.Parent = playerGui

    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.4
    overlay.Parent = screen

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 640, 0, 420)
    panel.Position = UDim2.new(0.5, -320, 0.5, -210)
    panel.BackgroundColor3 = Color3.fromRGB(15, 0, 25)
    panel.BackgroundTransparency = 0.05
    panel.Parent = overlay

    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 16)
    local s = Instance.new("UIStroke", panel)
    s.Color = Color3.fromRGB(180, 0, 255); s.Thickness = 2

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 60)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(255, 220, 50)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Text = "⚡  CHOOSE YOUR VILLAIN BASE  ⚡"
    title.Parent = panel

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, 0, 0, 28)
    sub.Position = UDim2.new(0, 0, 0, 58)
    sub.BackgroundTransparency = 1
    sub.TextColor3 = Color3.fromRGB(200, 160, 255)
    sub.TextScaled = true
    sub.Font = Enum.Font.Gotham
    sub.Text = "Select an empty plot to begin your conquest"
    sub.Parent = panel

    local grid = Instance.new("Frame")
    grid.Size = UDim2.new(1, -40, 1, -120)
    grid.Position = UDim2.new(0, 20, 0, 105)
    grid.BackgroundTransparency = 1
    grid.Parent = panel

    local layout = Instance.new("UIGridLayout")
    layout.CellSize = UDim2.new(0, 170, 0, 110)
    layout.CellPadding = UDim2.new(0, 12, 0, 12)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Parent = grid

    for _, pd in ipairs(freePlots) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 170, 0, 110)
        btn.BackgroundColor3 = Color3.fromRGB(30, 0, 50)
        btn.Font = Enum.Font.GothamBold
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextScaled = true
        btn.Text = "🏚\nBase " .. pd.index .. "\n✅ FREE"
        btn.Parent = grid

        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
        local bs = Instance.new("UIStroke", btn)
        bs.Color = Color3.fromRGB(180, 0, 255); bs.Thickness = 1.5

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(70, 0, 120)}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(30, 0, 50)}):Play()
        end)
        btn.Activated:Connect(function()
            Remotes.ClaimBase:FireServer(pd.name)
            screen:Destroy()
        end)
    end
end

-- ── Move Here signs ─────────────────────────────────────────────────────────

local movePrompts: {ProximityPrompt} = {}
local moveBillboards: {BillboardGui} = {}

local function clearMoveSigns()
    for _, pp in ipairs(movePrompts) do pp:Destroy() end
    for _, bb in ipairs(moveBillboards) do bb:Destroy() end
    movePrompts = {}
    moveBillboards = {}
end

local function refreshMoveSigns()
    clearMoveSigns()

    -- Only show signs if this player has a base
    local myPlot = nil
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Folder") and obj.Name:match("^Plot_%d+$") then
            local oid = obj:FindFirstChild("OwnerId")
            if oid and oid.Value == player.UserId then
                myPlot = obj
                break
            end
        end
    end
    if not myPlot then return end

    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Folder") and obj.Name:match("^Plot_%d+$") and obj ~= myPlot then
            local occ    = obj:FindFirstChild("IsOccupied")
            local anchor = obj:FindFirstChild("MoveSignAnchor")
            if occ and not occ.Value and anchor then
                -- Proximity prompt
                local prompt = Instance.new("ProximityPrompt")
                prompt.ActionText = "Move Base Here"
                prompt.ObjectText = obj.Name
                prompt.HoldDuration = 1.5
                prompt.MaxActivationDistance = 25
                prompt.Parent = anchor
                table.insert(movePrompts, prompt)

                prompt.Triggered:Connect(function()
                    Remotes.MoveBase:FireServer(obj.Name)
                end)

                -- Billboard sign
                local bb = Instance.new("BillboardGui")
                bb.Name = "MoveSign"
                bb.Size = UDim2.new(0, 190, 0, 65)
                bb.StudsOffset = Vector3.new(0, 4, 0)
                bb.MaxDistance = 80
                bb.AlwaysOnTop = false
                bb.Parent = anchor
                table.insert(moveBillboards, bb)

                local bg = Instance.new("Frame")
                bg.Size = UDim2.new(1, 0, 1, 0)
                bg.BackgroundColor3 = Color3.fromRGB(0, 50, 0)
                bg.BackgroundTransparency = 0.15
                bg.Parent = bb

                Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 8)
                local st = Instance.new("UIStroke", bg)
                st.Color = Color3.fromRGB(0, 220, 0); st.Thickness = 2

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, -8, 1, 0)
                lbl.Position = UDim2.new(0, 4, 0, 0)
                lbl.BackgroundTransparency = 1
                lbl.TextColor3 = Color3.fromRGB(100, 255, 100)
                lbl.TextScaled = true
                lbl.Font = Enum.Font.GothamBold
                lbl.Text = "🏠  MOVE BASE HERE"
                lbl.Parent = bg
            end
        end
    end
end

-- ── Init ────────────────────────────────────────────────────────────────────

local freePlots = Remotes.GetFreePlots:InvokeServer()
if #freePlots > 1 then
    showSelectionScreen(freePlots)
end

-- Refresh signs whenever a base is assigned (own or others)
Remotes.BaseAssigned.OnClientEvent:Connect(function()
    task.wait(0.5)
    refreshMoveSigns()
end)

-- Periodic refresh to catch changes
task.spawn(function()
    while true do
        task.wait(5)
        refreshMoveSigns()
    end
end)
