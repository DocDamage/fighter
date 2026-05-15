extends Camera2D
## Camera that tracks both fighters with stage bounds.

const FighterController = preload("res://scripts/fight/fighter_controller.gd")

@export var min_zoom := 1.0
@export var max_zoom := 1.5
@export var margin := 60.0
@export var smooth_speed := 8.0

var _fighters: Array = []
var _stage: Dictionary = {}
var _bounds := Rect2()

func setup(fighters: Array, stage_data: Dictionary) -> void:
	_fighters = fighters
	_stage = stage_data
	# Use wall bounds for camera, with padding so camera can reach edges
	var left: float = stage_data.get("left_wall", 20.0) - 40.0
	var right: float = stage_data.get("right_wall", 364.0) + 40.0
	_bounds = Rect2(left, 0, right - left, GameConstants.GAME_HEIGHT)

func _process(delta: float) -> void:
	if _fighters.size() < 2:
		return
	var p1: Vector2 = _fighters[0].global_position
	var p2: Vector2 = _fighters[1].global_position

	# Target position: midpoint
	var target_pos: Vector2 = (p1 + p2) * 0.5
	# Clamp to bounds (handle zoomed-out case where half-viewport exceeds bounds)
	var half_view: float = GameConstants.GAME_WIDTH * 0.5 / zoom.x
	var cam_min: float = _bounds.position.x + half_view
	var cam_max: float = _bounds.end.x - half_view
	if cam_min > cam_max:
		# Stage fits entirely in view; just center the camera
		target_pos.x = (_bounds.position.x + _bounds.end.x) * 0.5
	else:
		target_pos.x = clampf(target_pos.x, cam_min, cam_max)
	target_pos.y = GameConstants.GAME_HEIGHT * 0.5

	position = position.lerp(target_pos, smooth_speed * delta)

	# Zoom to keep both fighters in view
	var dist := absf(p1.x - p2.x) + margin * 2
	var target_zoom := clampf(GameConstants.GAME_WIDTH / dist, min_zoom, max_zoom)
	zoom = lerp(zoom, Vector2(target_zoom, target_zoom), smooth_speed * delta)
