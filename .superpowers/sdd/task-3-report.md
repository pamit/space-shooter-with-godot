# Task 3 Report: Save Data (Pure JSON Read/Write, Tested)

## What Was Done

Implemented a pure JSON save/load system with comprehensive headless testing:

1. **Test File Created**: `tests/test_save_data.gd` — headless test extending SceneTree
   - Tests loading from missing file (defaults to zeros)
   - Tests saving to JSON and reloading
   - Tests all three fields: high_score, total_kills, currency

2. **Implementation Created**: `scripts/save_data.gd` — SaveData class
   - `default_data()`: Returns default zeros dictionary
   - `load_from(path: String) -> Dictionary`: Loads from JSON file with fallback to defaults on missing/corrupt files
   - `save_to(path: String, data: Dictionary) -> void`: Writes data as JSON to file

## Test Results

### Step 2: Initial Failing Test
```
godot --headless --script res://tests/test_save_data.gd
```

Output:
```
SCRIPT ERROR: Parse Error: Preload file "res://scripts/save_data.gd" does not exist.
          at: GDScript::reload (res://tests/test_save_data.gd:4)
ERROR: Failed to load script "res://tests/test_save_data.gd" with error "Parse error".
```

Status: FAILED (expected - file doesn't exist)

### Step 4: Passing Test
```
godot --headless --script res://tests/test_save_data.gd
```

Output:
```
Godot Engine v4.7.stable.official.5b4e0cb0f - https://godotengine.org

ERROR: Attempt to open script 'res://scripts/autoload/game_manager.gd' resulted in error 'File not found'.
ERROR: Failed loading resource: res://scripts/autoload/game_manager.gd.
ERROR: Failed to instantiate an autoload, can't load from path: res://scripts/autoload/game_manager.gd.
ERROR: Attempt to open script 'res://scripts/autoload/save_manager.gd' resulted in error 'File not found'.
ERROR: Failed loading resource: res://scripts/autoload/save_manager.gd.
ERROR: Failed to instantiate an autoload, can't load from path: res://scripts/autoload/save_manager.gd.
ALL PASS
```

Status: PASSED (all assertions passed, exit code 0)

Note: Autoload errors are expected and harmless - these files are part of Task 4.

## Commit Details

Command:
```bash
git add scripts/save_data.gd tests/test_save_data.gd
git commit -m "feat: add pure JSON save data read/write"
```

Commit Hash: `bb724a7`

Full output:
```
[feature/mvp bb724a7] feat: add pure JSON save data read/write
 2 files changed, 63 insertions(+)
 create mode mode 100644 scripts/save_data.gd
 create mode mode 100644 tests/test_save_data.gd
```

## Code Review

- No inline magic numbers in SaveData implementation
- All constants already defined in GameConstants (checked brief code - none needed)
- Error handling follows brief specification exactly
- Test coverage complete: missing file defaults, save/load round-trip, all three fields verified

## Status

✅ Task 3 complete. All steps executed per brief. No concerns.

---

## Code Review Fix: Guard save_to() Against Null FileAccess

**Finding**: scripts/save_data.gd, function save_to(), calls FileAccess.open() without checking if the result is null before calling file.store_string(). This can crash if the directory is missing or permissions are denied.

**Fix Applied**: Added null check guard:
```gdscript
static func save_to(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))
	file.close()
```

**Test Verification**:
```bash
cd /Users/pmousavi/Documents/me/projects/ai/space-shooter && godot --headless --script res://tests/test_save_data.gd
```

Output:
```
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
```

Status: **PASSED** (exit code 0)

**Commit Hash**: `0817937`

Command:
```bash
git add scripts/save_data.gd && git commit -m "fix: guard save_data.save_to against null FileAccess handle"
```

Fix complete. save_to() now matches load_from() defensive null-check pattern.
