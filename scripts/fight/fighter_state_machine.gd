extends Node
## Finite state machine for fighter behaviour.

signal state_changed(new_state: GameConstants.State, old_state: GameConstants.State)

var current: GameConstants.State = GameConstants.State.IDLE
var _frame_timer := 0

func change_state(new_state: GameConstants.State, frame_count: int = 0) -> void:
	var old := current
	current = new_state
	_frame_timer = frame_count
	state_changed.emit(new_state, old)

func tick() -> void:
	if _frame_timer > 0:
		_frame_timer -= 1
		if _frame_timer <= 0:
			_on_state_expire()

func _on_state_expire() -> void:
	# Default: return to IDLE when timer expires
	match current:
		GameConstants.State.PREJUMP:
			change_state(GameConstants.State.JUMP)
		GameConstants.State.ATTACK_STARTUP:
			change_state(GameConstants.State.ATTACK_ACTIVE)
		GameConstants.State.ATTACK_RECOVERY:
			change_state(GameConstants.State.IDLE)
		GameConstants.State.HITSTUN:
			change_state(GameConstants.State.IDLE)
		GameConstants.State.BLOCKSTUN:
			change_state(GameConstants.State.IDLE)
		GameConstants.State.KNOCKDOWN:
			change_state(GameConstants.State.GETUP)
		GameConstants.State.GETUP:
			change_state(GameConstants.State.IDLE)
		GameConstants.State.DASH:
			change_state(GameConstants.State.IDLE)
		GameConstants.State.BACKDASH:
			change_state(GameConstants.State.IDLE)
		GameConstants.State.PARRY_RECOV:
			change_state(GameConstants.State.IDLE)
		GameConstants.State.THROW:
			change_state(GameConstants.State.IDLE)
		GameConstants.State.THROW_TECH:
			change_state(GameConstants.State.IDLE)
		GameConstants.State.DIZZY:
			# Dizzy ends after timer, or can be ended early by hits
			change_state(GameConstants.State.IDLE)
		GameConstants.State.GUARD_CRUSH:
			change_state(GameConstants.State.IDLE)
		_:
			change_state(GameConstants.State.IDLE)

func get_frames_remaining() -> int:
	return _frame_timer

func is_idle() -> bool:
	return current == GameConstants.State.IDLE

func is_airborne() -> bool:
	return current in [
		GameConstants.State.JUMP,
		GameConstants.State.BLOCK_AIR,
		GameConstants.State.PREJUMP
	]

func is_blocking() -> bool:
	return current in [
		GameConstants.State.BLOCK_STAND,
		GameConstants.State.BLOCK_CROUCH,
		GameConstants.State.BLOCK_AIR
	]

func is_attack_active() -> bool:
	return current == GameConstants.State.ATTACK_ACTIVE

func is_invincible() -> bool:
	return current in [
		GameConstants.State.GETUP,
		GameConstants.State.KO
	]

func can_act() -> bool:
	return current in [
		GameConstants.State.IDLE,
		GameConstants.State.WALK,
		GameConstants.State.CROUCH,
		GameConstants.State.JUMP
	]
