# Task 1 Report: Project scaffold + balance constants

## What was done

Successfully completed all steps of Task 1:

1. **Created project.godot** - Project configuration file with:
   - Godot 4.7 and GL Compatibility features
   - Portrait viewport (720x1280)
   - MainMenu.tscn as main scene
   - Autoload references to game_manager.gd and save_manager.gd (not yet created, as expected)

2. **Created scripts/constants.gd** - Game constants class with:
   - GameConstants class_name declaration
   - All 24 required constants for viewport, enemy scaling, boss scaling, player, score, and pickups
   - All values match the brief exactly

3. **Ran verification command** - Executed: `godot --headless --quit`
   - Exit code: 0 (success)
   - Expected errors about missing autoload scripts and MainMenu.tscn appeared (as documented in brief as acceptable)

4. **Committed changes** - Created git commit with exact message from brief

## Verification command and output

**Command executed:**
```bash
godot --headless --quit
```

**Full output:**
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
ERROR: Cannot open file 'res://scenes/MainMenu.tscn'.
   at: load (scene/resources/resource_format_text.cpp:1442)
ERROR: Failed loading resource: res://scenes/MainMenu.tscn.
   at: _load (core/io/resource_loader.cpp:317)
ERROR: Failed loading scene: res://scenes/MainMenu.tscn.
   at: start (main/main.cpp:4763)
```

**Exit code:** 0 (success)

## Commit created

**Hash:** d923e32

**Message:** `chore: scaffold Godot project with balance constants`

**Files changed:**
- Created: project.godot (27 lines)
- Created: scripts/constants.gd (30 lines)

## Concerns

None. All expected warnings about missing autoload scripts and MainMenu.tscn scene appeared as documented. The project.godot configuration is valid and Godot exited successfully (exit code 0).
