### Task 1: Project scaffold + balance constants

**Files:**
- Create: `project.godot`
- Create: `scripts/constants.gd`

**Interfaces:**
- Produces: `GameConstants` class (via `class_name`) with static-readable constants used by every later task: `VIEWPORT_W`, `VIEWPORT_H`, `BASE_ENEMY_COUNT`, `ENEMIES_PER_LEVEL`, `BASE_ENEMY_SPEED`, `SPEED_GROWTH_PER_LEVEL`, `MAX_SPEED_MULTIPLIER`, `BASE_BOSS_HP`, `BOSS_HP_GROWTH`, `BOSS_LEVEL_INTERVAL`, `BOSS_BULLET_COUNT_BASE`, `BOSS_BULLET_COUNT_PER_LEVEL`, `BOSS_FIRE_INTERVAL_BASE`, `BOSS_FIRE_INTERVAL_MIN`, `PLAYER_MAX_HP`, `SCORE_PER_KILL`, `SCORE_PER_LEVEL`, `PICKUP_DURATION`.

- [ ] **Step 1: Create the Godot project file**

```ini
; project.godot
config_version=5

[application]

config/name="Space Shooter"
run/main_scene="res://scenes/MainMenu.tscn"
config/features=PackedStringArray("4.7", "GL Compatibility")

[display]

window/size/viewport_width=720
window/size/viewport_height=1280
window/handheld/orientation="portrait"
window/stretch/mode="canvas_items"
window/stretch/aspect="keep"

[rendering]

renderer/rendering_method="gl_compatibility"

[autoload]

GameManager="*res://scripts/autoload/game_manager.gd"
SaveManager="*res://scripts/autoload/save_manager.gd"
```

- [ ] **Step 2: Write balance constants**

```gdscript
# scripts/constants.gd
class_name GameConstants
extends RefCounted

const VIEWPORT_W := 720
const VIEWPORT_H := 1280

# Enemy wave scaling
const BASE_ENEMY_COUNT := 5
const ENEMIES_PER_LEVEL := 2
const BASE_ENEMY_SPEED := 100.0
const SPEED_GROWTH_PER_LEVEL := 0.03
const MAX_SPEED_MULTIPLIER := 2.5

# Boss scaling
const BASE_BOSS_HP := 100.0
const BOSS_HP_GROWTH := 1.15
const BOSS_LEVEL_INTERVAL := 5
const BOSS_BULLET_COUNT_BASE := 3
const BOSS_BULLET_COUNT_PER_LEVEL := 0.4
const BOSS_FIRE_INTERVAL_BASE := 1.5
const BOSS_FIRE_INTERVAL_MIN := 0.4

# Player
const PLAYER_MAX_HP := 100.0

# Score
const SCORE_PER_KILL := 10
const SCORE_PER_LEVEL := 50

# Pickups
const PICKUP_DURATION := 6.0
```

- [ ] **Step 3: Verify the project opens headless without errors**

Run: `cd space-shooter && godot --headless --quit`
Expected: prints Godot version/startup lines, exits 0, no `ERROR` lines about missing autoload scripts (they don't exist yet — expect a warning here, that's fine, fixed in Task 5).

- [ ] **Step 4: Commit**

```bash
git init
git add project.godot scripts/constants.gd
git commit -m "chore: scaffold Godot project with balance constants"
```

---

