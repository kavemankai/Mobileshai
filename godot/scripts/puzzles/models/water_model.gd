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
