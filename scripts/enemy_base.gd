# scripts/enemy_base.gd
extends Area2D
class_name EnemyBase

const HealthBarHelper = preload("res://scripts/health_bar_helper.gd")

signal died

@export var base_speed: float = 144.0
@export var hp: float = 20.0

var _speed: float = 120.0
var _removed: bool = false
var _base_hp: float = 0.0
var _max_hp: float = 0.0
var _hp_bar: Node2D = null

@onready var explosion_sfx: AudioStreamPlayer2D = $ExplosionSFX

func _ready() -> void:
	add_to_group("enemy")
	explosion_sfx.stream = GameAudio.EXPLOSION
	_base_hp = hp
	_max_hp = hp
	_hp_bar = HealthBarHelper.attach(self, _max_hp, hp, 81.0, -72.0, 4.0)

func set_level(level: int) -> void:
	_speed = base_speed * Difficulty.enemy_speed_multiplier(level)
	_max_hp = _base_hp * Difficulty.enemy_hp_multiplier(level)
	hp = _max_hp
	if _hp_bar != null and _hp_bar.has_method("setup"):
		_hp_bar.setup(_max_hp, hp, 81.0, 4.0)

func set_move_speed(speed: float) -> void:
	_speed = speed

func get_move_speed() -> float:
	return _speed

func is_hittable() -> bool:
	return GameConstants.is_past_hud_combat_line(global_position.y)

func take_damage(amount: float) -> void:
	if _removed or not is_hittable():
		return
	hp -= amount
	HealthBarHelper.update(_hp_bar, hp)
	VisualEffects.spawn_hit_glow(get_parent(), global_position, VisualEffects.HIT_GLOW_ENEMY)
	if hp <= 0.0:
		_mark_removed()
		died.emit()
		GameManager.add_kill()
		VisualEffects.spawn_explosion(get_parent(), global_position)
		GameAudio.play_2d(explosion_sfx, GameAudio.EXPLOSION)
		await get_tree().create_timer(0.3).timeout
		queue_free()

func _physics_process(_delta: float) -> void:
	if position.y > GameConstants.VIEWPORT_H + 60:
		_despawn_offscreen()

func _despawn_offscreen() -> void:
	if _removed:
		return
	_mark_removed()
	died.emit()
	queue_free()

func _mark_removed() -> void:
	_removed = true

func _on_area_entered(area: Node) -> void:
	if not area.is_in_group("player_bullet"):
		return
	if not is_hittable():
		area.queue_free()
		return
	take_damage(area.damage)
	area.queue_free()
