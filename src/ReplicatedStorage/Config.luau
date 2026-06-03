-- src/ReplicatedStorage/Config.luau
local Config = {}

Config.INCOME_TICK_INTERVAL = 3        -- seconds between passive income ticks
Config.RAID_STEAL_PERCENT   = 0.10     -- base fraction of vault stolen per raid
Config.RAID_COOLDOWN        = 600      -- seconds a player is immune after being raided
Config.STARTING_CURRENCY    = 2000     -- currency new players start with
Config.BASE_VAULT_CAP       = 3000    -- starting cap (overridden by progressive dept caps in RoomData)

-- Developer Product IDs — replace 0 with real IDs from Creator Hub before publishing
Config.PRODUCT_CURRENCY_SMALL  = 0    -- grants 500 in-game currency
Config.PRODUCT_CURRENCY_MEDIUM = 0    -- grants 1500 in-game currency
Config.PRODUCT_CURRENCY_LARGE  = 0    -- grants 5000 in-game currency
Config.PRODUCT_RAID            = 0    -- triggers a raid on a target player

-- Amounts granted per currency product
Config.PRODUCT_CURRENCY_AMOUNTS = {
    [Config.PRODUCT_CURRENCY_SMALL]  = 500,
    [Config.PRODUCT_CURRENCY_MEDIUM] = 1500,
    [Config.PRODUCT_CURRENCY_LARGE]  = 5000,
}

return Config
