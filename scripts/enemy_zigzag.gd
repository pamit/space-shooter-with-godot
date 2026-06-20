# scripts/enemy_zigzag.gd
extends "res://scripts/enemy_base.gd"

var _t: float = 0.0
var _origin_x: float = 0.0
var _initialized: bool = false

func _physics_process(delta: float) -> void:
	if not _initialized:
		_origin_x = position.x
		_initialized = true
	_t += delta
	position.y += _speed * delta
	position.x = _origin_x + sin(_t * 3.0) * 60.0
	super._physics_process(delta)
