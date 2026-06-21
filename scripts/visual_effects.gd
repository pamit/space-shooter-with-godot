# scripts/visual_effects.gd
class_name VisualEffects
extends RefCounted

const EXPLOSION_SCENE := preload("res://scenes/effects/Explosion.tscn")
const BOMB_EXPLOSION_SCENE := preload("res://scenes/effects/BombExplosion.tscn")
const HIT_SPARK_SCENE := preload("res://scenes/effects/HitSpark.tscn")
const HIT_GLOW_SCENE := preload("res://scenes/effects/HitGlow.tscn")

const HIT_SPARK_ENEMY := Color(1.0, 0.85, 0.35, 1.0)
const HIT_SPARK_PLAYER := Color(1.0, 0.45, 0.35, 1.0)
const HIT_SPARK_BOSS := Color(1.0, 0.55, 0.25, 1.0)
const HIT_GLOW_ENEMY := Color(0.55, 0.85, 1.0, 1.0)
const HIT_GLOW_PLAYER := Color(1.0, 0.55, 0.45, 1.0)
const HIT_GLOW_BOSS := Color(1.0, 0.65, 0.35, 1.0)
const HIT_GLOW_ROCKET := Color(1.0, 0.85, 0.45, 1.0)

static func spawn_explosion(parent: Node, global_pos: Vector2) -> void:
	if parent == null:
		return
	var explosion: Node2D = EXPLOSION_SCENE.instantiate()
	parent.add_child(explosion)
	explosion.global_position = global_pos

static func spawn_boss_bombing(parent: Node, global_pos: Vector2) -> void:
	if parent == null:
		return
	var bombing: Node2D = BOMB_EXPLOSION_SCENE.instantiate()
	parent.add_child(bombing)
	bombing.global_position = global_pos

static func spawn_hit_spark(parent: Node, global_pos: Vector2, tint: Color = HIT_SPARK_ENEMY) -> void:
	if parent == null:
		return
	var spark: Node2D = HIT_SPARK_SCENE.instantiate()
	if spark.has_method("setup"):
		spark.setup(tint)
	parent.add_child(spark)
	spark.global_position = global_pos

static func spawn_hit_glow(
	parent: Node,
	global_pos: Vector2,
	tint: Color = HIT_GLOW_ENEMY,
	duration: float = GameConstants.HIT_GLOW_DURATION
) -> Node2D:
	if parent == null:
		return null
	var glow: Node2D = HIT_GLOW_SCENE.instantiate()
	parent.add_child(glow)
	glow.global_position = global_pos
	if glow.has_method("setup"):
		glow.setup(tint, duration)
	return glow

static func spawn_rocket_impact(parent: Node, global_pos: Vector2) -> void:
	spawn_hit_glow(parent, global_pos, HIT_GLOW_ROCKET, GameConstants.HIT_GLOW_DURATION)
	spawn_hit_spark(parent, global_pos, HIT_GLOW_ROCKET)

static func flash_sprite(sprite: Sprite2D, duration: float = 0.12) -> void:
	if sprite == null or not is_instance_valid(sprite):
		return
	var original: Color = sprite.modulate
	sprite.modulate = Color(2.5, 2.5, 2.5, 1.0)
	var tween: Tween = sprite.create_tween()
	tween.tween_property(sprite, "modulate", original, duration)
