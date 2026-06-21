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
var _barrier_active: bool = false

var _base_fire_rate: float = 0.0
var _base_speed_multiplier: float = 0.0
var _weapon_boost_count: int = 0
var _speed_boost_count: int = 0
var _shield_count: int = 0
var _triple_shot_count: int = 0
var _penta_shot_count: int = 0
var _deferred_triple_pending: bool = false
var _deferred_triple_duration: float = 0.0
var _can_fire: bool = true

@onready var fire_sfx: AudioStreamPlayer2D = $FireSFX
@onready var hit_sfx: AudioStreamPlayer2D = $HitSFX
@onready var visual: Sprite2D = $Visual
@onready var shield_halo: Sprite2D = $ShieldHalo

var _halo_spin: float = 0.0

func _ready() -> void:
	add_to_group("player")
	_base_fire_rate = fire_rate
	_base_speed_multiplier = speed_multiplier
	fire_sfx.stream = GameAudio.FIRE
	fire_sfx.volume_db = -14.0
	hit_sfx.stream = GameAudio.HIT
	visual.modulate = Color(1, 1, 1, 1)

func set_can_fire(enabled: bool) -> void:
	_can_fire = enabled

func destroy_ship() -> void:
	set_can_fire(false)
	_dragging = false
	shield_halo.visible = false
	visual.visible = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	var parent := get_parent()
	if parent != null:
		VisualEffects.spawn_explosion(parent, global_position)

func restore_ship() -> void:
	visible = true
	monitoring = true
	monitorable = true
	visual.visible = true
	visual.modulate = Color(1, 1, 1, 1)
	shield_halo.visible = _shield_active
	set_can_fire(true)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_begin_drag(_event_to_world(event.position))
		else:
			_dragging = false
	elif event is InputEventScreenDrag and _dragging:
		_update_drag(_event_to_world(event.position))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_drag(_event_to_world(event.position))
		else:
			_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_update_drag(_event_to_world(event.position))

func _event_to_world(screen_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_pos

func _begin_drag(world_pos: Vector2) -> void:
	_dragging = true
	_drag_offset = global_position - world_pos

func _update_drag(world_pos: Vector2) -> void:
	global_position = world_pos + _drag_offset
	_clamp_to_screen()

func _clamp_to_screen() -> void:
	global_position.x = clamp(global_position.x, 40, GameConstants.VIEWPORT_W - 40)
	global_position.y = clamp(global_position.y, 40, GameConstants.VIEWPORT_H - 40)

func _physics_process(delta: float) -> void:
	if shield_halo.visible:
		_halo_spin += delta * 1.6
		shield_halo.rotation = _halo_spin
	if not _can_fire:
		return
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire()
		_fire_timer = fire_rate

func _fire() -> void:
	if bullet_scene == null:
		return
	if _penta_shot_count > 0:
		_fire_penta_spread()
	elif _triple_shot_count > 0:
		_fire_triple_spread()
	else:
		_spawn_bullet(Vector2.UP)
	if fire_sfx.stream != null:
		fire_sfx.play()

func _fire_penta_spread() -> void:
	var spread: float = GameConstants.PENTA_SHOT_SPREAD
	for i in range(5):
		var t: float = 0.0 if i == 0 else float(i) / 4.0
		var angle: float = lerpf(-spread, spread, t)
		_spawn_bullet(Vector2.UP.rotated(angle))

func _fire_triple_spread() -> void:
	var spread: float = GameConstants.TRIPLE_SHOT_SPREAD
	var angles: Array[float] = [-spread, 0.0, spread]
	for angle in angles:
		_spawn_bullet(Vector2.UP.rotated(angle))

func _spawn_bullet(direction: Vector2) -> void:
	var bullet = bullet_scene.instantiate()
	bullet.direction = direction
	get_parent().add_child(bullet)
	bullet.global_position = global_position + Vector2(0, -60)

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
	shield_halo.visible = true

func remove_shield() -> void:
	_shield_count = max(_shield_count - 1, 0)
	if _shield_count == 0:
		_shield_active = false
		shield_halo.visible = false

func add_barrier() -> void:
	_barrier_active = true

func add_triple_shot() -> void:
	_triple_shot_count += 1

func try_add_triple_shot(duration: float) -> void:
	if _penta_shot_count > 0:
		_deferred_triple_pending = true
		_deferred_triple_duration = max(_deferred_triple_duration, duration)
		return
	_activate_triple_shot(duration)

func _activate_triple_shot(duration: float) -> void:
	add_triple_shot()
	get_tree().create_timer(duration).timeout.connect(remove_triple_shot)

func is_penta_shot_active() -> bool:
	return _penta_shot_count > 0

func remove_triple_shot() -> void:
	_triple_shot_count = max(_triple_shot_count - 1, 0)

func add_penta_shot() -> void:
	_penta_shot_count += 1

func remove_penta_shot() -> void:
	_penta_shot_count = max(_penta_shot_count - 1, 0)
	if _penta_shot_count == 0 and _deferred_triple_pending:
		_deferred_triple_pending = false
		var duration := _deferred_triple_duration
		_deferred_triple_duration = 0.0
		_activate_triple_shot(duration)

func reset_powerups() -> void:
	_weapon_boost_count = 0
	_speed_boost_count = 0
	_shield_count = 0
	_triple_shot_count = 0
	_penta_shot_count = 0
	_deferred_triple_pending = false
	_deferred_triple_duration = 0.0
	_shield_active = false
	_barrier_active = false
	fire_rate = _base_fire_rate
	speed_multiplier = _base_speed_multiplier
	shield_halo.visible = false

func take_damage(amount: float) -> void:
	if _barrier_active:
		_barrier_active = false
		return
	if _shield_active:
		return
	GameManager.damage_player(amount)
	hit.emit(amount)
	GameAudio.play_2d(hit_sfx, GameAudio.HIT)

func _on_area_entered(area: Node) -> void:
	if area.is_in_group("enemy_bullet"):
		take_damage(GameConstants.ENEMY_CONTACT_DAMAGE)
		area.queue_free()
	elif area.is_in_group("enemy"):
		take_damage(GameConstants.ENEMY_CONTACT_DAMAGE)
		if area.has_method("take_damage"):
			area.take_damage(99999.0)
