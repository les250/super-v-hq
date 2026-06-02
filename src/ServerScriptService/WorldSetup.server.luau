-- src/ServerScriptService/WorldSetup.server.luau
local Lighting = game:GetService("Lighting")
local RoomData  = require(game.ReplicatedStorage.RoomData)

local NUM_PLOTS = 6
local RADIUS    = 260
local FLOOR_H   = 14

-- Lab layout
local LAB_W, LAB_D = 116, 94
local DEPT_X   = { -44, -22, 0, 22, 44 }  -- 5 dept column centres
local STATION_Z = {}
for i = 1, 10 do STATION_Z[i] = -36 + (i-1)*8 end  -- 8 studs apart, 10 rows

local DEPT_MAT = {
    Enum.Material.Marble,       -- Chemistry  (clean, sterile)
    Enum.Material.Metal,        -- Electronics (industrial)
    Enum.Material.Tiles,        -- Biology    (clinical)
    Enum.Material.SmoothPlastic,-- Physics    (high-tech)
    Enum.Material.DiamondPlate, -- Weapons    (military)
}
local DEPT_FLOOR_COL = {
    "White",        -- Chemistry
    "Dark grey",    -- Electronics
    "Light grey",   -- Biology
    "Really black", -- Physics
    "Dark stone grey", -- Weapons
}
local DEPT_ACCENT = {
    "Bright green", "Bright blue", "Cyan", "Bright violet", "Bright red"
}
local DEPT_NEON_MAT = Enum.Material.Neon

local UPPER_FLOORS = {
    {id="armory",         name="Armory",        wc="Dark grey",     fc="Dark stone grey", floor=2},
    {id="minion_barracks",name="Minion Barracks",wc="Bright orange", fc="Reddish brown",   floor=3},
    {id="war_room",       name="War Room",       wc="Really black",  fc="Dark grey",       floor=4},
    {id="vault",          name="Vault",          wc="Bright yellow", fc="Gold",            floor=5},
    {id="escape_pod_bay", name="Escape Pod Bay", wc="White",         fc="Mid gray",        floor=6},
}

-- ── Part helpers ───────────────────────────────────────────────────────────

-- Visible part (permanent, collidable)
local function vp(parent, name, sz, px, py, pz, col, mat, noCollide)
    local pt = Instance.new("Part")
    pt.Name = name; pt.Size = sz
    pt.Position = Vector3.new(px, py, pz)
    pt.Anchored = true
    pt.CanCollide = noCollide ~= true
    pt.Transparency = 0
    pt.BrickColor = BrickColor.new(col)
    pt.Material = mat or Enum.Material.SmoothPlastic
    pt.Parent = parent
    return pt
end

-- Hidden part (invisible until bought, no collision until visible)
-- Stores intended collision state in attribute for DropPadClient to restore
local function hp(parent, name, sz, px, py, pz, col, mat, collidable)
    local pt = Instance.new("Part")
    pt.Name = name; pt.Size = sz
    pt.Position = Vector3.new(px, py, pz)
    pt.Anchored = true
    pt.CanCollide = false
    pt.Transparency = 1
    pt.BrickColor = BrickColor.new(col)
    pt.Material = mat or Enum.Material.SmoothPlastic
    pt:SetAttribute("ShouldCollide", collidable == true)
    pt.Parent = parent
    return pt
end

-- ── Lighting ───────────────────────────────────────────────────────────────

local function buildLighting()
    Lighting.ClockTime = 0; Lighting.Brightness = 1.5
    Lighting.Ambient = Color3.fromRGB(40, 0, 60)
    Lighting.OutdoorAmbient = Color3.fromRGB(20, 0, 40)
    Lighting.FogEnd = 1000; Lighting.FogColor = Color3.fromRGB(15, 0, 30)
    local a = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
    a.Density=0.3; a.Color=Color3.fromRGB(80,0,120); a.Haze=2
end

-- ── Terrain ────────────────────────────────────────────────────────────────

local function buildTerrain()
    for _, n in ipairs({"VillainFloor","CentrePad","GlowRing"}) do
        local o=workspace:FindFirstChild(n); if o then o:Destroy() end
    end
    for _, o in pairs(workspace:GetChildren()) do
        if o.Name=="PathSegment" then o:Destroy() end
    end
    vp(workspace,"VillainFloor",Vector3.new(1200,1,1200),0,-0.5,0,"Really black")
    local c=Instance.new("Part"); c.Name="CentrePad"; c.Size=Vector3.new(50,1,50)
    c.Position=Vector3.new(0,0.2,0); c.Anchored=true; c.Shape=Enum.PartType.Cylinder
    c.BrickColor=BrickColor.new("Dark grey"); c.Material=Enum.Material.SmoothPlastic; c.Parent=workspace
    local r=Instance.new("Part"); r.Name="GlowRing"; r.Size=Vector3.new(3,0.3,600)
    r.Position=Vector3.new(0,0.3,0); r.Anchored=true; r.Shape=Enum.PartType.Cylinder
    r.BrickColor=BrickColor.new("Bright red"); r.Material=DEPT_NEON_MAT; r.Parent=workspace
    for i=1,NUM_PLOTS do
        local a=(i-1)*(2*math.pi/NUM_PLOTS)
        local cx=math.cos(a)*RADIUS/2; local cz=math.sin(a)*RADIUS/2
        local path=Instance.new("Part"); path.Name="PathSegment"
        path.Size=Vector3.new(8,0.3,RADIUS)
        path.CFrame=CFrame.new(cx,0.15,cz)*CFrame.Angles(0,-a,0)
        path.Anchored=true; path.BrickColor=BrickColor.new("Dark grey")
        path.Material=Enum.Material.SmoothPlastic; path.Parent=workspace
    end
end

-- ── Lab floor (ground, always visible building, hidden station equipment) ──

local function buildLabFloor(plot, cx, cz)
    local W, D, H, T = LAB_W, LAB_D, FLOOR_H, 1.5
    local bm = Instance.new("Model"); bm.Name="Room_lab_building"; bm.Parent=plot

    -- Permanent structure (always visible, collidable)
    vp(bm,"Floor",   Vector3.new(W,T,D),    cx,T/2,    cz,"Dark grey",Enum.Material.SmoothPlastic)
    vp(bm,"Ceiling", Vector3.new(W,T,D),    cx,H-T/2,  cz,"Really black",nil,true)
    vp(bm,"BkWall",  Vector3.new(W,H,T),    cx,H/2,    cz-D/2+T/2,"Really black")
    vp(bm,"LWall",   Vector3.new(T,H,D),    cx-W/2+T/2,H/2,cz,"Really black")
    vp(bm,"RWall",   Vector3.new(T,H,D),    cx+W/2-T/2,H/2,cz,"Really black")
    -- Front wall with 40-stud wide entrance
    local fw=(W-40)/2
    vp(bm,"FrL", Vector3.new(fw,H,T), cx-(W/2-fw/2),H/2,cz+D/2-T/2,"Really black")
    vp(bm,"FrR", Vector3.new(fw,H,T), cx+(W/2-fw/2),H/2,cz+D/2-T/2,"Really black")
    vp(bm,"FrTop",Vector3.new(40,4,T),cx,H-2,cz+D/2-T/2,"Really black")

    -- Dept divider walls (thin, visible)
    for d=1,4 do
        local wx = cx + (DEPT_X[d]+DEPT_X[d+1])/2
        vp(bm,"Div"..d,Vector3.new(T,H-3,D-6),wx,H/2,cz,"Dark grey")
    end

    -- Dept zone floors (coloured and textured per dept, slightly raised)
    for dIdx=1,5 do
        local dx = cx + DEPT_X[dIdx]
        vp(bm,"DeptFloor"..dIdx, Vector3.new(20,0.2,D-4),
            dx, T+0.1, cz, DEPT_FLOOR_COL[dIdx], DEPT_MAT[dIdx], true)
        -- Dept label strip on ceiling
        vp(bm,"DeptStrip"..dIdx, Vector3.new(18,0.3,D-2),
            dx, H-1.5, cz, DEPT_ACCENT[dIdx], DEPT_NEON_MAT, true)
        -- Dept neon border on back wall
        vp(bm,"DeptBorder"..dIdx, Vector3.new(18,0.4,T+0.1),
            dx, H-4, cz-D/2+T/2+0.1, DEPT_ACCENT[dIdx], DEPT_NEON_MAT, true)
    end

    -- 50 station drop pads + hidden models
    for dIdx=1,5 do
        for sIdx=1,10 do
            local stId  = "lab_"..RoomData.LAB_DEPTS[dIdx].name.."_"..sIdx
            local dx    = cx + DEPT_X[dIdx]
            local dz    = cz + STATION_Z[sIdx]
            local acol  = DEPT_ACCENT[dIdx]
            local dmat  = DEPT_MAT[dIdx]

            -- Drop pad (always visible, collidable)
            local pad = Instance.new("Part")
            pad.Name     = "DropPad_"..stId
            pad.Size     = Vector3.new(5,0.3,5)
            pad.Position = Vector3.new(dx, T+0.25, dz)
            pad.Anchored = true; pad.BrickColor = BrickColor.new(acol)
            pad.Material = DEPT_NEON_MAT; pad.Parent = plot

            -- Station model (hidden until bought)
            local sm = Instance.new("Model"); sm.Name="Room_"..stId; sm.Parent=plot

            -- Base plate
            hp(sm,"Base",   Vector3.new(4.5,0.5,4.5), dx, T+0.65, dz, acol, dmat, true)
            -- Main equipment body
            hp(sm,"Body",   Vector3.new(3,6,3),        dx, T+4,    dz, DEPT_FLOOR_COL[dIdx], DEPT_MAT[dIdx], true)
            -- Front screen/panel
            hp(sm,"Panel",  Vector3.new(2.5,3,0.3),    dx, T+5,    dz+1.6, acol, Enum.Material.SmoothPlastic, false)
            -- Glow on top
            hp(sm,"Glow",   Vector3.new(2,0.5,2),      dx, T+7.3,  dz, acol, DEPT_NEON_MAT, false)
            -- Side indicator light
            hp(sm,"Light",  Vector3.new(0.3,4,0.3),    dx+1.8, T+4, dz, acol, DEPT_NEON_MAT, false)
        end
    end
end

-- ── Upper floor rooms ──────────────────────────────────────────────────────

local function buildUpperFloor(plot, cx, cz, fd, fIdx)
    local yBase = FLOOR_H * fd.floor
    local W, D, H, T = 26, 26, FLOOR_H, 1.5
    local m = Instance.new("Model"); m.Name="Room_"..fd.id; m.Parent=plot

    -- Floor/walls/ceiling — hidden until bought, structural parts collidable when visible
    hp(m,"Floor",   Vector3.new(W,T,D),     cx,   yBase+T/2,     cz,          fd.fc, nil, true)
    hp(m,"Ceiling", Vector3.new(W,T,D),     cx,   yBase+H-T/2,   cz,          fd.wc, nil, false)
    hp(m,"BkWall",  Vector3.new(W,H,T),     cx,   yBase+H/2,     cz-D/2+T/2,  fd.wc, nil, true)
    hp(m,"LWall",   Vector3.new(T,H,D),     cx-W/2+T/2, yBase+H/2, cz,        fd.wc, nil, true)
    hp(m,"RWall",   Vector3.new(T,H,D),     cx+W/2-T/2, yBase+H/2, cz,        fd.wc, nil, true)
    local fw=(W-8)/2
    hp(m,"FrL",  Vector3.new(fw,H,T),  cx-(W/2-fw/2), yBase+H/2, cz+D/2-T/2, fd.wc, nil, true)
    hp(m,"FrR",  Vector3.new(fw,H,T),  cx+(W/2-fw/2), yBase+H/2, cz+D/2-T/2, fd.wc, nil, true)
    hp(m,"FrTop",Vector3.new(8,4,T),   cx, yBase+H-2,             cz+D/2-T/2, fd.wc, nil, true)
    -- Interior neon strip
    hp(m,"Strip",Vector3.new(W-2,0.3,D-2),cx,yBase+H-1.5,cz,"Bright violet",DEPT_NEON_MAT,false)

    -- Drop pad (elevated, on a visible platform outside the room)
    local padY = yBase + 0.25
    local padPart = Instance.new("Part")
    padPart.Name     = "DropPad_"..fd.id
    padPart.Size     = Vector3.new(6,0.5,6)
    padPart.Position = Vector3.new(cx, padY, cz + D/2 + 4)
    padPart.Anchored = true
    padPart.BrickColor = BrickColor.new("Bright green")
    padPart.Material = DEPT_NEON_MAT
    padPart.Parent = plot

    -- Visible exterior staircase up to this floor
    local steps = math.ceil(yBase / 1.5)
    local sm = Instance.new("Model"); sm.Name="Stair_"..fd.id; sm.Parent=plot
    for s=1,steps do
        vp(sm,"Step"..s, Vector3.new(5,0.5,1.5),
            cx, s*1.5-0.25, cz+D/2+4-s*1.1, "Dark grey", Enum.Material.SmoothPlastic)
    end

    -- "Locked" barrier at staircase top — hidden part so it blocks entry when invisible room is locked
    -- This is handled by the invisible walls above; staircase is just visual
end

-- ── Central tower (always visible) ────────────────────────────────────────

local function buildTower(plot, cx, cz)
    local m = Instance.new("Model"); m.Name="CentralTower"; m.Parent=plot
    local totalH = FLOOR_H * 7
    vp(m,"Shaft", Vector3.new(4,totalH,4),   cx, totalH/2, cz, "Really black", Enum.Material.SmoothPlastic)
    vp(m,"Glow",  Vector3.new(1,totalH+2,1), cx, totalH/2, cz, "Bright violet", DEPT_NEON_MAT, true)
end

-- ── Plots ──────────────────────────────────────────────────────────────────

local function buildPlots()
    for i=1,NUM_PLOTS do
        local old=workspace:FindFirstChild("Plot_"..i); if old then old:Destroy() end

        local a  = (i-1)*(2*math.pi/NUM_PLOTS)
        local cx = math.cos(a)*RADIUS
        local cz = math.sin(a)*RADIUS

        local plot=Instance.new("Folder"); plot.Name="Plot_"..i; plot.Parent=workspace

        local occ=Instance.new("BoolValue"); occ.Name="IsOccupied"; occ.Value=false; occ.Parent=plot
        local oid=Instance.new("IntValue");  oid.Name="OwnerId";    oid.Value=0;     oid.Parent=plot

        -- Per-plot spawn
        local sp=Instance.new("SpawnLocation"); sp.Name="PlotSpawn"
        sp.Size=Vector3.new(6,1,6); sp.Position=Vector3.new(cx,0.5,cz+LAB_D/2+20)
        sp.Anchored=true; sp.Neutral=false; sp.AllowTeamChangeOnTouch=false
        sp.Transparency=0.8; sp.BrickColor=BrickColor.new("Bright red"); sp.Material=DEPT_NEON_MAT
        sp.Parent=plot

        -- Move sign anchor
        local ma=Instance.new("Part"); ma.Name="MoveSignAnchor"
        ma.Size=Vector3.new(1,1,1); ma.Transparency=1; ma.CanCollide=false
        ma.Anchored=true; ma.Position=Vector3.new(cx,FLOOR_H*8,cz); ma.Parent=plot

        -- Sky label anchor
        local bla=Instance.new("Part"); bla.Name="BaseLabelAnchor"
        bla.Size=Vector3.new(1,1,1); bla.Transparency=1; bla.CanCollide=false
        bla.Anchored=true; bla.Position=Vector3.new(cx,FLOOR_H*9,cz); bla.Parent=plot

        -- Point light
        local lp=Instance.new("Part"); lp.Name="PlotLight"
        lp.Size=Vector3.new(1,1,1); lp.Transparency=1; lp.CanCollide=false
        lp.Anchored=true; lp.Position=Vector3.new(cx,FLOOR_H*7+10,cz); lp.Parent=plot
        local pl=Instance.new("PointLight",lp); pl.Brightness=4; pl.Range=90
        pl.Color=Color3.fromRGB(180,0,255)

        buildLabFloor(plot, cx, cz)
        for fIdx, fd in ipairs(UPPER_FLOORS) do
            buildUpperFloor(plot, cx, cz, fd, fIdx)
        end
        buildTower(plot, cx, cz)
    end
end

-- ── Spawn ──────────────────────────────────────────────────────────────────

local function buildSpawn()
    local old=workspace:FindFirstChild("VillainSpawn"); if old then old:Destroy() end
    local sp=Instance.new("SpawnLocation"); sp.Name="VillainSpawn"
    sp.Size=Vector3.new(8,1,8); sp.CFrame=CFrame.new(0,0.5,0)
    sp.Anchored=true; sp.BrickColor=BrickColor.new("Bright red")
    sp.Material=DEPT_NEON_MAT; sp.Parent=workspace
end

-- ── Run ────────────────────────────────────────────────────────────────────

buildLighting(); buildTerrain(); buildPlots(); buildSpawn()
print("[WorldSetup] World built — multi-floor HQ with textured lab")
