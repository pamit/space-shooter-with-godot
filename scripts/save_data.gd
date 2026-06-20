# scripts/save_data.gd
class_name SaveData
extends RefCounted

static func default_data() -> Dictionary:
	return {"high_score": 0, "total_kills": 0, "currency": 0}

static func load_from(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return default_data()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return default_data()
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return default_data()
	var data := default_data()
	for key in data.keys():
		if parsed.has(key):
			data[key] = parsed[key]
	return data

static func save_to(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))
	file.close()
