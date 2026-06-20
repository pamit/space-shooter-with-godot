# scripts/enemy_straight.gd
extends "res://scripts/enemy_base.gd"

func _physics_process(delta: float) -> void:
	position.y += _speed * delta
	super._physics_process(delta)
