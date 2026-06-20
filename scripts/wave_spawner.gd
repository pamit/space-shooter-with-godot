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
