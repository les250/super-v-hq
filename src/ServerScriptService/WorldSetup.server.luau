-- src/ServerScriptService/WorldSetup.server.luau
local Lighting = game:GetService("Lighting")
local RoomData  = require(game.ReplicatedStorage.RoomData)

local NUM_PLOTS = 6
local RADIUS    = 280
local FLOOR_H   = 14   -- studs per floor

-- Lab layout (floor 1 — large ground-level building)
local LAB_W, LAB_D = 116, 94
local DEPT_X    = { -44, -22, 0, 22, 44 }
local STATION_Z = {}
for i = 1, 10 do STATION_Z[i] = -36 + (i-1)*8 end

-- Upper floor buildings sit BEHIND the lab (away from centre)
-- Lab front entrance faces the map centre (+Z toward centre)
-- Upper floors stacked behind the lab and elevated

local DEPT_MAT = {
    Enum.Material.Marble,
    Enum.Material.Metal,
    Enum.Material.Concrete,
    Enum.Material.SmoothPlastic,
    Enum.Material.DiamondPlate,
}
local DEPT_FLOOR_COL = { "White","Dark grey","Light grey","Really black","Dark stone grey" }
local DEPT_ACCENT    = { "Bright green","Bright blue","Cyan","Bright violet","Bright red" }

local UPPER_FLOORS = {
    {id="armory",          name="Armory",        wc="Dark grey",     fc="Dark stone grey", floor=2},
    {id="minion_barracks", name="Minion Barracks",wc="Bright orange", fc="Reddish brown",   floor=3},
    {id="war_room",        name="War Room",       wc="Really black",  fc="Dark grey",       floor=4},
    {id="vault",           name="Vault",          wc="Bright yellow", fc="Gold",            floor=5},
    {id="escape_pod_bay",  name="Escape Pod Bay", wc="White",         fc="Mid gray",        floor=6},
}

-- ── Part helpers ───────────────────────────────────────────────────────────

local function vp(parent, name, sz, px, py, pz, col, mat, noCollide)
    local pt = Instance.new("Part")
    pt.Name=name; pt.Size=sz; pt.Position=Vector3.new(px,py,pz)
    pt.Anchored=true; pt.CanCollide = noCollide~=true; pt.Transparency=0
    pt.BrickColor=BrickColor.new(col); pt.Material=mat or Enum.Material.SmoothPlastic
    pt.Parent=parent; return pt
end

local function hp(parent, name, sz, px, py, pz, col, mat, collidable)
    local pt = Instance.new("Part")
    pt.Name=name; pt.Size=sz; pt.Position=Vector3.new(px,py,pz)
    pt.Anchored=true; pt.CanCollide=false; pt.Transparency=1
    pt.BrickColor=BrickColor.new(col); pt.Material=mat or Enum.Material.SmoothPlastic
    pt:SetAttribute("ShouldCollide", collidable==true)
    pt.Parent=parent; return pt
end

-- ── Lighting ───────────────────────────────────────────────────────────────

local function buildLighting()
    Lighting.ClockTime      = 20        -- late evening, some sky glow
    Lighting.Brightness     = 3         -- bright enough to see everything
    Lighting.Ambient        = Color3.fromRGB(120, 80, 180)   -- visible purple ambient
    Lighting.OutdoorAmbient = Color3.fromRGB(80,  50, 140)   -- outdoor fill light
    Lighting.FogEnd         = 1400
    Lighting.FogColor       = Color3.fromRGB(20, 0, 40)

    -- Remove old effects first
    for _, e in ipairs(Lighting:GetChildren()) do e:Destroy() end

    local atmo = Instance.new("Atmosphere", Lighting)
    atmo.Density = 0.2
    atmo.Color   = Color3.fromRGB(100, 0, 160)
    atmo.Haze    = 1.5
    atmo.Glare   = 0.3

    -- Bloom makes neon elements pop
    local bloom = Instance.new("BloomEffect", Lighting)
    bloom.Intensity  = 0.8
    bloom.Size       = 24
    bloom.Threshold  = 0.9

    -- Slight colour correction to keep villain purple tone
    local cc = Instance.new("ColorCorrectionEffect", Lighting)
    cc.Saturation = 0.2
    cc.Contrast   = 0.1
    cc.TintColor  = Color3.fromRGB(220, 200, 255)
end

-- ── Terrain ────────────────────────────────────────────────────────────────

local function buildTerrain()
    for _,n in ipairs({"VillainFloor","CentrePad","GlowRing"}) do
        local o=workspace:FindFirstChild(n); if o then o:Destroy() end
    end
    for _,o in pairs(workspace:GetChildren()) do
        if o.Name=="PathSegment" then o:Destroy() end
    end
    -- Solid ground covering the whole map
    vp(workspace,"VillainFloor",Vector3.new(1400,2,1400),0,-1,0,"Really black",Enum.Material.SmoothPlastic)
    -- Centre disc
    vp(workspace,"CentrePad",Vector3.new(60,1,60),0,0,0,"Dark grey",Enum.Material.SmoothPlastic)
    -- Centre glow ring (flat neon disc)
    vp(workspace,"GlowRing",Vector3.new(100,0.2,100),0,0.1,0,"Bright red",Enum.Material.Neon,true)
    -- Paths to plots
    for i=1,NUM_PLOTS do
        local a=(i-1)*(2*math.pi/NUM_PLOTS)
        local cx=math.cos(a)*RADIUS/2; local cz=math.sin(a)*RADIUS/2
        local path=Instance.new("Part"); path.Name="PathSegment"
        path.Size=Vector3.new(8,0.2,RADIUS)
        path.CFrame=CFrame.new(cx,0.1,cz)*CFrame.Angles(0,-a,0)
        path.Anchored=true; path.CanCollide=false
        path.BrickColor=BrickColor.new("Dark grey"); path.Material=Enum.Material.SmoothPlastic
        path.Parent=workspace
    end
end

-- ── Lab building (ground floor, floor is VillainFloor — no raised interior) ─

local function buildLabFloor(plot, cx, cz)
    -- The lab FRONT faces toward the plot centre (toward map origin).
    -- cz+D/2 is the BACK of the lab (away from centre).
    -- cz-D/2 is the FRONT (facing centre, open entrance).
    local W, D, H, T = LAB_W, LAB_D, FLOOR_H, 1.5
    local bm=Instance.new("Model"); bm.Name="Room_lab_building"; bm.Parent=plot

    -- Walls (always visible, collidable) — NO raised floor, players walk on VillainFloor
    vp(bm,"BkWall", Vector3.new(W,H,T),       cx,        H/2,    cz+D/2-T/2, "Really black")  -- back
    vp(bm,"LWall",  Vector3.new(T,H,D),       cx-W/2+T/2,H/2,    cz,         "Really black")  -- left
    vp(bm,"RWall",  Vector3.new(T,H,D),       cx+W/2-T/2,H/2,    cz,         "Really black")  -- right
    -- Front wall: 40-stud wide entrance (facing toward map centre = cz-D/2)
    local fw=(W-40)/2
    vp(bm,"FrL",  Vector3.new(fw,H,T),  cx-(W/2-fw/2), H/2,  cz-D/2+T/2, "Really black")
    vp(bm,"FrR",  Vector3.new(fw,H,T),  cx+(W/2-fw/2), H/2,  cz-D/2+T/2, "Really black")
    vp(bm,"FrTop",Vector3.new(40,4,T),  cx,            H-2,   cz-D/2+T/2, "Really black")
    -- Ceiling
    vp(bm,"Ceil", Vector3.new(W,T,D),   cx,            H-T/2, cz,         "Really black",nil,true)

    -- Dept dividers (thin, no collision so players walk freely)
    for d=1,4 do
        local wx=cx+(DEPT_X[d]+DEPT_X[d+1])/2
        vp(bm,"Div"..d,Vector3.new(T,H-3,D-6),wx,H/2,cz,"Dark grey",nil,true)
    end

    -- Dept floor zones (slightly above VillainFloor, coloured texture)
    for dIdx=1,5 do
        local dx=cx+DEPT_X[dIdx]
        vp(bm,"DZone"..dIdx,  Vector3.new(20,0.3,D-4),dx,0.15,cz,DEPT_FLOOR_COL[dIdx],DEPT_MAT[dIdx],true)
        -- Neon ceiling strips
        vp(bm,"CStrip"..dIdx, Vector3.new(18,0.3,D-2),dx,H-1.5,cz,DEPT_ACCENT[dIdx],Enum.Material.Neon,true)
        -- Neon floor edge lines
        vp(bm,"FEdge"..dIdx,  Vector3.new(18,0.2,0.5),dx,0.3,cz-D/2+3,DEPT_ACCENT[dIdx],Enum.Material.Neon,true)
        vp(bm,"BEdge"..dIdx,  Vector3.new(18,0.2,0.5),dx,0.3,cz+D/2-3,DEPT_ACCENT[dIdx],Enum.Material.Neon,true)
    end

    -- Interior lights per department (always on so you can see inside)
    local DEPT_LIGHT_COLORS = {
        Color3.fromRGB(80,255,120),   -- Chemistry: green
        Color3.fromRGB(80,160,255),   -- Electronics: blue
        Color3.fromRGB(80,220,220),   -- Biology: cyan
        Color3.fromRGB(180,80,255),   -- Physics: violet
        Color3.fromRGB(255,80,80),    -- Weapons: red
    }
    for dIdx=1,5 do
        local dx=cx+DEPT_X[dIdx]
        local col=DEPT_LIGHT_COLORS[dIdx]
        for _, zOff in ipairs({-D/4, D/4}) do
            local lp=Instance.new("Part"); lp.Size=Vector3.new(0.5,0.5,0.5)
            lp.Position=Vector3.new(dx,H-2,cz+zOff)
            lp.Anchored=true; lp.CanCollide=false; lp.Transparency=1; lp.Parent=bm
            local pl=Instance.new("PointLight",lp)
            pl.Brightness=3; pl.Range=42; pl.Color=col
        end
    end

    -- 50 station pads + hidden equipment
    for dIdx=1,5 do
        for sIdx=1,10 do
            local stId = "lab_"..RoomData.LAB_DEPTS[dIdx].name.."_"..sIdx
            local dx   = cx+DEPT_X[dIdx]
            local dz   = cz+STATION_Z[sIdx]
            local acol = DEPT_ACCENT[dIdx]
            local dmat = DEPT_MAT[dIdx]

            -- Pad (always visible, collidable — players stand on it)
            vp(plot,"DropPad_"..stId,Vector3.new(5,0.3,5),dx,0.25,dz,acol,Enum.Material.Neon)

            -- Station model (hidden until bought)
            local sm=Instance.new("Model"); sm.Name="Room_"..stId; sm.Parent=plot
            hp(sm,"Base",  Vector3.new(4.5,0.5,4.5), dx,0.55,  dz, acol, dmat, true)
            hp(sm,"Body",  Vector3.new(3,6,3),        dx,3.8,   dz, DEPT_FLOOR_COL[dIdx], DEPT_MAT[dIdx], true)
            hp(sm,"Panel", Vector3.new(2.5,3,0.3),    dx,4.8,   dz+1.6, acol, Enum.Material.SmoothPlastic, false)
            hp(sm,"Glow",  Vector3.new(2,0.5,2),      dx,7.05,  dz, acol, Enum.Material.Neon, false)
            hp(sm,"Light", Vector3.new(0.3,5.5,0.3),  dx+1.8,3.8,dz, acol, Enum.Material.Neon, false)
        end
    end
end

-- ── Upper floors (stacked BEHIND the lab building, away from map centre) ──

local function buildUpperFloor(plot, cx, cz, fd)
    -- Upper floors sit behind the lab (at cz+LAB_D/2 onward, away from centre)
    -- Each floor is offset further back and elevated
    local floorIdx = fd.floor - 1   -- 1-5
    local W, D, H, T = 28, 28, FLOOR_H, 1.5
    -- Lateral offset: spread upper floors side by side so they're all reachable
    local lateralOffset = (floorIdx - 3) * (W + 4)  -- centre on floor 3
    local buildX = cx + lateralOffset
    local buildZ = cz + LAB_D/2 + D/2 + 6   -- just behind the lab back wall
    local yBase  = FLOOR_H * fd.floor

    local m=Instance.new("Model"); m.Name="Room_"..fd.id; m.Parent=plot

    -- Structure (hidden until bought)
    hp(m,"Floor",  Vector3.new(W,T,D),    buildX,yBase+T/2,    buildZ, fd.fc, nil, true)
    hp(m,"Ceil",   Vector3.new(W,T,D),    buildX,yBase+H-T/2,  buildZ, fd.wc, nil, false)
    hp(m,"BkWall", Vector3.new(W,H,T),    buildX,yBase+H/2,    buildZ+D/2-T/2, fd.wc, nil, true)
    hp(m,"LWall",  Vector3.new(T,H,D), buildX-W/2+T/2,yBase+H/2,buildZ, fd.wc, nil, true)
    hp(m,"RWall",  Vector3.new(T,H,D), buildX+W/2-T/2,yBase+H/2,buildZ, fd.wc, nil, true)
    local fw2=(W-8)/2
    hp(m,"FrL",  Vector3.new(fw2,H,T),  buildX-(W/2-fw2/2),yBase+H/2,buildZ-D/2+T/2, fd.wc, nil, true)
    hp(m,"FrR",  Vector3.new(fw2,H,T),  buildX+(W/2-fw2/2),yBase+H/2,buildZ-D/2+T/2, fd.wc, nil, true)
    hp(m,"FrTop",Vector3.new(8,4,T),    buildX,yBase+H-2,             buildZ-D/2+T/2, fd.wc, nil, true)
    hp(m,"Strip",Vector3.new(W-2,0.3,D-2),buildX,yBase+H-1.5,buildZ,"Bright violet",Enum.Material.Neon,false)

    -- Drop pad at ground level in front of the staircase (always accessible)
    vp(plot,"DropPad_"..fd.id,Vector3.new(6,0.3,6),
        buildX, 0.25, buildZ-D/2-4, "Bright green", Enum.Material.Neon)

    -- Visible staircase from ground up to this floor (behind lab, no clipping)
    local sm=Instance.new("Model"); sm.Name="Stair_"..fd.id; sm.Parent=plot
    local stepsNeeded = math.ceil(yBase/1.8)
    for s=1,stepsNeeded do
        vp(sm,"Step"..s, Vector3.new(W-2,0.5,2),
            buildX, s*1.8-0.25, buildZ-D/2-4+s*1.4,
            "Dark grey", Enum.Material.SmoothPlastic)
    end

    -- Floor label (always visible marker showing which floor this is)
    local labelPart = vp(plot, "FloorMarker_"..fd.id,
        Vector3.new(W-2, 0.3, 2),
        buildX, 0.4, buildZ-D/2-4, fd.fc, nil, true)
    labelPart.Parent = plot
end

-- ── Plots ──────────────────────────────────────────────────────────────────

local function buildPlots()
    for i=1,NUM_PLOTS do
        local old=workspace:FindFirstChild("Plot_"..i); if old then old:Destroy() end

        local a  = (i-1)*(2*math.pi/NUM_PLOTS)
        local cx = math.cos(a)*RADIUS
        local cz = math.sin(a)*RADIUS

        -- Rotate lab so its entrance faces the map centre
        -- "toward centre" = direction from plot to (0,0,0)
        -- The lab is always built with +Z = deeper into plot (away from centre)
        -- So cz-D/2 is the entrance side = faces toward (0,0,0)
        -- This is already correct since cx,cz point away from centre

        local plot=Instance.new("Folder"); plot.Name="Plot_"..i; plot.Parent=workspace
        local occ=Instance.new("BoolValue"); occ.Name="IsOccupied"; occ.Value=false; occ.Parent=plot
        local oid=Instance.new("IntValue");  oid.Name="OwnerId";    oid.Value=0;     oid.Parent=plot

        -- Per-plot spawn: in front of lab entrance, on solid ground
        local spawnZ = cz - LAB_D/2 - 10
        local sp=Instance.new("SpawnLocation"); sp.Name="PlotSpawn"
        sp.Size=Vector3.new(6,1,6); sp.Position=Vector3.new(cx,0.5,spawnZ)
        sp.Anchored=true; sp.Neutral=false; sp.AllowTeamChangeOnTouch=false
        sp.Transparency=0.7; sp.BrickColor=BrickColor.new("Bright red"); sp.Material=Enum.Material.Neon
        sp.Parent=plot

        -- Move sign and sky label anchors
        local ma=Instance.new("Part"); ma.Name="MoveSignAnchor"
        ma.Size=Vector3.new(1,1,1); ma.Transparency=1; ma.CanCollide=false
        ma.Anchored=true; ma.Position=Vector3.new(cx,FLOOR_H*7+5,cz); ma.Parent=plot
        local bla=Instance.new("Part"); bla.Name="BaseLabelAnchor"
        bla.Size=Vector3.new(1,1,1); bla.Transparency=1; bla.CanCollide=false
        bla.Anchored=true; bla.Position=Vector3.new(cx,FLOOR_H*8,cz); bla.Parent=plot

        -- Point light
        local lp=Instance.new("Part"); lp.Name="PlotLight"
        lp.Size=Vector3.new(1,1,1); lp.Transparency=1; lp.CanCollide=false
        lp.Anchored=true; lp.Position=Vector3.new(cx,FLOOR_H*7,cz); lp.Parent=plot
        local pl=Instance.new("PointLight",lp); pl.Brightness=5; pl.Range=100
        pl.Color=Color3.fromRGB(180,0,255)

        buildLabFloor(plot, cx, cz)
        for _, fd in ipairs(UPPER_FLOORS) do
            buildUpperFloor(plot, cx, cz, fd)
        end
    end
end

-- ── Global spawn ───────────────────────────────────────────────────────────

local function buildSpawn()
    local old=workspace:FindFirstChild("VillainSpawn"); if old then old:Destroy() end
    local sp=Instance.new("SpawnLocation"); sp.Name="VillainSpawn"
    sp.Size=Vector3.new(10,1,10); sp.CFrame=CFrame.new(0,0.5,0)
    sp.Anchored=true; sp.BrickColor=BrickColor.new("Bright red")
    sp.Material=Enum.Material.Neon; sp.Parent=workspace
end

-- ── Run ────────────────────────────────────────────────────────────────────

buildLighting(); buildTerrain(); buildSpawn(); buildPlots()
print("[WorldSetup] World built")
