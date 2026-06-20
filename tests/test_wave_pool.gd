# tests/test_wave_pool.gd
extends SceneTree

const WavePool = preload("res://scripts/wave_pool.gd")
const Difficulty = preload("res://scripts/difficulty.gd")

var failures := 0

func check(name: String, cond: bool) -> void:
	if not cond:
		failures += 1
		print("FAIL %s" % name)

func _initialize() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234

	var valid_ids := WavePool.enemy_type_ids()
	check("type_ids has 3 entries", valid_ids.size() == 3)

	var wave := WavePool.pick_wave(3, rng)
	check("wave length matches difficulty", wave.size() == Difficulty.enemy_count_for_level(3))
	var all_valid := true
	for id in wave:
		if not valid_ids.has(id):
			all_valid = false
	check("all entries are valid type ids", all_valid)

	# Same seed -> same sequence (determinism)
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 1234
	var wave2 := WavePool.pick_wave(3, rng2)
	check("same seed produces same wave", wave == wave2)

	if failures == 0:
		print("ALL PASS")
	else:
		print("%d FAILURES" % failures)
	quit(1 if failures > 0 else 0)
