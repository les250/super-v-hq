# Super V HQ — Publish Checklist

## Before Publishing
- [ ] All 50 lab stations build correctly in Studio playtest
- [ ] Upper floors unlock after lab completion
- [ ] Raid mechanic works in 2-player Team Test
- [ ] DataStore saves/loads between sessions (test by leaving and rejoining)
- [ ] Promo code `04160416` still works (grants 1B, bypasses cap)

## Publishing Steps
1. In Roblox Studio: **File → Publish to Roblox As**
2. Name: `Super V HQ`
3. Description: `Build your Supervillain HQ, unlock labs, raid rivals, and dominate the leaderboard!`
4. Genre: **Town and City**
5. Click **Create** — save the Place ID shown

## After Publishing
1. Go to **create.roblox.com** → Super V HQ → **Monetization → Developer Products**
2. Create 4 products:
   | Name | Price | Amount |
   |---|---|---|
   | 500 Credits | 10 Robux | 500 in-game currency |
   | 1500 Credits | 25 Robux | 1500 in-game currency |
   | 5000 Credits | 75 Robux | 5000 in-game currency |
   | Raid Strike | 50 Robux | Triggers a raid |
3. Copy each Product ID into `src/ReplicatedStorage/Config.luau`
4. Commit and push — Rojo will sync instantly
5. Test purchases in the **live game** (not Studio) with a small test purchase

## Post-Launch
- [ ] Enable Studio Access to API Services (Game Settings → Security) for DataStore in Studio tests
- [ ] Monitor output for `[PUBLISH]` warnings — remove `PublishValidator.server.luau` once IDs are set
- [ ] Set up Roblox Analytics to track player retention
