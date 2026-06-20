# Task 7 Report: Enemy base + 3 movement-pattern types

## Status: DONE_WITH_CONCERNS

## What was done

Created exactly per the brief, with one deliberate deviation noted below:

- `scripts/enemy_base.gd` — `EnemyBase` (extends `Area2D`, `class_name EnemyBase`), exported `base_speed`/`hp`, `set_level()` using `Difficulty.enemy_speed_multiplier(level)`, `take_damage()` emitting `died`, calling `GameManager.add_kill()`, `queue_free()` on `hp <= 0`, off-screen cleanup in `_physics_process`, and `_on_area_entered` reacting to `player_bullet` group.
- `scripts/enemy_straight.gd` — straight downward movement, calls `super._physics_process(delta)`.
- `scripts/enemy_zigzag.gd` — sinusoidal x-offset zigzag (amplitude 60.0, frequency factor 3.0) layered on downward movement.
- `scripts/enemy_shooter.gd` — slow downward movement (`_speed * 0.5`), periodic fire via `enemy_bullet_scene`, initial `_fire_timer = 1.0`, reload `1.5`.
- `scenes/EnemyBullet.tscn` — reuses `scripts/bullet.gd`, group `enemy_bullet`, `speed=350.0`, `damage=20.0`, `collision_layer=8`, `collision_mask=2` (as brief shows, unmodified).
- `scenes/EnemyStraight.tscn` — `base_speed=100.0`, `hp=20.0`, group `enemy`, `collision_layer=8`, `collision_mask=4` (corrected — see below), `area_entered` wired to `_on_area_entered`.
- `scenes/EnemyZigzag.tscn` — `base_speed=90.0`, `hp=15.0`, same collision setup as above.
- `scenes/EnemyShooter.tscn` — `base_speed=60.0`, `hp=30.0`, `enemy_bullet_scene` wired to `EnemyBullet.tscn`, same collision setup as above.

## Collision fix applied (per instructions, deviates from brief's literal text)

The brief's literal `.tscn` text showed `collision_mask = 2` for all three enemy scenes. Per the task instructions, this was corrected to `collision_mask = 4` for `EnemyStraight.tscn`, `EnemyZigzag.tscn`, and `EnemyShooter.tscn`, keeping `collision_layer = 8` unchanged.

Rationale verified against existing scenes in the repo:
- `scenes/Player.tscn`: `collision_layer=2` (player), `collision_mask=8` (detects enemy layer 8) — player detects enemies for contact damage on its own side.
- `scenes/Bullet.tscn` (player_bullet): `collision_layer=4`, `collision_mask=8` (detects enemy layer 8).
- Enemies therefore must be on `collision_layer=8` and need `collision_mask=4` to detect `player_bullet` (layer 4) via their own `area_entered` → `_on_area_entered` → `take_damage`. A `mask=2` would have made enemies detect the player area (layer 2) directly, which is not how contact damage is wired in this design (that flows from the Player side, via Player's existing `collision_mask=8`).

`EnemyBullet.tscn` was left as the brief shows: `collision_layer=8`, `collision_mask=2` — enemy bullets need to detect the player (layer 2). This is correct and unmodified.

## Verification — Step 5 (script parse check)

Ran:
```
godot --headless --check-only --script res://scripts/enemy_base.gd
godot --headless --check-only --script res://scripts/enemy_straight.gd
godot --headless --check-only --script res://scripts/enemy_zigzag.gd
godot --headless --check-only --script res://scripts/enemy_shooter.gd
```

Output (all four), exit code 0 in every case:

```
=== enemy_base ===
Godot Engine v4.7.stable.official.5b4e0cb0f - https://godotengine.org

SCRIPT ERROR: Compile Error: Identifier not found: GameManager
          at: GDScript::reload (res://scripts/enemy_base.gd:22)
ERROR: Failed to load script "res://scripts/enemy_base.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
exit: 0

=== enemy_straight ===
SCRIPT ERROR: Compile Error: Identifier not found: GameManager
          at: GDScript::reload (res://scripts/enemy_base.gd:22)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
          at: GDScript::reload (res://scripts/enemy_straight.gd:0)
ERROR: Failed to load script "res://scripts/enemy_straight.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
exit: 0

=== enemy_zigzag ===
SCRIPT ERROR: Compile Error: Identifier not found: GameManager
          at: GDScript::reload (res://scripts/enemy_base.gd:22)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
          at: GDScript::reload (res://scripts/enemy_zigzag.gd:0)
ERROR: Failed to load script "res://scripts/enemy_zigzag.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
exit: 0

=== enemy_shooter ===
SCRIPT ERROR: Compile Error: Identifier not found: GameManager
          at: GDScript::reload (res://scripts/enemy_base.gd:22)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
          at: GDScript::reload (res://scripts/enemy_shooter.gd:0)
ERROR: Failed to load script "res://scripts/enemy_shooter.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
exit: 0
```

All four show only `Compile Error: Identifier not found: GameManager` (no `Parse Error`), with exit code 0. The `enemy_straight`/`enemy_zigzag`/`enemy_shooter` scripts additionally show "Failed to compile depended scripts" because they extend `enemy_base.gd`, which is expected cascading behavior, not a new defect — per the documented Task 6 known limitation (headless `--script` mode doesn't initialize autoloads, so `GameManager`/`GameConstants`/`Difficulty` identifiers used as autoloads aren't resolvable in this mode). Treated as PASS per task instructions.

## Commit

```
5e117af feat: add 3 enemy types with distinct movement patterns
```//
8 files changed, 146 insertions(+):
- scenes/EnemyBullet.tscn
- scenes/EnemyShooter.tscn
- scenes/EnemyStraight.tscn
- scenes/EnemyZigzag.tscn
- scripts/enemy_base.gd
- scripts/enemy_shooter.gd
- scripts/enemy_straight.gd
- scripts/enemy_zigzag.gd

## Concerns / flags

1. **Collision mask correction applied** (documented above) — all three enemy scenes use `collision_mask=4` instead of the brief's literal `collision_mask=2`. This was an explicit instruction in the task brief override, not a unilateral change, but flagging per report requirements since it differs from the brief's literal `.tscn` text.

2. **Magic numbers not covered by GameConstants/Difficulty** — the brief's literal values for per-enemy-type tuning are not sourced from `GameConstants`/`Difficulty` and were left as-is per instructions (not unilaterally promoted to new constants):
   - `EnemyStraight`: `base_speed=100.0` (matches existing `GameConstants.BASE_ENEMY_SPEED=100.0` in value but is hardcoded separately in the scene, not referenced), `hp=20.0`.
   - `EnemyZigzag`: `base_speed=90.0`, `hp=15.0`, zigzag amplitude `60.0` and frequency factor `3.0` (in `enemy_zigzag.gd`).
   - `EnemyShooter`: `base_speed=60.0`, `hp=30.0`, fire timer initial `1.0` and reload `1.5` (in `enemy_shooter.gd`), shooter movement speed factor `0.5`.
   - `EnemyBullet`: `speed=350.0`, `damage=20.0`.
   - Geometry/visual literals (polygon vertices, colors, bullet spawn offsets `Vector2(0, 20)`/`Vector2(0, -30)`) are layout-only and intentionally left inline per project standard.

   None of these (except the coincidental match of `EnemyStraight.base_speed` to `GameConstants.BASE_ENEMY_SPEED`) have a corresponding constant already defined in `scripts/constants.gd` or `scripts/difficulty.gd`. Following instructions, these were left inline rather than unilaterally adding new constants, but are flagged here for whoever owns balance-constant consolidation.

3. Verification could only check script parse-ability, not actual scene instantiation/runtime behavior (e.g., enemy-bullet collision interactions, `set_level` wiring from a spawner), since no spawner/level-loading code exists yet (likely a later task). No `EnemyBase.set_level()` caller exists yet in the codebase — expected, as wave spawning is presumably a subsequent task.
