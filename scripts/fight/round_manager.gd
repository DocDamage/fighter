extends Node
## Manages round start, end, and match flow.

const FighterController = preload("res://scripts/fight/fighter_controller.gd")

signal round_started(round_num: int)
signal round_ended(winner_player_index: int)
signal match_ended(winner_player_index: int)

@export var rounds_to_win := 2
@export var round_timer := 99

var _current_round := 1
var _p1_wins := 0
var _p2_wins := 0
var _fighters: Array = []
var _active := false

func setup(fighters: Array) -> void:
	_fighters = fighters
	_current_round = 1
	_p1_wins = 0
	_p2_wins = 0
	_start_round()

func _start_round() -> void:
	_active = true
	for f in _fighters:
		f.reset_health()
		f.global_position.y = 190
		if f.player_index == 0:
			f.global_position.x = 140
		else:
			f.global_position.x = 244
	round_started.emit(_current_round)
	AudioManager.play_sfx("announcer_fight")

func check_round_end() -> void:
	if not _active:
		return
	var f0: FighterController = _fighters[0]
	var f1: FighterController = _fighters[1]
	var p1_ko := f0.is_ko()
	var p2_ko := f1.is_ko()
	var winner := -1
	if p1_ko and p2_ko:
		winner = -1 # draw
	elif p1_ko:
		winner = 1
	elif p2_ko:
		winner = 0
	else:
		return

	_active = false
	if winner == 0:
		_p1_wins += 1
	elif winner == 1:
		_p2_wins += 1

	round_ended.emit(winner)

	if _p1_wins >= rounds_to_win or _p2_wins >= rounds_to_win:
		match_ended.emit(winner if winner >= 0 else -1)
	else:
		_current_round += 1
		# Small delay then next round
		await get_tree().create_timer(2.0).timeout
		_start_round()

func is_active() -> bool:
	return _active
