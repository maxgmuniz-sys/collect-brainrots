# PROGRESS.md — Collect Brainrot's🦈

**Last Updated:** 2026-02-22
**Current Phase:** Documentation (pre-development)

---

## Phase Summary

| Phase | Name | Status | Notes |
|-------|------|--------|-------|
| Docs | Documentation Suite | DONE | All 13 docs written |
| 0 | Setup & Tooling | NOT STARTED | Install Wally, Rojo plugin, VS Code, project structure |
| 1 | MVP Core Loop | NOT STARTED | Common food + common brainrots + money/sec |
| 2 | Full Rarity & Food | NOT STARTED | All 25 brainrots, all 8 food tiers, balance costs |
| 3 | Size System | NOT STARTED | Random weighted sizes, weight in lbs |
| 4 | Base Mutations | NOT STARTED | Gold/Diamond/Rainbow from food |
| 5 | Base Management | NOT STARTED | Capacity upgrades (1→30), sell store, fencing |
| 6 | Weather System | NOT STARTED | 7 weather events, weather mutations, music |
| 7 | Index & Social | NOT STARTED | Codex, gifting, leaderboards |
| 8 | Advanced Features | NOT STARTED | Fusion, lucky hours, VIP food, personalities |
| 9 | Map & Polish | NOT STARTED | 6 plots, rival bases, tutorial, sounds, balancing |

---

## Documentation Checklist

- [x] GAME_DESIGN.md — Full game design (691 lines)
- [x] ARCHITECTURE.md — Code architecture (1,045 lines)
- [x] AGENT_WORKFLOW.md — AI agent rules (12 sections)
- [x] PROGRESS.md — This file
- [x] PHASE_0_SETUP.md — Tooling & scaffold
- [x] PHASE_1_MVP.md — Core loop spec
- [x] PHASE_2_RARITY.md — Full rarity system
- [x] PHASE_3_SIZE.md — Size system
- [x] PHASE_4_MUTATIONS.md — Base mutations
- [x] PHASE_5_BASE.md — Base management & sell store
- [x] PHASE_6_WEATHER.md — Weather events
- [x] PHASE_7_SOCIAL.md — Index, gifting, leaderboards
- [x] PHASE_8_ADVANCED.md — Fusion, lucky hours, VIP food, personalities
- [x] PHASE_9_POLISH.md — Map, tutorial, sounds, balancing

---

## Phase 0: Setup & Tooling

- [ ] Install Wally via aftman
- [ ] Install Selene via aftman
- [ ] Install StyLua via aftman
- [ ] Install VS Code via winget
- [ ] Create wally.toml with ProfileStore
- [ ] Run wally install
- [ ] Update default.project.json
- [ ] Create directory structure
- [ ] Delete Hello.luau
- [ ] Update .gitignore
- [ ] Install Rojo Studio plugin
- [ ] Verify rojo build
- [ ] Verify rojo serve + Studio connection
- [ ] Git commit: "Phase 0: Project setup and tooling"

---

## Phase 1: MVP Core Loop

- [ ] Config/Brainrots.luau
- [ ] Config/Foods.luau
- [ ] Types.luau
- [ ] Utils.luau
- [ ] Remotes/init.luau
- [ ] DataService.luau
- [ ] BaseService.luau
- [ ] EarningsService.luau
- [ ] FoodService.luau
- [ ] MoneyUI.luau
- [ ] FoodStoreUI.luau
- [ ] BaseUI.luau
- [ ] init.server.luau
- [ ] init.client.luau
- [ ] Playtest: core loop works
- [ ] Git commit: "Phase 1: MVP core loop"

---

## Phase 2: Full Rarity & Food System

- [ ] Update Foods.luau (balanced costs, rarity weights)
- [ ] Update FoodService.luau (rarity-weighted rolling)
- [ ] Update FoodStoreUI.luau (all 8 tiers)
- [ ] Update BaseUI.luau (rarity colors)
- [ ] Playtest: all rarities obtainable
- [ ] Git commit: "Phase 2: Full rarity and food system"

---

## Phase 3: Size System

- [ ] Create Config/Sizes.luau
- [ ] Update FoodService.luau (roll size)
- [ ] Update EarningsService.luau (size multiplier)
- [ ] Update BaseUI.luau (visual scaling)
- [ ] Update FoodStoreUI.luau (size in reveal)
- [ ] Playtest: sizes vary, earnings scale
- [ ] Git commit: "Phase 3: Size system"

---

## Phase 4: Base Mutations

- [ ] Create Config/Mutations.luau
- [ ] Update FoodService.luau (roll mutation)
- [ ] Update EarningsService.luau (mutation multiplier)
- [ ] Update BaseUI.luau (mutation visuals)
- [ ] Update FoodStoreUI.luau (mutation in reveal)
- [ ] Playtest: mutations appear, earnings chain correctly
- [ ] Git commit: "Phase 4: Base mutations"

---

## Phase 5: Base Management

- [ ] Update BaseService.luau (capacity upgrades)
- [ ] Create SellService.luau
- [ ] Create SellUI.luau
- [ ] Update BaseUI.luau (upgrade button, fencing)
- [ ] Update Remotes/init.luau (sell remotes)
- [ ] Update init.server.luau + init.client.luau
- [ ] Playtest: upgrades work, sell works, fence visible
- [ ] Git commit: "Phase 5: Base management and sell store"

---

## Phase 6: Weather System

- [ ] Create Config/Weather.luau
- [ ] Create WeatherService.luau
- [ ] Create WeatherUI.luau
- [ ] Update EarningsService.luau (weather mutation multiplier)
- [ ] Update BaseUI.luau (weather mutation visuals)
- [ ] Update Remotes/init.luau (weather remotes)
- [ ] Update init.server.luau + init.client.luau
- [ ] Playtest: weather events trigger, mutations apply, music changes
- [ ] Git commit: "Phase 6: Weather system"

---

## Phase 7: Index & Social

- [ ] Create IndexService.luau
- [ ] Create GiftService.luau
- [ ] Create LeaderboardService.luau
- [ ] Create IndexUI.luau
- [ ] Create LeaderboardUI.luau
- [ ] Update DataService.luau (index fields)
- [ ] Update FoodService.luau (register discovery)
- [ ] Update BaseUI.luau (gift button, fence cosmetics)
- [ ] Update Remotes/init.luau
- [ ] Update init.server.luau + init.client.luau
- [ ] Playtest: codex tracks, gifting works, leaderboards show
- [ ] Git commit: "Phase 7: Index, gifting, and leaderboards"

---

## Phase 8: Advanced Features

- [ ] Create Config/Personalities.luau
- [ ] Create LuckyHourService.luau
- [ ] Create FusionUI.luau
- [ ] Update Config/Foods.luau (VIP food entries)
- [ ] Update FoodService.luau (personality, fusion, VIP, lucky hour)
- [ ] Update EarningsService.luau (personality multiplier)
- [ ] Update BaseUI.luau (personality display, fusion button)
- [ ] Update FoodStoreUI.luau (VIP food, lucky hour indicator)
- [ ] Update Remotes/init.luau
- [ ] Update init.server.luau + init.client.luau
- [ ] Playtest: fusion, lucky hours, personalities work
- [ ] Git commit: "Phase 8: Advanced features"

---

## Phase 9: Map & Polish

- [ ] Create Config/Sounds.luau
- [ ] Create TutorialUI.luau
- [ ] Update BaseService.luau (6 plots)
- [ ] Update BaseUI.luau (rival bases, sounds)
- [ ] Update WeatherUI.luau (music polish, crossfades)
- [ ] Update FoodStoreUI.luau (sound effects)
- [ ] Update init.client.luau
- [ ] Final balancing pass
- [ ] Playtest: full end-to-end with 6 players
- [ ] Git commit: "Phase 9: Map, tutorial, sounds, and polish"

---

## Recovery Notes

_Use this section to document any crashes, issues, or recovery actions._

| Date | Event | Resolution |
|------|-------|------------|
| | | |
