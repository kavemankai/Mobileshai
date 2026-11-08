class_name ScrewsModel
extends RefCounted
## Screws (Screwdom-style). Plates stacked bottom to top, held by coloured screws. A screw can be taken when no
## plate above it that is still on the board covers it. Two colour boxes are open, 3 screws each; a screw with no
## open box of its colour waits in the tray. Full boxes leave and the next opens, pulling matching tray screws.

var plates: Array = []        # {rect: Rect2 (0..1), screws: [index]}
var screws: Array = []        # {plate, pos: Vector2 (0..1), color}
var queue: Array = []         # box colours
var tray_size := 5
var covers: Array = []        # per screw: plate indices above it whose rect holds its point

# state
var removed := {}             # screw index -> true
var next_box := 0
var boxes: Array = []         # [{color, filled}] x2 ("" = closed for good)
var tray: Array = []          # colours


static func from_def(def: Dictionary) -> ScrewsModel:
	var m := ScrewsModel.new()
	for pi in def["plates"].size():
		var p: Dictionary = def["plates"][pi]
		var r: Array = p["rect"]
		var idx := []
		for s in p["screws"]:
			idx.append(m.screws.size())
			m.screws.append({"plate": pi, "pos": Vector2(float(s[0]), float(s[1])), "color": String(s[2])})
		m.plates.append({"rect": Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3])), "screws": idx})
	m.queue = def["boxes"].duplicate()
	m.tray_size = int(def.get("tray", 5))
	for k in m.screws.size():
		var over := []
		var s: Dictionary = m.screws[k]
		for j in range(int(s["plate"]) + 1, m.plates.size()):
			var rr: Rect2 = m.plates[j]["rect"]
			if rr.has_point(s["pos"]) or (s["pos"].x == rr.end.x or s["pos"].y == rr.end.y):
				if s["pos"].x >= rr.position.x and s["pos"].x <= rr.end.x and s["pos"].y >= rr.position.y and s["pos"].y <= rr.end.y:
					over.append(j)
		m.covers.append(over)
	m.reset()
	return m


func reset() -> void:
	removed = {}
	tray = []
	boxes = []
	next_box = 0
	for i in mini(2, queue.size()):
		boxes.append({"color": queue[i], "filled": 0})
		next_box += 1


func plate_gone(pi: int) -> bool:
	for k in plates[pi]["screws"]:
		if not removed.has(k):
			return false
	return true


func is_free(k: int) -> bool:
	if removed.has(k):
		return false
	for j in covers[k]:
		if not plate_gone(j):
			return false
	return true


func free_screws() -> Array:
	var out := []
	for k in screws.size():
		if is_free(k):
			out.append(k)
	return out


## Where screw k would go: ["box", i] or ["tray", slot] or [] if the tray is full.
func destination(k: int) -> Array:
	var c: String = screws[k]["color"]
	for i in boxes.size():
		if boxes[i]["color"] == c and int(boxes[i]["filled"]) < 3:
			return ["box", i]
	if tray.size() < tray_size:
		return ["tray", tray.size()]
	return []


## Takes screw k. Returns the events for a view: {to, boxes_closed: [i], opened: [i], from_tray: [[tray_slot, box]]}
## or {} if the move can't be made.
func take(k: int) -> Dictionary:
	if not is_free(k):
		return {}
	var dest := destination(k)
	if dest.is_empty():
		return {}
	var c: String = screws[k]["color"]
	removed[k] = true
	if dest[0] == "box":
		boxes[dest[1]]["filled"] = int(boxes[dest[1]]["filled"]) + 1
	else:
		tray.append(c)
	var ev := {"to": dest, "closed": [], "opened": [], "from_tray": []}
	var changed := true
	while changed:
		changed = false
		for i in boxes.size():
			if boxes[i]["color"] != "" and int(boxes[i]["filled"]) >= 3:
				ev["closed"].append([i, boxes[i]["color"]])
				if next_box < queue.size():
					boxes[i] = {"color": queue[next_box], "filled": 0}
					next_box += 1
					ev["opened"].append(i)
				else:
					boxes[i] = {"color": "", "filled": 0}
				changed = true
		for i in boxes.size():
			var bc: String = boxes[i]["color"]
			while bc != "" and int(boxes[i]["filled"]) < 3 and tray.has(bc):
				var slot := tray.find(bc)
				tray.remove_at(slot)
				boxes[i]["filled"] = int(boxes[i]["filled"]) + 1
				ev["from_tray"].append([slot, i])
				changed = true
	return ev


func won() -> bool:
	return removed.size() == screws.size()


func snapshot() -> Dictionary:
	return {"removed": removed.duplicate(), "next": next_box, "boxes": boxes.duplicate(true), "tray": tray.duplicate()}


func restore(s: Dictionary) -> void:
	removed = s["removed"].duplicate()
	next_box = s["next"]
	boxes = s["boxes"].duplicate(true)
	tray = s["tray"].duplicate()


func _key() -> String:
	var ks := removed.keys()
	ks.sort()
	var t := tray.duplicate()
	t.sort()
	return "%s|%d|%s|%s" % [str(ks), next_box, str(boxes), str(t)]


## First move of a way to clear the board from here, or -1 if none is found.
func first_move() -> int:
	var seen := {}
	var path := []
	if _dfs(seen, path):
		return path[0] if not path.is_empty() else -1
	return -1


func _dfs(seen: Dictionary, path: Array) -> bool:
	if won():
		return true
	var key := _key()
	if seen.has(key) or seen.size() > 40000:
		return false
	seen[key] = true
	var opts := free_screws()
	# screws that go straight into a box first: the solver finds sensible lines quickly
	opts.sort_custom(func(a: int, b: int) -> bool: return destination(a).size() > 0 and destination(a)[0] == "box" and not (destination(b).size() > 0 and destination(b)[0] == "box"))
	for k in opts:
		var snap := snapshot()
		if take(k).is_empty():
			continue
		path.append(k)
		if _dfs(seen, path):
			restore(snap)
			return true
		path.pop_back()
		restore(snap)
	return false
