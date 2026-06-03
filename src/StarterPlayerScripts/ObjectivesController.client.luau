-- src/StarterPlayerScripts/ObjectivesController.client.luau
-- Collapsible Objectives panel: lab stations + upper floors with green/white/grey states
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Remotes      = require(game.ReplicatedStorage.Remotes)
local RoomData     = require(game.ReplicatedStorage.RoomData)
local Config       = require(game.ReplicatedStorage.Config)

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TICKS_PER_30S = 30 / Config.INCOME_TICK_INTERVAL

local UPPER_IDS = {"armory","minion_barracks","war_room","vault","escape_pod_bay"}
local DEPT_NAMES = {
    chemistry="Chemistry", electronics="Electronics", biology="Biology",
    physics="Physics", weapons="Weapons R&D",
}

-- ── Build UI ───────────────────────────────────────────────────────────────

local screen = Instance.new("ScreenGui")
screen.Name = "ObjectivesUI"; screen.ResetOnSpawn = false; screen.Parent = playerGui

-- Toggle button (right side)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size       = UDim2.new(0, 38, 0, 110)
toggleBtn.Position   = UDim2.new(1, -38, 0.5, -55)
toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 0, 80)
toggleBtn.BackgroundTransparency = 0.2
toggleBtn.TextColor3 = Color3.fromRGB(220, 180, 255)
toggleBtn.TextScaled = true
toggleBtn.Font       = Enum.Font.GothamBold
toggleBtn.Text       = "📋\nOBJ"
toggleBtn.Parent     = screen
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

-- Main panel (slides in from right)
local panel = Instance.new("Frame")
panel.Name = "ObjPanel"
panel.Size = UDim2.new(0, 310, 0.82, 0)
panel.Position = UDim2.new(1, 4, 0.09, 0)   -- starts off-screen
panel.BackgroundColor3 = Color3.fromRGB(12, 0, 22)
panel.BackgroundTransparency = 0.08
panel.Parent = screen
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)
local ps = Instance.new("UIStroke", panel); ps.Color = Color3.fromRGB(160, 0, 220); ps.Thickness = 1.5

-- Panel title (acts as close button too)
local titleLbl = Instance.new("TextButton")
titleLbl.Size = UDim2.new(1, -10, 0, 36)
titleLbl.Position = UDim2.new(0, 5, 0, 4)
titleLbl.BackgroundTransparency = 1
titleLbl.TextColor3 = Color3.fromRGB(255, 220, 50)
titleLbl.TextScaled = true; titleLbl.Font = Enum.Font.GothamBold
titleLbl.Text = "📋  OBJECTIVES  ✕"
titleLbl.Parent = panel

-- Lab progress count
local labCountLbl = Instance.new("TextLabel")
labCountLbl.Size = UDim2.new(1, -10, 0, 22)
labCountLbl.Position = UDim2.new(0, 5, 0, 40)
labCountLbl.BackgroundTransparency = 1
labCountLbl.TextColor3 = Color3.fromRGB(180, 255, 180)
labCountLbl.TextScaled = true; labCountLbl.Font = Enum.Font.Gotham
labCountLbl.Text = "🔬 Lab Floor: 0 / 50"
labCountLbl.Parent = panel

-- Scrolling list
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -8, 1, -70)
scroll.Position = UDim2.new(0, 4, 0, 66)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = Color3.fromRGB(160, 0, 220)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = panel

local listLayout = Instance.new("UIListLayout", scroll)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 1)

-- ── Row builder ────────────────────────────────────────────────────────────

local function makeRow(parent, order, icon, nameText, subText, textCol, bgCol)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -4, 0, 30)
    row.BackgroundColor3 = bgCol or Color3.fromRGB(25, 0, 40)
    row.BackgroundTransparency = 0.4
    row.LayoutOrder = order
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

    local iconLbl = Instance.new("TextLabel")
    iconLbl.Size = UDim2.new(0, 28, 1, 0); iconLbl.BackgroundTransparency = 1
    iconLbl.TextColor3 = textCol; iconLbl.TextScaled = true
    iconLbl.Font = Enum.Font.GothamBold; iconLbl.Text = icon; iconLbl.Parent = row

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1, -90, 1, 0); nameLbl.Position = UDim2.new(0, 28, 0, 0)
    nameLbl.BackgroundTransparency = 1; nameLbl.TextColor3 = textCol
    nameLbl.TextScaled = true; nameLbl.Font = Enum.Font.Gotham
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.Text = nameText; nameLbl.Parent = row

    local subLbl = Instance.new("TextLabel")
    subLbl.Size = UDim2.new(0, 80, 1, 0); subLbl.Position = UDim2.new(1, -82, 0, 0)
    subLbl.BackgroundTransparency = 1
    subLbl.TextColor3 = Color3.fromRGB(textCol.R*255*0.7, textCol.G*255*0.7, textCol.B*255*0.7)
    subLbl.TextScaled = true; subLbl.Font = Enum.Font.Gotham
    subLbl.TextXAlignment = Enum.TextXAlignment.Right
    subLbl.Text = subText; subLbl.Parent = row

    return row
end

local function makeSectionHeader(parent, order, text, col)
    local hdr = Instance.new("Frame")
    hdr.Size = UDim2.new(1, -4, 0, 24)
    hdr.BackgroundColor3 = Color3.fromRGB(40, 0, 65)
    hdr.BackgroundTransparency = 0.3
    hdr.LayoutOrder = order
    hdr.Parent = parent
    Instance.new("UICorner", hdr).CornerRadius = UDim.new(0, 4)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -8, 1, 0); lbl.Position = UDim2.new(0, 4, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.TextColor3 = col or Color3.fromRGB(200, 150, 255)
    lbl.TextScaled = true; lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = text; lbl.Parent = hdr
    return hdr
end

-- ── Populate / refresh ─────────────────────────────────────────────────────

local rowCache = {}   -- reuse or rebuild rows

local COL_DONE    = Color3.fromRGB(100, 255, 120)   -- green
local COL_AVAIL   = Color3.fromRGB(255, 255, 255)   -- white
local COL_LOCKED  = Color3.fromRGB(100, 80,  120)   -- grey-purple

local function refreshObjectives(data)
    if not data then return end

    -- Clear existing rows
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local bought, total = RoomData.getLabProgress(data.rooms)
    labCountLbl.Text = string.format("🔬 Lab Floor: %d / %d", bought, total)

    local order = 0

    -- ── Lab section ──
    makeSectionHeader(scroll, order, "🔬  LAB FLOOR  (" .. bought .. "/" .. total .. ")",
        Color3.fromRGB(180, 255, 180))
    order += 1

    local currentDept = ""
    for _, room in ipairs(RoomData.ROOMS) do
        if room.unlockOrder ~= 1 then break end

        -- Dept header
        local deptName = DEPT_NAMES[room.id:match("lab_(.-)_%d+") or ""] or ""
        if deptName ~= "" and deptName ~= currentDept then
            currentDept = deptName
            makeSectionHeader(scroll, order, "  " .. deptName, Color3.fromRGB(160, 200, 255))
            order += 1
        end

        local tier = data.rooms[room.id] or 0
        local icon, col, sub
        if tier > 0 then
            local inc30s = math.floor(room.tiers[tier].incomePerTick * TICKS_PER_30S)
            icon = "✓"; col = COL_DONE; sub = "+" .. inc30s .. "/30s"
        else
            icon = "○"; col = COL_AVAIL; sub = "💰" .. room.tiers[1].cost
        end
        makeRow(scroll, order, icon, room.name, sub, col)
        order += 1
    end

    -- ── Upper floors section ──
    local labComplete = (bought == total)
    makeSectionHeader(scroll, order, "🏗  UPPER FLOORS", Color3.fromRGB(255, 200, 80))
    order += 1

    for _, id in ipairs(UPPER_IDS) do
        local room = RoomData.getRoom(id)
        if room then
            local tier = data.rooms[id] or 0
            local icon, col, sub
            if tier > 0 then
                local inc30s = math.floor(room.tiers[tier].incomePerTick * TICKS_PER_30S)
                icon = "✓"; col = COL_DONE; sub = "+" .. inc30s .. "/30s"
            elseif labComplete then
                icon = "○"; col = COL_AVAIL; sub = "💰" .. room.tiers[1].cost
            else
                icon = "🔒"; col = COL_LOCKED; sub = "Lab req."
            end
            makeRow(scroll, order, icon, room.name, sub, col,
                tier == 0 and not labComplete and Color3.fromRGB(20, 0, 30) or nil)
            order += 1
        end
    end
end

-- ── Toggle open/close ──────────────────────────────────────────────────────

local isOpen = false
local OPEN_POS  = UDim2.new(1, -314, 0.09, 0)
local CLOSE_POS = UDim2.new(1, 4,    0.09, 0)

local function setOpen(open: boolean)
    isOpen = open
    TweenService:Create(panel, TweenInfo.new(0.25, Enum.EasingStyle.Quad),
        {Position = isOpen and OPEN_POS or CLOSE_POS}):Play()
    toggleBtn.Text = isOpen and "📋\n✕" or "📋\nOBJ"
    if isOpen then
        local data = Remotes.GetPlayerData:InvokeServer()
        refreshObjectives(data)
    end
end

-- Toggle button on the side
toggleBtn.Activated:Connect(function() setOpen(not isOpen) end)

-- Title bar inside panel also closes it
titleLbl.Activated:Connect(function() setOpen(false) end)

-- ── Auto-refresh when a room is built ─────────────────────────────────────

Remotes.RoomBuilt.OnClientEvent:Connect(function()
    if not isOpen then return end
    task.wait(0.2)
    local data = Remotes.GetPlayerData:InvokeServer()
    refreshObjectives(data)
end)

-- ── Initial load ──────────────────────────────────────────────────────────

task.spawn(function()
    task.wait(2)
    local data = Remotes.GetPlayerData:InvokeServer()
    if data then
        local bought = RoomData.getLabProgress(data.rooms)
        labCountLbl.Text = string.format("🔬 Lab Floor: %d / 50", bought)
    end
end)
