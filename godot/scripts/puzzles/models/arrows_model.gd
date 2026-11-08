class_name ArrowsModel
extends RefCounted
## Arrows: each arrow is a path of squares whose head is the last square, pointing away from the one before it.
## An arrow leaves along the straight line ahead of its head, if no other arrow sits on that line.

var w := 6
var h := 6
var arrows: Array = []      # each: Array of Vector2i(row, col)
var gone := {}              # arrow index -> true


static func from_def(def: Dictionary) -> ArrowsModel:
	var m := ArrowsModel.new()
	m.w = int(def["w"])
	m.h = int(def["h"])
	for a in def["arrows"]:
		var path := []
		for cell in a:
			path.append(Vector2i(int(cell[0]), int(cell[1])))
		m.arrows.append(path)
	return m


func dir_of(i: int) -> Vector2i:
	var a: Array = arrows[i]
	return Vector2i(a[-1]) - Vector2i(a[-2])


func owner_map() -> Dictionary:
	var o := {}
	for i in arrows.size():
		if gone.has(i):
			continue
		for cell in arrows[i]:
			o[cell] = i
	return o


## The squares ahead of arrow i's head, to the edge.
func ray(i: int) -> Array:
	var out := []
	var d := dir_of(i)
	var p: Vector2i = arrows[i][-1] + d
	while p.x >= 0 and p.y >= 0 and p.x < h and p.y < w:
		out.append(p)
		p += d
	return out


## The first arrow in the way, and how many free squares lie before it; -1 if the way is clear.
func blocker(i: int) -> Array:
	var o := owner_map()
	var r := ray(i)
	for k in r.size():
		if o.has(r[k]) and o[r[k]] != i:
			return [o[r[k]], k]
	return [-1, r.size()]


func can_go(i: int) -> bool:
	return not gone.has(i) and blocker(i)[0] == -1


func free_arrows() -> Array:
	var out := []
	for i in arrows.size():
		if can_go(i):
			out.append(i)
	return out


func remove(i: int) -> bool:
	if not can_go(i):
		return false
	gone[i] = true
	return true


func won() -> bool:
	return gone.size() == arrows.size()


## How many arrows wait (directly or not) on arrow i: clearing those first opens the most.
func unlocks(i: int) -> int:
	var n := 0
	for j in arrows.size():
		if j == i or gone.has(j):
			continue
		if blocker(j)[0] == i:
			n += 1
	return n
