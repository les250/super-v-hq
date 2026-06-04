-- src/StarterPlayerScripts/LeaderboardController.client.luau
local Players      = game:GetService("Players")
local Remotes      = require(game.ReplicatedStorage.Remotes)

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
task.wait(2)

local screen = Instance.new("ScreenGui")
screen.Name="LeaderboardUI"; screen.ResetOnSpawn=false; screen.Parent=playerGui

-- Panel (centre-top, appears when near the board)
local panel = Instance.new("Frame")
panel.Size=UDim2.new(0,360,0,420); panel.Position=UDim2.new(0.5,-180,0.5,-210)
panel.BackgroundColor3=Color3.fromRGB(10,0,20); panel.BackgroundTransparency=0.08
panel.Visible=false; panel.Parent=screen
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,12)
local ps=Instance.new("UIStroke",panel); ps.Color=Color3.fromRGB(160,0,220); ps.Thickness=2

local header=Instance.new("TextLabel"); header.Size=UDim2.new(1,0,0,36)
header.BackgroundTransparency=1; header.TextColor3=Color3.fromRGB(255,220,50)
header.TextScaled=true; header.Font=Enum.Font.GothamBold; header.Text="🏆  LEADERBOARD"
header.Parent=panel

local closeBtn=Instance.new("TextButton"); closeBtn.Size=UDim2.new(0,32,0,32)
closeBtn.Position=UDim2.new(1,-36,0,4); closeBtn.BackgroundColor3=Color3.fromRGB(60,0,60)
closeBtn.BackgroundTransparency=0.3; closeBtn.TextColor3=Color3.fromRGB(255,100,255)
closeBtn.TextScaled=true; closeBtn.Font=Enum.Font.GothamBold; closeBtn.Text="✕"
closeBtn.Parent=panel
Instance.new("UICorner",closeBtn).CornerRadius=UDim.new(0,6)
closeBtn.Activated:Connect(function() panel.Visible=false end)

-- Tab buttons
local tabFrame=Instance.new("Frame"); tabFrame.Size=UDim2.new(1,-8,0,34)
tabFrame.Position=UDim2.new(0,4,0,38); tabFrame.BackgroundTransparency=1; tabFrame.Parent=panel

local moneyTab=Instance.new("TextButton"); moneyTab.Size=UDim2.new(0.5,0,1,0)
moneyTab.BackgroundColor3=Color3.fromRGB(60,0,100); moneyTab.TextColor3=Color3.fromRGB(255,220,50)
moneyTab.TextScaled=true; moneyTab.Font=Enum.Font.GothamBold; moneyTab.Text="💰 Money"
moneyTab.Parent=tabFrame
Instance.new("UICorner",moneyTab).CornerRadius=UDim.new(0,6)

local timeTab=Instance.new("TextButton"); timeTab.Size=UDim2.new(0.5,0,1,0)
timeTab.Position=UDim2.new(0.5,0,0,0)
timeTab.BackgroundColor3=Color3.fromRGB(20,0,40); timeTab.TextColor3=Color3.fromRGB(180,160,220)
timeTab.TextScaled=true; timeTab.Font=Enum.Font.GothamBold; timeTab.Text="⏱ Time Played"
timeTab.Parent=tabFrame
Instance.new("UICorner",timeTab).CornerRadius=UDim.new(0,6)

-- List
local scroll=Instance.new("ScrollingFrame"); scroll.Size=UDim2.new(1,-8,1,-84)
scroll.Position=UDim2.new(0,4,0,76); scroll.BackgroundTransparency=1
scroll.ScrollBarThickness=4; scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; scroll.Parent=panel
Instance.new("UIListLayout",scroll).Padding=UDim.new(0,3)

local currentMoneyTop = {}
local currentTimeTop  = {}
local showingMoney    = true

local RANK_ICONS = {"🥇","🥈","🥉","4️⃣","5️⃣","6️⃣","7️⃣","8️⃣","9️⃣","🔟"}

local function makeRow(rank, name, value, isSelf)
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,-4,0,36)
    row.BackgroundColor3=isSelf and Color3.fromRGB(40,0,60) or Color3.fromRGB(20,0,35)
    row.BackgroundTransparency=0.3; row.Parent=scroll
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,4)
    local rl=Instance.new("TextLabel"); rl.Size=UDim2.new(0,32,1,0)
    rl.BackgroundTransparency=1; rl.TextScaled=true; rl.Font=Enum.Font.GothamBold
    rl.Text=RANK_ICONS[rank] or tostring(rank); rl.Parent=row
    local nl=Instance.new("TextLabel"); nl.Size=UDim2.new(0.55,0,1,0)
    nl.Position=UDim2.new(0,34,0,0); nl.BackgroundTransparency=1
    nl.TextColor3=isSelf and Color3.fromRGB(255,220,50) or Color3.fromRGB(220,200,255)
    nl.TextScaled=true; nl.Font=isSelf and Enum.Font.GothamBold or Enum.Font.Gotham
    nl.TextXAlignment=Enum.TextXAlignment.Left; nl.Text=name; nl.Parent=row
    local vl=Instance.new("TextLabel"); vl.Size=UDim2.new(0.38,0,1,0)
    vl.Position=UDim2.new(0.61,0,0,0); vl.BackgroundTransparency=1
    vl.TextColor3=Color3.fromRGB(255,220,50); vl.TextScaled=true; vl.Font=Enum.Font.Gotham
    vl.TextXAlignment=Enum.TextXAlignment.Right
    -- Format value
    local display = type(value)=="number" and string.format("💰 %d", math.floor(value)) or tostring(value)
    vl.Text=display; vl.Parent=row
end

local function renderList(rows)
    for _,c in ipairs(scroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    if #rows == 0 then
        local el=Instance.new("TextLabel"); el.Size=UDim2.new(1,0,0,40)
        el.BackgroundTransparency=1; el.TextColor3=Color3.fromRGB(160,140,180)
        el.TextScaled=true; el.Font=Enum.Font.Gotham; el.Text="No data yet"
        el.Parent=scroll; return
    end
    for _, entry in ipairs(rows) do
        makeRow(entry.rank, entry.name, entry.value, entry.name == player.DisplayName)
    end
end

local function showTab(money)
    showingMoney = money
    moneyTab.BackgroundColor3 = money and Color3.fromRGB(60,0,100) or Color3.fromRGB(20,0,40)
    moneyTab.TextColor3       = money and Color3.fromRGB(255,220,50) or Color3.fromRGB(180,160,220)
    timeTab.BackgroundColor3  = money and Color3.fromRGB(20,0,40) or Color3.fromRGB(60,0,100)
    timeTab.TextColor3        = money and Color3.fromRGB(180,160,220) or Color3.fromRGB(255,220,50)
    renderList(money and currentMoneyTop or currentTimeTop)
end

moneyTab.Activated:Connect(function() showTab(true) end)
timeTab.Activated:Connect(function() showTab(false) end)

Remotes.LeaderboardUpdate.OnClientEvent:Connect(function(moneyTop, timeTop)
    currentMoneyTop = moneyTop
    currentTimeTop  = timeTop
    if panel.Visible then renderList(showingMoney and moneyTop or timeTop) end
end)

-- ProximityPrompt on LeaderboardBoard to open panel
local function wireBoard()
    local board = workspace:WaitForChild("LeaderboardBoard", 10)
    if not board then return end
    if board:FindFirstChildOfClass("ProximityPrompt") then return end
    local prompt=Instance.new("ProximityPrompt"); prompt.ActionText="View Leaderboard"
    prompt.ObjectText="🏆 Top Players"; prompt.HoldDuration=0
    prompt.MaxActivationDistance=15; prompt.Parent=board
    prompt.Triggered:Connect(function()
        panel.Visible = not panel.Visible
        if panel.Visible then
            showTab(true)  -- default to money tab
        end
    end)
end

task.spawn(wireBoard)
