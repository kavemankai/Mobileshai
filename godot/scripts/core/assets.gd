class_name Assets
extends RefCounted
## Where each picture lives. The art pass swaps files in godot/assets; nothing else changes.

const PORTRAIT_MOODS := {
	"NINA": ["neutral", "frightened", "relieved"],
	"CLAIRE": ["guarded", "grieving", "angry"],
}
## The cut-out portraits have a transparent background. OWEN and DANIEL are first-pass rectangular crops.
const CUTOUTS := ["NINA", "CLAIRE"]


static func scene(key: String) -> Texture2D:
	return load("res://assets/art/%s.webp" % key) if ResourceLoader.exists("res://assets/art/%s.webp" % key) else null


static func item(id: String) -> Texture2D:
	var file := "coin_50c" if id == "coin" else id
	var path := "res://assets/items/%s.png" % file
	return load(path) if ResourceLoader.exists(path) else null


static func tile(index: int) -> Texture2D:
	return load("res://assets/tiles/match_tile_%d.png" % (index + 1))


## A speaker tag such as "NINA · RECORDING~frightened", split into {key, mood, name, remote}.
static func speaker(tag: String) -> Dictionary:
	var parts := tag.split("~")
	var who := parts[0].strip_edges()
	var mood := parts[1].strip_edges().to_lower() if parts.size() > 1 else ""
	var key := who.split(" ")[0].to_upper()
	var remote := false
	for w in ["PHONE", "RECORDING", "INTERCOM", "DISTANT"]:
		if who.contains(w):
			remote = true
	return {"key": key, "mood": mood, "name": who, "remote": remote}


## The portrait for a speaker, or null for NARRATOR, YOU and anyone without one.
static func portrait(sp: Dictionary) -> Texture2D:
	var key: String = sp["key"]
	var file := ""
	if PORTRAIT_MOODS.has(key):
		var moods: Array = PORTRAIT_MOODS[key]
		file = "%s_%s" % [key.to_lower(), sp["mood"] if moods.has(sp["mood"]) else moods[0]]
	elif key == "OWEN" or key == "DANIEL":
		file = key.to_lower()
	else:
		return null
	return load("res://assets/portraits/%s.webp" % file)
