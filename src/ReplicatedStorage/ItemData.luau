-- src/ReplicatedStorage/ItemData.luau
local ItemData = {}

ItemData.ITEMS = {
    ["stim_pack"]      = {name="Stim Pack",      rarity="Common",   icon="💊", incomeBoostPct=0.10, description="+10% income while held"},
    ["emp_grenade"]    = {name="EMP Grenade",    rarity="Uncommon", icon="💣", raidBoostPct=0.05,  description="+5% raid steal"},
    ["armor_chip"]     = {name="Armor Chip",     rarity="Rare",     icon="🔩", defenseBoostPct=0.03,description="+3% raid defense"},
    ["vault_override"] = {name="Vault Override", rarity="Epic",     icon="🗝", capBoost=5000,      description="+5000 vault cap"},
    ["minion_core"]    = {name="Minion Core",    rarity="Rare",     icon="🤖", minionBoostPct=0.10,description="+10% minion defense"},
}

ItemData.RARITY_COLOR = {
    Common   = Color3.fromRGB(200,200,200),
    Uncommon = Color3.fromRGB(100,220,100),
    Rare     = Color3.fromRGB(80,140,255),
    Epic     = Color3.fromRGB(180,80,255),
}

function ItemData.get(id: string)
    return ItemData.ITEMS[id]
end

return ItemData
