extends Node
## Audio: three buses (Music, Ambience, SFX) under Master.
## Room tone and music crossfade. Music plays one pass of its cue, then rests in silence for 20 to 45 s
## before the next pass, so a short cue does not wear out. Dialogue ducks the music.

const FADE := 1.6
const REST_SECONDS := Vector2(20.0, 45.0)
const SILENT := -60.0
const MUSIC_BY_CHAPTER := ["investigation", "investigation", "tension", "pressure"]

var amb_key := ""
## The cue we want, whether it is playing or resting before its next pass.
var music_key := ""
## Recent sounds, for tests: {name, from}.
var played: Array = []

var _streams := {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx := 0
var _stinger_player: AudioStreamPlayer
var _amb: Array[AudioStreamPlayer] = []
var _mus: Array[AudioStreamPlayer] = []
var _rest_timer: Timer
var _fade_timer: Timer
var _pass_id := 0
var _duck_db := 0.0
var _duck_tween: Tween


func _ready() -> void:
	for bus_name in ["Music", "Ambience", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus_name)
			AudioServer.set_bus_send(i, "Master")
	for i in 10:
		_sfx_players.append(_player("SFX"))
	_stinger_player = _player("SFX")
	for i in 2:
		_amb.append(_player("Ambience"))
		_mus.append(_player("Music"))
	_rest_timer = Timer.new()
	_rest_timer.one_shot = true
	_rest_timer.timeout.connect(_on_rest_done)
	add_child(_rest_timer)
	_fade_timer = Timer.new()
	_fade_timer.one_shot = true
	_fade_timer.timeout.connect(_fade_out_pass)
	add_child(_fade_timer)
	Game.settings_changed.connect(apply_settings)
	apply_settings()


func _player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


func _stream(group: String, key: String) -> AudioStream:
	var path := "res://assets/audio/%s/%s.ogg" % [group, key]
	if _streams.has(path):
		return _streams[path]
	var s: AudioStream = load(path) if ResourceLoader.exists(path) else null
	_streams[path] = s
	return s


# ---------- volumes ----------

func apply_settings() -> void:
	var s: Dictionary = Game.settings
	AudioServer.set_bus_mute(0, bool(s["muted"]))
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(float(s["master"]), 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Ambience"), linear_to_db(maxf(float(s["ambience"]) * 0.9, 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(maxf(float(s["effects"]) * 0.8, 0.0001)))
	_apply_music_volume()


func _apply_music_volume() -> void:
	var v := maxf(float(Game.settings["music"]) * 0.9, 0.0001)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(v) + _duck_db)


## Lower the music under dialogue, restore it for puzzles.
func duck(on: bool) -> void:
	if _duck_tween:
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_method(func(v: float) -> void:
		_duck_db = v
		_apply_music_volume(), _duck_db, -5.0 if on else 0.0, 0.4)


# ---------- effects ----------

func sfx(sfx_name: String, pitch_jitter: float = 0.0) -> void:
	var s := _stream("sfx", sfx_name)
	if s == null:
		return
	var p := _sfx_players[_next_sfx]
	_next_sfx = (_next_sfx + 1) % _sfx_players.size()
	p.stream = s
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()
	_log(sfx_name)


## Plays a stinger. False if there is no such file, so callers can fall back to an effect.
func stinger(stinger_name: String) -> bool:
	var s := _stream("stingers", stinger_name)
	if s == null:
		return false
	_stinger_player.stream = s
	_stinger_player.play()
	_log(stinger_name)
	return true


func _log(n: String) -> void:
	played.append({"name": n, "from": "file"})
	if played.size() > 3000:
		played.pop_front()


# ---------- room tone and score ----------

func ambience(key: String) -> void:
	if key == amb_key:
		return
	amb_key = key
	var s := _stream("ambience", key)
	if s == null:
		return
	if "loop" in s:
		s.loop = true
	_crossfade(_amb, s)


func music_cue(cue: String) -> void:
	if cue == music_key:
		return
	music_key = cue
	_rest_timer.stop()
	_start_pass()


## Room tone for a scene and the score for a chapter.
func scene(scene_key: String, chapter: int, ending: bool = false) -> void:
	ambience(scene_key)
	music_cue("resolution" if ending else MUSIC_BY_CHAPTER[clampi(chapter, 0, 3)])


func title() -> void:
	ambience("exterior")
	music_cue("title")


func _start_pass() -> void:
	var s := _stream("music", music_key)
	if s == null:
		return
	if "loop" in s:
		s.loop = false
	_pass_id += 1
	_crossfade(_mus, s)
	var length := s.get_length()
	_fade_timer.start(maxf(length - FADE, 0.5))
	_rest_timer.start(length + randf_range(REST_SECONDS.x, REST_SECONDS.y))


func _fade_out_pass() -> void:
	var cur: AudioStreamPlayer = _mus[0]
	if cur.playing:
		create_tween().tween_property(cur, "volume_db", SILENT, FADE)


func _on_rest_done() -> void:
	if music_key != "":
		_start_pass()


## players[0] is the one playing now. The other takes over while the first fades out.
func _crossfade(players: Array, stream: AudioStream) -> void:
	var cur: AudioStreamPlayer = players[0]
	var nxt: AudioStreamPlayer = players[1]
	nxt.stream = stream
	nxt.volume_db = SILENT
	nxt.play()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(nxt, "volume_db", 0.0, FADE)
	if cur.playing:
		tw.tween_property(cur, "volume_db", SILENT, FADE)
		tw.chain().tween_callback(cur.stop)
	players[0] = nxt
	players[1] = cur


# ---------- for tests ----------

func status() -> Dictionary:
	return {
		"music": music_key, "music_playing": _mus[0].playing, "ambience": amb_key, "ambience_playing": _amb[0].playing,
		"played": played.duplicate(),
		"files": {"sfx": _count("sfx"), "ambience": _count("ambience"), "music": _count("music"), "stingers": _count("stingers")},
	}


func _count(group: String) -> int:
	var d := DirAccess.open("res://assets/audio/%s" % group)
	if d == null:
		return 0
	var seen := {}
	for f in d.get_files():
		var n := f.trim_suffix(".remap").trim_suffix(".import")
		if n.ends_with(".ogg"):
			seen[n] = true
	return seen.size()
