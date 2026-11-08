class_name ArrowsPuzzle
extends PuzzleBase
## Arrows: tap an arrow and it slides off the board the way it points, if nothing is in its path.
## A blocked arrow slides up to whatever is in the way, bumps it, and comes back. Misses cost nothing.

const TINTS := [Color("e3d6ba"), Color("cdb88f"), Color("d9c7a6"), Color("bfa985"), Color("e8dcc4")]

var m: ArrowsModel
var board: ArrowsBoard
var misses := 0


func build() -> void:
	m = ArrowsModel.from_def(def)
	var col := UI.vbox(8)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(col)
	col.add_child(UI.label(String(def.get("caption", "")), 12, UI.AMBER2, "mono_bold"))
	board = ArrowsBoard.new(self)
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI.qa(board, "arrows.board")
	col.add_child(board)
	board.resized.connect(func() -> void:
		if board.size.x > 0.0:
			ask_height(board.size.x * float(m.h) / float(m.w) + 30.0 + 16.0))
	_status()


func _status() -> void:
	say("%d of %d cleared." % [m.gone.size(), m.arrows.size()])


func tap(i: int) -> void:
	if is_done() or board.busy:
		return
	var b := m.blocker(i)
	if int(b[0]) >= 0:
		misses += 1
		sfx("invalid")
		haptic(14)
		say("Blocked. Something is in the way.")
		await board.bump(i, int(b[1]), int(b[0]))
		return
	sfx("swap", 0.05)
	haptic(6)
	await board.slide_out(i)
	m.remove(i)
	_status()
	if m.won():
		sfx("solve")
		haptic(30)
		board.celebrate()
		finish(1000 if Fx.motion() else 300)


func board_hint(level: int) -> Dictionary:
	var free := m.free_arrows()
	if free.is_empty():
		return {}
	free.sort_custom(func(a: int, b: int) -> bool: return m.unlocks(a) > m.unlocks(b))
	var i: int = free[0]
	var rects := [view_rect(board, board.arrow_rect(i))]
	if level >= 2:
		for j in m.arrows.size():
			if not m.gone.has(j) and j != i and m.blocker(j)[0] == i:
				rects.append(view_rect(board, board.arrow_rect(j)))
		return {"rects": rects, "text": "This one is clear, and it frees the teal ones."}
	return {"rects": rects, "text": "This one has a clear path."}


func ghost_move() -> Dictionary:
	var free := m.free_arrows()
	if free.is_empty():
		return {}
	var a := view_rect(board, board.cell_rect(m.arrows[free[0]][-1])).get_center()
	return {"from": a, "to": a, "text": "Tap an arrow to slide it off the way it points. Its path must be clear."}


func qa_state() -> Dictionary:
	var pts := []
	for i in m.arrows.size():
		pts.append(QA.css(board, board.cell_rect(m.arrows[i][-1]).get_center()))
	return {"kind": "arrows", "free": m.free_arrows(), "gone": m.gone.keys(), "pts": pts, "busy": board.busy,
		"count": m.arrows.size(), "done": is_done()}


class ArrowsBoard extends Control:
	var p: ArrowsPuzzle
	var cell := 40.0
	var origin := Vector2.ZERO
	var busy := false
	var shift := {}         # arrow -> squares moved along its line (can be fractional)
	var fade := {}          # arrow -> alpha
	var shake := {}
	var glow := 0.0:
		set(v):
			glow = v
			queue_redraw()

	func _init(puzzle: ArrowsPuzzle) -> void:
		p = puzzle
		mouse_filter = Control.MOUSE_FILTER_STOP
		resized.connect(_relayout)

	func _relayout() -> void:
		cell = floorf(minf(size.x / p.m.w, size.y / p.m.h))
		origin = ((size - Vector2(cell * p.m.w, cell * p.m.h)) / 2.0).floor()
		queue_redraw()

	func _process(_d: float) -> void:
		if busy or not shake.is_empty():
			queue_redraw()

	func cell_rect(rc: Vector2i) -> Rect2:
		return Rect2(origin + Vector2(rc.y, rc.x) * cell, Vector2(cell, cell))

	func arrow_rect(i: int) -> Rect2:
		var r := Rect2()
		var first := true
		for c in p.m.arrows[i]:
			r = cell_rect(c) if first else r.merge(cell_rect(c))
			first = false
		return r

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			var q: Vector2 = (e.position - origin) / cell
			var rc := Vector2i(int(floorf(q.y)), int(floorf(q.x)))
			var o := p.m.owner_map()
			if o.has(rc):
				p.tap(o[rc])

	## Where a point `s` squares along arrow i's path-plus-line sits: the body follows the head like a snake.
	func _point_along(i: int, s: float) -> Vector2:
		var path: Array = p.m.arrows[i]
		var d := p.m.dir_of(i)
		var n := path.size()
		if s <= n - 1:
			var k := int(floorf(s))
			var f := s - k
			var a := cell_rect(path[k]).get_center()
			var b := cell_rect(path[mini(k + 1, n - 1)]).get_center()
			return a.lerp(b, f)
		return cell_rect(path[-1]).get_center() + Vector2(d.y, d.x) * cell * (s - (n - 1))

	func slide_out(i: int) -> void:
		if not Fx.motion():
			return
		busy = true
		var dist := float(p.m.ray(i).size() + p.m.arrows[i].size() + 1)
		var tw := create_tween()
		tw.tween_method(func(v: float) -> void:
			shift[i] = v
			fade[i] = clampf(1.0 - (v - dist * 0.6) / (dist * 0.4), 0.0, 1.0)
			queue_redraw(), 0.0, dist, 0.08 * dist + 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tw.finished
		shift.erase(i)
		fade.erase(i)
		busy = false

	func bump(i: int, free_steps: int, blocker_i: int) -> void:
		if not Fx.motion():
			return
		busy = true
		var go := float(free_steps) + 0.25
		var tw := create_tween()
		tw.tween_method(func(v: float) -> void:
			shift[i] = v
			queue_redraw(), 0.0, go, 0.06 * go + 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(func() -> void: shake[blocker_i] = 1.0)
		tw.tween_method(func(v: float) -> void:
			shift[i] = v
			if shake.has(blocker_i):
				shake[blocker_i] = v / go
			queue_redraw(), go, 0.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await tw.finished
		shift.erase(i)
		shake.erase(blocker_i)
		busy = false

	func celebrate() -> void:
		if Fx.motion():
			create_tween().tween_property(self, "glow", 1.0, 0.6)
			Fx.burst(self, size / 2.0, UI.AMBER2, 26, 260.0, 4.0)

	func _draw() -> void:
		if cell < 6.0:
			return
		var board_r := Rect2(origin, Vector2(cell * p.m.w, cell * p.m.h))
		draw_style_box(UI.flat(Color("15232b"), 12, UI.LINE.lerp(UI.AMBER2, glow), 1, 0), board_r.grow(6.0))
		for r in p.m.h:
			for c in p.m.w:
				draw_circle(cell_rect(Vector2i(r, c)).get_center(), 1.5, Color(1, 1, 1, 0.08))
		for i in p.m.arrows.size():
			if p.m.gone.has(i):
				continue
			var path: Array = p.m.arrows[i]
			var n := path.size()
			var s: float = float(shift.get(i, 0.0))
			var a: float = float(fade.get(i, 1.0))
			var jig := Vector2(sin(Time.get_ticks_msec() * 0.08) * 3.0 * float(shake.get(i, 0.0)), 0)
			var pts := PackedVector2Array()
			for k in 9 * (n - 1) + 1:
				pts.append(_point_along(i, s + k / 9.0) + jig)
			var col: Color = ArrowsPuzzle.TINTS[i % ArrowsPuzzle.TINTS.size()]
			var wdt := cell * 0.32
			draw_polyline(pts, Color(0, 0, 0, 0.35 * a), wdt + 4.0, true)
			draw_polyline(pts, Color(col, a), wdt, true)
			draw_circle(pts[0], wdt * 0.5, Color(col, a))
			# the head
			var d := p.m.dir_of(i)
			var dv := Vector2(d.y, d.x)
			var tip := pts[pts.size() - 1] + dv * cell * 0.28
			var side := Vector2(-dv.y, dv.x) * cell * 0.26
			var base := pts[pts.size() - 1] - dv * cell * 0.02
			draw_colored_polygon(PackedVector2Array([tip, base + side, base - side]), Color(col.darkened(0.15), a))
