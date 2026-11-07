class_name PanelsModel
extends RefCounted
## State: slots[slot] = panel index, views[panel] = 0 (wide) or 1 (close).

const OPP := {"N": "S", "S": "N", "E": "W", "W": "E"}


static func _next(slot: int, cols: int, out: String) -> Vector2i:
	var r := slot / cols
	var c := slot % cols
	match out:
		"N": return Vector2i(r - 1, c)
		"S": return Vector2i(r + 1, c)
		"E": return Vector2i(r, c + 1)
	return Vector2i(r, c - 1)


## Panels connected from the start before the first break (or the whole path), in order.
static func connected(def: Dictionary, slots: Array, views: Array) -> Array:
	var cols := int(def["cols"])
	var rows := int(def["rows"])
	var slot := int(def["start"]["slot"])
	var entry: String = def["start"]["edge"]
	var out := []
	for _k in def["panels"].size():
		var pi: int = slots[slot]
		var ex: Array = def["panels"][pi]["views"][views[pi]]["exits"]
		if not ex.has(entry) or out.has(pi):
			break
		out.append(pi)
		var o: String = ex[1] if ex[0] == entry else ex[0]
		if slot == int(def["end"]["slot"]) and o == def["end"]["edge"]:
			return out
		var nx := _next(slot, cols, o)
		if nx.x < 0 or nx.y < 0 or nx.x >= rows or nx.y >= cols:
			break
		slot = nx.x * cols + nx.y
		entry = OPP[o]
	return out


## The full path from start to end, or [] if it breaks or never gets there.
static func trace(def: Dictionary, slots: Array, views: Array) -> Array:
	var cols := int(def["cols"])
	var rows := int(def["rows"])
	var slot := int(def["start"]["slot"])
	var entry: String = def["start"]["edge"]
	var seen := []
	for _k in rows * cols:
		var pi: int = slots[slot]
		var ex: Array = def["panels"][pi]["views"][views[pi]]["exits"]
		if not ex.has(entry):
			return []
		var o: String = ex[1] if ex[0] == entry else ex[0]
		seen.append(pi)
		if slot == int(def["end"]["slot"]) and o == def["end"]["edge"]:
			return seen
		var nx := _next(slot, cols, o)
		if nx.x < 0 or nx.y < 0 or nx.x >= rows or nx.y >= cols:
			return []
		slot = nx.x * cols + nx.y
		entry = OPP[o]
		if seen.has(slots[slot]):
			return []
	return []


static func solved(def: Dictionary, slots: Array, views: Array) -> bool:
	var seen := trace(def, slots, views)
	if seen.size() != def["panels"].size():
		return false
	for i in seen.size():
		if def["panels"][seen[i]]["id"] != def["order"][i]:
			return false
	return true


static func shuffled_start(def: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var n: int = def["panels"].size()
	for _try in 500:
		var slots := range(n)
		for i in range(n - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var t = slots[i]
			slots[i] = slots[j]
			slots[j] = t
		var views := []
		for i in n:
			views.append(0 if rng.randf() < 0.5 else 1)
		if trace(def, slots, views).is_empty():
			return {"slots": slots, "views": views}
	return {"slots": range(n), "views": [0, 0, 0, 0, 0, 0].slice(0, n)}


## Brute force for tests and the QA driver: every arrangement that solves the board.
static func solutions(def: Dictionary) -> Array:
	var n: int = def["panels"].size()
	var out := []
	var perms := []
	_perms(range(n), [], perms)
	for p in perms:
		for mask in 1 << n:
			var views := []
			for i in n:
				views.append((mask >> i) & 1)
			if solved(def, p, views):
				out.append({"slots": p, "views": views})
	return out


static func _perms(rest: Array, cur: Array, out: Array) -> void:
	if rest.is_empty():
		out.append(cur.duplicate())
		return
	for i in rest.size():
		var r := rest.duplicate()
		var x = r.pop_at(i)
		cur.append(x)
		_perms(r, cur, out)
		cur.pop_back()
