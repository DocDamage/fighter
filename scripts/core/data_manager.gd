extends Node
## Loads and caches JSON data files.

var _cache := {}

func _ready() -> void:
	preload_manifests()

func preload_manifests() -> void:
	load_json("res://data/audio/sfx_map.json")
	load_json("res://data/audio/music_map.json")
	load_json("res://data/stages/stage_manifest.json")
	load_json("res://data/fighters/fighter_manifest.json")

func load_json(path: String) -> Dictionary:
	if _cache.has(path):
		return _cache[path]
	if not FileAccess.file_exists(path):
		push_error("DataManager: missing JSON: " + path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var result = JSON.parse_string(text)
	if result == null or not result is Dictionary:
		push_error("DataManager: failed to parse JSON: " + path)
		return {}
	_cache[path] = result
	return result

func get_sfx_path(event_id: String) -> String:
	var map = _cache.get("res://data/audio/sfx_map.json", {})
	return map.get(event_id, "")

func get_music_path(screen_id: String) -> String:
	var map = _cache.get("res://data/audio/music_map.json", {})
	return map.get(screen_id, "")

func get_stage_data(stage_id: String) -> Dictionary:
	var manifest = _cache.get("res://data/stages/stage_manifest.json", {})
	var entry = manifest.get(stage_id, {})
	if entry.is_empty():
		return {}
	var data_path: String = entry.get("data_file", "")
	if data_path.is_empty():
		return entry
	return load_json(data_path)

func get_fighter_data(fighter_id: String) -> Dictionary:
	var manifest = _cache.get("res://data/fighters/fighter_manifest.json", {})
	var entry = manifest.get(fighter_id, {})
	if entry.is_empty():
		return {}
	var data_path: String = entry.get("data_file", "")
	if data_path.is_empty():
		return entry
	return load_json(data_path)

func get_move_data(move_id: String) -> Dictionary:
	var path: String = "res://data/moves/%s.json" % move_id
	return load_json(path)

func clear_cache() -> void:
	_cache.clear()
