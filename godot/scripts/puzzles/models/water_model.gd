class_name WaterModel
extends RefCounted
## A tank is a string, bottom to top. One letter per layer.


static func can_pour(tubes: Array, cap: int, a: int, b: int) -> bool:
	if a == b or String(tubes[a]).is_empty() or String(tubes[b]).length() >= cap:
		return false
	return String(tubes[b]).is_empty() or String(tubes[b]).right(1) == String(tubes[a]).right(1)


## How many layers a pour from a to b moves.
static func amount(tubes: Array, cap: int, a: int, b: int) -> int:
	var t: String = tubes[a]
	var c := t.right(1)
	var run := 0
	for i in range(t.length() - 1, -1, -1):
		if t[i] == c:
			run += 1
		else:
			break
	return mini(run, cap - String(tubes[b]).length())


static func pour(tubes: Array, cap: int, a: int, b: int) -> Array:
	var t := tubes.duplicate()
	var c := String(t[a]).right(1)
	var n := amount(tubes, cap, a, b)
	t[a] = String(t[a]).left(String(t[a]).length() - n)
	t[b] = String(t[b]) + c.repeat(n)
	return t


static func solved(tubes: Array, cap: int) -> bool:
	for t in tubes:
		var s := String(t)
		if s.is_empty():
			continue
		if s.length() != cap:
			return false
		for ch in s:
			if ch != s[0]:
				return false
	return true


## First pour of a shortest solution from here: [from, to], or [] if none is found.
static func first_move(tubes: Array, cap: int) -> Array:
	var start := "|".join(tubes)
	var prev := {start: null}
	var queue := [tubes]
	var head := 0
	while head < queue.size() and prev.size() < 30000:
		var t: Array = queue[head]
		head += 1
		if solved(t, cap):
			var k := "|".join(t)
			var mv = null
			while prev[k] != null:
				mv = prev[k][1]
				k = prev[k][0]
			return mv if mv != null else []
		var kt := "|".join(t)
		for a in t.size():
			for b in t.size():
				if can_pour(t, cap, a, b):
					var n := pour(t, cap, a, b)
					var kn := "|".join(n)
					if not prev.has(kn):
						prev[kn] = [kt, [a, b]]
						queue.append(n)
	return _dfs_first(tubes, cap)


## Deep boards run past the breadth-first budget: find any solution depth-first, best-looking pours first.
static func _dfs_first(tubes: Array, cap: int) -> Array:
	var seen := {"|".join(tubes): true}
	var stack := [[tubes, []]]
	while not stack.is_empty() and seen.size() < 200000:
		var item: Array = stack.pop_back()
		var t: Array = item[0]
		var first: Array = item[1]
		if solved(t, cap):
			return first
		var moves := []
		for a in t.size():
			for b in t.size():
				if can_pour(t, cap, a, b):
					# pouring onto the same liquid scores higher than into an empty tank
					var score := 2 if not String(t[b]).is_empty() else 0
					if String(t[a]).length() == amount(t, cap, a, b):
						score -= 1
					moves.append([score, a, b])
		moves.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
		for mv in moves:
			var n := pour(t, cap, mv[1], mv[2])
			var k := "|".join(n)
			if not seen.has(k):
				seen[k] = true
				stack.append([n, first if not first.is_empty() else [mv[1], mv[2]]])
	return []
