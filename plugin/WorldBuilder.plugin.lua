-- Super V HQ World Builder Plugin
-- Drop this file in %LOCALAPPDATA%\Roblox\Plugins\ to install

local toolbar = plugin:CreateToolbar("Super V HQ")
local button = toolbar:CreateButton("Build World", "Build Super V HQ world in edit mode", "rbxassetid://0")

local ROOMS = {"lab","armory","minion_barracks","war_room","vault","escape_pod_bay"}
local NUM_PLOTS = 6
local RADIUS = 220
local W, H, D = 22, 12, 22

local function p(m, sz, dx, dy, dz, col, mat, cc, ox, oz)
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

local function labDecor(m, ox, oz)
    p(m,Vector3.new(2.5,7,2.5),-5,4.5,-7,"Bright green",Enum.Material.Neon,false,ox,oz)
    p(m,Vector3.new(2.5,7,2.5),5,4.5,-7,"Bright green",Enum.Material.Neon,false,ox,oz)
    p(m,Vector3.new(8,.5,4),-3,3.5,2,"Light grey",nil,true,ox,oz)
    p(m,Vector3.new(10,5,.3),2,7.5,-10.4,"Black",nil,false,ox,oz)
    p(m,Vector3.new(9,4,.2),2,7.5,-10.3,"Bright blue",Enum.Material.Neon,false,ox,oz)
    p(m,Vector3.new(20,.2,.2),0,1.2,-10.4,"Bright green",Enum.Material.Neon,false,ox,oz)
end
local function armoryDecor(m, ox, oz)
    for _,z in ipairs({-7,-2,3,8}) do
        p(m,Vector3.new(.4,6,.4),-10.3,4,z,"Dark grey",nil,true,ox,oz)
        p(m,Vector3.new(.4,6,.4),-10.3,4,z+1.5,"Dark grey",nil,true,ox,oz)
    end
    p(m,Vector3.new(4,3,4),6,2.5,-4,"Olive",nil,true,ox,oz)
    p(m,Vector3.new(4,3,4),6,2.5,2,"Olive",nil,true,ox,oz)
    p(m,Vector3.new(20,.2,.2),0,11.8,-10.4,"Bright red",Enum.Material.Neon,false,ox,oz)
    p(m,Vector3.new(20,.2,.2),0,11.8,10.4,"Bright red",Enum.Material.Neon,false,ox,oz)
end
local function barracksDecor(m, ox, oz)
    for _,bz in ipairs({-7,0,7}) do
        p(m,Vector3.new(6,.5,3),-6,2,bz,"Reddish brown",nil,true,ox,oz)
        p(m,Vector3.new(6,.5,3),-6,5,bz,"Reddish brown",nil,true,ox,oz)
        p(m,Vector3.new(.3,3,.3),-3.5,3.5,bz+1.2,"Dark grey",nil,true,ox,oz)
    end
    for _,lx in ipairs({2,4,6,8}) do
        p(m,Vector3.new(1.8,5,1.3),lx,3.5,-10,"Sand blue",nil,true,ox,oz)
    end
end
local function warRoomDecor(m, ox, oz)
    p(m,Vector3.new(12,1,8),0,4,0,"Dark grey",nil,true,ox,oz)
    p(m,Vector3.new(11.5,.3,7.5),0,4.65,0,"Bright blue",Enum.Material.Neon,false,ox,oz)
    p(m,Vector3.new(14,6,.3),0,7.5,-10.4,"Black",nil,false,ox,oz)
    p(m,Vector3.new(13,5,.2),0,7.5,-10.3,"Bright red",Enum.Material.Neon,false,ox,oz)
    p(m,Vector3.new(20,.2,.2),0,1.2,-10.4,"Bright blue",Enum.Material.Neon,false,ox,oz)
end
local function vaultDecor(m, ox, oz)
    p(m,Vector3.new(10,10,1.5),0,6,-10,"Dark grey",nil,true,ox,oz)
    p(m,Vector3.new(9,9,.5),0,6,-9.1,"Medium stone grey",nil,true,ox,oz)
    p(m,Vector3.new(7,7,.3),0,6,-8.8,"Dark grey",nil,false,ox,oz)
    p(m,Vector3.new(.5,3,.5),3,6,-8.5,"Gold",nil,false,ox,oz)
    for row=0,2 do for col=-2,2 do
        p(m,Vector3.new(1.5,.8,2.5),5+col*.4,1.5+row*.85,4+row*.2,"Bright yellow",nil,true,ox,oz)
    end end
    p(m,Vector3.new(20,.2,.2),0,1.5,-10.4,"Bright yellow",Enum.Material.Neon,false,ox,oz)
end
local function escapePodDecor(m, ox, oz)
    p(m,Vector3.new(6,1,6),0,1,-1,"Dark grey",nil,true,ox,oz)
    p(m,Vector3.new(5,8,5),0,6,-1,"White",nil,true,ox,oz)
    p(m,Vector3.new(4,3,4),0,10.5,-1,"Light grey",nil,true,ox,oz)
    for _,pos in ipairs({{2,2},{-2,2},{2,-4},{-2,-4}}) do
        p(m,Vector3.new(1,1,1),pos[1],.2,pos[2],"Bright orange",Enum.Material.Neon,false,ox,oz)
    end
    p(m,Vector3.new(6,.2,6),0,11.8,-1,"Cyan",Enum.Material.Neon,false,ox,oz)
end

local ROOM_DEFS = {
    lab             ={w="White",        f="Light grey",     d=labDecor},
    armory          ={w="Dark grey",    f="Dark stone grey",d=armoryDecor},
    minion_barracks ={w="Bright orange",f="Reddish brown",  d=barracksDecor},
    war_room        ={w="Really black", f="Dark grey",      d=warRoomDecor},
    vault           ={w="Bright yellow",f="Gold",           d=vaultDecor},
    escape_pod_bay  ={w="White",        f="Mid gray",       d=escapePodDecor},
}

local function buildRoomModel(plot, roomId, padPos, wc, fc, decorFn)
    local old = plot:FindFirstChild("Room_"..roomId)
    if old then old:Destroy() end
    local m = Instance.new("Model"); m.Name="Room_"..roomId; m.Parent=plot
    local ox, oz = padPos.X, padPos.Z
    local function pp(sz,dx,dy,dz,col,mat,cc)
        p(m,sz,dx,dy,dz,col,mat,cc,ox,oz)
    end
    pp(Vector3.new(W,1,D),   0, .5,  0,  fc)
    pp(Vector3.new(W,1,D),   0, H-.5,0,  wc, nil, false)
    pp(Vector3.new(W,H,1),   0, H/2,-D/2+.5, wc)
    pp(Vector3.new(1,H,D),  -W/2+.5,H/2,0,   wc)
    pp(Vector3.new(1,H,D),   W/2-.5,H/2,0,   wc)
    pp(Vector3.new(8,H,1),  -7,H/2,D/2-.5,   wc)
    pp(Vector3.new(8,H,1),   7,H/2,D/2-.5,   wc)
    pp(Vector3.new(6,4,1),   0,H-2,D/2-.5,   wc)
    decorFn(m, ox, oz)
end

local function buildWorld()
    -- Lighting
    local l = game:GetService("Lighting")
    l.ClockTime=0; l.Brightness=1.5
    l.Ambient=Color3.fromRGB(40,0,60); l.OutdoorAmbient=Color3.fromRGB(20,0,40)
    l.FogEnd=900; l.FogColor=Color3.fromRGB(15,0,30)
    local atmo = l:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere",l)
    atmo.Density=0.3; atmo.Color=Color3.fromRGB(80,0,120); atmo.Haze=2

    -- Clear old world
    for _,name in ipairs({"VillainFloor","CentrePad","GlowRing","VillainSpawn"}) do
        local old=workspace:FindFirstChild(name); if old then old:Destroy() end
    end
    for _,obj in pairs(workspace:GetChildren()) do
        if obj.Name:match("^Plot_%d+$") or obj.Name=="PathSegment" or obj.Name=="PathGlow" then
            obj:Destroy()
        end
    end

    -- Floor
    local floor=Instance.new("Part"); floor.Name="VillainFloor"
    floor.Size=Vector3.new(700,1,700); floor.Position=Vector3.new(0,-0.5,0)
    floor.Anchored=true; floor.BrickColor=BrickColor.new("Really black")
    floor.Material=Enum.Material.SmoothPlastic; floor.Parent=workspace

    -- Centre + ring
    local centre=Instance.new("Part"); centre.Name="CentrePad"
    centre.Size=Vector3.new(40,0.5,40); centre.Position=Vector3.new(0,0.2,0)
    centre.Anchored=true; centre.Shape=Enum.PartType.Cylinder
    centre.BrickColor=BrickColor.new("Dark grey"); centre.Parent=workspace

    local ring=Instance.new("Part"); ring.Name="GlowRing"
    ring.Size=Vector3.new(3,0.3,460); ring.Position=Vector3.new(0,0.3,0)
    ring.Anchored=true; ring.Shape=Enum.PartType.Cylinder
    ring.BrickColor=BrickColor.new("Bright red"); ring.Material=Enum.Material.Neon
    ring.Parent=workspace

    -- Spawn
    local sp=Instance.new("SpawnLocation"); sp.Name="VillainSpawn"
    sp.Size=Vector3.new(6,1,6); sp.CFrame=CFrame.new(0,0.5,0)
    sp.Anchored=true; sp.BrickColor=BrickColor.new("Bright red")
    sp.Material=Enum.Material.Neon; sp.Parent=workspace

    -- Plots
    for i=1,NUM_PLOTS do
        local angle=(i-1)*(2*math.pi/NUM_PLOTS)
        local cx=math.cos(angle)*RADIUS; local cz=math.sin(angle)*RADIUS
        local perp=angle+math.pi/2

        -- Path
        local path=Instance.new("Part"); path.Name="PathSegment"
        path.Size=Vector3.new(4,0.3,RADIUS)
        path.CFrame=CFrame.new(cx/2,0.2,cz/2)*CFrame.Angles(0,-angle,0)
        path.Anchored=true; path.BrickColor=BrickColor.new("Dark grey")
        path.Material=Enum.Material.SmoothPlastic; path.Parent=workspace

        local plot=Instance.new("Folder"); plot.Name="Plot_"..i; plot.Parent=workspace
        local occ=Instance.new("BoolValue"); occ.Name="IsOccupied"; occ.Value=false; occ.Parent=plot
        local oid=Instance.new("IntValue"); oid.Name="OwnerId"; oid.Value=0; oid.Parent=plot

        -- Point light
        local lpart=Instance.new("Part"); lpart.Name="PlotLight"
        lpart.Size=Vector3.new(1,1,1); lpart.Transparency=1; lpart.CanCollide=false
        lpart.Anchored=true; lpart.Position=Vector3.new(cx,12,cz); lpart.Parent=plot
        local pl=Instance.new("PointLight",lpart); pl.Brightness=3; pl.Range=60
        pl.Color=Color3.fromRGB(180,0,255)

        for idx,roomId in ipairs(ROOMS) do
            local offset=(idx-3.5)*18
            local px=cx+math.cos(perp)*offset; local pz=cz+math.sin(perp)*offset

            local pad=Instance.new("Part"); pad.Name="DropPad_"..roomId
            pad.Size=Vector3.new(6,0.5,6); pad.Anchored=true
            pad.BrickColor=BrickColor.new("Bright green"); pad.Material=Enum.Material.Neon
            pad.CFrame=CFrame.new(px,0.25,pz); pad.Parent=plot

            local def=ROOM_DEFS[roomId]
            buildRoomModel(plot,roomId,pad.Position,def.w,def.f,def.d)
        end
    end

    print("[WorldBuilder Plugin] World built in edit mode!")
end

button.Click:Connect(function()
    local changeHistoryService = game:GetService("ChangeHistoryService")
    changeHistoryService:SetWaypoint("Before Build World")
    buildWorld()
    changeHistoryService:SetWaypoint("After Build World")
end)
