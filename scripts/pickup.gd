# scripts/pickup.gd
extends Area2D

const METEORITE_TEXTURE := preload("res://assets/sprites/meteorite.png")

const PICKUP_TEXTURES := {
	"weapon": preload("res://assets/sprites/kenney/PNG/Power-ups/powerupYellow_bolt.png"),
	"shield": preload("res://assets/sprites/kenney/PNG/Power-ups/powerupBlue_shield.png"),
	"triple": preload("res://assets/sprites/kenney/PNG/Power-ups/powerupBlue_star.png"),
}

@export var kind: String = "weapon"
@export var fall_speed: float = 120.0

var _hits_remaining: int = 1
var _spin_speed: float = 0.0

@onready var pickup_sfx: AudioStreamPlayer2D = $PickupSFX
@onready var visual: Sprite2D = $Visual

func _ready() -> void:
	add_to_group("pickup")
	pickup_sfx.stream = GameAudio.PICKUP
	if kind == "barrier":
		add_to_group("barrier_pickup")
		_hits_remaining = GameConstants.BARRIER_HITS_TO_DESTROY
		_spin_speed = randf_range(
			GameConstants.BARRIER_ROTATION_SPEED_MIN,
			GameConstants.BARRIER_ROTATION_SPEED_MAX
		)
		if fall_speed <= 0.0:
			fall_speed = randf_range(
				GameConstants.BARRIER_FALL_SPEED_MIN,
				GameConstants.BARRIER_FALL_SPEED_MAX
			)
		visual.texture = METEORITE_TEXTURE
		var meteorite_scale: float = GameConstants.BARRIER_METEORITE_SCALE * randf_range(0.92, 1.08)
		visual.scale = Vector2(meteorite_scale, meteorite_scale)
		visual.rotation = randf_range(0.0, TAU)
	elif PICKUP_TEXTURES.has(kind):
		visual.texture = PICKUP_TEXTURES[kind]
		visual.scale = Vector2(GameConstants.PICKUP_SCALE, GameConstants.PICKUP_SCALE)

func _physics_process(delta: float) -> void:
	if kind == "barrier":
		visual.rotation += _spin_speed * delta
	position.y += fall_speed * delta
	if position.y > GameConstants.VIEWPORT_H + 50:
		queue_free()

func _on_area_entered(area: Node) -> void:
	if kind == "barrier":
		if area.is_in_group("player_bullet"):
			area.queue_free()
			_hit_barrier()
			return
		if area.is_in_group("player"):
			_destroy_barrier()
			if area.has_method("take_damage"):
				area.take_damage(GameConstants.ENEMY_CONTACT_DAMAGE)
			return
	if area.is_in_group("player_bullet"):
		return
	if not area.is_in_group("player"):
		return
	match kind:
		"weapon":
			_apply_weapon_boost(area)
		"shield":
			_apply_shield(area)
		"triple":
			_apply_triple_shot(area)
	GameAudio.play_2d(pickup_sfx, GameAudio.PICKUP)
	await get_tree().create_timer(0.2).timeout
	queue_free()

func _hit_barrier() -> void:
	_hits_remaining -= 1
	if _hits_remaining <= 0:
		_destroy_barrier()
	else:
		VisualEffects.spawn_hit_glow(
			get_parent(),
			global_position,
			VisualEffects.HIT_GLOW_ENEMY,
			GameConstants.HIT_GLOW_DURATION * 0.6
		)

func _destroy_barrier() -> void:
	VisualEffects.spawn_explosion(get_parent(), global_position)
	queue_free()

func _apply_weapon_boost(player: Node) -> void:
	player.add_weapon_boost()
	get_tree().create_timer(GameConstants.WEAPON_PICKUP_DURATION).timeout.connect(
		func(): player.remove_weapon_boost()
	)

func _apply_shield(player: Node) -> void:
	player.add_shield()
	get_tree().create_timer(GameConstants.SHIELD_PICKUP_DURATION).timeout.connect(
		func(): player.remove_shield()
	)

func _apply_triple_shot(player: Node) -> void:
	if player.has_method("try_add_triple_shot"):
		player.try_add_triple_shot(GameConstants.TRIPLE_PICKUP_DURATION)
	else:
		player.add_triple_shot()
		get_tree().create_timer(GameConstants.TRIPLE_PICKUP_DURATION).timeout.connect(
			func(): player.remove_triple_shot()
		)
