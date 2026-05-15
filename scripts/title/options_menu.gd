extends Control
## Options menu with volume sliders and toggles.

const CONFIG_PATH := "user://options.cfg"

const MENU_ITEMS := [
	{"label": "MASTER VOLUME", "type": "slider", "key": "master_volume", "default": 1.0},
	{"label": "SFX VOLUME", "type": "slider", "key": "sfx_volume", "default": 1.0},
	{"label": "MUSIC VOLUME", "type": "slider", "key": "music_volume", "default": 1.0},
	{"label": "SHOW INPUT DISPLAY", "type": "toggle", "key": "show_input", "default": true},
	{"label": "SHOW HITBOXES", "type": "toggle", "key": "show_hitboxes", "default": false},
	{"label": "TRAINING MODE DEFAULT", "type": "toggle", "key": "training_default", "default": true},
	{"label": "BACK", "type": "button", "key": "", "default": null},
]

@onready var _menu_container: VBoxContainer = $MenuContainer
@onready var _cursor: Label = $Cursor

var _selected := 0
var _can_input := true
var _config := ConfigFile.new()

func _ready() -> void:
	_load_config()
	_build_menu()
	_update_cursor()
	_can_input = true

func _load_config() -> void:
	var err := _config.load(CONFIG_PATH)
	if err != OK:
		# First run: set defaults
		for item in MENU_ITEMS:
			if item["key"] != "":
				_config.set_value("options", item["key"], item["default"])
		_config.save(CONFIG_PATH)

func _save_config() -> void:
	_config.save(CONFIG_PATH)

func _build_menu() -> void:
	for i in range(MENU_ITEMS.size()):
		var item := MENU_ITEMS[i]
		var row := HBoxContainer.new()
		row.name = "MenuRow_%d" % i
		
		var lbl := Label.new()
		lbl.text = item["label"]
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.custom_minimum_size = Vector2(160, 14)
		row.add_child(lbl)
		
		match item["type"]:
			"slider":
				var val := _config.get_value("options", item["key"], item["default"]) as float
				var val_lbl := Label.new()
				val_lbl.name = "ValueLabel"
				val_lbl.text = "%d%%" % int(val * 100)
				val_lbl.add_theme_font_size_override("font_size", 10)
				val_lbl.custom_minimum_size = Vector2(40, 14)
				row.add_child(val_lbl)
			"toggle":
				var val := _config.get_value("options", item["key"], item["default"]) as bool
				var val_lbl := Label.new()
				val_lbl.name = "ValueLabel"
				val_lbl.text = "ON" if val else "OFF"
				val_lbl.add_theme_font_size_override("font_size", 10)
				val_lbl.custom_minimum_size = Vector2(40, 14)
				row.add_child(val_lbl)
			"button":
				pass
		
		_menu_container.add_child(row)

func _process(_delta: float) -> void:
	if not _can_input:
		return
	
	var prev := _selected
	if Input.is_action_just_pressed("p0_up") or Input.is_action_just_pressed("ui_up"):
		_selected = wrapi(_selected - 1, 0, MENU_ITEMS.size())
	elif Input.is_action_just_pressed("p0_down") or Input.is_action_just_pressed("ui_down"):
		_selected = wrapi(_selected + 1, 0, MENU_ITEMS.size())
	
	if _selected != prev:
		AudioManager.play_sfx("cursor_move")
		_update_cursor()
	
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("p0_lp"):
		AudioManager.play_sfx("cursor_select")
		_select_item()
	elif Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("p0_mk"):
		AudioManager.play_sfx("cursor_move")
		_close_menu()
	
	# Left/right adjusts values
	var item := MENU_ITEMS[_selected]
	if item["type"] == "slider":
		var changed := false
		var current: float = _config.get_value("options", item["key"], item["default"])
		if Input.is_action_just_pressed("p0_left") or Input.is_action_just_pressed("ui_left"):
			current = clampf(current - 0.1, 0.0, 1.0)
			changed = true
		elif Input.is_action_just_pressed("p0_right") or Input.is_action_just_pressed("ui_right"):
			current = clampf(current + 0.1, 0.0, 1.0)
			changed = true
		if changed:
			_config.set_value("options", item["key"], current)
			_save_config()
			_apply_settings()
			_update_value_label(_selected, "%d%%" % int(current * 100))
	elif item["type"] == "toggle":
		if Input.is_action_just_pressed("p0_left") or Input.is_action_just_pressed("ui_left") \
		or Input.is_action_just_pressed("p0_right") or Input.is_action_just_pressed("ui_right") \
		or Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("p0_lp"):
			var current: bool = _config.get_value("options", item["key"], item["default"])
			current = not current
			_config.set_value("options", item["key"], current)
			_save_config()
			_apply_settings()
			_update_value_label(_selected, "ON" if current else "OFF")

func _update_value_label(idx: int, text: String) -> void:
	var row: HBoxContainer = _menu_container.get_child(idx)
	for child in row.get_children():
		if child.name == "ValueLabel":
			child.text = text

func _update_cursor() -> void:
	for i in range(_menu_container.get_child_count()):
		var row: HBoxContainer = _menu_container.get_child(i)
		for child in row.get_children():
			if child is Label:
				if i == _selected:
					child.modulate = Color.YELLOW
				else:
					child.modulate = Color.WHITE
	
	var selected_row: Control = _menu_container.get_child(_selected)
	_cursor.position = Vector2(selected_row.position.x - 14, selected_row.position.y + _menu_container.position.y)

func _select_item() -> void:
	var item := MENU_ITEMS[_selected]
	if item["label"] == "BACK":
		_close_menu()

func _close_menu() -> void:
	_can_input = false
	queue_free()

func _apply_settings() -> void:
	var master: float = _config.get_value("options", "master_volume", 1.0)
	var sfx: float = _config.get_value("options", "sfx_volume", 1.0)
	var music: float = _config.get_value("options", "music_volume", 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master))
	# Assuming SFX and Music are separate buses; if not, this is a no-op
	if AudioServer.get_bus_index("SFX") >= 0:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sfx))
	if AudioServer.get_bus_index("Music") >= 0:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(music))

static func get_option(key: String, default_value = null):
	var cfg := ConfigFile.new()
	var err := cfg.load(CONFIG_PATH)
	if err != OK:
		return default_value
	return cfg.get_value("options", key, default_value)
