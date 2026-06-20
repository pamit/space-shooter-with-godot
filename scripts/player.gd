# scripts/player.gd
extends Area2D

signal hit(amount: float)

@export var fire_rate: float = 0.25
@export var bullet_scene: PackedScene
@export var speed_multiplier: float = 1.0

var _fire_timer: float = 0.0
var _drag_offset: Vector2 = Vector2.ZERO
var _dragging: bool = false
var _shield_active: bool = false

func _ready() -> void:
	add_to_group("player")
	GameManager.start_run()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if get_rect_global().has_point(event.position) or true:
				_dragging = true
				_drag_offset = global_position - event.position
		else:
			_dragging = false
	elif event is InputEventScreenDrag and _dragging:
		global_position = event.position + _drag_offset
		_clamp_to_screen()

func get_rect_global() -> Rect2:
	return Rect2(global_position - Vector2(40, 40), Vector2(80, 80))

func _clamp_to_screen() -> void:
	global_position.x = clamp(global_position.x, 30, GameConstants.VIEWPORT_W - 30)
	global_position.y = clamp(global_position.y, 30, GameConstants.VIEWPORT_H - 30)

func _physics_process(delta: float) -> void:
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire()
		_fire_timer = fire_rate

func _fire() -> void:
	if bullet_scene == null:
		return
	var bullet = bullet_scene.instantiate()
	bullet.direction = Vector2.UP
	get_parent().add_child(bullet)
	bullet.global_position = global_position + Vector2(0, -30)

func apply_shield(active: bool) -> void:
	_shield_active = active

func take_damage(amount: float) -> void:
	if _shield_active:
		return
	GameManager.damage_player(amount)
	hit.emit(amount)

func _on_area_entered(area: Node) -> void:
	if area.is_in_group("enemy_bullet") or area.is_in_group("enemy"):
		take_damage(20.0)
		if area.has_method("queue_free"):
			area.queue_free()
