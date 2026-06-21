# scripts/enemy_bullet.gd
extends Area2D

@export var speed: float = 350.0
@export var damage: float = 20.0
var direction: Vector2 = Vector2.DOWN

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	if position.y < -50 or position.y > GameConstants.VIEWPORT_H + 50:
		queue_free()

func _on_area_entered(area: Node) -> void:
	if area.is_in_group("player") and area.has_method("take_damage"):
		area.take_damage(damage)
		queue_free()
