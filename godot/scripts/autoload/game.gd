extends Node
## Story data, the save, settings, and what the debug tools may touch.
## Save format matches the web build (v2) so a web save imports once on first run.

signal settings_changed

const SAVE_PATH := "user://save.json"
const SETTINGS_PATH := "user://settings.json"
const WEB_SAVE_KEY := "last-check-in-save-v2"
const WEB_SETTINGS_KEY := "last-check-in-settings-v2"
const DEFAULT_NAME := "Alex"
const PHASES := ["name", "chapter", "intro", "puzzle", "reveal", "end"]

var chapters: Array = []
var levels: Array = []
var save: Dictionary = {}
var settings: Dictionary = {
	"master": 0.7, "music": 0.35, "ambience": 0.45, "effects": 0.7,
	"muted": false, "reduced_motion": false, "text_size": 1, "haptics": true,
}
var debug := false
## Debug jumps run in a sandbox that never writes the real save.
var sandbox := false


func _ready() -> void:
	_load_levels()
	_import_web_data()
	_load_settings()
	debug = _detect_debug()


# ---------- data ----------

## JSON numbers arrive as floats. Whole numbers go back to int so they can index arrays.
static func normalize(v: Variant) -> Variant:
	if v is Dictionary:
		var d := {}
		for k in v:
			d[k] = normalize(v[k])
		return d
	if v is Array:
		var a := []
		for x in v:
			a.append(normalize(x))
		return a
	if v is float and v == floorf(v) and absf(v) < 1.0e9:
		return int(v)
	return v


func _load_levels() -> void:
	var data = normalize(JSON.parse_string(FileAccess.get_file_as_string("res://data/levels.json")))
	chapters = data["chapters"]
	levels = data["levels"]


func level(i: int) -> Dictionary:
	return levels[clampi(i, 0, levels.size() - 1)]


func fill(text: String) -> String:
	return text.replace("{name}", String(save.get("name", "")) if String(save.get("name", "")) != "" else DEFAULT_NAME)


func player_name() -> String:
	var n := String(save.get("name", ""))
	return n if n != "" else DEFAULT_NAME


func chapter_size(ch: int) -> int:
	var n := 0
	for l in levels:
		if l["ch"] == ch:
			n += 1
	return n


func level_in_chapter(i: int) -> int:
	var n := 0
	for k in i:
		if levels[k]["ch"] == levels[i]["ch"]:
			n += 1
	return n + 1


# ---------- the save ----------

func new_save(player: String = "") -> Dictionary:
	return {"v": 2, "name": player, "level": 0, "phase": "name", "line": 0, "clues": [], "hints": {}, "finished": false}


## Reads the save file without making it the current save. Empty if there is none or it is unusable.
func read_save_file() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not (parsed is Dictionary):
		return {}
	var s: Dictionary = normalize(parsed)
	if s.get("v", 0) != 2 or not (s.get("level", -1) is int) or not (s.get("clues", null) is Array):
		return {}
	if s["level"] < 0 or s["level"] > levels.size() or not PHASES.has(s.get("phase", "")):
		return {}
	if not (s.get("hints", null) is Dictionary):
		s["hints"] = {}
	s["name"] = String(s.get("name", "")).substr(0, 20)
	s["line"] = int(s.get("line", 0))
	s["finished"] = bool(s.get("finished", false))
	return s


func write_save() -> void:
	if sandbox or save.is_empty():
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(save))


func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func current_level() -> Dictionary:
	return level(int(save["level"]))


func earn_clue(level_index: int) -> void:
	if not save["clues"].has(level_index):
		save["clues"].append(level_index)


## Earned clues, in story order, as {level, ch, title, text}.
func earned_clues() -> Array:
	var idx: Array = save.get("clues", []).duplicate()
	idx.sort()
	var out := []
	for i in idx:
		var l: Dictionary = levels[i]
		out.append({"level": i, "ch": l["ch"], "title": l["clue"]["title"], "text": fill(l["clue"]["text"])})
	return out


func hints_used(level_index: int) -> int:
	return int(save["hints"].get(str(level_index), 0))


func add_hint(level_index: int) -> void:
	save["hints"][str(level_index)] = hints_used(level_index) + 1


# ---------- settings ----------

func _load_settings() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
		if parsed is Dictionary:
			for k in settings:
				if parsed.has(k):
					settings[k] = parsed[k]
	elif OS.has_feature("web"):
		var reduced = JavaScriptBridge.eval("window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches")
		settings["reduced_motion"] = bool(reduced)
	settings["text_size"] = clampi(int(settings["text_size"]), 1, 3)


func set_setting(key: String, value: Variant) -> void:
	settings[key] = value
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(settings))
	settings_changed.emit()


func text_scale() -> float:
	return [1.0, 1.14, 1.3][int(settings["text_size"]) - 1]


func reduced_motion() -> bool:
	return bool(settings["reduced_motion"])


# ---------- first run on the web: bring over a save made by the web build ----------

func _import_web_data() -> void:
	if not OS.has_feature("web"):
		return
	if not FileAccess.file_exists(SAVE_PATH):
		var raw = JavaScriptBridge.eval("localStorage.getItem('%s')" % WEB_SAVE_KEY)
		if raw is String and raw != "":
			var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
			if f:
				f.store_string(raw)
			if read_save_file().is_empty():
				clear_save()
	if not FileAccess.file_exists(SETTINGS_PATH):
		var raw2 = JavaScriptBridge.eval("localStorage.getItem('%s')" % WEB_SETTINGS_KEY)
		if raw2 is String and raw2 != "":
			var p = JSON.parse_string(raw2)
			if p is Dictionary:
				var mapped := {
					"master": p.get("master", settings["master"]), "music": p.get("music", settings["music"]),
					"ambience": p.get("ambience", settings["ambience"]), "effects": p.get("effects", settings["effects"]),
					"muted": p.get("muted", false), "reduced_motion": p.get("reducedMotion", false),
					"text_size": p.get("textSize", 1), "haptics": p.get("haptics", true),
				}
				var f2 := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
				if f2:
					f2.store_string(JSON.stringify(mapped))


func _detect_debug() -> bool:
	if OS.has_feature("web"):
		var q = JavaScriptBridge.eval("new URLSearchParams(location.search).get('debug') === '1' || location.hash === '#debug'")
		return bool(q)
	return OS.get_cmdline_user_args().has("--debug") or OS.has_environment("LCI_DEBUG")
