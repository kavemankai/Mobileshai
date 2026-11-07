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
