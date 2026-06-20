# scripts/bullet.gd
extends Area2D

@export var speed: float = 600.0
@export var damage: float = 10.0
var direction: Vector2 = Vector2.UP

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	if position.y < -50 or position.y > GameConstants.VIEWPORT_H + 50:
		queue_free()
