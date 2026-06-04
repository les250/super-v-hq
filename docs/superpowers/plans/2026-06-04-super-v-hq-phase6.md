# Super V HQ — Phase 6: Post-Roadmap Status

**Date:** 2026-06-04
**Status:** All 17 original roadmap tasks complete. Castle redesign, 50-station lab, progressive vault cap, and sprint mechanic added beyond original scope.

---

## ✅ Completed (Phases 1-5 + extras)

| Feature | Status |
|---|---|
| 50-station lab (5 depts × 10) | ✅ |
| Progressive vault cap per dept (3k→30k) | ✅ |
| 5 castle tower floors (Dungeon/Great Hall/Throne/Treasury/Parapets) | ✅ |
| Staircase system (one floor per staircase, floor holes) | ✅ |
| Castle exterior (portcullis, battlements, corner towers) | ✅ |
| Sprint (double-tap W = 2× speed) | ✅ |
| Raid cooldown shield HUD | ✅ |
| War Room spy panel | ✅ |
| Escape Pod teleport | ✅ |
| Armory raid boost (+5/10/15%) | ✅ |
| Wallet slots (3–9) | ✅ |
| Item system (5 items: Stim Pack, EMP, Armor Chip, Vault Override, Minion Core) | ✅ |
| Crafting (5 dept recipes) | ✅ |
| Trading (P2P with 30s timeout) | ✅ |
| Leaderboard (💰 money + ⏱ time played) | ✅ |
| NPC minions (2/4/6 per Barracks tier) | ✅ |
| Sound effects | ✅ |
| Tutorial overlay | ✅ |
| Settings menu | ✅ |
| Mobile UI | ✅ |
| Objectives panel (green/white/grey per dept) | ✅ |
| Promo code (04160416 = 1B dev code) | ✅ |
| Dev "Buy All Lab" button | ✅ |
| Anti-exploit (rate limit, vault floor, tier cap) | ✅ |
| Publish validator + checklist | ✅ |
| Dual leaderboard (money + time played) | ✅ |
| Time played tracking | ✅ |
| Brighter villain lighting | ✅ |

---

## 🔧 Bug Fixes Applied (2026-06-04)

- [x] **Item effects now wired**: Armor Chip, Minion Core reduce raid damage taken; EMP Grenade boosts raid steal; Vault Override adds 5000 to vault cap; Stim Pack income boost applied correctly everywhere
- [x] **Trade initiation from inventory**: Each item row now has a 🤝 Trade button
- [x] **CraftKiosk positions**: Confirmed correct for T-shaped lab (no change needed)
- [x] **Minions cleared on base move**: `MinionManager.onBarracksBuilt(player, 0)` called in MoveBase handler
- [x] **Vault cap includes inventory items** in income tick and currency display

---

## 📋 Remaining / Future Work

### Must-do before publish
- [ ] Set real Robux Developer Product IDs in Config.luau (see `docs/PUBLISH_CHECKLIST.md`)
- [ ] Enable Studio API Services (Game Settings → Security) for DataStore testing
- [ ] Playtest staircase geometry with new floor hole positions
- [ ] Test trading end-to-end with 2 players

### Nice-to-have (post-launch Phase 7)
- [ ] **Trade initiation UX** — current Trade button opens first player found, not a picker. Needs a proper player list showing all online players
- [ ] **Raid history log** — show last 5 raids received (who, when, how much)
- [ ] **Daily login bonus** — simple streak reward (easy retention)
- [ ] **Achievement system** — first lab complete, 10 raids, max slots, etc.
- [ ] **Escape Pod cooldown in HUD** — persistent indicator alongside the raid shield
- [ ] **Objectives panel reset on base move** — UI keeps old progress display after moving base
- [ ] **Sound for sprint** — whoosh on double-tap W
- [ ] **More promo codes** — event codes, launch codes
- [ ] **Minion combat** — minions actively intercept raiders (currently visual only)
- [ ] **War Room historical data** — show peak vault amounts, not just live
- [ ] **Game passes** — permanent income multiplier, extra slots, custom minion skins

---

## Architecture snapshot (current)

```
src/
├── ReplicatedStorage/
│   ├── Config.luau           — all constants (PRODUCT IDs still 0)
│   ├── ItemData.luau         — 5 item definitions
│   ├── Remotes.luau          — all 20+ RemoteEvents/Functions
│   ├── RoomData.luau         — 50 lab stations + 5 floors + item effect helpers
│   └── SoundData.luau        — sound IDs and volumes
└── StarterPlayerScripts/     — 17 LocalScripts
ServerScriptService/          — 9 server scripts
```
