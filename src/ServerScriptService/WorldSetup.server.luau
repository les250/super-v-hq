-- src/ServerScriptService/WorldSetup.server.luau
-- Builds the entire world on server start. Safe to re-run (clears and rebuilds).
local Lighting = game:GetService("Lighting")
local RoomData  = require(game.ReplicatedStorage.RoomData)

local NUM_PLOTS    = 6
local RADIUS       = 220
local FLOOR_H      = 12   -- studs per floor
local LAB_W        = 90   -- lab building width
local LAB_D        = 44   -- lab building depth
local UPPER_W      = 24   -- upper floor width/depth
local UPPER_D      = 24

-- Dept pad grid inside lab
local DEPT_OFFSETS_X = {-36, -18, 0, 18, 36}  -- 5 dept columns
local STATION_OFFSETS_Z = {}
for i = 1, 10 do
    STATION_OFFSETS_Z[i] = -19 + (i-1) * 4.2
end

local DEPT_COLORS = {
    "Bright green", "Bright blue", "Cyan", "Bright violet", "Bright red"
}

local UPPER_FLOORS = {
    {id="armory",          name="Armory",         floor=2},
    {id="minion_barracks", name="Minion Barracks", floor=3},
    {id="war_room",        name="War Room",        floor=4},
    {id="vault",           name="Vault",           floor=5},
    {id="escape_pod_bay",  name="Escape Pod Bay",  floor=6},
}

-- ── Part helper ────────────────────────────────────────────────────────────

local function makePart(parent, name, sz, px, py, pz, col, mat, canCollide, transparent)
    local pt = Instance.new("Part")
    pt.Name = name
    pt.Size = sz
    pt.Position = Vector3.new(px, py, pz)
    pt.Anchored = true
    pt.CanCollide = canCollide ~= false
    pt.Transparency = transparent ~= false and 1 or 0
    pt.BrickColor = BrickColor.new(col)
    pt.Material = mat or Enum.Material.SmoothPlastic
    pt.Parent = parent
    return pt
end

-- ── Lighting ───────────────────────────────────────────────────────────────

local function buildLighting()
    Lighting.ClockTime       = 0
    Lighting.Brightness      = 1.5
    Lighting.Ambient         = Color3.fromRGB(40, 0, 60)
    Lighting.OutdoorAmbient  = Color3.fromRGB(20, 0, 40)
    Lighting.FogEnd          = 900
    Lighting.FogColor        = Color3.fromRGB(15, 0, 30)
    local atmo = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
    atmo.Density = 0.3; atmo.Color = Color3.fromRGB(80, 0, 120); atmo.Haze = 2
end

-- ── Terrain ────────────────────────────────────────────────────────────────

local function buildTerrain()
    for _, n in ipairs({"VillainFloor","CentrePad","GlowRing"}) do
        local o = workspace:FindFirstChild(n); if o then o:Destroy() end
    end
    for _, o in pairs(workspace:GetChildren()) do
        if o.Name == "PathSegment" or o.Name == "PathGlow" then o:Destroy() end
    end

    local floor = Instance.new("Part"); floor.Name="VillainFloor"
    floor.Size=Vector3.new(900,1,900); floor.Position=Vector3.new(0,-0.5,0)
    floor.Anchored=true; floor.BrickColor=BrickColor.new("Really black")
    floor.Material=Enum.Material.SmoothPlastic; floor.Parent=workspace

    local centre=Instance.new("Part"); centre.Name="CentrePad"
    centre.Size=Vector3.new(40,0.5,40); centre.Position=Vector3.new(0,0.2,0)
    centre.Anchored=true; centre.Shape=Enum.PartType.Cylinder
    centre.BrickColor=BrickColor.new("Dark grey"); centre.Parent=workspace

    local ring=Instance.new("Part"); ring.Name="GlowRing"
    ring.Size=Vector3.new(3,0.3,500); ring.Position=Vector3.new(0,0.3,0)
    ring.Anchored=true; ring.Shape=Enum.PartType.Cylinder
    ring.BrickColor=BrickColor.new("Bright red"); ring.Material=Enum.Material.Neon
    ring.Parent=workspace

    for i=1,NUM_PLOTS do
        local a=(i-1)*(2*math.pi/NUM_PLOTS)
        local cx=math.cos(a)*RADIUS/2; local cz=math.sin(a)*RADIUS/2
        local path=Instance.new("Part"); path.Name="PathSegment"
        path.Size=Vector3.new(6,0.3,RADIUS)
        path.CFrame=CFrame.new(cx,0.2,cz)*CFrame.Angles(0,-a,0)
        path.Anchored=true; path.BrickColor=BrickColor.new("Dark grey")
        path.Material=Enum.Material.SmoothPlastic; path.Parent=workspace
    end
end

-- ── Lab floor building ─────────────────────────────────────────────────────

local function buildLabFloor(plot, cx, cz)
    local m = Instance.new("Model"); m.Name = "Room_lab_building"; m.Parent = plot
    local W, D, H = LAB_W, LAB_D, FLOOR_H
    local T = 1

    local function pp(nm, sz, dx, dy, dz, col, mat, cc)
        return makePart(m, nm, sz, cx+dx, dy, cz+dz, col, mat, cc, true)
    end

    -- Structure (starts invisible)
    pp("Floor",     Vector3.new(W,T,D),     0, T/2,       0,  "Dark grey")
    pp("Ceiling",   Vector3.new(W,T,D),     0, H-T/2,     0,  "Really black", nil, false)
    pp("BackWall",  Vector3.new(W,H,T),     0, H/2, -D/2+T/2, "Really black")
    pp("LeftWall",  Vector3.new(T,H,D), -W/2+T/2, H/2, 0,     "Really black")
    pp("RightWall", Vector3.new(T,H,D),  W/2-T/2, H/2, 0,     "Really black")
    -- Front wall with wide entrance (30 wide)
    local side = (W-30)/2
    pp("FrontL",    Vector3.new(side,H,T), -(W/2-side/2), H/2, D/2-T/2, "Really black")
    pp("FrontR",    Vector3.new(side,H,T),  (W/2-side/2), H/2, D/2-T/2, "Really black")
    pp("FrontTop",  Vector3.new(30,4,T),    0, H-2,        D/2-T/2,     "Really black")

    -- Dept divider walls (light separators)
    for dIdx = 1, 4 do
        local dx = DEPT_OFFSETS_X[dIdx] + 9  -- between depts
        pp("Divider"..dIdx, Vector3.new(T, H-2, D-4), dx, (H-2)/2, 0, "Dark grey", nil, false)
    end

    -- Dept ceiling strips (neon color per dept)
    for dIdx, col in ipairs(DEPT_COLORS) do
        local dx = DEPT_OFFSETS_X[dIdx]
        pp("Strip"..dIdx, Vector3.new(14, 0.3, D-2), dx, H-1.5, 0, col, Enum.Material.Neon, false)
    end

    -- Lab station pads (50 total, with colored markers)
    for dIdx, dept in ipairs(RoomData.LAB_DEPTS) do
        for i = 1, 10 do
            local stId = "lab_" .. dept.name .. "_" .. i
            local dx = DEPT_OFFSETS_X[dIdx]
            local dz = STATION_OFFSETS_Z[i]

            -- Drop pad
            local pad = Instance.new("Part")
            pad.Name       = "DropPad_" .. stId
            pad.Size       = Vector3.new(4, 0.4, 3.5)
            pad.Position   = Vector3.new(cx+dx, 0.45, cz+dz)
            pad.Anchored   = true
            pad.BrickColor = BrickColor.new("Dark grey")
            pad.Material   = Enum.Material.SmoothPlastic
            pad.Parent     = plot

            -- Station model (small equipment pillar, invisible until bought)
            local sm = Instance.new("Model")
            sm.Name = "Room_" .. stId
            sm.Parent = plot

            makePart(sm, "Base",  Vector3.new(3.5,0.5,3),   cx+dx, 0.75, cz+dz, "Dark grey", nil, true, true)
            makePart(sm, "Pillar",Vector3.new(1,5,1),        cx+dx, 3.5,  cz+dz, DEPT_COLORS[dIdx], nil, false, true)
            makePart(sm, "Glow",  Vector3.new(2,1,2),        cx+dx, 6.2,  cz+dz, DEPT_COLORS[dIdx], Enum.Material.Neon, false, true)
        end
    end
end

-- ── Upper floor buildings ──────────────────────────────────────────────────

local UPPER_WALL_COLORS = {
    "Dark grey",       -- Armory
    "Bright orange",   -- Minion Barracks
    "Really black",    -- War Room
    "Bright yellow",   -- Vault
    "White",           -- Escape Pod Bay
}
local UPPER_FLOOR_COLORS = {
    "Dark stone grey", "Reddish brown", "Dark grey", "Gold", "Mid gray"
}

local function buildUpperFloor(plot, cx, cz, floorData, floorIdx)
    local yBase = FLOOR_H * floorData.floor  -- stacked above lab
    local W, D, H = UPPER_W, UPPER_D, FLOOR_H
    local T = 1
    local wc = UPPER_WALL_COLORS[floorIdx]
    local fc = UPPER_FLOOR_COLORS[floorIdx]

    local m = Instance.new("Model")
    m.Name = "Room_" .. floorData.id
    m.Parent = plot

    local function pp(nm, sz, dx, dy, dz, col, mat, cc)
        return makePart(m, nm, sz, cx+dx, yBase+dy, cz+dz, col, mat, cc, true)
    end

    pp("Floor",    Vector3.new(W,T,D),   0, T/2,     0,     fc)
    pp("Ceiling",  Vector3.new(W,T,D),   0, H-T/2,   0,     wc, nil, false)
    pp("BackWall", Vector3.new(W,H,T),   0, H/2, -D/2+T/2,  wc)
    pp("LeftWall", Vector3.new(T,H,D), -W/2+T/2, H/2, 0,    wc)
    pp("RightWall",Vector3.new(T,H,D),  W/2-T/2, H/2, 0,    wc)
    -- Front wall with door
    local side = (W-6)/2
    pp("FrontL",  Vector3.new(side,H,T), -(W/2-side/2), H/2, D/2-T/2, wc)
    pp("FrontR",  Vector3.new(side,H,T),  (W/2-side/2), H/2, D/2-T/2, wc)
    pp("FrontTop",Vector3.new(6,4,T),     0, H-2, D/2-T/2,             wc)

    -- Drop pad for this floor (placed at bottom of staircase = front of building at ground)
    -- Elevated platform outside the building, accessible via exterior staircase
    local padY = yBase + 0.25
    local pad = Instance.new("Part")
    pad.Name     = "DropPad_" .. floorData.id
    pad.Size     = Vector3.new(6, 0.5, 6)
    pad.Position = Vector3.new(cx, padY, cz + D/2 + 4)
    pad.Anchored = true
    pad.BrickColor = BrickColor.new("Bright green")
    pad.Material = Enum.Material.Neon
    pad.Parent = plot

    -- Staircase up to this floor (visual only, invisible until bought)
    local stairM = Instance.new("Model"); stairM.Name = "Stair_"..floorData.id; stairM.Parent = plot
    local steps = math.ceil(yBase / 2)
    for s = 1, steps do
        makePart(stairM, "Step"..s,
            Vector3.new(4, 0.5, 1.5),
            cx, s*2 - 0.25, cz + D/2 + 4 - s*1.2,
            "Dark grey", nil, true, true)
    end
end

-- ── Staircase glow pillar ──────────────────────────────────────────────────

local function buildCorePillar(plot, cx, cz)
    local m = Instance.new("Model"); m.Name = "CorePillar"; m.Parent = plot
    -- Central glowing tower rising through all floors
    makePart(m, "Pillar", Vector3.new(3, FLOOR_H*6, 3), cx, FLOOR_H*3, cz,
        "Really black", nil, true, true)
    makePart(m, "Glow", Vector3.new(1, FLOOR_H*6+2, 1), cx, FLOOR_H*3, cz,
        "Bright violet", Enum.Material.Neon, false, true)
end

-- ── Plots ──────────────────────────────────────────────────────────────────

local function buildPlots()
    for i = 1, NUM_PLOTS do
        local old = workspace:FindFirstChild("Plot_" .. i)
        if old then old:Destroy() end

        local a = (i-1) * (2*math.pi/NUM_PLOTS)
        local cx = math.cos(a) * RADIUS
        local cz = math.sin(a) * RADIUS

        local plot = Instance.new("Folder")
        plot.Name = "Plot_" .. i; plot.Parent = workspace

        local occ = Instance.new("BoolValue")
        occ.Name="IsOccupied"; occ.Value=false; occ.Parent=plot
        local oid = Instance.new("IntValue")
        oid.Name="OwnerId"; oid.Value=0; oid.Parent=plot

        -- Per-plot spawn
        local sp = Instance.new("SpawnLocation"); sp.Name="PlotSpawn"
        sp.Size=Vector3.new(6,1,6); sp.Position=Vector3.new(cx,0.5,cz)
        sp.Anchored=true; sp.Neutral=false; sp.AllowTeamChangeOnTouch=false
        sp.Transparency=0.85; sp.BrickColor=BrickColor.new("Bright red")
        sp.Material=Enum.Material.Neon; sp.Parent=plot

        -- Move sign anchor (above plot)
        local ma = Instance.new("Part"); ma.Name="MoveSignAnchor"
        ma.Size=Vector3.new(1,1,1); ma.Transparency=1; ma.CanCollide=false
        ma.Anchored=true; ma.Position=Vector3.new(cx,8+FLOOR_H*6,cz); ma.Parent=plot

        -- Point light
        local lp = Instance.new("Part"); lp.Name="PlotLight"
        lp.Size=Vector3.new(1,1,1); lp.Transparency=1; lp.CanCollide=false
        lp.Anchored=true; lp.Position=Vector3.new(cx,FLOOR_H*6+20,cz); lp.Parent=plot
        local pl = Instance.new("PointLight",lp); pl.Brightness=4; pl.Range=80
        pl.Color=Color3.fromRGB(180,0,255)

        -- Lab floor (ground floor, fills full plot width)
        buildLabFloor(plot, cx, cz)

        -- Upper floors (stacked)
        for floorIdx, floorData in ipairs(UPPER_FLOORS) do
            buildUpperFloor(plot, cx, cz, floorData, floorIdx)
        end

        -- Core glow pillar (rises through all floors)
        buildCorePillar(plot, cx, cz)

        -- Base label anchor (high above)
        local bla = Instance.new("Part"); bla.Name="BaseLabelAnchor"
        bla.Size=Vector3.new(1,1,1); bla.Transparency=1; bla.CanCollide=false
        bla.Anchored=true; bla.Position=Vector3.new(cx, FLOOR_H*7+10, cz); bla.Parent=plot
    end
end

-- ── Spawn ──────────────────────────────────────────────────────────────────

local function buildSpawn()
    local old = workspace:FindFirstChild("VillainSpawn")
    if old then old:Destroy() end
    local sp = Instance.new("SpawnLocation"); sp.Name="VillainSpawn"
    sp.Size=Vector3.new(6,1,6); sp.CFrame=CFrame.new(0,0.5,0)
    sp.Anchored=true; sp.BrickColor=BrickColor.new("Bright red")
    sp.Material=Enum.Material.Neon; sp.Parent=workspace
end

-- ── Run ────────────────────────────────────────────────────────────────────

buildLighting()
buildTerrain()
buildPlots()
buildSpawn()
print("[WorldSetup] Multi-floor HQ world built")
