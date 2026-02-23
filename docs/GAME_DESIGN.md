# Collect Brainrot's🦈 — Game Design Document

> **Status:** Living document — the single source of truth for all game data.
> **Last updated:** 2026-02-22
> **Game type:** Roblox Tycoon / Idle
> **Target platform:** Roblox (PC, Mobile, Console)

---

## Table of Contents

1. [Core Game Loop](#1-core-game-loop)
2. [Brainrots](#2-brainrots)
3. [Food Store](#3-food-store)
4. [Size System](#4-size-system)
5. [Base Mutations (from Food Purchase)](#5-base-mutations-from-food-purchase)
6. [Weather Events & Added Mutations](#6-weather-events--added-mutations)
7. [Earnings Formula](#7-earnings-formula)
8. [Base / Plot System](#8-base--plot-system)
9. [Sell Store](#9-sell-store)
10. [Collection Index / Codex](#10-collection-index--codex)
11. [Social Features](#11-social-features)
12. [Advanced Features](#12-advanced-features)
13. [Music & Sound](#13-music--sound)
14. [Tutorial](#14-tutorial)
15. [Approved Decisions Log](#15-approved-decisions-log)
16. [Explicitly Rejected Features](#16-explicitly-rejected-features)

---

## 1. Core Game Loop

```
Buy Food  ──>  Drop food on the ground inside your base
                        │
                        v
              Food attracts brainrots (rarity depends on food tier)
                        │
                        v
              Each attracted brainrot has a STAY CHANCE
              (depends on food tier — higher food = lower stay chance)
                        │
                  ┌─────┴─────┐
                  │           │
               STAYS       LEAVES
                  │        (gone forever)
                  v
          Brainrot joins your base
          Earns money/sec automatically
                  │
                  v
          Use money to buy better food
                  │
                  v
            ┌─────┴─────┐
            │           │
         Upgrade     Buy higher-tier
         base         food
         capacity        │
            │           v
            │     Attract rarer brainrots
            │           │
            └─────┬─────┘
                  │
                  v
              REPEAT
```

**Key points:**
- Food has NO cooldown — players can spam-drop food as long as they can afford it.
- Brainrots that stay are permanent until sold or gifted.
- Money accumulates passively (idle income) from all brainrots at your base.
- The loop is: **Buy food -> food attracts brainrots to your base -> chance they stay -> they earn money/sec -> buy better food -> repeat.**

---

## 2. Brainrots

There are **25 brainrots** across **8 rarity tiers**.

### 2.1 Rarity Summary

| Rarity | Count | Base $/sec | Color |
|---|---|---|---|
| Common | 5 | $5 | White |
| Rare | 4 | $50 | Blue |
| Epic | 4 | $1,250 | Purple |
| Legendary | 3 | $10,000 | Orange |
| Mythic | 3 | $100,000 | Red |
| Goldy | 2 | $750,000 | Gold |
| Secret | 2 | $5,000,000 | Teal |
| Unknown | 2 | $50,000,000 | Black / Void |

### 2.2 Full Brainrot Index

| # | Name | Rarity | Base $/sec | Description | Base Weight (lbs) |
|---|---|---|---|---|---|
| 1 | Burbaloni Lulilolli | Common | $5 | Bubble creature — a wobbly, translucent blob that floats around leaving a trail of tiny bubbles. Pops if you look at it wrong. | 12 |
| 2 | Hipocactus | Common | $5 | Hippo-cactus hybrid — a stubby green hippo covered in cactus spines. Friendly but hugging it is not recommended. | 85 |
| 3 | Bobrito Bandito | Common | $5 | Burrito bandit — a sentient burrito wearing a tiny sombrero and bandana. Will steal your salsa without remorse. | 8 |
| 4 | Talpa Di Ferro | Common | $5 | Iron mole — a mechanical mole made of rusted iron plates. Digs tunnels at alarming speed and eats metal scraps. | 45 |
| 5 | Svinino Bombondino | Common | $5 | Pig bomber — a round piglet strapped with comically large cartoon bombs. Oinks menacingly before every explosion. | 60 |
| 6 | Frigo Camelo | Rare | $50 | Camel fridge — a two-humped camel whose humps are actually mini-fridges stocked with cold beverages. Always chill. | 320 |
| 7 | Blueberrinni Octopussini | Rare | $50 | Blueberry octopus — a deep-blue octopus made entirely of blueberries. Each tentacle ends in a juicy berry cluster. | 25 |
| 8 | Orangutini Ananasini | Rare | $50 | Orangutan pineapple — an orangutan with pineapple-textured fur and a leafy green crown on its head. Tropical vibes only. | 150 |
| 9 | Tigrrullini Watermellini | Rare | $50 | Tiger watermelon — a fierce tiger with watermelon-striped fur. Seeds fly out when it roars. | 180 |
| 10 | Boneca Ambalabu | Epic | $1,250 | Surreal doll animal — a haunting porcelain doll fused with an unidentifiable animal. Its eyes follow you. Nobody knows what it is. | 30 |
| 11 | Chef Crabracadabra | Epic | $1,250 | Magic crab chef — a crab in a chef hat that performs cooking magic. Pulls full meals out of its shell like a culinary magician. | 40 |
| 12 | Glorbo Fruttodrillo | Epic | $1,250 | Fruit crocodile — a crocodile whose entire body is made of mixed tropical fruits. Bites are surprisingly nutritious. | 200 |
| 13 | Tralalero Tralala | Epic | $1,250 | Shark with Nikes — a great white shark wearing fresh Nike sneakers. Walks on land like it owns the place. Absolutely dripped out. | 450 |
| 14 | Shpioniro Golubiro | Legendary | $10,000 | Spy pigeon — a pigeon in a tiny trench coat and sunglasses. Carries classified documents in its beak. Trust no one. | 5 |
| 15 | Ballerina Cappuccina | Legendary | $10,000 | Cappuccino ballerina — a graceful ballerina made entirely of cappuccino foam. Pirouettes leave latte art on the ground. | 15 |
| 16 | Bombombini Gusini | Legendary | $10,000 | Goose with bombs — an angry goose carrying an absurd arsenal of cartoon bombs. Honks before detonation. Do not provoke. | 35 |
| 17 | Chimpanzini Bananini | Mythic | $100,000 | Monkey-banana hybrid — a chimpanzee fused with a giant banana. Peels its own skin to reveal another banana underneath. Infinite layers. | 90 |
| 18 | Brr Brr Patapim | Mythic | $100,000 | Refrigerator DJ — a walking refrigerator with turntables on top. Drops ice-cold beats and literal ice cubes simultaneously. | 280 |
| 19 | Cappuccino Assassino | Mythic | $100,000 | Killer coffee cup — a sentient espresso cup with a tiny assassin cloak and twin dagger stirring spoons. Deadly and caffeinated. | 10 |
| 20 | Lirili Larila | Goldy | $750,000 | Cactus elephant — a massive elephant covered entirely in cactus skin. Trumpets cause a rain of cactus needles. Majestic and painful. | 2,500 |
| 21 | Bombardiro Crocodilo | Goldy | $750,000 | Crocodile bomber plane — a crocodile with airplane wings and jet engines. Carpet-bombs the area with eggs on every flyby. | 1,800 |
| 22 | Tung Tung Tung Sahur | Secret | $5,000,000 | Log creature with bat — a sentient wooden log wielding a baseball bat. Wakes everyone up at 3 AM by banging on things. Relentless. | 120 |
| 23 | Trippi Troppi | Secret | $5,000,000 | Brain-like creature — a pulsating, exposed brain on tiny legs. Thinks thoughts so powerful they generate visible shockwaves. | 7 |
| 24 | Centralucci Nuclearucci | Unknown | $50,000,000 | Nuclear reactor creature — a walking nuclear power plant with cooling towers for horns. Glows green. Geiger counters hate this thing. | 50,000 |
| 25 | La Vaca Saturno Saturnita | Unknown | $50,000,000 | Saturn cow — a cosmic cow with Saturn's rings orbiting its midsection. Moos in frequencies that bend spacetime. | 999,999 |

---

## 3. Food Store

There are **8 food tiers**, one per rarity. Each food tier can attract brainrots **up to one rarity above its own tier** (with the exception of Unknown food, which caps at Unknown).

> **Note:** All costs are **placeholder values (TBD)** that scale exponentially. These will be balanced during Phase 2 testing.

| Food Tier | Cost (TBD) | Max Rarity Attracted | Stay Chance | Notes |
|---|---|---|---|---|
| Tier 1 — Common Chow | $50 | Up to Rare | 60% | Cheap slop. Gets the job done for beginners. |
| Tier 2 — Rare Rations | $500 | Up to Epic | 55% | Slightly fancier grub. Attracts more exotic creatures. |
| Tier 3 — Epic Eats | $5,000 | Up to Legendary | 45% | Gourmet-grade food. Brainrots take notice. |
| Tier 4 — Legendary Feast | $50,000 | Up to Mythic | 35% | A spread fit for kings. Only the notable show up. |
| Tier 5 — Mythic Meal | $500,000 | Up to Goldy | 28% | Otherworldly cuisine. Reality bends around it. |
| Tier 6 — Goldy Grub | $5,000,000 | Up to Secret | 22% | Food made of pure gold particles. Obscenely expensive. |
| Tier 7 — Secret Snack | $50,000,000 | Up to Unknown | 18% | Food that technically does not exist. How did you buy it? |
| Tier 8 — Unknown Elixir | $500,000,000 | Up to Unknown | 15% | A substance from beyond comprehension. Guarantees Unknown-tier attraction pool. |

**How attraction works:**
- When food is dropped, the game rolls a brainrot from the attraction pool (all rarities from Common up to the food's max rarity).
- Higher rarities within the pool are weighted to appear less frequently (exact weights TBD during balancing).
- After a brainrot is selected, the **stay chance** is rolled. If it fails, the brainrot leaves and the food is consumed (money spent).
- Food is consumed on use regardless of whether the brainrot stays.

---

## 4. Size System

Every brainrot that spawns is assigned a **random size tier**, weighted toward smaller sizes.

### 4.1 Size Tier Distribution & Multipliers

| Size Tier | Spawn Weight | Multiplier | Visual Scale |
|---|---|---|---|
| Tiny | 20% | 0.5x | 60% of normal model size |
| Small | 40% | 0.75x | 80% of normal model size |
| Medium | 29% | 1.0x | 100% of normal model size |
| Large | 10% | 1.75x | 130% of normal model size |
| Massive | 1% | 3.0x | 175% of normal model size |

### 4.2 Individual Brainrot Weights by Size Tier

Each brainrot has a **base weight** (listed in Section 2.2). The actual weight displayed scales with the size tier:

| Size Tier | Weight Modifier |
|---|---|
| Tiny | base weight x 0.4 |
| Small | base weight x 0.7 |
| Medium | base weight x 1.0 |
| Large | base weight x 1.5 |
| Massive | base weight x 2.5 |

**Full weight table (all 25 brainrots, all 5 sizes, in lbs):**

| # | Name | Base (lbs) | Tiny | Small | Medium | Large | Massive |
|---|---|---|---|---|---|---|---|
| 1 | Burbaloni Lulilolli | 12 | 4.8 | 8.4 | 12.0 | 18.0 | 30.0 |
| 2 | Hipocactus | 85 | 34.0 | 59.5 | 85.0 | 127.5 | 212.5 |
| 3 | Bobrito Bandito | 8 | 3.2 | 5.6 | 8.0 | 12.0 | 20.0 |
| 4 | Talpa Di Ferro | 45 | 18.0 | 31.5 | 45.0 | 67.5 | 112.5 |
| 5 | Svinino Bombondino | 60 | 24.0 | 42.0 | 60.0 | 90.0 | 150.0 |
| 6 | Frigo Camelo | 320 | 128.0 | 224.0 | 320.0 | 480.0 | 800.0 |
| 7 | Blueberrinni Octopussini | 25 | 10.0 | 17.5 | 25.0 | 37.5 | 62.5 |
| 8 | Orangutini Ananasini | 150 | 60.0 | 105.0 | 150.0 | 225.0 | 375.0 |
| 9 | Tigrrullini Watermellini | 180 | 72.0 | 126.0 | 180.0 | 270.0 | 450.0 |
| 10 | Boneca Ambalabu | 30 | 12.0 | 21.0 | 30.0 | 45.0 | 75.0 |
| 11 | Chef Crabracadabra | 40 | 16.0 | 28.0 | 40.0 | 60.0 | 100.0 |
| 12 | Glorbo Fruttodrillo | 200 | 80.0 | 140.0 | 200.0 | 300.0 | 500.0 |
| 13 | Tralalero Tralala | 450 | 180.0 | 315.0 | 450.0 | 675.0 | 1,125.0 |
| 14 | Shpioniro Golubiro | 5 | 2.0 | 3.5 | 5.0 | 7.5 | 12.5 |
| 15 | Ballerina Cappuccina | 15 | 6.0 | 10.5 | 15.0 | 22.5 | 37.5 |
| 16 | Bombombini Gusini | 35 | 14.0 | 24.5 | 35.0 | 52.5 | 87.5 |
| 17 | Chimpanzini Bananini | 90 | 36.0 | 63.0 | 90.0 | 135.0 | 225.0 |
| 18 | Brr Brr Patapim | 280 | 112.0 | 196.0 | 280.0 | 420.0 | 700.0 |
| 19 | Cappuccino Assassino | 10 | 4.0 | 7.0 | 10.0 | 15.0 | 25.0 |
| 20 | Lirili Larila | 2,500 | 1,000.0 | 1,750.0 | 2,500.0 | 3,750.0 | 6,250.0 |
| 21 | Bombardiro Crocodilo | 1,800 | 720.0 | 1,260.0 | 1,800.0 | 2,700.0 | 4,500.0 |
| 22 | Tung Tung Tung Sahur | 120 | 48.0 | 84.0 | 120.0 | 180.0 | 300.0 |
| 23 | Trippi Troppi | 7 | 2.8 | 4.9 | 7.0 | 10.5 | 17.5 |
| 24 | Centralucci Nuclearucci | 50,000 | 20,000.0 | 35,000.0 | 50,000.0 | 75,000.0 | 125,000.0 |
| 25 | La Vaca Saturno Saturnita | 999,999 | 399,999.6 | 699,999.3 | 999,999.0 | 1,499,998.5 | 2,499,997.5 |

---

## 5. Base Mutations (from Food Purchase)

When a brainrot is attracted and stays, it has a chance to arrive with a **base mutation**. This is rolled once at spawn time and is permanent.

**RULE: Only ONE base mutation per brainrot. Base mutations do NOT stack with each other.**

| Mutation | Chance | Earnings Multiplier | Visual Effect |
|---|---|---|---|
| None | 85% | 1.0x | Normal appearance |
| Gold | 8% | 1.5x | Entire model has a gold metallic shader |
| Diamond | 5% | 2.5x | Translucent crystalline body with light refraction |
| Rainbow | 2% | 5.0x | Cycling rainbow gradient across the entire model |

**Notes:**
- Base mutations are determined at the moment the brainrot spawns from food.
- A brainrot can have at most ONE base mutation (None, Gold, Diamond, or Rainbow).
- Base mutations CAN stack with ONE weather mutation (see Section 6).
- The mutation is permanent and cannot be changed, removed, or re-rolled.
- Base mutations are visually distinct and displayed in the brainrot's info panel.
- Codex tracks each mutation variant separately (see Section 10).

---

## 6. Weather Events & Added Mutations

Weather events occur **periodically** (frequency TBD — estimated every 10-30 minutes, lasting 2-5 minutes each). During an active weather event, all brainrots currently at the player's base have a chance to receive the corresponding weather mutation.

**RULE: Only ONE weather mutation per brainrot. Weather mutations CAN stack with ONE base mutation.**

### 6.1 Weather Event Table

| Weather Event | Mutation Name | Mutation Rarity | Earnings Multiplier | Chance to Apply (TBD) | Visual / Atmosphere |
|---|---|---|---|---|---|
| Rain | Soaked | Common | 1.5x | ~30% | Dark clouds, rainfall, puddles on the ground |
| Snow | Frozen | Uncommon | 2.0x | ~20% | Snowfall, frost on surfaces, breath visible |
| Storm | Shocked | Rare | 2.5x | ~15% | Lightning strikes, thunder, dark purple sky |
| Meteor Shower | Starstrucked | Epic | 5.0x | ~8% | Flaming meteors streak across the sky, craters form |
| Solar Flare | Burnt | Legendary | 10.0x | ~4% | Blinding orange light, heat distortion, fire particles |
| Nuclear | Radiated | Mythic | 35.0x | ~2% | Green toxic fog, radiation symbol in sky, Geiger crackle |
| Black Hole | Gravitated | Godly | 100.0x | ~1% | Sky tears open, everything warps toward center, void particles |

### 6.2 Weather Mutation Rules

- A brainrot can hold **at most ONE weather mutation** at a time.
- If a brainrot already has a weather mutation and a new weather event occurs, the new mutation **replaces** the old one only if the new mutation is of **higher rarity**. Otherwise, the existing mutation is kept.
- Weather mutations are visually layered on top of any existing base mutation (e.g., a Gold + Soaked brainrot shows gold shader with dripping water particles).
- Weather mutation application chances listed above are **per brainrot, per weather event** (TBD — will be tuned in Phase 2).

### 6.3 Weather Event Frequency (TBD)

| Weather Event | Estimated Frequency | Estimated Duration |
|---|---|---|
| Rain | Every 10-15 min | 3-5 min |
| Snow | Every 15-20 min | 3-5 min |
| Storm | Every 20-30 min | 2-4 min |
| Meteor Shower | Every 30-45 min | 2-3 min |
| Solar Flare | Every 45-60 min | 1-3 min |
| Nuclear | Every 60-90 min | 1-2 min |
| Black Hole | Every 90-120 min | 30 sec - 1 min |

> All frequencies and durations are TBD and will be balanced during Phase 2 testing.

---

## 7. Earnings Formula

```
money/sec = base_rarity_income x size_multiplier x base_mutation_multiplier x weather_mutation_multiplier
```

All four factors are multiplied together. If a brainrot has no base mutation, that multiplier is 1.0x. If it has no weather mutation, that multiplier is 1.0x.

### 7.1 Example Calculations

---

**Example 1: Basic Common Brainrot (worst case)**

- Brainrot: Burbaloni Lulilolli (Common)
- Size: Tiny (0.5x)
- Base Mutation: None (1.0x)
- Weather Mutation: None (1.0x)

```
$5 x 0.5 x 1.0 x 1.0 = $2.50/sec
```

---

**Example 2: Decent Mid-Tier Brainrot**

- Brainrot: Tralalero Tralala (Epic)
- Size: Medium (1.0x)
- Base Mutation: Gold (1.5x)
- Weather Mutation: None (1.0x)

```
$1,250 x 1.0 x 1.5 x 1.0 = $1,875.00/sec
```

---

**Example 3: Strong Legendary Roll**

- Brainrot: Bombombini Gusini (Legendary)
- Size: Large (1.75x)
- Base Mutation: Diamond (2.5x)
- Weather Mutation: Shocked (2.5x)

```
$10,000 x 1.75 x 2.5 x 2.5 = $109,375.00/sec
```

---

**Example 4: God-Roll Unknown (theoretical maximum)**

- Brainrot: La Vaca Saturno Saturnita (Unknown)
- Size: Massive (3.0x)
- Base Mutation: Rainbow (5.0x)
- Weather Mutation: Gravitated (100.0x)

```
$50,000,000 x 3.0 x 5.0 x 100.0 = $75,000,000,000.00/sec ($75 billion/sec)
```

> This is the absolute theoretical maximum earnings for a single brainrot. The chance of this combination occurring is astronomically low (Unknown rarity from food x 1% Massive x 2% Rainbow x Black Hole event x ~1% Gravitated).

---

## 8. Base / Plot System

The player's base is a **fenced area** (inspired by the "Grow a Garden" style in Roblox). Brainrots roam freely within the fenced area once they join.

### 8.1 Base Capacity

| Level | Slots | Upgrade Cost (TBD) |
|---|---|---|
| 1 (Starting) | 1 | Free |
| 2 | 2 | $200 |
| 3 | 3 | $600 |
| 4 | 5 | $2,000 |
| 5 | 7 | $7,000 |
| 6 | 10 | $25,000 |
| 7 | 13 | $100,000 |
| 8 | 16 | $400,000 |
| 9 | 20 | $1,500,000 |
| 10 | 24 | $6,000,000 |
| 11 | 27 | $25,000,000 |
| 12 (Max) | 30 | $100,000,000 |

> All upgrade costs are TBD and will be balanced during Phase 2 testing. Cap is **30 brainrot slots**.

### 8.2 Food Mechanics

- Food is **dropped on the ground** inside the base by clicking/tapping.
- There is **NO cooldown** — players can spam food as fast as they can afford it.
- Each food drop is consumed immediately (costs money, attracts one brainrot attempt).
- If the base is full (all slots occupied), food **cannot be dropped** — a warning is shown.

### 8.3 Plot System

| Phase | Plots Available |
|---|---|
| MVP (Phase 1) | 1 plot |
| Final Version | 6 plots |

- Each plot is a separate fenced area with its own capacity and brainrots.
- All plots share the same wallet/currency.
- Plots are purchased with in-game money (costs TBD).
- Each plot can be upgraded independently.
- Each plot has its own 30-slot cap.
- Total theoretical maximum: 6 plots x 30 slots = **180 brainrots**.

---

## 9. Sell Store

Players can sell brainrots for in-game money. The sell store is accessible from the base.

### 9.1 Sell Options

| Option | Description |
|---|---|
| **Sell Individual** | Select a specific brainrot from your base and sell it. |
| **Sell All (Bulk Sell)** | Sell your entire inventory of brainrots at once. Confirmation prompt required. |

### 9.2 Sell Price Formula

```
sell_price = base_rarity_income x 60 x size_multiplier x base_mutation_multiplier
```

> Sell price equals approximately **60 seconds worth** of that brainrot's base earnings (factoring in size and base mutation, but NOT weather mutation). Weather mutations are lost on sale and do not affect price.

### 9.3 Sell Price Examples

| Brainrot | Size | Base Mutation | Sell Price |
|---|---|---|---|
| Burbaloni Lulilolli (Common, $5) | Small (0.75x) | None (1.0x) | $5 x 60 x 0.75 x 1.0 = **$225** |
| Tralalero Tralala (Epic, $1,250) | Medium (1.0x) | Gold (1.5x) | $1,250 x 60 x 1.0 x 1.5 = **$112,500** |
| La Vaca Saturno Saturnita (Unknown, $50M) | Massive (3.0x) | Rainbow (5.0x) | $50,000,000 x 60 x 3.0 x 5.0 = **$45,000,000,000** |

---

## 10. Collection Index / Codex

The Codex is a collectible catalogue that tracks every brainrot variant the player has ever owned.

### 10.1 Codex Sections

| Section | Requirement | Completion Reward |
|---|---|---|
| **Normal** | Own (or have owned) all 25 brainrots with no base mutation | **Normal Fence** (cosmetic upgrade) |
| **Gold** | Own (or have owned) all 25 brainrots with Gold base mutation | **Gold Fence** (cosmetic upgrade) |
| **Diamond** | Own (or have owned) all 25 brainrots with Diamond base mutation | **Diamond Fence** (cosmetic upgrade) |
| **Rainbow** | Own (or have owned) all 25 brainrots with Rainbow base mutation | **Rainbow Fence** (cosmetic upgrade) |

### 10.2 Codex Details

- Each section contains all 25 brainrots as entries.
- An entry is "discovered" the moment the player receives that brainrot variant (it stays discovered even if sold or gifted away).
- The Codex displays: brainrot model, name, rarity, description, base $/sec, and whether it has been discovered.
- Undiscovered entries show a silhouette/question mark.
- Section completion percentage is displayed.
- Fence cosmetic rewards apply to all plots and are purely visual.

---

## 11. Social Features

### 11.1 Gifting (No Trading)

- Players can **gift** a brainrot from their base to another player.
- Gifting is **one-way** — there is no trade confirmation, no exchange, no barter.
- The gifted brainrot retains its size, base mutation, and weather mutation.
- The recipient must have an open slot in their base to receive the gift.
- **There is NO trading system.** See Section 16.

### 11.2 Leaderboards

| Leaderboard | Metric | Display |
|---|---|---|
| **Richest Players** | Total money earned (lifetime) | Top 100 |
| **Most Dedicated** | Total time played (hours) | Top 100 |
| **Biggest Spenders** | Total Robux spent in-game | Top 100 |

- Leaderboards are server-wide (global).
- Updated in real-time.
- Accessible from a board at the spawn area.

### 11.3 Rival Bases

- Other players' bases are visible nearby in the game world.
- Players can walk up to and view (but not interact with) other players' bases.
- This creates a social comparison / flex dynamic.
- Players cannot steal, interact with, or modify other players' brainrots.

---

## 12. Advanced Features

### 12.1 Brainrot Fusion

Combine **3 brainrots of the same name and rarity** to produce **1 brainrot of the next rarity up**.

| Input | Output |
|---|---|
| 3x any Common brainrot (same name) | 1x random Rare brainrot |
| 3x any Rare brainrot (same name) | 1x random Epic brainrot |
| 3x any Epic brainrot (same name) | 1x random Legendary brainrot |
| 3x any Legendary brainrot (same name) | 1x random Mythic brainrot |
| 3x any Mythic brainrot (same name) | 1x random Goldy brainrot |
| 3x any Goldy brainrot (same name) | 1x random Secret brainrot |
| 3x any Secret brainrot (same name) | 1x random Unknown brainrot |
| Unknown brainrots | **Cannot be fused** |

**Fusion rules:**
- All 3 input brainrots must be the **same name** (e.g., 3x Burbaloni Lulilolli).
- Size, mutations, etc. of the inputs are **discarded** — the output brainrot is freshly rolled (new random size, new base mutation roll).
- The output brainrot is a **random** brainrot from the next rarity tier.
- Fusion consumes the 3 input brainrots permanently.

### 12.2 Lucky Hours

- **Random 5-minute windows** where rare spawn rates are **doubled (2x)**.
- Announced server-wide with a special UI banner and sound effect.
- Frequency: TBD (estimated every 30-60 minutes).
- During Lucky Hours, the rarity weighting in food attraction rolls is shifted to favor higher rarities within the food's attraction pool.
- Stacks with food tier (a player using Mythic Meal during Lucky Hour gets 2x the normal chance at higher rarities).

### 12.3 VIP Food

- **Limited-time event food** that is available during special events (holidays, game milestones, etc.).
- VIP Food **guarantees** attraction of a specific rarity tier (no lower-rarity dilution in the pool).
- Cost: Premium currency (Robux) or extremely high in-game currency cost (TBD).
- Duration of availability: Limited (hours to days).
- VIP Food still respects stay chance — the brainrot can still leave.
- VIP Food does NOT guarantee base mutations.

### 12.4 Brainrot Personalities

Each brainrot spawns with a **random personality tag** that slightly affects earnings and adds unique idle animations.

| Personality | Earnings Modifier | Animation Style |
|---|---|---|
| Lazy | 0.9x (−10%) | Slow movement, frequent sleeping, yawning |
| Chill | 1.0x (neutral) | Relaxed posture, slow wandering, vibing |
| Grumpy | 1.1x (+10%) | Angry idle animations, stomping, huffing |
| Hyper | 1.2x (+20%) | Fast movement, jumping, zooming around base |

**Rules:**
- Personality is assigned randomly at spawn (equal 25% chance each).
- Personality is permanent and cannot be changed.
- Personality modifier is applied as an additional multiplier in the earnings formula (after all other multipliers).
- Personality is displayed in the brainrot's info panel and visible in the Codex.

> **Note:** When personality is factored in, the full earnings formula becomes:
> `money/sec = base_rarity_income x size_multiplier x base_mutation_multiplier x weather_mutation_multiplier x personality_modifier`

---

## 13. Music & Sound

### 13.1 Background Music

| Game State | Music Mood | Description |
|---|---|---|
| Normal (no weather) | Joyful / Upbeat | Light, bouncy, happy tycoon music. Sets a fun and welcoming tone. |
| Rain | Gloomy / Melancholy | Soft piano with rain ambiance. Calm and slightly sad. |
| Snow | Gloomy / Peaceful | Gentle bells, muffled sounds, quiet winds. Winter wonderland feel. |
| Storm | Thriller / Suspense | Intense drums, deep bass, tension building. |
| Meteor Shower | Thriller / Epic | Orchestral swells, dramatic crescendos, awe-inspiring. |
| Solar Flare | Thriller / Intense | Distorted synths, alarm-like tones, heat haze audio. |
| Nuclear | Thriller / Dread | Low drones, Geiger counter clicks, oppressive atmosphere. |
| Black Hole | Thriller / Cosmic Horror | Deep void sounds, reversed audio, reality-warping effects. |

### 13.2 Sound Effects

| Event | Sound |
|---|---|
| Drop food | Soft "plop" / plate clink |
| Brainrot attracted | Curious creature sound + sparkle |
| Brainrot stays | Celebration jingle + confetti pop |
| Brainrot leaves | Sad trombone / deflation sound |
| Money earned (milestone) | Cash register "ka-ching" |
| Base mutation (Gold) | Metallic shimmer |
| Base mutation (Diamond) | Crystal chime |
| Base mutation (Rainbow) | Magical ascending arpeggio |
| Weather starts | Ambient transition + weather-specific intro |
| Weather mutation applied | Element-specific impact sound |
| Sell brainrot | Register beep + coin sounds |
| Fusion | Energy buildup + explosion + reveal fanfare |
| Lucky Hour starts | Trumpet fanfare + announcement |
| Codex entry discovered | Book page turn + discovery chime |
| Base upgrade | Construction hammer + level-up sound |

---

## 14. Tutorial

### 14.1 Onboarding Flow

The tutorial is a **guided, linear onboarding** that walks new players through the core loop. It triggers automatically on first join.

**Starting money:** $100 (enough for 2x Tier 1 Common Chow at $50 each).

### 14.2 Tutorial Steps

| Step | Instruction | Trigger |
|---|---|---|
| 1 | "Welcome to Collect Brainrot's! Let's get your first brainrot." | Player spawns for the first time |
| 2 | "Walk to the Food Store and buy some Common Chow." | Arrow pointing to Food Store |
| 3 | "Now walk to your base and drop the food on the ground." | Arrow pointing to base, food item in inventory |
| 4 | "A brainrot is coming! Let's see if it stays..." | Brainrot attraction animation plays |
| 5a | (If stays) "Your first brainrot joined your base! It's now earning money for you." | Brainrot enters base |
| 5b | (If leaves) "It left! Don't worry — buy another food and try again." | Redirect to step 2 |
| 6 | "See your money going up? That's your brainrot earning for you." | Highlight money counter |
| 7 | "When you have enough money, buy better food to attract rarer brainrots!" | Tutorial complete badge |

### 14.3 Tutorial Safeguards

- First food drop during tutorial has an **increased stay chance** (90%) to avoid frustrating new players.
- Tutorial can be skipped by experienced players (skip button appears after step 1).
- Tutorial progress is saved — if a player disconnects mid-tutorial, they resume where they left off.

---

## 15. Approved Decisions Log

This is the master record of all design decisions and their current status.

| # | Decision | Status | Notes |
|---|---|---|---|
| 1 | Core loop: buy food → attract brainrot → earn money → repeat | **APPROVED** | Fundamental game loop. Non-negotiable. |
| 2 | 25 brainrots across 8 rarity tiers | **APPROVED** | Full roster defined in Section 2. |
| 3 | Base $/sec values per rarity | **APPROVED** | Common $5 through Unknown $50M. |
| 4 | 8 food tiers matching 8 rarities | **APPROVED** | Structure approved; costs TBD. |
| 5 | Food costs (exponential scaling) | **TBD** | Placeholder values. Phase 2 balancing. |
| 6 | Stay chance per food tier (60% down to 15%) | **APPROVED** | May be fine-tuned in Phase 2. |
| 7 | Food attracts up to one rarity above its tier | **APPROVED** | E.g., Common food can attract up to Rare. |
| 8 | 5 size tiers (Tiny through Massive) | **APPROVED** | Weights: 20/40/29/10/1. |
| 9 | Size multipliers (0.5x to 3.0x) | **APPROVED** | Tiny 0.5x, Small 0.75x, Medium 1.0x, Large 1.75x, Massive 3.0x. |
| 10 | Per-brainrot base weight in lbs | **APPROVED** | Full table in Section 4.2. |
| 11 | 4 base mutations (None/Gold/Diamond/Rainbow) | **APPROVED** | Only ONE per brainrot. |
| 12 | Base mutation chances (85/8/5/2) | **APPROVED** | |
| 13 | Base mutations do NOT stack with each other | **APPROVED** | Only one base mutation allowed. |
| 14 | 7 weather events with corresponding mutations | **APPROVED** | Rain through Black Hole. |
| 15 | Weather mutations CAN stack with base mutations | **APPROVED** | Max one of each type. |
| 16 | Weather mutation replaces only if higher rarity | **APPROVED** | Lower/equal rarity weather does not overwrite. |
| 17 | Weather event frequencies and durations | **TBD** | Estimates in Section 6.3. Phase 2 balancing. |
| 18 | Weather mutation application chances | **TBD** | Estimates in Section 6.1. Phase 2 balancing. |
| 19 | Earnings formula (4-factor multiplication) | **APPROVED** | base x size x base_mut x weather_mut. |
| 20 | Fenced base area ("Grow a Garden" style) | **APPROVED** | |
| 21 | Starting capacity: 1 slot | **APPROVED** | |
| 22 | Max capacity: 30 slots per plot | **APPROVED** | |
| 23 | Base upgrade costs (scaling) | **TBD** | Placeholder values. Phase 2 balancing. |
| 24 | No food cooldown (spam allowed) | **APPROVED** | |
| 25 | 1 plot for MVP, 6 plots for final version | **APPROVED** | |
| 26 | Sell individual and bulk sell | **APPROVED** | |
| 27 | Sell price = 60 sec of base earnings | **APPROVED** | Weather mutation not included in sell price. |
| 28 | Codex with 4 sections (Normal/Gold/Diamond/Rainbow) | **APPROVED** | |
| 29 | Fence cosmetic rewards for Codex completion | **APPROVED** | |
| 30 | No trading — gifting only | **APPROVED** | See Section 16 (rejected features). |
| 31 | Leaderboards (money, time, Robux) | **APPROVED** | |
| 32 | Rival bases visible nearby | **APPROVED** | View-only, no interaction. |
| 33 | Brainrot Fusion (3 same → 1 next rarity) | **APPROVED** | |
| 34 | Lucky Hours (random 5-min 2x rare rates) | **APPROVED** | Frequency TBD. |
| 35 | VIP Food (event-limited, guarantees rarity) | **APPROVED** | Availability and pricing TBD. |
| 36 | Brainrot Personalities (Lazy/Chill/Grumpy/Hyper) | **APPROVED** | Earnings modifiers: 0.9x/1.0x/1.1x/1.2x. |
| 37 | Music shifts based on weather | **APPROVED** | See Section 13. |
| 38 | Guided tutorial with starting $100 | **APPROVED** | Boosted stay chance on first drop. |
| 39 | No rebirth/prestige system | **APPROVED** | Explicitly rejected. |
| 40 | No daily quests or achievements | **APPROVED** | Explicitly rejected. |
| 41 | No player cosmetics (base cosmetics only) | **APPROVED** | Explicitly rejected. |
| 42 | Rarity weighting in food attraction pools | **TBD** | Exact weights per rarity within pool. Phase 2 balancing. |
| 43 | Multiple plot purchase costs | **TBD** | Phase 2. |
| 44 | Lucky Hour frequency | **TBD** | Estimated 30-60 min intervals. |
| 45 | VIP Food pricing (Robux / in-game) | **TBD** | Event-dependent. |

---

## 16. Explicitly Rejected Features

The following features have been **deliberately excluded** from the game design. They should NOT be implemented.

| Rejected Feature | Reason |
|---|---|
| **Rebirth / Prestige System** | Adds unnecessary complexity. The game's depth comes from rarity chasing, mutations, and collection — not resetting progress. Idle progression should feel permanent. |
| **Daily Quests / Achievements** | Creates obligation-based gameplay that conflicts with the chill idle loop. Players should log in because they want to, not because a streak is at risk. |
| **Player Cosmetics** | Cosmetics are reserved for base decoration (fences from Codex completion). Player avatar customization is handled by Roblox itself — no in-game player skins or outfits. |
| **Trading** | Trading creates scam vectors, black markets, and balance exploitation. Gifting (one-way, no exchange) preserves the social element without the downsides. |

---

## Appendix A: Quick Reference — Rarity Color Codes

| Rarity | Hex Color | RGB |
|---|---|---|
| Common | `#FFFFFF` | 255, 255, 255 |
| Rare | `#3498DB` | 52, 152, 219 |
| Epic | `#9B59B6` | 155, 89, 182 |
| Legendary | `#E67E22` | 230, 126, 34 |
| Mythic | `#E74C3C` | 231, 76, 60 |
| Goldy | `#F1C40F` | 241, 196, 15 |
| Secret | `#1ABC9C` | 26, 188, 156 |
| Unknown | `#2C3E50` | 44, 62, 80 |

## Appendix B: Quick Reference — All Multiplier Ranges

| System | Min Multiplier | Max Multiplier |
|---|---|---|
| Size | 0.5x (Tiny) | 3.0x (Massive) |
| Base Mutation | 1.0x (None) | 5.0x (Rainbow) |
| Weather Mutation | 1.0x (None) | 100.0x (Gravitated) |
| Personality | 0.9x (Lazy) | 1.2x (Hyper) |
| **Combined Maximum** | **0.5 x 1.0 x 1.0 x 0.9 = 0.45x** | **3.0 x 5.0 x 100.0 x 1.2 = 1,800.0x** |

> Theoretical max single-brainrot income: $50,000,000 x 1,800.0 = **$90,000,000,000/sec** ($90 billion/sec) with personality factored in.

---

*End of Game Design Document.*
