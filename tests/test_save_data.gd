# tests/test_save_data.gd
extends SceneTree

const SaveData = preload("res://scripts/save_data.gd")

var failures := 0

func check(name: String, actual, expected) -> void:
	if actual != expected:
		failures += 1
		print("FAIL %s: expected %s, got %s" % [name, expected, actual])

func _initialize() -> void:
	var path := "user://test_savegame.json"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	var missing := SaveData.load_from(path)
	check("missing.high_score", missing.high_score, 0)
	check("missing.total_kills", missing.total_kills, 0)
	check("missing.currency", missing.currency, 0)

	SaveData.save_to(path, {"high_score": 420, "total_kills": 17, "currency": 5})
	var loaded := SaveData.load_from(path)
	check("loaded.high_score", loaded.high_score, 420)
	check("loaded.total_kills", loaded.total_kills, 17)
	check("loaded.currency", loaded.currency, 5)

	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	if failures == 0:
		print("ALL PASS")
	else:
		print("%d FAILURES" % failures)
	quit(1 if failures > 0 else 0)
