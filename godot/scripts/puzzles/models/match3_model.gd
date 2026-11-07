class_name Match3Model
extends RefCounted
## Signal-recovery board. Tiles are dictionaries {id, c, sp} so a view can follow each one as it moves.

var n := 5
var k := 5
var tiles: Array = []
var stat: Array = []
var rng := RandomNumberGenerator.new()
var splash := "ends"
var _next_id := 0


static func create(def: Dictionary, seed_value: int) -> Match3Model:
	var m := Match3Model.new()
	m.n = int(def["size"])
	m.k = int(def["colors"])
	m.rng.seed = seed_value
	m.splash = String(def.get("splash", "ends"))
	var mask := "".join(def["mask"])
	assert(mask.length() == m.n * m.n, "match3 mask size mismatch")
	for ch in mask:
		m.stat.append(ch == "#")
	var guard := 0
	while true:
		m.tiles.clear()
		for i in m.n * m.n:
			var c := m.rng.randi_range(0, m.k - 1)
			while (i % m.n >= 2 and m.tiles[i - 1]["c"] == c and m.tiles[i - 2]["c"] == c) or (i >= 2 * m.n and m.tiles[i - m.n]["c"] == c and m.tiles[i - 2 * m.n]["c"] == c):
				c = m.rng.randi_range(0, m.k - 1)
			m.tiles.append(m._tile(c))
		guard += 1
		if not m.has_move().is_empty() or guard > 500:
			break
	return m


func _tile(c: int, sp: String = "") -> Dictionary:
	_next_id += 1
	return {"id": _next_id, "c": c, "sp": sp}


func adjacent(a: int, b: int) -> bool:
	return (absi(a - b) == 1 and a / n == b / n) or absi(a - b) == n


func swap_tiles(a: int, b: int) -> void:
	var t = tiles[a]
	tiles[a] = tiles[b]
	tiles[b] = t


func static_left() -> int:
	var c := 0
	for s in stat:
		if s:
			c += 1
	return c


## {cells: {idx: true}, direct: {...}, runs: [{cells, horizontal}], specials: [{at, sp, c}]}
func find_matches(prefer: Array = []) -> Dictionary:
	var cells := {}
	var runs := []
	var specials := []
	for horizontal in [true, false]:
		for a in n:
			var run := []
			for b in n + 1:
				var i := (a * n + b) if horizontal else (b * n + a)
				var t = tiles[i] if b < n else null
				if t != null and not run.is_empty() and tiles[run[0]]["c"] == t["c"]:
					run.append(i)
				else:
					if run.size() >= 3:
						for x in run:
							cells[x] = true
						runs.append({"cells": run.duplicate(), "horizontal": horizontal})
						if run.size() >= 4:
							var at: int = run[run.size() / 2]
							for x in run:
								if prefer.has(x):
									at = x
									break
							specials.append({"at": at, "sp": "row" if horizontal else "col", "c": tiles[run[0]]["c"]})
					run = [i] if t != null else []
	var direct := cells.duplicate()
	var queue := cells.keys()
	var beams := []
	while not queue.is_empty():
		var i: int = queue.pop_back()
		var t = tiles[i]
		if t == null or t["sp"] == "":
			continue
		beams.append({"at": i, "sp": t["sp"]})
		var r := i / n
		var c := i % n
		for x in n:
			var j := (r * n + x) if t["sp"] == "row" else (x * n + c)
			if not cells.has(j):
				cells[j] = true
				queue.append(j)
	return {"cells": cells, "direct": direct, "runs": runs, "specials": specials, "beams": beams}


## A valid swap [i, j], or [] if there is none.
func has_move() -> Array:
	for i in n * n:
		for j in [i + 1, i + n]:
			if j >= n * n or not adjacent(i, j):
				continue
			swap_tiles(i, j)
			var ok: bool = not find_matches()["cells"].is_empty()
			swap_tiles(i, j)
			if ok:
				return [i, j]
	return []


func neighbours(i: int) -> Array:
	var r := i / n
	var c := i % n
	var out := []
	if r > 0:
		out.append(i - n)
	if r < n - 1:
		out.append(i + n)
	if c > 0:
		out.append(i - 1)
	if c < n - 1:
		out.append(i + 1)
	return out


## One round of matching: clear, wipe static, make line clearers, drop and refill.
## Returns {} if nothing matched, else what a view needs to animate it.
func step(prefer: Array = []) -> Dictionary:
	var res := find_matches(prefer)
	var cells: Dictionary = res["cells"]
	if cells.is_empty():
		return {}
	var cleared_ids := []
	var cleared := []
	for i in cells:
		cleared_ids.append(tiles[i]["id"])
		cleared.append({"i": i, "c": tiles[i]["c"], "id": tiles[i]["id"]})
	var static_cleared := []
	for i in cells:
		tiles[i] = null
		if stat[i]:
			static_cleared.append(i)
		stat[i] = false
	var wipe := func(j: int) -> void:
		if stat[j]:
			stat[j] = false
			static_cleared.append(j)
	if splash == "all":
		for i in res["direct"]:
			for j in neighbours(i):
				wipe.call(j)
	if splash == "ends":
		for run in res["runs"]:
			var cs: Array = run["cells"]
			var horizontal: bool = run["horizontal"]
			var d := 1 if horizontal else n
			var first: int = cs[0]
			var last: int = cs[-1]
			var before := first - d
			var after := last + d
			if before >= 0 and (not horizontal or before / n == first / n):
				wipe.call(before)
			if after < n * n and (not horizontal or after / n == last / n):
				wipe.call(after)
	var made := []
	for s in res["specials"]:
		var t := _tile(s["c"], s["sp"])
		tiles[s["at"]] = t
		made.append({"id": t["id"], "at": s["at"], "c": s["c"], "sp": s["sp"]})
	gravity()
	return {"cleared": cleared, "static_cleared": static_cleared, "beams": res["beams"], "made": made, "runs": res["runs"]}


func gravity() -> void:
	for c in n:
		var col := []
		for r in range(n - 1, -1, -1):
			if tiles[r * n + c] != null:
				col.append(tiles[r * n + c])
		var kk := 0
		for r in range(n - 1, -1, -1):
			tiles[r * n + c] = col[kk] if kk < col.size() else _tile(rng.randi_range(0, k - 1))
			kk += 1


## Fresh colours with no matches and at least one move. Static is untouched.
func reshuffle() -> void:
	for _try in 500:
		for i in n * n:
			tiles[i] = _tile(rng.randi_range(0, k - 1))
		if find_matches()["cells"].is_empty() and not has_move().is_empty():
			return
