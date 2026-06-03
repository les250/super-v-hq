-- src/ServerScriptService/PromoCodeManager.server.luau
-- Server-side promo code validation. All logic is server-only so codes can't be spoofed.
local Remotes  = require(game.ReplicatedStorage.Remotes)
local RoomData = require(game.ReplicatedStorage.RoomData)
local Config   = require(game.ReplicatedStorage.Config)

local function getDS()
    while not _G.DataStore do task.wait(0.1) end
    return _G.DataStore
end

-- ── Code registry (server-only, never sent to client) ─────────────────────
local CODES = {
    ["04160416"] = { amount = 100000, description = "Founder bonus" },
    -- Add more codes here as needed
}

-- ── Handler ────────────────────────────────────────────────────────────────

Remotes.RedeemCode.OnServerInvoke = function(player: Player, code: string)
    -- Sanitise input
    if type(code) ~= "string" then
        return { ok = false, message = "Invalid code." }
    end
    code = code:gsub("%s", ""):upper()  -- strip spaces, uppercase

    -- Check code exists (compare uppercase stored keys too)
    local codeData = nil
    for k, v in pairs(CODES) do
        if k:upper() == code then codeData = v; break end
    end

    if not codeData then
        return { ok = false, message = "Code not found. Check spelling and try again." }
    end

    -- Load player data
    local ds   = getDS()
    local data = ds.get(player)
    if not data then
        return { ok = false, message = "Data not loaded yet. Try again in a moment." }
    end

    -- Track used codes in player data
    if not data.usedCodes then data.usedCodes = {} end
    if data.usedCodes[code] then
        return { ok = false, message = "You've already redeemed this code." }
    end

    -- Grant currency (capped at vault limit)
    local cap = RoomData.getVaultCap(data.rooms, Config.BASE_VAULT_CAP)
    local before = data.vaultAmount
    data.vaultAmount = math.min(data.vaultAmount + codeData.amount, cap)
    local granted = data.vaultAmount - before
    data.usedCodes[code] = true

    -- Save immediately so duplicate redemptions across sessions are prevented
    ds.save(player)

    -- Push currency update to client
    local incPer30s = math.floor(RoomData.getTotalIncome(data.rooms) * (60 / Config.INCOME_TICK_INTERVAL))
    Remotes.UpdateCurrency:FireClient(player, data.vaultAmount, cap, incPer30s)

    return {
        ok      = true,
        message = string.format("💰 +%s granted! (%s)", granted, codeData.description),
        amount  = granted,
    }
end
