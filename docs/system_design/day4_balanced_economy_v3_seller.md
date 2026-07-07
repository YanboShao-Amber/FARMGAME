# Balanced Economy v3 — Seller Economy Rebalance (Phase G)

Run label: **V2_SELLER**. This document accompanies the numeric rebalance of the seller
economy. It changes values only — no gameplay logic, feature, or system behavior was altered.

## 1. Design Goals
- Make farming the stable primary income; keep fishing valuable but not dominant.
- Let the player afford the first machine blueprint (Sprinkler) around Day 2–3.
- Ensure a purchased Sprinkler can actually be *placed* around Day 4 (recipe uses early crops).
- Let the player afford or approach the second blueprint (Fisher) by Day 5.
- Give a fully chopped tree a meaningful Wood payout.
- Keep cosmetic styles as optional sinks — never a prerequisite to machine progression.
- Establish an independent V2 telemetry label + design doc for a fresh 5-day playtest.

Machine progression priority (protocol only, not enforced in shop code):
1. Sprinkler  2. Fisher  3. Scarecrow. Cowboy/Baseball/Beanie are optional cosmetics.

## 2. Previous Values (v2)
- Sale prices: Wheat 10, Corn 12, Tomato 20, Pumpkin 75, Fish 25.
- Blueprints: Sprinkler 400, Fisher 600, Scarecrow 900.
- Placement: Sprinkler {Tomato 2, Wheat 4}, Fisher {Wood 8, Fish 4}, Scarecrow {Pumpkin 1, Corn 4}.
- Tree yield: 1 Wood per fully chopped tree.
- Run label: V1.

## 3. Balanced Economy v3 Values
- Sale prices: Wheat **12**, Corn **15**, Tomato **25**, Pumpkin **80**, Fish **15**.
- Blueprints: Sprinkler **250**, Fisher **350**, Scarecrow **500**.
- Placement: Sprinkler **{Wheat 4, Corn 2}**, Fisher **{Wood 6, Fish 3}**, Scarecrow **{Pumpkin 1, Corn 4}** (unchanged).
- Tree yield: **5 Wood** per fully chopped tree.
- Run label: **V2_SELLER**.

## 4. Sale Price Rationale
Selling to the Courier remains the only crop/fish → coin path (harvest and manual fishing grant
no coins; Phase E). Per-tile harvest is ×2, so per-harvest value:
- Wheat ×2 = 24, Corn ×2 = 30, Tomato ×2 = 50, Pumpkin ×2 = 160, Fish ×1 = 15.
Late-maturing crops are worth more per unit; Fish dropped 25→15 so a fast fishing minigame no
longer out-earns farming.

## 5. Blueprint Price Rationale
Halving-ish the costs (250/350/500) matches realistic Day 1–5 coin accumulation so the Sprinkler
is the first automation buy (~Day 2–3), Fisher the second (~Day 4–5), and Scarecrow a later goal.
Shop UI and the purchase transaction both read `Data.MACHINE_BLUEPRINT_COIN_COSTS` (no duplicated
prices), so the new costs display and charge consistently; failed buys don't charge; owned
blueprints can't be re-charged.

## 6. Placement Recipe Rationale
Sprinkler previously required Tomato (matures Day 5), stranding a Day-2/3 blueprint until late.
The v3 recipe uses Wheat + Corn (both mature Day 4, ×2 each), so a Sprinkler bought early can be
placed the same day the first crops mature. Fisher trimmed to Wood 6 + Fish 3. Scarecrow keeps
Pumpkin 1 + Corn 4 (Pumpkin is the long-lead crop, so it stays a late goal). All recipes use mature
crops — never `*_SEED`. Placement reads `Data.MACHINE_PLACEMENT_COSTS`; invalid/failed placement
deducts nothing; success deducts once.

## 7. Tree Wood Yield
- **Before:** `tree.gd hit()` added `+1` Wood when `tree_health` hit exactly 0 → **1 Wood** per tree.
- **After:** `+5` Wood at the same point → **5 Wood** per fully chopped tree (Option A: single grant).
- **Timing:** on the single AXE hit that brings `tree_health` from 1 to 0 (tree HP = `APPLE_TREE_HEALTH` = 4, so the 4th hit).
- **Duplicate guard:** the existing `if tree_health == 0:` exact check fires once only (further hits push
  health negative and skip the block); the tree's body collision is disabled on destruction as well.
  Axe damage, tree HP, animation, and apple-drop logic are unchanged.

## 8–9. Day 1–5 Forecast (Low / Expected / High fishing)
Model (verified in `resources/plant_res.gd` + `level.gd`): crops grow once per day-transition
(`age += grow_speed`, mature at `age >= 3`, watered daily). **Wheat/Corn (1.0) mature Day 4,
Tomato (0.75) Day 5, Pumpkin (0.25) ~Day 13 (not within the 5-day window).**

Fixed route: Day-1 plant Wheat 6 / Corn 4 / Tomato 4 / Pumpkin 2; water all; harvest at maturity
(×2/tile); replant when seeds remain; 5 fishing attempts/day, fish sold same day at 15 each; sell
crops/fish to Courier; Mira quest (+100) claimed at first harvest (Day 4). Fishing scenarios:
Low 40% → 2.0 fish/day (30c), Expected 55% → 2.75 fish/day (~41c), High 70% → 3.5 fish/day (~53c).

### Expected (55%)
| Day | Crop Sale | Fish Sale | Quest | Balance (end) | Possible Purchase |
| --- | --------: | --------: | ----: | ------------: | ----------------- |
| 1 | 0 | 41 | 0 | 191 | — |
| 2 | 0 | 41 | 0 | 232 | — |
| 3 | 0 | 41 | 0 | 273 → 23 | **Buy Sprinkler (250)** |
| 4 | 186 (8 wheat + 6 corn; reserve 4W/2C) | 41 | 100 | 350 → 0 | **Place Sprinkler**, **Buy Fisher (350)** |
| 5 | 200 (8 tomato) | 41 | 0 | 241 | Place Fisher (Wood 6 + Fish 3) |

### Low (40%)
| Day | Crop | Fish | Quest | Balance | Purchase |
| --- | ---: | ---: | ----: | ------: | -------- |
| 1 | 0 | 30 | 0 | 180 | — |
| 2 | 0 | 30 | 0 | 210 | — |
| 3 | 0 | 30 | 0 | 240 | — (short of 250) |
| 4 | 186 | 30 | 100 | 556 → 306 | **Buy + Place Sprinkler (250)** |
| 5 | 200 | 30 | 0 | 536 → 186 | **Buy Fisher (350)** |

### High (70%)
| Day | Crop | Fish | Quest | Balance | Purchase |
| --- | ---: | ---: | ----: | ------: | -------- |
| 1 | 0 | 53 | 0 | 203 | — |
| 2 | 0 | 53 | 0 | 256 → 6 | **Buy Sprinkler (250)** |
| 3 | 0 | 53 | 0 | 59 | — |
| 4 | 186 | 53 | 100 | 398 → 48 | **Place Sprinkler**, **Buy Fisher (350)** |
| 5 | 200 | 53 | 0 | 301 | approaching Scarecrow (500) |

## 10. V2 Seller Playtest Targets
| Target | Result |
| ------ | ------ |
| Sprinkler blueprint affordable Day 2–3 | ✅ High (D2), Expected (D3); ⚠ Low slips to D4 |
| Sprinkler placeable ~Day 4 | ✅ all scenarios (Wheat/Corn mature D4; recipe = 4W/2C) |
| Fisher affordable/approached by Day 5 | ✅ Expected/High buy D4, Low buys D5 |
| Player not required to buy any Style | ✅ styles never gate progression |
| Fish income < 50% of total | ✅ ~24% (Low) / ~30% (Expected) / ~35% (High) |
| Scarecrow not required before Day 5 | ✅ remains a later goal |
| ≥1 machine placed by Day 5 | ✅ Sprinkler placed D4 all scenarios |
| 2 machines possible for active player | ✅ Fisher blueprint by D4–D5; placement Wood 6 (~2 trees) + Fish 3 |

## 11. Known Limitations
- **Days 1–3 income is fishing + starting coins only**, because nothing matures until Day 4. The
  target of "reduce fishing dominance" holds *overall* (crop payouts on Days 4–5 dwarf fishing), but
  the early game is still fishing-funded. Acceptable for a 5-day test; revisit if early pacing feels off.
- **Low-fishing (40%) delays the Sprinkler blueprint to Day 4** (misses the Day 2–3 window). Implemented
  values are kept as specified; this is a worst-case deviation to watch in the real V2 playtest.
- **Pumpkin does not mature within 5 days** (Day ~13), so the 80-coin price and the 2 Day-1 pumpkin
  tiles contribute nothing in-window — they're "banked" for a longer run. Tomato pays out only on Day 5.
- Forecast assumes the Mira quest is claimed on Day 4 and that the player has ~6 Wood (≈2 trees, now
  5 Wood each) + 3 Fish spare to place the Fisher; actual timing depends on player behavior.

## 12. Systems Deliberately Not Changed
Style coin/resource costs; starting inventory (Coin 150, seeds 6/8/3/10, crops 0, Wood 10, Apple 5,
Fish 0); harvest quantity (×2); Mira quest reward (100); manual fishing (Fish ×1) and auto Fisher
(Fish ×1); crop grow speeds; machine performance; `MACHINE_UPGRADE_COST` (display metadata);
`try_sell_item` validation and the Courier / Sell UI visuals; Player, Mira, Quest, Tool/Inventory UI;
weather; combat; slime AI; input map; `project.godot`; the root legacy `global/data.gd`; existing PNGs.
Harvest and manual fishing still grant **no** coins — the Courier sale remains the crop/fish → coin path.
