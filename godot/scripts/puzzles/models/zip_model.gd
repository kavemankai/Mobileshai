class_name ZipModel
extends RefCounted
## Rules of the Path puzzle. No nodes, so it can be tested without a window.

var rows := 0
var cols := 0
var open: Array = []          # bool per cell
var mark_at := {}             # cell -> mark order (0-based)
var mark_count := 0
var solution: Array = []
var open_count := 0


static func from_def(def: Dictionary) -> ZipModel:
	var m := ZipModel.new()
	m.rows = int(def["rows"])
	m.cols = int(def["cols"])
	var r := int(def["start"][0])
	var c := int(def["start"][1])
	m.solution = [r * m.cols + c]
	var step := {"U": Vector2i(-1, 0), "D": Vector2i(1, 0), "L": Vector2i(0, -1), "R": Vector2i(0, 1)}
	for ch in String(def["moves"]):
		r += step[ch].x
		c += step[ch].y
		assert(r >= 0 and c >= 0 and r < m.rows and c < m.cols, "zip path leaves grid")
		var i := r * m.cols + c
		assert(not m.solution.has(i), "zip path revisits a cell")
		m.solution.append(i)
	for i in m.rows * m.cols:
		m.open.append(m.solution.has(i))
	m.open_count = m.solution.size()
	var order := 0
	for idx in def["marks"]:
		m.mark_at[m.solution[int(idx)]] = order
		order += 1
	m.mark_count = order
	return m


func adjacent(a: int, b: int) -> bool:
	return absi(a / cols - b / cols) + absi(a % cols - b % cols) == 1


func reached(path: Array) -> int:
	var n := 0
	for i in path:
		if mark_at.has(i):
			n += 1
	return n


func can_extend(path: Array, next: int) -> bool:
	if not open[next] or path.has(next):
		return false
	if path.is_empty():
		return mark_at.get(next, -1) == 0
	if not adjacent(path[-1], next):
		return false
	var mk: int = mark_at.get(next, -1)
	if mk != -1 and mk != reached(path):
		return false
	if mk == mark_count - 1 and path.size() + 1 != open_count:
		return false
	return true


func solved(path: Array) -> bool:
	return path.size() == open_count and mark_at.get(path[-1], -1) == mark_count - 1
