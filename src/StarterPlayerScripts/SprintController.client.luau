-- src/StarterPlayerScripts/SprintController.client.luau
-- Double-tap W within 1.5s → sprint at 2× speed while W is held
local UIS       = game:GetService("UserInputService")
local TweenSvc  = game:GetService("TweenService")
local Players   = game:GetService("Players")

local player       = Players.LocalPlayer
local playerGui    = player:WaitForChild("PlayerGui")

local NORMAL_SPEED  = 16
local SPRINT_SPEED  = 32   -- 2× normal
local TAP_WINDOW    = 1.5  -- seconds between taps to count as double-tap

local lastWTime  = 0
local sprinting  = false

-- ── HUD indicator ──────────────────────────────────────────────────────────

local screen = Instance.new("ScreenGui")
screen.Name="SprintUI"; screen.ResetOnSpawn=false; screen.Parent=playerGui

local badge = Instance.new("Frame")
badge.Size=UDim2.new(0,110,0,28); badge.Position=UDim2.new(0.5,-55,1,-60)
badge.BackgroundColor3=Color3.fromRGB(0,180,80); badge.BackgroundTransparency=0.2
badge.Visible=false; badge.Parent=screen
Instance.new("UICorner",badge).CornerRadius=UDim.new(0,8)

local badgeLbl=Instance.new("TextLabel")
badgeLbl.Size=UDim2.new(1,0,1,0); badgeLbl.BackgroundTransparency=1
badgeLbl.TextColor3=Color3.new(1,1,1); badgeLbl.TextScaled=true
badgeLbl.Font=Enum.Font.GothamBold; badgeLbl.Text="⚡ SPRINT"
badgeLbl.Parent=badge

local function showBadge(visible)
    badge.Visible = visible
    if visible then
        TweenSvc:Create(badge,TweenInfo.new(0.15),{BackgroundTransparency=0.1}):Play()
    end
end

-- ── Humanoid helpers ───────────────────────────────────────────────────────

local function getHumanoid()
    local char = player.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function setSpeed(speed)
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = speed end
end

local function stopSprint()
    if not sprinting then return end
    sprinting = false
    setSpeed(NORMAL_SPEED)
    showBadge(false)
end

-- Reset on respawn
player.CharacterAdded:Connect(function()
    sprinting  = false
    lastWTime  = 0
    badge.Visible = false
end)

-- ── Input ──────────────────────────────────────────────────────────────────

UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode ~= Enum.KeyCode.W then return end

    local now = tick()
    if now - lastWTime <= TAP_WINDOW and not sprinting then
        -- Double-tap detected → start sprint
        sprinting = true
        setSpeed(SPRINT_SPEED)
        showBadge(true)
        lastWTime = 0   -- reset so a third tap doesn't double-trigger
    else
        lastWTime = now
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then
        stopSprint()
    end
end)
