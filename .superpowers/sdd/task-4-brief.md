### Task 4: Wave pool — procedural enemy selection (pure, tested)

**Files:**
- Create: `scripts/wave_pool.gd`
- Test: `tests/test_wave_pool.gd`

**Interfaces:**
- Consumes: `Difficulty.enemy_count_for_level` (Task 2).
- Produces: `WavePool` class with static func `pick_wave(level: int, rng: RandomNumberGenerator) -> Array` returning an `Array[String]` of enemy type ids (`"straight"`, `"zigzag"`, `"shooter"`), length equal to `Difficulty.enemy_count_for_level(level)`, each entry one of the 3 type ids. Also `static func enemy_type_ids() -> Array[String]` returning `["straight", "zigzag", "shooter"]` (single source of truth for valid type ids, consumed by Task 9 spawner).

- [ ] **Step 1: Write the failing test**

```gdscript
# tests/test_wave_pool.gd
extends SceneTree

const WavePool = preload("res://scripts/wave_pool.gd")
const Difficulty = preload("res://scripts/difficulty.gd")

var failures := 0

func check(name: String, cond: bool) -> void:
	if not cond:
		failures += 1
		print("FAIL %s" % name)

func _initialize() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234

	var valid_ids := WavePool.enemy_type_ids()
	check("type_ids has 3 entries", valid_ids.size() == 3)

	var wave := WavePool.pick_wave(3, rng)
	check("wave length matches difficulty", wave.size() == Difficulty.enemy_count_for_level(3))
	var all_valid := true
	for id in wave:
		if not valid_ids.has(id):
			all_valid = false
	check("all entries are valid type ids", all_valid)

	# Same seed -> same sequence (determinism)
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 1234
	var wave2 := WavePool.pick_wave(3, rng2)
	check("same seed produces same wave", wave == wave2)

	if failures == 0:
		print("ALL PASS")
	else:
		print("%d FAILURES" % failures)
	quit(1 if failures > 0 else 0)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --script res://tests/test_wave_pool.gd`
Expected: error opening `res://scripts/wave_pool.gd` (doesn't exist), non-zero exit.

- [ ] **Step 3: Write minimal implementation**

```gdscript
# scripts/wave_pool.gd
class_name WavePool
extends RefCounted

const Difficulty = preload("res://scripts/difficulty.gd")

static func enemy_type_ids() -> Array:
	return ["straight", "zigzag", "shooter"]

static func pick_wave(level: int, rng: RandomNumberGenerator) -> Array:
	var count := Difficulty.enemy_count_for_level(level)
	var ids := enemy_type_ids()
	var wave: Array = []
	for i in range(count):
		wave.append(ids[rng.randi_range(0, ids.size() - 1)])
	return wave
```

- [ ] **Step 4: Run test to verify it passes**

Run: `godot --headless --script res://tests/test_wave_pool.gd`
Expected: prints `ALL PASS`, exit code 0.

- [ ] **Step 5: Commit**

```bash
git add scripts/wave_pool.gd tests/test_wave_pool.gd
git commit -m "feat: add deterministic procedural wave enemy selection"
```

---

