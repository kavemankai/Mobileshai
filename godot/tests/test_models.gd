extends SceneTree
## Headless rule tests: godot --headless --path godot --script res://tests/test_models.gd

var fails := 0


func _init() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels.json"))
	var levels: Array = data["levels"]
	test_zip(levels)
	print("model tests: %s" % ("ALL PASS" if fails == 0 else "%d FAILED" % fails))
	quit(1 if fails else 0)


func check(ok: bool, msg: String) -> void:
	if not ok:
		fails += 1
		printerr("FAIL: " + msg)


func test_zip(levels: Array) -> void:
	var n := 0
	for i in levels.size():
		var d: Dictionary = levels[i]["puzzle"]
		if d["kind"] != "zip":
			continue
		n += 1
		var m := ZipModel.from_def(d)
		var path := []
		for c in m.solution:
			check(m.can_extend(path, c), "zip level %d: solution step %d refused" % [i, path.size()])
			path.append(c)
		check(m.solved(path), "zip level %d: solution not solved" % i)
		check(not m.can_extend([], m.solution[1]), "zip level %d: must start on 1" % i)
	check(n > 0, "no zip levels")
