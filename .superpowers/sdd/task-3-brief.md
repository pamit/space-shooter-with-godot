### Task 3: Save data (pure JSON read/write, tested)

**Files:**
- Create: `scripts/save_data.gd`
- Test: `tests/test_save_data.gd`

**Interfaces:**
- Produces: `SaveData` class with static funcs: `load_from(path: String) -> Dictionary` (returns `{"high_score": int, "total_kills": int, "currency": int}`, defaults to zeros if file missing/corrupt), `save_to(path: String, data: Dictionary) -> void`.
- Consumed by: `SaveManager` autoload (Task 4).

- [ ] **Step 1: Write the failing test**

```gdscript
# tests/test_save_data.gd
extends SceneTree

const SaveData = preload("res://scripts/save_data.gd")

var failures := 0

func check(name: String, actual, expected) -> void:
	if actual != expected:
		failures += 1
		print("FAIL %s: expected %s, got %s" % [name, expected, actual])

func _initialize() -> void:
	var path := "user://test_savegame.json"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	var missing := SaveData.load_from(path)
	check("missing.high_score", missing.high_score, 0)
	check("missing.total_kills", missing.total_kills, 0)
	check("missing.currency", missing.currency, 0)

	SaveData.save_to(path, {"high_score": 420, "total_kills": 17, "currency": 5})
	var loaded := SaveData.load_from(path)
	check("loaded.high_score", loaded.high_score, 420)
	check("loaded.total_kills", loaded.total_kills, 17)
	check("loaded.currency", loaded.currency, 5)

	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	if failures == 0:
		print("ALL PASS")
	else:
		print("%d FAILURES" % failures)
	quit(1 if failures > 0 else 0)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --script res://tests/test_save_data.gd`
Expected: error opening `res://scripts/save_data.gd` (doesn't exist), non-zero exit.

- [ ] **Step 3: Write minimal implementation**

```gdscript
# scripts/save_data.gd
class_name SaveData
extends RefCounted

static func default_data() -> Dictionary:
	return {"high_score": 0, "total_kills": 0, "currency": 0}

static func load_from(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return default_data()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return default_data()
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return default_data()
	var data := default_data()
	for key in data.keys():
		if parsed.has(key):
			data[key] = parsed[key]
	return data

static func save_to(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
```

- [ ] **Step 4: Run test to verify it passes**

Run: `godot --headless --script res://tests/test_save_data.gd`
Expected: prints `ALL PASS`, exit code 0.

- [ ] **Step 5: Commit**

```bash
git add scripts/save_data.gd tests/test_save_data.gd
git commit -m "feat: add pure JSON save data read/write"
```

---

