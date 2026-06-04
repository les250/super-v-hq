-- src/ReplicatedStorage/SoundData.luau
local SoundData = {}

-- Free Roblox audio library IDs
SoundData.IDS = {
	build        = 3526557030,   -- sci-fi construction beep
	income       = 4843648880,   -- soft coin chime
	raidIn       = 5804562289,   -- impact / alarm
	raidOut      = 6042053626,   -- launch sound
	deptComplete = 4809642087,   -- fanfare / level up
	click        = 876939830,    -- UI click
}

SoundData.VOLUME = {
	build        = 0.4,
	income       = 0.12,
	raidIn       = 0.7,
	raidOut      = 0.5,
	deptComplete = 0.8,
	click        = 0.3,
}

return SoundData
