-- src/ServerScriptService/PlayerSpawnController.server.luau
-- Explicitly teleports every character to the correct position on spawn/respawn.
-- Does NOT rely on Roblox's SpawnLocation system (which has been unreliable).
local Players = game:GetService("Players")

local function waitPM()
    while not _G.PlotManager do task.wait(0.1) end
    return _G.PlotManager
end

local function placeSafely(player: Player, char: Model)
    -- Wait for HumanoidRootPart to fully exist
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    if not hrp or not char.Parent then return end

    -- Small yield so physics engine is ready
    task.wait(0.15)
    if not char.Parent then return end   -- character might have been destroyed

    local pm   = waitPM()
    local plot = pm.getPlot(player)

    if plot then
        -- Player has an assigned base — land on their SpawnPad
        local pad = plot:FindFirstChild("SpawnPad")
        if pad then
            local topY = pad.Position.Y + pad.Size.Y / 2   -- top surface of pad
            hrp.CFrame = CFrame.new(pad.Position.X, topY + 5, pad.Position.Z)
            return
        end
    end

    -- No plot yet (first join / choosing base): use the central safe area
    local centralPad = workspace:FindFirstChild("CentralSpawnPad")
    local safeY = centralPad and (centralPad.Position.Y + centralPad.Size.Y / 2 + 5) or 6
    hrp.CFrame = CFrame.new(0, safeY, 0)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        task.spawn(placeSafely, player, char)
    end)
end)

-- Catch anyone already in game (Studio solo playtest)
for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        task.spawn(placeSafely, player, player.Character)
    end
end
