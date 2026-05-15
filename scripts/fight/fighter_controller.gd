extends CharacterBody2D
class_name FighterController

const FighterStateMachine = preload("res://scripts/fight/fighter_state_machine.gd")
const InputBuffer = preload("res://scripts/input/input_buffer.gd")

@export var player_index := 0
@export var fighter_id := "ryu"

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _state_machine: FighterStateMachine = $FighterStateMachine
@onready var _pushbox: CollisionShape2D = $Pushbox
@onready var _hurtbox: Area2D = $Hurtbox
@onready var _hitbox: Area2D = $Hitbox

var data: Dictionary = {}
var facing: int = GameConstants.Facing.RIGHT

# Physics
var _walk_speed := 180.0
var _back_walk_speed := 130.0
var _jump_vel := -620.0
var _gravity := GameConstants.GRAVITY
var _max_fall := GameConstants.MAX_FALL_SPEED

# State tracking
var _grounded := true
var _crouching := false
var _input_dir := Vector2.ZERO
var _air_action_used := false
var _opponent: FighterController = null
var _input_buffer: InputBuffer = null

# Combat
var health := 1000
var max_health := 1000
var stun_meter := 0
var max_stun := 1000
var super_meter := 0
var combo_hits := 0
var combo_damage := 0
var _current_move: Dictionary = {}
var _hitbox_base_x := 16.0
var _hitbox_base_y := -22.0

# Extension hooks (filled by Wave 3 agents)
var guard_meter := 0
var _training_dummy_mode := 0

func _ready() -> void:
	data = DataManager.get_fighter_data(fighter_id)
	if data.is_empty():
		push_error("FighterController: no data for " + fighter_id)
		return
	_walk_speed = data.get("walk_speed", 180.0)
	_back_walk_speed = data.get("back_walk_speed", 130.0)
	_jump_vel = data.get("jump_velocity", -620.0)
	var g_override = data.get("gravity_override", null)
	if g_override != null:
		_gravity = float(g_override)
	max_health = data.get("health", 1000)
	health = max_health
	max_stun = data.get("stun", 1000)
	stun_meter = 0

	_load_sprite()
	_setup_collision()
	_state_machine.state_changed.connect(_on_state_changed)

func _load_sprite() -> void:
	var source: String = data.get("sprite_source", "")
	if source.is_empty():
		_create_placeholder()
		return

	var format: String = data.get("sprite_format", "gif_sheet")
	if format == "pre_cut_frames":
		_load_pre_cut_frames(source)
	else:
		var res = load(source)
		if res == null:
			push_error("FighterController: failed to load sprite: " + source)
			_create_placeholder()
			return
		if res is SpriteFrames:
			_sprite.sprite_frames = res
			_sprite.play("default")
		elif res is Texture2D:
			var sf := SpriteFrames.new()
			sf.add_frame("default", res)
			_sprite.sprite_frames = sf
			_sprite.play("default")
			_sprite.scale = Vector2(2, 2)
		else:
			_create_placeholder()
			return
		_sprite.scale = Vector2(2, 2)

func _load_pre_cut_frames(folder: String) -> void:
	var frame_map_path := folder.path_join(fighter_id + "_frame_map.json")
	var frame_map := DataManager.load_json(frame_map_path)
	if frame_map.is_empty():
		_create_placeholder()
		return

	var pattern: String = data.get("frame_name_pattern", "{fighter_id}_{idx:04d}.png")
	var sf := SpriteFrames.new()
	var loaded_any := false
	for anim_name in frame_map.keys():
		var anim_data = frame_map[anim_name]
		var frame_indices: Array = anim_data.get("frames", [])
		var fps: int = anim_data.get("fps", 12)
		var loop: bool = anim_data.get("loop", false)
		if frame_indices.is_empty():
			continue
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, fps)
		sf.set_animation_loop(anim_name, loop)
		for idx in frame_indices:
			var fname: String = pattern.replace("{fighter_id}", fighter_id)
			fname = fname.replace("{idx:04d}", "%04d" % idx)
			fname = fname.replace("{idx}", str(idx))
			var frame_path: String = folder.path_join(fname)
			var tex = load(frame_path) as Texture2D
			if tex:
				sf.add_frame(anim_name, tex)
				loaded_any = true

	if not loaded_any:
		_create_placeholder()
		return

	_sprite.sprite_frames = sf
	if sf.has_animation("idle"):
		_sprite.play("idle")
	elif sf.has_animation("default"):
		_sprite.play("default")
	else:
		_sprite.play(sf.get_animation_names()[0])

	# Scale to match game resolution
	_sprite.scale = Vector2(2, 2)

func _create_placeholder() -> void:
	# Create a simple colored rectangle as placeholder
	var tex := GradientTexture2D.new()
	tex.width = 32
	tex.height = 48
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color.CRIMSON, Color.DARK_BLUE])
	tex.gradient = grad
	var sf := SpriteFrames.new()
	sf.add_frame("default", tex)
	_sprite.sprite_frames = sf
	_sprite.play("default")
	_sprite.scale = Vector2(1, 1)

func _setup_collision() -> void:
	# Pushbox — full body
	var push_rect := RectangleShape2D.new()
	push_rect.size = Vector2(24, 48)
	_pushbox.shape = push_rect
	_pushbox.position = Vector2(0, -24)

	# Hurtbox — slightly smaller
	var hurt_rect := RectangleShape2D.new()
	hurt_rect.size = Vector2(20, 44)
	$Hurtbox/CollisionShape2D.shape = hurt_rect
	$Hurtbox/CollisionShape2D.position = Vector2(0, -22)

	# Hitbox — initially disabled
	var hit_rect := RectangleShape2D.new()
	hit_rect.size = Vector2(20, 20)
	$Hitbox/CollisionShape2D.shape = hit_rect
	$Hitbox/CollisionShape2D.position = Vector2(16, -22)
	_hitbox.monitoring = false
	_hitbox.monitorable = false
	_hitbox.area_entered.connect(Callable(self, "_on_hitbox_area_entered"))

func set_opponent(op: FighterController) -> void:
	_opponent = op

func set_input_buffer(buf: InputBuffer) -> void:
	_input_buffer = buf

func is_on_ground() -> bool:
	return _grounded

func _physics_process(delta: float) -> void:
	_state_machine.tick()
	_update_facing()
	_process_input()
	_apply_physics(delta)
	_update_animation()
	_update_sprite_offset()
	_update_hitbox()
	_update_meters(delta)
	_update_training_dummy_ai()
	move_and_slide()

func _update_facing() -> void:
	if _opponent == null:
		return
	var dir := signf(_opponent.global_position.x - global_position.x)
	if dir != 0 and dir != facing:
		facing = int(dir)
		_sprite.flip_h = facing < 0
	# Always keep hitbox aligned with facing
	$Hitbox/CollisionShape2D.position.x = _hitbox_base_x * facing

func _process_input() -> void:
	var h := Input.get_axis("p%d_left" % player_index, "p%d_right" % player_index)
	var v := Input.get_axis("p%d_up" % player_index, "p%d_down" % player_index)
	_input_dir = Vector2(h, v)

	if not _state_machine.can_act():
		return

	# Grounded actions
	if _grounded:
		# Check for block input (hold away from opponent)
		var blocking := false
		if _opponent != null:
			var back_input := -facing
			blocking = absf(h) > 0.5 and signf(h) == back_input

		if v > 0.5:
			_crouching = true
			if blocking:
				_state_machine.change_state(GameConstants.State.BLOCK_CROUCH)
			else:
				_state_machine.change_state(GameConstants.State.CROUCH)
		elif _crouching and v <= 0.5:
			_crouching = false
			_state_machine.change_state(GameConstants.State.IDLE)
		elif blocking:
			if _state_machine.current != GameConstants.State.BLOCK_STAND:
				_state_machine.change_state(GameConstants.State.BLOCK_STAND)
		elif h != 0:
			_state_machine.change_state(GameConstants.State.WALK)
		else:
			_state_machine.change_state(GameConstants.State.IDLE)

		if Input.is_action_just_pressed("p%d_jump" % player_index) and v <= 0.5 and not blocking:
			_start_jump(h)
		elif Input.is_action_just_pressed("p%d_dash" % player_index) and h > 0 and not blocking:
			_start_dash()
		elif Input.is_action_just_pressed("p%d_backdash" % player_index) and h < 0 and not blocking:
			_start_backdash()
		elif _check_special_input("236236", "punch"):
			if _try_super_move("236236", "punch"):
				pass
		elif Input.is_action_just_pressed("p%d_lp" % player_index) and not blocking:
			var move_name := "cr_lp" if _crouching else "lp"
			_start_attack(move_name, 3, 2, 6, 25, 30)
		elif Input.is_action_just_pressed("p%d_mp" % player_index) and not blocking:
			var move_name := "cr_mp" if _crouching else "mp"
			_start_attack(move_name, 6, 3, 10, 55, 60)
		elif Input.is_action_just_pressed("p%d_hp" % player_index) and not blocking:
			var move_name := "cr_hp" if _crouching else "hp"
			_start_attack(move_name, 10, 4, 16, 100, 120)
		elif Input.is_action_just_pressed("p%d_lk" % player_index) and not blocking:
			var move_name := "cr_lk" if _crouching else "lk"
			_start_attack(move_name, 3, 2, 6, 25, 30)
		elif Input.is_action_just_pressed("p%d_mk" % player_index) and not blocking:
			var move_name := "cr_mk" if _crouching else "mk"
			_start_attack(move_name, 6, 3, 10, 55, 60)
		elif Input.is_action_just_pressed("p%d_hk" % player_index) and not blocking:
			var move_name := "cr_hk" if _crouching else "hk"
			_start_attack(move_name, 10, 4, 16, 100, 120)
		elif Input.is_action_just_pressed("p%d_parry" % player_index) and not blocking:
			_start_parry()
		elif Input.is_action_just_pressed("p%d_throw" % player_index) and not blocking:
			_start_throw()
		elif _check_special_input("236", "punch"):
			_start_special("hadouken")
		elif _check_special_input("623", "punch"):
			_start_special("shoryuken")
		elif _check_special_input("214", "kick"):
			_start_special("tatsumaki")
	else:
		# Airborne
		if Input.is_action_just_pressed("p%d_jump" % player_index) and not _air_action_used:
			if data.get("double_jump", false):
				_start_double_jump()
		elif Input.is_action_just_pressed("p%d_dash" % player_index) and not _air_action_used:
			if data.get("air_dash", false):
				_start_air_dash()
		elif Input.is_action_just_pressed("p%d_lp" % player_index):
			_start_attack("j_lp", 4, 20, 8, 20, 30)
		elif Input.is_action_just_pressed("p%d_mp" % player_index):
			_start_attack("j_mp", 6, 3, 10, 55, 60)
		elif Input.is_action_just_pressed("p%d_hp" % player_index):
			_start_attack("j_hp", 8, 4, 12, 90, 100)
		elif Input.is_action_just_pressed("p%d_lk" % player_index):
			_start_attack("j_lk", 4, 20, 8, 20, 30)
		elif Input.is_action_just_pressed("p%d_mk" % player_index):
			_start_attack("j_mk", 6, 3, 10, 55, 60)
		elif Input.is_action_just_pressed("p%d_hk" % player_index):
			_start_attack("j_hk", 10, 4, 16, 100, 120)

func _start_attack(name: String, startup: int, active: int, recovery: int, damage: int, stun: int) -> void:
	_current_move = {
		"id": name,
		"startup": startup,
		"active": active,
		"recovery": recovery,
		"damage": damage,
		"stun_damage": stun,
		"hitstop": GameConstants.HITSTOP_LIGHT if damage < 50 else GameConstants.HITSTOP_MEDIUM if damage < 80 else GameConstants.HITSTOP_HEAVY,
		"pushback": 40.0,
		"hit_sfx": "hit_jab" if damage < 50 else "hit_strong" if damage < 80 else "hit_fierce"
	}
	_state_machine.change_state(GameConstants.State.ATTACK_STARTUP, startup)

func _start_parry() -> void:
	_state_machine.change_state(GameConstants.State.PARRY, GameConstants.PARRY_ACTIVE)

func _start_throw() -> void:
	if _opponent == null:
		return
	var dist := absf(global_position.x - _opponent.global_position.x)
	if dist > GameConstants.THROW_RANGE:
		return
	_state_machine.change_state(GameConstants.State.THROW, GameConstants.THROW_STARTUP + GameConstants.THROW_ACTIVE)
	# Simple throw: deal damage after startup
	await get_tree().create_timer(GameConstants.THROW_STARTUP * GameConstants.FRAME_TIME).timeout
	if _state_machine.current == GameConstants.State.THROW and _opponent != null:
		var dist2 := absf(global_position.x - _opponent.global_position.x)
		if dist2 <= GameConstants.THROW_RANGE and not _opponent._state_machine.is_invincible():
			# Check for throw tech
			if _opponent._state_machine.current == GameConstants.State.THROW:
				# Tech
				_state_machine.change_state(GameConstants.State.THROW_TECH, 10)
				_opponent._state_machine.change_state(GameConstants.State.THROW_TECH, 10)
				velocity = Vector2(-50 * facing, 0)
				_opponent.velocity = Vector2(50 * facing, 0)
			else:
				_opponent.take_damage(130, 120, GameConstants.HITSTOP_HEAVY, 60)
				_opponent.reset_combo()
				AudioManager.play_sfx("hit_strong")

func _check_special_input(motion: String, button_type: String) -> bool:
	if _input_buffer == null:
		return false
	# Check motion via MotionParser if available
	var has_motion := false
	var scene = get_tree().current_scene
	if scene != null:
		var mp = scene.get_node_or_null("MotionParser")
		if mp == null:
			mp = scene.get_node_or_null("InputBuffer/MotionParser")
		if mp != null and mp.has_method("check_motion"):
			has_motion = mp.call("check_motion", player_index, motion, 12)
	if not has_motion:
		return false
	var btn_mask := 0
	match button_type:
		"punch":
			btn_mask = InputBuffer.InputButton.LP | InputBuffer.InputButton.MP | InputBuffer.InputButton.HP
		"kick":
			btn_mask = InputBuffer.InputButton.LK | InputBuffer.InputButton.MK | InputBuffer.InputButton.HK
	if _input_buffer.has_method("is_held"):
		return _input_buffer.call("is_held", player_index, btn_mask)
	return false

func _start_special(name: String) -> void:
	match name:
		"hadouken":
			AudioManager.play_sfx("voice_ryuken_hadouken")
			_current_move = {"id": "hadouken"}
			_spawn_vfx("Effect_DitheredFire", global_position + Vector2(10 * facing, -20))
			_spawn_projectile(220, 60, 80, 10, 60)
			_state_machine.change_state(GameConstants.State.ATTACK_RECOVERY, 32)
		"shoryuken":
			AudioManager.play_sfx("voice_ryuken_shoryuken")
			_spawn_vfx("Effect_Charged", global_position + Vector2(0, -30))
			_start_attack("shoryuken", 4, 8, 28, 120, 150)
			velocity.y = _jump_vel * 0.7
			_grounded = false
		"tatsumaki":
			AudioManager.play_sfx("voice_ryuken_tatsumaki")
			_spawn_vfx("Effect_Hyperspeed", global_position + Vector2(0, -20))
			_start_attack("tatsumaki", 10, 18, 20, 90, 120)
			velocity.x = _walk_speed * 1.5 * facing

func _spawn_projectile(speed: float, damage: int, stun: int, hitstop: int, pushback: float) -> void:
	var proj_scene = preload("res://scenes/fight/Projectile.tscn")
	if proj_scene == null:
		return
	var proj = proj_scene.instantiate()
	proj.speed = speed
	proj.damage = damage
	proj.stun_damage = stun
	proj.hitstop = hitstop
	proj.pushback = pushback
	proj.facing = facing
	proj.owner_fighter = self
	proj.move_data = {"vfx": "Effect_Explosion"}
	proj.global_position = global_position + Vector2(20 * facing, -20)
	get_tree().current_scene.add_child(proj)

func _start_jump(h_dir: float) -> void:
	_state_machine.change_state(GameConstants.State.PREJUMP, GameConstants.PREJUMP_FRAMES)
	velocity.y = _jump_vel
	if h_dir != 0:
		velocity.x = _walk_speed * h_dir * 0.8
	_grounded = false
	_air_action_used = false

func _start_double_jump() -> void:
	_air_action_used = true
	_state_machine.change_state(GameConstants.State.JUMP)
	velocity.y = _jump_vel * 0.85

func _start_air_dash() -> void:
	_air_action_used = true
	_state_machine.change_state(GameConstants.State.DASH, GameConstants.AIR_DASH_ACTIVE)
	velocity.x = _walk_speed * 2.0 * facing
	velocity.y = 0

func _start_dash() -> void:
	_state_machine.change_state(GameConstants.State.DASH, GameConstants.DASH_ACTIVE)
	velocity.x = _walk_speed * 2.5 * facing

func _start_backdash() -> void:
	_state_machine.change_state(GameConstants.State.BACKDASH, GameConstants.BACKDASH_ACTIVE)
	velocity.x = -_walk_speed * 2.0 * facing

func _apply_physics(delta: float) -> void:
	if _state_machine.is_airborne() or not _grounded:
		velocity.y += _gravity * delta
		velocity.y = minf(velocity.y, _max_fall)
	else:
		velocity.y = 0

	# Apply movement velocities based on state
	match _state_machine.current:
		GameConstants.State.WALK:
			var speed := _walk_speed if _input_dir.x * facing > 0 else _back_walk_speed
			velocity.x = _input_dir.x * speed
		GameConstants.State.CROUCH:
			velocity.x = 0
		GameConstants.State.IDLE:
			velocity.x = 0
		GameConstants.State.ATTACK_STARTUP, GameConstants.State.ATTACK_ACTIVE, GameConstants.State.ATTACK_RECOVERY:
			velocity.x = move_toward(velocity.x, 0, _gravity * delta * 0.5)
		GameConstants.State.HITSTUN, GameConstants.State.BLOCKSTUN:
			velocity.x = move_toward(velocity.x, 0, _gravity * delta * 0.3)
		GameConstants.State.KNOCKDOWN:
			velocity.x = move_toward(velocity.x, 0, _gravity * delta * 0.2)
		GameConstants.State.GETUP:
			velocity.x = 0
		GameConstants.State.THROW, GameConstants.State.THROW_TECH:
			velocity.x = 0

func land() -> void:
	_grounded = true
	velocity.y = 0
	velocity.x = 0
	_air_action_used = false
	if _state_machine.is_airborne() or _state_machine.current == GameConstants.State.JUMP:
		_state_machine.change_state(GameConstants.State.IDLE)
	AudioManager.play_sfx("landing")
	_spawn_vfx("Effect_PuffAndStars", global_position + Vector2(0, -5))

func _get_attack_anim_name() -> String:
	var move_id: String = _current_move.get("id", "")
	if move_id.is_empty():
		return ""
	# Map move IDs to animation names
	match move_id:
		"lp", "mp", "hp", "lk", "mk", "hk":
			return "st_" + move_id
		"cr_lp", "cr_mp", "cr_hp", "cr_lk", "cr_mk", "cr_hk":
			return move_id
		"j_lp", "j_mp", "j_hp", "j_lk", "j_mk", "j_hk":
			return "jmp_" + move_id.substr(2)
		"shoryuken", "tatsumaki":
			return move_id
		"hadouken":
			return "hadoken"
		_:
			return move_id

func _play_anim(anim_name: String, fallback: String = "") -> void:
	if not _sprite.sprite_frames:
		return
	var target := anim_name
	if not _sprite.sprite_frames.has_animation(target):
		if not fallback.is_empty() and _sprite.sprite_frames.has_animation(fallback):
			target = fallback
		elif _sprite.sprite_frames.has_animation("idle"):
			target = "idle"
		elif _sprite.sprite_frames.has_animation("default"):
			target = "default"
		else:
			return
	if _sprite.animation != target:
		_sprite.play(target)

func _update_sprite_offset() -> void:
	if _sprite.sprite_frames == null:
		return
	var tex = _sprite.sprite_frames.get_frame_texture(_sprite.animation, _sprite.frame)
	if tex:
		_sprite.position.y = -tex.get_height() * _sprite.scale.y * 0.5

func _update_animation() -> void:
	match _state_machine.current:
		GameConstants.State.IDLE:
			_play_anim("idle", "default")
		GameConstants.State.WALK:
			_play_anim("walk", "idle")
		GameConstants.State.CROUCH:
			_play_anim("crouch", "idle")
		GameConstants.State.PREJUMP:
			_play_anim("jump", "idle")
		GameConstants.State.JUMP:
			_play_anim("jump", "idle")
		GameConstants.State.DASH:
			_play_anim("walk", "idle")
		GameConstants.State.BACKDASH:
			_play_anim("walk", "idle")
		GameConstants.State.BLOCK_STAND, GameConstants.State.BLOCK_AIR:
			_play_anim("block", "crouch")
		GameConstants.State.BLOCK_CROUCH:
			_play_anim("block", "crouch")
		GameConstants.State.PARRY, GameConstants.State.PARRY_RECOV:
			_play_anim("block", "idle")
		GameConstants.State.ATTACK_STARTUP, GameConstants.State.ATTACK_ACTIVE, GameConstants.State.ATTACK_RECOVERY:
			var anim := _get_attack_anim_name()
			if not anim.is_empty():
				_play_anim(anim, "idle")
			else:
				_play_anim("idle")
		GameConstants.State.HITSTUN:
			_play_anim("hitstun", "idle")
		GameConstants.State.BLOCKSTUN:
			_play_anim("block", "idle")
		GameConstants.State.KNOCKDOWN:
			_play_anim("knockdown", "hitstun")
		GameConstants.State.GETUP:
			_play_anim("getup", "idle")
		GameConstants.State.THROW, GameConstants.State.THROW_TECH, GameConstants.State.THROWN:
			_play_anim("shoryuken", "idle")
		GameConstants.State.DIZZY:
			_play_anim("stunned", "idle")
		GameConstants.State.GUARD_CRUSH:
			_play_anim("hitstun", "idle")
		GameConstants.State.KO:
			_play_anim("knockdown", "hitstun")
		GameConstants.State.VICTORY:
			_play_anim("victory", "idle")

func _get_move_hitbox() -> Dictionary:
	var move_id: String = _current_move.get("id", "")
	match move_id:
		"lp", "j_lp":
			return {"size": Vector2(16, 12), "offset": Vector2(14, -28)}
		"mp", "j_mp":
			return {"size": Vector2(20, 16), "offset": Vector2(20, -28)}
		"hp", "j_hp":
			return {"size": Vector2(24, 20), "offset": Vector2(24, -28)}
		"lk", "j_lk":
			return {"size": Vector2(20, 14), "offset": Vector2(18, -18)}
		"mk", "j_mk":
			return {"size": Vector2(24, 16), "offset": Vector2(22, -18)}
		"hk", "j_hk":
			return {"size": Vector2(28, 20), "offset": Vector2(26, -18)}
		"cr_lp":
			return {"size": Vector2(16, 12), "offset": Vector2(14, -12)}
		"cr_mp":
			return {"size": Vector2(20, 14), "offset": Vector2(18, -12)}
		"cr_hp":
			return {"size": Vector2(24, 16), "offset": Vector2(22, -12)}
		"cr_lk":
			return {"size": Vector2(22, 12), "offset": Vector2(20, -8)}
		"cr_mk":
			return {"size": Vector2(26, 14), "offset": Vector2(24, -8)}
		"cr_hk":
			return {"size": Vector2(30, 16), "offset": Vector2(28, -8)}
		"shoryuken":
			return {"size": Vector2(24, 40), "offset": Vector2(10, -40)}
		"tatsumaki":
			return {"size": Vector2(32, 24), "offset": Vector2(18, -22)}
		"hadouken":
			return {"size": Vector2(20, 20), "offset": Vector2(16, -22)}
		_:
			return {"size": Vector2(20, 20), "offset": Vector2(16, -22)}

func _update_hitbox() -> void:
	match _state_machine.current:
		GameConstants.State.ATTACK_ACTIVE:
			var hb := _get_move_hitbox()
			var shape := $Hitbox/CollisionShape2D.shape as RectangleShape2D
			if shape:
				shape.size = hb["size"]
			_hitbox_base_x = hb["offset"].x
			_hitbox_base_y = hb["offset"].y
			$Hitbox/CollisionShape2D.position = Vector2(_hitbox_base_x * facing, _hitbox_base_y)
			_hitbox.monitoring = true
			_hitbox.monitorable = true
		_:
			_hitbox.monitoring = false
			_hitbox.monitorable = false

func _update_meters(delta: float) -> void:
	# Decay stun meter when not being hit
	if _state_machine.current not in [GameConstants.State.HITSTUN, GameConstants.State.BLOCKSTUN, GameConstants.State.KNOCKDOWN]:
		stun_meter = maxi(0, stun_meter - int(GameConstants.STUN_RECOVERY_RATE * delta))
	
	# Decay guard meter when not blocking
	if not _state_machine.is_blocking():
		guard_meter = maxi(0, guard_meter - int(GameConstants.STUN_RECOVERY_RATE * delta))
	
	# Check for dizzy
	if stun_meter >= max_stun and _state_machine.current != GameConstants.State.DIZZY:
		_on_dizzy_start()
	
	# Check for guard crush
	if guard_meter >= max_stun and _state_machine.current != GameConstants.State.GUARD_CRUSH:
		_on_guard_crush()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.name != "Hurtbox":
		return
	var defender = area.get_parent()
	if defender == null or defender == self:
		return
	if not defender.has_method("take_damage"):
		return
	if _current_move.is_empty():
		return

	var is_air: bool = not defender.is_on_ground()
	var is_blocking: bool = defender._state_machine.is_blocking() if defender.has_method("is_on_ground") else false
	var is_parry: bool = defender._state_machine.current == GameConstants.State.PARRY if defender.has_method("is_on_ground") else false

	var hitstop_val: int = _current_move.get("hitstop", GameConstants.HITSTOP_LIGHT)
	_trigger_hitstop(hitstop_val)

	if is_parry:
		# Parry success
		defender.add_meter(GameConstants.PARRY_METER)
		AudioManager.play_sfx("block")
		_spawn_vfx("Effect_ElectricShield", defender.global_position + Vector2(0, -30))
		_current_move = {}
		_state_machine.change_state(GameConstants.State.IDLE)
	elif is_blocking:
		var raw_damage: int = _current_move.get("damage", 0)
		var chip := int(raw_damage * GameConstants.CHIP_RATIO)
		var blockstun: int = GameConstants.BLOCKSTUN_LIGHT_GROUND
		var pushback: float = _current_move.get("pushback", 40.0) * 0.5
		if is_air:
			pushback *= 1.3
			blockstun = GameConstants.BLOCKSTUN_LIGHT_AIR
		defender.block_hit(is_air, hitstop_val, pushback, blockstun)
		defender.take_chip(chip)
		defender.guard_meter = mini(defender.max_stun, defender.guard_meter + int(raw_damage * 0.5))
		add_meter(_current_move.get("meter_gain", 1))
		AudioManager.play_sfx("block")
		_spawn_vfx("Effect_PuffAndStars", (global_position + defender.global_position) * 0.5 + Vector2(0, -25))
	else:
		# Use attacker's combo count for scaling
		var scaling := _get_scaling(combo_hits)
		var raw_damage: int = _current_move.get("damage", 0)
		var damage := int(raw_damage * scaling)
		var stun: int = _current_move.get("stun_damage", 0)
		var pushback: float = _current_move.get("pushback", 40.0)
		if is_air:
			pushback *= 1.3
		defender.take_damage(damage, stun, hitstop_val, pushback)
		combo_hits += 1
		combo_damage += damage
		add_meter(_current_move.get("meter_gain", 3))
		AudioManager.play_sfx(_current_move.get("hit_sfx", "hit_jab"))
		_spawn_vfx(_get_hit_vfx_id(raw_damage), (global_position + defender.global_position) * 0.5 + Vector2(0, -25))

func _spawn_vfx(vfx_id: String, pos: Vector2) -> void:
	if vfx_id.is_empty():
		return
	var scene = get_tree().current_scene
	if scene == null:
		return
	var vfx_spawner = scene.get_node_or_null("VFXSpawner")
	if vfx_spawner and vfx_spawner.has_method("spawn"):
		vfx_spawner.spawn(vfx_id, pos, facing < 0)

func _get_hit_vfx_id(damage: int) -> String:
	if damage < 50:
		return "Effect_SmallHit"
	elif damage < 100:
		return "Effect_BigHit"
	else:
		return "Effect_BloodImpact"

func _trigger_hitstop(frames: int) -> void:
	var scene = get_tree().current_scene
	if scene.has_node("HitstopManager"):
		var hm = scene.get_node("HitstopManager")
		if hm.has_method("freeze"):
			hm.freeze(frames)

func _get_scaling(hit_count: int) -> float:
	var idx := mini(hit_count, GameConstants.SCALING.size() - 1)
	return GameConstants.SCALING[idx]

func _on_state_changed(new_state: GameConstants.State, old_state: GameConstants.State) -> void:
	match new_state:
		GameConstants.State.ATTACK_ACTIVE:
			if _current_move.has("active"):
				_state_machine.change_state(GameConstants.State.ATTACK_ACTIVE, _current_move.get("active", 1))
		GameConstants.State.ATTACK_STARTUP:
			pass
		GameConstants.State.ATTACK_RECOVERY:
			pass
	# Reset combo when recovering to neutral from hit/block states
	var was_hit_state := old_state in [
		GameConstants.State.HITSTUN, GameConstants.State.BLOCKSTUN,
		GameConstants.State.KNOCKDOWN, GameConstants.State.GETUP
	]
	var is_neutral := new_state in [
		GameConstants.State.IDLE, GameConstants.State.WALK, GameConstants.State.CROUCH
	]
	if was_hit_state and is_neutral:
		reset_combo()
	_update_animation()

# ── Combat API ──
func take_damage(amount: int, stun: int, hitstop: int, pushback: float) -> void:
	health = maxi(0, health - amount)
	stun_meter = mini(max_stun, stun_meter + stun)
	_state_machine.change_state(GameConstants.State.HITSTUN, hitstop)
	velocity.x = pushback * -facing

func take_chip(amount: int) -> void:
	health = maxi(1, health - amount)

func block_hit(is_air: bool, hitstop: int, pushback: float, blockstun: int) -> void:
	if is_air:
		_state_machine.change_state(GameConstants.State.BLOCK_AIR, blockstun)
	elif _crouching:
		_state_machine.change_state(GameConstants.State.BLOCK_CROUCH, blockstun)
	else:
		_state_machine.change_state(GameConstants.State.BLOCK_STAND, blockstun)
	velocity.x = pushback * -facing

func reset_combo() -> void:
	combo_hits = 0
	combo_damage = 0

func add_meter(amount: int) -> void:
	super_meter = mini(GameConstants.METER_MAX, super_meter + amount)

func is_ko() -> bool:
	return health <= 0

func reset_health() -> void:
	health = max_health
	stun_meter = 0
	guard_meter = 0
	super_meter = 0
	combo_hits = 0
	combo_damage = 0
	_grounded = true
	velocity = Vector2.ZERO
	_state_machine.change_state(GameConstants.State.IDLE)

# ── Stub functions for downstream Wave 3 agents ──
func _try_super_move(input_motion: String, button: String) -> bool:
	# Check if we have enough meter
	var cost := GameConstants.METER_SUPER_1_COST
	if super_meter < cost:
		return false

	# Get super move data from fighter's moves list
	var super_id := fighter_id + "_super_1"
	var move_data := DataManager.get_move_data(super_id)
	if move_data.is_empty():
		return false

	# Deduct meter
	super_meter -= cost

	# Super freeze: freeze both fighters
	var freeze_frames: int = move_data.get("super_freeze", 30)
	_trigger_hitstop(freeze_frames)
	if _opponent != null:
		_opponent._trigger_hitstop(freeze_frames)

	# Spawn super flash VFX
	_spawn_vfx("Effect_SuperFlash", global_position + Vector2(0, -30))

	# Set up the super move
	_current_move = {
		"id": super_id,
		"startup": move_data.get("startup", 10),
		"active": move_data.get("active", 20),
		"recovery": move_data.get("recovery", 40),
		"damage": move_data.get("damage", 250),
		"stun_damage": move_data.get("stun_damage", 200),
		"hitstop": move_data.get("hitstop", GameConstants.HITSTOP_SUPER),
		"pushback": move_data.get("pushback", 80.0),
		"meter_gain": 0,
		"hit_sfx": move_data.get("hit_sfx", "hit_fierce"),
		"vfx": move_data.get("vfx", "")
	}

	_state_machine.change_state(GameConstants.State.ATTACK_STARTUP, _current_move["startup"])
	return true

func _on_guard_crush() -> void:
	guard_meter = 0
	_state_machine.change_state(GameConstants.State.GUARD_CRUSH, 60)
	velocity.x = -150 * facing
	_spawn_vfx("Effect_BigHit", global_position + Vector2(0, -25))
	AudioManager.play_sfx("hit_fierce")

func _on_dizzy_start() -> void:
	stun_meter = 0
	_state_machine.change_state(GameConstants.State.DIZZY, GameConstants.STUN_DIZZY_DURATION)
	_spawn_vfx("Effect_PuffAndStars", global_position + Vector2(0, -50))
	AudioManager.play_sfx("hit_strong")

func _on_dizzy_end() -> void:
	stun_meter = 0
	_state_machine.change_state(GameConstants.State.IDLE)

func _update_training_dummy_ai() -> void:
	var ai = get_node_or_null("TrainingDummyAI")
	if ai and ai.has_method("tick"):
		ai.tick(GameConstants.FRAME_TIME)
