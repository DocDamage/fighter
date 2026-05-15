extends Node
## Manages hitbox/hurtbox interactions and combat resolution.

const FighterController = preload("res://scripts/fight/fighter_controller.gd")

signal hit_connected(attacker: FighterController, defender: FighterController, move: Dictionary)
signal block_connected(attacker: FighterController, defender: FighterController, move: Dictionary)

var _fighters: Array = []
var _input_buffer: InputBuffer

func setup(fighters: Array, input_buffer: InputBuffer) -> void:
	_fighters = fighters
	_input_buffer = input_buffer
	for f in fighters:
		f._hitbox.body_entered.connect(_on_hitbox_entered.bind(f))

func _on_hitbox_entered(body: Node2D, attacker: FighterController) -> void:
	if not body is FighterController:
		return
	var defender: FighterController = body
	if defender == attacker:
		return
	if defender._state_machine.is_invincible():
		return

	var move = attacker._current_move if "_current_move" in attacker else {}
	if move == null or (move is Dictionary and move.is_empty()):
		return

	var is_air := not defender.is_on_ground()
	var is_blocking := defender._state_machine.is_blocking()
	var is_parry := defender._state_machine.current == GameConstants.State.PARRY

	if is_parry:
		_resolve_parry(attacker, defender, move)
	elif is_blocking:
		_resolve_block(attacker, defender, move, is_air)
	else:
		_resolve_hit(attacker, defender, move, is_air)

func _resolve_hit(attacker: FighterController, defender: FighterController, move, is_air: bool) -> void:
	var scaling := _get_scaling(attacker.combo_hits)
	var raw_damage: int = move.get("damage", 0)
	var damage := int(raw_damage * scaling)
	var stun: int = move.get("stun_damage", 0)
	var hitstop: int = move.get("hitstop", GameConstants.HITSTOP_LIGHT)
	var pushback: float = move.get("pushback", 40.0)
	if is_air:
		pushback *= 1.3
	defender.take_damage(damage, stun, hitstop, pushback)
	attacker.add_meter(move.get("meter_gain", 3))
	AudioManager.play_sfx(move.get("hit_sfx", "hit_jab"))
	hit_connected.emit(attacker, defender, move)

func _resolve_block(attacker: FighterController, defender: FighterController, move, is_air: bool) -> void:
	var raw_damage: int = move.get("damage", 0)
	var chip := int(raw_damage * GameConstants.CHIP_RATIO)
	var blockstun_key := "blockstun_" + ("air" if is_air else "ground")
	var blockstun: int = move.get(blockstun_key, GameConstants.BLOCKSTUN_LIGHT_GROUND)
	var pushback: float = move.get("pushback", 40.0) * 0.5
	if is_air:
		pushback *= 1.3
	defender.block_hit(is_air, GameConstants.HITSTOP_LIGHT, pushback, blockstun)
	defender.take_chip(chip)
	attacker.add_meter(move.get("meter_gain", 1))
	AudioManager.play_sfx("block")
	block_connected.emit(attacker, defender, move)

func _resolve_parry(attacker: FighterController, defender: FighterController, move) -> void:
	# Parry success: freeze both, defender gets advantage
	defender.add_meter(GameConstants.PARRY_METER)
	AudioManager.play_sfx("block") # TODO: parry SFX
	# TODO: parry freeze and advantage

func _get_scaling(hit_count: int) -> float:
	var idx := mini(hit_count, GameConstants.SCALING.size() - 1)
	return GameConstants.SCALING[idx]
