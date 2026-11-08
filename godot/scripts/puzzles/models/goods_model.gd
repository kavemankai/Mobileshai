class_name GoodsModel
extends RefCounted
## Racks are arrays of card type ids.


static func init_racks(def: Dictionary) -> Array:
	var out := []
	for r in def["racks"]:
		out.append(r.filter(func(x: String) -> bool: return x != ""))
	return out


static func is_full_match(rack: Array, capacity: int) -> bool:
	if rack.size() != capacity:
		return false
	for x in rack:
		if x != rack[0]:
			return false
	return true


static func solved(def: Dictionary, racks: Array) -> bool:
	var left := []
	for r in racks:
		left.append_array(r)
	return left.size() == 1 and left[0] == def["leftover"]


## A quick, sensible next move for a hint: finish a set, grow a set, or start one in an empty rack.
## Instant, unlike plan(); a hint only has to point somewhere useful. [from_rack, slot, to_rack] or [].
static func suggest(def: Dictionary, racks: Array) -> Array:
	var cap := int(def["capacity"])
	var best := []
	var best_score := -1
	for b in racks.size():
		var rb: Array = racks[b]
		if rb.size() >= cap or rb.is_empty():
			continue
		var t = rb[0]
		var pure := true
		for x in rb:
			if x != t:
				pure = false
		if not pure:
			continue
		for a in racks.size():
			if a == b:
				continue
			for s in racks[a].size():
				if racks[a][s] != t:
					continue
				# finishing a set beats growing one; taking from a mixed rack beats breaking a pure one
				var score := rb.size() * 10
				var mixed := false
				for x in racks[a]:
					if x != t:
						mixed = true
				score += 5 if mixed else 0
				if score > best_score:
					best_score = score
					best = [a, s, b]
	if not best.is_empty():
		return best
	# no pure rack to grow: start a set in an empty rack with the most common loose card
	for b in racks.size():
		if racks[b].is_empty():
			var counts := {}
			for a in racks.size():
				for x in racks[a]:
					counts[x] = int(counts.get(x, 0)) + 1
			var pick = null
			var most := 0
			for k in counts:
				if k != def["leftover"] and int(counts[k]) > most:
					most = int(counts[k])
					pick = k
			for a in racks.size():
				for s in racks[a].size():
					if racks[a][s] == pick and racks[a].size() > 1:
						return [a, s, b]
	return []


## First move of a full solution from here: [from_rack, slot, to_rack], or [] if none is found.
## A complete search: fine for tests, too slow to run on a phone for every hint.
static func plan(def: Dictionary, racks: Array) -> Array:
	var path := []
	if _dfs(def, racks, int(def["capacity"]), {}, path):
		return path[0] if not path.is_empty() else []
	return []


static func _key(r: Array) -> String:
	var parts := []
	for x in r:
		var y: Array = x.duplicate()
		y.sort()
		parts.append("".join(y))
	parts.sort()
	return "|".join(parts)


static func _dfs(def: Dictionary, r: Array, cap: int, seen: Dictionary, path: Array) -> bool:
	if solved(def, r):
		return true
	if path.size() > 40 or seen.size() > 20000:
		return false
	var k := _key(r)
	if seen.has(k):
		return false
	seen[k] = true
	for a in r.size():
		for s in r[a].size():
			for b in r.size():
				if a == b or r[b].size() >= cap:
					continue
				var n := []
				for x in r:
					n.append(x.duplicate())
				var c = n[a].pop_at(s)
				n[b].append(c)
				if is_full_match(n[b], cap):
					n[b].clear()
				path.append([a, s, b])
				if _dfs(def, n, cap, seen, path):
					return true
				path.pop_back()
	return false
