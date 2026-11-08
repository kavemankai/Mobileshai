class_name StakeoutPuzzle
extends PuzzleBase
## Stakeout: one watcher in every row, column and coloured zone, none touching, corners included.
## Tap a square once for a cross, twice for a watcher. Drag across squares to cross out a run of them.

## Ten clearly different hues, so no two zones read as the same colour.
const ZONE_COLORS := [Color("6f9a4e"), Color("4a90c2"), Color("d1a14a"), Color("8d6bb8"), Color("3fa89a"),
	Color("c46a5a"), Color("c9c26a"), Color("d38fb0"), Color("8a8a8a"), Color("e08a3c")]

var m: StakeoutModel
var solution: Array = []
var board: StakeoutBoard


func build() -> void:
	m = StakeoutModel.from_def(def)
	var sols := m.solutions(1)
	solution = sols[0] if not sols.is_empty() else []
	var col := UI.vbox(8)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(col)
	col.add_child(UI.label(String(def.get("caption", "")), 12, UI.AMBER2, "mono_bold"))
	board = StakeoutBoard.new(self)
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI.qa(board, "stakeout.board")
	col.add_child(board)
	var rules := UI.hbox(6)
	for t in ["One per row and column", "One per zone", "Watchers can't touch"]:
		var chip := UI.panel(Color(UI.PANEL, 0.9), 8, UI.LINE, 1, 6)
		chip.add_child(UI.label(t, 11, UI.INK2, "sans", HORIZONTAL_ALIGNMENT_CENTER))
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rules.add_child(chip)
	col.add_child(rules)
	board.resized.connect(func() -> void:
		if board.size.x > 0.0:
			ask_height(board.size.x + 24.0 + 52.0 + 16.0))
	_status()


func _status() -> void:
	var placed := m.watchers().size()
	if not m.conflicts().is_empty():
		say("Two watchers clash. Check the red ones.")
	else:
		say("%d of %d watchers placed. Tap once for ✕, twice for a watcher. Drag to cross out." % [placed, m.n])


func changed() -> void:
	_status()
	if m.solved():
		sfx("solve")
		haptic(30)
		board.celebrate()
		finish(1300 if Fx.motion() else 300)


func board_hint(level: int) -> Dictionary:
	if solution.is_empty():
		return {}
	# a misplaced watcher first
	for w in m.watchers():
		if int(solution[w.x]) != w.y:
			return {"rects": [view_rect(board, board.cell_rect(w.x, w.y))], "text": "This watcher can't stay here."}
	# otherwise the zone with the fewest open squares, then its square
	var best_z := -1
	var best_n := 999
	for z in m.n:
		var done := false
		var open := 0
		for cell in m.cells_of_zone(z):
			if m.marks[cell.x][cell.y] == 2:
				done = true
			elif m.marks[cell.x][cell.y] == 0:
				open += 1
		if not done and open < best_n:
			best_n = open
			best_z = z
	if best_z < 0:
		return {}
	var target := Vector2i(-1, -1)
	for r in m.n:
		if m.zone[r][int(solution[r])] == best_z:
			target = Vector2i(r, int(solution[r]))
	if level < 2:
		var rects := []
		for cell in m.cells_of_zone(best_z):
			rects.append(view_rect(board, board.cell_rect(cell.x, cell.y)))
		return {"rects": rects, "text": "Work on this zone next: it has the least room."}
	return {"rects": [view_rect(board, board.cell_rect(target.x, target.y))], "text": "A watcher goes here."}


func ghost_move() -> Dictionary:
	# drag across the first row to show crossing out
	var a := view_rect(board, board.cell_rect(0, 0)).get_center()
	var b := view_rect(board, board.cell_rect(0, mini(2, m.n - 1))).get_center()
	return {"from": a, "to": b, "text": "Tap once for ✕, twice for a watcher. Drag across squares to cross them out."}


func qa_state() -> Dictionary:
	var cells := []
	for r in m.n:
		var row := []
		for c in m.n:
			row.append(QA.css(board, board.cell_rect(r, c).get_center()))
		cells.append(row)
	return {"kind": "stakeout", "n": m.n, "marks": m.marks.duplicate(true), "solution": solution, "cells": cells, "done": is_done()}


class StakeoutBoard extends Control:
	var p: StakeoutPuzzle
	var cell := 40.0
	var origin := Vector2.ZERO
	var pop := {}            # Vector2i -> 0..1 watcher scale-in
	var glow := 0.0:
		set(v):
			glow = v
			queue_redraw()
	var _down := Vector2i(-1, -1)
	var _dragging := false
	var _painted := {}
	var _font: Font

	func _init(puzzle: StakeoutPuzzle) -> void:
		p = puzzle
		mouse_filter = Control.MOUSE_FILTER_STOP
		_font = UI.font("mono_bold")
		resized.connect(_relayout)

	func _relayout() -> void:
		var n := p.m.n
		cell = floorf(minf(size.x, size.y) / n)
		origin = ((size - Vector2(cell * n, cell * n)) / 2.0).floor()
		queue_redraw()

	func cell_rect(r: int, c: int) -> Rect2:
		return Rect2(origin + Vector2(c, r) * cell, Vector2(cell, cell))

	func _at(pos: Vector2) -> Vector2i:
		var q := (pos - origin) / cell
		if q.x < 0 or q.y < 0 or q.x >= p.m.n or q.y >= p.m.n:
			return Vector2i(-1, -1)
		return Vector2i(int(q.y), int(q.x))

	func _gui_input(e: InputEvent) -> void:
		if p.is_done():
			return
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				_down = _at(e.position)
				_dragging = false
				_painted.clear()
			else:
				if not _dragging and _down.x >= 0 and _at(e.position) == _down:
					_tap(_down)
				_down = Vector2i(-1, -1)
				_dragging = false
		elif e is InputEventMouseMotion and _down.x >= 0:
			var at := _at(e.position)
			if at.x < 0:
				return
			if not _dragging and at != _down:
				_dragging = true
				_paint(_down)
			if _dragging:
				_paint(at)

	## A drag crosses out empty squares; it never removes a watcher.
	func _paint(at: Vector2i) -> void:
		if _painted.has(at):
			return
		_painted[at] = true
		if p.m.marks[at.x][at.y] == 0:
			p.m.marks[at.x][at.y] = 1
			Sound.sfx("tap", 0.08)
			queue_redraw()
			p.changed()

	func _tap(at: Vector2i) -> void:
		var v: int = (int(p.m.marks[at.x][at.y]) + 1) % 3
		p.m.marks[at.x][at.y] = v
		if v == 2:
			Sound.sfx("place")
			Fx.haptic(10)
			if Fx.motion():
				pop[at] = 0.0
				create_tween().tween_method(func(t: float) -> void:
					pop[at] = t
					queue_redraw(), 0.0, 1.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_zone_check(at)
		else:
			Sound.sfx("tap", 0.05)
		queue_redraw()
		p.changed()

	func _zone_check(at: Vector2i) -> void:
		if p.m.conflicts().has(at):
			Sound.sfx("invalid")
			Fx.haptic(16)

	func celebrate() -> void:
		if Fx.motion():
			create_tween().tween_property(self, "glow", 1.0, 0.7)
			Fx.burst(self, size / 2.0, UI.AMBER2, 30, 280.0, 5.0)
		else:
			glow = 1.0

	func _draw() -> void:
		var n := p.m.n
		if cell < 8.0:
			return
		var bad := p.m.conflicts()
		for r in n:
			for c in n:
				var rect := cell_rect(r, c)
				var z: int = p.m.zone[r][c]
				var col: Color = StakeoutPuzzle.ZONE_COLORS[z % StakeoutPuzzle.ZONE_COLORS.size()]
				draw_rect(rect, col.darkened(0.25).lerp(Color.WHITE, glow * 0.15))
				draw_rect(rect, Color(0, 0, 0, 0.25), false, 1.0)
				var v: int = p.m.marks[r][c]
				var ctr := rect.get_center()
				if v == 1:
					var a := cell * 0.16
					draw_line(ctr + Vector2(-a, -a), ctr + Vector2(a, a), Color(0, 0, 0, 0.55), maxf(2.0, cell * 0.06), true)
					draw_line(ctr + Vector2(a, -a), ctr + Vector2(-a, a), Color(0, 0, 0, 0.55), maxf(2.0, cell * 0.06), true)
				elif v == 2:
					var s: float = float(pop.get(Vector2i(r, c), 1.0))
					var rad := cell * 0.34 * s
					var ring := UI.RED if bad.has(Vector2i(r, c)) else Color("f4ead2")
					draw_circle(ctr, rad, Color(0.06, 0.08, 0.1))
					draw_arc(ctr, rad, 0.0, TAU, 28, ring, maxf(2.0, cell * 0.07), true)
					# an eye: the watcher
					draw_circle(ctr, rad * 0.45, ring)
					draw_circle(ctr, rad * 0.2, Color(0.06, 0.08, 0.1))
		# thick borders between zones
		var bw := maxf(2.5, cell * 0.08)
		for r in n:
			for c in n:
				var z: int = p.m.zone[r][c]
				var rect := cell_rect(r, c)
				if c + 1 < n and p.m.zone[r][c + 1] != z:
					draw_line(Vector2(rect.end.x, rect.position.y), rect.end, UI.BG, bw)
				if r + 1 < n and p.m.zone[r + 1][c] != z:
					draw_line(Vector2(rect.position.x, rect.end.y), rect.end, UI.BG, bw)
		draw_rect(Rect2(origin, Vector2(cell * n, cell * n)), UI.BG, false, bw)
		# zone letters, small, so colour is never the only cue
		for z in n:
			var cells := p.m.cells_of_zone(z)
			if cells.is_empty():
				continue
			var first: Vector2i = cells[0]
			var rr := cell_rect(first.x, first.y)
			draw_string(_font, rr.position + Vector2(4, 12), String.chr(65 + z), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.55))
