-- src/StarterPlayerScripts/SettingsController.client.luau
local Players = game:GetService("Players")
local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

task.wait(2)

local screen = Instance.new("ScreenGui")
screen.Name="SettingsUI"; screen.ResetOnSpawn=false; screen.Parent=playerGui

-- ⚙ Gear button (bottom-left)
local btn = Instance.new("TextButton")
btn.Size=UDim2.new(0,38,0,38); btn.Position=UDim2.new(0,16,1,-54)
btn.BackgroundColor3=Color3.fromRGB(30,30,50); btn.BackgroundTransparency=0.2
btn.TextColor3=Color3.fromRGB(180,180,255); btn.TextScaled=true
btn.Font=Enum.Font.GothamBold; btn.Text="⚙"
btn.Parent=screen
Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8)

-- Settings panel (slides up from bottom-left)
local panel = Instance.new("Frame")
panel.Size=UDim2.new(0,260,0,0); panel.AutomaticSize=Enum.AutomaticSize.Y
panel.Position=UDim2.new(0,16,1,-58)
panel.BackgroundColor3=Color3.fromRGB(15,15,30); panel.BackgroundTransparency=0.1
panel.Visible=false; panel.Parent=screen
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,10)
Instance.new("UIStroke",panel).Color=Color3.fromRGB(120,100,200)

local titleL=Instance.new("TextLabel"); titleL.Size=UDim2.new(1,0,0,30)
titleL.BackgroundTransparency=1; titleL.TextColor3=Color3.fromRGB(200,180,255)
titleL.TextScaled=true; titleL.Font=Enum.Font.GothamBold; titleL.Text="⚙  SETTINGS"
titleL.Parent=panel

-- State
local settings = {sfx=true, costLabels=true, skyLabel=true}

-- Toggle row builder
local yOff = 34
local function makeToggle(label: string, key: string, onToggle: (boolean) -> ())
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,-10,0,36)
    row.Position=UDim2.new(0,5,0,yOff); row.BackgroundTransparency=1; row.Parent=panel
    yOff += 40

    local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(0.65,0,1,0)
    lbl.BackgroundTransparency=1; lbl.TextColor3=Color3.fromRGB(200,180,255)
    lbl.TextScaled=true; lbl.Font=Enum.Font.Gotham; lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.Text=label; lbl.Parent=row

    local tog=Instance.new("TextButton"); tog.Size=UDim2.new(0,72,0,28)
    tog.Position=UDim2.new(1,-76,0.5,-14); tog.TextScaled=true; tog.Font=Enum.Font.GothamBold
    tog.Parent=row
    Instance.new("UICorner",tog).CornerRadius=UDim.new(0,6)

    local function refresh()
        local on = settings[key]
        tog.Text = on and "ON" or "OFF"
        tog.BackgroundColor3 = on and Color3.fromRGB(0,100,0) or Color3.fromRGB(80,0,0)
        tog.TextColor3 = Color3.new(1,1,1)
    end
    refresh()

    tog.Activated:Connect(function()
        settings[key] = not settings[key]
        refresh()
        onToggle(settings[key])
    end)
end

makeToggle("🔊 Sound Effects", "sfx", function(on)
    local sc = _G.SoundController
    if sc then sc.setEnabled(on) end
end)

makeToggle("💰 Cost Labels", "costLabels", function(on)
    -- Toggle all CostLabel BillboardGuis visible to this client
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "CostLabel" and obj:IsA("BillboardGui") then
            obj.Enabled = on
        end
    end
end)

makeToggle("🌌 Sky Name Tag", "skyLabel", function(on)
    -- Toggle all SkyLabel BillboardGuis
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "SkyLabel" and obj:IsA("BillboardGui") then
            obj.Enabled = on
        end
    end
end)

-- Toggle panel
btn.Activated:Connect(function()
    panel.Visible = not panel.Visible
    btn.Text = panel.Visible and "✕" or "⚙"
    -- Panel anchors above the button, so position it relative
    panel.Position = UDim2.new(0, 16, 1, -58 - (panel.AbsoluteSize.Y > 0 and panel.AbsoluteSize.Y or 160))
end)
