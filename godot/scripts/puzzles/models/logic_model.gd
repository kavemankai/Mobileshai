class_name LogicModel
extends RefCounted
## Marks 0 blank, 1 cross, 2 tick. Blocks: AB (rows A, cols B), AC (rows A, cols C), CB (rows C, cols B).

var n := 3
var marks := {}


func _init(size: int = 3) -> void:
	n = size
	for g in ["AB", "AC", "CB"]:
		var rows := []
		for r in n:
			var row := []
			row.resize(n)
			row.fill(0)
			rows.append(row)
		marks[g] = rows


## Cycles a cell blank -> cross -> tick -> blank. A tick crosses out the rest of its row and column.
## Returns the cells that changed, the tapped one first: [[g, r, c, new_mark], ...].
func toggle(g: String, r: int, c: int) -> Array:
	var next: int = (int(marks[g][r][c]) + 1) % 3
	marks[g][r][c] = next
	var changed := [[g, r, c, next]]
	if next == 2:
		for k in n:
			if k != c and marks[g][r][k] == 0:
				marks[g][r][k] = 1
				changed.append([g, r, k, 1])
			if k != r and marks[g][k][c] == 0:
				marks[g][k][c] = 1
				changed.append([g, k, c, 1])
	return changed


func correct(def: Dictionary) -> bool:
	var sol: Array = def["solution"]
	for a in n:
		for j in n:
			if (marks["AB"][a][j] == 2) != (j == int(sol[a][0])):
				return false
			if (marks["AC"][a][j] == 2) != (j == int(sol[a][1])):
				return false
	return true


static func _perms(n: int) -> Array:
	if n == 1:
		return [[0]]
	var out := []
	for p in _perms(n - 1):
		for i in p.size() + 1:
			var q: Array = p.slice(0, i)
			q.append(n - 1)
			q.append_array(p.slice(i))
			out.append(q)
	return out


## Every assignment consistent with the rules, for tests: [[b, c] per A item].
static func solutions(def: Dictionary) -> Array:
	var n: int = def["categories"][0]["items"].size()
	var perms := _perms(n)
	var rules := []
	for c in def["clues"]:
		if c.has("rule"):
			rules.append(c["rule"])
	var out := []
	for p in perms:
		for q in perms:
			var ok := true
			for r in rules:
				var oa := _owner(p, q, r["a"])
				var ob := _owner(p, q, r["b"])
				if (oa == ob) != (r["t"] == "same"):
					ok = false
					break
			if ok:
				var sol := []
				for i in n:
					sol.append([p[i], q[i]])
				out.append(sol)
	return out


static func _owner(p: Array, q: Array, ref: Array) -> int:
	var cat := int(ref[0])
	var item := int(ref[1])
	return item if cat == 0 else (p.find(item) if cat == 1 else q.find(item))
