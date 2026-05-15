extends Node
## Stores 20 frames of input history per player.

const BUFFER_SIZE := 20

enum InputButton {
	LP = 1,
	MP = 2,
	HP = 4,
	LK = 8,
	MK = 16,
	HK = 32,
	THROW = 64,
	PARRY = 128
}

class FrameInput:
	var direction: int = 5
	var pressed: int = 0
	var held: int = 0
	var released: int = 0
	var charge_frames: Dictionary = {}
	var ground_state := "GROUND"

var _buffer: Array[Array] = [[], []]

func _ready() -> void:
	for p in 2:
		_buffer[p] = []
		for i in BUFFER_SIZE:
			_buffer[p].append(FrameInput.new())

func tick() -> void:
	for p in 2:
		_buffer[p].pop_back()
		_buffer[p].push_front(_read_input(p))

func _read_input(player: int) -> FrameInput:
	var fi := FrameInput.new()
	var h := Input.get_axis("p%d_left" % player, "p%d_right" % player)
	var v := Input.get_axis("p%d_up" % player, "p%d_down" % player)
	fi.direction = _vec_to_numpad(h, v)

	var prev = _buffer[player][0] if _buffer[player].size() > 0 else null
	var prev_held = prev.held if prev else 0

	fi.held = _read_buttons(player)
	fi.pressed = fi.held & ~prev_held
	fi.released = prev_held & ~fi.held

	# Charge tracking
	for dir in [4, 1, 2, 6, 3, 9, 8, 7]:
		var prev_charge = prev.charge_frames.get(dir, 0) if prev else 0
		if fi.direction == dir:
			fi.charge_frames[dir] = prev_charge + 1
		else:
			fi.charge_frames[dir] = 0

	return fi

func _read_buttons(player: int) -> int:
	var mask := 0
	if Input.is_action_pressed("p%d_lp" % player): mask |= InputButton.LP
	if Input.is_action_pressed("p%d_mp" % player): mask |= InputButton.MP
	if Input.is_action_pressed("p%d_hp" % player): mask |= InputButton.HP
	if Input.is_action_pressed("p%d_lk" % player): mask |= InputButton.LK
	if Input.is_action_pressed("p%d_mk" % player): mask |= InputButton.MK
	if Input.is_action_pressed("p%d_hk" % player): mask |= InputButton.HK
	if Input.is_action_pressed("p%d_throw" % player): mask |= InputButton.THROW
	if Input.is_action_pressed("p%d_parry" % player): mask |= InputButton.PARRY
	return mask

func _vec_to_numpad(h: float, v: float) -> int:
	var x := 0
	var y := 0
	if h < -0.5: x = -1
	elif h > 0.5: x = 1
	if v < -0.5: y = -1
	elif v > 0.5: y = 1
	# Convert to numpad: 7 8 9 / 4 5 6 / 1 2 3
	var cols := [7, 8, 9]
	var col := x + 1
	var row := 2 - y
	return cols[col] + row * 3 - 3

func get_frame(player: int, frames_ago: int) -> FrameInput:
	if frames_ago < 0 or frames_ago >= BUFFER_SIZE:
		return FrameInput.new()
	return _buffer[player][frames_ago]

func is_pressed(player: int, button: int, frames_ago: int = 0) -> bool:
	return (get_frame(player, frames_ago).pressed & button) != 0

func is_held(player: int, button: int, frames_ago: int = 0) -> bool:
	return (get_frame(player, frames_ago).held & button) != 0

func get_charge(player: int, direction: int) -> int:
	return _buffer[player][0].charge_frames.get(direction, 0)
