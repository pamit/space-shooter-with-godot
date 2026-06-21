# scripts/boss.gd
extends Area2D

const HealthBarHelper = preload("res://scripts/health_bar_helper.gd")
const LightningBoltScene = preload("res://scenes/LightningBolt.tscn")

enum AttackPattern { SPREAD_3, SINGLE, SPREAD_5, LIGHTNING }

signal died

@export var enemy_bullet_scene: PackedScene
var hp: float = 100.0
var _max_hp: float = 100.0
var _fire_interval: float = 1.5
var _fire_timer: float = 1.5
var _move_dir: float = 1.0
var _removed: bool = false
var _hp_bar: Node2D = null
var _can_attack: bool = true
var _entering: bool = true
var _patrol_y: float = GameConstants.BOSS_PATROL_Y
var _bob_time: float = 0.0
var _pattern_index: int = 0

const ATTACK_SEQUENCE: Array[int] = [
	AttackPattern.SPREAD_3,
	AttackPattern.SINGLE,
	AttackPattern.SPREAD_5,
	AttackPattern.LIGHTNING,
]

@onready var explosion_sfx: AudioStreamPlayer2D = $ExplosionSFX

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("boss")
	explosion_sfx.stream = GameAudio.EXPLOSION
	_max_hp = hp
	_patrol_y = GameConstants.BOSS_PATROL_Y
	_hp_bar = HealthBarHelper.attach(self, _max_hp, hp, 227.0, -217.0, 6.0)

func set_level(level: int) -> void:
	hp = Difficulty.boss_hp_for_level(level)
	_max_hp = hp
	_fire_interval = Difficulty.boss_fire_interval_for_level(level)
	_fire_timer = _fire_interval
	_entering = true
	_can_attack = true
	_pattern_index = 0
	_bob_time = 0.0
	if _hp_bar != null and _hp_bar.has_method("setup"):
		_hp_bar.setup(_max_hp, hp, 227.0, 6.0)

func get_max_hp() -> float:
	return _max_hp

func get_current_hp() -> float:
	return hp

func set_can_attack(enabled: bool) -> void:
	_can_attack = enabled

func is_hittable() -> bool:
	return GameConstants.is_past_hud_combat_line(global_position.y)

func _physics_process(delta: float) -> void:
	if not _can_attack:
		return
	if _entering:
		position.y += GameConstants.BOSS_ENTER_SPEED * delta
		if position.y >= _patrol_y:
			position.y = _patrol_y
			_entering = false
		return
	_bob_time += delta
	position.y = _patrol_y + sin(_bob_time * GameConstants.BOSS_VERTICAL_BOB_SPEED) * GameConstants.BOSS_VERTICAL_BOB_AMPLITUDE
	position.x += _move_dir * 80.0 * delta
	if position.x < 80 or position.x > GameConstants.VIEWPORT_W - 80:
		_move_dir *= -1.0
	if not is_hittable():
		return
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_execute_attack()
		_fire_timer = _fire_interval

func _execute_attack() -> void:
	match ATTACK_SEQUENCE[_pattern_index]:
		AttackPattern.SPREAD_3:
			_fire_spread(3)
		AttackPattern.SINGLE:
			_fire_spread(1)
		AttackPattern.SPREAD_5:
			_fire_spread(5)
		AttackPattern.LIGHTNING:
			_fire_lightning()
	_pattern_index = (_pattern_index + 1) % ATTACK_SEQUENCE.size()

func _fire_spread(bullet_count: int) -> void:
	if enemy_bullet_scene == null:
		return
	var spread_angle := PI / 4.0
	for i in range(bullet_count):
		var t := 0.0 if bullet_count == 1 else float(i) / float(bullet_count - 1)
		var angle: float = lerp(-spread_angle, spread_angle, t) + PI / 2.0
		var bullet = enemy_bullet_scene.instantiate()
		bullet.direction = Vector2.RIGHT.rotated(angle)
		get_parent().add_child(bullet)
		bullet.global_position = global_position + Vector2(0, 30)

func _fire_lightning() -> void:
	var spread_angle := PI / 3.0
	var count := GameConstants.BOSS_LIGHTNING_COUNT
	for i in range(count):
		var t := 0.0 if count == 1 else float(i) / float(count - 1)
		var angle: float = lerp(-spread_angle, spread_angle, t) + PI / 2.0
		var bolt = LightningBoltScene.instantiate()
		if bolt.has_method("setup"):
			bolt.setup(Vector2.RIGHT.rotated(angle))
		get_parent().add_child(bolt)
		bolt.global_position = global_position + Vector2(0, 40)

func take_damage(amount: float) -> void:
	if _removed or not is_hittable():
		return
	hp -= amount
	HealthBarHelper.update(_hp_bar, hp)
	VisualEffects.spawn_hit_glow(get_parent(), global_position, VisualEffects.HIT_GLOW_BOSS)
	if hp <= 0.0:
		_removed = true
		set_can_attack(false)
		died.emit()
		GameManager.add_kill()
		GameAudio.play_2d(explosion_sfx, GameAudio.EXPLOSION)
		await get_tree().create_timer(0.3).timeout
		queue_free()

func _on_area_entered(area: Node) -> void:
	if area.is_in_group("player_bullet"):
		if not is_hittable():
			area.queue_free()
			return
		take_damage(area.damage)
		area.queue_free()
