# Task 5 Report: GameManager + SaveManager autoload singletons

## Summary
Implemented Task 5 exactly per brief: created `scripts/autoload/game_manager.gd`,
`scripts/autoload/save_manager.gd`, and `tests/test_game_manager.gd`, verified
red -> green, committed.

## Steps taken

1. Wrote `tests/test_game_manager.gd` verbatim from the brief.
2. Ran the test to confirm it fails (files don't exist yet).
3. **Pre-existing environment issue found and resolved**: the repo had no
   `.godot/` import cache (project had never been opened/imported by the
   editor), so `GameConstants` (and the other Task 1-4 global `class_name`
   types) were not yet registered as global script classes. This caused the
   test to fail with `Identifier "GameConstants" not declared in the current
   scope"` even after creating `game_manager.gd`. Fixed by running
   `godot --headless --editor --quit` once to force a full project
   import/global-class-cache build (this is the same one-time step the brief's
   Step 4 note assumes was "already satisfied by Task 1 Step 3" — it hadn't
   actually happened in this checkout). This is an environment/setup step, not
   a code change; no project files were altered by it other than the
   auto-generated `.godot/` cache directory (not committed, already
   git-ignored implicitly since this repo currently has no `.gitignore`
   tracking it — see Concerns).
4. Wrote `scripts/autoload/game_manager.gd` and `scripts/autoload/save_manager.gd`
   verbatim from the brief. Both consume `GameConstants` and `SaveData` by
   global class name (no magic numbers introduced; `PLAYER_MAX_HP`,
   `SCORE_PER_KILL`, `SCORE_PER_LEVEL` all already existed in
   `scripts/constants.gd` from Task 1). `SAVE_PATH` is a string literal
   exactly as specified in the brief (not a numeric magic value, so it is
   outside the no-magic-numbers standard).
5. Re-ran the test: `ALL PASS`, exit code 0.
6. Committed with the exact command from the brief.

## Test commands and output

**Failing run (before implementation):**
```
$ godot --headless --script res://tests/test_game_manager.gd
Godot Engine v4.7.stable.official.5b4e0cb0f - https://godotengine.org

SCRIPT ERROR: Parse Error: Preload file "res://scripts/autoload/game_manager.gd" does not exist.
          at: GDScript::reload (res://tests/test_game_manager.gd:4)
SCRIPT ERROR: Parse Error: Identifier "GameConstants" not declared in the current scope.
          at: GDScript::reload (res://tests/test_game_manager.gd:18)
... (repeated for each GameConstants reference)
ERROR: Failed to load script "res://tests/test_game_manager.gd" with error "Parse error".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
EXIT: 0
```
(Confirms expected failure: script fails to load because
`game_manager.gd` does not exist. Note: Godot's headless `--script` runner
returns exit code 0 even on a script load failure — it doesn't propagate a
nonzero process exit code for this kind of parse error. The brief's "non-zero
exit" expectation did not hold in this Godot 4.7 build; the load failure
itself, printed as `SCRIPT ERROR` / `ERROR: Failed to load script`, is the
actual confirmation of red state.)

**After importing project once (to build global class cache) but before creating game_manager.gd/save_manager.gd:**
```
SCRIPT ERROR: Parse Error: Identifier "GameConstants" not declared in the current scope.
...
ERROR: Failed to load script "res://tests/test_game_manager.gd" with error "Parse error".
EXIT: 0
```

**Passing run (after implementation):**
```
$ godot --headless --script res://tests/test_game_manager.gd
Godot Engine v4.7.stable.official.5b4e0cb0f - https://godotengine.org

ALL PASS
WARNING: 3 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2535)
ERROR: 1 resources still in use at exit (run with --verbose for details).
   at: clear (core/io/resource.cpp:822)
EXIT: 0
```

Confirmed regression-free: `test_wave_pool.gd` and `test_save_data.gd` still print `ALL PASS` with no leak warnings (those test `RefCounted` scripts; this is the first test in the suite to instantiate a `Node`-derived script directly via `.new()` without adding it to a tree, hence the leak warning — see Concerns).

## Commit

```
git add scripts/autoload/game_manager.gd scripts/autoload/save_manager.gd tests/test_game_manager.gd
git commit -m "feat: add GameManager and SaveManager autoload singletons"
```

Commit hash: `dfb29d1a211c4c290363e970c2a6ac50029efd05`
Branch: `feature/mvp`

```
[feature/mvp dfb29d1] feat: add GameManager and SaveManager autoload singletons
 3 files changed, 96 insertions(+)
 create mode 100644 scripts/autoload/game_manager.gd
 create mode 100644 scripts/autoload/save_manager.gd
 create mode 100644 tests/test_game_manager.gd
```

## Concerns

1. **Project had no `.godot/` import cache before this task.** I had to run
   `godot --headless --editor --quit` to build it before `GameConstants` and
   friends were resolvable as global classes. This succeeded and is harmless
   (auto-generated, not committed), but it means the assumption in the brief
   ("already satisfied by Task 1 Step 3") was not actually true in this
   checkout — worth flagging to whoever runs Task 6+ in a fresh clone/CI, since
   they'll hit the same `GameConstants not declared` error on a clean checkout
   until the project is imported once. Consider documenting this as an
   explicit one-time setup step (or adding a CI step that runs
   `godot --headless --editor --quit` / `--import` before running any tests).
2. **`MainMenu.tscn` does not exist yet** (`run/main_scene` in `project.godot`
   points at `res://scenes/MainMenu.tscn`). This produced an `ERROR: Cannot
   open file` during the editor import pass, but it's unrelated to Task 5
   (no scenes have been created yet in this task chain) and did not affect
   the test run or global class registration.
3. **ObjectDB leak warning on the new test.** `tests/test_game_manager.gd`
   (written verbatim per brief) instantiates `GameManagerScript.new()`
   (a `Node` subclass) and never calls `.free()`/`queue_free()` on it before
   `quit()`. This produces a harmless `3 ObjectDB instances were leaked at
   exit` warning that prior tests didn't have (they instantiate `RefCounted`
   scripts, which don't leak the same way). Test still passes and exits 0;
   flagging only because it's a new noisy-but-harmless pattern introduced by
   this test file's exact spec from the brief — I did not deviate from the
   brief's test code to fix it.
4. No deviations from the brief's exact code for `game_manager.gd`,
   `save_manager.gd`, or `test_game_manager.gd`. No new magic numbers were
   introduced; all tunables (`PLAYER_MAX_HP`, `SCORE_PER_KILL`,
   `SCORE_PER_LEVEL`) were already present in `GameConstants` from Task 1.
