-- src/StarterPlayerScripts/SoundController.client.luau
local Remotes   = require(game.ReplicatedStorage.Remotes)
local RoomData  = require(game.ReplicatedStorage.RoomData)
local SoundData = require(game.ReplicatedStorage.SoundData)
local Debris    = game:GetService("Debris")

local sfxEnabled = true   -- toggled by SettingsController via _G

local function play(key: string)
	if not sfxEnabled then return end
	local id  = SoundData.IDS[key]
	local vol = SoundData.VOLUME[key] or 0.5
	if not id then return end
	local s = Instance.new("Sound")
	s.SoundId  = "rbxassetid://" .. id
	s.Volume   = vol
	s.RollOffMaxDistance = 0   -- 2D sound (no positional falloff)
	s.Parent   = workspace
	s:Play()
	Debris:AddItem(s, 6)
end

-- Room built → build sound; if a dept just completed → fanfare
Remotes.RoomBuilt.OnClientEvent:Connect(function(roomId: string, tier: number)
	play("build")
	-- Check if this completed a whole department (station index 10 = last in dept)
	if tier == 1 and roomId:match("lab_.+_10$") then
		task.delay(0.4, function() play("deptComplete") end)
	end
end)

-- Income tick → soft chime (only when income > 0)
Remotes.UpdateCurrency.OnClientEvent:Connect(function(amount: number, cap: number, incPerMin: number?)
	if (incPerMin or 0) > 0 then
		play("income")
	end
end)

-- Raid received
Remotes.RaidNotification.OnClientEvent:Connect(function()
	play("raidIn")
end)

-- Expose toggle for SettingsController
_G.SoundController = {
	setEnabled = function(enabled: boolean)
		sfxEnabled = enabled
	end
}
