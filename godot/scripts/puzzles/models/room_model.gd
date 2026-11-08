class_name RoomModel
extends RefCounted
## Escape-room rules: flags, items and used hotspots. A tap may carry the selected item.

var flags := {}
var items := {}      # id -> true
var used := {}


static func spot_visible(s: Dictionary, st: RoomModel) -> bool:
	return (not s.has("visibleIf") or st.flags.has(s["visibleIf"])) and (not s.has("hiddenIf") or not st.flags.has(s["hiddenIf"]))


## Applies a tap. Returns {text, ok, keypad}.
func use_spot(def: Dictionary, s: Dictionary, item: String) -> Dictionary:
	if s.get("keypad", false):
		return {"text": "", "ok": true, "keypad": true}
	if used.has(s["id"]):
		return {"text": String(s.get("doneText", s["text"])), "ok": true, "keypad": false}
	if s.has("needs") and item != s["needs"]:
		var t: String
		if s.has("needsText"):
			t = String(s["needsText"])
		elif items.has(s["needs"]):
			t = "Try using the %s here." % String(def["items"][s["needs"]]["label"]).to_lower()
		else:
			t = String(s["text"])
		return {"text": t, "ok": false, "keypad": false}
	used[s["id"]] = true
	if s.has("needs") and s.get("consumes", false):
		items.erase(s["needs"])
	if s.has("gives"):
		items[s["gives"]] = true
	if s.has("sets"):
		flags[s["sets"]] = true
	return {"text": String(s["text"]), "ok": true, "keypad": false}


func enter_code(def: Dictionary, code: String) -> bool:
	var kp: Dictionary = def["keypad"]
	if code == kp["code"]:
		flags[kp["sets"]] = true
		return true
	return false


func goal_reached(def: Dictionary) -> bool:
	return flags.has(def["goal"])


## Plays the room by trying every visible hotspot with every item until the goal is reached.
## Returns the steps as [[hotspot_id, item_or_empty]] or [] if it gets stuck.
static func auto_solve(def: Dictionary) -> Array:
	var st := RoomModel.new()
	var steps := []
	for _round in 60:
		if st.goal_reached(def):
			return steps
		var progressed := false
		for s in def["hotspots"]:
			if not spot_visible(s, st) or st.used.has(s["id"]):
				continue
			if s.get("keypad", false):
				if st.enter_code(def, String(def["keypad"]["code"])):
					steps.append([s["id"], "", "keypad"])
					progressed = true
				continue
			var tries := [""]
			for it in st.items:
				tries.append(it)
			for it in tries:
				var r := st.use_spot(def, s, it)
				if r["ok"]:
					steps.append([s["id"], it])
					progressed = true
					break
		if not progressed:
			return []
	return steps if st.goal_reached(def) else []


func copy() -> RoomModel:
	var c := RoomModel.new()
	c.flags = flags.duplicate()
	c.items = items.duplicate()
	c.used = used.duplicate()
	return c


## The next useful step from here: [hotspot, item or "", "keypad" or ""], or [].
static func next_step(def: Dictionary, st: RoomModel) -> Array:
	for s in def["hotspots"]:
		if not spot_visible(s, st) or st.used.has(s["id"]):
			continue
		if s.get("keypad", false):
			if not st.flags.has(def["keypad"]["sets"]):
				# only worth it once everything else that gives information has been seen
				continue
			continue
		var tries := [""]
		for it in st.items:
			tries.append(it)
		for it in tries:
			var probe := st.copy()
			var r := probe.use_spot(def, s, it)
			if r["ok"] and not r["keypad"]:
				return [s["id"], it, ""]
	for s in def["hotspots"]:
		if s.get("keypad", false) and spot_visible(s, st) and not st.flags.has(def["keypad"]["sets"]):
			return [s["id"], "", "keypad"]
	return []
