-- src/ServerScriptService/WorldSetup.server.luau
local Lighting = game:GetService("Lighting")
local RoomData  = require(game.ReplicatedStorage.RoomData)

local NUM_PLOTS = 6
local RADIUS    = 320
local H         = 14   -- floor height
local T         = 1.2  -- wall thickness
local DOOR_W    = 10   -- door gap width
local WIN_W, WIN_H, WIN_BASE = 8, 5, 2  -- window dimensions

local DEPT_MAT = {
    Enum.Material.Marble, Enum.Material.Metal, Enum.Material.Concrete,
    Enum.Material.SmoothPlastic, Enum.Material.DiamondPlate,
}
local DEPT_FLOOR_COL = {"White","Dark grey","Light grey","Really black","Dark stone grey"}
local DEPT_ACCENT    = {"Bright green","Bright blue","Cyan","Bright violet","Bright red"}
local DEPT_LIGHT_COL = {
    Color3.fromRGB(80,255,120), Color3.fromRGB(80,160,255), Color3.fromRGB(80,220,220),
    Color3.fromRGB(180,80,255), Color3.fromRGB(255,80,80),
}

-- ── Part helpers (CFrame-based) ────────────────────────────────────────────

local function vp(parent, name, sz, cf, col, mat, noCol)
    local pt = Instance.new("Part")
    pt.Name=name; pt.Size=sz; pt.CFrame=cf; pt.Anchored=true
    pt.CanCollide=noCol~=true; pt.Transparency=0
    pt.BrickColor=BrickColor.new(col); pt.Material=mat or Enum.Material.SmoothPlastic
    pt.Parent=parent; return pt
end

local function hp(parent, name, sz, cf, col, mat, shouldCol)
    local pt = Instance.new("Part")
    pt.Name=name; pt.Size=sz; pt.CFrame=cf; pt.Anchored=true
    pt.CanCollide=false; pt.Transparency=1
    pt.BrickColor=BrickColor.new(col); pt.Material=mat or Enum.Material.SmoothPlastic
    pt:SetAttribute("ShouldCollide", shouldCol==true)
    pt.Parent=parent; return pt
end

-- ── Lighting ───────────────────────────────────────────────────────────────

local function buildLighting()
    Lighting.ClockTime=20; Lighting.Brightness=3
    Lighting.Ambient=Color3.fromRGB(120,80,180); Lighting.OutdoorAmbient=Color3.fromRGB(80,50,140)
    Lighting.FogEnd=1400; Lighting.FogColor=Color3.fromRGB(20,0,40)
    for _,e in ipairs(Lighting:GetChildren()) do e:Destroy() end
    local a=Instance.new("Atmosphere",Lighting); a.Density=0.2; a.Color=Color3.fromRGB(100,0,160); a.Haze=1.5
    local b=Instance.new("BloomEffect",Lighting); b.Intensity=0.8; b.Size=24; b.Threshold=0.9
    local c=Instance.new("ColorCorrectionEffect",Lighting); c.Saturation=0.2; c.TintColor=Color3.fromRGB(220,200,255)
end

-- ── Terrain ────────────────────────────────────────────────────────────────

local function buildTerrain()
    for _,n in ipairs({"VillainFloor","CentrePad","GlowRing"}) do
        local o=workspace:FindFirstChild(n); if o then o:Destroy() end
    end
    for _,o in pairs(workspace:GetChildren()) do if o.Name=="PathSegment" then o:Destroy() end end
    vp(workspace,"VillainFloor",Vector3.new(1400,2,1400),CFrame.new(0,-1,0),"Really black")
    vp(workspace,"CentrePad",  Vector3.new(60,1,60),     CFrame.new(0,0,0), "Dark grey")
    -- (GlowRing removed)
    for i=1,NUM_PLOTS do
        local a=(i-1)*(2*math.pi/NUM_PLOTS)
        local path=Instance.new("Part"); path.Name="PathSegment"
        path.Size=Vector3.new(8,0.2,RADIUS)
        path.CFrame=CFrame.new(math.cos(a)*RADIUS/2,0.1,math.sin(a)*RADIUS/2)*CFrame.Angles(0,-a,0)
        path.Anchored=true; path.CanCollide=false
        path.BrickColor=BrickColor.new("Dark grey"); path.Material=Enum.Material.SmoothPlastic
        path.Parent=workspace
    end
end

-- ── Room builder ───────────────────────────────────────────────────────────
-- Builds one department room in plot-local space using plotCF.
-- lx, lz: room centre in plot-local coords (lz negative = deeper into plot)
-- W, D: width (X) and depth (Z)
-- doorDir: "N"=deeper, "S"=entrance, "E"=right, "W"=left

local function buildRoom(plot, model, plotCF, deptIdx, lx, lz, W, D, doorDir, stationList)
    local acol = DEPT_ACCENT[deptIdx]
    local dmat = DEPT_MAT[deptIdx]

    local function cf(dx,dy,dz)
        return plotCF * CFrame.new(lx+dx, dy, lz+dz)
    end

    -- Floor zone + ceiling strip
    vp(model,"DFloor"..lx..lz, Vector3.new(W-T*2,0.25,D-T*2), cf(0,0.12,0), DEPT_FLOOR_COL[deptIdx], dmat, true)
    vp(model,"DCeil"..lx..lz,  Vector3.new(W-2,0.3,D-2),       cf(0,H-1.2,0),acol, Enum.Material.Neon, true)

    -- Interior point light
    local lp=Instance.new("Part"); lp.Size=Vector3.new(0.5,0.5,0.5); lp.CFrame=cf(0,H-2,0)
    lp.Anchored=true; lp.CanCollide=false; lp.Transparency=1; lp.Parent=model
    local pl=Instance.new("PointLight",lp); pl.Brightness=4; pl.Range=55; pl.Color=DEPT_LIGHT_COL[deptIdx]

    -- Wall helpers (dy is explicit so door top goes above the gap, not in it)
    local function solidWall(name,sz,dx,dy,dz)
        vp(model,name,sz,cf(dx,dy,dz),"Really black")
    end

    -- Door: gap is 10 studs tall (floor→Y=10), thin solid strip above (Y=10→H)
    local function doorWall(isXAxis, offset)
        local doorH  = 10
        local topH   = H - doorH          -- 4 studs of wall above the door
        local topY   = doorH + topH/2     -- centre of top strip
        if isXAxis then
            local side = (W-DOOR_W)/2
            solidWall("Wd_L",Vector3.new(side,H,T),   -(W/2-side/2), H/2,  offset)
            solidWall("Wd_R",Vector3.new(side,H,T),    (W/2-side/2), H/2,  offset)
            solidWall("Wd_T",Vector3.new(DOOR_W,topH,T), 0,           topY, offset)
            -- Neon accent above door arch
            local g=vp(model,"WdAccent",Vector3.new(DOOR_W,0.4,T),cf(0,doorH,offset),acol,Enum.Material.Neon,true)
        else
            local side = (D-DOOR_W)/2
            solidWall("Wd_L",Vector3.new(T,H,side),    offset, H/2,  -(D/2-side/2))
            solidWall("Wd_R",Vector3.new(T,H,side),    offset, H/2,   (D/2-side/2))
            solidWall("Wd_T",Vector3.new(T,topH,DOOR_W),offset, topY, 0)
            local g=vp(model,"WdAccent",Vector3.new(T,0.4,DOOR_W),cf(offset,doorH,0),acol,Enum.Material.Neon,true)
        end
    end

    local function windowWall(isXAxis, offset)
        local topH  = H - WIN_BASE - WIN_H
        local topY  = WIN_BASE + WIN_H + topH/2
        if isXAxis then
            local side=(W-WIN_W)/2
            solidWall("Ww_L",Vector3.new(side,H,T),           -(W/2-side/2), H/2,           offset)
            solidWall("Ww_R",Vector3.new(side,H,T),            (W/2-side/2), H/2,           offset)
            solidWall("Ww_B",Vector3.new(WIN_W,WIN_BASE,T),    0,             WIN_BASE/2,    offset)
            local g=vp(model,"WwGlass",Vector3.new(WIN_W,WIN_H,T),cf(0,WIN_BASE+WIN_H/2,offset),acol,Enum.Material.SmoothPlastic)
            g.Transparency=0.45
            solidWall("Ww_T",Vector3.new(WIN_W,topH,T),        0,             topY,          offset)
        else
            local side=(D-WIN_W)/2
            solidWall("Ww_L",Vector3.new(T,H,side),            offset, H/2,           -(D/2-side/2))
            solidWall("Ww_R",Vector3.new(T,H,side),            offset, H/2,            (D/2-side/2))
            solidWall("Ww_B",Vector3.new(T,WIN_BASE,WIN_W),    offset, WIN_BASE/2,     0)
            local g=vp(model,"WwGlass",Vector3.new(T,WIN_H,WIN_W),cf(offset,WIN_BASE+WIN_H/2,0),acol,Enum.Material.SmoothPlastic)
            g.Transparency=0.45
            solidWall("Ww_T",Vector3.new(T,topH,WIN_W),        offset, topY,           0)
        end
    end

    -- N=deeper(-Z), S=entrance(+Z), E=right(+X), W=left(-X)
    if doorDir=="S" then
        doorWall(true,    D/2-T/2)
        solidWall("WN",Vector3.new(W,H,T), 0, H/2, -D/2+T/2)
        windowWall(false, -W/2+T/2)
        windowWall(false,  W/2-T/2)
    elseif doorDir=="N" then
        doorWall(true, -D/2+T/2)
        solidWall("WS",Vector3.new(W,H,T), 0, H/2, D/2-T/2)
        windowWall(false,-W/2+T/2)
        windowWall(false, W/2-T/2)
    elseif doorDir=="E" then
        doorWall(false,   W/2-T/2)
        solidWall("WW",Vector3.new(T,H,D),-W/2+T/2, H/2, 0)
        windowWall(true, -D/2+T/2)
        windowWall(true,  D/2-T/2)
    elseif doorDir=="W" then
        doorWall(false,  -W/2+T/2)
        solidWall("WE",Vector3.new(T,H,D), W/2-T/2, H/2, 0)
        windowWall(true, -D/2+T/2)
        windowWall(true,  D/2-T/2)
    end

    -- Station pads + hidden models
    for _, st in ipairs(stationList) do
        local sdx, sdz = st.dx, st.dz
        local pad=Instance.new("Part"); pad.Name="DropPad_"..st.id
        pad.Size=Vector3.new(5,0.3,5); pad.CFrame=cf(sdx,0.25,sdz)
        pad.Anchored=true; pad.BrickColor=BrickColor.new(acol); pad.Material=Enum.Material.Neon
        pad.Parent=plot

        local sm=Instance.new("Model"); sm.Name="Room_"..st.id; sm.Parent=plot
        hp(sm,"Base",  Vector3.new(4.5,0.5,4.5),cf(sdx,0.55,sdz),acol,dmat,true)
        hp(sm,"Body",  Vector3.new(3,6,3),       cf(sdx,3.8,sdz), DEPT_FLOOR_COL[deptIdx],dmat,true)
        hp(sm,"Panel", Vector3.new(2.5,3,0.3),   cf(sdx,4.8,sdz+1.6),acol,Enum.Material.SmoothPlastic,false)
        hp(sm,"Glow",  Vector3.new(2,0.5,2),     cf(sdx,7.05,sdz),acol,Enum.Material.Neon,false)
        hp(sm,"Stem",  Vector3.new(0.3,5.5,0.3), cf(sdx+1.8,3.8,sdz),acol,Enum.Material.Neon,false)
    end
end

-- ── Corridor builder ───────────────────────────────────────────────────────

local function buildCorridor(model, plotCF, lx, lz, W, D)
    local function cf(dx,dy,dz) return plotCF*CFrame.new(lx+dx,dy,lz+dz) end
    vp(model,"CC"..lx..lz, Vector3.new(W-2,0.25,D-2), cf(0,0.12,0), "Dark grey", Enum.Material.SmoothPlastic, true)
    vp(model,"CC_strip"..lx..lz, Vector3.new(W-2,0.3,D-2), cf(0,H-1.2,0),"Bright violet",Enum.Material.Neon,true)
    vp(model,"CC_ceil"..lx..lz,  Vector3.new(W,T,D),        cf(0,H-T/2,0),"Really black",nil,true)
end

-- ── Station layout helpers ─────────────────────────────────────────────────

local function makeStations(deptIdx, positions)
    local dept = RoomData.LAB_DEPTS[deptIdx]
    local result = {}
    for i, pos in ipairs(positions) do
        table.insert(result, {id="lab_"..dept.name.."_"..i, dx=pos[1], dz=pos[2]})
    end
    return result
end

local function grid5x2(xSpacing, zSpacing)
    local xs={-2,-1,0,1,2}; local zs={-0.5,0.5}; local out={}
    for _,z in ipairs(zs) do for _,x in ipairs(xs) do
        table.insert(out,{x*xSpacing, z*zSpacing})
    end end; return out
end

local function grid2x5(xSpacing, zSpacing)
    local xs={-0.5,0.5}; local zs={-2,-1,0,1,2}; local out={}
    for _,x in ipairs(xs) do for _,z in ipairs(zs) do
        table.insert(out,{x*xSpacing, z*zSpacing})
    end end; return out
end

-- ── Lab floor: T-shaped multi-room layout ─────────────────────────────────
-- Plot-local coords: +Z toward map centre (entrance), -Z deeper into plot
-- lx=0,lz=0 is the plot's world position

local function buildLabFloor(plot, plotCF)
    local bm=Instance.new("Model"); bm.Name="Room_lab_building"; bm.Parent=plot

    -- 1. Lobby / visitor centre
    local function lobbyVP(name,sz,dx,dy,dz,col,mat,nc)
        vp(bm,name,sz,plotCF*CFrame.new(dx,dy,dz),col,mat,nc)
    end
    lobbyVP("LobbyFloor", Vector3.new(30,0.25,28),  0,0.12,-18,"Dark grey",Enum.Material.SmoothPlastic,true)
    lobbyVP("LobbyCeil",  Vector3.new(30,T,28),      0,H-T/2,-18,"Really black",nil,true)
    lobbyVP("LobbyStripN",Vector3.new(28,0.3,28),    0,H-1.2,-18,"Bright violet",Enum.Material.Neon,true)
    -- Lobby sign post
    lobbyVP("SignPost",   Vector3.new(1,8,1),         0,4,-4,"Dark grey",nil,true)
    lobbyVP("SignTop",    Vector3.new(12,3,0.5),       0,8.5,-4,"Bright violet",Enum.Material.Neon,true)
    -- Lobby walls (sides only — front open to entrance, back open to spine)
    lobbyVP("LobbyWL",Vector3.new(T,H,28),-15,H/2,-18,"Really black")
    lobbyVP("LobbyWR",Vector3.new(T,H,28), 15,H/2,-18,"Really black")
    -- Point light
    local llp=Instance.new("Part"); llp.Size=Vector3.new(1,1,1)
    llp.CFrame=plotCF*CFrame.new(0,H-2,-18); llp.Anchored=true; llp.CanCollide=false; llp.Transparency=1; llp.Parent=bm
    local lpl=Instance.new("PointLight",llp); lpl.Brightness=3; lpl.Range=50; lpl.Color=Color3.fromRGB(180,80,255)

    -- 2. Chemistry Lab — back centre (door faces S = toward lobby)
    buildRoom(plot,bm,plotCF, 1, 0,-68, 44,26, "S",
        makeStations(1, grid5x2(8,8)))

    -- 3. Biology Lab — right wing (door faces W = toward lobby)
    buildRoom(plot,bm,plotCF, 2, 60,-22, 26,44, "W",
        makeStations(2, grid2x5(8,8)))

    -- 4. Physics Lab — left wing (door faces E = toward lobby)
    buildRoom(plot,bm,plotCF, 3,-60,-22, 26,44, "E",
        makeStations(3, grid2x5(8,8)))

    -- 5. Electronics Lab — back-left (door faces E = toward spine)
    buildRoom(plot,bm,plotCF, 4,-52,-68, 32,26, "E",
        makeStations(4, grid5x2(6,7)))

    -- 6. Weapons R&D — back-right (door faces W = toward spine)
    buildRoom(plot,bm,plotCF, 5, 52,-68, 32,26, "W",
        makeStations(5, grid5x2(6,7)))

    -- 3. Corridors
    buildCorridor(bm,plotCF,   0,-44, 14,20)   -- N-S spine (lobby→chemistry)
    buildCorridor(bm,plotCF,  37,-22, 24,12)   -- R-wing (lobby→biology)
    buildCorridor(bm,plotCF, -37,-22, 24,12)   -- L-wing (lobby→physics)
    buildCorridor(bm,plotCF, -34,-68, 14,12)   -- Back-L (spine→electronics)
    buildCorridor(bm,plotCF,  34,-68, 14,12)   -- Back-R (spine→weapons)
end

-- ── Upper floors (behind lab, stacked, accessible via staircases) ──────────

local UPPER = {
    {id="armory",         wc="Dark grey",    fc="Dark stone grey",floor=2},
    {id="minion_barracks",wc="Bright orange",fc="Reddish brown",  floor=3},
    {id="war_room",       wc="Really black", fc="Dark grey",      floor=4},
    {id="vault",          wc="Bright yellow",fc="Gold",           floor=5},
    {id="escape_pod_bay", wc="White",        fc="Mid gray",       floor=6},
}

local function buildUpperFloor(plot, plotCF, fd)
    local yBase = H * fd.floor
    local W, D  = 28, 28
    local fIdx  = fd.floor - 1
    local xOff  = (fIdx - 3) * (W + 4)   -- spread 5 floors side-by-side
    local lx, lz = xOff, -(70 + D/2 + 6) -- behind the lab back wall

    local function cf(dx,dy,dz) return plotCF*CFrame.new(lx+dx,yBase+dy,lz+dz) end

    local m=Instance.new("Model"); m.Name="Room_"..fd.id; m.Parent=plot

    hp(m,"Floor",Vector3.new(W,T,D),        cf(0,T/2,0),       fd.fc,nil,true)
    hp(m,"Ceil", Vector3.new(W,T,D),        cf(0,H-T/2,0),     fd.wc,nil,false)
    hp(m,"BkW",  Vector3.new(W,H,T),        cf(0,H/2,D/2-T/2), fd.wc,nil,true)
    hp(m,"LW",   Vector3.new(T,H,D),        cf(-W/2+T/2,H/2,0),fd.wc,nil,true)
    hp(m,"RW",   Vector3.new(T,H,D),        cf( W/2-T/2,H/2,0),fd.wc,nil,true)
    local fw=(W-8)/2
    hp(m,"FrL",  Vector3.new(fw,H,T),       cf(-(W/2-fw/2),H/2,-D/2+T/2),fd.wc,nil,true)
    hp(m,"FrR",  Vector3.new(fw,H,T),       cf( (W/2-fw/2),H/2,-D/2+T/2),fd.wc,nil,true)
    hp(m,"FrTop",Vector3.new(8,4,T),        cf(0,H-2,-D/2+T/2),fd.wc,nil,true)
    hp(m,"Strip",Vector3.new(W-2,0.3,D-2),  cf(0,H-1.5,0),"Bright violet",Enum.Material.Neon,false)

    -- Drop pad at ground level in front of staircase
    local padCF = plotCF*CFrame.new(lx, 0.25, lz-D/2-4)
    local pad=Instance.new("Part"); pad.Name="DropPad_"..fd.id
    pad.Size=Vector3.new(6,0.3,6); pad.CFrame=padCF
    pad.Anchored=true; pad.BrickColor=BrickColor.new("Bright green"); pad.Material=Enum.Material.Neon
    pad.Parent=plot

    -- Visible staircase
    local sm=Instance.new("Model"); sm.Name="Stair_"..fd.id; sm.Parent=plot
    local steps=math.ceil(yBase/1.8)
    for s=1,steps do
        vp(sm,"S"..s,Vector3.new(W-2,0.5,2),
            plotCF*CFrame.new(lx, s*1.8-0.25, lz-D/2-4+s*1.3),
            "Dark grey",Enum.Material.SmoothPlastic)
    end
end

-- ── Plots ──────────────────────────────────────────────────────────────────

local function buildPlots()
    for i=1,NUM_PLOTS do
        local old=workspace:FindFirstChild("Plot_"..i); if old then old:Destroy() end
        local a=(i-1)*(2*math.pi/NUM_PLOTS)
        local cx,cz=math.cos(a)*RADIUS,math.sin(a)*RADIUS

        -- CFrame facing toward map centre
        local plotCF=CFrame.lookAt(Vector3.new(cx,0,cz),Vector3.new(0,0,0))

        local plot=Instance.new("Folder"); plot.Name="Plot_"..i; plot.Parent=workspace
        Instance.new("BoolValue",plot).Name="IsOccupied"; plot.IsOccupied.Value=false
        Instance.new("IntValue",plot).Name="OwnerId";     plot.OwnerId.Value=0

        -- Spawn just in front of lab entrance
        local sp=Instance.new("SpawnLocation"); sp.Name="PlotSpawn"
        sp.Size=Vector3.new(6,1,6); sp.CFrame=plotCF*CFrame.new(0,0.5,12)
        sp.Anchored=true; sp.Neutral=false; sp.AllowTeamChangeOnTouch=false
        sp.Transparency=0.7; sp.BrickColor=BrickColor.new("Bright red"); sp.Material=Enum.Material.Neon
        sp.Parent=plot

        -- Anchors
        for _,dat in ipairs({{"MoveSignAnchor",H*7+5},{"BaseLabelAnchor",H*9},{"PlotLight",H*7}}) do
            local p=Instance.new("Part"); p.Name=dat[1]; p.Size=Vector3.new(1,1,1)
            p.CFrame=plotCF*CFrame.new(0,dat[2],0); p.Anchored=true; p.CanCollide=false; p.Transparency=1
            p.Parent=plot
        end
        local pl=Instance.new("PointLight",plot.PlotLight); pl.Brightness=5; pl.Range=100; pl.Color=Color3.fromRGB(180,0,255)

        buildLabFloor(plot, plotCF)
        for _,fd in ipairs(UPPER) do buildUpperFloor(plot,plotCF,fd) end
    end
end

-- ── Global spawn ───────────────────────────────────────────────────────────

local function buildSpawn()
    local old=workspace:FindFirstChild("VillainSpawn"); if old then old:Destroy() end
    local sp=Instance.new("SpawnLocation"); sp.Name="VillainSpawn"
    sp.Size=Vector3.new(10,1,10); sp.CFrame=CFrame.new(0,0.5,0)
    sp.Anchored=true; sp.BrickColor=BrickColor.new("Bright red"); sp.Material=Enum.Material.Neon
    sp.Parent=workspace
end

-- ── Run ────────────────────────────────────────────────────────────────────

buildLighting(); buildTerrain(); buildSpawn(); buildPlots()
print("[WorldSetup] T-shaped multi-room lab built")
