# Super V HQ — Design Spec

**Date:** 2026-06-02
**Genre:** Tycoon / Base Builder
**Platform:** Roblox
**Toolchain:** Rojo (free, open source) + GitHub

---

## Overview

Super V HQ is a Roblox tycoon game where each player builds and upgrades their own Supervillain headquarters. Players earn in-game currency passively through their HQ, spend it on drop-pad upgrades and room tiers, trade items with other players, and can raid other players' vaults by spending real Robux.

---

## Multiplayer Format

- Each player is assigned their own **private HQ plot** on join
- Other players can **visit** your plot freely
- Visitors can **raid your vault** by spending real Robux (Developer Product)
- No griefing beyond the raid mechanic — visitors cannot destroy upgrades

---

## Core Gameplay Loop

1. Player joins → assigned an empty HQ plot
2. Walk over **drop pads** → spend in-game currency → room appears
3. Enter a room → open **upgrade menu** → spend currency to level up (3 tiers per room)
4. Rooms passively generate in-game currency over time
5. Visit another player's HQ → pay real Robux → steal a % of their vault balance

---

## Progression: Rooms

Drop pads unlock rooms. Each room has 3 upgrade tiers that increase passive income and unlock abilities.

| Order | Room | Passive Income Role | Ability Unlocked |
|---|---|---|---|
| 1 | Lab | Low — slow steady drip | Unlocks item crafting |
| 2 | Armory | Medium | Unlocks raid damage boost |
| 3 | Minion Barracks | Medium | Spawns NPC minions that defend vs raids |
| 4 | War Room | High | Reveals other players' vault amounts |
| 5 | Vault | Stores currency (increases cap) | Reduces % stolen on raids |
| 6 | Escape Pod Bay | Bonus income burst | Lets you teleport to another player's plot |

Rooms are unlocked in order via drop pads. Later rooms cost significantly more, creating a long progression curve.

---

## Economy

| Action | Currency Type |
|---|---|
| Passive room income | Earn in-game currency |
| Buy/upgrade rooms | Spend in-game currency |
| Buy items (cosmetics, boosts) | Spend in-game currency |
| Trade items with other players | In-game currency exchange |
| Buy in-game currency | Real Robux (Developer Product) |
| Raid another player's vault | Real Robux (Developer Product) |

### Raid Mechanic
- Raider pays Robux → triggers a raid event on the victim's plot
- Steals a fixed % of the victim's current vault balance (e.g. 10%)
- Victim gets a notification: "Your HQ was raided by [player]!"
- Minion Barracks (if built) reduces the % stolen
- Vault upgrades reduce the % stolen further
- Cooldown: a player cannot be raided more than once per 10 minutes

---

## Tech Stack

| Layer | Tool |
|---|---|
| Game engine | Roblox Studio |
| Code sync | Rojo (free, open source) |
| Language | Luau (Roblox's Lua dialect) |
| Version control | Git + GitHub (`les250/super-v-hq`) |
| Local storage | `~/Ubuntu - Les/PERSONAL/roblox-game/` |
| Cloud backup | OneDrive (Ubuntu - Les/PERSONAL) |

---

## Project Structure

```
super-v-hq/
├── src/
│   ├── ServerScriptService/
│   │   ├── PlotManager.server.luau       -- assigns plots on join
│   │   ├── EconomyManager.server.luau    -- passive income ticks
│   │   ├── RaidManager.server.luau       -- handles raid Developer Products
│   │   └── DataStore.server.luau         -- saves/loads player data
│   ├── ReplicatedStorage/
│   │   ├── Config.luau                   -- room costs, income rates, raid %
│   │   ├── Remotes.luau                  -- RemoteEvents/Functions
│   │   └── RoomData.luau                 -- room definitions and tier data
│   ├── StarterPlayerScripts/
│   │   ├── DropPadClient.client.luau     -- proximity prompts for drop pads
│   │   └── HudController.client.luau     -- currency display, notifications
│   └── Workspace/
│       └── PlotTemplate/                 -- the base plot model with drop pad positions
├── default.project.json                  -- Rojo project file
├── .gitignore
└── docs/
    └── superpowers/specs/
        └── 2026-06-02-super-v-hq-design.md
```

---

## Rojo Workflow

```bash
# Install Rojo plugin in Roblox Studio (one-time)
# Then in terminal:
cd ~/Ubuntu\ -\ Les/PERSONAL/roblox-game
rojo serve

# Studio connects to localhost:34872
# Any file change on disk instantly syncs into Studio
```

---

## Out of Scope (v1)

- Leaderboards / social features
- Seasonal events
- Mobile-specific UI
- Anti-cheat systems
- Cosmetic shop beyond basic items
