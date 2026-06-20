# Task 6 Report: Player scene — touch-drag movement, HP, auto-fire

## What was done

Created four files exactly as specified in the task brief (with the brief's already-corrected
collision layer/mask/group values applied verbatim, as instructed):

- `scripts/bullet.gd` — `Area2D` with `speed`/`damage` exports, moves along `direction`,
  frees itself when leaving the viewport (using `GameConstants.VIEWPORT_H`).
- `scenes/Bullet.tscn` — `Area2D` named `Bullet`, group `["player_bullet"]`,
  `collision_layer = 4`, `collision_mask = 8`, plus `CollisionShape2D` (shape left unset,
  intentionally, per the brief's note — set per-instance in code later) and a `Polygon2D` visual.
- `scripts/player.gd` — `Area2D` with touch-drag movement (`InputEventScreenTouch` /
  `InputEventScreenDrag`), screen clamping, auto-fire timer (`fire_rate`, default 0.25s),
  `apply_shield(active)`, `take_damage(amount)` going through `GameManager.damage_player`,
  `hit(amount)` signal, and `_on_area_entered` reacting to `enemy`/`enemy_bullet` groups.
  Calls `GameManager.start_run()` in `_ready()`.
- `scenes/Player.tscn` — `Area2D` named `Player`, `collision_layer = 2`, `collision_mask = 8`,
  `CollisionShape2D` (shape unset, same pattern), `Polygon2D` visual, and the
  `area_entered -> _on_area_entered` connection.

No deviations from the brief's literal code/scene text were made — the brief I was handed
already contained the corrected `collision_layer`/`collision_mask`/`groups` values described
in my task instructions (Bullet: layer 4 / mask 8 / group `player_bullet`; Player: layer 2 /
mask 8), so nothing needed to be overridden.

## Verification

### Brief's literal Step 5 command

```
$ godot --headless --check-only --script res://scripts/player.gd
Godot Engine v4.7.stable.official.5b4e0cb0f - https://godotengine.org

SCRIPT ERROR: Compile Error: Identifier not found: GameManager
          at: GDScript::reload (res://scripts/player.gd:17)
ERROR: Failed to load script "res://scripts/player.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
EXIT_CODE:0
```

This is **not** a bug in `player.gd`. I reproduced the identical failure with a trivial
unrelated throwaway script (`extends Node` / `extends SceneTree`, body `GameManager.start_run()`
only) — `godot --headless --script ...` and `--check-only --script ...` do not initialize
project autoload singletons before compiling the target script, so any script that references
an autoload by its singleton name (`GameManager`, `SaveManager`) will always fail this exact
invocation in Godot 4.7, regardless of correctness. This matches the precedent already noted in
the Task 5 report about headless `--script` mode quirks (exit codes / global class resolution).

By contrast, `scripts/bullet.gd` (which only references the global class `GameConstants`, not
an autoload singleton) passes the identical command cleanly:

```
$ godot --headless --check-only --script res://scripts/bullet.gd
Godot Engine v4.7.stable.official.5b4e0cb0f - https://godotengine.org
EXIT_CODE:0
```

### Additional verification performed (beyond the brief, for confidence — not committed)

Ran a temporary (deleted after use, never committed) `SceneTree`-extending script via
`godot --headless --script ...` that loaded and instantiated both `.tscn` files directly
(no `GameManager` reference, to avoid the autoload-in-`--script`-mode limitation above) and
printed real instance state:

```
Bullet instantiated: true
Bullet in group player_bullet: true
Bullet collision_layer: 4 collision_mask: 8
Player instantiated: true
Player collision_layer: 2 collision_mask: 8
Player fire_rate: 0.25
```

This confirms both scenes parse, load, and instantiate correctly with the expected exported
defaults, collision layers/masks, and group membership. (Trailing `WARNING`/`ERROR` lines in
that run were RID/ObjectDB leak-at-exit noise from manually instantiating nodes outside a tree
in a throwaway script — not related to the scene/script files themselves.)

Also rebuilt the global class cache first via `godot --headless --editor --quit` (same
one-time step flagged as necessary in the Task 5 report); this is environment-only and not a
tracked file change (the `ERROR: Cannot open file 'res://scenes/MainMenu.tscn'` printed during
that step is expected/unrelated — that scene doesn't exist yet).

## Commit

```
298ee65fff9819579b77f7831625302df5cb2600
feat: add player touch-drag movement, auto-fire, and bullet scene
 6 files changed, 108 insertions(+)
 create mode 100644 scenes/Bullet.tscn
 create mode 100644 scenes/Player.tscn
 create mode 100644 scripts/bullet.gd
 create mode 100644 scripts/bullet.gd.uid
 create mode 100644 scripts/player.gd
 create mode 100644 scripts/player.gd.uid
```

## Concerns / notes for the controller

1. **Step 5 verification command as literally written in the brief cannot pass in Godot 4.7**,
   for any script that references an autoload singleton by name — this is an environment
   limitation of `--headless --script`/`--check-only`, not a defect in `player.gd`. Future
   tasks with the same "headless --check-only --script" pattern on scripts touching
   `GameManager`/`SaveManager` will hit the same false-negative. Recommend the controller treat
   "no `Parse Error` (only `Compile Error: Identifier not found: GameManager`, reproducible on
   a trivial unrelated script)" as a pass condition for this class of check going forward, or
   switch verification for autoload-dependent scripts to a `SceneTree`-based test under
   `tests/` (matching the existing `tests/test_game_manager.gd` pattern, which uses
   `preload()` of the script class directly rather than the autoload identifier).
2. **Magic-number literals left as-is per instructions** (already present in the brief's literal
   code, not introduced by me, and explicitly out of scope to "fix" per my task instructions):
   - `player.gd`: `Vector2(40, 40)` / `Vector2(80, 80)` in `get_rect_global()`.
   - `player.gd`: `clamp(..., 30, GameConstants.VIEWPORT_W - 30)` / same for `VIEWPORT_H` — the
     `30` screen-margin in `_clamp_to_screen()`.
   - `player.gd`: `Vector2(0, -30)` muzzle offset in `_fire()`.
   - `player.gd`: hardcoded `20.0` damage amount in `_on_area_entered()` (note: this one is a
     gameplay balance value, not a geometry constant — likely candidate for a future
     `GameConstants.ENEMY_CONTACT_DAMAGE`-style entry if enemy/bullet damage tuning becomes
     centralized in a later task).
   - `bullet.gd`: `-50` / `+50` viewport-leeway margin in `_physics_process()`.
   None of these were in `GameConstants` already and the brief's literal code uses them
   inline, so per my instructions I left them unchanged.
3. Both `.tscn` files leave `CollisionShape2D.shape` unset, exactly as the brief specifies and
   explains (shape assigned per-instance in code in a later task) — flagging only so the
   controller is aware this is intentional, not an oversight, if a later task's verification
   checks for a `RectangleShape2D`/`CircleShape2D` resource on these nodes.

---

## Code Review Fixes

### Finding 1 (dead code): Remove `or true` condition in `_input(event)`

The condition `if get_rect_global().has_point(event.position) or true:` makes the rect check dead code.
Design intent (confirmed correct): touch-anywhere-on-screen should grab/drag the ship. Fixed by:

1. Removed the entire dead condition, replaced with `if event.pressed:`
2. Removed unused `get_rect_global()` function (grep confirmed no other uses)
3. Touch-drag movement now always activates on screen touch (correct mobile shmup UX)

### Finding 2 (magic number): Extract hardcoded `20.0` contact damage to constant

The hardcoded `take_damage(20.0)` in `_on_area_entered` is a gameplay balance value. Fixed by:

1. Added `const ENEMY_CONTACT_DAMAGE := 20.0` in `scripts/constants.gd` (line 27, after `PLAYER_MAX_HP`)
2. Changed `take_damage(20.0)` to `take_damage(GameConstants.ENEMY_CONTACT_DAMAGE)` in `player.gd` line 63

### Verification

```
$ godot --headless --check-only --script res://scripts/bullet.gd
Godot Engine v4.7.stable.official.5b4e0cb0f - https://godotengine.org

EXIT_CODE:0
```

(Note: `player.gd` still fails with "Identifier not found: GameManager" in headless `--check-only --script` mode — known Godot 4.7 limitation for autoload-dependent scripts, documented in previous report above. This is not a sign the fix is broken.)

### Commit

```
2208655
fix: remove dead touch-hit-test condition, extract contact damage to GameConstants
```
