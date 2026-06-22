# scripts/wave_spawner.gd
extends Node2D

signal wave_cleared(was_boss: bool, boss_position: Vector2)
signal boss_warning
signal boss_spawned

const BOSS_WARNING_DURATION := GameConstants.BOSS_WARNING_DURATION
const PICKUP_POOL := [
	{"kind": "weapon", "weight": 2},
	{"kind": "shield", "weight": 5},
	{"kind": "triple", "weight": 5},
]

const ENEMY_SCENES := {
	"straight": preload("res://scenes/EnemyStraight.tscn"),
	"zigzag": preload("res://scenes/EnemyZigzag.tscn"),
	"shooter": preload("res://scenes/EnemyShooter.tscn"),
}
const BOSS_SCENE := preload("res://scenes/Boss.tscn")
const PICKUP_SCENE := preload("res://scenes/Pickup.tscn")

@export var pickup_drop_chance: float = GameConstants.PICKUP_DROP_CHANCE

var _alive_count: int = 0
var _rng := RandomNumberGenerator.new()
var _spawned: Array = []
var _active_level: int = 1
var _boss_phase: bool = false
var _boss_warning_timer: SceneTreeTimer = null
var _spawn_wave_token: int = 0
var _wave_spawn_complete: bool = false

func _ready() -> void:
	_rng.randomize()

func start_level(level: int) -> void:
	_cancel_boss_warning()
	_spawn_wave_token += 1
	_active_level = level
	_boss_phase = false
	_wave_spawn_complete = false
	clear_all()
	clear_projectiles()
	clear_pickups()
	_spawn_wave(level, _spawn_wave_token)
	_spawn_barrier_loop(_spawn_wave_token)

func _cancel_boss_warning() -> void:
	if _boss_warning_timer != null and is_instance_valid(_boss_warning_timer):
		_boss_warning_timer.timeout.disconnect(_on_boss_warning_finished)
	_boss_warning_timer = null

func clear_all() -> void:
	for node in _spawned:
		if is_instance_valid(node):
			node.queue_free()
	_spawned.clear()
	_alive_count = 0

func _begin_boss_phase() -> void:
	_boss_phase = true
	boss_warning.emit()
	_boss_warning_timer = get_tree().create_timer(BOSS_WARNING_DURATION)
	_boss_warning_timer.timeout.connect(_on_boss_warning_finished)

func _on_boss_warning_finished() -> void:
	_boss_warning_timer = null
	_spawn_boss(_active_level)
	boss_spawned.emit()

func _spawn_wave(level: int, token: int) -> void:
	var wave := WavePool.pick_wave(level, _rng)
	_alive_count = 0
	var row_index := 0
	var wave_index := 0
	while wave_index < wave.size():
		if token != _spawn_wave_token:
			return
		var row_size: int = mini(GameConstants.ENEMIES_PER_ROW, wave.size() - wave_index)
		var row_y: float = -50.0 - row_index * GameConstants.ENEMY_WAVE_VERTICAL_STAGGER
		var row_center: float = _rng.randf_range(220.0, GameConstants.VIEWPORT_W - 220.0)
		for col in range(row_size):
			if token != _spawn_wave_token:
				return
			while _alive_count >= GameConstants.MAX_ON_SCREEN_ENEMIES:
				if token != _spawn_wave_token:
					return
				await get_tree().process_frame
			var type_id: String = wave[wave_index]
			var scene: PackedScene = ENEMY_SCENES.get(type_id)
			if scene == null:
				push_error("WaveSpawner: missing enemy scene for '%s'" % type_id)
				wave_index += 1
				continue
			_alive_count += 1
			var enemy = scene.instantiate()
			var x_offset: float = (col - (row_size - 1) * 0.5) * GameConstants.ROW_HORIZONTAL_SPACING
			var spawn_x: float = clampf(row_center + x_offset, 80.0, GameConstants.VIEWPORT_W - 80.0)
			enemy.global_position = Vector2(spawn_x, row_y)
			add_child(enemy)
			_spawned.append(enemy)
			if enemy.has_method("set_level"):
				enemy.set_level(level)
			_assign_unique_speed(enemy)
			enemy.died.connect(_on_enemy_died.bind(enemy))
			wave_index += 1
		row_index += 1
		if wave_index < wave.size() and GameConstants.ENEMY_SPAWN_DELAY > 0.0:
			await get_tree().create_timer(GameConstants.ENEMY_SPAWN_DELAY).timeout
	if token != _spawn_wave_token:
		return
	_wave_spawn_complete = true
	if _alive_count <= 0:
		_begin_boss_phase()

func _spawn_boss(level: int) -> void:
	_alive_count = 1
	var boss = BOSS_SCENE.instantiate()
	add_child(boss)
	_spawned.append(boss)
	boss.global_position = Vector2(GameConstants.VIEWPORT_W / 2.0, GameConstants.BOSS_ENTER_START_Y)
	if boss.has_method("set_level"):
		boss.set_level(level)
	boss.died.connect(_on_enemy_died.bind(boss))

func _on_enemy_died(enemy: Node) -> void:
	var drop_position: Vector2 = enemy.global_position if is_instance_valid(enemy) else Vector2.ZERO
	var is_boss_kill: bool = enemy.is_in_group("boss")
	_alive_count -= 1
	if not is_boss_kill and _rng.randf() < pickup_drop_chance:
		_drop_pickup.call_deferred(drop_position)
	if _alive_count > 0:
		return
	if is_boss_kill:
		wave_cleared.emit(true, drop_position)
	elif not _boss_phase and _wave_spawn_complete:
		_begin_boss_phase()

func _drop_pickup(drop_position: Vector2) -> void:
	var pickup = PICKUP_SCENE.instantiate()
	pickup.kind = _pick_random_pickup_kind()
	add_child(pickup)
	pickup.global_position = drop_position

func _spawn_barrier_loop(token: int) -> void:
	while token == _spawn_wave_token and is_inside_tree():
		var wait: float = _rng.randf_range(
			GameConstants.BARRIER_SPAWN_INTERVAL_MIN,
			GameConstants.BARRIER_SPAWN_INTERVAL_MAX
		)
		await get_tree().create_timer(wait).timeout
		if token != _spawn_wave_token:
			return
		if _count_barriers() >= GameConstants.BARRIER_MAX_ON_SCREEN:
			continue
		_spawn_barrier()

func _spawn_barrier() -> void:
	var pickup = PICKUP_SCENE.instantiate()
	pickup.kind = "barrier"
	pickup.fall_speed = _rng.randf_range(
		GameConstants.BARRIER_FALL_SPEED_MIN,
		GameConstants.BARRIER_FALL_SPEED_MAX
	)
	add_child(pickup)
	pickup.global_position = Vector2(
		_rng.randf_range(80.0, GameConstants.VIEWPORT_W - 80.0),
		-50.0
	)
	_spawned.append(pickup)

func _count_barriers() -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group("barrier_pickup"):
		if is_instance_valid(node):
			count += 1
	return count

func _pick_random_pickup_kind() -> String:
	var total_weight := 0
	for entry in PICKUP_POOL:
		total_weight += entry["weight"]
	var roll := _rng.randi_range(0, total_weight - 1)
	var cumulative := 0
	for entry in PICKUP_POOL:
		cumulative += entry["weight"]
		if roll < cumulative:
			return entry["kind"]
	return PICKUP_POOL[0]["kind"]

func _assign_unique_speed(enemy: Node) -> void:
	if not enemy.has_method("set_move_speed") or not enemy.has_method("get_move_speed"):
		return
	var base_speed: float = enemy.get_move_speed()
	for _attempt in range(32):
		var speed: float = base_speed * _rng.randf_range(
			GameConstants.ENEMY_SPEED_VARIANCE_MIN,
			GameConstants.ENEMY_SPEED_VARIANCE_MAX
		)
		speed = snappedf(speed, 0.05)
		if not _overlapping_enemy_has_speed(enemy, speed):
			enemy.set_move_speed(speed)
			return
	enemy.set_move_speed(
		base_speed * _rng.randf_range(
			GameConstants.ENEMY_SPEED_VARIANCE_MIN,
			GameConstants.ENEMY_SPEED_VARIANCE_MAX
		)
	)

func _overlapping_enemy_has_speed(enemy: Node, speed: float) -> bool:
	for other in get_tree().get_nodes_in_group("enemy"):
		if other == enemy or not is_instance_valid(other) or other.is_in_group("boss"):
			continue
		if not _enemies_overlap(enemy, other):
			continue
		if not other.has_method("get_move_speed"):
			continue
		if abs(other.get_move_speed() - speed) < GameConstants.ENEMY_SPEED_EQUALITY_EPSILON:
			return true
	return false

func _enemies_overlap(a: Node2D, b: Node2D) -> bool:
	var radius_a := _enemy_radius(a)
	var radius_b := _enemy_radius(b)
	return a.global_position.distance_squared_to(b.global_position) < pow(radius_a + radius_b, 2)

func _enemy_radius(node: Node2D) -> float:
	var shape := node.get_node_or_null("Shape") as CollisionShape2D
	if shape == null or shape.shape == null:
		return 40.0
	var rect := shape.shape.get_rect()
	var scale := shape.global_transform.get_scale()
	return maxf(rect.size.x * scale.x, rect.size.y * scale.y) * 0.5

func clear_projectiles() -> void:
	for node in get_tree().get_nodes_in_group("player_bullet"):
		if is_instance_valid(node):
			node.queue_free()
	for node in get_tree().get_nodes_in_group("enemy_bullet"):
		if is_instance_valid(node):
			node.queue_free()

func clear_pickups() -> void:
	for node in get_tree().get_nodes_in_group("pickup"):
		if is_instance_valid(node):
			node.queue_free()

func get_spawned_count() -> int:
	return _spawned.size()

func get_visible_enemy_count() -> int:
	return _visible_enemy_count()

func _visible_enemy_count() -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(node) or node.is_in_group("boss"):
			continue
		var y: float = node.global_position.y
		if y >= 0.0 and y <= GameConstants.VIEWPORT_H:
			count += 1
	return count

func is_boss_phase() -> bool:
	return _boss_phase
