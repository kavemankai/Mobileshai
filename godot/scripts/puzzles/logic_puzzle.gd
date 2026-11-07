class_name LogicPuzzle
extends PuzzleBase
## Deduction grid. Tap a cell: cross, then tick. A tick rules out the rest of its row and column,
## and the crosses spread one after another.

var m: LogicModel
var grid: LogicGrid
var _accuse := VBoxContainer.new()
var _scroll := ScrollContainer.new()
var _grid_done := false


func build() -> void:
	m = LogicModel.new(def["categories"][0]["items"].size())
	_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	var col := UI.vbox(8)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(col)
	var lines := []
	for i in def["clues"].size():
		lines.append("%d. %s" % [i + 1, def["clues"][i]["text"]])
	col.add_child(UI.label("\n".join(lines), 12, UI.INK2))
	grid = LogicGrid.new(self, m, def)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI.qa(grid, "logic.grid")
	col.add_child(grid)
	_accuse.visible = false
	_accuse.add_theme_constant_override("separation", 6)
	col.add_child(_accuse)
	col.add_child(UI.spacer(36))
	say("Tap once for ✗, twice for ✓. A ✓ rules out the rest of its row and column.")


func cell_changed() -> void:
	if _grid_done or not m.correct(def):
		return
	_grid_done = true
	sfx("power")
	haptic(24)
	grid.celebrate()
	if def.has("accuse"):
		get_tree().create_timer(0.9 if Fx.motion() else 0.0).timeout.connect(_show_accuse)
	else:
		finish(1200 if Fx.motion() else 300)


func _show_accuse() -> void:
	var acc: Dictionary = def["accuse"]
	_accuse.visible = true
	_accuse.add_child(UI.label(String(acc["prompt"]), 16, UI.PAPER, "serif_bold"))
	var row := UI.hbox(6)
	var items: Array = def["categories"][0]["items"]
	for i in items.size():
		var b := FxButton.new(String(items[i]))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void: _accuse_pick(i, b))
		UI.qa(b, "logic.accuse.%d" % i)
		row.add_child(b)
	_accuse.add_child(row)
	Fx.fade_in(_accuse, 0.4)
	await get_tree().process_frame
	await get_tree().process_frame
	_scroll.scroll_vertical = 9999
	say("The grid is complete. Now make the call.")


func _accuse_pick(i: int, b: Control) -> void:
	if is_done():
		return
	var acc: Dictionary = def["accuse"]
	if i == int(acc["answer"]):
		sfx("solve")
		haptic(30)
		finish(1000 if Fx.motion() else 300)
	else:
		sfx("invalid")
		Fx.shake(b, 6.0, 0.3)
		var wrong: Dictionary = acc["wrong"]
		say(String(wrong.get(str(i), "The evidence doesn't support that.")))


func qa_state() -> Dictionary:
	var cells := {}
	for g in ["AB", "AC", "CB"]:
		var arr := []
		for r in m.n:
			for c in m.n:
				var pt: Array = QA.css(grid, grid.cell_rect(g, r, c).get_center())
				arr.append([r, c, pt[0], pt[1]])
		cells[g] = arr
	return {"kind": "logic", "marks": m.marks.duplicate(true), "solution": def["solution"], "cells": cells,
		"dbg": [grid.size.y, grid.custom_minimum_size.y, grid.cell, grid.col_h, grid.get_parent().size.y, grid.get_parent().get_combined_minimum_size().y, _scroll.size.y],
		"grid_done": _grid_done, "accuse": def.has("accuse"), "done": is_done(),
		"view": [QA.css(_scroll, Vector2.ZERO)[1], QA.css(_scroll, _scroll.size)[1]]}


class LogicGrid extends Control:
	var p: LogicPuzzle
	var m: LogicModel
	var def: Dictionary
	var anim := {}               # "g,r,c" -> 0..1
	var glow := 0.0:
		set(v):
			glow = v
			queue_redraw()
	var cell := 40.0
	var row_w := 80.0
	var col_h := 80.0
	var _a: Array
	var _b: Array
	var _c: Array
	var _press := Vector3i(-1, -1, -1)
	var _font: Font
	var _mono: Font

	func _init(puzzle: LogicPuzzle, model: LogicModel, d: Dictionary) -> void:
		p = puzzle
		m = model
		def = d
		_a = d["categories"][0]["items"]
		_b = d["categories"][1]["items"]
		_c = d["categories"][2]["items"]
		_font = UI.font("sans")
		_mono = UI.font("sans_bold")
		resized.connect(_relayout)
		mouse_filter = Control.MOUSE_FILTER_PASS

	func _ready() -> void:
		_relayout()

	func _relayout() -> void:
		var fs := 12
		var rw := 0.0
		for s in _a + _c:
			rw = maxf(rw, _font.get_string_size(String(s), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
		var ch := 0.0
		for s in _b + _c:
			ch = maxf(ch, _font.get_string_size(String(s), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
		row_w = rw + 10.0
		col_h = ch + 10.0
		var n := m.n
		cell = clampf(floorf((size.x - row_w - 6.0) / (2.0 * n)), 20.0, 48.0)
		var need := col_h + 2.0 * n * cell + 8.0
		if absf(custom_minimum_size.y - need) > 0.5:
			custom_minimum_size.y = need
		queue_redraw()

	func _origin(g: String) -> Vector2:
		var n := m.n
		var total_w := row_w + 2.0 * n * cell + 6.0
		var x0 := floorf((size.x - total_w) / 2.0)
		var total_h := col_h + 2.0 * n * cell + 6.0
		var y0 := 0.0
		match g:
			"AB": return Vector2(x0 + row_w, y0 + col_h)
			"AC": return Vector2(x0 + row_w + n * cell + 6.0, y0 + col_h)
			_: return Vector2(x0 + row_w, y0 + col_h + n * cell + 6.0)

	func cell_rect(g: String, r: int, c: int) -> Rect2:
		return Rect2(_origin(g) + Vector2(c, r) * cell, Vector2(cell, cell))

	func _hit(pos: Vector2) -> Vector3i:
		for g in ["AB", "AC", "CB"]:
			var o := _origin(g)
			var q := (pos - o) / cell
			if q.x >= 0 and q.y >= 0 and q.x < m.n and q.y < m.n:
				return Vector3i(["AB", "AC", "CB"].find(g), int(q.y), int(q.x))
		return Vector3i(-1, -1, -1)

	func _gui_input(e: InputEvent) -> void:
		if p._grid_done:
			return
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				_press = _hit(e.position)
				queue_redraw()
			else:
				var h := _hit(e.position)
				if h == _press and h.x >= 0:
					_tap(["AB", "AC", "CB"][h.x], h.y, h.z)
				_press = Vector3i(-1, -1, -1)
				queue_redraw()

	func _tap(g: String, r: int, c: int) -> void:
		var changed := m.toggle(g, r, c)
		for i in changed.size():
			var ch: Array = changed[i]
			_animate_cell(String(ch[0]), int(ch[1]), int(ch[2]), 0.0 if i == 0 else 0.05 * i)
		p.sfx("click" if changed[0][3] == 2 else "tap", 0.04)
		p.haptic(6)
		if changed[0][3] == 2:
			Fx.burst(self, cell_rect(g, r, c).get_center(), UI.TEAL, 8, 120.0, 3.0)
		p.cell_changed()

	func _animate_cell(g: String, r: int, c: int, delay: float) -> void:
		var key := "%s,%d,%d" % [g, r, c]
		anim[key] = 0.0 if Fx.motion() else 1.0
		if not Fx.motion():
			queue_redraw()
			return
		var tw := create_tween()
		if delay > 0.0:
			tw.tween_interval(delay)
		tw.tween_method(func(v: float) -> void:
			anim[key] = v
			queue_redraw(), 0.0, 1.0, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	func celebrate() -> void:
		if Fx.motion():
			create_tween().tween_property(self, "glow", 1.0, 0.6)
		else:
			glow = 1.0

	func _draw() -> void:
		if cell < 8.0:
			return
		var n := m.n
		for g in ["AB", "AC", "CB"]:
			var o := _origin(g)
			var blk := Rect2(o, Vector2(n * cell, n * cell))
			draw_style_box(UI.flat(Color(UI.PANEL, 0.9), 10, UI.LINE.lerp(UI.TEAL, glow), 1, 0), blk)
			for k in range(1, n):
				draw_line(o + Vector2(k * cell, 6), o + Vector2(k * cell, n * cell - 6), Color(UI.LINE, 0.8), 1.0)
				draw_line(o + Vector2(6, k * cell), o + Vector2(n * cell - 6, k * cell), Color(UI.LINE, 0.8), 1.0)
			# highlight the row and column under the finger
			if _press.x >= 0 and ["AB", "AC", "CB"][_press.x] == g:
				draw_rect(Rect2(o + Vector2(0, _press.y * cell), Vector2(n * cell, cell)), Color(UI.AMBER, 0.08))
				draw_rect(Rect2(o + Vector2(_press.z * cell, 0), Vector2(cell, n * cell)), Color(UI.AMBER, 0.08))
			for r in n:
				for c in n:
					_draw_mark(g, r, c)
		# headers
		var fs := 12
		var oab := _origin("AB")
		var ocb := _origin("CB")
		for r in n:
			_text_right(String(_a[r]), Vector2(oab.x - 6.0, oab.y + (r + 0.5) * cell), fs)
			_text_right(String(_c[r]), Vector2(ocb.x - 6.0, ocb.y + (r + 0.5) * cell), fs)
		var oac := _origin("AC")
		for c in n:
			_text_up(String(_b[c]), Vector2(oab.x + (c + 0.5) * cell, oab.y - 6.0), fs)
			_text_up(String(_c[c]), Vector2(oac.x + (c + 0.5) * cell, oac.y - 6.0), fs)

	func _text_right(s: String, at: Vector2, fs: int) -> void:
		var sz := _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		draw_string(_font, Vector2(at.x - sz.x, at.y + sz.y * 0.3), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UI.INK2)

	func _text_up(s: String, at: Vector2, fs: int) -> void:
		var sz := _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		draw_set_transform(at, -PI / 2.0, Vector2.ONE)
		draw_string(_font, Vector2(0, sz.y * 0.3 - 1.0 + 0.0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UI.INK2)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func _draw_mark(g: String, r: int, c: int) -> void:
		var v: int = m.marks[g][r][c]
		if v == 0:
			return
		var t := clampf(float(anim.get("%s,%d,%d" % [g, r, c], 1.0)), 0.0, 1.0)
		var ctr := cell_rect(g, r, c).get_center()
		var u := cell * 0.5
		if v == 1:
			var a := u * 0.42
			var tt := clampf(t * 2.0, 0.0, 1.0)
			var col := Color(UI.RED, 0.85)
			var w := maxf(2.0, cell * 0.07)
			draw_line(ctr + Vector2(-a, -a), ctr + Vector2(-a, -a).lerp(Vector2(a, a), tt), col, w, true)
			var t2 := clampf(t * 2.0 - 1.0, 0.0, 1.0)
			draw_line(ctr + Vector2(a, -a), ctr + Vector2(a, -a).lerp(Vector2(-a, a), t2), col, w, true)
		else:
			var s := 0.6 + 0.4 * t
			var col := UI.TEAL.lerp(Color.WHITE, glow * 0.4)
			draw_circle(ctr, u * 0.78 * s, Color(col, 0.18))
			var w := maxf(3.0, cell * 0.09)
			var a := ctr + Vector2(-0.38, 0.02) * u * s
			var b := ctr + Vector2(-0.1, 0.34) * u * s
			var e := ctr + Vector2(0.42, -0.34) * u * s
			var seg1 := clampf(t * 2.0, 0.0, 1.0)
			var seg2 := clampf(t * 2.0 - 1.0, 0.0, 1.0)
			draw_line(a, a.lerp(b, seg1), col, w, true)
			if seg2 > 0.0:
				draw_line(b, b.lerp(e, seg2), col, w, true)
