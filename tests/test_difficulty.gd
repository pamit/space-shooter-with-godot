# tests/test_difficulty.gd
extends SceneTree

const Difficulty = preload("res://scripts/difficulty.gd")

var failures := 0

func check(name: String, actual, expected) -> void:
	if actual != expected:
		failures += 1
		print("FAIL %s: expected %s, got %s" % [name, expected, actual])

func _initialize() -> void:
	check("enemy_count_for_level(1)", Difficulty.enemy_count_for_level(1), 5)
	check("enemy_count_for_level(3)", Difficulty.enemy_count_for_level(3), 9)
	check("enemy_speed_multiplier(1)", Difficulty.enemy_speed_multiplier(1), 1.0)
	check("boss_hp_for_level(1)", Difficulty.boss_hp_for_level(1), 100.0)
	check("is_boss_level(5)", Difficulty.is_boss_level(5), true)
	check("is_boss_level(6)", Difficulty.is_boss_level(6), false)
	check("boss_bullet_count_for_level(1)", Difficulty.boss_bullet_count_for_level(1), 3)
	check("enemy_speed_multiplier(1000) clamps", Difficulty.enemy_speed_multiplier(1000), GameConstants.MAX_SPEED_MULTIPLIER)
	check("boss_fire_interval_for_level(1000) floors", Difficulty.boss_fire_interval_for_level(1000), GameConstants.BOSS_FIRE_INTERVAL_MIN)
	if failures == 0:
		print("ALL PASS")
	else:
		print("%d FAILURES" % failures)
	quit(1 if failures > 0 else 0)
