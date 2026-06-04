-- src/StarterPlayerScripts/TutorialController.client.luau
local Players  = game:GetService("Players")
local Remotes  = require(game.ReplicatedStorage.Remotes)
local TweenService = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

task.wait(3)

-- Skip tutorial if player already has rooms built
local data = Remotes.GetPlayerData:InvokeServer()
if data and next(data.rooms) ~= nil then return end

local screen = Instance.new("ScreenGui")
screen.Name = "TutorialUI"; screen.ResetOnSpawn = false; screen.Parent = playerGui

-- Dark overlay
local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1,0,1,0)
overlay.BackgroundColor3 = Color3.new(0,0,0)
overlay.BackgroundTransparency = 0.55
overlay.Parent = screen

-- Card
local card = Instance.new("Frame")
card.Size = UDim2.new(0,440,0,210)
card.Position = UDim2.new(0.5,-220,0.5,-105)
card.BackgroundColor3 = Color3.fromRGB(12,0,22)
card.BackgroundTransparency = 0.05
card.Parent = screen
Instance.new("UICorner",card).CornerRadius=UDim.new(0,14)
local cs=Instance.new("UIStroke",card); cs.Color=Color3.fromRGB(180,0,255); cs.Thickness=2

-- Icon
local iconL = Instance.new("TextLabel")
iconL.Size=UDim2.new(0,70,0,70); iconL.Position=UDim2.new(0,16,0,16)
iconL.BackgroundTransparency=1; iconL.TextScaled=true
iconL.Font=Enum.Font.GothamBold; iconL.Parent=card

-- Title
local titleL = Instance.new("TextLabel")
titleL.Size=UDim2.new(1,-100,0,44); titleL.Position=UDim2.new(0,90,0,14)
titleL.BackgroundTransparency=1; titleL.TextColor3=Color3.fromRGB(255,220,50)
titleL.TextScaled=true; titleL.Font=Enum.Font.GothamBold
titleL.TextXAlignment=Enum.TextXAlignment.Left; titleL.TextWrapped=true
titleL.Parent=card

-- Body
local bodyL = Instance.new("TextLabel")
bodyL.Size=UDim2.new(1,-32,0,96); bodyL.Position=UDim2.new(0,16,0,78)
bodyL.BackgroundTransparency=1; bodyL.TextColor3=Color3.fromRGB(220,200,255)
bodyL.TextScaled=true; bodyL.Font=Enum.Font.Gotham; bodyL.TextWrapped=true
bodyL.TextXAlignment=Enum.TextXAlignment.Left; bodyL.Parent=card

-- Next button
local nextBtn = Instance.new("TextButton")
nextBtn.Size=UDim2.new(0,130,0,36); nextBtn.Position=UDim2.new(1,-146,1,-48)
nextBtn.BackgroundColor3=Color3.fromRGB(80,0,140); nextBtn.TextColor3=Color3.new(1,1,1)
nextBtn.TextScaled=true; nextBtn.Font=Enum.Font.GothamBold; nextBtn.Parent=card
Instance.new("UICorner",nextBtn).CornerRadius=UDim.new(0,8)

-- Step indicator
local stepL = Instance.new("TextLabel")
stepL.Size=UDim2.new(0,90,0,28); stepL.Position=UDim2.new(0,16,1,-42)
stepL.BackgroundTransparency=1; stepL.TextColor3=Color3.fromRGB(150,120,180)
stepL.TextScaled=true; stepL.Font=Enum.Font.Gotham; stepL.Parent=card

local STEPS = {
    {
        icon  = "🦹",
        title = "Welcome to Super V HQ!",
        body  = "You are a villain building your empire.\n\nWalk into the LAB building through the wide entrance. It's the big building in front of you.",
    },
    {
        icon  = "🔬",
        title = "Build Lab Stations",
        body  = "Inside the lab, walk up to a GREEN glowing pad and hold the 'Build' prompt.\n\nYou start with 💰2,000 — build Chemistry stations first!",
    },
    {
        icon  = "💰",
        title = "Grow Your Empire",
        body  = "Rooms generate income every 3 seconds.\n\n📋 Open Objectives (right side) to track progress.\nComplete all 50 Lab stations to unlock upper floors!",
    },
}

local stepIndex = 1

local function showStep(i)
    local step = STEPS[i]
    iconL.Text  = step.icon
    titleL.Text = step.title
    bodyL.Text  = step.body
    stepL.Text  = i .. " / " .. #STEPS
    nextBtn.Text = i < #STEPS and "Next  →" or "Let's Go! 🚀"
end

local function dismiss()
    if not screen.Parent then return end
    TweenService:Create(card, TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.In),
        {Position=UDim2.new(0.5,-220,1.2,0)}):Play()
    task.delay(0.35, function()
        screen:Destroy()
    end)
end

showStep(1)

nextBtn.Activated:Connect(function()
    if stepIndex < #STEPS then
        stepIndex += 1
        -- Slide card out and back in
        TweenService:Create(card,TweenInfo.new(0.15,Enum.EasingStyle.Quad,Enum.EasingDirection.In),
            {Position=UDim2.new(0.5,-220,1.5,0)}):Play()
        task.delay(0.18, function()
            showStep(stepIndex)
            card.Position=UDim2.new(0.5,-220,0.5,-105)
        end)
    else
        dismiss()
    end
end)

-- Auto-dismiss when first room is built
Remotes.RoomBuilt.OnClientEvent:Connect(function()
    dismiss()
end)
