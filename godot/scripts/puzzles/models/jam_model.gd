class_name JamModel
extends RefCounted
## Jam (Color Block Jam style): coloured blocks slide along rows and columns until stopped. A block pushed into
## a border gate of its colour, at least as wide as itself, leaves the board. Clear them all.

const DIRS := {"U": Vector2i(-1, 0), "D": Vector2i(1, 0), "L": Vector2i(0, -1), "R": Vector2i(0, 1)}
const SIDE := {"U": "N", "D": "S", "L": "W", "R": "E"}

var w := 5
var h := 6
var blocks: Array = []      # {color, shape: [Vector2i], pos: Vector2i}
var gates: Array = []       # {side, at, len, color}
var pos: Array = []         # Vector2i or null (gone)


static func from_def(def: Dictionary) -> JamModel:
	var m := JamModel.new()
	m.w = int(def["w"])
	m.h = int(def["h"])
	for b in def["blocks"]:
		var shape := []
		for s in b["shape"]:
			shape.append(Vector2i(int(s[0]), int(s[1])))
		m.blocks.append({"color": String(b["color"]), "shape": shape})
		m.pos.append(Vector2i(int(b["pos"][0]), int(b["pos"][1])))
	for g in def["gates"]:
		m.gates.append({"side": String(g["side"]), "at": int(g["at"]), "len": int(g["len"]), "color": String(g["color"])})
	return m


func cells_at(i: int, p: Vector2i) -> Array:
	var out := []
	for s in blocks[i]["shape"]:
		out.append(p + Vector2i(s))
	return out


func occupancy(skip: int = -1, state: Array = []) -> Dictionary:
	var st := state if not state.is_empty() else pos
	var o := {}
	for j in blocks.size():
		if j == skip or st[j] == null:
			continue
		for c in cells_at(j, st[j]):
			o[c] = j
	return o


func fits(i: int, p: Vector2i, occ: Dictionary) -> bool:
	for c in cells_at(i, p):
		if c.x < 0 or c.y < 0 or c.x >= h or c.y >= w or occ.has(c):
			return false
	return true


## Is block i at p, pushed in direction d, against a matching gate wide enough for it?
func exits_at(i: int, p: Vector2i, d: String) -> bool:
	var cs := cells_at(i, p)
	var r0 := 9999
	var r1 := -1
	var c0 := 9999
	var c1 := -1
	for c in cs:
		r0 = mini(r0, c.x)
		r1 = maxi(r1, c.x)
		c0 = mini(c0, c.y)
		c1 = maxi(c1, c.y)
	var lo := c0
	var hi := c1
	match d:
		"U":
			if r0 != 0:
				return false
		"D":
			if r1 != h - 1:
				return false
		"L":
			if c0 != 0:
				return false
			lo = r0
			hi = r1
		"R":
			if c1 != w - 1:
				return false
			lo = r0
			hi = r1
	for g in gates:
		if g["side"] == SIDE[d] and g["color"] == blocks[i]["color"] and int(g["at"]) <= lo and hi < int(g["at"]) + int(g["len"]):
			return true
	return false


## Where block i ends up sliding in direction d: {steps, end, out}.
func slide(i: int, d: String, state: Array = []) -> Dictionary:
	var st := state if not state.is_empty() else pos
	var occ := occupancy(i, st)
	var p: Vector2i = st[i]
	var steps := 0
	while fits(i, p + DIRS[d], occ):
		p += DIRS[d]
		steps += 1
	return {"steps": steps, "end": p, "out": exits_at(i, p, d)}


## One step for dragging: returns "moved", "out" or "" (blocked).
func step(i: int, d: String) -> String:
	var occ := occupancy(i)
	var np: Vector2i = pos[i] + DIRS[d]
	if fits(i, np, occ):
		pos[i] = np
		return "moved"
	if exits_at(i, pos[i], d):
		pos[i] = null
		return "out"
	return ""


func won() -> bool:
	for p in pos:
		if p != null:
			return false
	return true


func _key(st: Array) -> String:
	return str(st)


## The shortest list of slides from the current position: [[block, dir]], or [] if none found.
## A* with "blocks still on the board" as the estimate, using buckets by f (f is a small integer).
func solve(limit: int = 60000) -> Array:
	var start := pos.duplicate()
	var sk := _key(start)
	var prev := {sk: null}
	var states := {sk: start}
	var g := {sk: 0}
	var buckets := {}
	var f0 := _left(start)
	buckets[f0] = [sk]
	var f := f0
	var max_f := f0
	while prev.size() < limit:
		while f <= max_f and (not buckets.has(f) or buckets[f].is_empty()):
			f += 1
		if f > max_f:
			return []
		var key: String = buckets[f].pop_back()
		var st: Array = states[key]
		if int(g[key]) + _left(st) != f:
			continue
		if _left(st) == 0:
			var path := []
			var kk := key
			while prev[kk] != null:
				path.push_front(prev[kk][1])
				kk = prev[kk][0]
			return path
		for i in blocks.size():
			if st[i] == null:
				continue
			for d in DIRS:
				var r := slide(i, d, st)
				if int(r["steps"]) == 0 and not r["out"]:
					continue
				var ns := st.duplicate()
				ns[i] = null if r["out"] else r["end"]
				var nk := _key(ns)
				var nc: int = int(g[key]) + 1
				if not g.has(nk) or nc < int(g[nk]):
					g[nk] = nc
					prev[nk] = [key, [i, d]]
					states[nk] = ns
					var nf := nc + _left(ns)
					if not buckets.has(nf):
						buckets[nf] = []
					buckets[nf].append(nk)
					max_f = maxi(max_f, nf)
					if nf < f:
						f = nf
	return []


func _left(st: Array) -> int:
	var n := 0
	for p in st:
		if p != null:
			n += 1
	return n
