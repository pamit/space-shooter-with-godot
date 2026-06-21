# scripts/enemy_health_bar.gd
extends Node2D

var max_hp: float = 1.0
var hp: float = 1.0
var bar_width: float = 52.0
var bar_height: float = 4.0

func setup(max_value: float, current: float, width: float, height: float) -> void:
	max_hp = max_value
	hp = current
	bar_width = width
	bar_height = height
	queue_redraw()

func update_hp(value: float) -> void:
	hp = value
	queue_redraw()

func _draw() -> void:
	var ratio: float = clampf(hp / max_hp, 0.0, 1.0)
	var origin := Vector2(-bar_width * 0.5, 0.0)
	draw_rect(Rect2(origin, Vector2(bar_width, bar_height)), Color(0.12, 0.02, 0.02, 0.9))
	draw_rect(Rect2(origin, Vector2(bar_width * ratio, bar_height)), Color(0.95, 0.12, 0.08, 1.0))
	if ratio > 0.02:
		draw_rect(
			Rect2(origin, Vector2(bar_width * ratio, maxf(1.0, bar_height * 0.35))),
			Color(1.0, 0.55, 0.25, 0.55)
		)
