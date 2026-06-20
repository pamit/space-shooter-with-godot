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
