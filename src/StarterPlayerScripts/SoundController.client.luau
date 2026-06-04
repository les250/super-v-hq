-- src/StarterPlayerScripts/SoundController.client.luau
local Remotes   = require(game.ReplicatedStorage.Remotes)
local SoundData = require(game.ReplicatedStorage.SoundData)
local Debris    = game:GetService("Debris")
local RunService = game:GetService("RunService")

-- Disable all sounds in Studio to avoid asset-load spam in output
local IS_STUDIO = RunService:IsStudio()

local sfxEnabled = not IS_STUDIO  -- off in Studio, on in live game

local lastIncomeSfx = 0
local INCOME_SFX_COOLDOWN = 8  -- play income chime at most once every 8 seconds

local function play(key: string)
    if not sfxEnabled then return end
    local id  = SoundData.IDS[key]
    local vol = SoundData.VOLUME[key] or 0.5
    if not id then return end
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://" .. id
    s.Volume  = vol
    s.RollOffMaxDistance = 0
    s.Parent  = workspace
    s:Play()
    Debris:AddItem(s, 6)
end

-- Room built → build sound + dept complete fanfare
Remotes.RoomBuilt.OnClientEvent:Connect(function(roomId: string, tier: number)
    play("build")
    if tier == 1 and roomId:match("lab_.+_10$") then
        task.delay(0.5, function() play("deptComplete") end)
    end
end)

-- Income tick → soft chime with 8s cooldown (income fires every 3s, would spam otherwise)
Remotes.UpdateCurrency.OnClientEvent:Connect(function(amount, cap, incPerMin)
    if (incPerMin or 0) > 0 then
        local now = tick()
        if now - lastIncomeSfx >= INCOME_SFX_COOLDOWN then
            lastIncomeSfx = now
            play("income")
        end
    end
end)

-- Raid received
Remotes.RaidNotification.OnClientEvent:Connect(function()
    play("raidIn")
end)

-- Settings toggle
_G.SoundController = {
    setEnabled = function(enabled: boolean)
        sfxEnabled = enabled and not IS_STUDIO
    end
}
