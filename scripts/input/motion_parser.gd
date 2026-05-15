extends Node
## Recognizes motion inputs from input buffer.

const InputBuffer = preload("res://scripts/input/input_buffer.gd")

@onready var _buffer: Node = $"../InputBuffer"

const MOTIONS := {
	"236": [2, 3, 6],
	"214": [2, 1, 4],
	"623": [6, 2, 3],
	"421": [4, 2, 1],
	"41236": [4, 1, 2, 3, 6],
	"63214": [6, 3, 2, 1, 4],
	"236236": [2, 3, 6, 2, 3, 6],
	"214214": [2, 1, 4, 2, 1, 4],
}

func check_motion(player: int, motion: String, within_frames: int = 12) -> bool:
	var seq: Array = MOTIONS.get(motion, [])
	if seq.is_empty():
		return false
	var seq_idx := 0
	for i in range(min(within_frames, InputBuffer.BUFFER_SIZE)):
		var frame = _buffer.get_frame(player, i)
		var dir: int = frame.direction
		if seq_idx < seq.size() and dir == seq[seq_idx]:
			seq_idx += 1
		elif seq_idx > 0 and dir == seq[seq_idx - 1]:
			pass # allow holding the current direction
		if seq_idx >= seq.size():
			return true
	return false

func check_charge(player: int, charge_dir: int, release_dir: int, min_charge: int = 45) -> bool:
	var charge: int = _buffer.get_charge(player, charge_dir)
	if charge < min_charge:
		return false
	var current = _buffer.get_frame(player, 0)
	return current.direction == release_dir
