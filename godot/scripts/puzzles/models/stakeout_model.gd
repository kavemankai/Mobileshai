class_name StakeoutModel
extends RefCounted
## Stakeout (Queens-style): an N x N grid in N zones. One watcher per row, column and zone, none touching.
## Marks: 0 empty, 1 crossed out, 2 watcher.

var n := 6
var zone: Array = []        # zone[r][c] = zone index
var marks: Array = []


static func from_def(def: Dictionary) -> StakeoutModel:
	var m := StakeoutModel.new()
	var rows: Array = def["regions"]
	m.n = rows.size()
	var letters := {}
	for r in m.n:
		var line := []
		var mk := []
		for ch in String(rows[r]):
			if not letters.has(ch):
				letters[ch] = letters.size()
			line.append(letters[ch])
			mk.append(0)
		m.zone.append(line)
		m.marks.append(mk)
	return m


func watchers() -> Array:
	var out := []
	for r in n:
		for c in n:
			if marks[r][c] == 2:
				out.append(Vector2i(r, c))
	return out


## Watchers that break a rule with another watcher.
func conflicts() -> Dictionary:
	var bad := {}
	var w := watchers()
	for i in w.size():
		for j in range(i + 1, w.size()):
			var a: Vector2i = w[i]
			var b: Vector2i = w[j]
			if a.x == b.x or a.y == b.y or zone[a.x][a.y] == zone[b.x][b.y] or (absi(a.x - b.x) <= 1 and absi(a.y - b.y) <= 1):
				bad[a] = true
				bad[b] = true
	return bad


func solved() -> bool:
	return watchers().size() == n and conflicts().is_empty()


## Every placement that satisfies the rules, up to `limit`. Each is an Array of column per row.
func solutions(limit: int = 2) -> Array:
	var out := []
	_rec(0, [], {}, {}, out, limit)
	return out


func _rec(r: int, placed: Array, cols: Dictionary, zones: Dictionary, out: Array, limit: int) -> void:
	if out.size() >= limit:
		return
	if r == n:
		out.append(placed.duplicate())
		return
	for c in n:
		if cols.has(c) or zones.has(zone[r][c]):
			continue
		if not placed.is_empty() and absi(int(placed[-1]) - c) <= 1:
			continue
		placed.append(c)
		cols[c] = true
		zones[zone[r][c]] = true
		_rec(r + 1, placed, cols, zones, out, limit)
		placed.pop_back()
		cols.erase(c)
		zones.erase(zone[r][c])


func cells_of_zone(z: int) -> Array:
	var out := []
	for r in n:
		for c in n:
			if zone[r][c] == z:
				out.append(Vector2i(r, c))
	return out
