# scripts/hit_spark.gd
extends Node2D

@onready var particles: CPUParticles2D = $Particles

func setup(tint: Color) -> void:
	if is_node_ready():
		_apply_tint(tint)
	else:
		_pending_tint = tint

var _pending_tint: Color = Color.WHITE

func _apply_tint(tint: Color) -> void:
	if particles != null:
		particles.color = tint

func _ready() -> void:
	if _pending_tint != Color.WHITE:
		_apply_tint(_pending_tint)
	particles.emitting = true
	await get_tree().create_timer(particles.lifetime + 0.05).timeout
	queue_free()
