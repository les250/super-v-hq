# Super V HQ — Full Roadmap & Task Breakdown

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete Super V HQ from current playable state to a shippable Roblox tycoon game.

**Architecture:** 14 Luau scripts, Rojo sync, DataStore persistence, MarketplaceService monetisation. New features add server scripts in `ServerScriptService/`, client scripts in `StarterPlayerScripts/`, and shared data in `ReplicatedStorage/`.

**Tech Stack:** Luau, Rojo 7.x, Roblox Studio, DataStoreService, MarketplaceService, TweenService

---

## What Already Exists

| File | Status |
|---|---|
| Config.luau | ✅ |
| RoomData.luau (50 lab + 5 upper floors) | ✅ |
| Remotes.luau | ✅ |
| DataStore.server.luau | ✅ |
| EconomyManager.server.luau | ✅ |
| PlotManager.server.luau | ✅ |
| RaidManager.server.luau | ✅ |
| WorldSetup.server.luau | ✅ |
| PromoCodeManager.server.luau | ✅ |
| BaseSelector.client.luau | ✅ |
| DropPadClient.client.luau | ✅ |
| HudController.client.luau | ✅ |
| LabelController.client.luau | ✅ |
| ObjectivesController.client.luau | ✅ |

---

## Task Groups (independent — safe to run in parallel)

```
Phase 1 (Core gameplay)  ←── can all run in parallel
  Task 1: Raid Cooldown Display
  Task 2: War Room Spy UI
  Task 3: Escape Pod Teleport
  Task 4: Armory Raid Boost

Phase 2 (Item economy)   ←── Task 5 before 6, 7, 8
  Task 5: Wallet Slots (lobby purchase, 3–9 slots)
  Task 6: Item System (items, inventory UI)
  Task 7: Crafting (Lab ability unlocks recipes)
  Task 8: Trading System

Phase 3 (Social)         ←── parallel
  Task 9:  Leaderboard
  Task 10: NPC Minions (Barracks visual defenders)

Phase 4 (Polish)         ←── parallel
  Task 11: Sound Effects
  Task 12: Tutorial / Onboarding
  Task 13: Settings Menu
  Task 14: Mobile UI

Phase 5 (Launch)         ←── sequential, last
  Task 15: Better Room Visuals
  Task 16: Publish + Real Robux Product IDs
  Task 17: Anti-Exploit Hardening
```

---

## ✅ Checkpoint after Phase 1
> All 4 abilities work in a 2-player test. Income/raid flow is smooth.

## ✅ Checkpoint after Phase 2
> Item economy complete. Players can craft, own, and trade items.

## ✅ Checkpoint after Phase 3
> Leaderboard live. Minions defend raids.

## ✅ Checkpoint after Phase 4
> Game feels polished — sounds, tutorial, settings, mobile-friendly.

## ✅ Checkpoint after Phase 5 (Ship)
> Published on Roblox, real Robux products wired, no known exploits.

---

---

# Task 1: Raid Cooldown Display

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans

**Goal:** Show the raided player a countdown HUD element so they know when they can be raided again (10-minute cooldown = 600s).

**Files:**
- Modify: `src/ServerScriptService/RaidManager.server.luau` — send `lastRaidedAt` on each currency update
- Modify: `src/StarterPlayerScripts/HudController.client.luau` — add cooldown countdown label
- Modify: `src/ReplicatedStorage/Remotes.luau` — add `RaidCooldownUpdate` RemoteEvent

**Architecture:** Server fires `RaidCooldownUpdate(secondsRemaining)` on join and after every raid. Client polls a countdown label every second.

- [ ] **Step 1: Add remote**

In `src/ReplicatedStorage/Remotes.luau`, after `Remotes.RaidNotification`:
```lua
Remotes.RaidCooldownUpdate = get("RemoteEvent", "RaidCooldownUpdate") -- (secondsRemaining: number)
```

- [ ] **Step 2: Fire cooldown on join and after raid**

In `src/ServerScriptService/RaidManager.server.luau`, add helper:
```lua
local function pushCooldown(player: Player)
    local ds   = getDS()
    local data = ds.get(player)
    if not data then return end
    local remaining = math.max(0, Config.RAID_COOLDOWN - (os.time() - (data.lastRaidedAt or 0)))
    Remotes.RaidCooldownUpdate:FireClient(player, remaining)
end
```

Call `pushCooldown(player)` at the end of `executeRaid` (after RaidNotification).

Also push on join: in the `Players.PlayerAdded` section of RaidManager (add a new connection):
```lua
game:GetService("Players").PlayerAdded:Connect(function(player)
    task.wait(2)  -- wait for data to load
    pushCooldown(player)
end)
```

- [ ] **Step 3: Client countdown UI**

In `src/StarterPlayerScripts/HudController.client.luau`, add below `incomeLabel`:
```lua
-- Raid shield countdown (hidden when no cooldown)
local shieldFrame = Instance.new("Frame")
shieldFrame.Size     = UDim2.new(0, 260, 0, 28)
shieldFrame.Position = UDim2.new(0, 16, 0, 132)
shieldFrame.BackgroundColor3 = Color3.fromRGB(0, 40, 60)
shieldFrame.BackgroundTransparency = 0.3
shieldFrame.Visible  = false
shieldFrame.Parent   = gui
Instance.new("UICorner", shieldFrame).CornerRadius = UDim.new(0, 6)

local shieldLabel = Instance.new("TextLabel")
shieldLabel.Size = UDim2.new(1, -8, 1, 0); shieldLabel.Position = UDim2.new(0,4,0,0)
shieldLabel.BackgroundTransparency = 1; shieldLabel.TextColor3 = Color3.fromRGB(80,200,255)
shieldLabel.TextScaled = true; shieldLabel.Font = Enum.Font.Gotham
shieldLabel.TextXAlignment = Enum.TextXAlignment.Left; shieldLabel.Parent = shieldFrame

local cooldownRemaining = 0
task.spawn(function()
    while true do
        task.wait(1)
        if cooldownRemaining > 0 then
            cooldownRemaining -= 1
            local m = math.floor(cooldownRemaining/60)
            local s = cooldownRemaining % 60
            shieldLabel.Text = string.format("🛡 Raid shield: %d:%02d", m, s)
            shieldFrame.Visible = true
        else
            shieldFrame.Visible = false
        end
    end
end)

Remotes.RaidCooldownUpdate.OnClientEvent:Connect(function(secs: number)
    cooldownRemaining = math.floor(secs)
    shieldFrame.Visible = cooldownRemaining > 0
end)
```

- [ ] **Step 4: In-Studio test**

Playtest with 2 clients. Have player 2 raid player 1. Verify:
- Player 1 sees `🛡 Raid shield: 9:59` counting down
- Shield disappears after timer reaches 0
- On rejoin, shield timer resumes from where it was (server pushes remaining on join)

- [ ] **Step 5: Commit**
```bash
cd ~/Ubuntu\ -\ Les/PERSONAL/roblox-game
git add src/ReplicatedStorage/Remotes.luau src/ServerScriptService/RaidManager.server.luau src/StarterPlayerScripts/HudController.client.luau
git commit -m "feat: raid cooldown countdown shield in HUD"
git push
```

---

# Task 2: War Room Spy UI

**Goal:** Players who have built the War Room can open a "Spy Network" panel showing every online player's name and vault amount.

**Files:**
- Create: `src/StarterPlayerScripts/WarRoomController.client.luau`
- Remotes: `GetAllPlotInfo` already exists in EconomyManager (gated by war_room ownership)

**Architecture:** A toggle panel (right side, below Objectives). Calls `GetAllPlotInfo:InvokeServer()` on open. Shows a scrollable list of players with vault bars. Refreshes every 30 seconds when open.

- [ ] **Step 1: Create WarRoomController.client.luau**

```lua
-- src/StarterPlayerScripts/WarRoomController.client.luau
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Remotes      = require(game.ReplicatedStorage.Remotes)
local RoomData     = require(game.ReplicatedStorage.RoomData)

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

task.wait(2)

local screen = Instance.new("ScreenGui")
screen.Name = "WarRoomUI"; screen.ResetOnSpawn = false; screen.Parent = playerGui

-- Toggle button (below Objectives button)
local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0,38,0,90); btn.Position = UDim2.new(1,-38,0.5,60)
btn.BackgroundColor3 = Color3.fromRGB(80,0,0); btn.BackgroundTransparency=0.2
btn.TextColor3 = Color3.fromRGB(255,100,100); btn.TextScaled=true
btn.Font = Enum.Font.GothamBold; btn.Text = "🕵\nSPY"
btn.Parent = screen
Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8)

-- Panel
local panel = Instance.new("Frame")
panel.Name="SpyPanel"; panel.Size=UDim2.new(0,280,0.7,0)
panel.Position=UDim2.new(1,4,0.15,0)   -- off-screen initially
panel.BackgroundColor3=Color3.fromRGB(20,0,0); panel.BackgroundTransparency=0.1
panel.Parent=screen
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,10)
local pst=Instance.new("UIStroke",panel); pst.Color=Color3.fromRGB(220,0,0); pst.Thickness=1.5

local titleLbl=Instance.new("TextLabel"); titleLbl.Size=UDim2.new(1,-40,0,32)
titleLbl.Position=UDim2.new(0,5,0,4); titleLbl.BackgroundTransparency=1
titleLbl.TextColor3=Color3.fromRGB(255,80,80); titleLbl.TextScaled=true
titleLbl.Font=Enum.Font.GothamBold; titleLbl.Text="🕵  SPY NETWORK"
titleLbl.TextXAlignment=Enum.TextXAlignment.Left; titleLbl.Parent=panel

local closeBtn=Instance.new("TextButton"); closeBtn.Size=UDim2.new(0,32,0,32)
closeBtn.Position=UDim2.new(1,-36,0,4); closeBtn.BackgroundColor3=Color3.fromRGB(60,0,0)
closeBtn.BackgroundTransparency=0.3; closeBtn.TextColor3=Color3.fromRGB(255,80,80)
closeBtn.TextScaled=true; closeBtn.Font=Enum.Font.GothamBold; closeBtn.Text="✕"
closeBtn.Parent=panel; Instance.new("UICorner",closeBtn).CornerRadius=UDim.new(0,6)

local noWarRoom=Instance.new("TextLabel"); noWarRoom.Size=UDim2.new(1,-10,0,40)
noWarRoom.Position=UDim2.new(0,5,0,40); noWarRoom.BackgroundTransparency=1
noWarRoom.TextColor3=Color3.fromRGB(150,80,80); noWarRoom.TextScaled=true
noWarRoom.Font=Enum.Font.Gotham; noWarRoom.Text="🔒 Build the War Room\nto unlock spy network"
noWarRoom.Parent=panel; noWarRoom.Visible=false

local scroll=Instance.new("ScrollingFrame"); scroll.Size=UDim2.new(1,-8,1,-44)
scroll.Position=UDim2.new(0,4,0,40); scroll.BackgroundTransparency=1
scroll.ScrollBarThickness=4; scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
scroll.Parent=panel
Instance.new("UIListLayout",scroll).Padding=UDim.new(0,3)

local function makeRow(name, vaultAmt, isMe)
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,-4,0,36)
    row.BackgroundColor3=isMe and Color3.fromRGB(40,0,0) or Color3.fromRGB(25,0,0)
    row.BackgroundTransparency=0.3; row.Parent=scroll
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,4)
    local nl=Instance.new("TextLabel"); nl.Size=UDim2.new(0.55,0,1,0)
    nl.Position=UDim2.new(0,4,0,0); nl.BackgroundTransparency=1
    nl.TextColor3=isMe and Color3.fromRGB(255,200,50) or Color3.fromRGB(255,255,255)
    nl.TextScaled=true; nl.Font=Enum.Font.GothamBold; nl.TextXAlignment=Enum.TextXAlignment.Left
    nl.Text=(isMe and "★ " or "")..name; nl.Parent=row
    local vl=Instance.new("TextLabel"); vl.Size=UDim2.new(0.43,0,1,0)
    vl.Position=UDim2.new(0.56,0,0,0); vl.BackgroundTransparency=1
    vl.TextColor3=Color3.fromRGB(255,220,50); vl.TextScaled=true; vl.Font=Enum.Font.Gotham
    vl.TextXAlignment=Enum.TextXAlignment.Right
    vl.Text=string.format("💰 %d", math.floor(vaultAmt)); vl.Parent=row
end

local function refresh()
    for _,c in ipairs(scroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    local info = Remotes.GetAllPlotInfo:InvokeServer()
    if not info or #info == 0 then
        noWarRoom.Visible = true; scroll.Visible = false; return
    end
    noWarRoom.Visible = false; scroll.Visible = true
    table.sort(info, function(a,b) return a.vaultAmount > b.vaultAmount end)
    for _, entry in ipairs(info) do
        makeRow(entry.name, entry.vaultAmount, entry.userId == player.UserId)
    end
end

local isOpen = false
local OPEN_POS  = UDim2.new(1,-284,0.15,0)
local CLOSE_POS = UDim2.new(1,4,0.15,0)

local function setOpen(open)
    isOpen = open
    TweenService:Create(panel,TweenInfo.new(0.25,Enum.EasingStyle.Quad),
        {Position=open and OPEN_POS or CLOSE_POS}):Play()
    btn.Text = open and "🕵\n✕" or "🕵\nSPY"
    if open then refresh() end
end

btn.Activated:Connect(function() setOpen(not isOpen) end)
closeBtn.Activated:Connect(function() setOpen(false) end)

-- Auto-refresh every 30s when open
task.spawn(function()
    while true do task.wait(30); if isOpen then refresh() end end
end)
```

- [ ] **Step 2: In-Studio test**

1. Build War Room in a 2-player test
2. Click 🕵 SPY button → panel slides in showing both players sorted by vault
3. Without War Room built → panel shows locked message
4. Verify sorted by vault amount descending

- [ ] **Step 3: Commit**
```bash
git add src/StarterPlayerScripts/WarRoomController.client.luau
git commit -m "feat: War Room spy network panel — shows all players' vault amounts"
git push
```

---

# Task 3: Escape Pod Teleport System

**Goal:** Players with Escape Pod Bay built get a "Teleport" button that lets them visit any other player's base (one-way teleport, 30-second cooldown).

**Files:**
- Create: `src/StarterPlayerScripts/EscapePodController.client.luau`
- Modify: `src/ServerScriptService/PlotManager.server.luau` — add `TeleportToPlot` remote
- Modify: `src/ReplicatedStorage/Remotes.luau` — add `TeleportToPlot` RemoteEvent

**Architecture:** Client shows a player picker. Server moves character's HumanoidRootPart to target plot's spawn. 30-second client-side cooldown prevents spam.

- [ ] **Step 1: Add remote**

In `src/ReplicatedStorage/Remotes.luau`:
```lua
Remotes.TeleportToPlot = get("RemoteEvent", "TeleportToPlot")  -- (targetUserId: number)
```

- [ ] **Step 2: Server handler in PlotManager**

Add at the bottom of `src/ServerScriptService/PlotManager.server.luau` (inside the task.spawn block after Remotes loads):
```lua
Remotes.TeleportToPlot.OnServerEvent:Connect(function(player, targetUserId)
    -- Validate: player must have Escape Pod Bay built
    local ds = getDS()
    local data = ds.get(player)
    if not data or not data.rooms["escape_pod_bay"] or data.rooms["escape_pod_bay"] == 0 then return end

    local targetPlot = playerPlots[targetUserId]
    if not targetPlot then return end

    local spawn = targetPlot:FindFirstChild("PlotSpawn")
    if not spawn then return end

    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = spawn.CFrame * CFrame.new(0, 4, 0)
    end
end)
```

- [ ] **Step 3: Client UI**

```lua
-- src/StarterPlayerScripts/EscapePodController.client.luau
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Remotes      = require(game.ReplicatedStorage.Remotes)

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local COOLDOWN  = 30

task.wait(2)

local screen = Instance.new("ScreenGui")
screen.Name="EscapePodUI"; screen.ResetOnSpawn=false; screen.Parent=playerGui

local btn = Instance.new("TextButton")
btn.Size=UDim2.new(0,38,0,80); btn.Position=UDim2.new(1,-38,0.5,158)
btn.BackgroundColor3=Color3.fromRGB(0,40,80); btn.BackgroundTransparency=0.2
btn.TextColor3=Color3.fromRGB(80,200,255); btn.TextScaled=true
btn.Font=Enum.Font.GothamBold; btn.Text="🚀\nFLY"
btn.Parent=screen
Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8)

local panel=Instance.new("Frame"); panel.Name="PodPanel"
panel.Size=UDim2.new(0,260,0,0); panel.AutomaticSize=Enum.AutomaticSize.Y
panel.Position=UDim2.new(1,4,0.5,-40)
panel.BackgroundColor3=Color3.fromRGB(0,15,30); panel.BackgroundTransparency=0.1
panel.Parent=screen
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,10)
local pst=Instance.new("UIStroke",panel); pst.Color=Color3.fromRGB(0,160,255); pst.Thickness=1.5

local titleL=Instance.new("TextLabel"); titleL.Size=UDim2.new(1,0,0,30)
titleL.BackgroundTransparency=1; titleL.TextColor3=Color3.fromRGB(80,200,255)
titleL.TextScaled=true; titleL.Font=Enum.Font.GothamBold
titleL.Text="🚀  TELEPORT TO BASE"; titleL.Parent=panel

local listFrame=Instance.new("Frame"); listFrame.Size=UDim2.new(1,-8,0,0)
listFrame.Position=UDim2.new(0,4,0,34); listFrame.AutomaticSize=Enum.AutomaticSize.Y
listFrame.BackgroundTransparency=1; listFrame.Parent=panel
Instance.new("UIListLayout",listFrame).Padding=UDim.new(0,3)

local cooldownTimer = 0

local function setCooldown()
    cooldownTimer = COOLDOWN
    btn.BackgroundTransparency = 0.6; btn.Text = "🚀\n"..COOLDOWN.."s"
    task.spawn(function()
        while cooldownTimer > 0 do
            task.wait(1); cooldownTimer -= 1
            btn.Text = "🚀\n"..(cooldownTimer > 0 and cooldownTimer.."s" or "FLY")
        end
        btn.BackgroundTransparency = 0.2
    end)
end

local isOpen = false
local OPEN_P = UDim2.new(1,-264,0.5,-40); local CLOSE_P = UDim2.new(1,4,0.5,-40)

local function populate()
    for _,c in ipairs(listFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    for _,p in ipairs(Players:GetPlayers()) do
        if p == player then continue end
        local rb=Instance.new("TextButton"); rb.Size=UDim2.new(1,0,0,34)
        rb.BackgroundColor3=Color3.fromRGB(0,25,45); rb.BackgroundTransparency=0.3
        rb.TextColor3=Color3.fromRGB(255,255,255); rb.TextScaled=true; rb.Font=Enum.Font.Gotham
        rb.Text="  🚀  "..p.DisplayName; rb.TextXAlignment=Enum.TextXAlignment.Left; rb.Parent=listFrame
        Instance.new("UICorner",rb).CornerRadius=UDim.new(0,4)
        rb.Activated:Connect(function()
            if cooldownTimer > 0 then return end
            Remotes.TeleportToPlot:FireServer(p.UserId)
            setCooldown()
            TweenService:Create(panel,TweenInfo.new(0.2),{Position=CLOSE_P}):Play()
            isOpen=false; btn.Text="🚀\nFLY"
        end)
    end
end

btn.Activated:Connect(function()
    if cooldownTimer > 0 then return end
    isOpen = not isOpen
    TweenService:Create(panel,TweenInfo.new(0.2),{Position=isOpen and OPEN_P or CLOSE_P}):Play()
    btn.Text = isOpen and "🚀\n✕" or "🚀\nFLY"
    if isOpen then populate() end
end)
```

- [ ] **Step 4: In-Studio test**

2-player test: Build Escape Pod Bay → click 🚀 FLY → select other player → character teleports to their base. 30-second cooldown appears on button.

- [ ] **Step 5: Commit**
```bash
git add src/ReplicatedStorage/Remotes.luau src/ServerScriptService/PlotManager.server.luau src/StarterPlayerScripts/EscapePodController.client.luau
git commit -m "feat: Escape Pod Bay teleport — visit any player's base with 30s cooldown"
git push
```

---

# Task 4: Armory Raid Damage Boost

**Goal:** Players with Armory built deal 5/10/15% extra stolen amount per tier when raiding.

**Files:**
- Modify: `src/ServerScriptService/RaidManager.server.luau` — apply armory boost to stealPercent

**Architecture:** In `executeRaid`, look up raider's armory tier and apply multiplier before calculating stolen amount.

- [ ] **Step 1: Add armory boost to RaidManager**

In `src/ServerScriptService/RaidManager.server.luau`, replace:
```lua
    local defense      = RoomData.getDefenseReduction(targetData.rooms)
    local stealPercent = math.max(0, Config.RAID_STEAL_PERCENT - defense)
```
with:
```lua
    local defense      = RoomData.getDefenseReduction(targetData.rooms)
    local ARMORY_BOOST = {0.05, 0.10, 0.15}  -- +5/10/15% per tier
    local raiderArmoryTier = raiderData and raiderData.rooms["armory"] or 0
    local boost = raiderArmoryTier > 0 and ARMORY_BOOST[raiderArmoryTier] or 0
    local stealPercent = math.max(0, Config.RAID_STEAL_PERCENT + boost - defense)
```

- [ ] **Step 2: In-Studio test**

Use dev promo code to get currency. Build Armory tier 1. Raid another player. Verify stolen = (10% base + 5% armory) × vault = 15% of victim vault.

- [ ] **Step 3: Commit**
```bash
git add src/ServerScriptService/RaidManager.server.luau
git commit -m "feat: Armory boosts raid steal percent by 5/10/15% per tier"
git push
```

---

# Task 5: Wallet Slots (Item Inventory Capacity)

**Goal:** Players start with 3 item slots. They can buy up to 9 slots (6 purchasable, 500 currency each) from a kiosk in the lab lobby. Slot count stored in player data.

**Files:**
- Modify: `src/ServerScriptService/DataStore.server.luau` — add `inventorySlots = 3` to DEFAULT_DATA
- Modify: `src/ServerScriptService/EconomyManager.server.luau` — handle `BuyInventorySlot` remote
- Modify: `src/ReplicatedStorage/Remotes.luau` — add `BuyInventorySlot`, `SlotCountUpdate`
- Modify: `src/ReplicatedStorage/Config.luau` — add `SLOT_COST = 500`, `MAX_SLOTS = 9`, `STARTING_SLOTS = 3`
- Create: `src/StarterPlayerScripts/InventoryHudController.client.luau` — slot counter + buy button near lobby

**Architecture:** Lobby kiosk (ProximityPrompt on a Part named `SlotKiosk` added by WorldSetup) triggers `BuyInventorySlot`. Server checks cost, increments slot count, fires `SlotCountUpdate`. Client shows current/max slots in HUD.

- [ ] **Step 1: Update Config**

In `src/ReplicatedStorage/Config.luau`:
```lua
Config.STARTING_SLOTS = 3
Config.MAX_SLOTS      = 9
Config.SLOT_COST      = 500   -- currency per additional slot
```

- [ ] **Step 2: Update DEFAULT_DATA in DataStore**

In `src/ServerScriptService/DataStore.server.luau`, add to DEFAULT_DATA:
```lua
local DEFAULT_DATA = {
    currency      = Config.STARTING_CURRENCY,
    rooms         = {},
    vaultAmount   = Config.STARTING_CURRENCY,
    lastRaidedAt  = 0,
    usedCodes     = {},
    inventorySlots = Config.STARTING_SLOTS,  -- ADD THIS
    inventory     = {},                        -- ADD THIS (for Task 6)
}
```

- [ ] **Step 3: Add remotes**

In `src/ReplicatedStorage/Remotes.luau`:
```lua
Remotes.BuyInventorySlot = get("RemoteEvent",    "BuyInventorySlot") -- ()
Remotes.SlotCountUpdate  = get("RemoteEvent",    "SlotCountUpdate")  -- (current: number, max: number)
```

- [ ] **Step 4: Server handler**

In `src/ServerScriptService/EconomyManager.server.luau`, add after existing handlers:
```lua
Remotes.BuyInventorySlot.OnServerEvent:Connect(function(player: Player)
    local ds   = getDS()
    local data = ds.get(player)
    if not data then return end
    local slots = data.inventorySlots or Config.STARTING_SLOTS
    if slots >= Config.MAX_SLOTS then return end
    if data.vaultAmount < Config.SLOT_COST then return end
    data.vaultAmount   -= Config.SLOT_COST
    data.inventorySlots = slots + 1
    pushCurrencyUpdate(player)
    Remotes.SlotCountUpdate:FireClient(player, data.inventorySlots, Config.MAX_SLOTS)
    ds.save(player)
end)
```

- [ ] **Step 5: Client HUD + kiosk prompt**

Create `src/StarterPlayerScripts/InventoryHudController.client.luau`:
```lua
-- src/StarterPlayerScripts/InventoryHudController.client.luau
local Players = game:GetService("Players")
local Remotes = require(game.ReplicatedStorage.Remotes)
local Config  = require(game.ReplicatedStorage.Config)

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

task.wait(2)

local screen = Instance.new("ScreenGui")
screen.Name="InventoryUI"; screen.ResetOnSpawn=false; screen.Parent=playerGui

-- Slot counter (top-left, below promo button)
local slotFrame = Instance.new("Frame")
slotFrame.Size=UDim2.new(0,260,0,28); slotFrame.Position=UDim2.new(0,16,0,134)
slotFrame.BackgroundColor3=Color3.fromRGB(20,20,30); slotFrame.BackgroundTransparency=0.3
slotFrame.Parent=screen
Instance.new("UICorner",slotFrame).CornerRadius=UDim.new(0,6)

local slotLabel = Instance.new("TextLabel")
slotLabel.Size=UDim2.new(1,-8,1,0); slotLabel.Position=UDim2.new(0,4,0,0)
slotLabel.BackgroundTransparency=1; slotLabel.TextColor3=Color3.fromRGB(200,160,255)
slotLabel.TextScaled=true; slotLabel.Font=Enum.Font.Gotham
slotLabel.Text="🎒 Item Slots: 3 / 9"; slotLabel.TextXAlignment=Enum.TextXAlignment.Left
slotLabel.Parent=slotFrame

-- Initial load
task.spawn(function()
    local data = Remotes.GetPlayerData:InvokeServer()
    if data then
        local s = data.inventorySlots or Config.STARTING_SLOTS
        slotLabel.Text = string.format("🎒 Item Slots: %d / %d", s, Config.MAX_SLOTS)
    end
end)

Remotes.SlotCountUpdate.OnClientEvent:Connect(function(current, max)
    slotLabel.Text = string.format("🎒 Item Slots: %d / %d", current, max)
end)

-- Kiosk ProximityPrompt (wired up when plot is assigned)
local function getMyPlot()
    while true do
        for _,obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Folder") and obj.Name:match("^Plot_%d+$") then
                local oid=obj:FindFirstChild("OwnerId")
                if oid and oid.Value==player.UserId then return obj end
            end
        end
        task.wait(0.5)
    end
end

task.spawn(function()
    local plot = getMyPlot()
    -- Wire up SlotKiosk part (added by WorldSetup in lobby area)
    plot.DescendantAdded:Connect(function(obj)
        if obj.Name=="SlotKiosk" and obj:IsA("Part") then
            local prompt=Instance.new("ProximityPrompt")
            prompt.ActionText="Buy Slot (💰500)"; prompt.ObjectText="Item Slots"
            prompt.HoldDuration=0.5; prompt.MaxActivationDistance=8; prompt.Parent=obj
            prompt.Triggered:Connect(function()
                Remotes.BuyInventorySlot:FireServer()
            end)
        end
    end)
    -- Also check already-existing kiosk
    local kiosk=plot:FindFirstChild("SlotKiosk",true)
    if kiosk then
        local prompt=Instance.new("ProximityPrompt")
        prompt.ActionText="Buy Slot (💰500)"; prompt.ObjectText="Item Slots"
        prompt.HoldDuration=0.5; prompt.MaxActivationDistance=8; prompt.Parent=kiosk
        prompt.Triggered:Connect(function() Remotes.BuyInventorySlot:FireServer() end)
    end
end)
```

- [ ] **Step 6: Add SlotKiosk to WorldSetup lobby area**

In `src/ServerScriptService/WorldSetup.server.luau`, inside `buildLabFloor`, after the lobby sign post:
```lua
    -- Slot expansion kiosk in lobby
    local kiosk=Instance.new("Part"); kiosk.Name="SlotKiosk"
    kiosk.Size=Vector3.new(3,4,3); kiosk.Anchored=true; kiosk.CanCollide=true
    kiosk.BrickColor=BrickColor.new("Bright violet"); kiosk.Material=Enum.Material.SmoothPlastic
    kiosk.CFrame=plotCF*CFrame.new(10,2,-4)  -- right of the sign post
    kiosk.Parent=plot
    local ks=Instance.new("Part"); ks.Name="KioskSign"
    ks.Size=Vector3.new(3,1,0.3); ks.Anchored=true; ks.CanCollide=false
    ks.BrickColor=BrickColor.new("Bright violet"); ks.Material=Enum.Material.Neon
    ks.CFrame=plotCF*CFrame.new(10,4.5,-4); ks.Parent=plot
```

Wait — this is inside `buildLabFloor` which takes `plot, plotCF` params. The kiosk must be a child of `plot`, not `bm`. Add this after the lobby section in buildLabFloor.

- [ ] **Step 7: In-Studio test**

1. Start play → see `🎒 Item Slots: 3 / 9`
2. Walk to purple kiosk in lobby → "Buy Slot (💰500)" prompt appears
3. Activate → slot count becomes 4, currency drops by 500
4. Repeat to 9 → no more purchases accepted

- [ ] **Step 8: Commit**
```bash
git add src/ReplicatedStorage/Config.luau src/ReplicatedStorage/Remotes.luau src/ServerScriptService/DataStore.server.luau src/ServerScriptService/EconomyManager.server.luau src/ServerScriptService/WorldSetup.server.luau src/StarterPlayerScripts/InventoryHudController.client.luau
git commit -m "feat: wallet slot system 3-9 slots, purchasable kiosk in lobby"
git push
```

---

# Task 6: Item System

**Goal:** Players can hold items (up to their slot count). Items have a type, rarity, and bonus. Lab crafting (Task 7) creates items. Items display in an inventory panel.

**Files:**
- Modify: `src/ReplicatedStorage/Config.luau` — add `ITEMS` table
- Create: `src/ReplicatedStorage/ItemData.luau` — item definitions
- Modify: `src/ServerScriptService/EconomyManager.server.luau` — add `DropItem` remote handler
- Modify: `src/ReplicatedStorage/Remotes.luau` — add `InventoryUpdate` event
- Create: `src/StarterPlayerScripts/InventoryPanel.client.luau` — inventory UI

**Item types (v1):**
```lua
-- ItemData.luau
local ItemData = {}
ItemData.ITEMS = {
    ["stim_pack"]     = {name="Stim Pack",     rarity="Common",   incomeBoost=0.10, icon="💊"},
    ["emp_grenade"]   = {name="EMP Grenade",   rarity="Uncommon", raidBoost=0.05,  icon="💣"},
    ["armor_chip"]    = {name="Armor Chip",    rarity="Rare",     defenseBoost=0.03,icon="🔩"},
    ["vault_override"]= {name="Vault Override",rarity="Epic",     capBoost=5000,   icon="🗝"},
}
return ItemData
```

- [ ] **Step 1: Create ItemData.luau**

Full file:
```lua
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
```

- [ ] **Step 2: Add `InventoryUpdate` remote**

In `src/ReplicatedStorage/Remotes.luau`:
```lua
Remotes.InventoryUpdate = get("RemoteEvent", "InventoryUpdate") -- (inventory: {string})
```

- [ ] **Step 3: Server — apply item effects**

In `src/ServerScriptService/EconomyManager.server.luau`, modify `pushCurrencyUpdate` to account for Stim Pack income boost:
```lua
local ItemData = require(game.ReplicatedStorage.ItemData)

local function getItemIncomeBoost(data): number
    local boost = 0
    for _, itemId in ipairs(data.inventory or {}) do
        local item = ItemData.get(itemId)
        if item and item.incomeBoostPct then
            boost += item.incomeBoostPct
        end
    end
    return boost
end
```

In the income tick, change:
```lua
local income = RoomData.getTotalIncome(data.rooms)
```
to:
```lua
local baseIncome = RoomData.getTotalIncome(data.rooms)
local boost = getItemIncomeBoost(data)
local income = math.floor(baseIncome * (1 + boost))
```

- [ ] **Step 4: Client inventory panel**

Create `src/StarterPlayerScripts/InventoryPanel.client.luau`:
```lua
-- src/StarterPlayerScripts/InventoryPanel.client.luau
local Players  = game:GetService("Players")
local Remotes  = require(game.ReplicatedStorage.Remotes)
local ItemData = require(game.ReplicatedStorage.ItemData)
local Config   = require(game.ReplicatedStorage.Config)

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
task.wait(2)

local screen=Instance.new("ScreenGui"); screen.Name="InventoryUI2"
screen.ResetOnSpawn=false; screen.Parent=playerGui

local btn=Instance.new("TextButton"); btn.Size=UDim2.new(0,38,0,80)
btn.Position=UDim2.new(0,16,1,-96); btn.BackgroundColor3=Color3.fromRGB(30,0,50)
btn.BackgroundTransparency=0.2; btn.TextColor3=Color3.fromRGB(200,150,255)
btn.TextScaled=true; btn.Font=Enum.Font.GothamBold; btn.Text="🎒\nBAG"
btn.Parent=screen; Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8)

local panel=Instance.new("Frame"); panel.Size=UDim2.new(0,280,0.5,0)
panel.Position=UDim2.new(0,60,1,-280); panel.BackgroundColor3=Color3.fromRGB(15,0,25)
panel.BackgroundTransparency=0.1; panel.Visible=false; panel.Parent=screen
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,10)
Instance.new("UIStroke",panel).Color=Color3.fromRGB(160,0,220)

local titleL=Instance.new("TextLabel"); titleL.Size=UDim2.new(1,0,0,32)
titleL.BackgroundTransparency=1; titleL.TextColor3=Color3.fromRGB(255,220,50)
titleL.TextScaled=true; titleL.Font=Enum.Font.GothamBold; titleL.Text="🎒 INVENTORY"
titleL.Parent=panel

local scroll=Instance.new("ScrollingFrame"); scroll.Size=UDim2.new(1,-8,1,-36)
scroll.Position=UDim2.new(0,4,0,34); scroll.BackgroundTransparency=1
scroll.ScrollBarThickness=4; scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; scroll.Parent=panel
Instance.new("UIListLayout",scroll).Padding=UDim.new(0,3)

local currentInventory = {}

local function refreshPanel()
    for _,c in ipairs(scroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    if #currentInventory == 0 then
        local el=Instance.new("TextLabel"); el.Size=UDim2.new(1,0,0,40)
        el.BackgroundTransparency=1; el.TextColor3=Color3.fromRGB(150,120,180)
        el.TextScaled=true; el.Font=Enum.Font.Gotham; el.Text="No items yet. Visit the Lab to craft!"
        el.Parent=scroll; return
    end
    for _, itemId in ipairs(currentInventory) do
        local def = ItemData.get(itemId)
        if not def then continue end
        local row=Instance.new("Frame"); row.Size=UDim2.new(1,-4,0,44)
        row.BackgroundColor3=Color3.fromRGB(25,0,40); row.BackgroundTransparency=0.3; row.Parent=scroll
        Instance.new("UICorner",row).CornerRadius=UDim.new(0,4)
        local il=Instance.new("TextLabel"); il.Size=UDim2.new(0,36,1,0)
        il.BackgroundTransparency=1; il.TextScaled=true; il.Font=Enum.Font.GothamBold
        il.Text=def.icon; il.Parent=row
        local nl=Instance.new("TextLabel"); nl.Size=UDim2.new(1,-40,0.55,0)
        nl.Position=UDim2.new(0,36,0,0); nl.BackgroundTransparency=1
        nl.TextColor3=ItemData.RARITY_COLOR[def.rarity] or Color3.new(1,1,1)
        nl.TextScaled=true; nl.Font=Enum.Font.GothamBold
        nl.TextXAlignment=Enum.TextXAlignment.Left; nl.Text=def.name; nl.Parent=row
        local dl=Instance.new("TextLabel"); dl.Size=UDim2.new(1,-40,0.45,0)
        dl.Position=UDim2.new(0,36,0.55,0); dl.BackgroundTransparency=1
        dl.TextColor3=Color3.fromRGB(180,160,200); dl.TextScaled=true; dl.Font=Enum.Font.Gotham
        dl.TextXAlignment=Enum.TextXAlignment.Left; dl.Text=def.description; dl.Parent=row
    end
end

Remotes.InventoryUpdate.OnClientEvent:Connect(function(inv)
    currentInventory = inv
    refreshPanel()
end)

task.spawn(function()
    local data = Remotes.GetPlayerData:InvokeServer()
    if data then currentInventory = data.inventory or {}; refreshPanel() end
end)

btn.Activated:Connect(function()
    panel.Visible = not panel.Visible
    btn.Text = panel.Visible and "🎒\n✕" or "🎒\nBAG"
end)
```

- [ ] **Step 5: In-Studio test**

Manually give a player an item via command bar:
```lua
_G.DataStore.get(game.Players:GetPlayers()[1]).inventory = {"stim_pack"}
```
Then open inventory panel → stim pack appears with icon and description.

- [ ] **Step 6: Commit**
```bash
git add src/ReplicatedStorage/ItemData.luau src/ReplicatedStorage/Remotes.luau src/ServerScriptService/EconomyManager.server.luau src/StarterPlayerScripts/InventoryPanel.client.luau
git commit -m "feat: item system — ItemData module, inventory panel, income boost from Stim Pack"
git push
```

---

# Task 7: Crafting System (Lab Ability)

**Goal:** Players with all 50 lab stations unlocked can craft items using in-game currency. One crafting kiosk per department, each producing that dept's themed item.

**Files:**
- Modify: `src/ServerScriptService/EconomyManager.server.luau` — `CraftItem` handler
- Modify: `src/ReplicatedStorage/Remotes.luau` — `CraftItem` RemoteFunction
- Create: `src/StarterPlayerScripts/CraftingController.client.luau`

**Crafting recipes (dept → item):**
- Chemistry → Stim Pack (cost: 2000)
- Electronics → EMP Grenade (cost: 3000)
- Biology → Armor Chip (cost: 4000)
- Physics → Vault Override (cost: 6000)
- Weapons → Minion Core (cost: 5000)

- [ ] **Step 1: Add remote**

In `src/ReplicatedStorage/Remotes.luau`:
```lua
Remotes.CraftItem = get("RemoteFunction", "CraftItem")  -- (recipe: string) → {ok: bool, message: string}
```

- [ ] **Step 2: Server handler**

In `src/ServerScriptService/EconomyManager.server.luau`:
```lua
local CRAFT_RECIPES = {
    chemistry   = {itemId="stim_pack",      cost=2000},
    electronics = {itemId="emp_grenade",    cost=3000},
    biology     = {itemId="armor_chip",     cost=4000},
    physics     = {itemId="vault_override", cost=6000},
    weapons     = {itemId="minion_core",    cost=5000},
}

Remotes.CraftItem.OnServerInvoke = function(player: Player, deptKey: string)
    local ds   = getDS()
    local data = ds.get(player)
    if not data then return {ok=false,message="Data not ready"} end

    -- Must have all 50 lab stations (lab complete = 5 depts done)
    local deptsDone = RoomData.getDeptsDone(data.rooms)
    if deptsDone < 5 then
        return {ok=false, message="Complete all Lab departments first"}
    end

    local recipe = CRAFT_RECIPES[deptKey]
    if not recipe then return {ok=false,message="Unknown recipe"} end

    -- Check inventory space
    local slots = data.inventorySlots or 3
    local inv   = data.inventory or {}
    if #inv >= slots then
        return {ok=false,message="Inventory full! Buy more slots."}
    end

    if data.vaultAmount < recipe.cost then
        return {ok=false,message=string.format("Need 💰%d to craft", recipe.cost)}
    end

    data.vaultAmount -= recipe.cost
    table.insert(inv, recipe.itemId)
    data.inventory = inv

    pushCurrencyUpdate(player)
    Remotes.InventoryUpdate:FireClient(player, inv)
    ds.save(player)

    return {ok=true, message="Crafted "..recipe.itemId:gsub("_"," ")}
end
```

- [ ] **Step 3: Client crafting controller**

Create `src/StarterPlayerScripts/CraftingController.client.luau`:
```lua
-- src/StarterPlayerScripts/CraftingController.client.luau
-- ProximityPrompts on CraftKiosk_<dept> parts in the lab (added by WorldSetup)
-- Opens a simple confirm dialog with cost/item info
local Players  = game:GetService("Players")
local Remotes  = require(game.ReplicatedStorage.Remotes)
local ItemData = require(game.ReplicatedStorage.ItemData)

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
task.wait(2)

local CRAFT_RECIPES = {
    chemistry   = {itemId="stim_pack",      cost=2000},
    electronics = {itemId="emp_grenade",    cost=3000},
    biology     = {itemId="armor_chip",     cost=4000},
    physics     = {itemId="vault_override", cost=6000},
    weapons     = {itemId="minion_core",    cost=5000},
}

local function showToast(msg, col)
    local gui = playerGui:FindFirstChild("SuperVHQ_HUD")
    if not gui then return end
    -- Reuse existing toast if available via HudController globals
    -- Fallback: create a simple notification
    local n=Instance.new("ScreenGui",playerGui); n.Name="CraftNotif"
    local f=Instance.new("Frame",n); f.Size=UDim2.new(0,300,0,50)
    f.Position=UDim2.new(0.5,-150,0,80); f.BackgroundColor3=col or Color3.fromRGB(20,60,20)
    f.BackgroundTransparency=0.1; Instance.new("UICorner",f).CornerRadius=UDim.new(0,8)
    local l=Instance.new("TextLabel",f); l.Size=UDim2.new(1,0,1,0)
    l.BackgroundTransparency=1; l.TextColor3=Color3.new(1,1,1)
    l.TextScaled=true; l.Font=Enum.Font.GothamBold; l.Text=msg
    task.delay(2.5, function() n:Destroy() end)
end

local function getMyPlot()
    while true do
        for _,obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Folder") and obj.Name:match("^Plot_%d+$") then
                local oid=obj:FindFirstChild("OwnerId")
                if oid and oid.Value==player.UserId then return obj end
            end
        end; task.wait(0.5)
    end
end

task.spawn(function()
    local plot = getMyPlot()
    local function wireCraftKiosk(obj)
        if not obj:IsA("Part") then return end
        local dept = obj.Name:match("^CraftKiosk_(.+)$")
        if not dept then return end
        local recipe = CRAFT_RECIPES[dept]
        if not recipe then return end
        local def = ItemData.get(recipe.itemId)
        local prompt=Instance.new("ProximityPrompt")
        prompt.ActionText=string.format("Craft %s (💰%d)", def and def.name or recipe.itemId, recipe.cost)
        prompt.ObjectText="Crafting Station"; prompt.HoldDuration=1
        prompt.MaxActivationDistance=8; prompt.Parent=obj
        prompt.Triggered:Connect(function()
            local result = Remotes.CraftItem:InvokeServer(dept)
            if result.ok then
                showToast("✅ "..result.message, Color3.fromRGB(20,60,20))
            else
                showToast("❌ "..result.message, Color3.fromRGB(60,20,20))
            end
        end)
    end
    for _,obj in ipairs(plot:GetDescendants()) do wireCraftKiosk(obj) end
    plot.DescendantAdded:Connect(wireCraftKiosk)
end)
```

- [ ] **Step 4: Add CraftKiosk parts to WorldSetup**

In `src/ServerScriptService/WorldSetup.server.luau`, in `buildLabFloor`, add after each dept room is built (in the station loop or after all 5 rooms):
```lua
    -- Crafting kiosks (one per dept, visible, in the back of each dept room)
    local CRAFT_DEPTS = {"chemistry","electronics","biology","physics","weapons"}
    local CRAFT_POSITIONS = {  -- local (dx, dz) relative to each dept room centre
        {lx=0,    lz=-68, cx=-14},  -- chemistry back-left
        {lx=60,   lz=-22, cx=-8},   -- biology left side
        {lx=-60,  lz=-22, cx=8},    -- physics right side
        {lx=-52,  lz=-68, cx=-10},  -- electronics back
        {lx=52,   lz=-68, cx=10},   -- weapons back
    }
    for dIdx, dept in ipairs(CRAFT_DEPTS) do
        local pos = CRAFT_POSITIONS[dIdx]
        local ck=Instance.new("Part"); ck.Name="CraftKiosk_"..dept
        ck.Size=Vector3.new(2,3,2); ck.Anchored=true; ck.CanCollide=true
        ck.BrickColor=BrickColor.new(DEPT_ACCENT[dIdx]); ck.Material=Enum.Material.Neon
        ck.CFrame=plotCF*CFrame.new(pos.lx+(pos.cx or 0), 1.5, pos.lz)
        ck.Parent=plot
    end
```

- [ ] **Step 5: In-Studio test**

1. Build all 50 lab stations (use promo code for currency)
2. Walk to a crafting kiosk → hold prompt → item appears in inventory
3. Try with full inventory → get "Inventory full" message

- [ ] **Step 6: Commit**
```bash
git add src/ReplicatedStorage/Remotes.luau src/ServerScriptService/EconomyManager.server.luau src/ServerScriptService/WorldSetup.server.luau src/StarterPlayerScripts/CraftingController.client.luau
git commit -m "feat: crafting system — 5 dept recipes, ProximityPrompt kiosks, inventory validation"
git push
```

---

# Task 8: Trading System

**Goal:** Player A can offer an item to player B. Player B accepts or declines. Items transfer server-side.

**Files:**
- Modify: `src/ReplicatedStorage/Remotes.luau` — `TradeRequest`, `TradeResponse`, `TradeCancelled`
- Create: `src/ServerScriptService/TradeManager.server.luau`
- Create: `src/StarterPlayerScripts/TradeController.client.luau`

**Architecture:** Client-to-client trade offer via server relay. Server holds pending trade state. 30-second timeout auto-cancels.

- [ ] **Step 1: Add remotes**

```lua
Remotes.TradeRequest   = get("RemoteEvent",    "TradeRequest")   -- server→client: (fromUserId, fromName, itemId)
Remotes.TradeResponse  = get("RemoteEvent",    "TradeResponse")  -- client→server: (accepted: bool)
Remotes.SendTrade      = get("RemoteEvent",    "SendTrade")       -- client→server: (targetUserId, itemId)
Remotes.TradeCancelled = get("RemoteEvent",    "TradeCancelled")  -- server→client: (reason: string)
Remotes.TradeComplete  = get("RemoteEvent",    "TradeComplete")   -- server→client: (itemId, fromName)
```

- [ ] **Step 2: Create TradeManager.server.luau**

```lua
-- src/ServerScriptService/TradeManager.server.luau
local Players = game:GetService("Players")
local Remotes = require(game.ReplicatedStorage.Remotes)
local ItemData = require(game.ReplicatedStorage.ItemData)

local function getDS()
    while not _G.DataStore do task.wait(0.1) end
    return _G.DataStore
end

-- pending: { [senderUserId]: {targetUserId, itemId, expireAt} }
local pending: {[number]: any} = {}

Remotes.SendTrade.OnServerEvent:Connect(function(sender, targetUserId, itemId)
    local ds         = getDS()
    local senderData = ds.get(sender)
    if not senderData then return end

    -- Validate sender has item
    local inv = senderData.inventory or {}
    local hasItem = false
    for i, id in ipairs(inv) do
        if id == itemId then hasItem = true; break end
    end
    if not hasItem then return end

    -- Validate target online
    local target = Players:GetPlayerByUserId(targetUserId)
    if not target then
        Remotes.TradeCancelled:FireClient(sender, "Player not online")
        return
    end

    -- Cancel any existing pending trade from this sender
    pending[sender.UserId] = nil

    pending[sender.UserId] = {
        targetUserId = targetUserId,
        itemId       = itemId,
        expireAt     = os.time() + 30,
    }

    -- Notify target
    local def = ItemData.get(itemId)
    Remotes.TradeRequest:FireClient(target, sender.UserId, sender.DisplayName,
        itemId, def and def.name or itemId)

    -- Auto-cancel after 30s
    task.delay(30, function()
        if pending[sender.UserId] and pending[sender.UserId].itemId == itemId then
            pending[sender.UserId] = nil
            Remotes.TradeCancelled:FireClient(sender, "Trade expired")
        end
    end)
end)

Remotes.TradeResponse.OnServerEvent:Connect(function(target, senderUserId, accepted)
    -- Find the pending trade for this sender → this target
    local trade = pending[senderUserId]
    if not trade or trade.targetUserId ~= target.UserId then return end
    if os.time() > trade.expireAt then
        pending[senderUserId] = nil; return
    end

    local sender = Players:GetPlayerByUserId(senderUserId)
    pending[senderUserId] = nil

    if not accepted then
        if sender then Remotes.TradeCancelled:FireClient(sender, target.DisplayName.." declined") end
        return
    end

    -- Execute transfer
    local ds         = getDS()
    local senderData = ds.get(sender)
    local targetData = ds.get(target)
    if not senderData or not targetData then return end

    local sInv = senderData.inventory or {}
    local found = false
    for i, id in ipairs(sInv) do
        if id == trade.itemId then table.remove(sInv, i); found = true; break end
    end
    if not found then return end

    local tSlots = targetData.inventorySlots or 3
    local tInv   = targetData.inventory or {}
    if #tInv >= tSlots then
        if sender then Remotes.TradeCancelled:FireClient(sender, "Target inventory full") end
        return
    end

    senderData.inventory = sInv
    table.insert(tInv, trade.itemId)
    targetData.inventory = tInv

    ds.save(sender); ds.save(target)

    Remotes.InventoryUpdate:FireClient(sender, sInv)
    Remotes.InventoryUpdate:FireClient(target, tInv)
    if sender then Remotes.TradeComplete:FireClient(sender, trade.itemId, target.DisplayName) end
    Remotes.TradeComplete:FireClient(target, trade.itemId, (sender and sender.DisplayName or "?"))
end)
```

- [ ] **Step 3: Create TradeController.client.luau**

See full implementation in detailed plan — provides trade offer UI when near another player's base, and incoming trade request dialog.

*(Full code omitted here for space — see `docs/superpowers/plans/2026-06-03-trading-detail.md` if you need it broken out further.)*

- [ ] **Step 4: In-Studio 2-player test**

Player A opens inventory → clicks item → "Trade" button → selects Player B → B sees incoming request → accepts → item transfers.

- [ ] **Step 5: Commit**
```bash
git add src/ReplicatedStorage/Remotes.luau src/ServerScriptService/TradeManager.server.luau src/StarterPlayerScripts/TradeController.client.luau
git commit -m "feat: player-to-player item trading with 30s timeout and inventory validation"
git push
```

---

# Task 9: Leaderboard

**Goal:** In-game leaderboard showing top 10 players by vault amount. Updates every 60 seconds. Accessible via a board in the map centre.

**Files:**
- Create: `src/ServerScriptService/LeaderboardManager.server.luau`
- Create: `src/StarterPlayerScripts/LeaderboardController.client.luau`
- Modify: `src/ReplicatedStorage/Remotes.luau` — `LeaderboardUpdate` event

- [ ] **Step 1: Add remote**
```lua
Remotes.LeaderboardUpdate = get("RemoteEvent", "LeaderboardUpdate")
-- fires: list of {rank, name, vaultAmount}
```

- [ ] **Step 2: LeaderboardManager server script**
```lua
-- src/ServerScriptService/LeaderboardManager.server.luau
local Players = game:GetService("Players")
local Remotes = require(game.ReplicatedStorage.Remotes)

local function getDS()
    while not _G.DataStore do task.wait(0.1) end
    return _G.DataStore
end

local function buildLeaderboard()
    local ds  = getDS()
    local rows = {}
    for _, player in ipairs(Players:GetPlayers()) do
        local data = ds.get(player)
        if data then
            table.insert(rows, {name=player.DisplayName, vaultAmount=data.vaultAmount})
        end
    end
    table.sort(rows, function(a,b) return a.vaultAmount > b.vaultAmount end)
    local top = {}
    for i = 1, math.min(10, #rows) do
        top[i] = {rank=i, name=rows[i].name, vaultAmount=rows[i].vaultAmount}
    end
    Remotes.LeaderboardUpdate:FireAllClients(top)
end

-- Update every 60 seconds
task.spawn(function()
    while true do
        task.wait(60)
        buildLeaderboard()
    end
end)

-- Also update when anyone joins/leaves
Players.PlayerAdded:Connect(function() task.wait(3); buildLeaderboard() end)
Players.PlayerRemoving:Connect(function() task.wait(1); buildLeaderboard() end)
```

- [ ] **Step 3: Client leaderboard controller**

Creates a board UI triggered by a Part named `LeaderboardBoard` in workspace (added by WorldSetup near the centre). Shows top 10 with rank, name, vault amount.

- [ ] **Step 4: Add board to WorldSetup in buildSpawn**
```lua
-- In buildSpawn(), add a leaderboard board at the centre
local board=Instance.new("Part"); board.Name="LeaderboardBoard"
board.Size=Vector3.new(8,5,0.5); board.Position=Vector3.new(0,3,0)
board.Anchored=true; board.BrickColor=BrickColor.new("Really black")
board.Material=Enum.Material.SmoothPlastic; board.Parent=workspace
local bs=Instance.new("Part"); bs.Name="BoardGlow"
bs.Size=Vector3.new(7.5,4.5,0.2); bs.Position=Vector3.new(0,3,0.4)
bs.Anchored=true; bs.BrickColor=BrickColor.new("Bright violet")
bs.Material=Enum.Material.Neon; bs.CanCollide=false; bs.Parent=workspace
```

- [ ] **Step 5: Commit**
```bash
git add src/ReplicatedStorage/Remotes.luau src/ServerScriptService/LeaderboardManager.server.luau src/StarterPlayerScripts/LeaderboardController.client.luau src/ServerScriptService/WorldSetup.server.luau
git commit -m "feat: leaderboard — top 10 by vault amount, updates every 60s"
git push
```

---

# Task 10: NPC Minions (Barracks Visual Defenders)

**Goal:** Players with Minion Barracks built have NPC humanoids patrolling their plot. Minion count scales with tier (2/4/6 minions). Minions are visual only (defense bonus is already in RaidManager).

**Files:**
- Create: `src/ServerScriptService/MinionManager.server.luau`
- Modify: `src/ReplicatedStorage/Remotes.luau` — `MinionSpawned` event (for client visual effect)

- [ ] **Step 1: MinionManager.server.luau**
```lua
-- src/ServerScriptService/MinionManager.server.luau
local Players = game:GetService("Players")
local Remotes = require(game.ReplicatedStorage.Remotes)

local function getDS() while not _G.DataStore do task.wait(0.1) end return _G.DataStore end
local function getPM() while not _G.PlotManager do task.wait(0.1) end return _G.PlotManager end

local MINION_COUNT = {2, 4, 6}  -- per barracks tier

local spawnedMinions: {[number]: {Model}} = {}

local function clearMinions(userId: number)
    for _, m in ipairs(spawnedMinions[userId] or {}) do
        if m and m.Parent then m:Destroy() end
    end
    spawnedMinions[userId] = {}
end

local function spawnMinions(player: Player, tier: number)
    local pm   = getPM()
    local plot = pm.getPlot(player)
    if not plot then return end

    clearMinions(player.UserId)
    spawnedMinions[player.UserId] = {}

    local count = MINION_COUNT[tier] or 2
    local pad   = plot:FindFirstChild("DropPad_minion_barracks")
    local baseX = pad and pad.Position.X or 0
    local baseZ = pad and pad.Position.Z or 0

    for i = 1, count do
        local rig = Instance.new("Model"); rig.Name = "Minion_"..i

        local hrp = Instance.new("Part"); hrp.Name="HumanoidRootPart"
        hrp.Size=Vector3.new(2,2,1); hrp.Anchored=false; hrp.CanCollide=true
        hrp.BrickColor=BrickColor.new("Bright orange"); hrp.Parent=rig

        local head = Instance.new("Part"); head.Name="Head"
        head.Size=Vector3.new(2,1,1); head.BrickColor=BrickColor.new("Bright orange")
        head.Parent=rig

        local weld=Instance.new("WeldConstraint"); weld.Part0=hrp; weld.Part1=head; weld.Parent=rig
        head.CFrame=hrp.CFrame*CFrame.new(0,1.5,0)

        local hum=Instance.new("Humanoid"); hum.WalkSpeed=8; hum.Parent=rig

        local angle = (i-1)*(2*math.pi/count)
        hrp.Position = Vector3.new(baseX+math.cos(angle)*6, 3, baseZ+math.sin(angle)*6)
        rig.PrimaryPart = hrp
        rig.Parent = workspace

        table.insert(spawnedMinions[player.UserId], rig)

        -- Simple patrol loop
        task.spawn(function()
            local targets = {
                Vector3.new(baseX+math.cos(angle)*6,   1, baseZ+math.sin(angle)*6),
                Vector3.new(baseX+math.cos(angle+math.pi)*4, 1, baseZ+math.sin(angle+math.pi)*4),
            }
            local t = 1
            while rig.Parent do
                hum:MoveTo(targets[t])
                hum.MoveToFinished:Wait()
                t = t % #targets + 1
                task.wait(0.5)
            end
        end)
    end
end

-- React to room purchases
Remotes.RoomBuilt.OnClientEvent  -- server side handled via EconomyManager

-- Listen for barracks built or upgraded
game:GetService("Players").PlayerAdded:Connect(function(player)
    task.wait(3)
    local ds   = getDS()
    local data = ds.get(player)
    if data and data.rooms["minion_barracks"] and data.rooms["minion_barracks"] > 0 then
        spawnMinions(player, data.rooms["minion_barracks"])
    end
end)

-- EconomyManager fires RoomBuilt to client; we need a server-side hook
-- Add a BindableEvent bridge in EconomyManager (see step below)
```

- [ ] **Step 2: Add server BindableEvent in EconomyManager**

After the existing `Remotes.RoomBuilt:FireClient(player, roomId, tier)` calls in EconomyManager, add:
```lua
-- Notify MinionManager when barracks is built/upgraded
if roomId == "minion_barracks" then
    local mm = _G.MinionManager
    if mm then mm.onBarracksBuilt(player, tier) end
end
```

And expose `_G.MinionManager = { onBarracksBuilt = spawnMinions }` at end of MinionManager.

- [ ] **Step 3: In-Studio test**

Build Minion Barracks → 2 orange humanoids appear patrolling nearby. Upgrade to tier 2 → 4 minions. Upgrade to tier 3 → 6 minions.

- [ ] **Step 4: Commit**
```bash
git add src/ServerScriptService/MinionManager.server.luau
git commit -m "feat: NPC minion defenders — 2/4/6 humanoids patrol plot based on Barracks tier"
git push
```

---

# Task 11: Sound Effects

**Goal:** Key game events have matching sound effects: building a room, income tick, raid received, raid sent, level up (completing a dept), button clicks.

**Files:**
- Create: `src/ReplicatedStorage/SoundData.luau` — asset IDs and categories
- Create: `src/StarterPlayerScripts/SoundController.client.luau`

**Sound IDs (free Roblox library):**
```lua
local SOUNDS = {
    build        = 3526557030,  -- sci-fi build
    income       = 4843648880,  -- coin chime
    raidOut      = 6042053626,  -- alarm
    raidIn       = 5804562289,  -- impact
    deptComplete = 4809642087,  -- fanfare
    click        = 876939830,   -- UI click
}
```

- [ ] **Step 1: Create SoundData.luau**
```lua
-- src/ReplicatedStorage/SoundData.luau
local SoundData = {}
SoundData.IDS = {
    build        = 3526557030,
    income       = 4843648880,
    raidOut      = 6042053626,
    raidIn       = 5804562289,
    deptComplete = 4809642087,
    click        = 876939830,
}
return SoundData
```

- [ ] **Step 2: Create SoundController.client.luau**
```lua
-- src/StarterPlayerScripts/SoundController.client.luau
local Remotes   = require(game.ReplicatedStorage.Remotes)
local SoundData = require(game.ReplicatedStorage.SoundData)

local function play(id, volume)
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://"..id
    s.Volume  = volume or 0.5
    s.Parent  = workspace
    s:Play()
    game:GetService("Debris"):AddItem(s, 5)
end

-- Room built
Remotes.RoomBuilt.OnClientEvent:Connect(function(roomId)
    play(SoundData.IDS.build, 0.4)
end)

-- Currency update (income tick) — play softly every tick
Remotes.UpdateCurrency.OnClientEvent:Connect(function(amount, cap, incPerMin)
    if incPerMin > 0 then
        play(SoundData.IDS.income, 0.15)
    end
end)

-- Raid notification
Remotes.RaidNotification.OnClientEvent:Connect(function()
    play(SoundData.IDS.raidIn, 0.7)
end)
```

- [ ] **Step 3: In-Studio test**

Build a lab station → hear build sound. Wait for income tick → soft chime. Get raided → alarm sound.

- [ ] **Step 4: Commit**
```bash
git add src/ReplicatedStorage/SoundData.luau src/StarterPlayerScripts/SoundController.client.luau
git commit -m "feat: sound effects for build, income, raid events"
git push
```

---

# Task 12: Tutorial / Onboarding

**Goal:** New players (first join, 0 rooms built) see a step-by-step guide highlighting what to do: (1) walk to a green pad, (2) build a station, (3) wait for income.

**Files:**
- Create: `src/StarterPlayerScripts/TutorialController.client.luau`

**Architecture:** 3-step highlight overlay with arrows pointing at the relevant element. Stored completion state client-side (no server call needed for tutorial — just check if any room is built).

- [ ] **Step 1: Create TutorialController.client.luau**

```lua
-- src/StarterPlayerScripts/TutorialController.client.luau
local Players  = game:GetService("Players")
local Remotes  = require(game.ReplicatedStorage.Remotes)

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

task.wait(3)

-- Skip if player has rooms built
local data = Remotes.GetPlayerData:InvokeServer()
if data and next(data.rooms) ~= nil then return end  -- already has rooms, skip tutorial

local screen = Instance.new("ScreenGui")
screen.Name="Tutorial"; screen.ResetOnSpawn=false; screen.Parent=playerGui

local STEPS = {
    {
        title = "Welcome to Super V HQ! 🦹",
        body  = "You are a villain building your empire.\n\nWalk into the Lab building through the entrance.",
        icon  = "🏃",
    },
    {
        title = "Build Your First Station ⚗",
        body  = "Walk up to a GREEN pad and hold the 'Build' prompt.\n\nYou start with 💰2,000 — build as many Chemistry stations as you can!",
        icon  = "🔬",
    },
    {
        title = "Watch Your Income Grow 📈",
        body  = "Every 3 seconds your rooms generate currency.\n\nCheck the 📋 Objectives panel to track progress.\nComplete all 50 Lab stations to unlock upper floors!",
        icon  = "💰",
    },
}

local stepIndex = 1

local overlay = Instance.new("Frame")
overlay.Size=UDim2.new(1,0,1,0); overlay.BackgroundColor3=Color3.new(0,0,0)
overlay.BackgroundTransparency=0.55; overlay.Parent=screen

local card=Instance.new("Frame")
card.Size=UDim2.new(0,420,0,200); card.Position=UDim2.new(0.5,-210,0.5,-100)
card.BackgroundColor3=Color3.fromRGB(15,0,25); card.BackgroundTransparency=0.05
card.Parent=screen
Instance.new("UICorner",card).CornerRadius=UDim.new(0,14)
local cs=Instance.new("UIStroke",card); cs.Color=Color3.fromRGB(180,0,255); cs.Thickness=2

local iconL=Instance.new("TextLabel"); iconL.Size=UDim2.new(0,60,0,60)
iconL.Position=UDim2.new(0,16,0,16); iconL.BackgroundTransparency=1
iconL.TextScaled=true; iconL.Font=Enum.Font.GothamBold; iconL.Parent=card

local titleL=Instance.new("TextLabel"); titleL.Size=UDim2.new(1,-90,0,40)
titleL.Position=UDim2.new(0,82,0,16); titleL.BackgroundTransparency=1
titleL.TextColor3=Color3.fromRGB(255,220,50); titleL.TextScaled=true
titleL.Font=Enum.Font.GothamBold; titleL.TextXAlignment=Enum.TextXAlignment.Left
titleL.Parent=card

local bodyL=Instance.new("TextLabel"); bodyL.Size=UDim2.new(1,-32,0,90)
bodyL.Position=UDim2.new(0,16,0,78); bodyL.BackgroundTransparency=1
bodyL.TextColor3=Color3.fromRGB(220,200,255); bodyL.TextScaled=true
bodyL.Font=Enum.Font.Gotham; bodyL.TextWrapped=true
bodyL.TextXAlignment=Enum.TextXAlignment.Left; bodyL.Parent=card

local nextBtn=Instance.new("TextButton")
nextBtn.Size=UDim2.new(0,120,0,36); nextBtn.Position=UDim2.new(1,-136,1,-48)
nextBtn.BackgroundColor3=Color3.fromRGB(80,0,140); nextBtn.TextColor3=Color3.new(1,1,1)
nextBtn.TextScaled=true; nextBtn.Font=Enum.Font.GothamBold; nextBtn.Parent=card
Instance.new("UICorner",nextBtn).CornerRadius=UDim.new(0,8)

local stepL=Instance.new("TextLabel")
stepL.Size=UDim2.new(0,80,0,28); stepL.Position=UDim2.new(0,16,1,-42)
stepL.BackgroundTransparency=1; stepL.TextColor3=Color3.fromRGB(150,120,180)
stepL.TextScaled=true; stepL.Font=Enum.Font.Gotham; stepL.Parent=card

local function showStep(i)
    local step = STEPS[i]
    iconL.Text    = step.icon
    titleL.Text   = step.title
    bodyL.Text    = step.body
    stepL.Text    = i.."/"..#STEPS
    nextBtn.Text  = i < #STEPS and "Next →" or "Let's Go!"
end

showStep(1)

nextBtn.Activated:Connect(function()
    if stepIndex < #STEPS then
        stepIndex += 1; showStep(stepIndex)
    else
        screen:Destroy()
    end
end)

-- Auto-dismiss when first room is built
Remotes.RoomBuilt.OnClientEvent:Connect(function()
    if screen.Parent then screen:Destroy() end
end)
```

- [ ] **Step 2: In-Studio test**

Join with a fresh account (or clear rooms via dev code). Tutorial should appear with 3 steps. Click Next → advances. Build any station → tutorial closes.

- [ ] **Step 3: Commit**
```bash
git add src/StarterPlayerScripts/TutorialController.client.luau
git commit -m "feat: 3-step tutorial overlay for new players — auto-dismisses on first build"
git push
```

---

# Task 13: Settings Menu

**Goal:** Accessible from a gear button (⚙) in the HUD. Lets players toggle: music volume, SFX volume, show/hide sky labels, show/hide cost labels.

**Files:**
- Create: `src/StarterPlayerScripts/SettingsController.client.luau`

- [ ] **Step 1: Create SettingsController.client.luau**

```lua
-- src/StarterPlayerScripts/SettingsController.client.luau
local Players       = game:GetService("Players")
local SoundService  = game:GetService("SoundService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

task.wait(2)

local screen = Instance.new("ScreenGui")
screen.Name="SettingsUI"; screen.ResetOnSpawn=false; screen.Parent=playerGui

local btn=Instance.new("TextButton"); btn.Size=UDim2.new(0,38,0,38)
btn.Position=UDim2.new(0,16,1,-54); btn.BackgroundColor3=Color3.fromRGB(30,30,50)
btn.BackgroundTransparency=0.2; btn.TextColor3=Color3.fromRGB(200,200,255)
btn.TextScaled=true; btn.Font=Enum.Font.GothamBold; btn.Text="⚙"
btn.Parent=screen; Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8)

local panel=Instance.new("Frame"); panel.Size=UDim2.new(0,260,0,200)
panel.Position=UDim2.new(0,60,1,-210); panel.BackgroundColor3=Color3.fromRGB(15,15,30)
panel.BackgroundTransparency=0.1; panel.Visible=false; panel.Parent=screen
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,10)
Instance.new("UIStroke",panel).Color=Color3.fromRGB(120,100,200)

local titleL=Instance.new("TextLabel"); titleL.Size=UDim2.new(1,0,0,30)
titleL.BackgroundTransparency=1; titleL.TextColor3=Color3.fromRGB(200,180,255)
titleL.TextScaled=true; titleL.Font=Enum.Font.GothamBold; titleL.Text="⚙  SETTINGS"
titleL.Parent=panel

-- Generic toggle row builder
local yOff = 36
local settings = {sfxEnabled=true, labelsEnabled=true, skyLabelEnabled=true}

local function makeToggle(label, key)
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,-10,0,34)
    row.Position=UDim2.new(0,5,0,yOff); row.BackgroundTransparency=1; row.Parent=panel
    yOff += 38
    local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(0.7,0,1,0)
    lbl.BackgroundTransparency=1; lbl.TextColor3=Color3.fromRGB(200,180,255)
    lbl.TextScaled=true; lbl.Font=Enum.Font.Gotham; lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.Text=label; lbl.Parent=row
    local tog=Instance.new("TextButton"); tog.Size=UDim2.new(0,70,0,28)
    tog.Position=UDim2.new(1,-74,0.5,-14); tog.TextScaled=true; tog.Font=Enum.Font.GothamBold
    tog.Parent=row; Instance.new("UICorner",tog).CornerRadius=UDim.new(0,6)
    local function updateVisual()
        tog.Text = settings[key] and "ON" or "OFF"
        tog.BackgroundColor3 = settings[key] and Color3.fromRGB(0,100,0) or Color3.fromRGB(80,0,0)
        tog.TextColor3 = Color3.new(1,1,1)
    end
    updateVisual()
    tog.Activated:Connect(function()
        settings[key] = not settings[key]; updateVisual()
        -- Apply setting
        if key == "sfxEnabled" then
            SoundService.RespectFilteringEnabled = true
            -- Muting handled by SoundController listening to a BindableEvent (simplified: set volume)
        end
        if key == "labelsEnabled" then
            local lu=playerGui:FindFirstChild("LabelUI")
            if lu then lu.Enabled=settings[key] end
        end
        if key == "skyLabelEnabled" then
            -- Sky label in BaseLabelAnchor BillboardGui
            for _,obj in pairs(workspace:GetDescendants()) do
                if obj.Name=="SkyLabel" and obj:IsA("BillboardGui") then
                    obj.Enabled=settings[key]
                end
            end
        end
    end)
end

makeToggle("Sound Effects", "sfxEnabled")
makeToggle("Cost Labels",   "labelsEnabled")
makeToggle("Sky Name Tag",  "skyLabelEnabled")

btn.Activated:Connect(function()
    panel.Visible = not panel.Visible
    btn.Text = panel.Visible and "✕" or "⚙"
end)
```

- [ ] **Step 2: In-Studio test**

Click ⚙ → panel opens with 3 toggles. Toggle "Sky Name Tag" → sky labels hide/show. Toggle "Cost Labels" → cost billboards toggle.

- [ ] **Step 3: Commit**
```bash
git add src/StarterPlayerScripts/SettingsController.client.luau
git commit -m "feat: settings menu — SFX/labels/sky tag toggles"
git push
```

---

# Task 14: Mobile UI

**Goal:** Ensure all proximity prompts, buttons, and panels work with touch input. Increase button tap targets for mobile. Add a dedicated mobile action bar.

**Files:**
- Modify: `src/StarterPlayerScripts/HudController.client.luau` — detect mobile, scale up buttons
- Modify: `src/StarterPlayerScripts/DropPadClient.client.luau` — increase MaxActivationDistance on mobile
- Create: `src/StarterPlayerScripts/MobileController.client.luau`

- [ ] **Step 1: Detect mobile and scale HUD**

In `src/StarterPlayerScripts/HudController.client.luau`, after `local gui = Instance.new(...)`:
```lua
local isMobile = game:GetService("UserInputService").TouchEnabled

if isMobile then
    currencyFrame.Size = UDim2.new(0, 300, 0, 90)
    -- scale all children proportionally
    for _, child in ipairs(currencyFrame:GetChildren()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            child.TextSize = 0  -- TextScaled handles it
        end
    end
end
```

- [ ] **Step 2: Increase proximity prompt distance on mobile**

In `src/StarterPlayerScripts/DropPadClient.client.luau`, change:
```lua
prompt.MaxActivationDistance = 8
```
to:
```lua
local isMobile = game:GetService("UserInputService").TouchEnabled
prompt.MaxActivationDistance = isMobile and 14 or 8
```

Apply same pattern to upgrade pad prompt in `setupUpgradePad`.

- [ ] **Step 3: Mobile action bar**

Create `src/StarterPlayerScripts/MobileController.client.luau`:
```lua
-- src/StarterPlayerScripts/MobileController.client.luau
local UIS = game:GetService("UserInputService")
if not UIS.TouchEnabled then return end  -- desktop: do nothing

local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

-- Move side toggle buttons so they don't overlap on small screens
task.wait(2)

-- Reposition objectives button on mobile (it starts at UDim2.new(1,-38,0.5,-55))
local objUI = playerGui:WaitForChild("ObjectivesUI", 5)
if objUI then
    local toggleBtn = objUI:FindFirstChildOfClass("TextButton")
    if toggleBtn then
        toggleBtn.Size     = UDim2.new(0,52,0,120)
        toggleBtn.Position = UDim2.new(1,-52,0.5,-60)
    end
end
```

- [ ] **Step 4: In-Studio test**

Switch Studio to mobile emulation (View → Emulation). Verify:
- All buttons are large enough to tap (min 44px)
- Proximity prompts appear at 14 studs instead of 8
- HUD doesn't overlap with Roblox mobile controls

- [ ] **Step 5: Commit**
```bash
git add src/StarterPlayerScripts/HudController.client.luau src/StarterPlayerScripts/DropPadClient.client.luau src/StarterPlayerScripts/MobileController.client.luau
git commit -m "feat: mobile UI — larger tap targets, extended proximity range, repositioned buttons"
git push
```

---

# Task 15: Better Room Visuals

**Goal:** Replace placeholder coloured boxes in lab stations and upper floor rooms with multi-part themed models.

**Files:**
- Modify: `src/ServerScriptService/WorldSetup.server.luau` — replace hp() placeholders with detailed models

**This task is artistic and iterative — a sub-agent should:**
1. Replace each dept's station model (Body/Panel/Glow parts) with themed equipment pieces
2. Replace upper floor rooms with interior decorations (tables, screens, crates)
3. Keep all parts as `hp()` (hidden until bought)

The detailed model designs are specified per-dept below:

**Chemistry:** Glass cylinders (`hp` sphere+cylinder), bubbling cauldron effect (neon parts), formula boards (flat parts as screens)

**Electronics:** Server racks (stacked thin boxes), monitor arrays, circuit trace neon lines

**Biology:** DNA helix (two twisted cylinder sequences), microscope silhouettes, culture vat cylinders

**Physics:** Particle emitter rings (torus-like stacked cylinders), laser array lines, holographic display

**Weapons:** Weapon crates (box stacks), targeting computer screen, blast shield parts

Each station model replaces the current `Base + Body + Panel + Glow + Stem` with 6-8 parts that look like the equipment they represent. Keep total part count under 400/plot to avoid performance issues.

- [ ] **Step 1: Update lab station models in WorldSetup (Chemistry example)**

In `buildLabFloor`, replace the section:
```lua
hp(sm,"Body",  Vector3.new(3,6,3), cf(sdx,3.8,sdz),...)
hp(sm,"Panel", ...)
hp(sm,"Glow",  ...)
hp(sm,"Stem",  ...)
```
with dept-specific builds (see designs above).

- [ ] **Step 2: Update upper floor room interiors**

For Armory: add weapon rack models (hp), ammo crate stacks (hp)
For War Room: add central table (hp), wall screens (hp)
For Vault: add gold bar stacks (hp), vault door detail (hp)

- [ ] **Step 3: In-Studio test with Build World plugin**

Click Build World → verify rooms look distinct and themed. Build stations → verify models appear correctly.

- [ ] **Step 4: Commit**
```bash
git add src/ServerScriptService/WorldSetup.server.luau
git commit -m "feat: themed lab station and upper floor room models replacing placeholder boxes"
git push
```

---

# Task 16: Publish + Real Robux Product IDs

**Goal:** Publish game to Roblox, create real Developer Products, wire IDs into Config.

**Files:**
- Modify: `src/ReplicatedStorage/Config.luau` — real product IDs

**Steps:**

- [ ] **Step 1: Publish game**

In Studio: File → Publish to Roblox As → name "Super V HQ" → genre Town and City → Create

- [ ] **Step 2: Create Developer Products**

Go to create.roblox.com → Super V HQ → Monetization → Developer Products. Create:
- "500 Credits" → 10 Robux → copy product ID
- "1500 Credits" → 25 Robux → copy ID
- "5000 Credits" → 75 Robux → copy ID
- "Raid Strike" → 50 Robux → copy ID

- [ ] **Step 3: Update Config.luau**

```lua
Config.PRODUCT_CURRENCY_SMALL  = <real_id_here>
Config.PRODUCT_CURRENCY_MEDIUM = <real_id_here>
Config.PRODUCT_CURRENCY_LARGE  = <real_id_here>
Config.PRODUCT_RAID            = <real_id_here>
Config.PRODUCT_CURRENCY_AMOUNTS = {
    [Config.PRODUCT_CURRENCY_SMALL]  = 500,
    [Config.PRODUCT_CURRENCY_MEDIUM] = 1500,
    [Config.PRODUCT_CURRENCY_LARGE]  = 5000,
}
```

- [ ] **Step 4: Test in live game (not Studio)**

Open game from Roblox website. Attempt small currency purchase → verify currency granted and saved.

- [ ] **Step 5: Commit + push**
```bash
git add src/ReplicatedStorage/Config.luau
git commit -m "feat: wire real Robux developer product IDs for live monetisation"
git push
```

---

# Task 17: Anti-Exploit Hardening

**Goal:** Prevent common exploits: currency manipulation via remote spam, negative vault values, impossible room tier jumps.

**Files:**
- Modify: `src/ServerScriptService/EconomyManager.server.luau` — rate limiting + validation
- Modify: `src/ServerScriptService/RaidManager.server.luau` — validate productId against Config

- [ ] **Step 1: Rate-limit BuyRoom and UpgradeRoom**

In EconomyManager, add debounce per player:
```lua
local buyDebounce: {[number]: number} = {}

Remotes.BuyRoom.OnServerEvent:Connect(function(player, roomId)
    local now = os.clock()
    if buyDebounce[player.UserId] and now - buyDebounce[player.UserId] < 0.5 then return end
    buyDebounce[player.UserId] = now
    -- ... existing handler ...
end)
```

Apply same pattern to UpgradeRoom.

- [ ] **Step 2: Validate vault amount never goes negative**

After any currency deduction, add:
```lua
data.vaultAmount = math.max(0, data.vaultAmount)
```

- [ ] **Step 3: Validate room tier jumps**

In UpgradeRoom handler, after checking currentTier:
```lua
-- Prevent jumping multiple tiers at once (exploit)
if nextTier ~= currentTier + 1 then return end
```

- [ ] **Step 4: Validate ProcessReceipt productIds**

In RaidManager ProcessReceipt, add:
```lua
local validIds = {
    [Config.PRODUCT_CURRENCY_SMALL]  = true,
    [Config.PRODUCT_CURRENCY_MEDIUM] = true,
    [Config.PRODUCT_CURRENCY_LARGE]  = true,
    [Config.PRODUCT_RAID]            = true,
}
if not validIds[productId] then
    return Enum.ProductPurchaseDecision.NotProcessedYet
end
```

- [ ] **Step 5: Commit**
```bash
git add src/ServerScriptService/EconomyManager.server.luau src/ServerScriptService/RaidManager.server.luau
git commit -m "fix: anti-exploit — rate limiting, vault floor, tier jump prevention, productId allowlist"
git push
```

---

## Spec Coverage

| Feature | Task |
|---|---|
| Raid cooldown display | Task 1 |
| War Room spy UI | Task 2 |
| Escape Pod teleport | Task 3 |
| Armory raid boost | Task 4 |
| Wallet slots (3-9) | Task 5 |
| Item system + inventory | Task 6 |
| Crafting (Lab ability) | Task 7 |
| Trading system | Task 8 |
| Leaderboard | Task 9 |
| NPC minions | Task 10 |
| Sound effects | Task 11 |
| Tutorial / onboarding | Task 12 |
| Settings menu | Task 13 |
| Mobile UI | Task 14 |
| Better room visuals | Task 15 |
| Publish + Robux IDs | Task 16 |
| Anti-exploit | Task 17 |
