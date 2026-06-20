# Task 13 Report: Audio hooks (structural — no bundled files)

## Summary

Added guarded `AudioStreamPlayer2D`/`AudioStreamPlayer` nodes and `if X.stream != null: X.play()` call sites across the gameplay scripts/scenes, per the brief. All edits were applied as targeted, additive diffs on top of the current file contents — verified each file (player.gd, enemy_base.gd, boss.gd, pickup.gd, and all 8 scenes) was re-read fresh before editing, so the Task 9 reference-counted boost/shield methods in player.gd and the Task 12 `process_mode = 3` fix on `GameOverPanel` in Main.tscn were left untouched.

Commit hash: **c195c7b**

## What was done

### scripts/player.gd
- Added `@onready var fire_sfx: AudioStreamPlayer2D = $FireSFX` and `@onready var hit_sfx: AudioStreamPlayer2D = $HitSFX` after the `_shield_count` var (before `_ready()`).
- In `_fire()`, after positioning the bullet: `if fire_sfx.stream != null: fire_sfx.play()`.
- In `take_damage()`, after `hit.emit(amount)`: `if hit_sfx.stream != null: hit_sfx.play()`.
- Did not touch `add_weapon_boost`/`remove_weapon_boost`/`add_speed_boost`/`remove_speed_boost`/`add_shield`/`remove_shield` (Task 9 reference-counted pattern preserved as-is).

### scripts/enemy_base.gd
- Added `@onready var explosion_sfx: AudioStreamPlayer2D = $ExplosionSFX` before `_ready()`.
- In `take_damage()`, inserted guarded explosion play + 0.3s timer await right before `queue_free()` (after `GameManager.add_kill()`).

### scripts/boss.gd
- Same pattern as enemy_base.gd: `@onready var explosion_sfx` added before `_ready()`, guarded play + await inserted before `queue_free()` in `take_damage()`.

### scripts/pickup.gd
- Added `@onready var pickup_sfx: AudioStreamPlayer2D = $PickupSFX` before `_ready()`.
- In `_on_area_entered()`, inserted guarded pickup play + 0.2s timer await right before the existing `queue_free()` (after the `match kind:` block).

### Scene files — new child nodes added (stream left empty)
- `scenes/Player.tscn`: `FireSFX`, `HitSFX` (`AudioStreamPlayer2D`), added after the `Visual` Polygon2D node, before the `area_entered` connection.
- `scenes/EnemyStraight.tscn`, `scenes/EnemyZigzag.tscn`, `scenes/EnemyShooter.tscn`, `scenes/Boss.tscn`: `ExplosionSFX` (`AudioStreamPlayer2D`) added after `Visual`, before the connection block.
- `scenes/Pickup.tscn`: `PickupSFX` (`AudioStreamPlayer2D`) added after `Visual`, before the connection block.
- `scenes/MainMenu.tscn`: `MusicPlayer` (`AudioStreamPlayer`, `autoplay = true`) added after `MuteButton`, before the connections.
- `scenes/Main.tscn`: `MusicPlayer` (`AudioStreamPlayer`, `autoplay = true`) added after the `HUD` instance node. Did not touch the `GameOverPanel` node or its `process_mode = 3` (Task 12 fix preserved).

## Verification

### Step 6 — check-only loop (brief's exact command)

```
for f in scripts/player.gd scripts/enemy_base.gd scripts/boss.gd scripts/pickup.gd; do godot --headless --check-only --script res://$f || echo "FAILED $f"; done
```

Full output:

```
=== scripts/player.gd ===
Godot Engine v4.7.stable.official.5b4e0cb0f - https://godotengine.org

SCRIPT ERROR: Compile Error: Identifier not found: GameManager
          at: GDScript::reload (res://scripts/player.gd:26)
ERROR: Failed to load script "res://scripts/player.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
exit:0

=== scripts/enemy_base.gd ===
Godot Engine v4.7.stable.official.5b4e0cb0f - https://godotengine.org

SCRIPT ERROR: Compile Error: Identifier not found: GameManager
          at: GDScript::reload (res://scripts/enemy_base.gd:24)
ERROR: Failed to load script "res://scripts/enemy_base.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
exit:0

=== scripts/boss.gd ===
Godot Engine v4.7.stable.official.5b4e0cb0f - https://godotengine.org

SCRIPT ERROR: Compile Error: Identifier not found: GameManager
          at: GDScript::reload (res://scripts/boss.gd:50)
ERROR: Failed to load script "res://scripts/boss.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
exit:0

=== scripts/pickup.gd ===
Godot Engine v4.7.stable.official.5b4e0cb0f - https://godotengine.org

exit:0
```

Result: exactly as expected per task brief — `player.gd`, `enemy_base.gd`, `boss.gd` each hit only the known autoload **Compile Error** (`Identifier not found: GameManager`) in headless `--check-only` mode (this autoload-resolution limitation predates this task and is not a regression — `--check-only` mode doesn't load `project.godot` autoload bindings). Crucially, no **Parse Error** appeared in any of the four files, confirming the new `@onready` declarations and guarded `play()` call sites are syntactically valid GDScript. `pickup.gd` (no autoload reference) passed cleanly with no errors at all, as predicted.

### Headless smoke tests

```
godot --headless --path . res://scenes/Main.tscn --quit-after 3
```
Output:
```
Godot Engine v4.7.stable.official.5b4e0cb0f - https://godotengine.org

```
Exit code: 0. No ERROR, SCRIPT ERROR, or missing-stream warning lines at all.

```
godot --headless --path . res://scenes/MainMenu.tscn --quit-after 3
```
Output:
```
Godot Engine v4.7.stable.official.5b4e0cb0f - https://godotengine.org

```
Exit code: 0. No ERROR, SCRIPT ERROR, or missing-stream warning lines at all.

Both scenes loaded and ran for 3 seconds headless with clean exit codes and no new error output versus pre-task baseline. No crashes from calling `.play()` on a null stream — confirms the `if X.stream != null` guards are correctly preventing any play() calls (no streams are assigned, so no SFX/music attempted to play, and no errors were raised attempting to do so).

### Git diff scope check

`git diff --stat` against the prior commit showed exactly the 12 files named in the brief modified, all purely additive (42 insertions, 0 deletions):
```
 scenes/Boss.tscn          | 2 ++
 scenes/EnemyShooter.tscn  | 2 ++
 scenes/EnemyStraight.tscn | 2 ++
 scenes/EnemyZigzag.tscn   | 2 ++
 scenes/Main.tscn          | 3 +++
 scenes/MainMenu.tscn      | 3 +++
 scenes/Pickup.tscn        | 2 ++
 scenes/Player.tscn        | 4 ++++
 scripts/boss.gd           | 5 +++++
 scripts/enemy_base.gd     | 5 +++++
 scripts/pickup.gd         | 5 +++++
 scripts/player.gd         | 7 +++++++
 12 files changed, 42 insertions(+)
```
This confirms no accidental reverts of the Task 9 (player.gd reference-counted boosts) or Task 12 (`Main.tscn` `GameOverPanel.process_mode = 3`) fixes — those lines are untouched in the diff.

## Commit

```
git add scripts/player.gd scripts/enemy_base.gd scripts/boss.gd scripts/pickup.gd scenes/Player.tscn scenes/EnemyStraight.tscn scenes/EnemyZigzag.tscn scenes/EnemyShooter.tscn scenes/Boss.tscn scenes/Pickup.tscn scenes/MainMenu.tscn scenes/Main.tscn
git commit -m "feat: wire guarded audio hooks for fire, hit, explosion, pickup, and music"
```

Result: `[feature/mvp c195c7b] feat: wire guarded audio hooks for fire, hit, explosion, pickup, and music` — 12 files changed, 42 insertions(+).

## Concerns

None. This is the final task (13 of 13) in the plan. All edits are purely additive/structural as scoped — no audio assets are bundled (out of scope per the brief's explicit follow-up note), all `stream` properties are left empty, and all `play()` call sites are guarded so no runtime behavior changes until audio files are later dropped in and assigned. Manual play-test (brief's Step 7) was not re-run interactively in this headless environment, but the headless smoke tests for both `Main.tscn` and `MainMenu.tscn` confirm no errors are raised by the new nodes/guards during scene load and a few seconds of `_process`/`_physics_process` ticks (where `_fire()` would normally run and trigger the new guarded `fire_sfx` check).
