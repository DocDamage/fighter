extends Control
## Character select screen. P1 and P2 pick fighters, then launch training.

const VS_SCENE := "res://scenes/title/VSScreen.tscn"
const STAGE_SELECT_SCENE := "res://scenes/title/StageSelect.tscn"

@onready var _p1_cursor: ColorRect = $P1Cursor
@onready var _p2_cursor: ColorRect = $P2Cursor
@onready var _p1_name: Label = $P1Name
@onready var _p2_name: Label = $P2Name
@onready var _vs_label: Label = $VSLabel
@onready var _ready_label: Label = $ReadyLabel
@onready var _grid: GridContainer = $GridContainer

var _fighter_ids: Array[String] = []
var _fighter_names: Array[String] = []
var _fighter_locked: Array[bool] = []

var _p1_idx := 0
var _p2_idx := 1
var _p1_confirmed := false
var _p2_confirmed := false
var _can_input := true

func _ready() -> void:
	AudioManager.play_music("character_select")
	_load_fighters_from_manifest()
	_p1_idx = 0
	_p2_idx = mini(1, _fighter_ids.size() - 1)
	_build_grid()
	_update_display()

func _load_fighters_from_manifest() -> void:
	var manifest := DataManager.load_json("res://data/fighters/fighter_manifest.json")
	_fighter_ids.clear()
	_fighter_names.clear()
	_fighter_locked.clear()
	for fid in manifest.keys():
		var entry: Dictionary = manifest[fid]
		_fighter_ids.append(fid)
		_fighter_names.append(entry.get("display_name", fid.to_upper()))
		# Locked if frame map does not exist
		var fdata := DataManager.get_fighter_data(fid)
		var source: String = fdata.get("sprite_source", "")
		var pattern: String = fdata.get("frame_name_pattern", "{fighter_id}_{idx:04d}.png")
		var fname: String = pattern.replace("{fighter_id}", fid).replace("{idx:04d}", "0000").replace("{idx}", "0")
		var frame_map_path: String = source.path_join(fid + "_frame_map.json")
		var is_locked := not FileAccess.file_exists(frame_map_path)
		_fighter_locked.append(is_locked)

func _build_grid() -> void:
	# Clear existing
	for child in _grid.get_children():
		child.queue_free()
	
	for i in range(_fighter_ids.size()):
		var box := ColorRect.new()
		box.custom_minimum_size = Vector2(64, 64)
		box.color = Color(0.15, 0.15, 0.2, 1.0)
		box.name = "FighterBox_%d" % i

		var lbl := Label.new()
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 8)
		lbl.text = _fighter_names[i]
		if _fighter_locked[i]:
			lbl.modulate = Color.GRAY
			lbl.text += "\n[LOCKED]"
		lbl.anchors_preset = Control.PRESET_FULL_RECT
		box.add_child(lbl)

		_grid.add_child(box)

func _process(_delta: float) -> void:
	if not _can_input:
		return
	
	if _fighter_ids.is_empty():
		return

	# P1 navigation (A/D or Left/Right)
	var p1_prev := _p1_idx
	if not _p1_confirmed:
		if Input.is_action_just_pressed("p0_left") or Input.is_action_just_pressed("ui_left"):
			_p1_idx = wrapi(_p1_idx - 1, 0, _fighter_ids.size())
		elif Input.is_action_just_pressed("p0_right") or Input.is_action_just_pressed("ui_right"):
			_p1_idx = wrapi(_p1_idx + 1, 0, _fighter_ids.size())
		elif Input.is_action_just_pressed("p0_lp"):
			if not _fighter_locked[_p1_idx]:
				_p1_confirmed = true
				AudioManager.play_sfx("cursor_select")
			else:
				AudioManager.play_sfx("cursor_move")
		elif Input.is_action_just_pressed("p0_mk") and _p1_confirmed:
			_p1_confirmed = false
			AudioManager.play_sfx("cursor_move")

	if _p1_idx != p1_prev and not _p1_confirmed:
		AudioManager.play_sfx("cursor_move")

	# P2 navigation (arrow keys + numpad)
	var p2_prev := _p2_idx
	if not _p2_confirmed:
		if Input.is_action_just_pressed("p1_left"):
			_p2_idx = wrapi(_p2_idx - 1, 0, _fighter_ids.size())
		elif Input.is_action_just_pressed("p1_right"):
			_p2_idx = wrapi(_p2_idx + 1, 0, _fighter_ids.size())
		elif Input.is_action_just_pressed("p1_lp"):
			if not _fighter_locked[_p2_idx]:
				_p2_confirmed = true
				AudioManager.play_sfx("cursor_select")
			else:
				AudioManager.play_sfx("cursor_move")
		elif Input.is_action_just_pressed("p1_mk") and _p2_confirmed:
			_p2_confirmed = false
			AudioManager.play_sfx("cursor_move")

	if _p2_idx != p2_prev and not _p2_confirmed:
		AudioManager.play_sfx("cursor_move")

	_update_display()

	# Start fight when both confirmed
	if _p1_confirmed and _p2_confirmed:
		_ready_label.visible = true
		if Input.is_action_just_pressed("p0_hp") or Input.is_action_just_pressed("p1_hp"):
			_start_fight()
	else:
		_ready_label.visible = false

func _update_display() -> void:
	if _fighter_ids.is_empty():
		return
	_p1_name.text = "P1: " + _fighter_names[_p1_idx] + (" ✓" if _p1_confirmed else "")
	_p2_name.text = "P2: " + _fighter_names[_p2_idx] + (" ✓" if _p2_confirmed else "")

	# Update cursor positions
	if _p1_idx < _grid.get_child_count():
		var box1: Control = _grid.get_child(_p1_idx)
		_p1_cursor.position = box1.global_position - Vector2(4, 4)
		_p1_cursor.size = box1.size + Vector2(8, 8)
		_p1_cursor.color = Color.RED if not _p1_confirmed else Color.DARK_RED

	if _p2_idx < _grid.get_child_count():
		var box2: Control = _grid.get_child(_p2_idx)
		_p2_cursor.position = box2.global_position - Vector2(2, 2)
		_p2_cursor.size = box2.size + Vector2(4, 4)
		_p2_cursor.color = Color.BLUE if not _p2_confirmed else Color.DARK_BLUE

func _start_fight() -> void:
	_can_input = false
	
	# If StageSelect scene exists, go there first; otherwise fall back to random stage + VS
	if ResourceLoader.exists(STAGE_SELECT_SCENE):
		var stage_select = load(STAGE_SELECT_SCENE).instantiate()
		stage_select.p1_fighter = _fighter_ids[_p1_idx]
		stage_select.p2_fighter = _fighter_ids[_p2_idx]
		get_tree().root.add_child(stage_select)
		queue_free()
	else:
		var stages: Array[String] = ["tournament_day", "noh_stage", "temple_night"]
		var stage: String = stages[randi() % stages.size()]
		var vs = load(VS_SCENE).instantiate()
		vs.p1_fighter = _fighter_ids[_p1_idx]
		vs.p2_fighter = _fighter_ids[_p2_idx]
		vs.stage_id = stage
		get_tree().root.add_child(vs)
		queue_free()
