-- src/StarterPlayerScripts/EscapePodController.client.luau
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Remotes      = require(game.ReplicatedStorage.Remotes)

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local COOLDOWN  = 30

task.wait(2)

local screen = Instance.new("ScreenGui")
screen.Name="EscapePodUI"; screen.ResetOnSpawn=false; screen.Parent=playerGui

-- Toggle button (below War Room spy button on right side)
local btn = Instance.new("TextButton")
btn.Size=UDim2.new(0,38,0,80); btn.Position=UDim2.new(1,-38,0.5,158)
btn.BackgroundColor3=Color3.fromRGB(0,40,80); btn.BackgroundTransparency=0.2
btn.TextColor3=Color3.fromRGB(80,200,255); btn.TextScaled=true
btn.Font=Enum.Font.GothamBold; btn.Text="🚀\nFLY"
btn.Parent=screen
Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8)

-- Player picker panel
local panel=Instance.new("Frame"); panel.Name="PodPanel"
panel.Size=UDim2.new(0,260,0,0); panel.AutomaticSize=Enum.AutomaticSize.Y
panel.Position=UDim2.new(1,4,0.5,-40)
panel.BackgroundColor3=Color3.fromRGB(0,15,30); panel.BackgroundTransparency=0.1
panel.Parent=screen
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,10)
local pst=Instance.new("UIStroke",panel); pst.Color=Color3.fromRGB(0,160,255); pst.Thickness=1.5

local titleL=Instance.new("TextLabel"); titleL.Size=UDim2.new(1,0,0,30)
titleL.BackgroundTransparency=1; titleL.TextColor3=Color3.fromRGB(80,200,255)
titleL.TextScaled=true; titleL.Font=Enum.Font.GothamBold
titleL.Text="🚀  TELEPORT TO BASE"; titleL.Parent=panel

local listFrame=Instance.new("Frame"); listFrame.Size=UDim2.new(1,-8,0,0)
listFrame.Position=UDim2.new(0,4,0,34); listFrame.AutomaticSize=Enum.AutomaticSize.Y
listFrame.BackgroundTransparency=1; listFrame.Parent=panel
Instance.new("UIListLayout",listFrame).Padding=UDim.new(0,3)

local cooldownTimer = 0

local function setCooldown()
    cooldownTimer = COOLDOWN
    btn.BackgroundTransparency = 0.6
    task.spawn(function()
        while cooldownTimer > 0 do
            task.wait(1); cooldownTimer -= 1
            btn.Text = "🚀\n"..(cooldownTimer > 0 and cooldownTimer.."s" or "FLY")
        end
        btn.BackgroundTransparency = 0.2
    end)
end

local isOpen = false
local OPEN_P = UDim2.new(1,-264,0.5,-40)
local CLOSE_P = UDim2.new(1,4,0.5,-40)

local function populate()
    for _,c in ipairs(listFrame:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    for _,p in ipairs(Players:GetPlayers()) do
        if p == player then continue end
        local rb=Instance.new("TextButton"); rb.Size=UDim2.new(1,0,0,34)
        rb.BackgroundColor3=Color3.fromRGB(0,25,45); rb.BackgroundTransparency=0.3
        rb.TextColor3=Color3.fromRGB(255,255,255); rb.TextScaled=true; rb.Font=Enum.Font.Gotham
        rb.Text="  🚀  "..p.DisplayName
        rb.TextXAlignment=Enum.TextXAlignment.Left; rb.Parent=listFrame
        Instance.new("UICorner",rb).CornerRadius=UDim.new(0,4)
        rb.Activated:Connect(function()
            if cooldownTimer > 0 then return end
            Remotes.TeleportToPlot:FireServer(p.UserId)
            setCooldown()
            TweenService:Create(panel,TweenInfo.new(0.2),{Position=CLOSE_P}):Play()
            isOpen=false; btn.Text="🚀\nFLY"
        end)
    end
end

btn.Activated:Connect(function()
    if cooldownTimer > 0 then return end
    isOpen = not isOpen
    TweenService:Create(panel,TweenInfo.new(0.2),{Position=isOpen and OPEN_P or CLOSE_P}):Play()
    btn.Text = isOpen and "🚀\n✕" or "🚀\nFLY"
    if isOpen then populate() end
end)
