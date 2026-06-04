-- src/ServerScriptService/WorldSetup.server.luau
local Lighting = game:GetService("Lighting")
local RoomData  = require(game.ReplicatedStorage.RoomData)

local NUM_PLOTS = 6
local RADIUS    = 550   -- spread plots near map edge, ~90 studs from 700-unit floor border
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
    Lighting.ClockTime       = 17      -- golden evening — bright but dramatic
    Lighting.Brightness      = 5       -- much brighter overall
    Lighting.Ambient         = Color3.fromRGB(180,150,220)  -- bright purple daylight
    Lighting.OutdoorAmbient  = Color3.fromRGB(150,120,190)  -- strong fill light outdoors
    Lighting.FogEnd          = 2400    -- reduced fog so map is visible
    Lighting.FogColor        = Color3.fromRGB(80,50,120)

    for _,e in ipairs(Lighting:GetChildren()) do e:Destroy() end

    local a=Instance.new("Atmosphere",Lighting)
    a.Density=0.08; a.Color=Color3.fromRGB(120,80,180); a.Haze=0.8; a.Glare=0.3

    local b=Instance.new("BloomEffect",Lighting)
    b.Intensity=0.5; b.Size=16; b.Threshold=1.5   -- subtle bloom, not overpowering

    local c=Instance.new("ColorCorrectionEffect",Lighting)
    c.Saturation=0.15; c.Brightness=0.05; c.TintColor=Color3.fromRGB(230,210,255)

    -- Sun rays for dramatic castle atmosphere
    local d=Instance.new("SunRaysEffect",Lighting)
    d.Intensity=0.05; d.Spread=0.5
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

    -- Themed station model builder (called once per station)
    local function buildStationModel(sm, deptIdx, sdx, sdz)
        local acol = DEPT_ACCENT[deptIdx]
        local dmat = DEPT_MAT[deptIdx]
        local floorCol = DEPT_FLOOR_COL[deptIdx]

        -- Base platform (all depts share this)
        hp(sm,"Base", Vector3.new(4.5,0.4,4.5), cf(sdx,0.5,sdz), acol, dmat, true)

        if deptIdx == 1 then
            -- Chemistry: glowing beaker + bubbles
            hp(sm,"Tank",  Vector3.new(1.5,4,1.5), cf(sdx,3,sdz),      acol, Enum.Material.Glass, true)
            hp(sm,"Liquid",Vector3.new(1.2,3,1.2), cf(sdx,2.5,sdz),    acol, Enum.Material.Neon, false)
            hp(sm,"Cap",   Vector3.new(1.8,0.4,1.8),cf(sdx,5.2,sdz),   acol, dmat, true)
            hp(sm,"Tube1", Vector3.new(0.3,2,0.3), cf(sdx+0.8,4,sdz-0.5), acol, dmat, true)
            hp(sm,"Tube2", Vector3.new(0.3,1.5,0.3),cf(sdx-0.7,3.5,sdz+0.5),floorCol,dmat,true)
            hp(sm,"Glow",  Vector3.new(0.8,0.3,0.8),cf(sdx,5.6,sdz),   acol, Enum.Material.Neon, false)

        elseif deptIdx == 2 then
            -- Electronics: server rack with blinking lights
            hp(sm,"Rack",  Vector3.new(3.5,5,2),   cf(sdx,3,sdz),      floorCol, Enum.Material.Metal, true)
            hp(sm,"Panel1",Vector3.new(3,0.4,1.5),  cf(sdx,1.8,sdz+0.3),acol, Enum.Material.SmoothPlastic, true)
            hp(sm,"Panel2",Vector3.new(3,0.4,1.5),  cf(sdx,3,sdz+0.3), acol, Enum.Material.SmoothPlastic, true)
            hp(sm,"Panel3",Vector3.new(3,0.4,1.5),  cf(sdx,4.2,sdz+0.3),acol, Enum.Material.SmoothPlastic, true)
            hp(sm,"Light1",Vector3.new(0.3,0.3,0.2),cf(sdx-1.2,1.8,sdz+0.35),acol,Enum.Material.Neon,false)
            hp(sm,"Light2",Vector3.new(0.3,0.3,0.2),cf(sdx-0.6,3,sdz+0.35),  "Bright green",Enum.Material.Neon,false)
            hp(sm,"Light3",Vector3.new(0.3,0.3,0.2),cf(sdx-1.2,4.2,sdz+0.35),acol,Enum.Material.Neon,false)
            hp(sm,"Glow",  Vector3.new(3,0.2,0.2),  cf(sdx,5.5,sdz),   acol, Enum.Material.Neon, false)

        elseif deptIdx == 3 then
            -- Biology: microscope + culture dish
            hp(sm,"Stand", Vector3.new(0.5,4,0.5),  cf(sdx,2.5,sdz-0.3),floorCol,Enum.Material.Metal,true)
            hp(sm,"Arm",   Vector3.new(2,0.4,0.4),  cf(sdx,4.8,sdz-0.3),floorCol,Enum.Material.Metal,true)
            hp(sm,"Lens",  Vector3.new(0.8,1.2,0.8),cf(sdx,3.5,sdz-0.3),acol,Enum.Material.Glass,true)
            hp(sm,"Eye",   Vector3.new(0.6,0.8,0.6),cf(sdx,5.2,sdz-0.3),acol,Enum.Material.Neon,false)
            hp(sm,"Dish",  Vector3.new(2.5,0.3,2.5),cf(sdx,0.95,sdz+0.5),acol,Enum.Material.Glass,true)
            hp(sm,"Sample",Vector3.new(2,0.2,2),     cf(sdx,1.05,sdz+0.5),acol,Enum.Material.Neon,false)
            hp(sm,"Glow",  Vector3.new(0.4,0.4,0.4),cf(sdx,5.8,sdz-0.3),acol,Enum.Material.Neon,false)

        elseif deptIdx == 4 then
            -- Physics: particle ring accelerator
            hp(sm,"Core",  Vector3.new(1.5,1.5,1.5),cf(sdx,3,sdz),     acol, Enum.Material.Neon, false)
            hp(sm,"Ring1", Vector3.new(4,0.3,4),     cf(sdx,3,sdz),     floorCol,Enum.Material.Metal,true)
            hp(sm,"Ring2", Vector3.new(3.2,0.3,3.2), cf(sdx,3.8,sdz),   floorCol,Enum.Material.Metal,true)
            hp(sm,"Ring3", Vector3.new(2.5,0.3,2.5), cf(sdx,4.5,sdz),   floorCol,Enum.Material.Metal,true)
            hp(sm,"Beam1", Vector3.new(0.2,5,0.2),   cf(sdx+1.8,3,sdz), acol,Enum.Material.Neon,false)
            hp(sm,"Beam2", Vector3.new(0.2,5,0.2),   cf(sdx-1.8,3,sdz), acol,Enum.Material.Neon,false)
            hp(sm,"Glow",  Vector3.new(1,1,1),        cf(sdx,3,sdz),     acol, Enum.Material.Neon, false)

        elseif deptIdx == 5 then
            -- Weapons R&D: weapon crate + targeting reticle
            hp(sm,"Crate1",Vector3.new(3,2,2),       cf(sdx,1.5,sdz),   floorCol,Enum.Material.DiamondPlate,true)
            hp(sm,"Crate2",Vector3.new(2,1.5,1.5),   cf(sdx,3.25,sdz-0.5),floorCol,Enum.Material.DiamondPlate,true)
            hp(sm,"Target",Vector3.new(2.5,2.5,0.2), cf(sdx+0.5,4,sdz+0.8),floorCol,Enum.Material.SmoothPlastic,true)
            hp(sm,"Ring",  Vector3.new(2.5,2.5,0.1), cf(sdx+0.5,4,sdz+0.85),acol,Enum.Material.Neon,false)
            hp(sm,"Cross1",Vector3.new(2.5,0.2,0.1), cf(sdx+0.5,4,sdz+0.9), acol,Enum.Material.Neon,false)
            hp(sm,"Cross2",Vector3.new(0.2,2.5,0.1), cf(sdx+0.5,4,sdz+0.9), acol,Enum.Material.Neon,false)
            hp(sm,"Glow",  Vector3.new(0.4,5,0.4),   cf(sdx+0.5,4,sdz+0.8), acol,Enum.Material.Neon,false)
        end
    end

    -- Station pads + hidden models
    for _, st in ipairs(stationList) do
        local sdx, sdz = st.dx, st.dz
        local pad=Instance.new("Part"); pad.Name="DropPad_"..st.id
        pad.Size=Vector3.new(5,0.3,5); pad.CFrame=cf(sdx,0.25,sdz)
        pad.Anchored=true; pad.BrickColor=BrickColor.new(acol); pad.Material=Enum.Material.Neon
        pad.Parent=plot

        local sm=Instance.new("Model"); sm.Name="Room_"..st.id; sm.Parent=plot
        buildStationModel(sm, deptIdx, sdx, sdz)
    end
end

-- ── Corridor builder ───────────────────────────────────────────────────────

local function buildCorridor(model, plotCF, lx, lz, W, D)
    local function cf(dx,dy,dz) return plotCF*CFrame.new(lx+dx,dy,lz+dz) end
    vp(model,"CC_f"..lx..lz,  Vector3.new(W-2,0.25,D-2),cf(0,0.12,0),"Dark grey",Enum.Material.SmoothPlastic,true)
    vp(model,"CC_s"..lx..lz,  Vector3.new(W-2,0.3,D-2),  cf(0,H-1.2,0),"Bright violet",Enum.Material.Neon,true)
    vp(model,"CC_c"..lx..lz,  Vector3.new(W,T,D),         cf(0,H-T/2,0),"Really black",nil,true)
    -- Side walls (enclose the corridor passage)
    if W >= D then
        -- E-W corridor: add N and S walls
        vp(model,"CC_wn"..lx..lz, Vector3.new(W,H,T), cf(0,H/2,-D/2+T/2),"Really black")
        vp(model,"CC_ws"..lx..lz, Vector3.new(W,H,T), cf(0,H/2, D/2-T/2),"Really black")
    else
        -- N-S corridor: add E and W walls
        vp(model,"CC_we"..lx..lz, Vector3.new(T,H,D), cf( W/2-T/2,H/2,0),"Really black")
        vp(model,"CC_ww"..lx..lz, Vector3.new(T,H,D), cf(-W/2+T/2,H/2,0),"Really black")
    end
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
    -- Wallet slot expansion kiosk (right of the lobby sign)
    local kiosk = Instance.new("Part"); kiosk.Name = "SlotKiosk"
    kiosk.Size = Vector3.new(3,4,3); kiosk.Anchored = true; kiosk.CanCollide = true
    kiosk.BrickColor = BrickColor.new("Bright violet")
    kiosk.Material = Enum.Material.SmoothPlastic
    kiosk.CFrame = plotCF * CFrame.new(10, 2, -4)
    kiosk.Parent = plot
    local kioskGlow = Instance.new("Part"); kioskGlow.Name = "SlotKioskGlow"
    kioskGlow.Size = Vector3.new(3.2, 0.3, 3.2); kioskGlow.Anchored = true
    kioskGlow.CanCollide = false
    kioskGlow.BrickColor = BrickColor.new("Bright violet")
    kioskGlow.Material = Enum.Material.Neon
    kioskGlow.CFrame = plotCF * CFrame.new(10, 4.2, -4)
    kioskGlow.Parent = plot
    -- Crafting kiosks — one per department, positioned in the back of each dept room
    local CRAFT_DEPT_DATA = {
        {dept="chemistry",   lx=0,    lz=-68, cx=-14},
        {dept="biology",     lx=60,   lz=-22, cx=-8 },
        {dept="physics",     lx=-60,  lz=-22, cx=8  },
        {dept="electronics", lx=-52,  lz=-68, cx=-10},
        {dept="weapons",     lx=52,   lz=-68, cx=10 },
    }
    local CRAFT_COLORS = {
        chemistry="Bright green", electronics="Bright blue", biology="Cyan",
        physics="Bright violet", weapons="Bright red"
    }
    for _, cd in ipairs(CRAFT_DEPT_DATA) do
        local ck = Instance.new("Part"); ck.Name = "CraftKiosk_" .. cd.dept
        ck.Size = Vector3.new(2,3,2); ck.Anchored = true; ck.CanCollide = true
        ck.BrickColor = BrickColor.new(CRAFT_COLORS[cd.dept] or "Bright violet")
        ck.Material = Enum.Material.Neon
        ck.CFrame = plotCF * CFrame.new(cd.lx + cd.cx, 1.5, cd.lz)
        ck.Parent = plot
    end
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

    -- 3. Corridors (enclosed passages between rooms)
    buildCorridor(bm,plotCF,   0,-44, 14,20)   -- N-S spine (lobby→chemistry)
    buildCorridor(bm,plotCF,  37,-22, 24,12)   -- R-wing (lobby→biology)
    buildCorridor(bm,plotCF, -37,-22, 24,12)   -- L-wing (lobby→physics)
    buildCorridor(bm,plotCF, -34,-68, 14,12)   -- Back-L (spine→electronics)
    buildCorridor(bm,plotCF,  34,-68, 14,12)   -- Back-R (spine→weapons)

    -- 4. Stairwell extension — enclosed hall at the very back of the building
    -- Houses all 5 staircases/drop pads; players reach it through Chemistry back wall
    local SWZ = -94   -- stairwell centre Z (local)
    local SWW = 116   -- same width as lab
    local SWD = 14
    local function swvp(name,sz,dx,dy,dz,col,mat,nc)
        vp(bm,name,sz,plotCF*CFrame.new(dx,dy,SWZ+dz),col,mat,nc)
    end
    swvp("SW_Floor",  Vector3.new(SWW,0.25,SWD),   0,0.12,0,"Dark grey",Enum.Material.SmoothPlastic,true)
    swvp("SW_Ceil",   Vector3.new(SWW,T,SWD),       0,H-T/2,0,"Really black",nil,true)
    swvp("SW_BkWall", Vector3.new(SWW,H,T),         0,H/2,SWD/2-T/2,"Really black")
    swvp("SW_LWall",  Vector3.new(T,H,SWD),        -SWW/2+T/2,H/2,0,"Really black")
    swvp("SW_RWall",  Vector3.new(T,H,SWD),         SWW/2-T/2,H/2,0,"Really black")
    swvp("SW_Strip",  Vector3.new(SWW-2,0.3,SWD-2), 0,H-1.2,0,"Bright violet",Enum.Material.Neon,true)
    -- Connection passage from Chemistry's back wall → stairwell (gap in Chemistry N-wall handled by room's solid-N wall; add a short link corridor)
    buildCorridor(bm,plotCF, 0,-86, 12,10)   -- chemistry → stairwell link
end

-- ── Castle tower upper floors ─────────────────────────────────────────────
-- Each floor matches the lab footprint exactly (W=116, D=94) and stacks above it.
-- lz=-47 centres the floors over the lab (lab spans Z=0 to Z=-94, centre=-47).
-- The back wall is at lz-D/2 = -94 = STAIR_Z, so staircases emerge through a
-- door gap directly into the back of each floor.
-- All parts use hp() — invisible/non-collidable until the floor is purchased.

local STAIR_X = {-44, -22, 0, 22, 44}   -- X positions of the 5 staircases
local STAIR_Z = -94                       -- back of building = stairwell Z
local FLR_LZ  = -47                       -- floor centre Z (= lab centre)
local FLR_W   = 116                       -- matches lab width
local FLR_D   = 94                        -- matches lab depth
local STONE    = Enum.Material.SmoothPlastic
local NEON     = Enum.Material.Neon

local CASTLE_FLOORS = {
    { id="armory",         floor=2, wc="Dark stone grey", fc="Really black",   light="Bright orange"  },
    { id="minion_barracks",floor=3, wc="Reddish brown",   fc="Reddish brown",  light="Bright yellow"  },
    { id="war_room",       floor=4, wc="Really black",    fc="Dark grey",      light="Bright violet"  },
    { id="vault",          floor=5, wc="Dark grey",       fc="Gold",           light="Bright yellow"  },
    { id="escape_pod_bay", floor=6, wc="Medium stone grey",fc="Light grey",    light="Cyan"           },
}

local function buildUpperFloor(plot, plotCF, fd)
    local fIdx   = fd.floor - 1
    local yBase  = H * (fd.floor - 1)   -- 14, 28, 42, 56, 70
    local W, D   = FLR_W, FLR_D         -- 116 × 94 — same as lab
    local lx, lz = 0, FLR_LZ            -- centred above lab
    local stairX = STAIR_X[fIdx]        -- staircase X per floor

    local function cf(dx,dy,dz) return plotCF*CFrame.new(lx+dx,yBase+dy,lz+dz) end

    local m = Instance.new("Model"); m.Name="Room_"..fd.id; m.Parent=plot

    -- ── Structure ─────────────────────────────────────────────────────────
    hp(m,"Floor", Vector3.new(W,T,D),   cf(0,T/2,0),           fd.fc, STONE, true)

    -- Front wall with wide entrance (30 wide, faces toward map centre)
    local fw=(W-30)/2
    hp(m,"FrL",  Vector3.new(fw,H,T),   cf(-(W/2-fw/2),H/2,-D/2+T/2), fd.wc,STONE,true)
    hp(m,"FrR",  Vector3.new(fw,H,T),   cf( (W/2-fw/2),H/2,-D/2+T/2), fd.wc,STONE,true)
    hp(m,"FrTop",Vector3.new(30,4,T),   cf(0,H-2,-D/2+T/2),            fd.wc,STONE,true)

    -- Back wall with STAIRCASE DOOR GAPS (one per stairX, 8 wide)
    -- Left and right sections around the 5 staircase openings
    local gapW = 10
    local prevX = -W/2
    local stairPositions = {-44,-22,0,22,44}
    table.sort(stairPositions)
    for _, sx in ipairs(stairPositions) do
        local segW = (sx - gapW/2) - prevX
        if segW > 0.5 then
            hp(m,"BkSeg"..sx, Vector3.new(segW,H,T), cf(prevX+segW/2,H/2,D/2-T/2), fd.wc,STONE,true)
        end
        prevX = sx + gapW/2
    end
    local lastSeg = W/2 - prevX
    if lastSeg > 0.5 then
        hp(m,"BkSegLast",Vector3.new(lastSeg,H,T), cf(prevX+lastSeg/2,H/2,D/2-T/2), fd.wc,STONE,true)
    end
    -- Top strip above staircase gaps
    hp(m,"BkTop",Vector3.new(W,4,T), cf(0,H-2,D/2-T/2), fd.wc,STONE,true)

    -- Side walls (solid)
    hp(m,"LW",  Vector3.new(T,H,D), cf(-W/2+T/2,H/2,0), fd.wc,STONE,true)
    hp(m,"RW",  Vector3.new(T,H,D), cf( W/2-T/2,H/2,0), fd.wc,STONE,true)

    -- Ceiling light strip
    hp(m,"CeilLight",Vector3.new(W-2,0.3,D-2), cf(0,H-0.8,0), fd.light,NEON,false)

    -- ── Battlements (10 on front/back, 8 on sides) ────────────────────────
    local mW,mH,mT = 4,3,T+0.5
    for k=0,9 do
        local bx=(k-4.5)*(W/10)
        hp(m,"MFr"..k,Vector3.new(mW,mH,mT),cf(bx,H+mH/2,-D/2),fd.wc,STONE,true)
        hp(m,"MBk"..k,Vector3.new(mW,mH,mT),cf(bx,H+mH/2, D/2),fd.wc,STONE,true)
    end
    for k=0,7 do
        local bz=(k-3.5)*(D/8)
        hp(m,"MLf"..k,Vector3.new(mT,mH,mW),cf(-W/2,H+mH/2,bz),fd.wc,STONE,true)
        hp(m,"MRt"..k,Vector3.new(mT,mH,mW),cf( W/2,H+mH/2,bz),fd.wc,STONE,true)
    end
    -- Corner towers
    for _,cx in ipairs({-W/2,W/2}) do for _,cz in ipairs({-D/2,D/2}) do
        hp(m,"Twr"..cx..cz,Vector3.new(6,H+10,6),cf(cx,H/2+5,cz),fd.wc,STONE,true)
    end end

    -- Wall torch sconces (every 18 studs on the long side walls)
    local torchCol = "Bright orange"
    for _,sx2 in ipairs({-50,-32,-14,0,14,32,50}) do
        hp(m,"TW"..sx2,  Vector3.new(0.5,2,0.5),  cf(sx2,7,-D/2+2), "Dark grey",STONE,true)
        hp(m,"TF"..sx2,  Vector3.new(0.9,1.2,0.9),cf(sx2,8.5,-D/2+2),torchCol,NEON,false)
        hp(m,"TW2"..sx2, Vector3.new(0.5,2,0.5),  cf(sx2,7, D/2-2), "Dark grey",STONE,true)
        hp(m,"TF2"..sx2, Vector3.new(0.9,1.2,0.9),cf(sx2,8.5,D/2-2), torchCol,NEON,false)
    end

    -- ── Distinct themed interior per floor ────────────────────────────────

    if fd.id == "armory" then
        -- ═══ THE DUNGEON ═══
        -- Damp dark dungeon. Iron bars, chains, weapon racks, torture device, moat.
        -- Moat / water trench across the centre
        hp(m,"Moat",    Vector3.new(W-4,0.4,6),     cf(0,1.3,0),          "Really blue",STONE,true)
        hp(m,"MoatWater",Vector3.new(W-5,0.2,5),    cf(0,1.4,0),          "Bright blue",NEON,false)
        -- Drawbridge over moat
        hp(m,"Bridge",  Vector3.new(8,0.5,6),        cf(0,1.75,0),         "Reddish brown",nil,true)
        -- Multiple weapon rack columns across width
        for _,rx in ipairs({-45,-25,-5,15,35}) do
            hp(m,"Rack"..rx,    Vector3.new(T,9,7),   cf(rx,5.5,-D/2+2),  "Dark grey",Enum.Material.Metal,true)
            for i=-2,2 do
                hp(m,"WRSword"..rx..i,Vector3.new(0.4,6,0.4),cf(rx,6,i*2-D/2+2),"Medium stone grey",nil,false)
            end
        end
        -- Iron bar cells (3 cells across the back)
        for cell=0,2 do
            local cx4=(cell-1)*30
            for bar=0,5 do
                hp(m,"Cell"..cell.."Bar"..bar,Vector3.new(0.4,H-2,T),cf(cx4+bar*2-4,H/2,D/2-2),"Dark grey",STONE,true)
            end
            hp(m,"CellTop"..cell,Vector3.new(12,T,T),cf(cx4,H-T/2,D/2-2),"Dark grey",STONE,true)
        end
        -- Chains hanging from ceiling
        for _,cx5 in ipairs({-40,-20,0,20,40}) do
            hp(m,"Chain"..cx5,Vector3.new(0.4,8,0.4),cf(cx5,8,-10),"Dark grey",nil,false)
        end
        -- Torture rack in corner
        hp(m,"RackBase",Vector3.new(5,0.5,3),cf(-50,1.75,20),"Dark stone grey",STONE,true)
        hp(m,"RackFrame",Vector3.new(5,5,0.5),cf(-50,4,20),  "Reddish brown",nil,true)
        -- Floor: black stone tiles
        hp(m,"DungeonFloor",Vector3.new(W-2,0.2,D-2),cf(0,0.9,0),"Really black",STONE,true)

    elseif fd.id == "minion_barracks" then
        -- ═══ THE GREAT HALL (Feasting Hall) ═══
        -- Warm communal feast hall. Long tables, fireplace, trophy wall, barrel storage.
        -- Warm wooden floor overlay
        hp(m,"WoodFloor",Vector3.new(W-2,0.2,D-2),cf(0,0.9,0),"Reddish brown",Enum.Material.Wood,true)
        -- Grand fireplace at back centre
        hp(m,"FireMant",  Vector3.new(14,10,T),     cf(0,6,D/2-1.5),  "Dark stone grey",STONE,true)
        hp(m,"FireArch",  Vector3.new(10,6,T+0.2),  cf(0,4,D/2-1.3),  "Really black",STONE,true)
        hp(m,"FireFlame", Vector3.new(7,4,0.5),     cf(0,3.5,D/2-1.2),"Bright orange",NEON,false)
        hp(m,"FireBase",  Vector3.new(12,1,3),       cf(0,1.5,D/2-2),  "Dark stone grey",STONE,true)
        -- Long feast tables (4 rows)
        for t=0,3 do
            local tz=(t-1.5)*16
            hp(m,"Table"..t,  Vector3.new(60,1,5),  cf(0,3,tz),       "Reddish brown",Enum.Material.Wood,true)
            hp(m,"Bench"..t.."A",Vector3.new(58,0.5,2),cf(0,2,tz-3.5),"Dark grey",Enum.Material.Wood,true)
            hp(m,"Bench"..t.."B",Vector3.new(58,0.5,2),cf(0,2,tz+3.5),"Dark grey",Enum.Material.Wood,true)
        end
        -- Trophy heads / mounted shields on walls
        for _,tx2 in ipairs({-50,-30,-10,10,30,50}) do
            hp(m,"Shield"..tx2,Vector3.new(3,3.5,0.4),cf(tx2,9,-D/2+1),"Dark grey",nil,false)
            hp(m,"ShieldGlow"..tx2,Vector3.new(2,2,0.2),cf(tx2,9,-D/2+1.1),"Bright red",NEON,false)
        end
        -- Mead barrels along the sides
        for b=0,4 do
            local bz2=(b-2)*14
            hp(m,"BarrelL"..b,Vector3.new(3,4,3),cf(-55,3,bz2),"Reddish brown",nil,true)
            hp(m,"BarrelR"..b,Vector3.new(3,4,3),cf( 55,3,bz2),"Reddish brown",nil,true)
        end
        -- Chandeliers (3 across the hall)
        for _,cx6 in ipairs({-30,0,30}) do
            hp(m,"Chan"..cx6,    Vector3.new(8,0.5,8),   cf(cx6,H-2,0),   "Bright yellow",NEON,false)
            hp(m,"ChanChain"..cx6,Vector3.new(0.4,4,0.4),cf(cx6,H-5.5,0),"Dark grey",nil,false)
        end
        -- Overriding torch color for warmth
        torchCol = "Bright yellow"

    elseif fd.id == "war_room" then
        -- ═══ THE THRONE ROOM ═══
        -- Grand royal chamber. Columns, throne, red carpet, war table, royal banners.
        -- Marble floor overlay
        hp(m,"MarbleFloor",Vector3.new(W-2,0.2,D-2),cf(0,0.9,0),"White",Enum.Material.Marble,true)
        -- Red carpet runner
        hp(m,"Carpet",     Vector3.new(6,0.2,D-4),   cf(0,1.1,0),        "Bright red",nil,false)
        -- Grand throne at back (centre)
        hp(m,"Dais",       Vector3.new(16,1.5,10),    cf(0,1.75,D/2-7),   "Dark stone grey",STONE,true)
        hp(m,"ThroneBase", Vector3.new(7,5,4),        cf(0,5.5,D/2-8),    "Really black",STONE,true)
        hp(m,"ThroneBack", Vector3.new(7,7,0.8),      cf(0,8.5,D/2-9.8),  "Really black",STONE,true)
        hp(m,"ThroneCrown",Vector3.new(8,2,0.8),      cf(0,13,D/2-9.8),   "Bright yellow",NEON,false)
        hp(m,"ThroneGlow", Vector3.new(5,1,3),        cf(0,3.5,D/2-8),    "Bright violet",NEON,false)
        -- 8 stone columns (4 per side) running down the hall
        for _,cx7 in ipairs({-46,-30,-14,14,30,46}) do
            hp(m,"Col"..cx7, Vector3.new(3,H,3),   cf(cx7,H/2,0),   "Medium stone grey",STONE,true)
            hp(m,"ColCap"..cx7,Vector3.new(4,1.5,4),cf(cx7,H+0.5,0),"Dark stone grey",STONE,true)
            hp(m,"ColBase"..cx7,Vector3.new(4,1,4), cf(cx7,0.5,0),  "Dark stone grey",STONE,true)
        end
        -- War strategy table
        hp(m,"WarTable",   Vector3.new(20,1,10),      cf(0,3.5,-15),      "Reddish brown",Enum.Material.Wood,true)
        hp(m,"MapSurface", Vector3.new(19,0.3,9),     cf(0,4.2,-15),      "Dark grey",nil,false)
        -- Royal banners (every 20 studs along sides)
        for _,bx3 in ipairs({-48,-28,-8,8,28,48}) do
            hp(m,"BanL"..bx3,Vector3.new(0.4,9,4),cf(bx3,8,0),"Bright red",nil,false)
            hp(m,"BanSymL"..bx3,Vector3.new(0.3,4,2),cf(bx3,8,0),"Bright yellow",NEON,false)
        end
        -- Chandelier array
        for _,cx8 in ipairs({-35,0,35}) do
            hp(m,"RChan"..cx8,     Vector3.new(10,0.6,10), cf(cx8,H-1.5,0),"Bright yellow",NEON,false)
            hp(m,"RChanChain"..cx8,Vector3.new(0.5,5,0.5), cf(cx8,H-5,0),  "Dark grey",nil,false)
        end
        torchCol = "Bright violet"

    elseif fd.id == "vault" then
        -- ═══ THE TREASURY ═══
        -- Glittering treasure vault. Gold everywhere, chests, portcullis, coin mountains.
        -- Gold tile floor
        hp(m,"GoldFloor",Vector3.new(W-2,0.2,D-2), cf(0,0.9,0),"Bright yellow",STONE,true)
        -- Gold bar walls (stacks lining the sides)
        for row=0,5 do
            for _,sx3 in ipairs({-54,-50,-46,46,50,54}) do
                hp(m,"GBar"..row..sx3,Vector3.new(3,1,4),cf(sx3,1.5+row*1.1,0),"Bright yellow",nil,true)
            end
        end
        -- Central coin mountain
        for ring=0,4 do
            hp(m,"Coins"..ring,Vector3.new(20-ring*4,ring*0.8+1,20-ring*4),cf(0,ring*0.9+1,10),"Bright yellow",nil,true)
        end
        -- Treasure chests scattered across floor
        for k=0,7 do
            local cx9=(k-3.5)*13
            hp(m,"Chest"..k,    Vector3.new(4,2.5,3),   cf(cx9,2.25,-15),  "Reddish brown",nil,true)
            hp(m,"ChestLid"..k, Vector3.new(4,1.5,3),   cf(cx9,3.75,-15),  "Dark orange",nil,true)
            hp(m,"ChestGlow"..k,Vector3.new(3,0.5,2),   cf(cx9,2.6,-15),   "Bright yellow",NEON,false)
        end
        -- Portcullis gate at entrance area
        local gateW = 30
        hp(m,"Gate",    Vector3.new(gateW,H,T),          cf(0,H/2,-D/2+4),  "Dark grey",STONE,true)
        for k=0,9 do
            hp(m,"GBar"..k,Vector3.new(0.5,H,T*0.5),    cf((k-4.5)*3,H/2,-D/2+4.2),"Really black",STONE,true)
        end
        hp(m,"GBarH1",  Vector3.new(gateW,0.6,T*0.5),   cf(0,4,-D/2+4.2),  "Really black",nil,true)
        hp(m,"GBarH2",  Vector3.new(gateW,0.6,T*0.5),   cf(0,8,-D/2+4.2),  "Really black",nil,true)
        -- Giant vault door at back
        hp(m,"VaultDoor",Vector3.new(16,12,T),           cf(0,7,D/2-1.5),   "Dark grey",Enum.Material.Metal,true)
        hp(m,"VaultRing",Vector3.new(12,12,0.5),         cf(0,7,D/2-1.2),   "Medium stone grey",nil,false)
        hp(m,"VaultSpoke1",Vector3.new(10,0.8,0.4),      cf(0,7,D/2-1),     "Dark grey",nil,false)
        hp(m,"VaultSpoke2",Vector3.new(0.8,10,0.4),      cf(0,7,D/2-1),     "Dark grey",nil,false)
        hp(m,"VaultHandle",Vector3.new(1,5,1),           cf(5,7,D/2-0.8),   "Gold",NEON,false)
        -- Golden chandelier
        hp(m,"GChan",   Vector3.new(12,0.6,12),          cf(0,H-1.5,0),     "Bright yellow",NEON,false)
        torchCol = "Bright yellow"

    elseif fd.id == "escape_pod_bay" then
        -- ═══ THE PARAPETS (Open-air castle top) ═══
        -- Exposed battlements, trebuchet, signal fires, crow's nest, flagpoles.
        -- Stone walkway floor
        hp(m,"WalkFloor",Vector3.new(W-2,0.2,D-2),cf(0,0.9,0),"Medium stone grey",STONE,true)
        -- Central crow's nest tower
        hp(m,"CrowsNest",   Vector3.new(8,8,8),    cf(0,5,0),           "Dark stone grey",STONE,true)
        hp(m,"CrowsTop",    Vector3.new(10,1,10),   cf(0,9.5,0),         "Dark stone grey",STONE,true)
        hp(m,"CrowsFlag",   Vector3.new(0.6,10,0.6),cf(0,15,0),         "Dark grey",STONE,true)
        hp(m,"CrowsFlagBan",Vector3.new(6,3,0.3),   cf(3,17.5,0),        "Bright red",nil,false)
        -- Trebuchet (left side)
        hp(m,"TBase",  Vector3.new(8,1.5,6),        cf(-40,1.75,-20),    "Dark stone grey",STONE,true)
        hp(m,"TPost1", Vector3.new(0.8,8,0.8),      cf(-43,6,-20),       "Reddish brown",nil,true)
        hp(m,"TPost2", Vector3.new(0.8,8,0.8),      cf(-37,6,-20),       "Reddish brown",nil,true)
        hp(m,"TArm",   Vector3.new(0.8,14,0.8),     cf(-40,10,-19),      "Reddish brown",nil,true)
        hp(m,"TCounter",Vector3.new(4,4,4),         cf(-40,13.5,-17),    "Dark stone grey",STONE,true)
        hp(m,"TSling", Vector3.new(3,0.4,3),        cf(-40,4.5,-22),     "Dark grey",nil,true)
        hp(m,"TWheel", Vector3.new(5,5,0.6),        cf(-40,5,-20),       "Dark stone grey",STONE,true)
        -- Signal fire pyre (right side)
        hp(m,"FireBase1",Vector3.new(5,1,5),        cf(40,1.5,20),       "Dark stone grey",STONE,true)
        hp(m,"FireLog1", Vector3.new(4,0.8,1),      cf(40,2.4,21),       "Reddish brown",nil,true)
        hp(m,"FireLog2", Vector3.new(1,0.8,4),      cf(41,2.4,20),       "Reddish brown",nil,true)
        hp(m,"FireFlame1",Vector3.new(3,5,3),       cf(40,5,20),         "Bright orange",NEON,false)
        hp(m,"FireFlame2",Vector3.new(2,3,2),       cf(40,7.5,20),       "Bright yellow",NEON,false)
        -- Second signal fire (left)
        hp(m,"FireBase2",Vector3.new(5,1,5),        cf(-40,1.5,20),      "Dark stone grey",STONE,true)
        hp(m,"Fire2",    Vector3.new(3,5,3),        cf(-40,5,20),        "Bright orange",NEON,false)
        -- Flag poles across the parapets
        for _,fpx in ipairs({-50,-25,25,50}) do
            hp(m,"FlagPole"..fpx,Vector3.new(0.6,12,0.6),cf(fpx,7,-D/2+1),"Dark grey",STONE,true)
            hp(m,"Flag"..fpx,    Vector3.new(5,3,0.3),   cf(fpx+2.5,11,-D/2+1),"Bright red",nil,false)
        end
        -- Arrow loops in side walls
        for _,ax2 in ipairs({-45,-25,-5,15,35,55}) do
            hp(m,"ArrL"..ax2,Vector3.new(T,5,2),cf(-W/2,6,ax2-D/2),"Really black",nil,false)
            hp(m,"ArrR"..ax2,Vector3.new(T,5,2),cf( W/2,6,ax2-D/2),"Really black",nil,false)
        end
        -- Sky light from open top
        hp(m,"SkyGlow",Vector3.new(W-4,0.3,D-4),cf(0,H-0.5,0),"Cyan",NEON,false)
        torchCol = "Cyan"
    end

    -- Re-apply torch color for whichever theme was selected
    for _,sx2 in ipairs({-50,-32,-14,0,14,32,50}) do
        local tf1 = m:FindFirstChild("TF"..sx2); if tf1 then tf1.BrickColor=BrickColor.new(torchCol) end
        local tf2 = m:FindFirstChild("TF2"..sx2); if tf2 then tf2.BrickColor=BrickColor.new(torchCol) end
    end

    -- ── Drop pad + staircase ──────────────────────────────────────────────
    local pad = Instance.new("Part"); pad.Name="DropPad_"..fd.id
    pad.Size=Vector3.new(6,0.3,6)
    pad.CFrame=plotCF*CFrame.new(stairX,0.25,STAIR_Z)
    pad.Anchored=true; pad.BrickColor=BrickColor.new("Bright green"); pad.Material=NEON
    pad.Parent=plot

    -- Staircase: goes from Y=0 up through the stairwell, enters floor through back wall gap
    local sm = Instance.new("Model"); sm.Name="Stair_"..fd.id; sm.Parent=plot
    local totalSteps = math.ceil((yBase+H*0.7)/1.6)
    for s=1,totalSteps do
        hp(sm,"S"..s, Vector3.new(4,0.5,1.8),
            plotCF*CFrame.new(stairX, s*1.6-0.8, STAIR_Z+s*0.8),
            "Dark stone grey",STONE,true)
    end
    -- Landing platform inside the floor room
    hp(sm,"Land",Vector3.new(8,0.5,6),
        plotCF*CFrame.new(stairX,yBase+T/2+0.2,D/2-4+FLR_LZ),
        "Dark stone grey",STONE,true)
end

local UPPER = CASTLE_FLOORS

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

    -- Dual leaderboard board at map centre (facing +Z by default)
    local board = Instance.new("Part"); board.Name="LeaderboardBoard"
    board.Size=Vector3.new(14,7,0.5); board.Position=Vector3.new(0,4.5,-8)
    board.Anchored=true; board.CanCollide=true
    board.BrickColor=BrickColor.new("Really black")
    board.Material=Enum.Material.SmoothPlastic; board.Parent=workspace

    local boardGlow = Instance.new("Part"); boardGlow.Name="BoardGlow"
    boardGlow.Size=Vector3.new(13.5,6.5,0.2); boardGlow.Position=Vector3.new(0,4.5,-7.7)
    boardGlow.Anchored=true; boardGlow.CanCollide=false
    boardGlow.BrickColor=BrickColor.new("Bright violet")
    boardGlow.Material=Enum.Material.Neon; boardGlow.Parent=workspace

    local boardFrame = Instance.new("Part"); boardFrame.Name="BoardFrame"
    boardFrame.Size=Vector3.new(15,8,0.4); boardFrame.Position=Vector3.new(0,4.5,-8.3)
    boardFrame.Anchored=true; boardFrame.CanCollide=false
    boardFrame.BrickColor=BrickColor.new("Dark grey")
    boardFrame.Material=Enum.Material.SmoothPlastic; boardFrame.Parent=workspace
end

-- ── Run ────────────────────────────────────────────────────────────────────

buildLighting(); buildTerrain(); buildSpawn(); buildPlots()
print("[WorldSetup] T-shaped multi-room lab built")
