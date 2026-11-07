class_name CryptexModel
extends RefCounted


static func word(def: Dictionary, pos: Array) -> String:
	var s := ""
	for i in pos.size():
		s += String(def["rings"][i])[int(pos[i])]
	return s


## Start positions where no ring already shows its right letter.
static func start_positions(def: Dictionary, rng: RandomNumberGenerator) -> Array:
	var pos := []
	for i in def["rings"].size():
		var ring: String = def["rings"][i]
		var p := rng.randi_range(0, ring.length() - 1)
		while ring[p] == String(def["word"])[i]:
			p = rng.randi_range(0, ring.length() - 1)
		pos.append(p)
	return pos
