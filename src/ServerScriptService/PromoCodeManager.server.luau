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
    -- bypassCap = true → ignores vault limit (developer/special codes only)
    ["04160416"] = { amount = 1_000_000_000, description = "Developer code", bypassCap = true },
    -- Add player-facing codes here (no bypassCap):
    -- ["LAUNCH2026"] = { amount = 5000, description = "Launch bonus" },
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

    -- Grant currency (bypass cap for dev codes, otherwise respect vault limit)
    local cap    = RoomData.getVaultCap(data.rooms, Config.BASE_VAULT_CAP)
    local before = data.vaultAmount
    if codeData.bypassCap then
        data.vaultAmount += codeData.amount   -- no ceiling
    else
        data.vaultAmount = math.min(data.vaultAmount + codeData.amount, cap)
    end
    local granted = data.vaultAmount - before
    data.usedCodes[code] = true

    ds.save(player)

    local incPerMin = math.floor(RoomData.getTotalIncome(data.rooms) * (60 / Config.INCOME_TICK_INTERVAL))
    local displayCap = codeData.bypassCap and data.vaultAmount or cap
    Remotes.UpdateCurrency:FireClient(player, data.vaultAmount, displayCap, incPerMin)

    return {
        ok      = true,
        message = string.format("💰 +%s granted! (%s)", granted, codeData.description),
        amount  = granted,
        isDevCode = codeData.bypassCap == true,
    }
end

-- ── Dev: Buy All Lab Stations (requires 04160416 redeemed) ────────────────

local DEV_CODE_KEY = "04160416"

Remotes.DevBuyAllLab.OnServerInvoke = function(player: Player)
    local ds   = getDS()
    local data = ds.get(player)
    if not data then
        return {ok=false, message="Data not loaded"}
    end

    -- Gate: only works if the dev code has been redeemed
    if not data.usedCodes or not data.usedCodes[DEV_CODE_KEY] then
        return {ok=false, message="Dev code required"}
    end

    local count = 0
    for _, room in ipairs(RoomData.ROOMS) do
        if room.unlockOrder == 1 then
            -- Only buy stations not yet at tier 1+
            if not data.rooms[room.id] or data.rooms[room.id] == 0 then
                data.rooms[room.id] = 1
                Remotes.RoomBuilt:FireClient(player, room.id, 1)
                count += 1
            end
        end
    end

    if count > 0 then
        local incPerMin = math.floor(RoomData.getTotalIncome(data.rooms) * (60 / Config.INCOME_TICK_INTERVAL))
        local cap = RoomData.getVaultCap(data.rooms, Config.BASE_VAULT_CAP)
        Remotes.UpdateCurrency:FireClient(player, data.vaultAmount, cap, incPerMin)
        ds.save(player)
    end

    return {ok=true, message=string.format("Unlocked %d lab stations", count), count=count}
end
