# Day 4 V1 Playtest Protocol

This is a controlled five-day benchmark playtest.

The purpose is to compare the Balanced Economy v2 assumptions against
real player behavior and runtime results.

The player must follow the same route during V1 and V2 testing so that
the Before / After comparison remains valid.

## Test Purpose

This protocol verifies:

1. Whether the game starts normally.
2. Whether Playtest Telemetry creates and updates JSON logs.
3. Time to first income.
4. Real manual fishing success rate.
5. Real average manual fishing duration.
6. Real play time per game day.
7. Day 5 final coins and inventory.
8. Income share from farming, fishing, and quest rewards.
9. Real purchase timing for Cowboy and machine blueprints.
10. Whether machine placement materials create meaningful limits.
11. Whether the economy loop has obvious blockers or progresses too quickly.

## Preflight Runtime Check

Before the official run, perform one short non-official launch check.

### Preflight Steps

1. Open the project in the Godot editor.
2. Run the main scene.
3. Check for GDScript parse errors.
4. Confirm the game reaches the level scene.
5. Confirm the Output console prints the telemetry log absolute path.
6. Open that path and confirm the JSON file was created.
7. Complete one manual fishing attempt or another income event.
8. Confirm the JSON file updates.
9. End this non-official run.
10. Fully close the running game process.

### Preflight Failure Rule

Stop the official test immediately if any of these occur:

- The game cannot start.
- GDScript parse errors appear.
- Telemetry functions error.
- JSON cannot be created.
- Harvest, fishing, shop, placement, or day-end flow crashes.
- Game behavior is visibly different from the intended Day 3 build.

Record the full error message, file, line number, and screenshot if possible. Do not continue the five-day run and do not adjust values.

### Clean Start

After a successful preflight:

1. Fully stop the game.
2. Mark the preflight JSON as non-official or move it out of the test folder.
3. Restart the game to create a new V1 JSON log.
4. Use the new JSON as the official V1 record.
5. Do not restart the game during the official five-day test.

## Fixed Test Rules

V1 and future V2 must use the same rules.

- Start from a fresh game process.
- Do not modify Inspector values.
- Do not use the debugger to modify inventory.
- Do not use temporary cheat code.
- Do not shorten growth cycles.
- Do not manually add coins or resources.
- Do not idle intentionally to farm automatic machine output.
- Do not exploit bugs.
- Do not change behavior to match model predictions.
- When runtime results differ from the model, runtime results win.
- End each day only after completing the listed activities.
- End each day through the normal bed or day-change flow.
- Do not repeatedly skip days to bypass activities.
- Only perform economic activities listed in this protocol.

## Fixed Daily Activity Order

Every day must follow this order:

```text
1. Farming
2. Harvest and immediate replanting
3. Water all active crops
4. Manual fishing attempts
5. Quest and NPC interactions
6. Shop purchase check
7. Machine placement check
8. End the day
```

If an activity cannot be performed that day, record the reason and continue to the next item. Do not change the order to wait for coins or crop maturity.

## Day 1 Planting Plan

Day 1 plants exactly 16 tiles:

| Crop | Tiles |
| ---- | ----: |
| Wheat | 6 |
| Corn | 4 |
| Tomato | 4 |
| Pumpkin | 2 |
| Total | 16 |

Actions:

1. Choose 16 tiles in the starting farm area.
2. Plant the exact crop counts above.
3. Water all 16 tiles.
4. Do not plant a 17th tile.
5. Do not use remaining crops for extra expansion.

Expected inventory after planting:

| Crop | Starting | Planted | Remaining |
| ---- | -------: | ------: | --------: |
| Wheat | 10 | 6 | 4 |
| Corn | 8 | 4 | 4 |
| Tomato | 6 | 4 | 2 |
| Pumpkin | 3 | 2 | 1 |

If actual inventory differs, record the issue and stop the official test because initial data may not have loaded correctly.

## Crop Maintenance Rule

Each day:

- Water every active crop.
- Harvest mature crops immediately.
- Replant the same crop type on the same tile immediately after harvest.
- Each harvested tile gives 2 crop items; use 1 of those items for replanting.
- Keep active crop capacity fixed at 16 tiles.
- Do not use harvest output to plant a 17th tile.
- Do not change the crop ratio.

Purpose:

```text
Keep active crop capacity fixed at 16 tiles
while measuring sustainable repeatable income.
```

If replanting fails, record:

- Crop type
- Game day
- Inventory before harvest
- Inventory after harvest
- Replant failure reason

## Manual Fishing Rule

Each day must include exactly:

```text
5 manual fishing attempts
```

Attempt definition:

```text
Fishing minigame is successfully opened.
```

Rules:

- Success and failure both count as attempts.
- Perform exactly 5 attempts per day.
- Do not add attempts after failures.
- Do not reduce attempts after early income.
- Do not selectively abandon difficult fish.
- Do not reload failed results.
- Do not count automatic Fisher output as manual fishing.
- Stop manual fishing for the day after 5 attempts.

Telemetry should record attempts, successes, failures, total duration, average duration, and manual fishing income.

Manual check before ending each day:

```text
Today completed exactly 5 manual fishing attempts: Yes / No
```

## Mira Quest Rule

Interact with Mira as early as possible and accept the current quest if available.

The current quest objective is:

```text
Harvest Wheat x3
```

The model assumed a Day 3 quest reward, but the playtest must record the real achievable reward day. If the reward is actually claimed on Day 4, that is model correction evidence, not a test failure.

Record:

- Day quest was accepted
- Day objective became complete
- Day the 100 coin reward was actually claimed
- Whether duplicate reward occurred
- Whether extra interaction was needed to claim

## Fixed Purchase Policy

Use this fixed benchmark priority:

```text
1. Cowboy Style
2. Sprinkler Blueprint
3. Fisher Blueprint
4. Scarecrow Blueprint
```

Do not purchase:

- Baseball
- Beanie
- Any other non-protocol item

Purchase check timing: after farming, 5 fishing attempts, and quest interaction.

Only check the current highest-priority unpurchased product each day.

### Cowboy

Buy immediately when all are true:

```text
Coins >= 300
Wood >= 6
Corn >= 4
```

If coins are sufficient but resources are not, record:

```text
Coin-affordable but resource-blocked
```

### Sprinkler Blueprint

Only start saving for Sprinkler after Cowboy is purchased.

Buy immediately when:

```text
Coins >= 400
```

### Fisher Blueprint

Only start saving for Fisher after Sprinkler Blueprint is purchased.

Buy immediately when:

```text
Coins >= 600
```

### Scarecrow Blueprint

Only start saving for Scarecrow after Fisher Blueprint is purchased.

Buy immediately when:

```text
Coins >= 900
```

This is not optimal play. It is a fixed benchmark route to test how one cosmetic purchase affects machine progression.

## Machine Placement Policy

After buying a machine blueprint, immediately try to place one corresponding machine.

### Sprinkler

Materials:

```text
Tomato 2 + Wheat 4
```

Rules:

- Place near the farm on a valid tile.
- Place only one Sprinkler.
- Do not place a second Sprinkler.
- If materials are insufficient, record the blocker.
- If position is invalid, choose one other valid position and retry once.

### Fisher

Materials:

```text
Wood 8 + Fish 4
```

Rules:

- Place only one Fisher.
- Must be placed adjacent to water.
- First intentionally try one obvious no-adjacent-water position as a failure test.
- After failure, check that materials were not deducted, the tile remains usable, and no invisible machine remains.
- Then place at a valid adjacent-water position.
- Do not repeat the intentional failure test.

### Scarecrow

Materials:

```text
Pumpkin 1 + Corn 4
```

Rules:

- Place only one Scarecrow.
- Do not test combat efficiency in this run.
- Only verify economic cost and placement success.

### Delete Tool

Do not delete successfully placed machines during the official five-day route. Delete can be checked after the five-day run without affecting main economic data.

## Exact Five-Day Route

### Day 1

1. Confirm initial inventory.
2. Plant 16 tiles: Wheat 6, Corn 4, Tomato 4, Pumpkin 2.
3. Water all 16 tiles.
4. Accept Mira quest if available.
5. Complete 5 manual fishing attempts.
6. Do not buy anything.
7. Do not place machines.
8. End Day 1 normally.

### Day 2

1. Check all crop states.
2. Water all active crops.
3. Complete 5 manual fishing attempts.
4. Perform Mira quest interaction.
5. Check Cowboy purchase conditions.
6. Buy Cowboy if conditions are met.
7. Do not buy anything else.
8. End Day 2 normally.

### Day 3

1. Maintain 16 crop tiles.
2. Harvest any actually mature crops and immediately replant same type.
3. Water all active crops.
4. Complete 5 manual fishing attempts.
5. Perform Mira quest interaction.
6. If Cowboy is not purchased, check Cowboy again.
7. If Cowboy is purchased, check Sprinkler Blueprint.
8. If Sprinkler is bought, immediately try placing one Sprinkler.
9. End Day 3 normally.

### Day 4

1. Harvest actually mature Wheat/Corn.
2. Replant same crop type immediately on each harvested tile.
3. Water all 16 tiles.
4. Complete 5 manual fishing attempts.
5. Complete and claim Mira quest if genuinely available.
6. Check the next purchase by priority.
7. If a blueprint is bought, immediately try placing one corresponding machine.
8. End Day 4 normally.

### Day 5

1. Harvest actually mature crops.
2. Replant same crop type immediately on each harvested tile.
3. Water all 16 tiles.
4. Complete 5 manual fishing attempts.
5. Perform Mira interaction.
6. Check the next purchase by priority.
7. If a blueprint is bought, immediately try placing one corresponding machine.
8. Do not perform extra money-making activities.
9. End Day 5 normally.
10. Wait for console output:

```text
DAY 5 PLAYTEST COMPLETE
```

11. Record the JSON absolute path.
12. Stop the game.

## Manual Observation Sheet

### Per-Day Notes

| Day | Confusing Moment | Waiting / Boredom | Strong Choice | Bug / Unexpected Behavior |
| --- | ---------------- | ----------------- | ------------- | ------------------------- |
| 1 | | | | |
| 2 | | | | |
| 3 | | | | |
| 4 | | | | |
| 5 | | | | |

### Required Questions

1. Did Day 1 have a clear goal?
2. Did 5 fishing attempts feel too many, too few, or appropriate?
3. Did fishing feel more profitable than farming?
4. Did the first days depend too heavily on fishing while waiting for crops?
5. Did buying Cowboy create a real tradeoff?
6. Did Cowboy delay machine progress too much?
7. Did the first machine appear too early, too late, or at the right time?
8. Were machine material costs easy to understand?
9. Did Fisher's Fish 4 material cost feel meaningful?
10. Did Pumpkin's 12-day cycle feel almost absent in the five-day demo?
11. Did the coin UI show income and spending promptly?
12. Did shop displayed prices match actual deductions?
13. When a purchase failed, was the missing requirement understandable?
14. When placement failed, was the failure reason understandable?
15. Did Day 5 still have a clear goal?

## Expected Model Values

These are comparison references only. The test does not need to hit these values.

| Metric | Balanced Model Assumption |
| ------ | ------------------------: |
| Fishing attempts | 25 |
| Fishing success rate | 70% |
| Average fishing duration | 18 seconds |
| Active crops | 16 |
| Crop income by Day 5 | 380 |
| Fishing income by Day 5 | 437.5 |
| Quest income | 100 |
| Total earned income | 917.5 |
| Ending coins before spending | 1,067.5 |

Notes:

- Actual coins are integers, so partial-fish model values are only estimates.
- Quest reward may be claimable on Day 4 instead of Day 3.
- The fixed route includes Cowboy, so final Day 5 coins will be lower than a no-spending model.
- Differences are the test result, not a failure.

## Stop Conditions

Stop immediately and preserve evidence if any occur:

- Game crashes.
- JSON stops updating.
- Harvest does not grant coins.
- Same crop grants coins multiple times.
- One fishing attempt grants coins multiple times.
- Automatic Fisher grants coins.
- Failed purchase deducts coins or resources.
- Failed machine placement deducts materials.
- Failed machine placement occupies a tile.
- Day end does not generate a snapshot.
- Day ID is recorded incorrectly.
- Economy data differs from UI display.
- GDScript errors prevent any system from continuing.

Record:

- Game day
- Step being performed
- Expected result
- Actual result
- Console error
- JSON content
- Screenshot

Do not fix code and continue the same run. After a fix, restart from Day 1 with a new V1 log.

## Required Deliverables

After the V1 test, provide:

1. Official V1 JSON log.
2. Per-day manual observation sheet.
3. Console errors or warnings.
4. Day 5 final inventory screenshot.
5. Day 5 coin screenshot.
6. Shop purchase screenshot.
7. At least one machine placement screenshot.
8. Fisher failed-placement result if Fisher unlocks before Day 5 ends.
9. Final summary:

| Metric | V1 Actual |
| ------ | --------: |
| First income time | |
| Total play time through Day 5 | |
| Fishing attempts | |
| Fishing successes | |
| Fishing success rate | |
| Fishing average duration | |
| Farming income | |
| Fishing income | |
| Quest income | |
| Highest income source share | |
| Total earned income | |
| Total coin spending | |
| Day 5 final coins | |
| First purchase day | |
| First machine blueprint day | |
| First machine placement day | |
| Day 5 active crops | |
| Day 5 placed machines | |

## Scope Confirmation

- This protocol does not modify the game.
- This protocol does not require the tester to hit predicted model values.
- All actual data comes from real play and telemetry.
- V2 must reuse the same five-day route.
- Any mid-run code fix invalidates the current test and requires restarting from Day 1.
- No balance values are adjusted at this stage.
