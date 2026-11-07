class_name TimelineModel
extends RefCounted


static func in_place(def: Dictionary, order: Array) -> int:
	var n := 0
	for i in order.size():
		if def["order"][i] == order[i]:
			n += 1
	return n


## A shuffle that never starts with more than one card already right.
static func initial_order(def: Dictionary, rng: RandomNumberGenerator) -> Array:
	var order: Array = def["order"].duplicate()
	for _try in 200:
		for i in range(order.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var t = order[i]
			order[i] = order[j]
			order[j] = t
		if in_place(def, order) <= 1:
			break
	return order
