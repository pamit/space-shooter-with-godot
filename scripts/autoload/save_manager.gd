# scripts/autoload/save_manager.gd
extends Node

const SAVE_PATH := "user://savegame.json"

var _data: Dictionary = {}

func _ready() -> void:
	_data = SaveData.load_from(SAVE_PATH)

func get_high_score() -> int:
	return _data.get("high_score", 0)

func report_run_result(score: int, kills: int) -> void:
	if score > _data.get("high_score", 0):
		_data["high_score"] = score
	_data["total_kills"] = _data.get("total_kills", 0) + kills
	SaveData.save_to(SAVE_PATH, _data)
