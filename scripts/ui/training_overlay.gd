extends CanvasLayer
## Training mode overlay: hitbox display, input history, frame data.

@onready var _hitbox_label: Label = $VBoxContainer/HitboxLabel
@onready var _frame_data_label: Label = $VBoxContainer/FrameDataLabel
@onready var _input_history_label: Label = $VBoxContainer/InputHistoryLabel
@onready var _mode_label: Label = $VBoxContainer/ModeLabel

var _fighters: Array = []
var _show_hitboxes := false
var _input_buffer: Node = null
var _f2_held := false
var _f3_held := false
var _f4_held := false
var _f5_held := false

func setup(fighters: Array, input_buffer: Node) -> void:
	_fighters = fighters
	_input_buffer = input_buffer
	visible = true

func _process(_delta: float) -> void:
	# F2 toggles hitbox display
	var f2_pressed := Input.is_key_pressed(KEY_F2)
	if f2_pressed and not _f2_held:
		_show_hitboxes = not _show_hitboxes
		_update_hitbox_visibility()
	_f2_held = f2_pressed

	# F3 resets positions
	var f3_pressed := Input.is_key_pressed(KEY_F3)
	if f3_pressed and not _f3_held:
		var fight_scene = get_parent()
		if fight_scene and fight_scene.has_method("reset_fighters"):
			fight_scene.reset_fighters()
	_f3_held = f3_pressed

	# F4 refills health and meter
	var f4_pressed := Input.is_key_pressed(KEY_F4)
	if f4_pressed and not _f4_held:
		var fight_scene = get_parent()
		if fight_scene and fight_scene.has_method("refill_fighters"):
			fight_scene.refill_fighters()
	_f4_held = f4_pressed

	# F5 cycles dummy AI mode
	var f5_pressed := Input.is_key_pressed(KEY_F5)
	if f5_pressed and not _f5_held:
		_cycle_dummy_mode()
	_f5_held = f5_pressed

	if _fighters.size() >= 1:
		var f = _fighters[0]
		_update_frame_data(f)
		_update_input_history(0)

func _update_hitbox_visibility() -> void:
	_hitbox_label.text = "Hitboxes: " + ("ON" if _show_hitboxes else "OFF")
	for f_obj in _fighters:
		var f: FighterController = f_obj
		# Use modulate to show/hide debug visuals since debug_color may not render in release
		f._pushbox.debug_color = Color.GREEN if _show_hitboxes else Color.TRANSPARENT
		f._hurtbox.debug_color = Color.BLUE if _show_hitboxes else Color.TRANSPARENT
		f._hitbox.debug_color = Color.RED if _show_hitboxes else Color.TRANSPARENT
		# Also toggle visibility of collision shapes for editor-like debug view
		f._pushbox.visible = _show_hitboxes
		f.get_node("Hurtbox/CollisionShape2D").visible = _show_hitboxes
		f.get_node("Hitbox/CollisionShape2D").visible = _show_hitboxes

func _update_frame_data(f: FighterController) -> void:
	var state_name: String = GameConstants.State.keys()[f._state_machine.current]
	var state_frames := f._state_machine.get_frames_remaining()
	var sprite: AnimatedSprite2D = f.get_node("AnimatedSprite2D")
	var anim_name: String = sprite.animation if sprite.sprite_frames else "none"
	var anim_frame: int = sprite.frame
	_frame_data_label.text = "State: %s (%d)\nAnim: %s [%d]\nPos: (%.0f, %.0f)\nVel: (%.0f, %.0f)\nHP: %d/%d  Meter: %d  Stun: %d/%d" % [
		state_name, state_frames,
		anim_name, anim_frame,
		f.global_position.x, f.global_position.y,
		f.velocity.x, f.velocity.y,
		f.health, f.max_health,
		f.super_meter,
		f.stun_meter, f.max_stun
	]

func _numpad_to_arrow(n: int) -> String:
	match n:
		7: return "↖"
		8: return "↑"
		9: return "↗"
		4: return "←"
		5: return "·"
		6: return "→"
		1: return "↙"
		2: return "↓"
		3: return "↘"
		_: return "?"

func _buttons_to_names(mask: int) -> String:
	var names: Array[String] = []
	if mask & 1:  names.append("LP")
	if mask & 2:  names.append("MP")
	if mask & 4:  names.append("HP")
	if mask & 8:  names.append("LK")
	if mask & 16: names.append("MK")
	if mask & 32: names.append("HK")
	if mask & 64: names.append("TH")
	if mask & 128: names.append("PR")
	return " ".join(names) if names.size() > 0 else "-"

func _update_input_history(player: int) -> void:
	if _input_buffer == null or not _input_buffer.has_method("get_frame"):
		_input_history_label.text = "Inputs: N/A"
		return
	var text := "P%d Inputs:\n" % (player + 1)
	for i in range(8):
		var frame = _input_buffer.call("get_frame", player, i)
		if frame == null:
			continue
		var dir: int = frame.direction
		var held: int = frame.held
		var pressed: int = frame.pressed
		var dir_str := _numpad_to_arrow(dir)
		var pressed_str := _buttons_to_names(pressed)
		text += "F-%d %s | %s\n" % [i, dir_str, pressed_str]
	_input_history_label.text = text
	_update_mode_label()

func _cycle_dummy_mode() -> void:
	if _fighters.size() < 2:
		return
	var dummy: FighterController = _fighters[1]
	var ai = dummy.get_node_or_null("TrainingDummyAI")
	if ai == null:
		return
	var next_mode := (ai.mode + 1) % 8
	ai.set_mode(next_mode)

func _update_mode_label() -> void:
	if _fighters.size() < 2:
		_mode_label.text = "Dummy: N/A"
		return
	var dummy: FighterController = _fighters[1]
	var ai = dummy.get_node_or_null("TrainingDummyAI")
	if ai == null:
		_mode_label.text = "Dummy: N/A"
		return
	var mode_names := ["STAND", "CROUCH", "JUMP", "BLOCK_ALL", "BLOCK_RANDOM", "ATTACK_RANDOM", "RECORD", "PLAYBACK"]
	_mode_label.text = "Dummy: %s" % mode_names[ai.mode]
