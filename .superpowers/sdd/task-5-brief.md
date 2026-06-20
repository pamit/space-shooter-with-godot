### Task 5: GameManager + SaveManager autoload singletons (tested)

**Files:**
- Create: `scripts/autoload/game_manager.gd`
- Create: `scripts/autoload/save_manager.gd`
- Test: `tests/test_game_manager.gd`

**Interfaces:**
- Consumes: `SaveData` (Task 3), `GameConstants` (Task 1).
- Produces:
  - `GameManager` (autoload singleton, accessible globally as `GameManager`): properties `level: int`, `score: int`, `kills: int`, `player_hp: float`; methods `start_run() -> void` (resets level=1, score=0, kills=0, player_hp=GameConstants.PLAYER_MAX_HP), `add_kill() -> void` (kills+=1, score += GameConstants.SCORE_PER_KILL), `advance_level() -> void` (level+=1, score += GameConstants.SCORE_PER_LEVEL), `damage_player(amount: float) -> void` (clamps player_hp to >=0), `is_player_dead() -> bool`, `restart_current_level() -> void` (player_hp reset to max, score/kills/level unchanged); signals `player_died`, `level_advanced(new_level: int)`.
  - `SaveManager` (autoload singleton, accessible globally as `SaveManager`): const `SAVE_PATH := "user://savegame.json"`; method `report_run_result(score: int, kills: int) -> void` (updates high_score if score is higher, adds kills to total_kills, persists via `SaveData.save_to`); method `get_high_score() -> int`; loads from disk in `_ready()`.

- [ ] **Step 1: Write the failing test**

```gdscript
# tests/test_game_manager.gd
extends SceneTree

const GameManagerScript = preload("res://scripts/autoload/game_manager.gd")

var failures := 0

func check(name: String, actual, expected) -> void:
	if actual != expected:
		failures += 1
		print("FAIL %s: expected %s, got %s" % [name, expected, actual])

func _initialize() -> void:
	var gm = GameManagerScript.new()
	gm.start_run()
	check("initial level", gm.level, 1)
	check("initial score", gm.score, 0)
	check("initial hp", gm.player_hp, GameConstants.PLAYER_MAX_HP)

	gm.add_kill()
	gm.add_kill()
	check("score after 2 kills", gm.score, GameConstants.SCORE_PER_KILL * 2)
	check("kills after 2 kills", gm.kills, 2)

	gm.advance_level()
	check("level after advance", gm.level, 2)
	check("score after advance", gm.score, GameConstants.SCORE_PER_KILL * 2 + GameConstants.SCORE_PER_LEVEL)

	gm.damage_player(GameConstants.PLAYER_MAX_HP + 50)
	check("hp clamped to 0", gm.player_hp, 0.0)
	check("is_player_dead true", gm.is_player_dead(), true)

	gm.restart_current_level()
	check("hp reset after restart", gm.player_hp, GameConstants.PLAYER_MAX_HP)
	check("level unchanged after restart", gm.level, 2)
	check("score unchanged after restart", gm.score, GameConstants.SCORE_PER_KILL * 2 + GameConstants.SCORE_PER_LEVEL)

	if failures == 0:
		print("ALL PASS")
	else:
		print("%d FAILURES" % failures)
	quit(1 if failures > 0 else 0)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --script res://tests/test_game_manager.gd`
Expected: error opening `res://scripts/autoload/game_manager.gd` (doesn't exist), non-zero exit.

- [ ] **Step 3: Write minimal implementation**

```gdscript
# scripts/autoload/game_manager.gd
extends Node

signal player_died
signal level_advanced(new_level: int)

var level: int = 1
var score: int = 0
var kills: int = 0
var player_hp: float = GameConstants.PLAYER_MAX_HP

func start_run() -> void:
	level = 1
	score = 0
	kills = 0
	player_hp = GameConstants.PLAYER_MAX_HP

func add_kill() -> void:
	kills += 1
	score += GameConstants.SCORE_PER_KILL

func advance_level() -> void:
	level += 1
	score += GameConstants.SCORE_PER_LEVEL
	level_advanced.emit(level)

func damage_player(amount: float) -> void:
	player_hp = clamp(player_hp - amount, 0.0, GameConstants.PLAYER_MAX_HP)
	if player_hp <= 0.0:
		player_died.emit()

func is_player_dead() -> bool:
	return player_hp <= 0.0

func restart_current_level() -> void:
	player_hp = GameConstants.PLAYER_MAX_HP
```

```gdscript
# scripts/autoload/save_manager.gd
extends Node

const SAVE_PATH := "user://savegame.json"

var _data: Dictionary = {}

func _ready() -> void:
	_data = SaveData.load_from(SAVE_PATH)

func get_high_score() -> int:
	return _data.get("high_score", 0)

func report_run_result(score: int, kills: int) -> void:
	if score > _data.get("high_score", 0):
		_data["high_score"] = score
	_data["total_kills"] = _data.get("total_kills", 0) + kills
	SaveData.save_to(SAVE_PATH, _data)
```

- [ ] **Step 4: Run test to verify it passes**

Run: `godot --headless --script res://tests/test_game_manager.gd`
Expected: prints `ALL PASS`, exit code 0.

Note: this test instantiates `GameManagerScript.new()` directly (not as an autoload), so `GameConstants` must be globally resolvable by class name — confirmed by Task 1's `class_name GameConstants` declaration, which Godot registers project-wide once the project has been opened/imported at least once (already satisfied by Task 1 Step 3).

- [ ] **Step 5: Commit**

```bash
git add scripts/autoload/game_manager.gd scripts/autoload/save_manager.gd tests/test_game_manager.gd
git commit -m "feat: add GameManager and SaveManager autoload singletons"
```

---

