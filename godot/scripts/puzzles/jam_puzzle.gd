class_name JamPuzzle
extends PuzzleBase
## Jam: drag the blocks. Each one leaves through a gap in the wall of its own colour, if the gap is wide enough.

var m: JamModel
var board: JamBoard
var moves := 0


func build() -> void:
	m = JamModel.from_def(def)
	var col := UI.vbox(8)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(col)
	col.add_child(UI.label(String(def.get("caption", "")), 12, UI.AMBER2, "mono_bold"))
	board = JamBoard.new(self)
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI.qa(board, "jam.board")
	col.add_child(board)
	board.resized.connect(func() -> void:
		if board.size.x > 0.0:
			ask_height(board.size.x * float(m.h + 1) / float(m.w + 1) + 30.0 + 16.0))
	_status()


func color_of(id: String) -> Color:
	return Color(def["colors"].get(id, "#cccccc"))


func _status() -> void:
	var left := 0
	for p in m.pos:
		if p != null:
			left += 1
	say("%d left · %d moves (par %d)" % [left, moves, int(def.get("par", 0))])


func moved_once() -> void:
	moves += 1
	_status()


func block_left() -> void:
	_status()
	if m.won():
		sfx("solve")
		haptic(30)
		board.celebrate()
		finish(1000 if Fx.motion() else 300)


func board_hint(level: int) -> Dictionary:
	var path := m.solve(40000)
	if path.is_empty():
		return {"text": "This is stuck. Reset and try a different order."}
	var i: int = path[0][0]
	var d: String = path[0][1]
	var names := {"U": "up", "D": "down", "L": "left", "R": "right"}
	var rects := [view_rect(board, board.block_rect(i))]
	if level < 2:
		return {"rects": rects, "text": "Move this one next."}
	return {"rects": rects, "text": "Slide it %s." % names[d]}


func ghost_move() -> Dictionary:
	var path := m.solve(20000)
	if path.is_empty():
		return {}
	var i: int = path[0][0]
	var d: Vector2i = JamModel.DIRS[path[0][1]]
	var a := view_rect(board, board.block_rect(i)).get_center()
	return {"from": a, "to": a + Vector2(d.y, d.x) * board.cell * 1.5, "text": "Drag a block. It leaves through the gap of its colour."}


func qa_state() -> Dictionary:
	var centers := []
	for i in m.blocks.size():
		centers.append(QA.css(board, board.block_rect(i).get_center()) if m.pos[i] != null else null)
	return {"kind": "jam", "centers": centers, "cell_css": board.cell, "busy": board.busy,
		"solution": m.solve(40000) if not board.busy else [], "done": is_done()}


class JamBoard extends Control:
	var p: JamPuzzle
	var cell := 40.0
	var origin := Vector2.ZERO
	var draw_off := {}      # block -> pixel offset (animated) from its grid position
	var leaving := {}       # block -> {pos, dir, t}
	var busy := false
	var _drag := -1
	var _anchor := Vector2.ZERO
	var _moved := false
	var _bumped := false
	var glow := 0.0:
		set(v):
			glow = v
			queue_redraw()

	func _init(puzzle: JamPuzzle) -> void:
		p = puzzle
		mouse_filter = Control.MOUSE_FILTER_STOP
		resized.connect(_relayout)

	func _relayout() -> void:
		cell = floorf(minf(size.x / (p.m.w + 0.8), size.y / (p.m.h + 0.8)))
		origin = ((size - Vector2(cell * p.m.w, cell * p.m.h)) / 2.0).floor()
		queue_redraw()

	func _process(_d: float) -> void:
		if not leaving.is_empty() or not draw_off.is_empty():
			queue_redraw()

	func grid_rect(rc: Vector2i) -> Rect2:
		return Rect2(origin + Vector2(rc.y, rc.x) * cell, Vector2(cell, cell))

	func block_rect(i: int) -> Rect2:
		var r := Rect2()
		var first := true
		if p.m.pos[i] == null:
			return r
		for c in p.m.cells_at(i, p.m.pos[i]):
			r = grid_rect(c) if first else r.merge(grid_rect(c))
			first = false
		return r

	func _block_at(pt: Vector2) -> int:
		var q: Vector2 = (pt - origin) / cell
		var rc := Vector2i(int(floorf(q.y)), int(floorf(q.x)))
		var o := p.m.occupancy()
		return o.get(rc, -1)

	func _gui_input(e: InputEvent) -> void:
		if p.is_done():
			return
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				_drag = _block_at(e.position)
				_anchor = e.position
				_moved = false
				_bumped = false
				if _drag >= 0:
					Sound.sfx("pick")
			else:
				if _drag >= 0 and _moved:
					p.moved_once()
				_drag = -1
		elif e is InputEventMouseMotion and _drag >= 0:
			var delta: Vector2 = e.position - _anchor
			var guard := 0
			while _drag >= 0 and guard < 20:
				guard += 1
				var d := ""
				if absf(delta.x) >= absf(delta.y) and absf(delta.x) > cell * 0.5:
					d = "R" if delta.x > 0 else "L"
				elif absf(delta.y) > cell * 0.5:
					d = "D" if delta.y > 0 else "U"
				if d == "":
					break
				var res := p.m.step(_drag, d)
				var dv := Vector2(JamModel.DIRS[d].y, JamModel.DIRS[d].x)
				if res == "moved":
					_moved = true
					_bumped = false
					_anchor += dv * cell
					delta -= dv * cell
					Sound.sfx("tap", 0.06)
					_nudge(_drag, -dv * cell)
				elif res == "out":
					_moved = true
					var i := _drag
					_drag = -1
					p.moved_once()
					_leave(i, dv)
					break
				else:
					if not _bumped:
						_bumped = true
						Sound.sfx("place")
						Fx.haptic(6)
					_anchor += dv * (absf(delta.dot(dv)) - cell * 0.45)
					break
			queue_redraw()

	## Show the block easing into its new square rather than jumping.
	func _nudge(i: int, from_off: Vector2) -> void:
		if not Fx.motion():
			return
		draw_off[i] = from_off
		var tw := create_tween()
		tw.tween_method(func(v: Vector2) -> void:
			draw_off[i] = v
			queue_redraw(), from_off, Vector2.ZERO, 0.08)
		tw.tween_callback(func() -> void: draw_off.erase(i))

	func _leave(i: int, dv: Vector2) -> void:
		var cells := []
		for c in p.m.blocks[i]["shape"]:
			cells.append(c)
		var last_pos := Vector2.ZERO
		# where it was: the model has already removed it, so remember its last cells from the shape and direction
		Sound.sfx("clear")
		Fx.haptic(14)
		if Fx.motion():
			busy = true
			leaving[i] = {"t": 0.0, "dir": dv, "rect": _last_rect.get(i, Rect2())}
			var tw := create_tween()
			tw.tween_method(func(v: float) -> void:
				leaving[i]["t"] = v
				queue_redraw(), 0.0, 1.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.tween_callback(func() -> void:
				Fx.burst(self, _last_rect.get(i, Rect2()).get_center() + dv * cell * 1.2, p.color_of(String(p.m.blocks[i]["color"])), 16, 200.0, 4.0)
				leaving.erase(i)
				busy = false
				p.block_left())
		else:
			p.block_left()

	var _last_rect := {}

	func celebrate() -> void:
		if Fx.motion():
			create_tween().tween_property(self, "glow", 1.0, 0.6)

	func _draw() -> void:
		if cell < 6.0:
			return
		var W := p.m.w
		var H := p.m.h
		var full := Rect2(origin, Vector2(W, H) * cell)
		var wall := maxf(6.0, cell * 0.16)
		draw_rect(full.grow(wall), Color("2b3a42"))
		draw_rect(full, Color("16232a"))
		for r in H:
			for c in W:
				draw_rect(grid_rect(Vector2i(r, c)).grow(-1.0), Color(1, 1, 1, 0.03 + 0.04 * glow))
		# gates: coloured gaps in the wall
		for g in p.m.gates:
			var col := p.color_of(String(g["color"]))
			var at := int(g["at"])
			var ln := int(g["len"])
			var gr := Rect2()
			match String(g["side"]):
				"N": gr = Rect2(origin + Vector2(at * cell, -wall), Vector2(ln * cell, wall))
				"S": gr = Rect2(origin + Vector2(at * cell, H * cell), Vector2(ln * cell, wall))
				"W": gr = Rect2(origin + Vector2(-wall, at * cell), Vector2(wall, ln * cell))
				"E": gr = Rect2(origin + Vector2(W * cell, at * cell), Vector2(wall, ln * cell))
			draw_rect(gr, col)
			draw_rect(gr, col.lightened(0.3), false, 1.5)
		# blocks
		for i in p.m.blocks.size():
			var col := p.color_of(String(p.m.blocks[i]["color"]))
			if p.m.pos[i] == null:
				if leaving.has(i):
					var lv: Dictionary = leaving[i]
					var rr: Rect2 = lv["rect"]
					var t: float = lv["t"]
					var off: Vector2 = lv["dir"] * cell * 1.6 * t
					var sc := 1.0 - 0.6 * t
					var rr2 := Rect2(rr.get_center() + off - rr.size * sc / 2.0, rr.size * sc)
					draw_style_box(UI.flat(Color(col, 1.0 - t), cell * 0.18, Color(0, 0, 0, 0), 0, 0), rr2)
				continue
			var off2: Vector2 = draw_off.get(i, Vector2.ZERO)
			_last_rect[i] = block_rect(i)
			for c in p.m.cells_at(i, p.m.pos[i]):
				var r := grid_rect(c).grow(-2.0)
				r.position += off2
				var sb := UI.flat(col, cell * 0.16, col.darkened(0.35), 2, 0)
				sb.shadow_color = Color(0, 0, 0, 0.35)
				sb.shadow_size = 3
				sb.shadow_offset = Vector2(0, 2)
				draw_style_box(sb, r)
				draw_rect(Rect2(r.position + Vector2(r.size.x * 0.18, r.size.y * 0.14), Vector2(r.size.x * 0.64, r.size.y * 0.12)), Color(1, 1, 1, 0.25))
			# join the squares of one block so it reads as one piece
			for c in p.m.cells_at(i, p.m.pos[i]):
				for nb in [Vector2i(0, 1), Vector2i(1, 0)]:
					if p.m.cells_at(i, p.m.pos[i]).has(c + nb):
						var a := grid_rect(c).get_center() + off2
						var b := grid_rect(c + nb).get_center() + off2
						draw_line(a, b, col, cell * 0.6)
		# a dark seam wherever two different blocks touch, so same-coloured neighbours read as two pieces
		var occ := p.m.occupancy()
		for rc in occ:
			for nb in [Vector2i(0, 1), Vector2i(1, 0)]:
				var o: Vector2i = rc + nb
				if occ.has(o) and occ[o] != occ[rc] and not draw_off.has(occ[rc]) and not draw_off.has(occ[o]):
					var r1 := grid_rect(rc)
					if nb.y == 1:
						draw_line(Vector2(r1.end.x, r1.position.y + 3), Vector2(r1.end.x, r1.end.y - 3), Color(0.05, 0.08, 0.1), 3.0)
					else:
						draw_line(Vector2(r1.position.x + 3, r1.end.y), Vector2(r1.end.x - 3, r1.end.y), Color(0.05, 0.08, 0.1), 3.0)
