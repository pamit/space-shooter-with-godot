# scripts/boss.gd
extends Area2D

signal died

@export var enemy_bullet_scene: PackedScene
var hp: float = 100.0
var _bullet_count: int = 3
var _fire_interval: float = 1.5
var _fire_timer: float = 1.5
var _move_dir: float = 1.0

@onready var explosion_sfx: AudioStreamPlayer2D = $ExplosionSFX

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
		var angle: float = lerp(-spread_angle, spread_angle, t) + PI / 2.0
		var bullet = enemy_bullet_scene.instantiate()
		bullet.direction = Vector2.RIGHT.rotated(angle)
		get_parent().add_child(bullet)
		bullet.global_position = global_position + Vector2(0, 30)

func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		died.emit()
		GameManager.add_kill()
		if explosion_sfx.stream != null:
			explosion_sfx.play()
			await get_tree().create_timer(0.3).timeout
		queue_free()

func _on_area_entered(area: Node) -> void:
	if area.is_in_group("player_bullet"):
		take_damage(area.damage)
		area.queue_free()
