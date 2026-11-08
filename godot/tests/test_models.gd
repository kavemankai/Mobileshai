extends SceneTree
## Headless rule tests: godot --headless --path godot --script res://tests/test_models.gd

var fails := 0


func _init() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels.json"))
	var levels: Array = data["levels"]
	test_zip(levels)
	test_logic(levels)
	test_cryptex(levels)
	test_goods_water(levels)
	test_match3(levels)
	test_blockfit_tilt(levels)
	test_panels(levels)
	test_box(levels)
	test_hint_planners(levels)
	test_stakeout(levels)
	test_screws(levels)
	test_arrows(levels)
	test_jam(levels)
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


func test_logic(levels: Array) -> void:
	for i in levels.size():
		var d: Dictionary = levels[i]["puzzle"]
		if d["kind"] != "logic":
			continue
		var sols := LogicModel.solutions(d)
		check(sols.size() == 1, "logic level %d has %d solutions" % [i, sols.size()])
		if sols.size() == 1:
			for a in sols[0].size():
				check(int(sols[0][a][0]) == int(d["solution"][a][0]) and int(sols[0][a][1]) == int(d["solution"][a][1]), "logic level %d solution differs from def" % i)
		var m := LogicModel.new(d["categories"][0]["items"].size())
		for a in m.n:
			m.marks["AB"][a][int(d["solution"][a][0])] = 2
			m.marks["AC"][a][int(d["solution"][a][1])] = 2
			for j in m.n:
				if j != int(d["solution"][a][0]):
					m.marks["AB"][a][j] = 1
				if j != int(d["solution"][a][1]):
					m.marks["AC"][a][j] = 1
		check(m.correct(d), "logic level %d full marks not correct" % i)
		var t := LogicModel.new(3)
		var ch := t.toggle("AB", 0, 0)
		ch = t.toggle("AB", 0, 0)
		check(t.marks["AB"][0][0] == 2 and t.marks["AB"][0][1] == 1 and t.marks["AB"][1][0] == 1, "tick must cross row and column")


func test_cryptex(levels: Array) -> void:
	for i in levels.size():
		var d: Dictionary = levels[i]["puzzle"]
		if d["kind"] != "cryptex":
			continue
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		var pos := CryptexModel.start_positions(d, rng)
		check(CryptexModel.word(d, pos) != d["word"], "cryptex starts solved")
		for r in d["rings"].size():
			check(String(d["rings"][r]).contains(String(d["word"])[r]), "cryptex ring %d lacks its letter" % r)


func test_goods_water(levels: Array) -> void:
	for i in levels.size():
		var d: Dictionary = levels[i]["puzzle"]
		if d["kind"] == "water":
			var cap := int(d["capacity"])
			var tubes: Array = d["tubes"].duplicate()
			# greedy random playout: solvable boards should be reachable by search; here we just check legality helpers
			check(WaterModel.can_pour(["AB", ""], cap, 0, 1), "water: pour into empty")
			check(not WaterModel.can_pour(["AB", "A"], cap, 0, 1), "water: colour mismatch")
			check(WaterModel.pour(["AAB", "B"], 4, 0, 1) == ["AA", "BB"], "water: pour moves top run")
			check(tubes.size() >= 2, "water tubes")
			check(_water_solvable(tubes, cap), "water level %d is not solvable" % i)
		if d["kind"] == "goods":
			var racks := GoodsModel.init_racks(d)
			check(_goods_solvable(d, racks), "goods level %d is not solvable" % i)


func _water_solvable(start: Array, cap: int) -> bool:
	var seen := {}
	var stack := [start]
	while not stack.is_empty():
		var s: Array = stack.pop_back()
		var key := "|".join(s)
		if seen.has(key):
			continue
		seen[key] = true
		if WaterModel.solved(s, cap):
			return true
		if seen.size() > 200000:
			return false
		for a in s.size():
			for b in s.size():
				if WaterModel.can_pour(s, cap, a, b):
					stack.append(WaterModel.pour(s, cap, a, b))
	return false


func _goods_solvable(def: Dictionary, start: Array) -> bool:
	var cap := int(def["capacity"])
	var seen := {}
	var stack := [start]
	while not stack.is_empty():
		var s: Array = stack.pop_back()
		var key := "|".join(s.map(func(r: Array) -> String: return "".join(r)))
		if seen.has(key):
			continue
		seen[key] = true
		if GoodsModel.solved(def, s):
			return true
		if seen.size() > 300000:
			return false
		for a in s.size():
			if s[a].is_empty():
				continue
			for b in s.size():
				if a == b or s[b].size() >= cap:
					continue
				var t := []
				for r in s:
					t.append(r.duplicate())
				var card = t[a].pop_back()
				t[b].append(card)
				for r in t:
					if GoodsModel.is_full_match(r, cap):
						r.clear()
				stack.append(t)
	return false


func test_match3(levels: Array) -> void:
	for i in levels.size():
		var d: Dictionary = levels[i]["puzzle"]
		if d["kind"] != "match3":
			continue
		for seed_value in [7919 * 7, 12345, 99]:
			var m := Match3Model.create(d, seed_value)
			check(m.find_matches()["cells"].is_empty(), "match3 level %d starts with a match" % i)
			check(not m.has_move().is_empty(), "match3 level %d starts without a move" % i)
			var moves := 0
			var rng := RandomNumberGenerator.new()
			rng.seed = seed_value
			while m.static_left() > 0 and moves < 400:
				# play a random legal move
				var legal := []
				for a in m.n * m.n:
					for b in [a + 1, a + m.n]:
						if b < m.n * m.n and m.adjacent(a, b):
							m.swap_tiles(a, b)
							if not m.find_matches()["cells"].is_empty():
								legal.append([a, b])
							m.swap_tiles(a, b)
				if legal.is_empty():
					m.reshuffle()
					continue
				var mv: Array = legal[rng.randi_range(0, legal.size() - 1)]
				m.swap_tiles(mv[0], mv[1])
				while not m.step(mv).is_empty():
					mv = []
				if m.has_move().is_empty():
					m.reshuffle()
				moves += 1
			check(m.static_left() == 0, "match3 level %d: random play left static after %d moves" % [i, moves])
			print("match3 level %d seed %d cleared in %d random moves" % [i, seed_value, moves])


func test_blockfit_tilt(levels: Array) -> void:
	for i in levels.size():
		var d: Dictionary = levels[i]["puzzle"]
		if d["kind"] == "blockfit":
			var info := BlockFitModel.derive(d)
			check(info["pieces"].size() >= 3, "blockfit level %d has too few pieces" % i)
			# rotating four times returns the same shape
			for p in info["pieces"]:
				var s: Array = p["cells"]
				for _k in 4:
					s = BlockFitModel.rotate(s)
				check(BlockFitModel.same_shape(s, p["cells"]), "blockfit rotate x4 differs")
			# the solution places every piece
			var occ := {}
			for p in info["pieces"]:
				for cell in p["cells"]:
					pass
			var rows: Array = d["solution"]
			var filled := 0
			for line in rows:
				for ch in line:
					if ch != ".":
						filled += 1
			var total := 0
			for p in info["pieces"]:
				total += p["cells"].size()
			check(filled == total, "blockfit cell count mismatch")
		if d["kind"] == "tilt":
			var sol := TiltModel.solve(d["rows"])
			check(not sol.is_empty(), "tilt level %d unsolvable" % i)
			print("tilt level %d shortest solution: %d tilts" % [i, sol.size()])
		if d["kind"] == "box":
			for st in d["stages"]:
				if st["type"] == "tilt":
					check(not TiltModel.solve(st["rows"]).is_empty(), "box tilt stage unsolvable")


func test_panels(levels: Array) -> void:
	for i in levels.size():
		var d: Dictionary = levels[i]["puzzle"]
		if d["kind"] != "panels":
			continue
		var sols := PanelsModel.solutions(d)
		check(sols.size() >= 1, "panels level %d has no solution" % i)
		print("panels level %d: %d solution(s)" % [i, sols.size()])
		var rng := RandomNumberGenerator.new()
		rng.seed = 7919 * 4
		var st := PanelsModel.shuffled_start(d, rng)
		check(not PanelsModel.solved(d, st["slots"], st["views"]), "panels level %d starts solved" % i)


func test_box(levels: Array) -> void:
	for i in levels.size():
		var d: Dictionary = levels[i]["puzzle"]
		if d["kind"] != "box":
			continue
		for st in d["stages"]:
			match st["type"]:
				"levers":
					var sol := BoxModel.lever_solve(st["start"])
					check(not sol.is_empty(), "box level %d levers unsolvable" % i)
					print("box level %d levers: %d presses" % [i, sol.size()])
				"sliders":
					check(st["targets"].size() >= 2, "sliders targets")
				"dials":
					check(String(st["code"]).length() >= 2, "dials code")
				"patch":
					var seen := {}
					for p in st["pairs"]:
						check(not seen.has(p), "patch pairs must be a permutation")
						seen[p] = true


func test_hint_planners(levels: Array) -> void:
	for i in levels.size():
		var d: Dictionary = levels[i]["puzzle"]
		if d["kind"] == "water":
			check(not WaterModel.first_move(d["tubes"].duplicate(), int(d["capacity"])).is_empty(), "water level %d: no hint from the start" % i)
		if d["kind"] == "goods":
			check(not GoodsModel.suggest(d, GoodsModel.init_racks(d)).is_empty(), "goods level %d: no hint from the start" % i)
		if d["kind"] == "tilt":
			check(not TiltModel.solve(d["rows"], TiltModel.find(d["rows"], "S")).is_empty(), "tilt level %d: no hint from the start" % i)


func test_stakeout(levels: Array) -> void:
	var n := 0
	for i in levels.size():
		var d: Dictionary = levels[i]["puzzle"]
		if d["kind"] != "stakeout":
			continue
		n += 1
		var m := StakeoutModel.from_def(d)
		var sols := m.solutions(3)
		check(sols.size() == 1, "stakeout level %d has %d solutions, wants exactly 1" % [i, sols.size()])
		var zones := {}
		for r in m.n:
			for c in m.n:
				zones[m.zone[r][c]] = true
		check(zones.size() == m.n, "stakeout level %d: %d zones on a %d grid" % [i, zones.size(), m.n])
		if sols.size() == 1:
			for r in m.n:
				m.marks[r][int(sols[0][r])] = 2
			check(m.solved(), "stakeout level %d: the solution does not check" % i)
		print("stakeout level %d: %dx%d" % [i, m.n, m.n])
	check(n == 3, "expected 3 stakeout levels, found %d" % n)


func test_screws(levels: Array) -> void:
	var n := 0
	for i in levels.size():
		var d: Dictionary = levels[i]["puzzle"]
		if d["kind"] != "screws":
			continue
		n += 1
		var m := ScrewsModel.from_def(d)
		var per := {}
		for s in m.screws:
			per[s["color"]] = int(per.get(s["color"], 0)) + 1
		var want := {}
		for c in m.queue:
			want[c] = int(want.get(c, 0)) + 3
		check(per == want, "screws level %d: screw colours %s do not match the boxes %s" % [i, per, want])
		# play the solver's moves all the way through
		var moves := 0
		while not m.won() and moves < 200:
			var k := m.first_move()
			if k < 0:
				break
			m.take(k)
			moves += 1
		check(m.won(), "screws level %d cannot be cleared" % i)
		print("screws level %d: %d screws, cleared in %d moves" % [i, m.screws.size(), moves])
	check(n == 2, "expected 2 screws levels, found %d" % n)


func test_arrows(levels: Array) -> void:
	var n := 0
	for i in levels.size():
		var d: Dictionary = levels[i]["puzzle"]
		if d["kind"] != "arrows":
			continue
		n += 1
		var m := ArrowsModel.from_def(d)
		var seen := {}
		for a in m.arrows:
			check(a.size() >= 2, "arrows level %d: an arrow shorter than two squares" % i)
			for cell in a:
				check(not seen.has(cell), "arrows level %d: two arrows share a square" % i)
				seen[cell] = true
		var rounds := 0
		while not m.won() and rounds < 200:
			var free := m.free_arrows()
			if free.is_empty():
				break
			m.remove(free[0])
			rounds += 1
		check(m.won(), "arrows level %d cannot be cleared" % i)
		print("arrows level %d: %dx%d, %d arrows" % [i, m.w, m.h, m.arrows.size()])
	check(n == 2, "expected 2 arrows levels, found %d" % n)


func test_jam(levels: Array) -> void:
	var n := 0
	for i in levels.size():
		var d: Dictionary = levels[i]["puzzle"]
		if d["kind"] != "jam":
			continue
		n += 1
		var m := JamModel.from_def(d)
		var occ := {}
		for b in m.blocks.size():
			for c in m.cells_at(b, m.pos[b]):
				check(not occ.has(c), "jam level %d: blocks overlap" % i)
				occ[c] = true
		var path := m.solve(200000)
		check(not path.is_empty(), "jam level %d cannot be solved" % i)
		check(path.size() == int(d["par"]), "jam level %d: par %d but the solver finds %d" % [i, int(d["par"]), path.size()])
		for mv in path:
			var r := m.slide(mv[0], mv[1])
			m.pos[mv[0]] = null if r["out"] else r["end"]
		check(m.won(), "jam level %d: replaying the solution does not clear the board" % i)
		print("jam level %d: %dx%d, %d blocks, par %d" % [i, m.w, m.h, m.blocks.size(), path.size()])
	check(n == 2, "expected 2 jam levels, found %d" % n)
