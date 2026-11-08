class_name TiltModel
extends RefCounted

const DIRS := {"U": Vector2i(-1, 0), "D": Vector2i(1, 0), "L": Vector2i(0, -1), "R": Vector2i(0, 1)}


static func find(rows: Array, ch: String) -> Vector2i:
	for r in rows.size():
		var c := String(rows[r]).find(ch)
		if c >= 0:
			return Vector2i(r, c)
	return Vector2i(-1, -1)


static func cell(rows: Array, p: Vector2i) -> String:
	if p.x < 0 or p.y < 0 or p.x >= rows.size() or p.y >= String(rows[p.x]).length():
		return "#"
	return String(rows[p.x])[p.y]


## The ball rolls until a wall. {path: [Vector2i], hole: bool}
static func roll(rows: Array, from: Vector2i, dir: String) -> Dictionary:
	var d: Vector2i = DIRS[dir]
	var p := from
	var path := []
	while true:
		var n := p + d
		var ch := cell(rows, n)
		if ch == "#":
			break
		p = n
		path.append(p)
		if ch == "O":
			return {"path": path, "hole": true}
	return {"path": path, "hole": false}


## Shortest tilt sequence from S to rest on G, or [] if there is none.
static func solve(rows: Array) -> Array:
	var s := find(rows, "S")
	var g := find(rows, "G")
	var prev := {s: null}
	var frontier := [s]
	while not frontier.is_empty():
		var next := []
		for p in frontier:
			for d in DIRS:
				var res := roll(rows, p, d)
				if res["path"].is_empty() or res["hole"]:
					continue
				var e: Vector2i = res["path"][-1]
				if prev.has(e):
					continue
				prev[e] = [p, d]
				next.append(e)
				if e == g:
					var out := []
					var k: Variant = e
					while prev[k] != null:
						out.push_front(prev[k][1])
						k = prev[k][0]
					return out
		frontier = next
	return []
