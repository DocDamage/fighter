extends Node2D

@onready var _label: Label = $Label

var _ready_to_start := false

func _ready() -> void:
	# Ensure audio buses exist
	var sfx_idx := AudioServer.get_bus_index("SFX")
	if sfx_idx < 0:
		AudioServer.add_bus(1)
		AudioServer.set_bus_name(1, "SFX")
	var music_idx := AudioServer.get_bus_index("Music")
	if music_idx < 0:
		AudioServer.add_bus(2)
		AudioServer.set_bus_name(2, "Music")

	# Preload data
	DataManager.preload_manifests()

	# Show loading briefly, then go to title
	_label.text = "Loading..."
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/title/TitleScreen.tscn")
