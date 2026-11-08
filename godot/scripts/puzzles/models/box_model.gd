class_name BoxModel
extends RefCounted


static func lever_toggle(state: Array, i: int) -> Array:
	var n := int(round(sqrt(state.size())))
	var s := state.duplicate()
	var r := i / n
	var c := i % n
	for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var rr: int = r + d.x
		var cc: int = c + d.y
		if rr >= 0 and cc >= 0 and rr < n and cc < n:
			s[rr * n + cc] = 1 - int(s[rr * n + cc])
	return s


static func neighbours(n: int, i: int) -> Array:
	var out := []
	var r := i / n
	var c := i % n
	for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var rr: int = r + d.x
		var cc: int = c + d.y
		if rr >= 0 and cc >= 0 and rr < n and cc < n:
			out.append(rr * n + cc)
	return out


## The fewest presses that light every lever, as a list of lever indices, or [] if impossible.
static func lever_solve(start: Array) -> Array:
	var count := start.size()
	var best := []
	var found := false
	for mask in 1 << count:
		var s := start.duplicate()
		var presses := []
		for i in count:
			if mask & (1 << i):
				s = lever_toggle(s, i)
				presses.append(i)
		var all := true
		for v in s:
			if int(v) != 1:
				all = false
				break
		if all and (not found or presses.size() < best.size()):
			best = presses
			found = true
	return best
