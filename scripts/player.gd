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

var _base_fire_rate: float = 0.0
var _base_speed_multiplier: float = 0.0
var _weapon_boost_count: int = 0
var _speed_boost_count: int = 0
var _shield_count: int = 0

@onready var fire_sfx: AudioStreamPlayer2D = $FireSFX
@onready var hit_sfx: AudioStreamPlayer2D = $HitSFX

func _ready() -> void:
	add_to_group("player")
	GameManager.start_run()
	_base_fire_rate = fire_rate
	_base_speed_multiplier = speed_multiplier

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_dragging = true
			_drag_offset = global_position - event.position
		else:
			_dragging = false
	elif event is InputEventScreenDrag and _dragging:
		global_position = event.position + _drag_offset
		_clamp_to_screen()

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
	if fire_sfx.stream != null:
		fire_sfx.play()

func add_weapon_boost() -> void:
	_weapon_boost_count += 1
	fire_rate = _base_fire_rate / GameConstants.WEAPON_BOOST_DIVISOR

func remove_weapon_boost() -> void:
	_weapon_boost_count = max(_weapon_boost_count - 1, 0)
	if _weapon_boost_count == 0:
		fire_rate = _base_fire_rate

func add_speed_boost() -> void:
	_speed_boost_count += 1
	speed_multiplier = GameConstants.SPEED_BOOST_MULTIPLIER

func remove_speed_boost() -> void:
	_speed_boost_count = max(_speed_boost_count - 1, 0)
	if _speed_boost_count == 0:
		speed_multiplier = _base_speed_multiplier

func add_shield() -> void:
	_shield_count += 1
	_shield_active = true

func remove_shield() -> void:
	_shield_count = max(_shield_count - 1, 0)
	if _shield_count == 0:
		_shield_active = false

func take_damage(amount: float) -> void:
	if _shield_active:
		return
	GameManager.damage_player(amount)
	hit.emit(amount)
	if hit_sfx.stream != null:
		hit_sfx.play()

func _on_area_entered(area: Node) -> void:
	if area.is_in_group("enemy_bullet"):
		take_damage(GameConstants.ENEMY_CONTACT_DAMAGE)
		area.queue_free()
	elif area.is_in_group("enemy"):
		take_damage(GameConstants.ENEMY_CONTACT_DAMAGE)
		if area.has_method("take_damage"):
			area.take_damage(99999.0)
