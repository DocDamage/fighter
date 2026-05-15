extends CanvasLayer
## Combat HUD: health bars, timer, super meter, combo counter.

const FighterController = preload("res://scripts/fight/fighter_controller.gd")

@onready var _p1_health: ProgressBar = $MarginContainer/TopRow/P1Health
@onready var _p2_health: ProgressBar = $MarginContainer/TopRow/P2Health
@onready var _timer_label: Label = $MarginContainer/TopRow/TimerLabel
@onready var _p1_name: Label = $MarginContainer/TopRow/P1Name
@onready var _p2_name: Label = $MarginContainer/TopRow/P2Name
@onready var _p1_super: ProgressBar = $MarginContainer/BottomRow/P1Super
@onready var _p2_super: ProgressBar = $MarginContainer/BottomRow/P2Super
@onready var _combo_label: Label = $MarginContainer/Center/ComboLabel

var _fighters: Array = []
var _round_time := 99
var _time_acc := 0.0

func setup(fighters: Array, round_time: int = 99) -> void:
	_fighters = fighters
	_round_time = round_time
	if fighters.size() >= 1:
		_p1_name.text = fighters[0].data.get("display_name", "P1")
		_p1_health.max_value = fighters[0].max_health
	if fighters.size() >= 2:
		_p2_name.text = fighters[1].data.get("display_name", "P2")
		_p2_health.max_value = fighters[1].max_health
		_p2_health.fill_mode = ProgressBar.FILL_BEGIN_TO_END
	_p1_super.max_value = GameConstants.METER_MAX
	_p2_super.max_value = GameConstants.METER_MAX
	_update_timer()

func _process(delta: float) -> void:
	if _fighters.size() < 2:
		return
	_p1_health.value = _fighters[0].health
	_p2_health.value = _fighters[1].health
	_p1_super.value = _fighters[0].super_meter
	_p2_super.value = _fighters[1].super_meter

	# Combo display
	if _fighters[0].combo_hits > 1:
		_combo_label.text = "%d HITS!\n%d DMG" % [_fighters[0].combo_hits, _fighters[0].combo_damage]
	elif _fighters[1].combo_hits > 1:
		_combo_label.text = "%d HITS!\n%d DMG" % [_fighters[1].combo_hits, _fighters[1].combo_damage]
	else:
		_combo_label.text = ""

	# Timer
	_time_acc += delta
	if _time_acc >= 1.0:
		_time_acc -= 1.0
		if _round_time > 0:
			_round_time -= 1
			_update_timer()

func _update_timer() -> void:
	_timer_label.text = str(_round_time)

func reset_timer(time: int) -> void:
	_round_time = time
	_time_acc = 0.0
	_update_timer()
