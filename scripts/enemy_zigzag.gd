# scripts/enemy_zigzag.gd
extends "res://scripts/enemy_base.gd"

const BASE_VISUAL_ROTATION := PI
const BASE_MODULATE := Color(0.85, 1.0, 0.75, 1.0)

var _t: float = 0.0
var _origin_x: float = 0.0
var _initialized: bool = false

@onready var visual: Sprite2D = $Visual

func _physics_process(delta: float) -> void:
	if not _initialized:
		_origin_x = position.x
		_initialized = true
	_t += delta
	position.y += _speed * delta
	position.x = _origin_x + sin(_t * GameConstants.ZIGZAG_HORIZONTAL_FREQ) * GameConstants.ZIGZAG_HORIZONTAL_AMPLITUDE
	visual.rotation = BASE_VISUAL_ROTATION
	var glow: float = 1.0 + abs(sin(_t * 7.0)) * 0.45
	visual.modulate = Color(
		BASE_MODULATE.r * glow,
		BASE_MODULATE.g * glow,
		BASE_MODULATE.b * glow,
		1.0
	)
	super._physics_process(delta)
