# scripts/health_bar_helper.gd
class_name HealthBarHelper
extends RefCounted

const EnemyHealthBar = preload("res://scripts/enemy_health_bar.gd")

static func attach(parent: Node2D, max_hp: float, current_hp: float, width: float, y_offset: float, height: float = 4.0) -> Node2D:
	var bar: Node2D = EnemyHealthBar.new()
	bar.position = Vector2(0.0, y_offset)
	bar.setup(max_hp, current_hp, width, height)
	parent.add_child(bar)
	return bar

static func update(bar: Node2D, hp: float) -> void:
	if bar != null and bar.has_method("update_hp"):
		bar.update_hp(hp)
