# Lab Animation + Building Overlap Fix — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix overlapping buildings with a stepped castle tower silhouette and a parapet separator ring, then add dynamic per-department animations to each lab room.

**Architecture:** Two files only. `WorldSetup.server.luau` gains stepped floor dimensions, a parapet ring at Y=14, and animated Attribute-tagged parts per dept. New `AnimationManager.client.luau` runs TweenService loops on any BasePart whose `AnimType` attribute is set — it watches workspace.DescendantAdded so newly-revealed (bought) station models automatically animate.

**Tech Stack:** Luau, Rojo, TweenService, Instance Attributes

---

## File Map

| File | Change |
|---|---|
| `src/ServerScriptService/WorldSetup.server.luau` | Stepped W/D per floor, parapet ring, 5× dept animated parts |
| `src/StarterPlayerScripts/AnimationManager.client.luau` | New — handles bob/spin/pulse/strobe/float animation types |

---

## ✅ Checkpoint 1 — Overlap Fix
> After Task 2: open `.rbxlx`, Build World, verify the tower visibly steps inward each floor and the stone parapet ring is visible at Y=14.

## ✅ Checkpoint 2 — Animations Working
> After Task 7: press Play, buy a lab station → animated parts appear and move/pulse/spin correctly.

---

## Task 1: Stepped upper-floor dimensions

**Files:**
- Modify: `src/ServerScriptService/WorldSetup.server.luau` lines ~480-487

Each castle floor steps 6 studs inward (3 per side) relative to the floor below it. Floor 2 = 110×88, Floor 3 = 104×82 … Floor 6 = 86×64. The stairX positions are clamped so they stay inside the narrowing floors.

- [ ] **Step 1: Change W, D and clamp stairX in buildUpperFloor**

Find this block (around line 481):
```lua
    local fIdx   = fd.floor - 1
    local yBase  = H * (fd.floor - 1)   -- 14, 28, 42, 56, 70
    local W, D   = FLR_W, FLR_D         -- 116 × 94 — same as lab
    local lx, lz = 0, FLR_LZ            -- centred above lab
    local stairX = STAIR_X[fIdx]        -- staircase X per floor
```

Replace with:
```lua
    local fIdx   = fd.floor - 1
    local yBase  = H * (fd.floor - 1)       -- 14, 28, 42, 56, 70
    local step   = fIdx * 6                  -- shrink 6 studs per level
    local W      = FLR_W - step              -- 110 → 104 → 98 → 92 → 86
    local D      = FLR_D - step              -- 88  → 82  → 76  → 70  → 64
    local lx, lz = 0, FLR_LZ
    -- Clamp stairX so it stays at least 8 studs from the (narrowing) wall
    local stairX = math.clamp(STAIR_X[fIdx], -(W/2 - 8), W/2 - 8)
```

- [ ] **Step 2: In-Studio test**

Open `.rbxlx`, click Build World. Look at the tower from outside:
- Floor 2 should be visibly narrower than the lab
- Each subsequent floor steps inward
- No staircase drop pad should clip outside the floor walls

- [ ] **Step 3: Commit**
```bash
cd ~/Ubuntu\ -\ Les/PERSONAL/roblox-game
git add src/ServerScriptService/WorldSetup.server.luau
git commit -m "feat: stepped castle tower — each floor 6 studs narrower than the one below"
git push
```

---

## Task 2: Parapet separator ring at Y=14

**Files:**
- Modify: `src/ServerScriptService/WorldSetup.server.luau` — add to `buildLabFloor` at the very end, before the final `end`

The parapet is a visible stone cornice ring at exactly Y=14 (the lab roof), marking the lab-to-castle boundary. It has a crenellated top.

- [ ] **Step 1: Add parapet parts at end of buildLabFloor**

Inside `buildLabFloor(plot, plotCF)`, just before the final `end` of that function, add:

```lua
    -- ── Castle parapet ring at Y=14 (lab roof / tower base separator) ────────
    local PAR_H  = 4      -- parapet wall height
    local PAR_T  = 2      -- parapet wall thickness
    local CREN_W = 4      -- merlon width
    local CREN_H = 3      -- merlon height above parapet

    local function par(name, sz, dx, dy, dz)
        vp(bm, name, sz, plotCF*CFrame.new(dx, H+dy, dz), "Dark stone grey", STONE)
    end

    -- Four parapet walls (front/back/left/right)
    par("ParFr", Vector3.new(LAB_W, PAR_H, PAR_T),     0, PAR_H/2,  LAB_D/2-PAR_T/2)  -- front (entrance side)
    par("ParBk", Vector3.new(LAB_W, PAR_H, PAR_T),     0, PAR_H/2, -LAB_D/2+PAR_T/2)  -- back
    par("ParLf", Vector3.new(PAR_T, PAR_H, LAB_D-PAR_T*2), -LAB_W/2+PAR_T/2, PAR_H/2, 0)
    par("ParRt", Vector3.new(PAR_T, PAR_H, LAB_D-PAR_T*2),  LAB_W/2-PAR_T/2, PAR_H/2, 0)

    -- Crenellations (merlons) on front and back — 10 per wall
    for k = 0, 9 do
        local bx = (k - 4.5) * (LAB_W / 10)
        par("CrFr"..k, Vector3.new(CREN_W, CREN_H, PAR_T+1), bx, PAR_H+CREN_H/2,  LAB_D/2-PAR_T/2)
        par("CrBk"..k, Vector3.new(CREN_W, CREN_H, PAR_T+1), bx, PAR_H+CREN_H/2, -LAB_D/2+PAR_T/2)
    end
    -- Crenellations on left and right — 8 per wall
    for k = 0, 7 do
        local bz = (k - 3.5) * (LAB_D / 8)
        par("CrLf"..k, Vector3.new(PAR_T+1, CREN_H, CREN_W), -LAB_W/2+PAR_T/2, PAR_H+CREN_H/2, bz)
        par("CrRt"..k, Vector3.new(PAR_T+1, CREN_H, CREN_W),  LAB_W/2-PAR_T/2, PAR_H+CREN_H/2, bz)
    end
    -- Neon accent strip on parapet top
    par("ParGlow", Vector3.new(LAB_W-2, 0.3, LAB_D-2), 0, PAR_H+0.15, 0)
    bm:FindFirstChild("ParGlow").BrickColor = BrickColor.new("Bright violet")
    bm:FindFirstChild("ParGlow").Material   = NEON
```

- [ ] **Step 2: In-Studio test**

Build World. Verify:
- A stone ring of crenellated walls is visible at the lab roof line (Y=14)
- The ring separates the lab from the castle tower above it
- The neon violet strip glows around the top of the parapet

- [ ] **Step 3: Commit**
```bash
git add src/ServerScriptService/WorldSetup.server.luau
git commit -m "feat: castle parapet ring at Y=14 with crenellations separating lab from tower"
git push
```

---

## Task 3: AnimationManager client script

**Files:**
- Create: `src/StarterPlayerScripts/AnimationManager.client.luau`

This script runs entirely client-side. It scans workspace for any `BasePart` with an `AnimType` attribute and starts the corresponding animation loop. It also watches `workspace.DescendantAdded` so newly-revealed parts (from `DropPadClient` making them visible) auto-animate.

Animation types:
- `"bob"` — Y oscillates ±`AnimRange` studs over `AnimSpeed` seconds (TweenService sine)
- `"spin"` — rotates around Y-axis at `AnimSpeed` seconds per full rotation (manual loop)
- `"pulse"` — Transparency oscillates 0 ↔ `AnimRange` over `AnimSpeed` seconds
- `"strobe"` — rapid on/off blink: 0.3s ON, (0.7-`AnimOffset`)s OFF, repeating
- `"float"` — moves Y up by `AnimRange` over `AnimSpeed` seconds, then resets (bubble effect)

- [ ] **Step 1: Create AnimationManager.client.luau**

```lua
-- src/StarterPlayerScripts/AnimationManager.client.luau
-- Reads AnimType attribute on BaseParts and runs corresponding TweenService loops.
-- Works for both pre-existing visible parts and newly revealed (bought) parts.
local TweenService = game:GetService("TweenService")

local function startAnim(part: BasePart)
    if not part:IsA("BasePart") then return end
    local animType = part:GetAttribute("AnimType")
    if not animType then return end
    if part:GetAttribute("_AnimStarted") then return end  -- prevent double-start
    part:SetAttribute("_AnimStarted", true)

    local speed  = part:GetAttribute("AnimSpeed")  or 2
    local offset = part:GetAttribute("AnimOffset") or 0
    local range  = part:GetAttribute("AnimRange")  or 1.5

    -- bob: Y oscillation using TweenService sine
    if animType == "bob" then
        local baseY = part.Position.Y
        task.delay(offset, function()
            while part.Parent do
                if part.Transparency < 0.5 then
                    local up = TweenService:Create(part,
                        TweenInfo.new(speed/2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                        {Position = Vector3.new(part.Position.X, baseY + range, part.Position.Z)})
                    up:Play(); up.Completed:Wait()
                    if not part.Parent then break end
                    local dn = TweenService:Create(part,
                        TweenInfo.new(speed/2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                        {Position = Vector3.new(part.Position.X, baseY, part.Position.Z)})
                    dn:Play(); dn.Completed:Wait()
                else
                    task.wait(0.5)
                end
            end
        end)

    -- spin: continuous Y-axis rotation at 30fps
    elseif animType == "spin" then
        local degsPerFrame = (360 / speed) / 30   -- degrees per frame at 30fps
        task.spawn(function()
            while part.Parent do
                task.wait(1/30)
                if part.Transparency < 0.5 then
                    part.CFrame = part.CFrame * CFrame.Angles(0, math.rad(degsPerFrame), 0)
                end
            end
        end)

    -- pulse: Transparency oscillates 0 ↔ range
    elseif animType == "pulse" then
        task.delay(offset, function()
            while part.Parent do
                if part.Transparency <= 0.1 then
                    local fadeOut = TweenService:Create(part,
                        TweenInfo.new(speed/2, Enum.EasingStyle.Sine),
                        {Transparency = range})
                    fadeOut:Play(); fadeOut.Completed:Wait()
                    if not part.Parent then break end
                    local fadeIn = TweenService:Create(part,
                        TweenInfo.new(speed/2, Enum.EasingStyle.Sine),
                        {Transparency = 0})
                    fadeIn:Play(); fadeIn.Completed:Wait()
                else
                    task.wait(0.5)
                end
            end
        end)

    -- strobe: rapid binary blink (0.3s on / speed-0.3 off)
    elseif animType == "strobe" then
        task.delay(offset, function()
            while part.Parent do
                if part.Transparency < 0.5 then
                    part.Transparency = 0
                    task.wait(0.3)
                    if not part.Parent then break end
                    part.Transparency = 1
                    task.wait(math.max(0.1, speed - 0.3))
                else
                    task.wait(0.5)
                end
            end
        end)

    -- float: moves upward then teleports back (bubble effect)
    elseif animType == "float" then
        local baseY = part.Position.Y
        task.delay(offset, function()
            while part.Parent do
                if part.Transparency < 0.5 then
                    local rise = TweenService:Create(part,
                        TweenInfo.new(speed, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                        {Position    = Vector3.new(part.Position.X, baseY + range, part.Position.Z),
                         Transparency = 1})
                    rise:Play(); rise.Completed:Wait()
                    if not part.Parent then break end
                    part.Position    = Vector3.new(part.Position.X, baseY, part.Position.Z)
                    part.Transparency = 0
                    task.wait(0.3)
                else
                    task.wait(0.5)
                end
            end
        end)
    end
end

-- Catch already-existing parts
for _, d in ipairs(workspace:GetDescendants()) do
    task.spawn(startAnim, d)
end

-- Catch newly added parts (station models revealed when bought)
workspace.DescendantAdded:Connect(function(inst)
    task.spawn(startAnim, inst)
end)
```

- [ ] **Step 2: In-Studio test**

Manually tag a test part via command bar:
```lua
local p = Instance.new("Part")
p.Size=Vector3.new(3,3,3); p.Position=Vector3.new(0,5,0)
p.Anchored=true; p.Parent=workspace
p:SetAttribute("AnimType","bob")
p:SetAttribute("AnimSpeed",2)
p:SetAttribute("AnimRange",2)
```
Press Play — the part should bob up and down smoothly.

- [ ] **Step 3: Commit**
```bash
git add src/StarterPlayerScripts/AnimationManager.client.luau
git commit -m "feat: AnimationManager — bob/spin/pulse/strobe/float animations via part Attributes"
git push
```

---

## Task 4: Chemistry animated parts

**Files:**
- Modify: `src/ServerScriptService/WorldSetup.server.luau` — inside `buildLabFloor`, after `buildRoom(plot,bm,plotCF, 1, ...)` call

Chemistry dept centre: local `(lx=0, lz=-68)`. Add 3 bobbing beakers + 4 floating bubbles.

- [ ] **Step 1: Add animated Chemistry decorations**

After the Chemistry `buildRoom` call (around line 361), add:
```lua
    -- ── Chemistry: bobbing beakers + floating bubbles ─────────────────────
    local function chemPart(name, sz, dx, dz, col, mat)
        return vp(bm, name, sz, plotCF*CFrame.new(dx, 2, -68+dz), col, mat or STONE)
    end
    -- 3 glass beakers that bob at different speeds
    for i, bx in ipairs({-12, 0, 12}) do
        local beaker = chemPart("ChemBeaker"..i, Vector3.new(2, 5, 2), bx, 0, "Bright green", Enum.Material.Glass)
        beaker:SetAttribute("AnimType",  "bob")
        beaker:SetAttribute("AnimSpeed",  2 + i * 0.5)   -- 2.5, 3.0, 3.5 s
        beaker:SetAttribute("AnimOffset", (i-1) * 0.8)    -- stagger start
        beaker:SetAttribute("AnimRange",  1.5)
        -- Neon liquid inside beaker
        local liq = chemPart("ChemLiq"..i, Vector3.new(1.4, 3.5, 1.4), bx, 0.2, "Bright green", NEON)
        liq:SetAttribute("AnimType",  "bob")
        liq:SetAttribute("AnimSpeed",  2 + i * 0.5)
        liq:SetAttribute("AnimOffset", (i-1) * 0.8)
        liq:SetAttribute("AnimRange",  1.5)
    end
    -- 4 floating bubbles (float upward and reset)
    local bubOffsets = {{-8,-4},{-3,5},{4,-2},{9,3}}
    for i, off in ipairs(bubOffsets) do
        local bub = chemPart("ChemBub"..i, Vector3.new(0.6,0.6,0.6), off[1], off[2], "Bright green", NEON)
        bub:SetAttribute("AnimType",  "float")
        bub:SetAttribute("AnimSpeed",  2.5)
        bub:SetAttribute("AnimOffset", (i-1) * 0.65)
        bub:SetAttribute("AnimRange",  4)
    end
    -- Ceiling neon pulse
    local ceilPulse = vp(bm,"ChemCeilPulse",Vector3.new(40,0.3,22),
        plotCF*CFrame.new(0, H-1.1, -68), "Bright green", NEON)
    ceilPulse:SetAttribute("AnimType",  "pulse")
    ceilPulse:SetAttribute("AnimSpeed",  2)
    ceilPulse:SetAttribute("AnimRange",  0.7)
```

- [ ] **Step 2: In-Studio test**

Build World → Play. In the Chemistry room you should see:
- 3 green glass beakers bobbing at different heights and speeds
- Green neon liquid inside each beaker moving with it
- 4 small green bubbles floating upward and resetting
- Ceiling glow pulsing green

- [ ] **Step 3: Commit**
```bash
git add src/ServerScriptService/WorldSetup.server.luau
git commit -m "feat: Chemistry dept animations — bobbing beakers, floating bubbles, pulsing ceiling"
git push
```

---

## Task 5: Electronics animated parts

**Files:**
- Modify: `src/ServerScriptService/WorldSetup.server.luau` — after `buildRoom(plot,bm,plotCF, 4,-52,-68, ...)` call

Electronics dept centre: local `(lx=-52, lz=-68)`. Add a spinning fan + 5 sequenced server lights.

- [ ] **Step 1: Add animated Electronics decorations**

After the Electronics `buildRoom` call (around line 373):
```lua
    -- ── Electronics: spinning fan + sequenced server lights ───────────────
    local function elecPart(name, sz, dx, dy, dz, col, mat)
        return vp(bm, name, sz, plotCF*CFrame.new(-52+dx, dy, -68+dz), col, mat or STONE)
    end
    -- Spinning fan disc (flat cylinder, spins on Y axis)
    local fan = elecPart("ElecFan", Vector3.new(8, 0.4, 8), 0, 8, -2, "Dark grey", STONE)
    fan:SetAttribute("AnimType",  "spin")
    fan:SetAttribute("AnimSpeed", 1.2)   -- one rotation per 1.2 seconds
    -- Fan blades (4 thin boxes welded to the disc conceptually — we just add them at same position)
    for i = 0, 3 do
        local blade = elecPart("ElecBlade"..i, Vector3.new(7, 0.3, 1),
            math.cos(math.rad(i*90))*3, 8.3, -2 + math.sin(math.rad(i*90))*3,
            "Dark grey", STONE)
        blade:SetAttribute("AnimType",  "spin")
        blade:SetAttribute("AnimSpeed", 1.2)
    end
    -- 5 server indicator lights that blink in sequence (strobe with offset)
    local lightColours = {"Bright blue","Bright green","Bright blue","Bright red","Bright green"}
    for i = 1, 5 do
        local light = elecPart("ElecLight"..i, Vector3.new(0.4, 0.4, 0.4),
            -8, 3 + i * 1.4, 4, lightColours[i], NEON)
        light:SetAttribute("AnimType",   "strobe")
        light:SetAttribute("AnimSpeed",  2.5)      -- total cycle length
        light:SetAttribute("AnimOffset", (i-1) * 0.5)  -- each light offset by 0.5s
    end
    -- Data stream strip (slides along back wall as a pulse)
    local stream = elecPart("ElecStream", Vector3.new(28, 0.5, 0.3), 0, 5, -12, "Bright blue", NEON)
    stream:SetAttribute("AnimType",  "pulse")
    stream:SetAttribute("AnimSpeed",  0.8)
    stream:SetAttribute("AnimRange",  0.9)
```

- [ ] **Step 2: In-Studio test**

In the Electronics room:
- A disc + blades spin continuously
- 5 blue/green/red lights blink one after another sequentially
- Back wall data-stream strip pulses

- [ ] **Step 3: Commit**
```bash
git add src/ServerScriptService/WorldSetup.server.luau
git commit -m "feat: Electronics dept animations — spinning fan, sequenced lights, data stream"
git push
```

---

## Task 6: Biology + Physics animated parts

**Files:**
- Modify: `src/ServerScriptService/WorldSetup.server.luau`

**Biology** (lx=60, lz=-22): DNA helix (two columns of spheres spinning in opposite directions) + pulsing tank glow.
**Physics** (lx=-60, lz=-22): Three rings spinning on different axes at different speeds + pulsing energy core.

- [ ] **Step 1: Add Biology decorations** (after the Biology buildRoom call around line 365)

```lua
    -- ── Biology: counter-rotating DNA columns + pulsing culture tank ──────
    local function bioPart(name, sz, dx, dy, dz, col, mat)
        return vp(bm, name, sz, plotCF*CFrame.new(60+dx, dy, -22+dz), col, mat or STONE)
    end
    -- Two DNA columns (tall cylinder spirals simulated as columns)
    local col1 = bioPart("BioCol1", Vector3.new(1.5, 12, 1.5), -2, 7, 0, "Cyan", Enum.Material.Glass)
    col1:SetAttribute("AnimType",  "spin");  col1:SetAttribute("AnimSpeed", 4)
    local col2 = bioPart("BioCol2", Vector3.new(1.5, 12, 1.5),  2, 7, 0, "Cyan", Enum.Material.Glass)
    col2:SetAttribute("AnimType",  "spin");  col2:SetAttribute("AnimSpeed", -4)  -- reverse spin
    -- DNA rungs (4 horizontal connectors between the columns)
    for i = 0, 3 do
        local rung = bioPart("BioRung"..i, Vector3.new(4, 0.5, 0.4), 0, 3+i*3, i*1.5-3, "Cyan", NEON)
        rung:SetAttribute("AnimType",  "pulse")
        rung:SetAttribute("AnimSpeed",  1.5)
        rung:SetAttribute("AnimOffset", i * 0.4)
        rung:SetAttribute("AnimRange",  0.6)
    end
    -- Culture tank glow
    local tank = bioPart("BioTank", Vector3.new(5, 6, 5), 0, 4, 8, "Cyan", NEON)
    tank.Transparency = 0.6
    tank:SetAttribute("AnimType",  "pulse")
    tank:SetAttribute("AnimSpeed",  2)
    tank:SetAttribute("AnimRange",  0.85)  -- goes from T=0.6 to T=0.85 and back (not fully off)
```

- [ ] **Step 2: Add Physics decorations** (after the Physics buildRoom call around line 369)

```lua
    -- ── Physics: 3 rings on different axes + pulsing energy core ──────────
    local function physPart(name, sz, dx, dy, dz, col, mat)
        return vp(bm, name, sz, plotCF*CFrame.new(-60+dx, dy, -22+dz), col, mat or STONE)
    end
    -- Energy core (central pulsing sphere)
    local core = physPart("PhysCore", Vector3.new(4,4,4), 0, 7, 0, "Bright violet", NEON)
    core:SetAttribute("AnimType",  "pulse")
    core:SetAttribute("AnimSpeed",  1.0)
    core:SetAttribute("AnimRange",  0.5)
    -- Ring 1: spins on Y axis (horizontal ring, fast)
    local ring1 = physPart("PhysRing1", Vector3.new(10, 0.5, 10), 0, 7, 0, "Bright violet", STONE)
    ring1:SetAttribute("AnimType",  "spin");  ring1:SetAttribute("AnimSpeed", 1.5)
    -- Ring 2: flat disc on X axis angle (tilted ring) — we fake this with a rotated part
    local ring2 = physPart("PhysRing2", Vector3.new(0.5, 8, 8), 0, 7, 0, "Bright violet", STONE)
    ring2.CFrame = ring2.CFrame * CFrame.Angles(0, 0, math.rad(45))  -- tilt it
    ring2:SetAttribute("AnimType",  "spin");  ring2:SetAttribute("AnimSpeed", 2.5)
    -- Ring 3: another angle, slower
    local ring3 = physPart("PhysRing3", Vector3.new(8, 0.5, 0.5), 0, 7, 0, "Bright violet", STONE)
    ring3.CFrame = ring3.CFrame * CFrame.Angles(math.rad(45), 0, 0)
    ring3:SetAttribute("AnimType",  "spin");  ring3:SetAttribute("AnimSpeed", 3.5)
    -- Energy beams (2 thin lines pulsing alternately)
    local beam1 = physPart("PhysBeam1", Vector3.new(0.3, 12, 0.3), -4, 7, 0, "Bright violet", NEON)
    beam1:SetAttribute("AnimType","pulse"); beam1:SetAttribute("AnimSpeed",0.8); beam1:SetAttribute("AnimRange",1)
    local beam2 = physPart("PhysBeam2", Vector3.new(0.3, 12, 0.3),  4, 7, 0, "Bright violet", NEON)
    beam2:SetAttribute("AnimType","pulse"); beam2:SetAttribute("AnimSpeed",0.8); beam2:SetAttribute("AnimOffset",0.4); beam2:SetAttribute("AnimRange",1)
```

- [ ] **Step 3: In-Studio test**

Biology room: two cyan columns spin in opposite directions, rungs pulse, tank glows.
Physics room: three rings spin on different axes, purple beams alternate, core pulses.

- [ ] **Step 4: Commit**
```bash
git add src/ServerScriptService/WorldSetup.server.luau
git commit -m "feat: Biology (DNA helix + culture tank) and Physics (3 spinning rings + energy core) animations"
git push
```

---

## Task 7: Weapons animated parts + final rebuild

**Files:**
- Modify: `src/ServerScriptService/WorldSetup.server.luau` — after Weapons buildRoom call

Weapons (lx=52, lz=-68): spinning targeting reticle + 3 strobing warning lights + shaking crate.

- [ ] **Step 1: Add Weapons decorations** (after the Weapons buildRoom call around line 377)

```lua
    -- ── Weapons: targeting reticle + warning strobes + shaking crate ──────
    local function weapPart(name, sz, dx, dy, dz, col, mat)
        return vp(bm, name, sz, plotCF*CFrame.new(52+dx, dy, -68+dz), col, mat or STONE)
    end
    -- Targeting reticle (flat ring spinning on Z axis)
    local reticle = weapPart("WeapReticle", Vector3.new(7, 7, 0.3), 4, 7, -6, "Bright red", STONE)
    reticle:SetAttribute("AnimType",  "spin")
    reticle:SetAttribute("AnimSpeed", 2.0)
    -- Inner crosshair (spins same speed, different part)
    local cross1 = weapPart("WeapCross1", Vector3.new(6, 0.4, 0.4), 4, 7, -5.8, "Bright red", NEON)
    cross1:SetAttribute("AnimType","spin"); cross1:SetAttribute("AnimSpeed",2.0)
    local cross2 = weapPart("WeapCross2", Vector3.new(0.4, 6, 0.4), 4, 7, -5.8, "Bright red", NEON)
    cross2:SetAttribute("AnimType","spin"); cross2:SetAttribute("AnimSpeed",2.0)
    -- 3 warning lights (strobe with offset so they don't sync)
    local warnPositions = {{-8, 4, 5},{0, 4, 5},{8, 4, 5}}
    for i, wp in ipairs(warnPositions) do
        local warn = weapPart("WeapWarn"..i, Vector3.new(0.8, 0.8, 0.8), wp[1], wp[2], wp[3], "Bright red", NEON)
        warn:SetAttribute("AnimType",   "strobe")
        warn:SetAttribute("AnimSpeed",  1.0)
        warn:SetAttribute("AnimOffset", (i-1) * 0.33)
    end
    -- Shaking ammo crate (uses bob on X axis — we approximate with bob)
    local crate = weapPart("WeapCrate", Vector3.new(4, 3, 4), -6, 2.5, 4, "Dark stone grey", STONE)
    crate:SetAttribute("AnimType",  "bob")
    crate:SetAttribute("AnimSpeed",  0.3)   -- fast shake
    crate:SetAttribute("AnimRange",  0.25)  -- small movement
```

- [ ] **Step 2: Final rebuild and commit**

```bash
cd ~/Ubuntu\ -\ Les/PERSONAL/roblox-game
~/bin/rojo build --output super-v-hq.rbxlx
git add src/ServerScriptService/WorldSetup.server.luau src/StarterPlayerScripts/AnimationManager.client.luau
git commit -m "feat: Weapons animations (spinning reticle, strobing warnings, shaking crate) + full rebuild"
git push
```

- [ ] **Step 3: Full in-Studio test**

Open `.rbxlx`, Build World, Press Play:
1. Tower steps inward each floor ✓
2. Stone parapet ring visible at Y=14 ✓
3. All 5 dept rooms have distinct animations:
   - Chemistry: green beakers bob, bubbles float upward ✓
   - Electronics: fan spins, lights blink in sequence ✓
   - Biology: cyan columns counter-rotate, tank pulses ✓
   - Physics: 3 rings spin on different axes, core pulses ✓
   - Weapons: reticle spins, warning lights strobe, crate shakes ✓
4. Animations only run when parts are visible (Transparency < 0.5) ✓
5. No animation starts on invisible station models (they animate after being bought) ✓

---

## Spec Coverage

| Requirement | Task |
|---|---|
| Stepped tower (6 studs per floor) | Task 1 |
| Parapet ring at Y=14 with crenellations | Task 2 |
| AnimationManager (bob/spin/pulse/strobe/float) | Task 3 |
| Chemistry: beakers bob, bubbles float | Task 4 |
| Electronics: fan spins, lights sequence | Task 5 |
| Biology: DNA counter-rotate, tank pulse | Task 6 |
| Physics: 3-axis rings, energy beams | Task 6 |
| Weapons: reticle spin, strobe warnings | Task 7 |
