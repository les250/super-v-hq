-- src/StarterPlayerScripts/SafeRespawnController.client.luau
-- Safety net: if the player falls below the map after spawning, teleport them to safety.
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local FLOOR_Y = -5   -- below this = definitely in the void

local function protect(char)
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    local hum = char:WaitForChild("Humanoid", 5)
    if not hrp or not hum then return end

    -- Give physics 1 second to settle, then watch for 5 more seconds
    task.wait(1)
    local deadline = tick() + 5

    while tick() < deadline and char.Parent and hum.Health > 0 do
        if hrp.Position.Y < FLOOR_Y then
            -- Player is below the map — find the best safe spot
            local safeY   = 3
            local safeCF  = CFrame.new(hrp.Position.X, safeY, hrp.Position.Z)

            -- Try PlotSpawn first
            for _, folder in ipairs(workspace:GetChildren()) do
                if folder:IsA("Folder") and folder.Name:match("^Plot_%d+$") then
                    local oid = folder:FindFirstChild("OwnerId")
                    if oid and oid.Value == player.UserId then
                        local sp = folder:FindFirstChild("PlotSpawn")
                        if sp then safeCF = sp.CFrame * CFrame.new(0, 4, 0) end
                        break
                    end
                end
            end

            -- Teleport
            hrp.CFrame = safeCF
            break
        end
        task.wait(0.25)
    end
end

player.CharacterAdded:Connect(protect)
if player.Character then task.spawn(protect, player.Character) end
