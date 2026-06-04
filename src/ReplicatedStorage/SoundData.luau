-- src/ReplicatedStorage/SoundData.luau
-- Using verified free Roblox audio asset IDs (confirmed audio type, not images/models)
local SoundData = {}

SoundData.IDS = {
    build        = 131961136,    -- classic Roblox build/place sound
    income       = 142376088,    -- soft ding/chime
    raidIn       = 131028062,    -- alarm / impact
    raidOut      = 144652837,    -- whoosh launch
    deptComplete = 131028082,    -- short fanfare
    click        = 131028056,    -- UI click
}

SoundData.VOLUME = {
    build        = 0.4,
    income       = 0.15,
    raidIn       = 0.7,
    raidOut      = 0.5,
    deptComplete = 0.8,
    click        = 0.3,
}

return SoundData
