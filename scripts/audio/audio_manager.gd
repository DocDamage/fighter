extends Node
## Handles SFX and music playback.

var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _sfx_pool_size := 16

func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)
	for i in _sfx_pool_size:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)

func play_sfx(event_id: String) -> void:
	var path: String = DataManager.get_sfx_path(event_id)
	if path.is_empty():
		return
	var stream: AudioStream = load(path)
	if stream == null:
		return
	for p in _sfx_players:
		if not p.playing:
			p.stream = stream
			p.play()
			return
	# fallback: reuse first player
	_sfx_players[0].stream = stream
	_sfx_players[0].play()

func play_music(screen_id: String) -> void:
	var path: String = DataManager.get_music_path(screen_id)
	if path.is_empty():
		return
	var stream: AudioStream = load(path)
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	_music_player.stream = stream
	_music_player.play()

func stop_music() -> void:
	_music_player.stop()

func set_music_volume(db: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), db)

func set_sfx_volume(db: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), db)
