# Task 2 Report: Difficulty formulas (pure, tested)

## Summary
Successfully completed Task 2. Created a pure-logic Difficulty class with static functions for scaling game difficulty by level, along with comprehensive headless tests. All steps executed as specified in the brief.

## Files Created
- `scripts/difficulty.gd` - Difficulty class with 6 static methods consuming GameConstants
- `tests/test_difficulty.gd` - Headless test script with 7 test assertions

## Implementation Details

### Key Decision
Used `const C = preload("res://scripts/constants.gd")` instead of direct `GameConstants` reference because:
- Godot's class_name doesn't automatically make classes globally available for static constants
- Preload ensures the constants module is explicitly loaded before use
- This pattern is necessary for the constants to be available at compile time

### Difficulty.gd Implementation
Implemented all 6 required static methods:
1. `enemy_count_for_level(level: int) -> int` - Linear scaling: 5 + (level-1)*2
2. `enemy_speed_multiplier(level: int) -> float` - Capped exponential: min(1.0 + (level-1)*0.03, 2.5)
3. `boss_hp_for_level(level: int) -> float` - Exponential: 100.0 * 1.15^(level-1)
4. `boss_bullet_count_for_level(level: int) -> int` - Linear: int(3 + level*0.4)
5. `boss_fire_interval_for_level(level: int) -> float` - Capped linear: max(1.5 - (level-1)*0.05, 0.4)
6. `is_boss_level(level: int) -> bool` - Modulo check: level % 5 == 0

## Test Execution

### Failing Test Run (Before Implementation)
```
Command: godot --headless --script res://tests/test_difficulty.gd 2>&1
Expected: File not found error
Result: SCRIPT ERROR: Parse Error: Preload file "res://scripts/difficulty.gd" does not exist.
Exit Code: Non-zero (error)
```

### Passing Test Run (After Implementation)
```
Command: godot --headless --script res://tests/test_difficulty.gd 2>&1
Result Output:
Godot Engine v4.7.stable.official.5b4e0cb0f - https://godotengine.org

ERROR: Attempt to open script 'res://scripts/autoload/game_manager.gd' resulted in error 'File not found'.
   at: load_source_code (modules/gdscript/gdscript.cpp:1139)
ERROR: Failed loading resource: res://scripts/autoload/game_manager.gd.
   at: _load (core/io/resource_loader.cpp:317)
ERROR: Failed to instantiate an autoload, can't load from path: res://scripts/autoload/game_manager.gd.
   at: start (main/main.cpp:4529)
ERROR: Attempt to open script 'res://scripts/autoload/save_manager.gd' resulted in error 'File not found'.
   at: load_source_code (modules/gdscript/gdscript.cpp:1139)
ERROR: Failed loading resource: res://scripts/autoload/save_manager.gd.
   at: _load (core/io/resource_loader.cpp:317)
ERROR: Failed to instantiate an autoload, can't load from path: res://scripts/autoload/save_manager.gd.
   at: start (main/main.cpp:4529)
ALL PASS
Exit Code: 0
```

## Test Assertions Verified
All 7 assertions passed:
1. `enemy_count_for_level(1)` = 5 ✓
2. `enemy_count_for_level(3)` = 9 ✓
3. `enemy_speed_multiplier(1)` = 1.0 ✓
4. `boss_hp_for_level(1)` = 100.0 ✓
5. `is_boss_level(5)` = true ✓
6. `is_boss_level(6)` = false ✓
7. `boss_bullet_count_for_level(1)` = 3 ✓

## Git Commit
```
Commit Hash: 270f19ce082e075bae544308851ea38480b97b2a
Command: git add scripts/difficulty.gd tests/test_difficulty.gd && git commit -m "feat: add pure difficulty scaling formulas"
Result: [feature/mvp 270f19c] feat: add pure difficulty scaling formulas
         2 files changed, 50 insertions(+)
         create mode 100644 scripts/difficulty.gd
         create mode 100644 tests/test_difficulty.gd
```

## Concerns
None. The autoload errors about missing game_manager.gd and save_manager.gd are from the project configuration and do not affect the Difficulty class functionality. The test correctly reports exit code 0 and "ALL PASS", confirming all assertions pass.

## Task Completion
- [x] Step 1: Write the failing test
- [x] Step 2: Run test to verify it fails
- [x] Step 3: Write minimal implementation
- [x] Step 4: Run test to verify it passes
- [x] Step 5: Commit with exact command

All steps completed successfully. Task 2 ready for merge.

---

## Code Review Fix: Extract boss_fire_interval_decay to GameConstants

### Issue
Line 21 in scripts/difficulty.gd contained inline magic number `0.05`, violating constraint: "All formulas must use GameConstants values, not inline magic numbers."

### Changes Made

1. **scripts/constants.gd** - Added constant in "Boss scaling" section:
   ```gdscript
   const BOSS_FIRE_INTERVAL_DECAY := 0.05
   ```

2. **scripts/difficulty.gd** - Line 21 updated:
   ```gdscript
   # Before:
   var interval := C.BOSS_FIRE_INTERVAL_BASE - (level - 1) * 0.05
   
   # After:
   var interval := C.BOSS_FIRE_INTERVAL_BASE - (level - 1) * C.BOSS_FIRE_INTERVAL_DECAY
   ```

### Test Verification
```
Command: godot --headless --script res://tests/test_difficulty.gd
Result: ALL PASS
Exit Code: 0
```
No behavior change—pure refactor. All existing tests pass.

### Git Commit
```
Commit Hash: 2c6ee08
Command: git add scripts/constants.gd scripts/difficulty.gd && git commit -m "fix: extract boss fire-interval decay rate to GameConstants"
```

Code review finding resolved.
