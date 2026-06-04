-- src/ServerScriptService/PublishValidator.server.luau
-- Warns in Studio output when developer product IDs are still placeholder (0).
-- Remove or disable this script before publishing to keep output clean.
local Config = require(game.ReplicatedStorage.Config)

local function checkId(name: string, id: number)
	if id == 0 then
		warn(string.format("[PUBLISH] %s is still 0 (placeholder). Set a real Developer Product ID in Config.luau before publishing.", name))
	end
end

checkId("PRODUCT_CURRENCY_SMALL",  Config.PRODUCT_CURRENCY_SMALL)
checkId("PRODUCT_CURRENCY_MEDIUM", Config.PRODUCT_CURRENCY_MEDIUM)
checkId("PRODUCT_CURRENCY_LARGE",  Config.PRODUCT_CURRENCY_LARGE)
checkId("PRODUCT_RAID",            Config.PRODUCT_RAID)

if Config.PRODUCT_CURRENCY_SMALL == 0 then
	warn("[PUBLISH] Monetisation NOT active. Players cannot purchase Robux products until product IDs are set.")
end
