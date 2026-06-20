# scripts/wave_pool.gd
class_name WavePool
extends RefCounted

const Difficulty = preload("res://scripts/difficulty.gd")

static func enemy_type_ids() -> Array:
	return ["straight", "zigzag", "shooter"]

static func pick_wave(level: int, rng: RandomNumberGenerator) -> Array:
	var count := Difficulty.enemy_count_for_level(level)
	var ids := enemy_type_ids()
	var wave: Array = []
	for i in range(count):
		wave.append(ids[rng.randi_range(0, ids.size() - 1)])
	return wave
