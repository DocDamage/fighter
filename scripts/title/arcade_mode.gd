extends Control
## Arcade mode ladder manager.

const CHAR_SELECT_SCENE := "res://scenes/title/CharacterSelect.tscn"
const STAGE_SELECT_SCENE := "res://scenes/title/StageSelect.tscn"
const VS_SCENE := "res://scenes/title/VSScreen.tscn"
const FIGHT_SCENE := "res://scenes/fight/FightScene.tscn"

# Ladder: 8 matches with increasing difficulty
const LADDER := [
	{"opponent": "ken", "stage": "tournament_day", "difficulty": 1},
	{"opponent": "guile", "stage": "noh_stage", "difficulty": 2},
	{"opponent": "chun_li", "stage": "temple_night", "difficulty": 3},
	{"opponent": "shin_akuma", "stage": "tournament_day", "difficulty": 4},
	{"opponent": "magician_red", "stage": "noh_stage", "difficulty": 5},
	{"opponent": "ryu", "stage": "temple_night", "difficulty": 6},
	{"opponent": "ken", "stage": "tournament_day", "difficulty": 7},  # Boss 1
	{"opponent": "shin_akuma", "stage": "noh_stage", "difficulty": 8},  # Boss 2
]

var _p1_fighter := "ryu"
var _current_match := 0
var _score := 0
var _total_time := 0.0

func _ready() -> void:
	_start_character_select()

func _start_character_select() -> void:
	var cs = load(CHAR_SELECT_SCENE).instantiate()
	# Override the start to go to our match instead of VS screen
	cs.connect("tree_exited", _on_character_select_done)
	get_tree().root.add_child(cs)

func _on_character_select_done() -> void:
	# Character select finished; P1 fighter is chosen
	# For now, just start the first match
	_start_match()

func _start_match() -> void:
	if _current_match >= LADDER.size():
		_show_ending()
		return
	
	var match_data: Dictionary = LADDER[_current_match]
	var vs = load(VS_SCENE).instantiate()
	vs.p1_fighter = _p1_fighter
	vs.p2_fighter = match_data["opponent"]
	vs.stage_id = match_data["stage"]
	vs.training_mode = false
	vs.connect("tree_exited", _on_vs_done)
	get_tree().root.add_child(vs)

func _on_vs_done() -> void:
	# VS screen finished; fight scene was launched
	# After fight ends, we need to check result
	# For skeleton, just advance to next match
	_current_match += 1
	_start_match()

func _show_ending() -> void:
	# Show arcade ending
	var ending_label := Label.new()
	ending_label.text = "CONGRATULATIONS!\nScore: %d\nTime: %.1fs" % [_score, _total_time]
	ending_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ending_label.position = Vector2(96, 100)
	add_child(ending_label)
	
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://scenes/title/TitleScreen.tscn")
