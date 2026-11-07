class_name BlockFitPuzzle
extends PuzzleBase
## Reassemble: drag a strip from the tray onto the page. A ghost shows where it will land (green fits, red does not),
## it snaps with a small thud, and tapping a placed strip lifts it back. Rotate the held or selected strip.

const HUES := [Color("d9c5a4"), Color("c9b48e"), Color("e3d4b5"), Color("bfa982"), Color("d4c09c"), Color("cbb997"), Color("e0cfa9"), Color("b8a27b"), Color("d2bd95"), Color("c4ad86")]

var board: Array = []
var pieces: Array = []        # {id, shape, placed(Vector2i or null), pos, s, color}
var field: BFField
var _rotate: FxButton
var _info := {}


func build() -> void:
	_info = BlockFitModel.derive(def)
	board = _info["board"]
	for i in _info["pieces"].size():
		var shape: Array = _info["pieces"][i]["cells"]
		for _k in rng.randi_range(0, 3):
			shape = BlockFitModel.rotate(shape)
		pieces.append({"id": _info["pieces"][i]["id"], "shape": shape, "placed": null, "pos": Vector2.ZERO, "s": 20.0, "color": HUES[i % HUES.size()], "sol": _info["pieces"][i]["cells"]})
	var col := UI.vbox(8)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(col)
	col.add_child(UI.label(String(def["caption"]), 14, UI.INK2, "serif_italic"))
	field = BFField.new(self)
	field.size_flags_vertical = Control.SIZE_EXPAND_FILL
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI.qa(field, "bf.field")
	col.add_child(field)
	_rotate = FxButton.new("⟳ Rotate strip")
	_rotate.pressed.connect(rotate_active)
	UI.qa(_rotate, "bf.rotate")
	col.add_child(_rotate)
	_status()


func _status() -> void:
	var left := 0
	for p in pieces:
		if p["placed"] == null:
			left += 1
	say("%d strip%s left. The gold dot is the corner you place." % [left, "" if left == 1 else "s"] if left > 0 else "")


func rotate_active() -> void:
	var i := field.active()
	if i < 0 or is_done():
		return
	pieces[i]["shape"] = BlockFitModel.rotate(pieces[i]["shape"])
	sfx("click")
	field.pop(i)
	field.layout_tray(true)


func place(i: int, r: int, c: int) -> bool:
	var occ := field.occupied(i)
	if not BlockFitModel.fits(board, occ, pieces[i]["shape"], r, c):
		return false
	var a: Vector2i = pieces[i]["shape"][0]
	pieces[i]["placed"] = Vector2i(r - a.x, c - a.y)
	sfx("place")
	haptic(6)
	_status()
	field.layout_tray(true)
	var all := true
	for p in pieces:
		if p["placed"] == null:
			all = false
	if all:
		_win()
	return true


func _win() -> void:
	sfx("solve")
	haptic(30)
	field.celebrate()
	finish(1300 if Fx.motion() else 300)


func qa_state() -> Dictionary:
	var out := []
	for i in pieces.size():
		var p: Dictionary = pieces[i]
		var anchor: Vector2i = p["shape"][0]
		var ac: Array = QA.css(field, p["pos"] + (Vector2(anchor.y, anchor.x) + Vector2(0.5, 0.5)) * float(p["s"]))
		var sol: Array = p["sol"]
		var sol_origin := Vector2i(9999, 9999)
		# where the solution puts this piece: find its cells in the picture
		var cells := []
		for r in def["solution"].size():
			var line: String = def["solution"][r]
			for c in line.length():
				if line[c] == String(p["id"]):
					cells.append(Vector2i(r, c))
		var mr := 9999
		var mc := 9999
		for cc in cells:
			mr = mini(mr, cc.x)
			mc = mini(mc, cc.y)
		sol_origin = Vector2i(mr, mc)
		out.append({"id": p["id"], "shape": p["shape"].map(func(v: Vector2i) -> Array: return [v.x, v.y]),
			"sol": sol.map(func(v: Vector2i) -> Array: return [v.x, v.y]), "sol_origin": [sol_origin.x, sol_origin.y],
			"placed": p["placed"] != null, "anchor_css": ac})
	var cells_css := []
	for r in board.size():
		var row := []
		for c in board[0].size():
			row.append(QA.css(field, field.cell_center(r, c)))
		cells_css.append(row)
	return {"kind": "blockfit", "pieces": out, "cells": cells_css, "done": is_done()}


class BFField extends Control:
	var p: BlockFitPuzzle
	var u := 30.0
	var org := Vector2.ZERO
	var tray_top := 0.0
	var um := 18.0
	var held := -1
	var sel := -1
	var ghost := Vector2i(-1, -1)
	var ghost_ok := false
	var flash := 0.0:
		set(v):
			flash = v
			queue_redraw()
	var _press := Vector2.ZERO
	var _cand := -1
	var _cand_tray := false
	var _dragging := false
	var _grab := Vector2.ZERO
	var _tw := {}

	func _init(puzzle: BlockFitPuzzle) -> void:
		p = puzzle
		mouse_filter = Control.MOUSE_FILTER_STOP
		resized.connect(_relayout)

	func _ready() -> void:
		_relayout()

	func _process(_d: float) -> void:
		queue_redraw()

	func _unhandled_key_input(e: InputEvent) -> void:
		if e is InputEventKey and e.pressed and e.keycode == KEY_R:
			p.rotate_active()

	func active() -> int:
		return held if held >= 0 else sel

	func _relayout() -> void:
		var R: int = p.board.size()
		var C: int = p.board[0].size()
		u = floorf(minf((size.x - 8.0) / C, minf(size.y * 0.52 / R, 54.0)))
		u = maxf(u, 14.0)
		org = Vector2(floorf((size.x - C * u) / 2.0), 6.0)
		tray_top = org.y + R * u + 16.0
		um = floorf(u * 0.7)
		layout_tray(false)
		# ask the page for room: board plus a tray of two rows
		var need := tray_top + 2.0 * (um * 3.0 + 12.0) + 50.0
		if absf(p.custom_minimum_size.y - need) > 1.0 and size.x > 0.0:
			p.custom_minimum_size.y = need

	func cell_center(r: int, c: int) -> Vector2:
		return org + (Vector2(c, r) + Vector2(0.5, 0.5)) * u

	func occupied(skip: int = -1) -> Dictionary:
		var occ := {}
		for i in p.pieces.size():
			if i == skip or p.pieces[i]["placed"] == null:
				continue
			var o: Vector2i = p.pieces[i]["placed"]
			for cell in p.pieces[i]["shape"]:
				occ[o + Vector2i(cell)] = i
		return occ

	func layout_tray(animate: bool) -> void:
		var x := 6.0
		var y := tray_top
		var row_h := 0.0
		for i in p.pieces.size():
			var pc: Dictionary = p.pieces[i]
			if pc["placed"] != null:
				var o: Vector2i = pc["placed"]
				_move(i, org + Vector2(o.y, o.x) * u, u, animate)
				continue
			if i == held:
				continue
			var mw := 0
			var mh := 0
			for cell in pc["shape"]:
				mw = maxi(mw, cell.y + 1)
				mh = maxi(mh, cell.x + 1)
			var w := mw * um
			if x + w > size.x - 6.0 and x > 6.0:
				x = 6.0
				y += row_h + 12.0
				row_h = 0.0
			_move(i, Vector2(x, y), um, animate)
			x += w + 14.0
			row_h = maxf(row_h, mh * um)

	func _move(i: int, pos: Vector2, s: float, animate: bool) -> void:
		var pc: Dictionary = p.pieces[i]
		if _tw.has(i) and _tw[i]:
			_tw[i].kill()
		if animate and Fx.motion() and (pc["pos"].distance_to(pos) > 0.5 or absf(pc["s"] - s) > 0.1):
			var from_pos: Vector2 = pc["pos"]
			var from_s: float = pc["s"]
			var tw := create_tween()
			tw.tween_method(func(t: float) -> void:
				pc["pos"] = from_pos.lerp(pos, t)
				pc["s"] = lerpf(from_s, s, t), 0.0, 1.0, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_tw[i] = tw
		else:
			pc["pos"] = pos
			pc["s"] = s

	func pop(i: int) -> void:
		if not Fx.motion():
			return
		var pc: Dictionary = p.pieces[i]
		var base: float = pc["s"]
		var tw := create_tween()
		tw.tween_method(func(t: float) -> void: pc["s"] = base * (1.0 + 0.18 * sin(t * PI)), 0.0, 1.0, 0.2)

	func _piece_at(pos: Vector2) -> Array:
		# the last drawn (topmost) first; placed pieces and tray pieces
		for i in range(p.pieces.size() - 1, -1, -1):
			var pc: Dictionary = p.pieces[i]
			for cell in pc["shape"]:
				var rect := Rect2(pc["pos"] + Vector2(cell.y, cell.x) * float(pc["s"]), Vector2(pc["s"], pc["s"])).grow(2.0 if pc["placed"] == null else 0.0)
				if rect.has_point(pos):
					return [i, pc["placed"] == null]
		return [-1, false]

	func _cell_at(pos: Vector2) -> Vector2i:
		var q := (pos - org) / u
		return Vector2i(int(floorf(q.y)), int(floorf(q.x)))

	func _gui_input(e: InputEvent) -> void:
		if p.is_done():
			return
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				_press = e.position
				_dragging = false
				var hit := _piece_at(e.position)
				_cand = hit[0]
				_cand_tray = hit[1]
			else:
				_release(e.position)
		elif e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			if not _dragging and _cand >= 0 and e.position.distance_to(_press) > 8.0:
				_start_drag(e.position)
			if _dragging:
				_drag_to(e.position)

	func _start_drag(pos: Vector2) -> void:
		_dragging = true
		held = _cand
		sel = -1
		var pc: Dictionary = p.pieces[held]
		if pc["placed"] != null:
			pc["placed"] = null
			p._status()
		p.sfx("pick")
		Fx.haptic(6)
		# the anchor square sits under the finger, lifted so the finger does not hide it
		if _tw.has(held) and _tw[held]:
			_tw[held].kill()
		pc["s"] = u
		_grab = Vector2(0, -34.0)
		_cand_tray = false
		layout_tray(true)

	func _drag_to(pos: Vector2) -> void:
		var pc: Dictionary = p.pieces[held]
		var a: Vector2i = pc["shape"][0]
		var anchor_off := (Vector2(a.y, a.x) + Vector2(0.5, 0.5)) * float(pc["s"])
		pc["pos"] = pos + _grab - anchor_off
		var cc := _cell_at(pos + _grab)
		ghost = cc
		ghost_ok = BlockFitModel.fits(p.board, occupied(held), pc["shape"], cc.x, cc.y)

	func _release(pos: Vector2) -> void:
		if _dragging and held >= 0:
			var i := held
			held = -1
			if ghost_ok and ghost.x >= 0:
				if not p.place(i, ghost.x, ghost.y):
					p.sfx("invalid")
			else:
				if ghost.x >= 0 and _over_board(pos + _grab):
					p.sfx("invalid")
					p.say("It doesn't fit there.")
				layout_tray(true)
			ghost = Vector2i(-1, -1)
			_dragging = false
			_cand = -1
			return
		# a tap
		if _cand >= 0:
			if _cand_tray:
				sel = -1 if sel == _cand else _cand
				p.sfx("pick")
				pop(_cand)
			else:
				p.pieces[_cand]["placed"] = null
				p.sfx("paper")
				p._status()
				layout_tray(true)
		elif sel >= 0:
			var cc := _cell_at(pos)
			if cc.x >= 0 and cc.y >= 0 and cc.x < p.board.size() and cc.y < p.board[0].size():
				if p.place(sel, cc.x, cc.y):
					sel = -1
				else:
					p.sfx("invalid")
					p.say("It doesn't fit there.")
					Fx.shake(self, 4.0, 0.2)
		_cand = -1

	func _over_board(pos: Vector2) -> bool:
		var cc := _cell_at(pos)
		return cc.x >= 0 and cc.y >= 0 and cc.x < p.board.size() and cc.y < p.board[0].size()

	func celebrate() -> void:
		if Fx.motion():
			create_tween().tween_property(self, "flash", 1.0, 0.9)
			Fx.burst(self, org + Vector2(p.board[0].size(), p.board.size()) * u / 2.0, UI.AMBER2, 30, 300.0, 5.0)
		else:
			flash = 1.0

	func celebrate_t() -> float:
		return flash

	func _draw() -> void:
		if u < 8.0:
			return
		var R: int = p.board.size()
		var C: int = p.board[0].size()
		for r in R:
			for c in C:
				if not p.board[r][c]:
					continue
				var rect := Rect2(org + Vector2(c, r) * u, Vector2(u, u)).grow(-1.0)
				draw_style_box(UI.flat(Color(0, 0, 0, 0.3), 4, Color(UI.LINE, 0.8), 1, 0), rect)
		# ghost
		if held >= 0 and ghost.x >= -1 and ghost != Vector2i(-1, -1):
			var shape: Array = p.pieces[held]["shape"]
			var o := ghost - Vector2i(shape[0])
			for cell in shape:
				var q: Vector2i = o + Vector2i(cell)
				if q.x < 0 or q.y < 0 or q.x >= R or q.y >= C:
					continue
				draw_rect(Rect2(org + Vector2(q.y, q.x) * u, Vector2(u, u)).grow(-1.0), Color(UI.TEAL, 0.4) if ghost_ok else Color(UI.RED, 0.35))
		# pieces: placed and tray first, held last
		for i in p.pieces.size():
			if i != held:
				_piece(i)
		if held >= 0:
			_piece(held)

	func _piece(i: int) -> void:
		var pc: Dictionary = p.pieces[i]
		var s: float = pc["s"]
		var shape: Array = pc["shape"]
		var col: Color = pc["color"]
		var lift := held == i
		var glow := flash if pc["placed"] != null else 0.0
		for k in shape.size():
			var cell: Vector2i = shape[k]
			var rect := Rect2(pc["pos"] + Vector2(cell.y, cell.x) * s, Vector2(s, s)).grow(-1.0)
			if lift:
				draw_rect(Rect2(rect.position + Vector2(0, 4), rect.size).grow(1.0), Color(0, 0, 0, 0.3))
			var sb := UI.flat(col.lerp(UI.AMBER2, glow * 0.6), maxf(2.0, s * 0.12), Color("8a7650"), 1, 0)
			draw_style_box(sb, rect)
			# a few lines of "text" on the strip
			var y0 := rect.position.y + s * 0.3
			draw_line(Vector2(rect.position.x + s * 0.18, y0), Vector2(rect.end.x - s * 0.18, y0), Color(0.2, 0.15, 0.08, 0.35), 1.0)
			draw_line(Vector2(rect.position.x + s * 0.18, y0 + s * 0.28), Vector2(rect.end.x - s * 0.34, y0 + s * 0.28), Color(0.2, 0.15, 0.08, 0.35), 1.0)
			if k == 0 and (sel == i or held == i):
				draw_circle(rect.get_center(), s * 0.14, UI.AMBER)
		if sel == i and held < 0:
			for cell in shape:
				draw_rect(Rect2(pc["pos"] + Vector2(cell.y, cell.x) * s, Vector2(s, s)).grow(0.0), Color(UI.AMBER, 0.18))
