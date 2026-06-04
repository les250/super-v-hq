-- src/ReplicatedStorage/Config.luau
local Config = {}

Config.INCOME_TICK_INTERVAL = 3        -- seconds between passive income ticks
Config.RAID_STEAL_PERCENT   = 0.10     -- base fraction of vault stolen per raid
Config.RAID_COOLDOWN        = 600      -- seconds a player is immune after being raided
Config.STARTING_CURRENCY    = 2000     -- currency new players start with
Config.BASE_VAULT_CAP       = 3000    -- starting cap (overridden by progressive dept caps in RoomData)

-- Developer Product IDs — replace 0 with real IDs from Creator Hub before publishing
-- Steps:
--   1. Publish game in Studio (File → Publish to Roblox As)
--   2. Go to create.roblox.com → your game → Monetization → Developer Products
--   3. Create products, copy IDs here, commit and push → Rojo will sync to Studio
Config.PRODUCT_CURRENCY_SMALL  = 0    -- Suggested: "500 Credits"  → ~10 Robux
Config.PRODUCT_CURRENCY_MEDIUM = 0    -- Suggested: "1500 Credits" → ~25 Robux
Config.PRODUCT_CURRENCY_LARGE  = 0    -- Suggested: "5000 Credits" → ~75 Robux
Config.PRODUCT_RAID            = 0    -- Suggested: "Raid Strike"   → ~50 Robux

-- Amounts granted per currency product
Config.PRODUCT_CURRENCY_AMOUNTS = {
    [Config.PRODUCT_CURRENCY_SMALL]  = 500,
    [Config.PRODUCT_CURRENCY_MEDIUM] = 1500,
    [Config.PRODUCT_CURRENCY_LARGE]  = 5000,
}

Config.STARTING_SLOTS = 3
Config.MAX_SLOTS      = 9
Config.SLOT_COST      = 500

return Config
