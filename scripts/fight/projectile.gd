extends Area2D
## Generic projectile with hitbox and lifetime.

var speed := 200.0
var damage := 60
var stun_damage := 80
var hitstop := 10
var pushback := 60.0
var lifetime := 3.0
var facing := 1
var owner_fighter: Node = null
var move_data: Dictionary = {}

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Set up a default collision shape if none exists
	var shape = $CollisionShape2D.shape
	if shape == null:
		var circle := CircleShape2D.new()
		circle.radius = 8.0
		$CollisionShape2D.shape = circle
		$CollisionShape2D.position = Vector2(8 * facing, 0)

	area_entered.connect(_on_area_entered)
	await get_tree().create_timer(lifetime).timeout
	_destroy()

func _physics_process(delta: float) -> void:
	position.x += speed * facing * delta

func _on_area_entered(area: Area2D) -> void:
	if area.get_parent() == owner_fighter:
		return

	# Hit opponent's hurtbox
	if area.name == "Hurtbox":
		var defender = area.get_parent()
		if defender != null and defender.has_method("take_damage"):
			_trigger_hitstop(hitstop)
			defender.take_damage(damage, stun_damage, hitstop, pushback)
			_spawn_hit_vfx()
			_destroy()
		return

	# Projectile clash
	if area.get_parent().has_method("_destroy"):
		area.get_parent()._destroy()
		_destroy()

func _spawn_hit_vfx() -> void:
	var vfx_id: String = move_data.get("vfx", "")
	if vfx_id.is_empty():
		return
	var vfx_spawner = get_tree().current_scene.get_node_or_null("VFXSpawner")
	if vfx_spawner:
		vfx_spawner.spawn(vfx_id, global_position, facing < 0)

func _trigger_hitstop(frames: int) -> void:
	var scene = get_tree().current_scene
	if scene != null and scene.has_node("HitstopManager"):
		var hm = scene.get_node("HitstopManager")
		if hm.has_method("freeze"):
			hm.freeze(frames)

func _destroy() -> void:
	queue_free()
