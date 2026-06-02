-- src/StarterPlayerScripts/LabelController.client.luau
-- Shows cost labels on owned plot drop pads (proximity) + sky label + lab progress
local Players  = game:GetService("Players")
local Remotes  = require(game.ReplicatedStorage.Remotes)
local RoomData = require(game.ReplicatedStorage.RoomData)

local player = Players.LocalPlayer

local UPPER_FLOORS = {"armory","minion_barracks","war_room","vault","escape_pod_bay"}
local UPPER_NAMES  = {
    armory="Armory", minion_barracks="Minion Barracks",
    war_room="War Room", vault="Vault", escape_pod_bay="Escape Pod Bay"
}

task.wait()

local function getMyPlot()
    while true do
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Folder") and obj.Name:match("^Plot_%d+$") then
                local oid = obj:FindFirstChild("OwnerId")
                if oid and oid.Value == player.UserId then return obj end
            end
        end
        task.wait(0.5)
    end
end

local plot = getMyPlot()

-- ── Label factory ──────────────────────────────────────────────────────────

local function makeLabel(pad, titleText, bodyText, maxDist, borderColor)
    local bb = Instance.new("BillboardGui")
    bb.Name = "CostLabel"
    bb.Size = UDim2.new(0, 170, 0, 60)
    bb.StudsOffset = Vector3.new(0, 4, 0)
    bb.MaxDistance = maxDist or 15
    bb.AlwaysOnTop = false
    bb.Parent = pad

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(15, 0, 25)
    bg.BackgroundTransparency = 0.2
    bg.Parent = bb

    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 8)
    local st = Instance.new("UIStroke", bg)
    st.Color = borderColor or Color3.fromRGB(180, 0, 255); st.Thickness = 1.5

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -6, 0.5, 0); t.Position = UDim2.new(0, 3, 0, 0)
    t.BackgroundTransparency = 1
    t.TextColor3 = Color3.fromRGB(255, 220, 50)
    t.TextScaled = true; t.Font = Enum.Font.GothamBold
    t.Text = titleText; t.Parent = bg

    local b = Instance.new("TextLabel")
    b.Size = UDim2.new(1, -6, 0.5, 0); b.Position = UDim2.new(0, 3, 0.5, 0)
    b.BackgroundTransparency = 1
    b.TextColor3 = Color3.fromRGB(200, 160, 255)
    b.TextScaled = true; b.Font = Enum.Font.Gotham
    b.Text = bodyText; b.Parent = bg

    return bb
end

-- ── Lab station labels (50 pads) ───────────────────────────────────────────

local DEPT_COLORS = {
    Color3.fromRGB(0, 200, 80),   -- chemistry  (green)
    Color3.fromRGB(0, 120, 255),  -- electronics (blue)
    Color3.fromRGB(0, 210, 210),  -- biology (cyan)
    Color3.fromRGB(160, 0, 255),  -- physics (violet)
    Color3.fromRGB(255, 40, 40),  -- weapons (red)
}

for _, room in ipairs(RoomData.ROOMS) do
    if room.unlockOrder == 1 then
        local pad = plot:FindFirstChild("DropPad_" .. room.id)
        if pad then
            makeLabel(pad, room.name, "💰 " .. room.tiers[1].cost,
                12, DEPT_COLORS[room.deptIndex])
        end
    end
end

-- ── Upper floor labels ─────────────────────────────────────────────────────

for _, id in ipairs(UPPER_FLOORS) do
    local pad = plot:FindFirstChild("DropPad_" .. id)
    if pad then
        local room = RoomData.getRoom(id)
        if room then
            makeLabel(pad, "Floor " .. (room.unlockOrder) .. " — " .. UPPER_NAMES[id],
                "💰 " .. room.tiers[1].cost .. "  (Lab required)", 20,
                Color3.fromRGB(255, 180, 0))
        end
    end
end

-- ── Sky label ──────────────────────────────────────────────────────────────

local function makeSkyLabel()
    local anchor = plot:WaitForChild("BaseLabelAnchor", 10)
    if not anchor then return end

    local bb = Instance.new("BillboardGui")
    bb.Name = "SkyLabel"; bb.Size = UDim2.new(0, 220, 0, 90)
    bb.MaxDistance = 600; bb.AlwaysOnTop = false; bb.Parent = anchor

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(15, 0, 25)
    bg.BackgroundTransparency = 0.15; bg.Parent = bb

    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 12)
    local st = Instance.new("UIStroke", bg)
    st.Color = Color3.fromRGB(180, 0, 255); st.Thickness = 2

    local function lbl(txt, col, yp, sz)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -8, sz or 0.3, 0)
        l.Position = UDim2.new(0, 4, yp, 0)
        l.BackgroundTransparency = 1
        l.TextColor3 = col; l.TextScaled = true
        l.Font = Enum.Font.GothamBold; l.Text = txt; l.Parent = bg
    end

    lbl("▼  YOUR BASE  ▼", Color3.fromRGB(180,0,255), 0, 0.28)
    lbl(player.DisplayName,  Color3.fromRGB(255,220,50), 0.28, 0.4)
    lbl("@"..player.Name,    Color3.fromRGB(200,160,255), 0.68, 0.28)
end

task.spawn(makeSkyLabel)

-- Lab progress moved to ObjectivesController

-- ── Remove label when bought ────────────────────────────────────────────

Remotes.RoomBuilt.OnClientEvent:Connect(function(roomId)
    local pad = plot:FindFirstChild("DropPad_" .. roomId)
    if pad then
        local label = pad:FindFirstChild("CostLabel")
        if label then label:Destroy() end
    end
end)
