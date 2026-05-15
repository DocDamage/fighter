extends Node
## Freezes the game for a specified number of frames on hit connect.

var _freeze_frames := 0
var _fighters: Array = []

func setup(fighters: Array) -> void:
	_fighters = fighters

func freeze(frames: int) -> void:
	_freeze_frames = maxi(_freeze_frames, frames)

func is_frozen() -> bool:
	return _freeze_frames > 0

func tick() -> bool:
	if _freeze_frames > 0:
		_freeze_frames -= 1
		return true
	return false
