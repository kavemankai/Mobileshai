class_name ZipPuzzle
extends PuzzleBase
## Path: one line through the numbers in order, covering every open square.
## The line glides after the finger, retracts when you back up, and lights up end to end on a solve.

var m: ZipModel
var _board: ZipBoard
var _legend: Label


func build() -> void:
	m = ZipModel.from_def(def)
	var col := UI.vbox(8)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(col)
	_board = ZipBoard.new(self, m, def)
	_board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(_board)
	if def.has("markLabels"):
		var parts := []
		for k in def["markLabels"].size():
			parts.append("%d %s" % [k + 1, def["markLabels"][k]])
		_legend = UI.label("  ·  ".join(parts), 12, UI.INK2, "mono", HORIZONTAL_ALIGNMENT_CENTER)
		col.add_child(_legend)
	if def.has("wallLabels"):
		var seen := {}
		for k in def["wallLabels"]:
			seen[String(def["wallLabels"][k]).to_lower()] = true
		col.add_child(UI.label("Blocked: " + ", ".join(seen.keys()), 12, UI.MUTE, "mono", HORIZONTAL_ALIGNMENT_CENTER))
	UI.qa(_board, "zip.board")
	_update_status()


func _update_status() -> void:
	var p := _board.path
	if p.is_empty():
		say("Start on 1. Drag, or tap neighbouring squares.")
	else:
		say("%d of %d squares · next number: %d" % [p.size(), m.open_count, mini(m.reached(p) + 1, m.mark_count)])


func board_hint(level: int) -> Dictionary:
	var p: Array = _board.path
	var k := 0
	while k < p.size() and k < m.solution.size() and p[k] == m.solution[k]:
		k += 1
	if k >= m.solution.size():
		return {}
	var rects := []
	var text := ""
	if k < p.size():
		# the line went wrong after square k-1: point back to the last good square
		rects.append(view_rect(_board, _board.cell_rect(m.solution[maxi(k - 1, 0)])))
		text = "The line goes wrong after the glowing square. Back up to it."
		if level >= 2:
			rects.append(view_rect(_board, _board.cell_rect(m.solution[k])))
			text = "Back up to the glowing square, then go to the teal one."
	else:
		var upto := 1 if level < 2 else 3
		for j in range(k, mini(k + upto, m.solution.size())):
			rects.append(view_rect(_board, _board.cell_rect(m.solution[j])))
		text = "Try here next." if level < 2 else "The next few squares, in order."
	return {"rects": rects, "text": text}

func qa_state() -> Dictionary:
	var cells := []
	var b := _board
	for i in m.rows * m.cols:
		var r := b.cell_rect(i)
		var gp: Array = QA.css(b, r.get_center())
		cells.append([i, gp[0], gp[1]])
	return {"kind": "zip", "path": _board.path.duplicate(), "solution": m.solution.duplicate(), "cells": cells,
		"cell_size": b.cell_size, "done": is_done()}


## The board: custom-drawn so the trail, glow and cell pops are all driven by one set of tweened values.
class ZipBoard extends Control:
	var owner_p: ZipPuzzle
	var m: ZipModel
	var def: Dictionary
	var path: Array = []
	var cell_size := 40.0
	var origin := Vector2.ZERO
	var pop: Array = []         # 0..1 per cell, scale-in of a cell as the line enters it
	var head := Vector2.ZERO    # smoothed head of the line, in board space
	var head_tw: Tween
	var flash := -1.0           # solve wave position along the path
	var pulse := 0.0
	var _dragging := false
	var _solved := false
	var _num_font: Font

	func _init(o: ZipPuzzle, model: ZipModel, d: Dictionary) -> void:
		owner_p = o
		m = model
		def = d
		mouse_filter = Control.MOUSE_FILTER_STOP
		clip_contents = false
		pop.resize(m.rows * m.cols)
		pop.fill(0.0)
		_num_font = UI.font("sans_bold")
		resized.connect(_relayout)
		focus_mode = Control.FOCUS_NONE

	func _ready() -> void:
		_relayout()
		if Fx.motion():
			var tw := create_tween().set_loops()
			tw.tween_property(self, "pulse", 1.0, 0.9).set_trans(Tween.TRANS_SINE)
			tw.tween_property(self, "pulse", 0.0, 0.9).set_trans(Tween.TRANS_SINE)

	func _process(_d: float) -> void:
		queue_redraw()

	func _relayout() -> void:
		cell_size = floorf(minf(size.x / m.cols, size.y / m.rows))
		var bs := Vector2(cell_size * m.cols, cell_size * m.rows)
		origin = ((size - bs) / 2.0).floor()
		if not path.is_empty():
			head = center_of(path[-1])

	func cell_rect(i: int) -> Rect2:
		return Rect2(origin + Vector2(i % m.cols, i / m.cols) * cell_size, Vector2(cell_size, cell_size))

	func center_of(i: int) -> Vector2:
		return cell_rect(i).get_center()

	func _cell_at(p: Vector2) -> int:
		var q := (p - origin) / cell_size
		if q.x < 0 or q.y < 0 or q.x >= m.cols or q.y >= m.rows:
			return -1
		return int(q.y) * m.cols + int(q.x)

	func _gui_input(e: InputEvent) -> void:
		if _solved:
			return
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				var i := _cell_at(e.position)
				if i < 0:
					return
				_dragging = true
				if not path.is_empty() and i == path[-1]:
					return
				_touch(i, false)
			else:
				_dragging = false
		elif e is InputEventMouseMotion and _dragging:
			var i := _cell_at(e.position)
			if i < 0 or (not path.is_empty() and i == path[-1]):
				return
			_touch(i, true)

	func _move_head(to: Vector2) -> void:
		if head_tw:
			head_tw.kill()
		if not Fx.motion():
			head = to
			return
		head_tw = create_tween()
		head_tw.tween_property(self, "head", to, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	func _pop_cell(i: int) -> void:
		if not Fx.motion():
			pop[i] = 1.0
			return
		pop[i] = 0.0
		var tw := create_tween()
		tw.tween_method(func(v: float) -> void: pop[i] = v, 0.0, 1.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	func _touch(i: int, from_drag: bool) -> void:
		var at := path.find(i)
		if at >= 0:
			if from_drag and at == path.size() - 2:
				var gone: int = path.pop_back()
				pop[gone] = 0.0
				owner_p.sfx("tap")
				_move_head(center_of(path[-1]))
			elif not from_drag:
				for k in range(at + 1, path.size()):
					pop[path[k]] = 0.0
				path = path.slice(0, at + 1)
				owner_p.sfx("tap")
				_move_head(center_of(path[-1]))
			owner_p._update_status()
			return
		if m.can_extend(path, i):
			if path.is_empty():
				head = center_of(i)
			path.append(i)
			_pop_cell(i)
			_move_head(center_of(i))
			owner_p.sfx("click" if m.mark_at.has(i) else "tap", 0.04)
			owner_p.haptic(8 if m.mark_at.has(i) else 4)
			if m.mark_at.has(i):
				Fx.burst(self, center_of(i), UI.AMBER2, 8, 110.0, 3.0)
			owner_p._update_status()
			if m.solved(path):
				_win()
		elif not from_drag:
			if path.is_empty():
				owner_p.say("Start on the square marked 1.")
			elif m.mark_at.has(i):
				owner_p.say("Numbers have to be reached in order, and the last number ends the line.")
			owner_p.sfx("invalid")
			if m.open[i] or m.mark_at.has(i):
				Fx.shake(self, 4.0, 0.2)

	func _win() -> void:
		_solved = true
		owner_p.sfx("power")
		owner_p.haptic(30)
		if Fx.motion():
			var n := path.size()
			var tw := create_tween()
			tw.tween_method(func(v: float) -> void: flash = v, 0.0, float(n) + 3.0, 0.9)
			tw.tween_callback(func() -> void:
				Fx.burst(self, center_of(path[-1]), UI.AMBER2, 36, 320.0, 5.0))
		owner_p.finish(1300 if Fx.motion() else 300)

	func _draw() -> void:
		if cell_size < 8.0:
			return
		var r := cell_size * 0.14
		var solved_glow := 0.0
		if _solved:
			solved_glow = 1.0
		for i in m.rows * m.cols:
			var rect := cell_rect(i).grow(-cell_size * 0.05)
			if not m.open[i]:
				draw_rect(rect, Color(UI.BG, 0.0), false)
				continue
			var idx := path.find(i)
			var on := idx >= 0
			var base := UI.PANEL2 if not on else UI.PANEL2.lerp(UI.AMBER, 0.28 * float(pop[i]))
			var s := 1.0 if not on else 1.0 + 0.06 * sin(PI * clampf(float(pop[i]), 0.0, 1.0))
			var rr := Rect2(rect.get_center() - rect.size * s / 2.0, rect.size * s)
			var fl := 0.0
			if flash >= 0.0 and on:
				fl = clampf(1.0 - absf(float(idx) - flash) / 3.0, 0.0, 1.0)
			draw_style_box(UI.flat(base.lerp(UI.AMBER2, fl * 0.7), r, UI.LINE.lerp(UI.AMBER, 0.6 if on else 0.0), 1), rr)
		# the trail
		if path.size() >= 1:
			var pts := PackedVector2Array()
			for k in path.size() - 1:
				pts.append(center_of(path[k]))
			pts.append(head if Fx.motion() else center_of(path[-1]))
			var w := cell_size * 0.3
			var col := UI.AMBER2 if not _solved else UI.AMBER2.lerp(Color.WHITE, 0.25)
			if pts.size() > 1:
				draw_polyline(pts, Color(col, 0.16 + 0.08 * pulse), w * 1.9, true)
				draw_polyline(pts, Color(col, 0.9), w, true)
				draw_polyline(pts, Color(1, 1, 1, 0.28), w * 0.32, true)
				for p in pts:
					draw_circle(p, w * 0.5, Color(col, 0.9))
			var hp: Vector2 = pts[-1]
			draw_circle(hp, w * (0.62 + 0.1 * pulse), Color(UI.AMBER2, 0.35))
			draw_circle(hp, w * 0.42, Color("fff3d2"))
		# numbers
		for i in m.mark_at:
			var c := center_of(i)
			var k: int = m.mark_at[i]
			var reached := path.has(i)
			var rad := cell_size * 0.3
			draw_circle(c, rad, UI.DARK_INK if reached else UI.BG)
			draw_arc(c, rad, 0.0, TAU, 28, UI.AMBER2 if reached else UI.INK2, 2.0, true)
			var txt := str(k + 1)
			var fsz := int(cell_size * 0.34)
			var ts := _num_font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz)
			draw_string(_num_font, c + Vector2(-ts.x / 2.0, ts.y * 0.28), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, UI.AMBER2 if reached else UI.INK)
