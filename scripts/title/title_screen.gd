extends Control
## Title screen with menu navigation.

const MENU_ITEMS := ["ARCADE MODE", "VERSUS MODE", "OPTIONS", "QUIT"]
const CHAR_SELECT_SCENE := "res://scenes/title/CharacterSelect.tscn"
const OPTIONS_SCENE := "res://scenes/title/OptionsMenu.tscn"
const ARCADE_SCENE := "res://scenes/title/ArcadeMode.tscn"

@onready var _bg: TextureRect = $Background
@onready var _menu_container: VBoxContainer = $MenuContainer
@onready var _cursor: Label = $Cursor

var _selected := 0
var _can_input := false

func _ready() -> void:
	# Load a random stage background for visual flair
	var bg_path := "res://assets/stages/SNES - Dragon Ball Z_ Hyper Dimension - Stages - Tournament (Day).png"
	var tex := load(bg_path) as Texture2D
	if tex:
		_bg.texture = tex
		# Darken it
		_bg.modulate = Color(0.4, 0.4, 0.5, 1.0)

	# Build menu labels
	for i in range(MENU_ITEMS.size()):
		var lbl := Label.new()
		lbl.name = "MenuItem_%d" % i
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.text = MENU_ITEMS[i]
		_menu_container.add_child(lbl)

	_update_cursor()
	AudioManager.play_music("title")
	_can_input = true

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

func _update_cursor() -> void:
	for i in range(_menu_container.get_child_count()):
		var lbl: Label = _menu_container.get_child(i)
		if i == _selected:
			lbl.modulate = Color.YELLOW
			_cursor.position = Vector2(lbl.position.x - 14, lbl.position.y + _menu_container.position.y)
		else:
			lbl.modulate = Color.WHITE

func _select_item() -> void:
	_can_input = false
	match _selected:
		0: # Arcade Mode
			await get_tree().create_timer(0.15).timeout
			get_tree().change_scene_to_file(ARCADE_SCENE)
		1: # Versus Mode
			await get_tree().create_timer(0.15).timeout
			get_tree().change_scene_to_file(CHAR_SELECT_SCENE)
		2: # Options
			var opts = load(OPTIONS_SCENE).instantiate()
			get_tree().root.add_child(opts)
			await opts.tree_exited
			_can_input = true
		3: # Quit
			get_tree().quit()
