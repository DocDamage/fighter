extends Node2D
## Spawns VFX animations at world positions.

var _pools := {}

func spawn(vfx_id: String, pos: Vector2, flip_h := false, tint := Color.WHITE, scale_mod := 1.0) -> AnimatedSprite2D:
	var data := DataManager.load_json("res://data/vfx/%s.json" % vfx_id)
	if data.is_empty():
		return null
	var sprite := AnimatedSprite2D.new()
	var folder: String = data.get("folder", "")
	var fps: int = data.get("fps", 60)
	var loop: bool = data.get("loop", false)
	var sscale: float = data.get("scale", 1.0)

	var frames := _load_vfx_frames(folder, fps)
	if frames == null:
		sprite.queue_free()
		return null

	sprite.sprite_frames = frames
	sprite.play("default")
	sprite.position = pos
	sprite.flip_h = flip_h
	sprite.modulate = tint
	sprite.scale = Vector2(sscale, sscale) * scale_mod
	add_child(sprite)

	if not loop:
		sprite.animation_finished.connect(func(): sprite.queue_free())

	return sprite

func _load_vfx_frames(folder: String, fps: int) -> SpriteFrames:
	var dir := DirAccess.open(folder)
	if dir == null:
		return null
	var frames := SpriteFrames.new()
	var textures: Array[Texture2D] = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".png") and not file_name.ends_with(".import"):
			var tex: Texture2D = load(folder.path_join(file_name))
			if tex:
				textures.append(tex)
		file_name = dir.get_next()
	dir.list_dir_end()

	textures.sort_custom(func(a, b): return a.resource_path < b.resource_path)

	if textures.is_empty():
		return null

	frames.set_animation_speed("default", fps)
	for tex in textures:
		frames.add_frame("default", tex)
	return frames
