# scripts/helper_rocket.gd
extends Area2D

@export var damage: float = GameConstants.HELPER_ROCKET_DAMAGE

var _speed: float = GameConstants.BASE_ENEMY_SPEED

@onready var visual: Sprite2D = $Visual

func _ready() -> void:
	add_to_group("helper_rocket")

func setup(spawn_x: float, spawn_y: float, move_speed: float) -> void:
	global_position = Vector2(spawn_x, spawn_y)
	_speed = move_speed
	rotation = 0.0
	if visual != null:
		visual.rotation = PI

func _physics_process(delta: float) -> void:
	position.y -= _speed * delta
	if global_position.y < -80:
		queue_free()
	elif global_position.x < -80 or global_position.x > GameConstants.VIEWPORT_W + 80:
		queue_free()

func _on_area_entered(area: Node) -> void:
	if not area.is_in_group("enemy") or not area.has_method("take_damage"):
		return
	area.take_damage(99999.0)
	VisualEffects.spawn_rocket_impact(get_parent(), global_position)
	queue_free()
