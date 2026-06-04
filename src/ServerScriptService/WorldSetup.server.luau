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
-- Each floor is a castle room stacked above the lab.
-- All parts use hp() — invisible until the floor is purchased.

local STAIR_X = {-44, -22, 0, 22, 44}
local STAIR_Z = -94
local STONE    = Enum.Material.SmoothPlastic  -- use Concrete or SmoothPlastic for stone feel
local NEON     = Enum.Material.Neon

-- Shared castle config per floor
local CASTLE_FLOORS = {
    { id="armory",         name="The Dungeon",      wc="Dark stone grey", fc="Dark stone grey", light="Bright orange",   floor=2 },
    { id="minion_barracks",name="Castle Barracks",  wc="Dark stone grey", fc="Reddish brown",   light="Bright orange",   floor=3 },
    { id="war_room",       name="Throne Room",      wc="Really black",    fc="Dark grey",        light="Bright yellow",   floor=4 },
    { id="vault",          name="The Treasury",     wc="Dark grey",       fc="Gold",             light="Bright yellow",   floor=5 },
    { id="escape_pod_bay", name="Castle Battlements",wc="Medium stone grey",fc="Light grey",     light="Cyan",            floor=6 },
}

local function buildUpperFloor(plot, plotCF, fd)
    local fIdx  = fd.floor - 1
    local yBase = H * (fd.floor - 1)   -- 14, 28, 42, 56, 70
    local W, D  = 22, 22
    local lx    = STAIR_X[fIdx]
    local lz    = STAIR_Z

    local function cf(dx,dy,dz) return plotCF*CFrame.new(lx+dx,yBase+dy,lz+dz) end

    local m = Instance.new("Model"); m.Name="Room_"..fd.id; m.Parent=plot

    -- ── Stone walls + floor ────────────────────────────────────────────────
    hp(m,"Floor",  Vector3.new(W,T,D),       cf(0,T/2,0),          fd.fc,  STONE, true)
    hp(m,"BkW",    Vector3.new(W,H,T),       cf(0,H/2, D/2-T/2),   fd.wc,  STONE, true)
    hp(m,"FrW",    Vector3.new(W,H,T),       cf(0,H/2,-D/2+T/2),   fd.wc,  STONE, true)
    hp(m,"LW",     Vector3.new(T,H,D),       cf(-W/2+T/2,H/2,0),   fd.wc,  STONE, true)
    hp(m,"RW",     Vector3.new(T,H,D),       cf( W/2-T/2,H/2,0),   fd.wc,  STONE, true)

    -- Stone texture strips on walls (give carved block look)
    for i=0,2 do
        hp(m,"HSB"..i, Vector3.new(W-2,0.3,T*0.5),  cf(0,3+i*3.5, D/2-0.4),    fd.wc, STONE, false)
        hp(m,"HSF"..i, Vector3.new(W-2,0.3,T*0.5),  cf(0,3+i*3.5,-D/2+0.4),    fd.wc, STONE, false)
    end

    -- ── Battlements (crenellations) on top of each wall ───────────────────
    local merlonW, merlonH = 3, 3
    local merlonT = T + 0.5
    -- Front and back walls: 4 merlons each
    for k=0,3 do
        local bx = (k-1.5) * (W/4)
        hp(m,"MFr"..k, Vector3.new(merlonW,merlonH,merlonT), cf(bx,H+merlonH/2,-D/2),  fd.wc,STONE,true)
        hp(m,"MBk"..k, Vector3.new(merlonW,merlonH,merlonT), cf(bx,H+merlonH/2, D/2),  fd.wc,STONE,true)
    end
    -- Left and right walls: 4 merlons each
    for k=0,3 do
        local bz = (k-1.5) * (D/4)
        hp(m,"MLf"..k, Vector3.new(merlonT,merlonH,merlonW), cf(-W/2,H+merlonH/2,bz), fd.wc,STONE,true)
        hp(m,"MRt"..k, Vector3.new(merlonT,merlonH,merlonW), cf( W/2,H+merlonH/2,bz), fd.wc,STONE,true)
    end
    -- Corner towers (taller pillars at each corner for castle silhouette)
    for _,cx in ipairs({-W/2, W/2}) do for _,cz in ipairs({-D/2, D/2}) do
        hp(m,"Tower", Vector3.new(3,H+6,3), cf(cx,H/2+3,cz), fd.wc, STONE, true)
    end end

    -- Torch sconces (neon orange on walls)
    for _,sx in ipairs({-W/2+2, W/2-2}) do
        hp(m,"Torch"..sx, Vector3.new(0.5,2,0.5), cf(sx,7,0),   "Dark grey",STONE,true)
        hp(m,"TFlame"..sx,Vector3.new(0.8,1,0.8), cf(sx,8.3,0), "Bright orange",NEON,false)
    end

    -- Ambient neon strip on ceiling underside
    hp(m,"Ceil", Vector3.new(W-2,0.3,D-2), cf(0,H-1,0), fd.light, NEON, false)

    -- ── Castle-themed room interiors ───────────────────────────────────────
    if fd.id == "armory" then
        -- The Dungeon: iron bars, weapon racks, chains, skull
        hp(m,"IronGate",  Vector3.new(W-4,8,T),      cf(0,5,-D/2+2),       "Dark grey",STONE,true)
        for k=-2,2 do
            hp(m,"Bar"..k, Vector3.new(0.4,8,T*0.5), cf(k*3,5,-D/2+2.2),  "Really black",STONE,true)
        end
        hp(m,"WeapRack",  Vector3.new(T,7,8),         cf(-W/2+1.5,4.5,0),  "Dark grey",Enum.Material.Metal,true)
        hp(m,"WeapRack2", Vector3.new(T,7,8),         cf( W/2-1.5,4.5,0),  "Dark grey",Enum.Material.Metal,true)
        for _,wz in ipairs({-3,0,3}) do
            hp(m,"Sword"..wz,Vector3.new(0.3,5,0.3), cf(-W/2+1.5,5.5,wz), "Medium stone grey",nil,false)
        end
        hp(m,"Chain1",    Vector3.new(0.3,6,0.3),     cf(-4,8,4),           "Dark grey",nil,false)
        hp(m,"Chain2",    Vector3.new(0.3,4,0.3),     cf( 4,7,4),           "Dark grey",nil,false)
        hp(m,"Crate1",    Vector3.new(4,3,4),          cf(4,2.5,-3),         "Dark stone grey",STONE,true)
        hp(m,"Crate2",    Vector3.new(3,3,3),          cf(4,5,0),            "Dark stone grey",STONE,true)
        hp(m,"Floor2",    Vector3.new(W-2,0.2,D-2),   cf(0,0.9,0),          "Really black",STONE,true)

    elseif fd.id == "minion_barracks" then
        -- Castle Barracks: stone bunk beds, armour stands, banner, captain platform
        for b=0,1 do
            local bz = b==0 and 5 or -5
            hp(m,"BedFrame"..b,Vector3.new(6,0.5,3),   cf(-5,2,bz),         "Dark stone grey",STONE,true)
            hp(m,"BedTop"..b,  Vector3.new(6,0.5,3),   cf(-5,5.5,bz),       "Dark stone grey",STONE,true)
            hp(m,"BedPost"..b.."1",Vector3.new(0.5,5.5,0.5),cf(-7.5,3.25,bz-1.2),"Dark stone grey",STONE,true)
            hp(m,"BedPost"..b.."2",Vector3.new(0.5,5.5,0.5),cf(-2.5,3.25,bz-1.2),"Dark stone grey",STONE,true)
            hp(m,"Mattress"..b,Vector3.new(5.5,0.4,2.5),cf(-5,2.4,bz),      "Reddish brown",nil,false)
        end
        -- Captain's raised platform + throne
        hp(m,"Platform",  Vector3.new(7,0.8,5),        cf(5,1.8,0),          "Dark stone grey",STONE,true)
        hp(m,"Throne",    Vector3.new(2.5,4,2),         cf(5,4,0),            "Really black",STONE,true)
        hp(m,"ThroneBack",Vector3.new(2.5,3,0.5),       cf(5,5.5,-0.8),       "Really black",STONE,true)
        -- Banner on back wall
        hp(m,"Banner",    Vector3.new(4,7,0.3),          cf(0,7,D/2-1.5),     "Bright red",nil,false)
        hp(m,"BannerSymb",Vector3.new(2,3,0.2),          cf(0,8,D/2-1.3),     "Bright yellow",nil,false)
        hp(m,"Locker1",   Vector3.new(2,5,1.5),          cf(-8,3.5,7),         "Dark stone grey",STONE,true)
        hp(m,"Locker2",   Vector3.new(2,5,1.5),          cf(-8,3.5,4),         "Dark stone grey",STONE,true)

    elseif fd.id == "war_room" then
        -- Throne Room: grand throne, columns, red carpet, chandelier, banners
        -- Red carpet
        hp(m,"Carpet",    Vector3.new(4,0.2,D-2),       cf(0,1.1,0),          "Bright red",nil,false)
        -- Throne on raised dais
        hp(m,"Dais",      Vector3.new(8,1.2,6),          cf(0,1.6,D/2-5),      "Dark stone grey",STONE,true)
        hp(m,"ThroneBase",Vector3.new(4,4,3),            cf(0,4.6,D/2-5),      "Really black",STONE,true)
        hp(m,"ThroneBack",Vector3.new(4,5,0.6),          cf(0,7.1,D/2-6.1),    "Really black",STONE,true)
        hp(m,"ThroneCrown",Vector3.new(5,1.5,0.6),       cf(0,10.4,D/2-6.1),   "Bright yellow",NEON,false)
        -- Four stone columns
        for _,cx2 in ipairs({-7,7}) do for _,cz2 in ipairs({-5,5}) do
            hp(m,"Col",   Vector3.new(2,H,2), cf(cx2,H/2,cz2), "Medium stone grey",STONE,true)
            hp(m,"ColCap",Vector3.new(3,1,3), cf(cx2,H+0.5,cz2),"Dark stone grey",STONE,true)
        end end
        -- War table (strategy map)
        hp(m,"WarTable",  Vector3.new(9,0.8,6),          cf(0,3,-4),           "Reddish brown",nil,true)
        hp(m,"MapTop",    Vector3.new(8.5,0.2,5.5),      cf(0,3.5,-4),         "Dark grey",nil,false)
        -- Chandelier
        hp(m,"Chandelier",Vector3.new(5,0.5,5),          cf(0,H-2,0),          "Bright yellow",NEON,false)
        hp(m,"ChanArm1",  Vector3.new(5,0.3,0.3),        cf(0,H-2.5,0),        "Dark grey",nil,false)
        hp(m,"ChanArm2",  Vector3.new(0.3,0.3,5),        cf(0,H-2.5,0),        "Dark grey",nil,false)
        -- Side banners
        for _,bx2 in ipairs({-W/2+1, W/2-1}) do
            hp(m,"Banner"..bx2,Vector3.new(0.3,7,3),    cf(bx2,8,2),          "Bright red",nil,false)
        end

    elseif fd.id == "vault" then
        -- The Treasury: gold bars, treasure chests, locked portcullis gate, coin piles
        -- Gold bar stacks
        for row=0,3 do for col=-2,2 do
            hp(m,"GBar"..row..col,Vector3.new(1.5,0.8,2.5),cf(col*2,1.5+row*0.9,4+row*0.3),"Bright yellow",nil,true)
        end end
        -- Treasure chests
        for k=0,2 do
            local cx3 = (k-1)*5
            hp(m,"Chest"..k,     Vector3.new(3,2,2),    cf(cx3,2,-6),         "Reddish brown",nil,true)
            hp(m,"ChestLid"..k,  Vector3.new(3,1,2),    cf(cx3,3.5,-6),       "Dark orange",nil,true)
            hp(m,"ChestGold"..k, Vector3.new(2.5,0.5,1.5),cf(cx3,2.5,-6),     "Bright yellow",NEON,false)
        end
        -- Portcullis gate
        hp(m,"Gate",     Vector3.new(W-4,10,T),          cf(0,6,-D/2+2),       "Dark grey",STONE,true)
        for k=-3,3 do
            hp(m,"GBar"..k, Vector3.new(0.5,10,T*0.5),  cf(k*2.5,6,-D/2+2.2),"Really black",nil,true)
        end
        hp(m,"GBarH",    Vector3.new(W-4,0.5,T*0.5),    cf(0,4,-D/2+2.2),     "Really black",nil,false)
        -- Coin piles
        hp(m,"Coins1",   Vector3.new(4,1,4),             cf(-6,1.5,-2),        "Bright yellow",nil,true)
        hp(m,"Coins2",   Vector3.new(3,0.8,3),           cf(-6,2.2,-2),        "Gold",nil,false)
        -- Vault door at back
        hp(m,"VDoor",    Vector3.new(7,9,T),             cf(0,5.5,D/2-1.5),    "Dark grey",Enum.Material.Metal,true)
        hp(m,"VRing",    Vector3.new(5,5,0.4),           cf(0,5.5,D/2-1.2),    "Medium stone grey",nil,false)
        hp(m,"VHandle",  Vector3.new(0.5,3,0.5),         cf(2,5.5,D/2-1),      "Gold",NEON,false)

    elseif fd.id == "escape_pod_bay" then
        -- Castle Battlements (top of the tower — open-air feel)
        -- Trebuchet / catapult
        hp(m,"TrebBase", Vector3.new(5,1,5),             cf(-4,1.5,0),         "Dark stone grey",STONE,true)
        hp(m,"TrebArm",  Vector3.new(0.6,9,0.6),         cf(-4,6.5,-1),        "Reddish brown",nil,true)
        hp(m,"TrebSling",Vector3.new(2,0.4,2),           cf(-4,11,2),          "Dark grey",nil,true)
        hp(m,"TrebWheel",Vector3.new(3,3,0.5),           cf(-4,3,-1),          "Dark stone grey",STONE,true)
        hp(m,"TrebBase2",Vector3.new(0.6,1.5,0.6),      cf(-2.5,2,1),         "Reddish brown",nil,true)
        -- Launch platform / signal fire
        hp(m,"FireBowl", Vector3.new(3,1,3),             cf(5,1.5,0),          "Dark stone grey",STONE,true)
        hp(m,"Fire",     Vector3.new(2,3,2),             cf(5,3.5,0),          "Bright orange",NEON,false)
        hp(m,"Smoke",    Vector3.new(1.5,2,1.5),         cf(5,5.5,0),          "Really black",nil,false)
        -- Sky window (glass ceiling for open tower feel)
        hp(m,"SkyGlass", Vector3.new(W-2,0.3,D-2),      cf(0,H-0.5,0),        "Cyan",NEON,false)
        -- Arrow slits in walls
        for _,ax in ipairs({-W/2+0.7, W/2-0.7}) do
            hp(m,"Slit1"..ax,Vector3.new(T,4,1.5),      cf(ax,6,3),           "Really black",nil,false)
            hp(m,"Slit2"..ax,Vector3.new(T,4,1.5),      cf(ax,6,-3),          "Really black",nil,false)
        end
        -- Flag pole at top
        hp(m,"FlagPole", Vector3.new(0.5,8,0.5),        cf(W/2-2,H+4,D/2-2), "Dark grey",STONE,true)
        hp(m,"Flag",     Vector3.new(4,2.5,0.2),        cf(W/2-2+2,H+7.5,D/2-2),"Bright red",nil,false)
    end

    -- Drop pad inside stairwell at ground level
    local pad = Instance.new("Part"); pad.Name="DropPad_"..fd.id
    pad.Size=Vector3.new(5,0.3,5)
    pad.CFrame=plotCF*CFrame.new(lx,0.25,STAIR_Z)
    pad.Anchored=true; pad.BrickColor=BrickColor.new("Bright green"); pad.Material=NEON
    pad.Parent=plot

    -- Castle stone staircase (hidden until bought)
    local sm = Instance.new("Model"); sm.Name="Stair_"..fd.id; sm.Parent=plot
    local steps = math.ceil(H/1.6)
    for s=1,steps do
        hp(sm,"S"..s, Vector3.new(4,0.5,1.8),
            plotCF*CFrame.new(lx, yBase+s*1.6-0.8, STAIR_Z-1+s*1.1),
            "Dark stone grey", STONE, true)
    end
    hp(sm,"Land",Vector3.new(4,0.5,4),
        plotCF*CFrame.new(lx,yBase+H-0.25,STAIR_Z),
        "Dark stone grey",STONE,true)
end

-- Alias so the plot builder loop still works
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
