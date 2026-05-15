extends Control
## VS screen shown between character select and fight.

const FIGHT_SCENE := "res://scenes/fight/FightScene.tscn"
const PORTRAIT_SCALE := 3.0

@onready var _p1_portrait: TextureRect = $P1Portrait
@onready var _p2_portrait: TextureRect = $P2Portrait
@onready var _p1_name: Label = $P1Name
@onready var _p2_name: Label = $P2Name
@onready var _vs_label: Label = $VSLabel
@onready var _stage_name: Label = $StageName

var p1_fighter := "ryu"
var p2_fighter := "ken"
var stage_id := "tournament_day"
var _timer := 0.0
var _auto_advance := 3.0
var _started := false

func _ready() -> void:
	AudioManager.play_music("character_select")
	
	# Load fighter display names
	var p1_data := DataManager.get_fighter_data(p1_fighter)
	var p2_data := DataManager.get_fighter_data(p2_fighter)
	_p1_name.text = p1_data.get("display_name", p1_fighter.to_upper())
	_p2_name.text = p2_data.get("display_name", p2_fighter.to_upper())
	
	# Load stage name
	var stage_data := DataManager.get_stage_data(stage_id)
	_stage_name.text = stage_data.get("display_name", stage_id)
	
	# Load portraits (idle frame 0)
	_load_portrait(p1_fighter, _p1_portrait)
	_load_portrait(p2_fighter, _p2_portrait)
	
	# Animate VS label
	_vs_label.scale = Vector2.ZERO
	var tween := create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_vs_label, "scale", Vector2(1.5, 1.5), 0.6)
	
	AudioManager.play_sfx("announcer_fight")

func _load_portrait(fighter_id: String, target: TextureRect) -> void:
	var fdata := DataManager.get_fighter_data(fighter_id)
	var folder: String = fdata.get("sprite_source", "res://assets/characters/processed/%s" % fighter_id)
	var pattern: String = fdata.get("frame_name_pattern", "{fighter_id}_{idx:04d}.png")
	var fname: String = pattern.replace("{fighter_id}", fighter_id).replace("{idx:04d}", "0000").replace("{idx}", "0")
	var png_path := folder.path_join(fname)
	var tex = load(png_path) as Texture2D
	if tex:
		target.texture = tex
		target.custom_minimum_size = Vector2(tex.get_width(), tex.get_height()) * PORTRAIT_SCALE
		target.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		target.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func _process(delta: float) -> void:
	if _started:
		return
	
	_timer += delta
	
	# Pulsing VS label
	_vs_label.modulate = Color.YELLOW.lerp(Color.WHITE, abs(sin(_timer * 4.0)))
	
	# Auto-advance or skip
	if _timer >= _auto_advance or Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("p0_lp") or Input.is_action_just_pressed("p1_lp"):
		_start_fight()

func _start_fight() -> void:
	_started = true
	var fight = load(FIGHT_SCENE).instantiate()
	fight.fighter_p1 = p1_fighter
	fight.fighter_p2 = p2_fighter
	fight.stage_id = stage_id
	fight.training_mode = true
	get_tree().root.add_child(fight)
	queue_free()
