# scripts/enemy_base.gd
extends Area2D
class_name EnemyBase

signal died

@export var base_speed: float = 100.0
@export var hp: float = 20.0

var _speed: float = 100.0

@onready var explosion_sfx: AudioStreamPlayer2D = $ExplosionSFX

func _ready() -> void:
	add_to_group("enemy")

func set_level(level: int) -> void:
	_speed = base_speed * Difficulty.enemy_speed_multiplier(level)

func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		died.emit()
		GameManager.add_kill()
		if explosion_sfx.stream != null:
			explosion_sfx.play()
			await get_tree().create_timer(0.3).timeout
		queue_free()

func _physics_process(_delta: float) -> void:
	if position.y > GameConstants.VIEWPORT_H + 60:
		queue_free()

func _on_area_entered(area: Node) -> void:
	if area.is_in_group("player_bullet"):
		take_damage(area.damage)
		area.queue_free()
