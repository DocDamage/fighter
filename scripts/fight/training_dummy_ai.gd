extends Node
class_name TrainingDummyAI

enum Mode {
	STAND,
	CROUCH,
	JUMP,
	BLOCK_ALL,
	BLOCK_RANDOM,
	ATTACK_RANDOM,
	RECORD,
	PLAYBACK
}

var mode := Mode.STAND
var _fighter: FighterController = null
var _rng := RandomNumberGenerator.new()
var _input_prefix := "p1"

# Recording
const MAX_RECORD_FRAMES := 600  # 10 seconds at 60fps
var _record_buffer: Array[Dictionary] = []
var _record_frame := 0
var _is_recording := false
var _is_playing := false
var _playback_frame := 0

func setup(fighter: FighterController) -> void:
	_fighter = fighter
	_input_prefix = "p%d" % fighter.player_index
	_rng.randomize()

func set_mode(new_mode: Mode) -> void:
	mode = new_mode
	_stop_record_playback()

func _stop_record_playback() -> void:
	_is_recording = false
	_is_playing = false
	_record_buffer.clear()
	_record_frame = 0
	_playback_frame = 0

func tick(delta: float) -> void:
	if _fighter == null:
		return
	
	match mode:
		Mode.RECORD:
			_tick_record()
		Mode.PLAYBACK:
			_tick_playback()
		_:
			_tick_behavior()

func _tick_record() -> void:
	if not _is_recording:
		_is_recording = true
		_record_buffer.clear()
		_record_frame = 0
	
	var frame_data := {
		"lp": Input.is_action_pressed(_input_prefix + "_lp"),
		"mp": Input.is_action_pressed(_input_prefix + "_mp"),
		"hp": Input.is_action_pressed(_input_prefix + "_hp"),
		"lk": Input.is_action_pressed(_input_prefix + "_lk"),
		"mk": Input.is_action_pressed(_input_prefix + "_mk"),
		"hk": Input.is_action_pressed(_input_prefix + "_hk"),
		"left": Input.is_action_pressed(_input_prefix + "_left"),
		"right": Input.is_action_pressed(_input_prefix + "_right"),
		"down": Input.is_action_pressed(_input_prefix + "_down"),
		"up": Input.is_action_pressed(_input_prefix + "_up"),
		"jump": Input.is_action_pressed(_input_prefix + "_jump"),
	}
	_record_buffer.append(frame_data)
	if _record_buffer.size() >= MAX_RECORD_FRAMES:
		mode = Mode.PLAYBACK
		_is_recording = false
		_is_playing = true
		_playback_frame = 0

func _tick_playback() -> void:
	if _record_buffer.is_empty():
		mode = Mode.STAND
		return
	
	var frame_data: Dictionary = _record_buffer[_playback_frame]
	_playback_frame = (_playback_frame + 1) % _record_buffer.size()
	
	# Feed inputs back via Input.action_press/action_release
	_set_input(_input_prefix + "_lp", frame_data.get("lp", false))
	_set_input(_input_prefix + "_mp", frame_data.get("mp", false))
	_set_input(_input_prefix + "_hp", frame_data.get("hp", false))
	_set_input(_input_prefix + "_lk", frame_data.get("lk", false))
	_set_input(_input_prefix + "_mk", frame_data.get("mk", false))
	_set_input(_input_prefix + "_hk", frame_data.get("hk", false))
	_set_input(_input_prefix + "_left", frame_data.get("left", false))
	_set_input(_input_prefix + "_right", frame_data.get("right", false))
	_set_input(_input_prefix + "_down", frame_data.get("down", false))
	_set_input(_input_prefix + "_up", frame_data.get("up", false))
	_set_input(_input_prefix + "_jump", frame_data.get("jump", false))

func _set_input(action: String, pressed: bool) -> void:
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)

func _tick_behavior() -> void:
	if not _fighter._state_machine.can_act():
		return
	
	# Release all inputs first
	for a in ["_left","_right","_down","_up","_lp","_mp","_hp","_lk","_mk","_hk","_jump"]:
		Input.action_release(_input_prefix + a)
	
	match mode:
		Mode.STAND:
			pass
		Mode.CROUCH:
			Input.action_press(_input_prefix + "_down")
		Mode.JUMP:
			if _fighter.is_on_ground() and _rng.randf() < 0.02:
				Input.action_press(_input_prefix + "_jump")
		Mode.BLOCK_ALL:
			if _fighter._opponent != null:
				var back_dir := -_fighter.facing
				if back_dir < 0:
					Input.action_press(_input_prefix + "_left")
				else:
					Input.action_press(_input_prefix + "_right")
		Mode.BLOCK_RANDOM:
			if _fighter._opponent != null and _rng.randf() < 0.70:
				var back_dir := -_fighter.facing
				if back_dir < 0:
					Input.action_press(_input_prefix + "_left")
				else:
					Input.action_press(_input_prefix + "_right")
		Mode.ATTACK_RANDOM:
			if _fighter.is_on_ground() and _rng.randf() < 0.03:
				var btn := [_input_prefix + "_lp", _input_prefix + "_mp", _input_prefix + "_hp", _input_prefix + "_lk", _input_prefix + "_mk", _input_prefix + "_hk"][_rng.randi() % 6]
				Input.action_press(btn)
