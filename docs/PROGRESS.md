# PROGRESS.md — Collect Brainrot's🦈

**Last Updated:** 2026-02-23
**Current Phase:** Phase 5 (Base Management) — DONE

---

## Phase Summary

| Phase | Name | Status | Notes |
|-------|------|--------|-------|
| Docs | Documentation Suite | DONE | All 13 docs written |
| 0 | Setup & Tooling | DONE | All tools installed, project scaffold complete |
| 1 | MVP Core Loop | DONE | All 14 files, playtested, core loop works |
| 2 | Full Rarity & Food | DONE | All 8 tiers, balanced costs, rarity colors, scrolling store UI |
| 3 | Size System | DONE | 5 size tiers, weighted sizes, visual scaling, weight in lbs |
| 4 | Base Mutations | DONE | Gold/Diamond/Rainbow mutations, particles, rainbow cycling |
| 5 | Base Management | DONE | Capacity upgrades (1→30), sell store, fencing, bug fixes |
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

- [x] Install Wally via aftman
- [x] Install Selene via aftman
- [x] Install StyLua via aftman
- [x] Install VS Code via winget
- [x] Create aftman.toml (pinned versions)
- [x] Create wally.toml with ProfileStore
- [x] Run wally install
- [x] Update default.project.json (Packages + ServerPackages)
- [x] Create directory structure (Config, Services, Remotes, Controllers)
- [x] Delete Hello.luau
- [x] Update .gitignore
- [x] Install Rojo Studio plugin
- [x] Verify rojo build
- [x] Verify rojo serve (port 34872)
- [ ] Verify Studio connection (user manual step)
- [x] Git commit: "Phase 0: Project setup and tooling"

---

## Phase 1: MVP Core Loop

- [x] Config/Brainrots.luau
- [x] Config/Foods.luau
- [x] Types.luau
- [x] Utils.luau
- [x] Remotes/init.luau
- [x] DataService.luau (ProfileStore at ServerScriptService.ServerPackages)
- [x] BaseService.luau
- [x] EarningsService.luau
- [x] FoodService.luau
- [x] MoneyUI.luau
- [x] FoodStoreUI.luau
- [x] BaseUI.luau
- [x] init.server.luau
- [x] init.client.luau
- [x] rojo build succeeds
- [x] Playtest: core loop works
- [x] Git commit: "Phase 1: MVP core loop"

---

## Phase 2: Full Rarity & Food System

- [x] Update Foods.luau (balanced costs, per-food rarityWeights)
- [x] Update FoodService.luau (removed Phase 1 gate, food.rarityWeights)
- [x] Update FoodStoreUI.luau (scrolling frame, all 8 tiers, affordability gating)
- [x] Update BaseUI.luau (new rarity colors, rarity label, Secret white text)
- [x] Playtest: food store works, rarity colors show, Base Full flashes
- [x] Git commit: "Phase 2: Full rarity and food system"

---

## Phase 3: Size System

- [x] Create Config/Sizes.luau
- [x] Update FoodService.luau (roll size)
- [x] Update EarningsService.luau (size multiplier)
- [x] Update BaseUI.luau (visual scaling)
- [x] Update FoodStoreUI.luau (size in reveal)
- [x] rojo build succeeds
- [x] Playtest: sizes vary, earnings scale
- [x] Git commit: "Phase 3: Size system"

---

## Phase 4: Base Mutations

- [x] Create Config/Mutations.luau
- [x] Update FoodService.luau (roll mutation)
- [x] Update EarningsService.luau (mutation multiplier)
- [x] Update BaseUI.luau (mutation visuals)
- [x] Update FoodStoreUI.luau (mutation in reveal)
- [x] Fix Base Full flicker (guard with baseFullShowing flag)
- [x] Playtest: mutations appear, earnings chain correctly
- [x] Git commit: "Phase 4: Base mutations"

---

## Phase 5: Base Management

- [x] Update BaseService.luau (capacity upgrades)
- [x] Create SellService.luau
- [x] Create SellUI.luau
- [x] Update BaseUI.luau (upgrade button, fencing, sell cleanup)
- [x] Update Remotes/init.luau (sell remotes)
- [x] Update init.server.luau + init.client.luau
- [x] Fix: sold brainrots now disappear from 3D world (soldIds in SellConfirmed)
- [x] Fix: fence and brainrots sit on ground (plotPosition Y=0)
- [x] Fix: Base Full message no longer flickers (state-transition tracking)
- [x] Fix: sell store list cleanup removes all children (not just Frames)
- [x] Playtest: upgrades work, sell works, fence visible, all bugs fixed
- [x] Git commit: "Phase 5: Base management and sell store"

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
| 2026-02-22 | Wally ProfileStore package name wrong in spec | Spec said `madstudioroblox/profilestore@1.2.2` — correct name is `lm-loleris/profilestore@1.0.3`. Also must use `[server-dependencies]` (not `[dependencies]`), packages go to `ServerPackages/` |
