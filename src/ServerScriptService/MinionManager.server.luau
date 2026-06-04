-- src/ServerScriptService/MinionManager.server.luau
local Players = game:GetService("Players")
local Remotes = require(game.ReplicatedStorage.Remotes)

local function getDS()
    while not _G.DataStore do task.wait(0.1) end
    return _G.DataStore
end

local function getPM()
    while not _G.PlotManager do task.wait(0.1) end
    return _G.PlotManager
end

local MINION_COUNT = {2, 4, 6}  -- per barracks tier

-- { [userId: number]: {Model} }
local spawnedMinions: {[number]: {any}} = {}

local function clearMinions(userId: number)
    for _, m in ipairs(spawnedMinions[userId] or {}) do
        if m and m.Parent then m:Destroy() end
    end
    spawnedMinions[userId] = {}
end

local function spawnMinions(player: Player, tier: number)
    if tier < 1 then clearMinions(player.UserId); return end  -- tier=0 = just clear
    if tier > 3 then return end
    local pm   = getPM()
    local plot = pm.getPlot(player)
    if not plot then return end

    clearMinions(player.UserId)
    spawnedMinions[player.UserId] = {}

    local count = MINION_COUNT[tier]
    local pad   = plot:FindFirstChild("DropPad_minion_barracks")
    local baseX = pad and pad.Position.X or 0
    local baseZ = pad and pad.Position.Z or 0
    local baseY = 1

    for i = 1, count do
        local angle = (i - 1) * (2 * math.pi / count)

        local rig = Instance.new("Model")
        rig.Name = "Minion_" .. player.UserId .. "_" .. i

        -- Root part
        local hrp = Instance.new("Part"); hrp.Name = "HumanoidRootPart"
        hrp.Size = Vector3.new(2, 2, 1); hrp.Anchored = false
        hrp.BrickColor = BrickColor.new("Bright orange")
        hrp.Material = Enum.Material.SmoothPlastic
        hrp.CFrame = CFrame.new(
            baseX + math.cos(angle) * 8,
            baseY,
            baseZ + math.sin(angle) * 8
        )
        hrp.Parent = rig

        -- Head
        local head = Instance.new("Part"); head.Name = "Head"
        head.Size = Vector3.new(2, 1, 1)
        head.BrickColor = BrickColor.new("Bright orange")
        head.Material = Enum.Material.SmoothPlastic
        head.CFrame = hrp.CFrame * CFrame.new(0, 1.5, 0)
        head.Parent = rig

        -- Weld head to root
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = hrp; weld.Part1 = head; weld.Parent = rig

        -- Eyes (neon dots)
        local eye1 = Instance.new("Part"); eye1.Name = "Eye1"
        eye1.Size = Vector3.new(0.3, 0.3, 0.1)
        eye1.BrickColor = BrickColor.new("Bright red")
        eye1.Material = Enum.Material.Neon
        eye1.CFrame = hrp.CFrame * CFrame.new(-0.4, 1.6, -0.5)
        eye1.Parent = rig
        local ew1 = Instance.new("WeldConstraint"); ew1.Part0=hrp; ew1.Part1=eye1; ew1.Parent=rig

        local eye2 = Instance.new("Part"); eye2.Name = "Eye2"
        eye2.Size = Vector3.new(0.3, 0.3, 0.1)
        eye2.BrickColor = BrickColor.new("Bright red")
        eye2.Material = Enum.Material.Neon
        eye2.CFrame = hrp.CFrame * CFrame.new(0.4, 1.6, -0.5)
        eye2.Parent = rig
        local ew2 = Instance.new("WeldConstraint"); ew2.Part0=hrp; ew2.Part1=eye2; ew2.Parent=rig

        local hum = Instance.new("Humanoid")
        hum.WalkSpeed = 8
        hum.MaxHealth = 100
        hum.Health    = 100
        hum.DisplayName = "Minion"
        hum.Parent = rig

        rig.PrimaryPart = hrp
        rig.Parent = workspace

        table.insert(spawnedMinions[player.UserId], rig)

        -- Patrol loop
        local patrolTargets = {
            Vector3.new(baseX + math.cos(angle) * 8, baseY, baseZ + math.sin(angle) * 8),
            Vector3.new(baseX + math.cos(angle + math.pi) * 5, baseY, baseZ + math.sin(angle + math.pi) * 5),
        }
        local targetIdx = 1
        task.spawn(function()
            while rig.Parent do
                hum:MoveTo(patrolTargets[targetIdx])
                hum.MoveToFinished:Wait()
                targetIdx = (targetIdx % #patrolTargets) + 1
                task.wait(0.5)
            end
        end)
    end
end

-- Expose API for EconomyManager hook
local MinionManager = {}

function MinionManager.onBarracksBuilt(player: Player, tier: number)
    spawnMinions(player, tier)
end

_G.MinionManager = MinionManager

-- Spawn minions for players already online with barracks built
Players.PlayerAdded:Connect(function(player)
    task.wait(3)  -- wait for data and plot to load
    local ds   = getDS()
    local data = ds.get(player)
    if data and data.rooms and data.rooms["minion_barracks"] and data.rooms["minion_barracks"] > 0 then
        spawnMinions(player, data.rooms["minion_barracks"])
    end
end)

Players.PlayerRemoving:Connect(function(player)
    clearMinions(player.UserId)
end)

-- Catch players already in game (Studio playtest)
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function()
        task.wait(3)
        local ds   = getDS()
        local data = ds.get(player)
        if data and data.rooms and data.rooms["minion_barracks"] and data.rooms["minion_barracks"] > 0 then
            spawnMinions(player, data.rooms["minion_barracks"])
        end
    end)
end
