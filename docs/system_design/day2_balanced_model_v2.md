# FarmGame System Design - Day 2 Balanced Economy Model v2

## 1. Purpose

```text
This document is the validated implementation candidate for Day 3.

It resolves the starting inventory, purchase timing, planting capacity,
machine material cost and missing selling-system contradictions found in
Day 2 Scenario Model v1.
```

This document separates three categories:

- Runtime-confirmed facts: values already found in the Godot project.
- Selected design values: final Balanced candidate values selected for Day 3 implementation.
- Day 4 playtest assumptions: values that must be measured and may be tuned after testing.

This document is a design contract only. It does not modify game code, resources, scenes, project settings or runtime data.

## 2. Problems Found in v1

## Problem 1 - Starting Coin Mismatch

Day 2 Scenario Model v1 recommended Balanced starting coins as 150, but its five-day cumulative income and purchase timing tables still started from 250 coins.

Correction:

```text
Balanced Starting Coins = 150
```

All corrected Balanced cumulative coin and purchase timing calculations must start from 150.

## Problem 2 - Starting Crop Inventory Mismatch

The v1 Balanced starting crop inventory was:

- Tomato 2
- Corn 2
- Pumpkin 1
- Wheat 8

Total crop inventory:

```text
2 + 2 + 1 + 8 = 13 crops
```

However, the Expected scenario assumed 16 planted tiles on Day 1. The player cannot plant 16 crop tiles with only 13 crop items because the current planting system consumes one mature crop item per planted tile.

Correction:

```text
Expected Day 1 planting requires at least 16 plantable crop items.
```

The selected Balanced starting inventory is increased to support a real 16-tile Expected opening.

## Problem 3 - Machine Resource Costs Are Unreachable

Current machine costs are:

- Sprinkler: Tomato 30 + Wheat 20
- Fisher: Wood 25 + Fish 15
- Scarecrow: Pumpkin 15 + Corn 15

After reducing starting inventory, these material costs cannot be obtained by the intended purchase days.

Therefore, the v1 targets:

- Sprinkler Day 2
- Fisher Day 3
- Scarecrow Day 5

only checked coin affordability. They did not verify material feasibility.

Correction:

```text
Machine shop cost becomes Blueprint Coin Cost.
Machine material cost moves to per-placement Placement Material Cost.
```

## Problem 4 - No Selling Interface Exists

The current game has no:

- Shipping Bin
- Sell Button
- Shop Sell Mode
- Inventory Sell Interaction
- Crop/Fish to Coin conversion

Therefore, "Sell Price" can exist as a design concept, but Day 3 has no existing sell flow to use directly.

Correction:

```text
Day 3 uses activity coin rewards instead of a generic selling system.
```

## Problem 5 - Machine Unlock and Placement Are Confused

Current machine resource costs are used by the shop as permanent unlock costs. After unlock, the player can place unlimited copies for free.

Current structure:

```text
One-time resource payment
-> Permanent blueprint unlock
-> Unlimited free machine placement
```

This cannot create stable machine investment costs.

Correction:

```text
Shop purchase unlocks the blueprint.
Each placement consumes a small material recipe.
```

## 3. Selected Minimal Economy Architecture

Day 3 should use the following minimal changes. It should not add a complex selling system.

## 3.1 Activity Coin Rewards

Do not add a Shipping Bin or full selling UI.

Use this structure:

```text
Crop Harvest
-> Receive crop inventory
-> Receive crop-type coin reward

Successful Manual Fishing
-> Receive Generic Fish x1
-> Receive manual fishing coin reward
```

Use these terms in code and documentation:

- `Crop Coin Reward`
- `Manual Fishing Coin Reward`

Do not call these true "Sell Price" values in Day 3 code because the player is not performing a selling action.

Design reasons:

- Uses existing harvest and fishing settlement functions.
- Does not require complex new UI.
- Creates a testable coin income loop within the five-day scope.
- Still allows Day 4 to compare activity income per unit of player time.
- Can later be replaced by a Shipping Bin or proper selling system.

## 3.2 Manual Fishing Only

Only successful manual fishing gives coins.

Automatic Fisher behavior:

- Produces Generic Fish item only.
- Does not automatically produce coins.
- Does not trigger `Manual Fishing Coin Reward`.

This prevents automatic machines from creating unlimited coins.

## 3.3 Blueprint Unlock + Placement Recipe

Machine system:

```text
Shop Coin Payment
-> Permanently unlock machine blueprint

Each Machine Placement
-> Consume machine-specific material recipe
```

Therefore:

- Shop no longer deducts machine material recipes.
- Shop checks and deducts only the machine blueprint coin price.
- Each machine placement checks and deducts materials.
- Placement is blocked if materials are insufficient.
- Delete does not refund materials for Day 3.
- Do not add machine upgrades, durability, fuel or capacity systems.

This is the Day 3 minimal system adjustment.

## 3.4 Hats

Hats remain one-time purchases.

Hat unlock structure:

```text
Coin Cost + Existing Resource Cost
-> Permanently unlock style
```

Hats do not involve placement, so they continue to deduct resources at shop purchase time.

## 4. Final Balanced Values

## Crop Coin Rewards

| Crop    | Growth Days | Sustainable Net Yield Basis | Coin Reward per Harvested Tile | Long-Run Coin per Tile per Day |
| ------- | ----------: | --------------------------: | -----------------------------: | -----------------------------: |
| Wheat   |           3 |              1 surplus unit |                             20 |                           6.67 |
| Corn    |           3 |              1 surplus unit |                             25 |                           8.33 |
| Tomato  |           4 |              1 surplus unit |                             40 |                          10.00 |
| Pumpkin |          12 |              1 surplus unit |                            150 |                          12.50 |

Rules:

- Harvest amount remains 2.
- Coin Reward is paid once per mature tile harvest.
- Do not pay a separate coin reward for each dropped crop item.
- One mature tile can trigger only one coin reward per harvest.
- Preserve this long-run return order:

```text
Wheat < Corn < Tomato < Pumpkin
```

Pumpkin has the highest return but the longest wait.

## Manual Fishing Coin Reward

```text
Manual Fishing Coin Reward = 25
```

On successful manual fishing:

```text
Generic Fish inventory +1
Coins +25
```

On failed manual fishing:

```text
Fish +0
Coins +0
```

Automatic Fisher output:

```text
Generic Fish inventory +1
Coins +0
```

## Quest Reward

Keep:

```text
Mira Quest Reward = 100 Coins
```

## 5. Final Starting Inventory

Selected Balanced start:

| Item    | Current Runtime | Selected Balanced Start |
| ------- | --------------: | ----------------------: |
| Wheat   |              50 |                      10 |
| Corn    |              50 |                       8 |
| Tomato  |              50 |                       6 |
| Pumpkin |              50 |                       3 |
| Fish    |              50 |                       0 |
| Wood    |              50 |                      10 |
| Apple   |              50 |                       5 |
| Coin    |             250 |                     150 |

## Expected Day 1 Planting

| Crop    | Starting Amount | Planted on Day 1 | Reserved |
| ------- | --------------: | ---------------: | -------: |
| Wheat   |              10 |                6 |        4 |
| Corn    |               8 |                4 |        4 |
| Tomato  |               6 |                4 |        2 |
| Pumpkin |               3 |                2 |        1 |
| Total   |              27 |               16 |       11 |

Notes:

- Expected scenario can actually plant 16 tiles.
- Reserved resources allow the player to pay for the first machine placement materials.
- The player cannot gain opening coins by selling starting inventory because Day 3 does not implement generic selling.
- Starting inventory no longer behaves like 50-item debug stacks.
- The player still makes resource allocation choices:
  - Expand planting area.
  - Save machine materials.
  - Buy cosmetics.
  - Complete quests.

## 6. Final Blueprint Coin Prices

| Blueprint / Product | Coin Price | Intended Affordable Day |
| ------------------- | ---------: | ----------------------- |
| Cowboy Hat          |        300 | Day 2                   |
| Baseball Hat        |        300 | Day 2+                  |
| Beanie              |        300 | Day 2+                  |
| Sprinkler Blueprint |        400 | Day 3                   |
| Fisher Blueprint    |        600 | Day 4                   |
| Scarecrow Blueprint |        900 | Day 5                   |

Final hat costs use Option A from the resource feasibility check:

| Hat      | Coin Cost | Resource Cost      |
| -------- | --------: | ------------------ |
| Cowboy   |       300 | Wood 6 + Corn 4    |
| Baseball |       300 | Tomato 6 + Apple 4 |
| Beanie   |       300 | Pumpkin 2 + Wheat 4 |

Notes:

- Not every hat must be immediately material-ready.
- Cowboy is the easiest early cosmetic purchase.
- Buying Cowboy consumes most early Wood and Corn, delaying Fisher or Scarecrow preparation.
- This creates intentional opportunity cost.

## 7. Final Machine Placement Recipes

The old high machine material costs are redefined and reduced into per-placement costs.

| Machine   | Blueprint Coin Cost | Material Cost per Placement |
| --------- | ------------------: | --------------------------- |
| Sprinkler |                 400 | Tomato 2 + Wheat 4          |
| Fisher    |                 600 | Wood 8 + Fish 4             |
| Scarecrow |                 900 | Pumpkin 1 + Corn 4          |

Rules:

- Blueprint is purchased once.
- Materials are deducted on every placement.
- A second machine placement requires paying materials again.
- Do not deduct materials before tile validity is confirmed.
- Validate tile legality first, then attempt setup, then deduct materials and register `machine_cells` only on successful placement.
- If instance creation or `setup()` fails, do not deduct materials and do not occupy `machine_cells`.
- Delete does not refund materials.

## Sprinkler

- Uses farming resources.
- Supports farming efficiency.
- Starting reserves can pay for the first placement.
- Later placements require continued farming.

## Fisher

- Requires Wood and manually obtained Fish.
- The player must participate in manual fishing before building automatic production.
- Cowboy Hat and Fisher compete for Wood.

## Scarecrow

- Uses long-term Pumpkin and Corn.
- Matches the defensive farming role.
- Beanie and Scarecrow compete for Pumpkin and Wheat/Corn-like resources.

## 8. Corrected Expected Scenario

Use:

- Starting Coins = 150
- Active Crop Tiles = 16
- Wheat 6
- Corn 4
- Tomato 4
- Pumpkin 2
- Manual fishing attempts per day = 5
- Fishing success rate = 70%
- Expected successful catches = 3.5 per day
- Manual Fish reward = 25
- Expected fishing income = 87.5 per day
- Quest completed on Day 3
- Quest reward = 100
- 3-day crops first reward on Day 4
- Tomato first rewards on Day 5
- Pumpkin does not mature in the first 5 days

Corrected calculation:

| Day   | Farming Income | Fishing Income | Quest Income | Total Daily Income | Cumulative Coins |
| ----- | -------------: | -------------: | -----------: | -----------------: | ---------------: |
| Day 1 |              0 |           87.5 |            0 |               87.5 |            237.5 |
| Day 2 |              0 |           87.5 |            0 |               87.5 |            325.0 |
| Day 3 |              0 |           87.5 |          100 |              187.5 |            512.5 |
| Day 4 |            220 |           87.5 |            0 |              307.5 |            820.0 |
| Day 5 |            160 |           87.5 |            0 |              247.5 |          1,067.5 |

Day 4 farming income:

```text
Wheat: 6 tiles x 20 = 120
Corn: 4 tiles x 25 = 100
Day 4 Farming Total = 220
```

Day 5 farming income:

```text
Tomato: 4 tiles x 40 = 160
```

## 9. Corrected Five-Day Income Share

| Source         | Five-Day Income | Share |
| -------------- | --------------: | ----: |
| Farming        |             380 | 41.4% |
| Manual Fishing |           437.5 | 47.7% |
| Quest          |             100 | 10.9% |
| Total Earned   |           917.5 |  100% |

Result:

- Manual Fishing is below 50%.
- Farming is stable but delayed income.
- Fishing provides early active cash flow.
- Quest is a one-time milestone reward.
- Both repeatable activities have meaningful value.

## 10. Corrected Coin Affordability

Assumption:

```text
The player has not spent coins yet and is saving for one item at a time.
```

| Purchase            | Price | Earliest Coin-Affordable Day | Target | Result |
| ------------------- | ----: | ---------------------------: | -----: | ------ |
| First Hat           |   300 |                        Day 2 |  Day 2 | Pass   |
| Sprinkler Blueprint |   400 |                        Day 3 |  Day 3 | Pass   |
| Fisher Blueprint    |   600 |                        Day 4 |  Day 4 | Pass   |
| Scarecrow Blueprint |   900 |                        Day 5 |  Day 5 | Pass   |

Notes:

- This checks coin affordability only.
- Actual purchase timing also depends on material availability and prior spending.
- If the player buys a hat, they will not simultaneously hit all listed machine dates.
- That is an economic choice, not a model error.

## 11. Resource Feasibility Check

Available initially after Expected planting:

```text
Wheat 4
Corn 4
Tomato 2
Pumpkin 1
Fish 0
Wood 10
Apple 5
Coins 150
```

| Machine / Product | Required Materials | Available Initially After Expected Planting | Immediately Material-Ready |
| ----------------- | ------------------ | ------------------------------------------- | -------------------------- |
| Sprinkler         | Tomato 2 + Wheat 4 | Tomato 2 + Wheat 4                          | Yes                        |
| Fisher            | Wood 8 + Fish 4    | Wood 10 + Fish 0                            | No                         |
| Scarecrow         | Pumpkin 1 + Corn 4 | Pumpkin 1 + Corn 4                          | Yes                        |
| Cowboy            | Wood 8 + Corn 6    | Wood 10 + Corn 4                            | No                         |

Fisher:

- Requires the player to manually catch 4 Fish.
- In the Expected scenario, this should take about 2 days.
- Coin price still delays the blueprint to around Day 4.

Cowboy with old resource cost:

- After Expected planting, only Corn 4 is reserved.
- Old Cowboy cost requires Corn 6.
- Therefore Cowboy would be coin-affordable on Day 2 but fully material-affordable later.

Two correction options:

## Option A

```text
Reduce Cowboy resource cost to Wood 6 + Corn 4
```

## Option B

```text
Keep Cowboy resource cost and accept the first fully affordable hat around Day 4
```

Selected option:

```text
Option A
```

Reason:

- Keeps resource consumption meaningful.
- Makes Day 2 cosmetic spending actually reachable.
- Still consumes Wood and Corn, creating competition with Fisher and Scarecrow.
- Brings all hat recipes closer to the reduced starting inventory economy.

Final hat recipes:

| Hat      | Coin Cost | Resource Cost      |
| -------- | --------: | ------------------ |
| Cowboy   |       300 | Wood 6 + Corn 4    |
| Baseball |       300 | Tomato 6 + Apple 4 |
| Beanie   |       300 | Pumpkin 2 + Wheat 4 |

## 12. Implementation Terminology

Use these terms consistently in Day 3:

| Design Term                | Meaning |
| -------------------------- | ------- |
| Crop Coin Reward           | Coins awarded when harvesting one mature crop tile |
| Manual Fishing Coin Reward | Coins awarded when player manual fishing succeeds |
| Blueprint Coin Cost        | Coins required to permanently unlock a machine blueprint |
| Placement Material Cost    | Materials consumed each time a machine is placed |
| Cosmetic Coin Cost         | Coins required to unlock a style |
| Cosmetic Material Cost     | Resources also consumed when unlocking a style |

Avoid using:

- Sell Price
- Seed Cost
- Machine Purchase Quantity

These concepts do not exist in the current Day 3 implementation plan.

## 13. Day 3 Implementation Contract

Day 3 must implement:

1. Adjust initial inventory to Balanced Start.
2. Add Coin Reward data for four crops.
3. Add coins once when harvesting a mature crop tile based on crop type.
4. Add 25 coins on successful manual fishing.
5. Automatic Fisher must not grant coins.
6. Add Coin Cost for shop products.
7. Before purchase, validate both coins and required resources.
8. Deduct coins correctly after successful purchase.
9. Block purchase when balance is insufficient.
10. Move machine shop resource costs to per-placement recipes.
11. Validate materials before every machine placement.
12. Deduct materials and register `machine_cells` only after tile legality and machine setup succeed.
13. Placement failure must not deduct materials.
14. Purchased machine blueprints remain permanently unlocked.
15. Unlocked shop products remain hidden from the shop.
16. Player-visible failure feedback is not the core requirement in this pass, but console errors should be clear.
17. Do not implement generic selling UI.
18. Do not implement Shipping Bin.
19. Do not implement save system.
20. Do not implement machine refund, upgrade, fuel or capacity.

## 14. Day 4 Required Measurements

| Metric                              | Current Model Assumption |
| ----------------------------------- | -----------------------: |
| Manual fishing success rate         |                      70% |
| Manual fishing average duration     |               18 seconds |
| Fishing attempts per day            |                        5 |
| Active crop tiles                   |                       16 |
| Average real play time per game day |               15 minutes |
| First full cosmetic purchase        |                    Day 2 |
| Sprinkler blueprint purchase        |                    Day 3 |
| Fisher blueprint purchase           |                    Day 4 |
| Scarecrow blueprint purchase        |                    Day 5 |

If Day 4 data differs from assumptions, tune in this priority order:

1. Manual Fishing Coin Reward
2. Machine Blueprint Coin Cost
3. Initial Coins
4. Crop Coin Rewards

Do not prioritize changing crop growth times because they already define the four crops' core differences.

## 15. Final Validation

| Validation                                                 | Result | Reason |
| ---------------------------------------------------------- | ------ | ------ |
| Starting inventory supports Expected planting              | Pass | 27 starting crop items support 16 planted tiles. |
| Expected planting uses exactly 16 tiles                    | Pass | Wheat 6 + Corn 4 + Tomato 4 + Pumpkin 2 = 16. |
| Coin projections start from 150                            | Pass | Corrected cumulative table starts at 150 coins. |
| No repeatable income source exceeds 50%                    | Pass | Manual Fishing is 47.7%; Farming is 41.4%. |
| First coin purchase occurs Day 2                           | Pass | 325 coins by Day 2 can afford a 300-coin hat. |
| First machine blueprint occurs Day 3                       | Pass | 512.5 coins by Day 3 can afford Sprinkler Blueprint at 400. |
| Fisher requires prior manual fishing                       | Pass | Fisher placement requires Fish 4 and starting Fish is 0. |
| Machine placement is no longer free                        | Pass | Every placement has a material recipe. |
| Automatic Fisher does not create coins                     | Pass | Only manual fishing grants Manual Fishing Coin Reward. |
| No generic selling UI required                             | Pass | Coins come from harvest and manual fishing settlement. |
| Values can be implemented without new complex architecture | Pass | Uses existing harvest, fishing, shop and machine placement flows. |

## Final Day 3 Candidate Summary

Selected candidate:

```text
Balanced Economy v2
```

Core Day 3 implementation values:

- Starting Coins: 150
- Manual Fishing Coin Reward: 25
- Mira Quest Reward: 100
- Crop Coin Rewards: Wheat 20, Corn 25, Tomato 40, Pumpkin 150
- Blueprint Coin Costs: Sprinkler 400, Fisher 600, Scarecrow 900
- Cosmetic Coin Cost: 300 each
- First practical cosmetic route: Cowboy, using Wood 6 + Corn 4
- Machine placement recipes: Sprinkler Tomato 2 + Wheat 4, Fisher Wood 8 + Fish 4, Scarecrow Pumpkin 1 + Corn 4
