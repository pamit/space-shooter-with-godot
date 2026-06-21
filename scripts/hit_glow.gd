# scripts/hit_glow.gd
extends Node2D

func setup(tint: Color, duration: float = GameConstants.HIT_GLOW_DURATION) -> void:
	var outer: Sprite2D = $Outer
	var inner: Sprite2D = $Inner
	var bright := Color(tint.r * 1.2, tint.g * 1.2, tint.b * 1.2, 0.95)
	var core := Color(1.0, 0.98, 0.85, 1.0)
	outer.modulate = bright
	inner.modulate = core
	outer.scale = Vector2(0.35, 0.35)
	inner.scale = Vector2(0.2, 0.2)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(outer, "scale", Vector2(1.8, 1.8), duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(inner, "scale", Vector2(1.1, 1.1), duration * 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(outer, "modulate:a", 0.0, duration)
	tween.tween_property(inner, "modulate:a", 0.0, duration)
	tween.chain().tween_callback(queue_free)
	get_tree().create_timer(duration + 0.05).timeout.connect(
		func() -> void:
			if is_instance_valid(self):
				queue_free()
	)
