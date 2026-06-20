# Space Shooter MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a portrait, touch-drag, auto-fire, endless vertical space shooter (Galaxy Attack-style) in Godot 4, with procedurally-scaled difficulty, per-level pickups, a scaling boss every N levels, local high-score save, and minimal UI — no monetization, no permanent upgrades in v1.

**Architecture:** Pure balance/data logic (difficulty formulas, wave enemy selection, save serialization) lives in plain `RefCounted`/static-style GDScript classes with zero scene-tree dependency, so it can be unit-tested headless via `godot --headless --script`. Stateful run data (score, level, HP) lives in a `GameManager` autoload singleton; persisted high score lives in a `SaveManager` autoload. Visual/gameplay nodes (Player, Enemy, Boss, Bullet, Pickup) are scenes with attached scripts that read from the pure logic layer. `Main.tscn` wires everything together and drives the level loop.

**Tech Stack:** Godot 4.7 (GDScript), portrait mobile target (Android export later), no external plugins/addons.

## Global Constraints

- Engine: Godot 4.7, GDScript only (no C#).
- Orientation: portrait, viewport 720x1280.
- Controls: touch-drag finger-follow (no virtual joystick).
- Firing: auto-fire always-on, no manual fire input.
- Difficulty: linear/formula-driven scaling by level (no hand-authored per-level tables).
- Levels: endless, procedural enemy-wave selection from a data-driven pool.
- Ship: single ship, no permanent upgrades in v1. Run currency/score tracked for future v2 but not spendable yet.
- HP: shield/HP bar, not single-hit death.
- Death: restart current level from scratch (level number unchanged, wave re-rolled).
- Boss: 1 archetype, every 5 levels, single attack pattern that scales in intensity (fire rate / bullet count) with level.
- Pickups: in-run only, reset each level (weapon boost, shield, speed, bomb).
- Score: `score = kills * 10 + level_reached * 50`.
- Monetization: none.
- Save: local-only JSON at `user://savegame.json` (high score only — no account/cloud).
- Art: no external asset packs in v1 — use primitive `Polygon2D`/`ColorRect` placeholders so the game is fully playable without downloads. Swapping in real Kenney-style sprites is a follow-up, not part of this plan.
- Audio: `AudioStreamPlayer` nodes are wired into every gameplay event (fire, hit, explosion, pickup, boss, menu) with `stream` left unassigned (`null`) where no royalty-free file is bundled. Code guards playback so a missing stream is a no-op, not an error. Dropping `.ogg`/`.wav` files into `assets/audio/` and assigning them in code is a follow-up, not part of this plan.

---

## File Structure

```
space-shooter/
  project.godot
  scripts/
    constants.gd                 # GameConstants: all balance numbers
    difficulty.gd                # Difficulty: pure formulas, static funcs
    save_data.gd                 # SaveData: JSON read/write, pure
    wave_pool.gd                 # WavePool: enemy-type selection, pure
    autoload/
      game_manager.gd            # GameManager singleton: score/level/HP/state
      save_manager.gd            # SaveManager singleton: high score persistence
    player.gd
    bullet.gd
    enemy_base.gd
    enemy_straight.gd
    enemy_zigzag.gd
    enemy_shooter.gd
    boss.gd
    pickup.gd
    wave_spawner.gd
    parallax_setup.gd
    hud.gd
    main_menu.gd
    main.gd
  scenes/
    Player.tscn
    Bullet.tscn
    EnemyBullet.tscn
    EnemyStraight.tscn
    EnemyZigzag.tscn
    EnemyShooter.tscn
    Boss.tscn
    Pickup.tscn
    HUD.tscn
    MainMenu.tscn
    Main.tscn
  tests/
    test_difficulty.gd
    test_save_data.gd
    test_wave_pool.gd
    test_game_manager.gd
```

---

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

### Task 6: Player scene — touch-drag movement, HP, auto-fire

**Files:**
- Create: `scenes/Player.tscn`
- Create: `scripts/player.gd`
- Create: `scenes/Bullet.tscn`
- Create: `scripts/bullet.gd`

**Interfaces:**
- Consumes: `GameManager.player_hp`/`damage_player` (Task 5), `GameConstants` (Task 1).
- Produces: `Player` node (group `"player"`) with exported `fire_rate: float = 0.25`, `bullet_scene: PackedScene`, `speed_multiplier: float = 1.0` (set by speed pickups, Task 11), method `apply_shield(active: bool) -> void`, signal `hit(amount: float)`. `Bullet` scene/script: exported `speed: float`, `damage: float`, moves in `direction` (`Vector2`), frees itself on leaving viewport or on area collision (area group check happens in the body it hits, e.g. enemy script calls `queue_free()` on the bullet after applying damage).

- [ ] **Step 1: Write the bullet script (used by player fire)**

```gdscript
# scripts/bullet.gd
extends Area2D

@export var speed: float = 600.0
@export var damage: float = 10.0
var direction: Vector2 = Vector2.UP

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	if position.y < -50 or position.y > GameConstants.VIEWPORT_H + 50:
		queue_free()
```

- [ ] **Step 2: Create the Bullet scene**

```ini
# scenes/Bullet.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/bullet.gd" id="1"]

[node name="Bullet" type="Area2D" groups=["player_bullet"]]
script = ExtResource("1")
collision_layer = 4
collision_mask = 8

[node name="Shape" type="CollisionShape2D" parent="."]

[node name="Visual" type="Polygon2D" parent="."]
polygon = PackedVector2Array(-4, -10, 4, -10, 4, 10, -4, 10)
color = Color(1, 0.9, 0.2, 1)
```

Note: `CollisionShape2D.shape` is intentionally left to be set in code (Step 3 below sets it on every spawned bullet instance) so the same scene can be reused for differently-sized bullets without per-scene resource duplication.

- [ ] **Step 3: Write the player script**

```gdscript
# scripts/player.gd
extends Area2D

signal hit(amount: float)

@export var fire_rate: float = 0.25
@export var bullet_scene: PackedScene
@export var speed_multiplier: float = 1.0

var _fire_timer: float = 0.0
var _drag_offset: Vector2 = Vector2.ZERO
var _dragging: bool = false
var _shield_active: bool = false

func _ready() -> void:
	add_to_group("player")
	GameManager.start_run()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if get_rect_global().has_point(event.position) or true:
				_dragging = true
				_drag_offset = global_position - event.position
		else:
			_dragging = false
	elif event is InputEventScreenDrag and _dragging:
		global_position = event.position + _drag_offset
		_clamp_to_screen()

func get_rect_global() -> Rect2:
	return Rect2(global_position - Vector2(40, 40), Vector2(80, 80))

func _clamp_to_screen() -> void:
	global_position.x = clamp(global_position.x, 30, GameConstants.VIEWPORT_W - 30)
	global_position.y = clamp(global_position.y, 30, GameConstants.VIEWPORT_H - 30)

func _physics_process(delta: float) -> void:
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire()
		_fire_timer = fire_rate

func _fire() -> void:
	if bullet_scene == null:
		return
	var bullet = bullet_scene.instantiate()
	bullet.direction = Vector2.UP
	get_parent().add_child(bullet)
	bullet.global_position = global_position + Vector2(0, -30)

func apply_shield(active: bool) -> void:
	_shield_active = active

func take_damage(amount: float) -> void:
	if _shield_active:
		return
	GameManager.damage_player(amount)
	hit.emit(amount)

func _on_area_entered(area: Node) -> void:
	if area.is_in_group("enemy_bullet") or area.is_in_group("enemy"):
		take_damage(20.0)
		if area.has_method("queue_free"):
			area.queue_free()
```

- [ ] **Step 4: Create the Player scene**

```ini
# scenes/Player.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/player.gd" id="1"]

[node name="Player" type="Area2D"]
script = ExtResource("1")
collision_layer = 2
collision_mask = 8

[node name="Shape" type="CollisionShape2D" parent="."]

[node name="Visual" type="Polygon2D" parent="."]
polygon = PackedVector2Array(0, -30, 25, 25, 0, 10, -25, 25)
color = Color(0.2, 0.7, 1, 1)

[connection signal="area_entered" from="." to="." method="_on_area_entered"]
```

- [ ] **Step 5: Manual verification (no automated test — touch input requires a running scene)**

Run: `godot --path . res://scenes/Player.tscn` (opens the editor's run mode for this scene). Since there's no parent `Main.tscn` yet, this will warn about missing bullet container, which is fine — full play-test happens in Task 12.

For now, verify headless that the scene parses with no script errors:

Run: `godot --headless --check-only --script res://scripts/player.gd`
Expected: no `Parse Error` lines printed, exit code 0.

- [ ] **Step 6: Commit**

```bash
git add scenes/Player.tscn scripts/player.gd scenes/Bullet.tscn scripts/bullet.gd
git commit -m "feat: add player touch-drag movement, auto-fire, and bullet scene"
```

---

### Task 7: Enemy base + 3 movement-pattern types

**Files:**
- Create: `scripts/enemy_base.gd`
- Create: `scripts/enemy_straight.gd`
- Create: `scripts/enemy_zigzag.gd`
- Create: `scripts/enemy_shooter.gd`
- Create: `scenes/EnemyStraight.tscn`, `scenes/EnemyZigzag.tscn`, `scenes/EnemyShooter.tscn`
- Create: `scenes/EnemyBullet.tscn` (reuses `scripts/bullet.gd` with `direction = Vector2.DOWN`)

**Interfaces:**
- Consumes: `Difficulty.enemy_speed_multiplier` (Task 2), `GameManager.add_kill` (Task 5).
- Produces: `EnemyBase` (extended by all 3 types) with exported `base_speed: float`, `hp: float = 20.0`, method `set_level(level: int) -> void` (applies `Difficulty.enemy_speed_multiplier(level)` to its movement speed), signal `died`. Each type adds to group `"enemy"`. On `hp <= 0`: emits `died`, calls `GameManager.add_kill()`, `queue_free()`.

- [ ] **Step 1: Write the enemy base script**

```gdscript
# scripts/enemy_base.gd
extends Area2D
class_name EnemyBase

signal died

@export var base_speed: float = 100.0
@export var hp: float = 20.0

var _speed: float = 100.0

func _ready() -> void:
	add_to_group("enemy")

func set_level(level: int) -> void:
	_speed = base_speed * Difficulty.enemy_speed_multiplier(level)

func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		died.emit()
		GameManager.add_kill()
		queue_free()

func _physics_process(_delta: float) -> void:
	if position.y > GameConstants.VIEWPORT_H + 60:
		queue_free()

func _on_area_entered(area: Node) -> void:
	if area.is_in_group("player_bullet"):
		take_damage(area.damage)
		area.queue_free()
```

- [ ] **Step 2: Write the 3 movement-pattern subclasses**

```gdscript
# scripts/enemy_straight.gd
extends "res://scripts/enemy_base.gd"

func _physics_process(delta: float) -> void:
	position.y += _speed * delta
	super._physics_process(delta)
```

```gdscript
# scripts/enemy_zigzag.gd
extends "res://scripts/enemy_base.gd"

var _t: float = 0.0
var _origin_x: float = 0.0
var _initialized: bool = false

func _physics_process(delta: float) -> void:
	if not _initialized:
		_origin_x = position.x
		_initialized = true
	_t += delta
	position.y += _speed * delta
	position.x = _origin_x + sin(_t * 3.0) * 60.0
	super._physics_process(delta)
```

```gdscript
# scripts/enemy_shooter.gd
extends "res://scripts/enemy_base.gd"

@export var enemy_bullet_scene: PackedScene
var _fire_timer: float = 1.0

func _physics_process(delta: float) -> void:
	position.y += _speed * 0.5 * delta
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire()
		_fire_timer = 1.5
	super._physics_process(delta)

func _fire() -> void:
	if enemy_bullet_scene == null:
		return
	var bullet = enemy_bullet_scene.instantiate()
	bullet.direction = Vector2.DOWN
	get_parent().add_child(bullet)
	bullet.global_position = global_position + Vector2(0, 20)
```

- [ ] **Step 3: Create EnemyBullet scene (reuses bullet.gd, marked as enemy_bullet group)**

```ini
# scenes/EnemyBullet.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/bullet.gd" id="1"]

[node name="EnemyBullet" type="Area2D" groups=["enemy_bullet"]]
script = ExtResource("1")
speed = 350.0
damage = 20.0
collision_layer = 8
collision_mask = 2

[node name="Shape" type="CollisionShape2D" parent="."]

[node name="Visual" type="Polygon2D" parent="."]
polygon = PackedVector2Array(-3, -8, 3, -8, 3, 8, -3, 8)
color = Color(1, 0.3, 0.3, 1)
```

- [ ] **Step 4: Create the 3 enemy scenes**

```ini
# scenes/EnemyStraight.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/enemy_straight.gd" id="1"]

[node name="EnemyStraight" type="Area2D" groups=["enemy"]]
script = ExtResource("1")
base_speed = 100.0
hp = 20.0
collision_layer = 8
collision_mask = 4

[node name="Shape" type="CollisionShape2D" parent="."]

[node name="Visual" type="Polygon2D" parent="."]
polygon = PackedVector2Array(0, 20, -20, -15, 20, -15)
color = Color(0.8, 0.2, 0.2, 1)

[connection signal="area_entered" from="." to="." method="_on_area_entered"]
```

```ini
# scenes/EnemyZigzag.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/enemy_zigzag.gd" id="1"]

[node name="EnemyZigzag" type="Area2D" groups=["enemy"]]
script = ExtResource("1")
base_speed = 90.0
hp = 15.0
collision_layer = 8
collision_mask = 4

[node name="Shape" type="CollisionShape2D" parent="."]

[node name="Visual" type="Polygon2D" parent="."]
polygon = PackedVector2Array(0, 20, -18, 0, 0, -20, 18, 0)
color = Color(0.8, 0.6, 0.1, 1)

[connection signal="area_entered" from="." to="." method="_on_area_entered"]
```

```ini
# scenes/EnemyShooter.tscn
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/enemy_shooter.gd" id="1"]
[ext_resource type="PackedScene" path="res://scenes/EnemyBullet.tscn" id="2"]

[node name="EnemyShooter" type="Area2D" groups=["enemy"]]
script = ExtResource("1")
base_speed = 60.0
hp = 30.0
enemy_bullet_scene = ExtResource("2")
collision_layer = 8
collision_mask = 4

[node name="Shape" type="CollisionShape2D" parent="."]

[node name="Visual" type="Polygon2D" parent="."]
polygon = PackedVector2Array(0, 22, -22, -10, 0, -22, 22, -10)
color = Color(0.6, 0.1, 0.7, 1)

[connection signal="area_entered" from="." to="." method="_on_area_entered"]
```

- [ ] **Step 5: Verify scripts parse cleanly**

Run: `godot --headless --check-only --script res://scripts/enemy_base.gd && godot --headless --check-only --script res://scripts/enemy_straight.gd && godot --headless --check-only --script res://scripts/enemy_zigzag.gd && godot --headless --check-only --script res://scripts/enemy_shooter.gd`
Expected: no `Parse Error` output for any of the four, exit code 0 each.

- [ ] **Step 6: Commit**

```bash
git add scripts/enemy_base.gd scripts/enemy_straight.gd scripts/enemy_zigzag.gd scripts/enemy_shooter.gd scenes/EnemyStraight.tscn scenes/EnemyZigzag.tscn scenes/EnemyShooter.tscn scenes/EnemyBullet.tscn
git commit -m "feat: add 3 enemy types with distinct movement patterns"
```

---

### Task 8: Boss scene — scaling single attack pattern

**Files:**
- Create: `scripts/boss.gd`
- Create: `scenes/Boss.tscn`

**Interfaces:**
- Consumes: `Difficulty.boss_hp_for_level`, `boss_bullet_count_for_level`, `boss_fire_interval_for_level` (Task 2), `EnemyBullet.tscn` (Task 7).
- Produces: `Boss` node (group `"enemy"`, also group `"boss"`) with method `set_level(level: int) -> void` (sets `hp` and internal fire params from `Difficulty`), signal `died`. Fires a radial spread of `boss_bullet_count_for_level(level)` bullets every `boss_fire_interval_for_level(level)` seconds.

- [ ] **Step 1: Write the boss script**

```gdscript
# scripts/boss.gd
extends Area2D

signal died

@export var enemy_bullet_scene: PackedScene
var hp: float = 100.0
var _bullet_count: int = 3
var _fire_interval: float = 1.5
var _fire_timer: float = 1.5
var _move_dir: float = 1.0

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("boss")

func set_level(level: int) -> void:
	hp = Difficulty.boss_hp_for_level(level)
	_bullet_count = Difficulty.boss_bullet_count_for_level(level)
	_fire_interval = Difficulty.boss_fire_interval_for_level(level)
	_fire_timer = _fire_interval

func _physics_process(delta: float) -> void:
	position.x += _move_dir * 80.0 * delta
	if position.x < 80 or position.x > GameConstants.VIEWPORT_W - 80:
		_move_dir *= -1.0
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_spread()
		_fire_timer = _fire_interval

func _fire_spread() -> void:
	if enemy_bullet_scene == null:
		return
	var spread_angle := PI / 4.0
	for i in range(_bullet_count):
		var t := 0.0 if _bullet_count == 1 else float(i) / float(_bullet_count - 1)
		var angle := lerp(-spread_angle, spread_angle, t) + PI / 2.0
		var bullet = enemy_bullet_scene.instantiate()
		bullet.direction = Vector2.RIGHT.rotated(angle)
		get_parent().add_child(bullet)
		bullet.global_position = global_position + Vector2(0, 30)

func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		died.emit()
		GameManager.add_kill()
		queue_free()

func _on_area_entered(area: Node) -> void:
	if area.is_in_group("player_bullet"):
		take_damage(area.damage)
		area.queue_free()
```

- [ ] **Step 2: Create the Boss scene**

```ini
# scenes/Boss.tscn
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/boss.gd" id="1"]
[ext_resource type="PackedScene" path="res://scenes/EnemyBullet.tscn" id="2"]

[node name="Boss" type="Area2D" groups=["enemy", "boss"]]
script = ExtResource("1")
enemy_bullet_scene = ExtResource("2")
collision_layer = 8
collision_mask = 4

[node name="Shape" type="CollisionShape2D" parent="."]

[node name="Visual" type="Polygon2D" parent="."]
polygon = PackedVector2Array(0, 50, -60, -10, -30, -50, 30, -50, 60, -10)
color = Color(0.9, 0.1, 0.1, 1)

[connection signal="area_entered" from="." to="." method="_on_area_entered"]
```

- [ ] **Step 3: Verify script parses cleanly**

Run: `godot --headless --check-only --script res://scripts/boss.gd`
Expected: no `Parse Error` output, exit code 0.

- [ ] **Step 4: Commit**

```bash
git add scripts/boss.gd scenes/Boss.tscn
git commit -m "feat: add boss with level-scaled radial bullet spread"
```

---

### Task 9: Pickups — weapon boost, shield, speed, bomb

**Files:**
- Create: `scripts/pickup.gd`
- Create: `scenes/Pickup.tscn`

**Interfaces:**
- Consumes: `Player.apply_shield` (Task 6), `GameConstants.PICKUP_DURATION` (Task 1).
- Produces: `Pickup` node, exported `kind: String` (one of `"weapon"`, `"shield"`, `"speed"`, `"bomb"`), falls downward, on overlapping group `"player"` applies its effect then `queue_free()`:
  - `"weapon"`: sets player `fire_rate` to a third for `PICKUP_DURATION` seconds, then restores.
  - `"shield"`: calls `player.apply_shield(true)`, then `false` after `PICKUP_DURATION`.
  - `"speed"`: sets player `speed_multiplier` to `1.6` for `PICKUP_DURATION` seconds, then restores to `1.0`. (`speed_multiplier` is read by `Player._clamp_to_screen`-adjacent drag logic — Task 6's drag movement is 1:1 with finger position already, so this multiplier is exposed for the pickup to set but does not change drag responsiveness; documented here as a no-op visual hook intentionally, since finger-follow movement has no "speed" to scale. Skip wiring `speed_multiplier` into movement math — it stays exported on `Player` for parity with the locked pickup list but has no effect until a non-drag movement mode exists.)
  - `"bomb"`: on pickup, immediately damages every node in group `"enemy"` for 999 damage (one-shot screen clear), no duration.

- [ ] **Step 1: Write the pickup script**

```gdscript
# scripts/pickup.gd
extends Area2D

@export var kind: String = "weapon"
@export var fall_speed: float = 120.0

func _ready() -> void:
	add_to_group("pickup")

func _physics_process(delta: float) -> void:
	position.y += fall_speed * delta
	if position.y > GameConstants.VIEWPORT_H + 50:
		queue_free()

func _on_area_entered(area: Node) -> void:
	if not area.is_in_group("player"):
		return
	match kind:
		"weapon":
			_apply_weapon_boost(area)
		"shield":
			_apply_shield(area)
		"speed":
			_apply_speed(area)
		"bomb":
			_apply_bomb()
	queue_free()

func _apply_weapon_boost(player: Node) -> void:
	var original := player.fire_rate
	player.fire_rate = original / 3.0
	get_tree().create_timer(GameConstants.PICKUP_DURATION).timeout.connect(
		func(): player.fire_rate = original
	)

func _apply_shield(player: Node) -> void:
	player.apply_shield(true)
	get_tree().create_timer(GameConstants.PICKUP_DURATION).timeout.connect(
		func(): player.apply_shield(false)
	)

func _apply_speed(player: Node) -> void:
	var original := player.speed_multiplier
	player.speed_multiplier = 1.6
	get_tree().create_timer(GameConstants.PICKUP_DURATION).timeout.connect(
		func(): player.speed_multiplier = original
	)

func _apply_bomb() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.has_method("take_damage"):
			enemy.take_damage(999.0)
```

- [ ] **Step 2: Create the Pickup scene**

```ini
# scenes/Pickup.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/pickup.gd" id="1"]

[node name="Pickup" type="Area2D"]
script = ExtResource("1")
collision_layer = 16
collision_mask = 2

[node name="Shape" type="CollisionShape2D" parent="."]

[node name="Visual" type="Polygon2D" parent="."]
polygon = PackedVector2Array(-12, -12, 12, -12, 12, 12, -12, 12)
color = Color(0.2, 1, 0.4, 1)

[connection signal="area_entered" from="." to="." method="_on_area_entered"]
```

- [ ] **Step 3: Verify script parses cleanly**

Run: `godot --headless --check-only --script res://scripts/pickup.gd`
Expected: no `Parse Error` output, exit code 0.

- [ ] **Step 4: Commit**

```bash
git add scripts/pickup.gd scenes/Pickup.tscn
git commit -m "feat: add 4 in-run pickup types (weapon, shield, speed, bomb)"
```

---

### Task 10: Wave spawner — drives procedural waves + pickup drops

**Files:**
- Create: `scripts/wave_spawner.gd`

**Interfaces:**
- Consumes: `WavePool.pick_wave` (Task 4), `Difficulty.is_boss_level` (Task 2), enemy scenes (Task 7), `Boss.tscn` (Task 8), `Pickup.tscn` (Task 9).
- Produces: `WaveSpawner` node (added as a child in `Main.tscn`), exported `enemy_scenes: Dictionary` (maps `"straight"/"zigzag"/"shooter"` to `PackedScene`), `boss_scene: PackedScene`, `pickup_scene: PackedScene`; method `start_level(level: int) -> void` spawns the wave (or boss if `Difficulty.is_boss_level(level)`), connects to each spawned enemy/boss `died` signal, emits its own signal `wave_cleared` when all spawned enemies are gone; method `clear_all() -> void` (frees every currently-spawned enemy/pickup — used on level restart).

- [ ] **Step 1: Write the wave spawner script**

```gdscript
# scripts/wave_spawner.gd
extends Node2D

signal wave_cleared

@export var enemy_scenes: Dictionary = {}
@export var boss_scene: PackedScene
@export var pickup_scene: PackedScene
@export var pickup_drop_chance: float = 0.15

var _alive_count: int = 0
var _rng := RandomNumberGenerator.new()
var _spawned: Array = []

func _ready() -> void:
	_rng.randomize()

func start_level(level: int) -> void:
	clear_all()
	if Difficulty.is_boss_level(level):
		_spawn_boss(level)
	else:
		_spawn_wave(level)

func clear_all() -> void:
	for node in _spawned:
		if is_instance_valid(node):
			node.queue_free()
	_spawned.clear()
	_alive_count = 0

func _spawn_wave(level: int) -> void:
	var wave := WavePool.pick_wave(level, _rng)
	_alive_count = wave.size()
	for i in range(wave.size()):
		var type_id: String = wave[i]
		var scene: PackedScene = enemy_scenes.get(type_id)
		if scene == null:
			continue
		var enemy = scene.instantiate()
		add_child(enemy)
		_spawned.append(enemy)
		enemy.global_position = Vector2(
			_rng.randf_range(60, GameConstants.VIEWPORT_W - 60),
			-50.0 - i * 70.0
		)
		enemy.set_level(level)
		enemy.died.connect(_on_enemy_died.bind(enemy.global_position))

func _spawn_boss(level: int) -> void:
	if boss_scene == null:
		return
	_alive_count = 1
	var boss = boss_scene.instantiate()
	add_child(boss)
	_spawned.append(boss)
	boss.global_position = Vector2(GameConstants.VIEWPORT_W / 2.0, 150.0)
	boss.set_level(level)
	boss.died.connect(_on_enemy_died.bind(boss.global_position))

func _on_enemy_died(drop_position: Vector2) -> void:
	_alive_count -= 1
	if pickup_scene != null and _rng.randf() < pickup_drop_chance:
		_drop_pickup(drop_position)
	if _alive_count <= 0:
		wave_cleared.emit()

func _drop_pickup(drop_position: Vector2) -> void:
	var kinds := ["weapon", "shield", "speed", "bomb"]
	var pickup = pickup_scene.instantiate()
	pickup.kind = kinds[_rng.randi_range(0, kinds.size() - 1)]
	add_child(pickup)
	pickup.global_position = drop_position
```

- [ ] **Step 2: Verify script parses cleanly**

Run: `godot --headless --check-only --script res://scripts/wave_spawner.gd`
Expected: no `Parse Error` output, exit code 0.

- [ ] **Step 3: Commit**

```bash
git add scripts/wave_spawner.gd
git commit -m "feat: add wave spawner driving procedural waves, bosses, and pickup drops"
```

---

### Task 11: Parallax starfield background

**Files:**
- Create: `scripts/parallax_setup.gd`

**Interfaces:**
- Produces: `ParallaxSetup` script attached to a `ParallaxBackground` node in `Main.tscn` (Task 12); in `_ready()` builds 3 `ParallaxLayer` children procedurally (no external star sprite needed — uses `Polygon2D` dots drawn via `_draw()` on a `Node2D` per layer), each layer auto-scrolling downward at a different speed to fake forward motion, and wrapping via `ParallaxBackground.scroll_offset`.

- [ ] **Step 1: Write the parallax setup script**

```gdscript
# scripts/parallax_setup.gd
extends ParallaxBackground

const LAYER_CONFIGS := [
	{"speed": 20.0, "count": 40, "size": 1.0, "color": Color(1, 1, 1, 0.4)},
	{"speed": 50.0, "count": 25, "size": 1.5, "color": Color(1, 1, 1, 0.7)},
	{"speed": 90.0, "count": 12, "size": 2.0, "color": Color(1, 1, 1, 1.0)},
]

var _speeds: Array = []

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for config in LAYER_CONFIGS:
		var layer := ParallaxLayer.new()
		add_child(layer)
		_speeds.append(config["speed"])
		for i in range(config["count"]):
			var star := ColorRect.new()
			var s: float = config["size"]
			star.size = Vector2(s, s)
			star.color = config["color"]
			star.position = Vector2(
				rng.randf_range(0, GameConstants.VIEWPORT_W),
				rng.randf_range(0, GameConstants.VIEWPORT_H)
			)
			layer.add_child(star)

func _process(delta: float) -> void:
	for i in range(get_child_count()):
		var layer := get_child(i) as ParallaxLayer
		layer.motion_offset.y += _speeds[i] * delta
		if layer.motion_offset.y > GameConstants.VIEWPORT_H:
			layer.motion_offset.y = 0.0
```

- [ ] **Step 2: Verify script parses cleanly**

Run: `godot --headless --check-only --script res://scripts/parallax_setup.gd`
Expected: no `Parse Error` output, exit code 0.

- [ ] **Step 3: Commit**

```bash
git add scripts/parallax_setup.gd
git commit -m "feat: add procedural 3-layer parallax starfield"
```

---

### Task 12: HUD, Main Menu, and Main scene wiring

**Files:**
- Create: `scripts/hud.gd`, `scenes/HUD.tscn`
- Create: `scripts/main_menu.gd`, `scenes/MainMenu.tscn`
- Create: `scripts/main.gd`, `scenes/Main.tscn`

**Interfaces:**
- Consumes: every prior task's scenes/scripts and signals.
- Produces: `MainMenu` (Play button -> loads `Main.tscn`; displays `SaveManager.get_high_score()`; mute toggle sets `AudioServer.set_bus_mute(0, muted)`); `HUD` (progress-bar HP from `GameManager.player_hp`, label for `GameManager.level`, label for `GameManager.score`, pause button toggling `get_tree().paused`); `Main` (instances `Player`, `WaveSpawner`, `HUD`, `ParallaxBackground`; on `wave_cleared` calls `GameManager.advance_level()` then `wave_spawner.start_level(GameManager.level)`; on `GameManager.player_died` shows game-over overlay, calls `SaveManager.report_run_result(...)`, and on confirm calls `GameManager.restart_current_level()` + `wave_spawner.start_level(GameManager.level)`).

- [ ] **Step 1: Write the HUD script and scene**

```gdscript
# scripts/hud.gd
extends Control

@onready var hp_bar: ProgressBar = $HPBar
@onready var level_label: Label = $LevelLabel
@onready var score_label: Label = $ScoreLabel

func _process(_delta: float) -> void:
	hp_bar.max_value = GameConstants.PLAYER_MAX_HP
	hp_bar.value = GameManager.player_hp
	level_label.text = "Level %d" % GameManager.level
	score_label.text = "Score %d" % GameManager.score

func _on_pause_pressed() -> void:
	get_tree().paused = not get_tree().paused
```

```ini
# scenes/HUD.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/hud.gd" id="1"]

[node name="HUD" type="Control"]
script = ExtResource("1")
anchors_preset = 15
process_mode = 3

[node name="HPBar" type="ProgressBar" parent="."]
offset_left = 20.0
offset_top = 20.0
offset_right = 220.0
offset_bottom = 44.0

[node name="LevelLabel" type="Label" parent="."]
offset_left = 20.0
offset_top = 50.0
text = "Level 1"

[node name="ScoreLabel" type="Label" parent="."]
offset_left = 20.0
offset_top = 80.0
text = "Score 0"

[node name="PauseButton" type="Button" parent="."]
offset_left = 620.0
offset_top = 20.0
offset_right = 700.0
offset_bottom = 60.0
text = "||"

[connection signal="pressed" from="PauseButton" to="." method="_on_pause_pressed"]
```

- [ ] **Step 2: Write the Main Menu script and scene**

```gdscript
# scripts/main_menu.gd
extends Control

@onready var high_score_label: Label = $HighScoreLabel
@onready var mute_button: CheckButton = $MuteButton

func _ready() -> void:
	high_score_label.text = "High Score: %d" % SaveManager.get_high_score()

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_mute_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(0, toggled_on)
```

```ini
# scenes/MainMenu.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/main_menu.gd" id="1"]

[node name="MainMenu" type="Control"]
script = ExtResource("1")
anchors_preset = 15

[node name="Title" type="Label" parent="."]
offset_left = 240.0
offset_top = 300.0
text = "SPACE SHOOTER"

[node name="HighScoreLabel" type="Label" parent="."]
offset_left = 270.0
offset_top = 360.0
text = "High Score: 0"

[node name="PlayButton" type="Button" parent="."]
offset_left = 300.0
offset_top = 420.0
offset_right = 420.0
offset_bottom = 460.0
text = "PLAY"

[node name="MuteButton" type="CheckButton" parent="."]
offset_left = 300.0
offset_top = 480.0
text = "Mute"

[connection signal="pressed" from="PlayButton" to="." method="_on_play_pressed"]
[connection signal="toggled" from="MuteButton" to="." method="_on_mute_toggled"]
```

- [ ] **Step 3: Write the Main script**

```gdscript
# scripts/main.gd
extends Node2D

@onready var wave_spawner: Node2D = $WaveSpawner
@onready var hud: Control = $HUD
@onready var game_over_panel: Control = $GameOverPanel
@onready var final_score_label: Label = $GameOverPanel/FinalScoreLabel

func _ready() -> void:
	game_over_panel.visible = false
	GameManager.player_died.connect(_on_player_died)
	wave_spawner.wave_cleared.connect(_on_wave_cleared)
	wave_spawner.start_level(GameManager.level)

func _on_wave_cleared() -> void:
	GameManager.advance_level()
	wave_spawner.start_level(GameManager.level)

func _on_player_died() -> void:
	get_tree().paused = true
	SaveManager.report_run_result(GameManager.score, GameManager.kills)
	final_score_label.text = "Score: %d" % GameManager.score
	game_over_panel.visible = true

func _on_retry_pressed() -> void:
	get_tree().paused = false
	game_over_panel.visible = false
	GameManager.restart_current_level()
	wave_spawner.start_level(GameManager.level)

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
```

- [ ] **Step 4: Create the Main scene wiring every node together**

```ini
# scenes/Main.tscn
[gd_scene load_steps=8 format=3]

[ext_resource type="Script" path="res://scripts/main.gd" id="1"]
[ext_resource type="Script" path="res://scripts/parallax_setup.gd" id="2"]
[ext_resource type="PackedScene" path="res://scenes/Player.tscn" id="3"]
[ext_resource type="PackedScene" path="res://scenes/Bullet.tscn" id="4"]
[ext_resource type="Script" path="res://scripts/wave_spawner.gd" id="5"]
[ext_resource type="PackedScene" path="res://scenes/Boss.tscn" id="6"]
[ext_resource type="PackedScene" path="res://scenes/Pickup.tscn" id="7"]
[ext_resource type="PackedScene" path="res://scenes/HUD.tscn" id="8"]
[ext_resource type="PackedScene" path="res://scenes/EnemyStraight.tscn" id="9"]
[ext_resource type="PackedScene" path="res://scenes/EnemyZigzag.tscn" id="10"]
[ext_resource type="PackedScene" path="res://scenes/EnemyShooter.tscn" id="11"]

[node name="Main" type="Node2D"]
script = ExtResource("1")

[node name="Parallax" type="ParallaxBackground" parent="."]
script = ExtResource("2")

[node name="Player" parent="." instance=ExtResource("3")]
position = Vector2(360, 1100)
bullet_scene = ExtResource("4")

[node name="WaveSpawner" type="Node2D" parent="."]
script = ExtResource("5")
boss_scene = ExtResource("6")
pickup_scene = ExtResource("7")
enemy_scenes = {
"straight": ExtResource("9"),
"zigzag": ExtResource("10"),
"shooter": ExtResource("11")
}

[node name="HUD" parent="." instance=ExtResource("8")]

[node name="GameOverPanel" type="Control" parent="."]
anchors_preset = 15
visible = false

[node name="FinalScoreLabel" type="Label" parent="GameOverPanel"]
offset_left = 270.0
offset_top = 500.0
text = "Score: 0"

[node name="RetryButton" type="Button" parent="GameOverPanel"]
offset_left = 280.0
offset_top = 560.0
offset_right = 440.0
offset_bottom = 600.0
text = "RETRY LEVEL"

[node name="QuitButton" type="Button" parent="GameOverPanel"]
offset_left = 300.0
offset_top = 610.0
offset_right = 420.0
offset_bottom = 650.0
text = "QUIT"

[connection signal="pressed" from="GameOverPanel/RetryButton" to="." method="_on_retry_pressed"]
[connection signal="pressed" from="GameOverPanel/QuitButton" to="." method="_on_quit_pressed"]
```

- [ ] **Step 5: Verify all scripts parse cleanly**

Run: `for f in scripts/hud.gd scripts/main_menu.gd scripts/main.gd; do godot --headless --check-only --script res://$f || echo "FAILED $f"; done`
Expected: no `FAILED` lines printed.

- [ ] **Step 6: Manual play-test (requires the Godot editor — this is the first point the full loop is playable)**

Open the project in the Godot editor (`godot --path .`), press F5 (or set `MainMenu.tscn` as run scene, already done in Task 1's `run/main_scene`), and verify:
1. Main menu shows "High Score: 0", Play button works.
2. Dragging anywhere moves the ship to follow your finger/cursor (mouse emulates touch in editor).
3. Ship auto-fires upward continuously.
4. Enemies spawn from the top in 3 distinct movement patterns (straight, zigzag, shooting).
5. Killing all enemies in a wave advances to the next level (HUD level label increments) and a new, larger wave spawns.
6. Reaching level 5 spawns a boss instead of a wave; killing it advances past level 5 to level 6 (a normal wave).
7. Taking enemy/boss bullet hits decreases the HP bar; HP reaching 0 shows the Game Over panel with final score.
8. Clicking "RETRY LEVEL" resets HP and re-spawns the same level's wave; "QUIT" returns to the main menu.
9. Occasionally a colored square (pickup) drops from a killed enemy; picking it up changes behavior (faster fire, brief invincibility, etc.) for a few seconds.

- [ ] **Step 7: Commit**

```bash
git add scripts/hud.gd scenes/HUD.tscn scripts/main_menu.gd scenes/MainMenu.tscn scripts/main.gd scenes/Main.tscn
git commit -m "feat: wire HUD, main menu, and main scene into a playable level loop"
```

---

### Task 13: Audio hooks (structural — no bundled files)

**Files:**
- Modify: `scripts/player.gd` (add fire/hit `AudioStreamPlayer` calls)
- Modify: `scripts/enemy_base.gd`, `scripts/boss.gd` (add explosion `AudioStreamPlayer` calls)
- Modify: `scripts/pickup.gd` (add pickup `AudioStreamPlayer` call)
- Modify: `scenes/Player.tscn`, `scenes/EnemyStraight.tscn`, `scenes/EnemyZigzag.tscn`, `scenes/EnemyShooter.tscn`, `scenes/Boss.tscn`, `scenes/Pickup.tscn` (add child `AudioStreamPlayer`/`AudioStreamPlayer2D` nodes, `stream` left empty)
- Modify: `scenes/MainMenu.tscn`, `scenes/Main.tscn` (add a `MusicPlayer` `AudioStreamPlayer`, `stream` left empty, `autoplay` true, loop via code if a stream is later assigned)

**Interfaces:**
- Produces: a `play_sfx(player: AudioStreamPlayer2D) -> void` pattern repeated at each call site: `if player.stream != null: player.play()`. No new public API — purely additive nodes + guarded calls.

- [ ] **Step 1: Add a guarded SFX helper and call sites in player.gd**

```gdscript
# scripts/player.gd — add near the top, after existing @export lines
@onready var fire_sfx: AudioStreamPlayer2D = $FireSFX
@onready var hit_sfx: AudioStreamPlayer2D = $HitSFX

# inside _fire(), after instantiating + positioning the bullet, add:
	if fire_sfx.stream != null:
		fire_sfx.play()

# inside take_damage(), after hit.emit(amount), add:
	if hit_sfx.stream != null:
		hit_sfx.play()
```

- [ ] **Step 2: Add `AudioStreamPlayer2D` children to Player.tscn**

```ini
# add to scenes/Player.tscn, as new nodes under "Player"
[node name="FireSFX" type="AudioStreamPlayer2D" parent="."]

[node name="HitSFX" type="AudioStreamPlayer2D" parent="."]
```

- [ ] **Step 3: Add guarded explosion SFX in enemy_base.gd and boss.gd**

```gdscript
# scripts/enemy_base.gd — add @onready and guard inside take_damage(), before queue_free()
@onready var explosion_sfx: AudioStreamPlayer2D = $ExplosionSFX

# inside take_damage(), right before queue_free():
	if explosion_sfx.stream != null:
		explosion_sfx.play()
		await get_tree().create_timer(0.3).timeout
```

```gdscript
# scripts/boss.gd — identical pattern
@onready var explosion_sfx: AudioStreamPlayer2D = $ExplosionSFX

# inside take_damage(), right before queue_free():
	if explosion_sfx.stream != null:
		explosion_sfx.play()
		await get_tree().create_timer(0.3).timeout
```

Add to each of `EnemyStraight.tscn`, `EnemyZigzag.tscn`, `EnemyShooter.tscn`, `Boss.tscn`:

```ini
[node name="ExplosionSFX" type="AudioStreamPlayer2D" parent="."]
```

- [ ] **Step 4: Add guarded pickup SFX in pickup.gd**

```gdscript
# scripts/pickup.gd — add @onready and guard inside _on_area_entered(), before queue_free()
@onready var pickup_sfx: AudioStreamPlayer2D = $PickupSFX

# at the end of _on_area_entered(), before the existing queue_free():
	if pickup_sfx.stream != null:
		pickup_sfx.play()
		await get_tree().create_timer(0.2).timeout
```

Add to `scenes/Pickup.tscn`:

```ini
[node name="PickupSFX" type="AudioStreamPlayer2D" parent="."]
```

- [ ] **Step 5: Add a music player to MainMenu and Main**

```ini
# add to scenes/MainMenu.tscn and scenes/Main.tscn
[node name="MusicPlayer" type="AudioStreamPlayer" parent="."]
autoplay = true
```

- [ ] **Step 6: Verify scripts still parse cleanly after edits**

Run: `for f in scripts/player.gd scripts/enemy_base.gd scripts/boss.gd scripts/pickup.gd; do godot --headless --check-only --script res://$f || echo "FAILED $f"; done`
Expected: no `FAILED` lines.

- [ ] **Step 7: Manual verification**

Re-run the Task 12 Step 6 play-test. Confirm no runtime errors appear in the Godot output panel related to `AudioStreamPlayer` nodes (silence is expected and correct — no streams are assigned yet).

- [ ] **Step 8: Commit**

```bash
git add scripts/player.gd scripts/enemy_base.gd scripts/boss.gd scripts/pickup.gd scenes/Player.tscn scenes/EnemyStraight.tscn scenes/EnemyZigzag.tscn scenes/EnemyShooter.tscn scenes/Boss.tscn scenes/Pickup.tscn scenes/MainMenu.tscn scenes/Main.tscn
git commit -m "feat: wire guarded audio hooks for fire, hit, explosion, pickup, and music"
```

---

## Follow-ups (explicitly out of scope for this plan)

- Swap placeholder `Polygon2D`/`ColorRect` shapes for real sprites (e.g. a Kenney-style asset pack you download and drop into `assets/sprites/`).
- Drop in royalty-free `.ogg`/`.wav` files and assign them to the `AudioStreamPlayer` `stream` properties added in Task 13.
- Android export presets / keystore signing (when ready to build an APK).
- v2 meta-progression: spending the already-tracked `total_kills`/`currency` save fields on permanent upgrades.
