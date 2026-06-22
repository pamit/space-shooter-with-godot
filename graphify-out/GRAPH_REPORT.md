# Graph Report - space-shooter  (2026-06-22)

## Corpus Check
- 31 files · ~578,287 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 240 nodes · 209 edges · 32 communities (19 shown, 13 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `645d055c`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]
- [[_COMMUNITY_Community 22|Community 22]]
- [[_COMMUNITY_Community 23|Community 23]]
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 25|Community 25]]
- [[_COMMUNITY_Community 26|Community 26]]
- [[_COMMUNITY_Community 27|Community 27]]
- [[_COMMUNITY_Community 28|Community 28]]
- [[_COMMUNITY_Community 29|Community 29]]
- [[_COMMUNITY_Community 31|Community 31]]

## God Nodes (most connected - your core abstractions)
1. `Changelog (iterative updates after initial plan)` - 17 edges
2. `File Structure` - 14 edges
3. `UI and Graphics Upgrade Implementation Plan` - 13 edges
4. `Task 2 Report: Difficulty formulas (pure, tested)` - 10 edges
5. `Task 12 Report: HUD, Main Menu, and Main scene wiring` - 9 edges
6. `Final Review Fix Report — feature/mvp` - 8 edges
7. `Task 3 Report: Save Data (Pure JSON Read/Write, Tested)` - 7 edges
8. `Task 7 Report: Enemy base + 3 movement-pattern types` - 7 edges
9. `Task 9 Report: Pickups (weapon, shield, speed, bomb)` - 7 edges
10. `Level & Boss Flow (current)` - 7 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (32 total, 13 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.11
Nodes (18): Changes Made, Code Review Fix: Extract boss_fire_interval_decay to GameConstants, Concerns, Difficulty.gd Implementation, Failing Test Run (Before Implementation), Files Created, Git Commit, Git Commit (+10 more)

### Community 1 - "Community 1"
Cohesion: 0.11
Nodes (17): File Structure, Follow-ups (explicitly out of scope for this plan), Global Constraints, Space Shooter MVP Implementation Plan, Task 10: Wave spawner — drives procedural waves + pickup drops, Task 11: Parallax starfield background, Task 12: HUD, Main Menu, and Main scene wiring, Task 13: Audio hooks (structural — no bundled files) (+9 more)

### Community 2 - "Community 2"
Cohesion: 0.09
Nodes (22): A. Kenney-first (fastest), Approaches Considered, B. Hybrid — Kenney gameplay + custom diegetic UI (recommended, **shipped**), C. Shader-heavy polish, Entity Visual Reference (current), File Structure (as shipped), Global Constraints (as shipped), HUD Layout (current) (+14 more)

### Community 3 - "Community 3"
Cohesion: 0.13
Nodes (14): Commit, Concerns, Git diff scope check, Headless smoke tests, Scene files — new child nodes added (stream left empty), scripts/boss.gd, scripts/enemy_base.gd, scripts/pickup.gd (+6 more)

### Community 4 - "Community 4"
Cohesion: 0.14
Nodes (13): Collision Layers (Verified), Commit, Files Created, Implementation Details, Notes, Parse Check, Script Features, Summary (+5 more)

### Community 5 - "Community 5"
Cohesion: 0.15
Nodes (12): Additional verification performed (beyond the brief, for confidence — not committed), Brief's literal Step 5 command, Code Review Fixes, Commit, Commit, Concerns / notes for the controller, Finding 1 (dead code): Remove `or true` condition in `_input(event)`, Finding 2 (magic number): Extract hardcoded `20.0` contact damage to constant (+4 more)

### Community 6 - "Community 6"
Cohesion: 0.17
Nodes (11): Commit, Files changed, Final Review Fix Report — feature/mvp, Finding 1 (Critical) — Player-enemy contact bypasses death contract, Finding 2 (Minor) — dead code cleanup, Finding 3 (Minor) — extract remaining balance magic numbers, Finding 4 (Important) — missing test assertions, Scene smoke test (+3 more)

### Community 7 - "Community 7"
Cohesion: 0.17
Nodes (11): Concerns, Dependencies & Verification, Files Created, Step 1: Write Failing Test, Step 2: Verify Test Fails, Step 3: Write Implementation, Step 4: Verify Test Passes, Step 5: Commit (+3 more)

### Community 8 - "Community 8"
Cohesion: 0.18
Nodes (10): Commit, Files Created, Implementation Details, Notes, Parse/Compile Check, Scene (scenes/Boss.tscn), Script (scripts/boss.gd), Summary (+2 more)

### Community 9 - "Community 9"
Cohesion: 0.20
Nodes (9): Code Review Fix: GameOverPanel process_mode, Commit, Concerns, Files written, Pre-implementation cross-check (per instructions), Summary, Task 12 Report: HUD, Main Menu, and Main scene wiring, Verification — Step 5 (script parse check) (+1 more)

### Community 10 - "Community 10"
Cohesion: 0.20
Nodes (9): Code Review, Code Review Fix: Guard save_to() Against Null FileAccess, Commit Details, Status, Step 2: Initial Failing Test, Step 4: Passing Test, Task 3 Report: Save Data (Pure JSON Read/Write, Tested), Test Results (+1 more)

### Community 11 - "Community 11"
Cohesion: 0.25
Nodes (7): Collision fix applied (per instructions, deviates from brief's literal text), Commit, Concerns / flags, Status: DONE_WITH_CONCERNS, Task 7 Report: Enemy base + 3 movement-pattern types, Verification — Step 5 (script parse check), What was done

### Community 12 - "Community 12"
Cohesion: 0.29
Nodes (6): Commit, Summary, Task 11 Implementation Report, Technical Notes, Verification, What Was Done

### Community 13 - "Community 13"
Cohesion: 0.29
Nodes (6): Commit, Concerns, Steps taken, Summary, Task 5 Report: GameManager + SaveManager autoload singletons, Test commands and output

### Community 14 - "Community 14"
Cohesion: 0.33
Nodes (5): Commit, Concerns, Task 10 Report: Wave spawner, Verification, What was done

### Community 15 - "Community 15"
Cohesion: 0.33
Nodes (5): Commit created, Concerns, Task 1 Report: Project scaffold + balance constants, Verification command and output, What was done

### Community 17 - "Community 17"
Cohesion: 0.50
Nodes (3): Refinements, Screenshots, Space Shooter with Godot

### Community 31 - "Community 31"
Cohesion: 0.12
Nodes (17): Bug fixes (across sessions), Changelog (iterative updates after initial plan), Session 10 — Combat tuning, pickups, pause menu, HUD polish, Session 11 — Combat zone, pause UX, VFX, rockets, pickups, Session 12 — Explosion VFX, game-over ship, meteorite barrier, rocket speeds, Session 13 — Barriers, enemy speed, penta-shot, confirm dialog, player visual, Session 14 — Difficulty scaling, spawn pacing, penta/triple priority, Session 15 — Game over fix, rockets, barrier spawner, starfield (+9 more)

## Knowledge Gaps
- **172 isolated node(s):** `Finding 1 (Critical) — Player-enemy contact bypasses death contract`, `Finding 2 (Minor) — dead code cleanup`, `Finding 3 (Minor) — extract remaining balance magic numbers`, `Finding 4 (Important) — missing test assertions`, `Test suite` (+167 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **13 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `UI and Graphics Upgrade Implementation Plan` connect `Community 2` to `Community 31`?**
  _High betweenness centrality (0.020) - this node is a cross-community bridge._
- **Why does `Changelog (iterative updates after initial plan)` connect `Community 31` to `Community 2`?**
  _High betweenness centrality (0.017) - this node is a cross-community bridge._
- **What connects `Finding 1 (Critical) — Player-enemy contact bypasses death contract`, `Finding 2 (Minor) — dead code cleanup`, `Finding 3 (Minor) — extract remaining balance magic numbers` to the rest of the system?**
  _172 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.10526315789473684 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.1111111111111111 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.08695652173913043 - nodes in this community are weakly interconnected._
- **Should `Community 3` be split into smaller, more focused modules?**
  _Cohesion score 0.13333333333333333 - nodes in this community are weakly interconnected._