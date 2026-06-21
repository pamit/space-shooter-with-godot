# scripts/lightning_bolt.gd
extends Area2D

@export var speed: float = 520.0
var direction: Vector2 = Vector2.DOWN

@onready var visual: Sprite2D = $Visual

func _ready() -> void:
	add_to_group("enemy_bullet")
	rotation = direction.angle() + PI / 2.0

func setup(dir: Vector2) -> void:
	direction = dir.normalized()
	rotation = direction.angle() + PI / 2.0

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	var pulse: float = 1.2 + abs(sin(Time.get_ticks_msec() * 0.02)) * 0.8
	visual.modulate = Color(1.0 * pulse, 0.95 * pulse, 0.35 * pulse, 1.0)
	if position.y > GameConstants.VIEWPORT_H + 80 or position.y < -80:
		queue_free()
	elif position.x < -80 or position.x > GameConstants.VIEWPORT_W + 80:
		queue_free()

func _on_area_entered(area: Node) -> void:
	if area.is_in_group("player"):
		if area.has_method("take_damage"):
			area.take_damage(GameConstants.ENEMY_CONTACT_DAMAGE * 1.5)
		queue_free()
