-- src/ServerScriptService/WorldSetup.server.luau
-- Builds the entire world on server start. Safe to re-run (clears and rebuilds).
local Lighting = game:GetService("Lighting")

local ROOMS = {"lab","armory","minion_barracks","war_room","vault","escape_pod_bay"}
local NUM_PLOTS = 6
local RADIUS = 220

-- ── Terrain ────────────────────────────────────────────────────────────────

local function buildTerrain()
    for _, name in ipairs({"VillainFloor","CentrePad","GlowRing"}) do
        local old = workspace:FindFirstChild(name)
        if old then old:Destroy() end
    end
    for _, obj in pairs(workspace:GetChildren()) do
        if obj.Name == "PathSegment" or obj.Name == "PathGlow" or obj.Name == "PlotLight" then
            obj:Destroy()
        end
    end

    local floor = Instance.new("Part")
    floor.Name = "VillainFloor"
    floor.Size = Vector3.new(700, 1, 700)
    floor.Position = Vector3.new(0, -0.5, 0)
    floor.Anchored = true
    floor.BrickColor = BrickColor.new("Really black")
    floor.Material = Enum.Material.SmoothPlastic
    floor.Parent = workspace

    local centre = Instance.new("Part")
    centre.Name = "CentrePad"
    centre.Size = Vector3.new(40, 0.5, 40)
    centre.Position = Vector3.new(0, 0.2, 0)
    centre.Anchored = true
    centre.Shape = Enum.PartType.Cylinder
    centre.BrickColor = BrickColor.new("Dark grey")
    centre.Material = Enum.Material.SmoothPlastic
    centre.Parent = workspace

    local ring = Instance.new("Part")
    ring.Name = "GlowRing"
    ring.Size = Vector3.new(3, 0.3, 460)
    ring.Position = Vector3.new(0, 0.3, 0)
    ring.Anchored = true
    ring.Shape = Enum.PartType.Cylinder
    ring.BrickColor = BrickColor.new("Bright red")
    ring.Material = Enum.Material.Neon
    ring.Parent = workspace

    for i = 1, NUM_PLOTS do
        local angle = (i-1) * (2*math.pi/NUM_PLOTS)
        local cx = math.cos(angle) * RADIUS/2
        local cz = math.sin(angle) * RADIUS/2

        local path = Instance.new("Part")
        path.Name = "PathSegment"
        path.Size = Vector3.new(4, 0.3, RADIUS)
        path.CFrame = CFrame.new(cx, 0.2, cz) * CFrame.Angles(0, -angle, 0)
        path.Anchored = true
        path.BrickColor = BrickColor.new("Dark grey")
        path.Material = Enum.Material.SmoothPlastic
        path.Parent = workspace

        local glow = Instance.new("Part")
        glow.Name = "PathGlow"
        glow.Size = Vector3.new(0.3, 0.3, RADIUS)
        glow.CFrame = CFrame.new(cx, 0.35, cz) * CFrame.Angles(0, -angle, 0) * CFrame.new(2.2, 0, 0)
        glow.Anchored = true
        glow.BrickColor = BrickColor.new("Bright red")
        glow.Material = Enum.Material.Neon
        glow.Parent = workspace
    end
end

-- ── Lighting ───────────────────────────────────────────────────────────────

local function buildLighting()
    Lighting.ClockTime = 0
    Lighting.Brightness = 1.5
    Lighting.Ambient = Color3.fromRGB(40, 0, 60)
    Lighting.OutdoorAmbient = Color3.fromRGB(20, 0, 40)
    Lighting.FogEnd = 900
    Lighting.FogColor = Color3.fromRGB(15, 0, 30)

    local atmo = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
    atmo.Density = 0.3
    atmo.Offset = 0.1
    atmo.Color = Color3.fromRGB(80, 0, 120)
    atmo.Glare = 0.2
    atmo.Haze = 2
end

-- ── Room models ────────────────────────────────────────────────────────────

local W, H, D = 22, 12, 22

local function buildRoomModel(plot, roomId, padPos, wallCol, floorCol, decorFn)
    local old = plot:FindFirstChild("Room_" .. roomId)
    if old then old:Destroy() end

    local m = Instance.new("Model")
    m.Name = "Room_" .. roomId
    m.Parent = plot

    local ox, oz = padPos.X, padPos.Z

    local function p(sz, dx, dy, dz, col, mat, cc)
        local pt = Instance.new("Part")
        pt.Size = sz
        pt.Position = Vector3.new(ox+dx, dy, oz+dz)
        pt.Anchored = true
        pt.CanCollide = cc ~= false
        pt.Transparency = 1
        pt.BrickColor = BrickColor.new(col)
        pt.Material = mat or Enum.Material.SmoothPlastic
        pt.Parent = m
    end

    p(Vector3.new(W,1,D),   0,   .5,  0,  floorCol)
    p(Vector3.new(W,1,D),   0,  H-.5, 0,  wallCol, nil, false)
    p(Vector3.new(W,H,1),   0,  H/2, -D/2+.5, wallCol)
    p(Vector3.new(1,H,D),  -W/2+.5, H/2, 0, wallCol)
    p(Vector3.new(1,H,D),   W/2-.5, H/2, 0, wallCol)
    p(Vector3.new(8,H,1),  -7,  H/2, D/2-.5, wallCol)
    p(Vector3.new(8,H,1),   7,  H/2, D/2-.5, wallCol)
    p(Vector3.new(6,4,1),   0, H-2,  D/2-.5, wallCol)

    decorFn(p)
end

local function labDecor(p)
    p(Vector3.new(2.5,7,2.5), -5, 4.5, -7, "Bright green", Enum.Material.Neon, false)
    p(Vector3.new(2.5,7,2.5),  5, 4.5, -7, "Bright green", Enum.Material.Neon, false)
    p(Vector3.new(8,.5,4), -3, 3.5, 2, "Light grey")
    p(Vector3.new(.4,3,.4), -5, 2, 1, "Dark grey")
    p(Vector3.new(.4,3,.4), -1, 2, 1, "Dark grey")
    p(Vector3.new(.4,3,.4), -5, 2, 3, "Dark grey")
    p(Vector3.new(.4,3,.4), -1, 2, 3, "Dark grey")
    p(Vector3.new(10,5,.3),  2, 7.5, -10.4, "Black", nil, false)
    p(Vector3.new(9,4,.2),   2, 7.5, -10.3, "Bright blue", Enum.Material.Neon, false)
    p(Vector3.new(20,.2,.2), 0, 1.2, -10.4, "Bright green", Enum.Material.Neon, false)
end

local function armoryDecor(p)
    for _, z in ipairs({-7,-2,3,8}) do
        p(Vector3.new(.4,6,.4), -10.3, 4, z,    "Dark grey")
        p(Vector3.new(.4,6,.4), -10.3, 4, z+1.5,"Dark grey")
        p(Vector3.new(1,.3,1.5),-10,   8, z+.75, "Dark grey", nil, false)
    end
    p(Vector3.new(4,3,4), 6, 2.5, -4, "Olive")
    p(Vector3.new(4,3,4), 6, 2.5,  2, "Olive")
    p(Vector3.new(4,3,4), 6, 5.5, -1, "Olive")
    p(Vector3.new(20,.2,.2), 0, 11.8, -10.4, "Bright red", Enum.Material.Neon, false)
    p(Vector3.new(20,.2,.2), 0, 11.8,  10.4, "Bright red", Enum.Material.Neon, false)
    p(Vector3.new(.2,12,.2), -10.4, 6, 0, "Bright red", Enum.Material.Neon, false)
    p(Vector3.new(.2,12,.2),  10.4, 6, 0, "Bright red", Enum.Material.Neon, false)
end

local function barracksDecor(p)
    for _, bz in ipairs({-7, 0, 7}) do
        p(Vector3.new(6,.5,3),   -6, 2,   bz,   "Reddish brown")
        p(Vector3.new(5.5,.3,2.5),-6, 2.4, bz,   "Bright orange", nil, false)
        p(Vector3.new(6,.5,3),   -6, 5,   bz,   "Reddish brown")
        p(Vector3.new(5.5,.3,2.5),-6, 5.4, bz,   "Bright orange", nil, false)
        p(Vector3.new(.3,3,.3),  -3.5,3.5, bz+1.2,"Dark grey")
    end
    for _, lx in ipairs({2,4,6,8}) do
        p(Vector3.new(1.8,5,1.3), lx, 3.5, -10, "Sand blue")
        p(Vector3.new(.1,4.5,.1), lx, 3.5, -9.3, "Black", nil, false)
    end
end

local function warRoomDecor(p)
    p(Vector3.new(12,1,8),    0, 4,    0, "Dark grey")
    p(Vector3.new(11.5,.3,7.5),0, 4.65, 0, "Bright blue", Enum.Material.Neon, false)
    for _, pos in ipairs({{-5,-3},{-5,3},{5,-3},{5,3}}) do
        p(Vector3.new(.8,4,.8), pos[1], 2, pos[2], "Really black")
    end
    p(Vector3.new(14,6,.3),  0, 7.5, -10.4, "Black", nil, false)
    p(Vector3.new(13,5,.2),  0, 7.5, -10.3, "Bright red", Enum.Material.Neon, false)
    p(Vector3.new(.3,9,6), -10.4, 5.5, 0, "Bright blue", Enum.Material.Neon, false)
    p(Vector3.new(.3,9,6),  10.4, 5.5, 0, "Bright blue", Enum.Material.Neon, false)
    p(Vector3.new(20,.2,.2), 0, 1.2, -10.4, "Bright blue", Enum.Material.Neon, false)
end

local function vaultDecor(p)
    p(Vector3.new(10,10,1.5), 0, 6, -10,   "Dark grey")
    p(Vector3.new(9,9,.5),    0, 6, -9.1,  "Medium stone grey")
    p(Vector3.new(7,7,.3),    0, 6, -8.8,  "Dark grey", nil, false)
    p(Vector3.new(5,5,.3),    0, 6, -8.6,  "Dark grey", nil, false)
    p(Vector3.new(.5,3,.5),   3, 6, -8.5,  "Gold", nil, false)
    for row = 0, 2 do
        for col = -2, 2 do
            p(Vector3.new(1.5,.8,2.5), 5+col*.4, 1.5+row*.85, 4+row*.2, "Bright yellow")
        end
    end
    p(Vector3.new(20,.2,.2), 0, 1.5, -10.4, "Bright yellow", Enum.Material.Neon, false)
    p(Vector3.new(20,.2,.2), 0, 1.5,  10.4, "Bright yellow", Enum.Material.Neon, false)
    p(Vector3.new(.2,12,.2), -10.4, 6, 0,  "Bright yellow", Enum.Material.Neon, false)
    p(Vector3.new(.2,12,.2),  10.4, 6, 0,  "Bright yellow", Enum.Material.Neon, false)
end

local function escapePodDecor(p)
    p(Vector3.new(6,1,6),   0,  1,  -1, "Dark grey")
    p(Vector3.new(5,8,5),   0,  6,  -1, "White")
    p(Vector3.new(4,3,4),   0, 10.5,-1, "Light grey")
    p(Vector3.new(2,2,2),   0, 13,  -1, "White", nil, false)
    for _, pos in ipairs({{2,2},{-2,2},{2,-4},{-2,-4}}) do
        p(Vector3.new(1.5,2.5,1.5), pos[1], .8,  pos[2], "Dark grey")
        p(Vector3.new(1,1,1),       pos[1], .2,  pos[2], "Bright orange", Enum.Material.Neon, false)
    end
    for _, pos in ipairs({{-4,-5},{4,-5},{-4,3},{4,3}}) do
        p(Vector3.new(.5,10,.5), pos[1], 6, pos[2], "Dark grey")
    end
    p(Vector3.new(6,.2,6),   0, 11.8, -1,    "Cyan", Enum.Material.Neon, false)
    p(Vector3.new(20,.2,.2), 0,  1.2, -10.4, "Cyan", Enum.Material.Neon, false)
end

local ROOM_DEFS = {
    lab              = {w="White",          f="Light grey",      decor=labDecor},
    armory           = {w="Dark grey",       f="Dark stone grey", decor=armoryDecor},
    minion_barracks  = {w="Bright orange",   f="Reddish brown",   decor=barracksDecor},
    war_room         = {w="Really black",    f="Dark grey",       decor=warRoomDecor},
    vault            = {w="Bright yellow",   f="Gold",            decor=vaultDecor},
    escape_pod_bay   = {w="White",           f="Mid gray",        decor=escapePodDecor},
}

-- ── Plots ──────────────────────────────────────────────────────────────────

local function buildPlots()
    for i = 1, NUM_PLOTS do
        local old = workspace:FindFirstChild("Plot_" .. i)
        if old then old:Destroy() end

        local angle = (i-1) * (2*math.pi/NUM_PLOTS)
        local cx = math.cos(angle) * RADIUS
        local cz = math.sin(angle) * RADIUS
        local perp = angle + math.pi/2

        local plot = Instance.new("Folder")
        plot.Name = "Plot_" .. i
        plot.Parent = workspace

        local occ = Instance.new("BoolValue")
        occ.Name = "IsOccupied"; occ.Value = false; occ.Parent = plot

        local oid = Instance.new("IntValue")
        oid.Name = "OwnerId"; oid.Value = 0; oid.Parent = plot

        -- Point light over plot
        local lpart = Instance.new("Part")
        lpart.Name = "PlotLight"
        lpart.Size = Vector3.new(1,1,1)
        lpart.Transparency = 1
        lpart.CanCollide = false
        lpart.Anchored = true
        lpart.Position = Vector3.new(cx, 12, cz)
        lpart.Parent = plot
        local pl = Instance.new("PointLight", lpart)
        pl.Brightness = 3
        pl.Range = 60
        pl.Color = Color3.fromRGB(180, 0, 255)

        for idx, roomId in ipairs(ROOMS) do
            local offset = (idx - 3.5) * 18
            local px = cx + math.cos(perp) * offset
            local pz = cz + math.sin(perp) * offset

            local pad = Instance.new("Part")
            pad.Name = "DropPad_" .. roomId
            pad.Size = Vector3.new(6, 0.5, 6)
            pad.Anchored = true
            pad.BrickColor = BrickColor.new("Bright green")
            pad.Material = Enum.Material.Neon
            pad.CFrame = CFrame.new(px, 0.25, pz)
            pad.Parent = plot

            local def = ROOM_DEFS[roomId]
            buildRoomModel(plot, roomId, pad.Position, def.w, def.f, def.decor)
        end
    end
end

-- ── Spawn ──────────────────────────────────────────────────────────────────

local function buildSpawn()
    local old = workspace:FindFirstChild("VillainSpawn")
    if old then old:Destroy() end
    local sp = Instance.new("SpawnLocation")
    sp.Name = "VillainSpawn"
    sp.Size = Vector3.new(6, 1, 6)
    sp.Anchored = true
    sp.CFrame = CFrame.new(0, 0.5, 0)
    sp.BrickColor = BrickColor.new("Bright red")
    sp.Material = Enum.Material.Neon
    sp.Parent = workspace
end

-- ── Run ────────────────────────────────────────────────────────────────────

buildLighting()
buildTerrain()
buildPlots()
buildSpawn()
print("[WorldSetup] World built successfully")
