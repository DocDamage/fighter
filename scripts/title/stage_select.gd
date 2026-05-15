extends Control

const VS_SCENE := "res://scenes/title/VSScreen.tscn"

@onready var _grid: HBoxContainer = $GridContainer  # horizontal row
@onready var _cursor: ColorRect = $Cursor
@onready var _stage_name: Label = $StageName

var p1_fighter := "ryu"
var p2_fighter := "ken"
var _stage_ids: Array[String] = []
var _stage_names: Array[String] = []
var _selected := 0
var _can_input := true

func _ready() -> void:
	_load_stages()
	_build_grid()
	_update_display()

func _load_stages() -> void:
	var manifest := DataManager.load_json("res://data/stages/stage_manifest.json")
	for sid in manifest.keys():
		var entry: Dictionary = manifest[sid]
		_stage_ids.append(sid)
		_stage_names.append(entry.get("display_name", sid))

func _build_grid() -> void:
	for i in range(_stage_ids.size()):
		var box := ColorRect.new()
		box.custom_minimum_size = Vector2(96, 56)
		box.color = Color(0.1, 0.1, 0.15, 1.0)
		box.name = "StageBox_%d" % i
		
		# Try to load stage background as thumbnail
		var stage_data := DataManager.get_stage_data(_stage_ids[i])
		var bg_path: String = stage_data.get("background", "")
		if not bg_path.is_empty():
			var tex = load(bg_path) as Texture2D
			if tex:
				var tr := TextureRect.new()
				tr.texture = tex
				tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				tr.custom_minimum_size = Vector2(96, 56)
				tr.anchors_preset = Control.PRESET_FULL_RECT
				box.add_child(tr)
		
		_grid.add_child(box)

func _process(_delta: float) -> void:
	if not _can_input or _stage_ids.is_empty():
		return
	
	var prev := _selected
	if Input.is_action_just_pressed("p0_left") or Input.is_action_just_pressed("ui_left"):
		_selected = wrapi(_selected - 1, 0, _stage_ids.size())
	elif Input.is_action_just_pressed("p0_right") or Input.is_action_just_pressed("ui_right"):
		_selected = wrapi(_selected + 1, 0, _stage_ids.size())
	
	if _selected != prev:
		AudioManager.play_sfx("cursor_move")
		_update_display()
	
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("p0_lp"):
		AudioManager.play_sfx("cursor_select")
		_start_vs()

func _update_display() -> void:
	_stage_name.text = _stage_names[_selected]
	var box: Control = _grid.get_child(_selected)
	_cursor.position = box.global_position - Vector2(4, 4)
	_cursor.size = box.size + Vector2(8, 8)

func _start_vs() -> void:
	_can_input = false
	var vs = load(VS_SCENE).instantiate()
	vs.p1_fighter = p1_fighter
	vs.p2_fighter = p2_fighter
	vs.stage_id = _stage_ids[_selected]
	get_tree().root.add_child(vs)
	queue_free()
