-- src/StarterPlayerScripts/WarRoomController.client.luau
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Remotes      = require(game.ReplicatedStorage.Remotes)

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

task.wait(2)

local screen = Instance.new("ScreenGui")
screen.Name = "WarRoomUI"; screen.ResetOnSpawn = false; screen.Parent = playerGui

-- Toggle button (below Objectives button on right side)
local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0,38,0,90); btn.Position = UDim2.new(1,-38,0.5,60)
btn.BackgroundColor3 = Color3.fromRGB(80,0,0); btn.BackgroundTransparency=0.2
btn.TextColor3 = Color3.fromRGB(255,100,100); btn.TextScaled=true
btn.Font = Enum.Font.GothamBold; btn.Text = "🕵\nSPY"
btn.Parent = screen
Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8)

-- Panel (slides in from right)
local panel = Instance.new("Frame")
panel.Name="SpyPanel"; panel.Size=UDim2.new(0,280,0.7,0)
panel.Position=UDim2.new(1,4,0.15,0)
panel.BackgroundColor3=Color3.fromRGB(20,0,0); panel.BackgroundTransparency=0.1
panel.Parent=screen
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,10)
local pst=Instance.new("UIStroke",panel); pst.Color=Color3.fromRGB(220,0,0); pst.Thickness=1.5

local titleLbl=Instance.new("TextLabel"); titleLbl.Size=UDim2.new(1,-40,0,32)
titleLbl.Position=UDim2.new(0,5,0,4); titleLbl.BackgroundTransparency=1
titleLbl.TextColor3=Color3.fromRGB(255,80,80); titleLbl.TextScaled=true
titleLbl.Font=Enum.Font.GothamBold; titleLbl.Text="🕵  SPY NETWORK"
titleLbl.TextXAlignment=Enum.TextXAlignment.Left; titleLbl.Parent=panel

local closeBtn=Instance.new("TextButton"); closeBtn.Size=UDim2.new(0,32,0,32)
closeBtn.Position=UDim2.new(1,-36,0,4); closeBtn.BackgroundColor3=Color3.fromRGB(60,0,0)
closeBtn.BackgroundTransparency=0.3; closeBtn.TextColor3=Color3.fromRGB(255,80,80)
closeBtn.TextScaled=true; closeBtn.Font=Enum.Font.GothamBold; closeBtn.Text="✕"
closeBtn.Parent=panel; Instance.new("UICorner",closeBtn).CornerRadius=UDim.new(0,6)

local noWarRoom=Instance.new("TextLabel"); noWarRoom.Size=UDim2.new(1,-10,0,50)
noWarRoom.Position=UDim2.new(0,5,0,44); noWarRoom.BackgroundTransparency=1
noWarRoom.TextColor3=Color3.fromRGB(150,80,80); noWarRoom.TextScaled=true
noWarRoom.Font=Enum.Font.Gotham; noWarRoom.TextWrapped=true
noWarRoom.Text="🔒 Build the War Room\nto unlock spy network"
noWarRoom.Parent=panel; noWarRoom.Visible=false

local scroll=Instance.new("ScrollingFrame"); scroll.Size=UDim2.new(1,-8,1,-44)
scroll.Position=UDim2.new(0,4,0,40); scroll.BackgroundTransparency=1
scroll.ScrollBarThickness=4; scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
scroll.Parent=panel
Instance.new("UIListLayout",scroll).Padding=UDim.new(0,3)

local function makeRow(name, vaultAmt, isMe)
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,-4,0,36)
    row.BackgroundColor3=isMe and Color3.fromRGB(40,0,0) or Color3.fromRGB(25,0,0)
    row.BackgroundTransparency=0.3; row.Parent=scroll
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,4)
    local nl=Instance.new("TextLabel"); nl.Size=UDim2.new(0.55,0,1,0)
    nl.Position=UDim2.new(0,4,0,0); nl.BackgroundTransparency=1
    nl.TextColor3=isMe and Color3.fromRGB(255,200,50) or Color3.fromRGB(255,255,255)
    nl.TextScaled=true; nl.Font=Enum.Font.GothamBold; nl.TextXAlignment=Enum.TextXAlignment.Left
    nl.Text=(isMe and "★ " or "")..name; nl.Parent=row
    local vl=Instance.new("TextLabel"); vl.Size=UDim2.new(0.43,0,1,0)
    vl.Position=UDim2.new(0.56,0,0,0); vl.BackgroundTransparency=1
    vl.TextColor3=Color3.fromRGB(255,220,50); vl.TextScaled=true; vl.Font=Enum.Font.Gotham
    vl.TextXAlignment=Enum.TextXAlignment.Right
    vl.Text=string.format("💰 %d", math.floor(vaultAmt)); vl.Parent=row
end

local function refresh()
    for _,c in ipairs(scroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    local info = Remotes.GetAllPlotInfo:InvokeServer()
    if not info or #info == 0 then
        noWarRoom.Visible = true; scroll.Visible = false; return
    end
    noWarRoom.Visible = false; scroll.Visible = true
    table.sort(info, function(a,b) return a.vaultAmount > b.vaultAmount end)
    for _, entry in ipairs(info) do
        makeRow(entry.name, entry.vaultAmount, entry.userId == player.UserId)
    end
end

local isOpen = false
local OPEN_POS  = UDim2.new(1,-284,0.15,0)
local CLOSE_POS = UDim2.new(1,4,0.15,0)

local function setOpen(open)
    isOpen = open
    TweenService:Create(panel,TweenInfo.new(0.25,Enum.EasingStyle.Quad),
        {Position=open and OPEN_POS or CLOSE_POS}):Play()
    btn.Text = open and "🕵\n✕" or "🕵\nSPY"
    if open then refresh() end
end

btn.Activated:Connect(function() setOpen(not isOpen) end)
closeBtn.Activated:Connect(function() setOpen(false) end)

-- Auto-refresh every 30s when open
task.spawn(function()
    while true do task.wait(30); if isOpen then refresh() end end
end)
