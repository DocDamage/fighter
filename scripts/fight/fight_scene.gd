extends Node2D
## Main combat scene. Manages stage, fighters, camera, and round flow.

const FighterController = preload("res://scripts/fight/fighter_controller.gd")

@export var stage_id := "tournament_day"
@export var fighter_p1 := "ryu"
@export var fighter_p2 := "ken"
@export var training_mode := true

@onready var _camera: Camera2D = $FightCamera
@onready var _stage_bg: Sprite2D = $StageBackground
@onready var _fighters_container: Node2D = $Fighters
@onready var _hud: CanvasLayer = $FightHUD
@onready var _round_manager = $RoundManager
@onready var _input_buffer = $InputBuffer
@onready var _vfx_spawner = $VFXSpawner
@onready var _hitstop_manager = $HitstopManager
@onready var _training_overlay = $TrainingOverlay

var _stage_data: Dictionary = {}
var _fighters: Array = []
var _floor_y := 190.0
var _left_wall := 20.0
var _right_wall := 364.0

func _ready() -> void:
	_load_stage()
	_spawn_fighters()
	_setup_camera()
	_setup_hud()
	_setup_round_manager()
	_setup_training_overlay()
	AudioManager.play_music(_stage_data.get("music", "tournament_day"))

func _load_stage() -> void:
	_stage_data = DataManager.get_stage_data(stage_id)
	var bg_path: String = _stage_data.get("background", "")
	if not bg_path.is_empty():
		var tex = load(bg_path) as Texture2D
		if tex:
			_stage_bg.texture = tex
			# Scale background to cover viewport
			var scale_x := float(GameConstants.GAME_WIDTH) / tex.get_width()
			var scale_y := float(GameConstants.GAME_HEIGHT) / tex.get_height()
			_stage_bg.scale = Vector2(scale_x, scale_y)
	_floor_y = _stage_data.get("floor_y", 190.0)
	_left_wall = _stage_data.get("left_wall", 20.0)
	_right_wall = _stage_data.get("right_wall", 364.0)

func _spawn_fighters() -> void:
	var p1: FighterController = _create_fighter(fighter_p1, 0)
	var p2: FighterController = _create_fighter(fighter_p2, 1)

	p1.global_position.x = _stage_data.get("p1_spawn_x", 140.0)
	p1.global_position.y = _floor_y
	p2.global_position.x = _stage_data.get("p2_spawn_x", 244.0)
	p2.global_position.y = _floor_y

	p1.set_opponent(p2)
	p2.set_opponent(p1)
	p1.set_input_buffer(_input_buffer)
	p2.set_input_buffer(_input_buffer)

	_fighters_container.add_child(p1)
	_fighters_container.add_child(p2)
	_fighters.append(p1)
	_fighters.append(p2)

func _create_fighter(id: String, idx: int) -> FighterController:
	var f := FighterController.new()
	f.fighter_id = id
	f.player_index = idx
	
	# Build node tree manually
	var sprite := AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	f.add_child(sprite)
	sprite.owner = f
	
	var sm := Node.new()
	sm.name = "FighterStateMachine"
	sm.script = load("res://scripts/fight/fighter_state_machine.gd")
	f.add_child(sm)
	sm.owner = f
	
	var pushbox := CollisionShape2D.new()
	pushbox.name = "Pushbox"
	f.add_child(pushbox)
	pushbox.owner = f
	
	var hurtbox := Area2D.new()
	hurtbox.name = "Hurtbox"
	hurtbox.collision_layer = 2
	hurtbox.collision_mask = 12
	f.add_child(hurtbox)
	hurtbox.owner = f
	var hurt_shape := CollisionShape2D.new()
	hurt_shape.name = "CollisionShape2D"
	hurtbox.add_child(hurt_shape)
	hurt_shape.owner = f
	
	var hitbox := Area2D.new()
	hitbox.name = "Hitbox"
	hitbox.collision_layer = 4
	hitbox.collision_mask = 6
	f.add_child(hitbox)
	hitbox.owner = f
	var hit_shape := CollisionShape2D.new()
	hit_shape.name = "CollisionShape2D"
	hitbox.add_child(hit_shape)
	hit_shape.owner = f
	
	if training_mode and idx == 1:
		var ai := TrainingDummyAI.new()
		ai.name = "TrainingDummyAI"
		ai.setup(f)
		f.add_child(ai)
		ai.owner = f
	
	return f

func _setup_camera() -> void:
	if _camera.has_method("setup"):
		_camera.setup(_fighters, _stage_data)

func _setup_hud() -> void:
	if _hud.has_method("setup"):
		_hud.setup(_fighters, 99)

func _setup_round_manager() -> void:
	if _round_manager.has_method("setup"):
		_round_manager.setup(_fighters)
	if _hitstop_manager.has_method("setup"):
		_hitstop_manager.setup(_fighters)

func _setup_training_overlay() -> void:
	if _training_overlay and _training_overlay.has_method("setup"):
		_training_overlay.setup(_fighters, _input_buffer)

func _physics_process(_delta: float) -> void:
	if _hitstop_manager.has_method("tick") and _hitstop_manager.call("tick"):
		return
	_input_buffer.call("tick")
	_clamp_fighters()
	if training_mode:
		_training_mode_tick()
	else:
		_check_ko()

func _clamp_fighters() -> void:
	for f_obj in _fighters:
		var f: FighterController = f_obj
		# Floor clamp
		if f.global_position.y >= _floor_y:
			if not f.is_on_ground():
				f.land()
			f.global_position.y = _floor_y
		# Wall clamp
		f.global_position.x = clampf(f.global_position.x, _left_wall, _right_wall)

func _check_ko() -> void:
	for f_obj in _fighters:
		var f: FighterController = f_obj
		if f.is_ko() and f._state_machine.current != GameConstants.State.KO:
			f._state_machine.change_state(GameConstants.State.KO)
			if _round_manager.has_method("check_round_end"):
				_round_manager.check_round_end()

func _training_mode_tick() -> void:
	# Prevent KO and keep meter full in training mode
	for f_obj in _fighters:
		var f: FighterController = f_obj
		if f.health <= 0:
			f.health = 1
		if f._state_machine.current == GameConstants.State.KO:
			f._state_machine.change_state(GameConstants.State.IDLE)

func reset_fighters() -> void:
	for f_obj in _fighters:
		var f: FighterController = f_obj
		if f.player_index == 0:
			f.global_position.x = _stage_data.get("p1_spawn_x", 140.0)
		else:
			f.global_position.x = _stage_data.get("p2_spawn_x", 244.0)
		f.global_position.y = _floor_y
		f.velocity = Vector2.ZERO
		f._state_machine.change_state(GameConstants.State.IDLE)

func refill_fighters() -> void:
	for f_obj in _fighters:
		var f: FighterController = f_obj
		f.health = f.max_health
		f.stun_meter = 0
		f.super_meter = GameConstants.METER_MAX
