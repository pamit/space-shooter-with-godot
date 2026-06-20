### Task 2: Difficulty formulas (pure, tested)

**Files:**
- Create: `scripts/difficulty.gd`
- Test: `tests/test_difficulty.gd`

**Interfaces:**
- Consumes: `GameConstants` (Task 1).
- Produces: `Difficulty` class with static funcs: `enemy_count_for_level(level: int) -> int`, `enemy_speed_multiplier(level: int) -> float`, `boss_hp_for_level(level: int) -> float`, `boss_bullet_count_for_level(level: int) -> int`, `boss_fire_interval_for_level(level: int) -> float`, `is_boss_level(level: int) -> bool`.

- [ ] **Step 1: Write the failing test**

```gdscript
# tests/test_difficulty.gd
extends SceneTree

const Difficulty = preload("res://scripts/difficulty.gd")

var failures := 0

func check(name: String, actual, expected) -> void:
	if actual != expected:
		failures += 1
		print("FAIL %s: expected %s, got %s" % [name, expected, actual])

func _initialize() -> void:
	check("enemy_count_for_level(1)", Difficulty.enemy_count_for_level(1), 5)
	check("enemy_count_for_level(3)", Difficulty.enemy_count_for_level(3), 9)
	check("enemy_speed_multiplier(1)", Difficulty.enemy_speed_multiplier(1), 1.0)
	check("boss_hp_for_level(1)", Difficulty.boss_hp_for_level(1), 100.0)
	check("is_boss_level(5)", Difficulty.is_boss_level(5), true)
	check("is_boss_level(6)", Difficulty.is_boss_level(6), false)
	check("boss_bullet_count_for_level(1)", Difficulty.boss_bullet_count_for_level(1), 3)
	if failures == 0:
		print("ALL PASS")
	else:
		print("%d FAILURES" % failures)
	quit(1 if failures > 0 else 0)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --script res://tests/test_difficulty.gd`
Expected: Godot error `Can't open file 'res://scripts/difficulty.gd'` (file doesn't exist yet), non-zero exit.

- [ ] **Step 3: Write minimal implementation**

```gdscript
# scripts/difficulty.gd
class_name Difficulty
extends RefCounted

const C = GameConstants

static func enemy_count_for_level(level: int) -> int:
	return C.BASE_ENEMY_COUNT + (level - 1) * C.ENEMIES_PER_LEVEL

static func enemy_speed_multiplier(level: int) -> float:
	var mult := 1.0 + (level - 1) * C.SPEED_GROWTH_PER_LEVEL
	return min(mult, C.MAX_SPEED_MULTIPLIER)

static func boss_hp_for_level(level: int) -> float:
	return C.BASE_BOSS_HP * pow(C.BOSS_HP_GROWTH, level - 1)

static func boss_bullet_count_for_level(level: int) -> int:
	return int(C.BOSS_BULLET_COUNT_BASE + level * C.BOSS_BULLET_COUNT_PER_LEVEL)

static func boss_fire_interval_for_level(level: int) -> float:
	var interval := C.BOSS_FIRE_INTERVAL_BASE - (level - 1) * 0.05
	return max(interval, C.BOSS_FIRE_INTERVAL_MIN)

static func is_boss_level(level: int) -> bool:
	return level % C.BOSS_LEVEL_INTERVAL == 0
```

- [ ] **Step 4: Run test to verify it passes**

Run: `godot --headless --script res://tests/test_difficulty.gd`
Expected: prints `ALL PASS`, exit code 0.

- [ ] **Step 5: Commit**

```bash
git add scripts/difficulty.gd tests/test_difficulty.gd
git commit -m "feat: add pure difficulty scaling formulas"
```

---

