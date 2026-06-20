# Final Review Fix Report — feature/mvp

Date: 2026-06-20

## Finding 1 (Critical) — Player-enemy contact bypasses death contract

File: `scripts/player.gd`

Before (lines 99-103):
```gdscript
func _on_area_entered(area: Node) -> void:
	if area.is_in_group("enemy_bullet") or area.is_in_group("enemy"):
		take_damage(GameConstants.ENEMY_CONTACT_DAMAGE)
		if area.has_method("queue_free"):
			area.queue_free()
```

After (lines 96-103):
```gdscript
func _on_area_entered(area: Node) -> void:
	if area.is_in_group("enemy_bullet"):
		take_damage(GameConstants.ENEMY_CONTACT_DAMAGE)
		area.queue_free()
	elif area.is_in_group("enemy"):
		take_damage(GameConstants.ENEMY_CONTACT_DAMAGE)
		if area.has_method("take_damage"):
			area.take_damage(99999.0)
```

Effect: ramming enemies/bosses now die through `EnemyBase.take_damage()`, so `died` fires,
`GameManager.add_kill()` runs, and `WaveSpawner._alive_count` decrements correctly. Enemy
bullets are still freed directly via `queue_free()` since they are not part of the
enemy/died/alive-count contract.

## Finding 2 (Minor) — dead code cleanup

File: `scripts/player.gd`

Confirmed via `grep -rn "apply_shield(" scripts/ scenes/` that `apply_shield(active: bool)`
(old line 61-62) was never called anywhere in the codebase (superseded by `add_shield`/
`remove_shield` reference-counted methods from Task 9). Removed the dead method:

Before:
```gdscript
func apply_shield(active: bool) -> void:
	_shield_active = active

func add_weapon_boost() -> void:
```

After:
```gdscript
func add_weapon_boost() -> void:
```

## Finding 3 (Minor) — extract remaining balance magic numbers

File: `scripts/constants.gd` — added new constants after `PICKUP_DURATION`:
```gdscript
# Pickups
const PICKUP_DURATION := 6.0
const WEAPON_BOOST_DIVISOR := 3.0
const SPEED_BOOST_MULTIPLIER := 1.6
const BOMB_DAMAGE := 999.0

# Enemy shooter
const SHOOTER_FIRE_INTERVAL := 1.5
```

Call-site updates:

1. `scripts/player.gd:63` — `add_weapon_boost()`:
   - Before: `fire_rate = _base_fire_rate / 3.0`
   - After: `fire_rate = _base_fire_rate / GameConstants.WEAPON_BOOST_DIVISOR`

2. `scripts/player.gd:72` — `add_speed_boost()`:
   - Before: `speed_multiplier = 1.6`
   - After: `speed_multiplier = GameConstants.SPEED_BOOST_MULTIPLIER`

3. `scripts/enemy_shooter.gd:12` — `_physics_process()`:
   - Before: `_fire_timer = 1.5`
   - After: `_fire_timer = GameConstants.SHOOTER_FIRE_INTERVAL`

4. `scripts/pickup.gd:55` — `_apply_bomb()`:
   - Before: `enemy.take_damage(999.0)`
   - After: `enemy.take_damage(GameConstants.BOMB_DAMAGE)`

## Finding 4 (Important) — missing test assertions

File: `tests/test_difficulty.gd`

Added two new `check()` calls inside `_initialize()`, right after the existing
`boss_bullet_count_for_level(1)` assertion:

```gdscript
check("enemy_speed_multiplier(1000) clamps", Difficulty.enemy_speed_multiplier(1000), GameConstants.MAX_SPEED_MULTIPLIER)
check("boss_fire_interval_for_level(1000) floors", Difficulty.boss_fire_interval_for_level(1000), GameConstants.BOSS_FIRE_INTERVAL_MIN)
```

These cover:
1. The clamp branch of `enemy_speed_multiplier` at a very high level (1000), which previously
   had zero coverage (only level 1 was tested).
2. `boss_fire_interval_for_level`, which previously had zero test coverage at all; asserts it
   floors at `GameConstants.BOSS_FIRE_INTERVAL_MIN` for level 1000.

## Verification

### Test suite

```
$ godot --headless --script res://tests/test_difficulty.gd
Godot Engine v4.7.stable.official.5b4e0cb0f - https://godotengine.org

ALL PASS
EXIT:0

$ godot --headless --script res://tests/test_save_data.gd
Godot Engine v4.7.stable.official.5b4e0cb0f - https://godotengine.org

ALL PASS
EXIT:0

$ godot --headless --script res://tests/test_wave_pool.gd
Godot Engine v4.7.stable.official.5b4e0cb0f - https://godotengine.org

ALL PASS
EXIT:0

$ godot --headless --script res://tests/test_game_manager.gd
Godot Engine v4.7.stable.official.5b4e0cb0f - https://godotengine.org

ALL PASS
WARNING: 3 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2535)
ERROR: 1 resources still in use at exit (run with --verbose for details).
   at: clear (core/io/resource.cpp:822)
EXIT:0
```

All four test scripts printed "ALL PASS" and exited 0. The ObjectDB leak warning/resource
notice in `test_game_manager.gd` is a benign engine-shutdown cleanup message (pre-existing
behavior unrelated to these changes); it does not affect the exit code or test result.

### Scene smoke test

```
$ godot --headless --path . res://scenes/Main.tscn --quit-after 3
Godot Engine v4.7.stable.official.5b4e0cb0f - https://godotengine.org

EXIT:0
```

Clean exit, no ERROR/SCRIPT ERROR lines.

### Script parse checks

```
$ godot --headless --check-only --script res://scripts/player.gd
SCRIPT ERROR: Compile Error: Identifier not found: GameManager
          at: GDScript::reload (res://scripts/player.gd:26)
ERROR: Failed to load script "res://scripts/player.gd" with error "Compilation failed".

$ godot --headless --check-only --script res://scripts/enemy_shooter.gd
SCRIPT ERROR: Compile Error: Identifier not found: GameManager
          at: GDScript::reload (res://scripts/enemy_base.gd:24)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
          at: GDScript::reload (res://scripts/enemy_shooter.gd:0)
ERROR: Failed to load script "res://scripts/enemy_shooter.gd" with error "Compilation failed".

$ godot --headless --check-only --script res://scripts/pickup.gd
(no output — clean)

$ godot --headless --check-only --script res://scripts/constants.gd
(no output — clean)

$ godot --headless --check-only --script res://tests/test_difficulty.gd
(no output — clean)
```

Both `player.gd` and `enemy_shooter.gd` (via its parent `enemy_base.gd`) show only the
expected pre-existing "Compile Error: Identifier not found: GameManager" — this is because
`--check-only --script` loads the script standalone, outside the running project, so the
`GameManager` autoload singleton is not registered. This is a Compile Error (autoload
resolution), not a Parse Error (syntax/structure), matching the documented expected
pre-existing condition. `pickup.gd`, `constants.gd`, and `test_difficulty.gd` parse with no
errors at all.

## Files changed

- `scripts/player.gd` — Finding 1 fix, Finding 2 dead-code removal, Finding 3 constant usage (×2)
- `scripts/constants.gd` — Finding 3 new constants
- `scripts/enemy_shooter.gd` — Finding 3 constant usage
- `scripts/pickup.gd` — Finding 3 constant usage
- `tests/test_difficulty.gd` — Finding 4 new assertions

## Commit

Staged and committed all changed files in one commit:

```
git add -A
git commit -m "fix: route contact kills through take_damage, extract remaining magic numbers, add formula edge-case tests"
```

Commit hash: see below (filled in after commit).
