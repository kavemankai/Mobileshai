class_name PanelsPuzzle
extends PuzzleBase
## Frames: swap frames, zoom each in or out, and join one path through all of them in story order.
## Frames glide when they swap, the picture zooms when the view changes, and the lit path runs through the chain.

var slots: Array = []
var views: Array = []
var frames: Array = []        # Frame per panel index
var _board: Control
var _sel := -1
var _gap := 10.0
var _fs := 120.0
var _origin := Vector2.ZERO
var _lit: Array = []
var _flow := 0.0:
	set(v):
		_flow = v
		if _board:
			_board.queue_redraw()


func build() -> void:
	var st := PanelsModel.shuffled_start(def, rng)
	slots = st["slots"]
	views = st["views"]
	var col := UI.vbox(8)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(col)
	col.add_child(UI.label("Start at the gold marker. Swap frames, zoom in or out, and join the path.", 14, UI.INK2, "serif_italic"))
	_board = Control.new()
	_board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board.mouse_filter = Control.MOUSE_FILTER_STOP
	_board.gui_input.connect(_input_board)
	_board.draw.connect(_draw_board)
	UI.qa(_board, "panels.board")
	col.add_child(_board)
	for pi in def["panels"].size():
		var f := Frame.new(self, pi)
		frames.append(f)
		_board.add_child(f)
	_board.resized.connect(_relayout)
	_relayout.call_deferred()
	if Fx.motion():
		var tw := create_tween().set_loops()
		tw.tween_property(self, "_flow", 1.0, 1.6)
		tw.tween_callback(func() -> void: _flow = 0.0)
	_after(false)


func _relayout() -> void:
	var rows := int(def["rows"])
	var cols := int(def["cols"])
	var s := _board.size
	# frames size from the width; a tall grid makes the page scroll rather than shrinking the pictures
	var fs_w := clampf(floorf((s.x - _gap * (cols - 1)) / cols), 60.0, 190.0)
	_fs = clampf(minf(fs_w, floorf((s.y - _gap * (rows - 1)) / rows)), 48.0, fs_w)
	_origin = Vector2(floorf((s.x - (_fs * cols + _gap * (cols - 1))) / 2.0), 0.0)
	var need := rows * fs_w + (rows - 1) * _gap + 36.0
	if s.x > 0.0:
		ask_height(need)
	for f in frames:
		f.size = Vector2(_fs, _fs)
		f.pivot_offset = f.size / 2.0
	_place(false)


func slot_pos(slot: int) -> Vector2:
	var cols := int(def["cols"])
	return _origin + Vector2(slot % cols, slot / cols) * (_fs + _gap)


func _place(animate: bool) -> void:
	for slot in slots.size():
		var f: Frame = frames[slots[slot]]
		var t := slot_pos(slot)
		if animate and Fx.motion() and f.position.distance_to(t) > 1.0:
			if f.tw:
				f.tw.kill()
			f.tw = create_tween()
			f.tw.tween_property(f, "position", t, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			f.position = t
		f.set_selected(slots[slot] == _sel)
	_board.queue_redraw()


func _slot_of(pi: int) -> int:
	return slots.find(pi)


func _input_board(e: InputEvent) -> void:
	if is_done():
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
		for f in frames:
			var fr: Frame = f
			var rect := Rect2(fr.position, fr.size)
			if rect.has_point(e.position):
				if fr.zoom_rect().has_point(e.position - fr.position):
					toggle_view(fr.idx)
				else:
					pick(_slot_of(fr.idx))
				return


func toggle_view(pi: int) -> void:
	views[pi] ^= 1
	sfx("click")
	haptic(6)
	frames[pi].zoom_to(views[pi])
	_after(true)


func pick(slot: int) -> void:
	if _sel == -1:
		_sel = slots[slot]
		sfx("pick")
	elif _sel == slots[slot]:
		_sel = -1
	else:
		var a := _slot_of(_sel)
		var tmp = slots[a]
		slots[a] = slots[slot]
		slots[slot] = tmp
		_sel = -1
		sfx("swap")
		_place(true)
	_after(true)


func _after(animate: bool) -> void:
	_lit = PanelsModel.trace(def, slots, views)
	var full := not _lit.is_empty()
	if not full:
		_lit = PanelsModel.connected(def, slots, views)
	for f in frames:
		f.lit = _lit.has(f.idx)
		f.queue_redraw()
	_place(false if not animate else false)
	_board.queue_redraw()
	if PanelsModel.solved(def, slots, views):
		_win()
	elif full:
		say("The path connects, but the frames are out of order. Follow the times.")
	else:
		say("%d of %d frames connected from the start marker." % [_lit.size(), frames.size()])


func _win() -> void:
	sfx("solve")
	haptic(30)
	for f in frames:
		f.celebrate()
	finish(1400 if Fx.motion() else 300)


func _input_unused() -> void:
	pass


func _draw_board() -> void:
	# start and end markers sit on the frame edge
	for marker in ["start", "end"]:
		var m: Dictionary = def[marker]
		var f: Frame = frames[slots[int(m["slot"])]]
		var pt: Vector2 = f.position + f.edge_point(String(m["edge"]), 0.0) * _fs / 100.0
		var col := UI.AMBER2 if marker == "start" else UI.TEAL
		_board.draw_circle(pt, 9.0, Color(col, 0.35))
		_board.draw_circle(pt, 5.0, col)


func board_hint(level: int) -> Dictionary:
	var sols := PanelsModel.solutions(def)
	if sols.is_empty():
		return {}
	var tgt: Dictionary = sols[0]
	for slot in slots.size():
		if slots[slot] != tgt["slots"][slot]:
			var f: Frame = frames[tgt["slots"][slot]]
			var rects := [view_rect(_board, Rect2(f.position, f.size))]
			var text := "This frame is in the wrong place."
			if level >= 2:
				var g: Frame = frames[slots[slot]]
				rects.append(view_rect(_board, Rect2(g.position, g.size)))
				text = "Swap the glowing frame with the teal one."
			return {"rects": rects, "text": text}
	for pi in views.size():
		if views[pi] != tgt["views"][pi]:
			var f2: Frame = frames[pi]
			var zr := f2.zoom_rect()
			var rects2 := [view_rect(_board, Rect2(f2.position, f2.size))]
			if level >= 2:
				rects2 = [view_rect(_board, Rect2(f2.position + zr.position, zr.size)), view_rect(_board, Rect2(f2.position, f2.size))]
			return {"rects": rects2, "text": "This frame needs the other view." if level < 2 else "Zoom this frame %s." % ("in" if views[pi] == 0 else "out")}
	return {}

func qa_state() -> Dictionary:
	var cs := []
	var zs := []
	for slot in slots.size():
		var f: Frame = frames[slots[slot]]
		cs.append(QA.css(_board, f.position + f.size / 2.0))
		zs.append(QA.css(_board, f.position + f.zoom_rect().get_center()))
	var sols := PanelsModel.solutions(def)
	return {"kind": "panels", "slots": slots.duplicate(), "views": views.duplicate(), "centers": cs, "zooms": zs,
		"solutions": sols.slice(0, 1), "lit": _lit.duplicate(), "done": is_done()}


class Frame extends Control:
	var p: PanelsPuzzle
	var idx := 0
	var lit := false
	var tw: Tween
	var _sel := false
	var _zt := 0.0            # 0 wide .. 1 close, for the crossfade and punch
	var _punch := 0.0
	var _glow := 0.0
	var _label := ""
	var _font: Font

	func _init(puzzle: PanelsPuzzle, i: int) -> void:
		p = puzzle
		idx = i
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_zt = float(puzzle.views[i])
		_label = String(puzzle.def["panels"][i]["label"])
		_font = UI.font("mono_bold")

	func zoom_rect() -> Rect2:
		return Rect2(size.x - 30.0, 4.0, 26.0, 26.0)

	func set_selected(on: bool) -> void:
		if _sel != on:
			_sel = on
			if Fx.motion():
				create_tween().tween_property(self, "scale", Vector2(1.04, 1.04) if on else Vector2.ONE, 0.12)
			queue_redraw()

	func zoom_to(v: int) -> void:
		if not Fx.motion():
			_zt = float(v)
			queue_redraw()
			return
		var t := create_tween().set_parallel(true)
		t.tween_property(self, "_zt", float(v), 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		_punch = 1.0
		t.tween_property(self, "_punch", 0.0, 0.35)

	func celebrate() -> void:
		if Fx.motion():
			create_tween().tween_property(self, "_glow", 1.0, 0.6)
		else:
			_glow = 1.0

	func _process(_d: float) -> void:
		queue_redraw()

	func edge_point(e: String, _t: float) -> Vector2:
		match e:
			"N": return Vector2(50, 0)
			"S": return Vector2(50, 100)
			"E": return Vector2(100, 50)
		return Vector2(0, 50)

	func _draw() -> void:
		if size.x < 8.0:
			return
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color("10232a"))
		# footage: the current view fades over the other as the zoom changes
		var views_def: Array = p.def["panels"][idx]["views"]
		var cur: int = p.views[idx]
		for v in [1 - cur, cur]:
			var crop := PanelArt.get_crop("%s_%s" % [p.def["panels"][idx]["id"], views_def[v]["name"]])
			if crop.is_empty():
				continue
			var a := 1.0
			if Fx.motion():
				a = clampf(_zt if v == 1 else 1.0 - _zt, 0.0, 1.0)
			else:
				a = 1.0 if v == cur else 0.0
			var dest := r.grow(_punch * 6.0)
			draw_texture_rect_region(crop["tex"], dest, crop["src"], Color(0.9, 0.93, 0.93, a))
		draw_rect(r, Color(UI.BG, 0.1))
		# the path through this frame
		var ex: Array = views_def[cur]["exits"]
		var a_pt: Vector2 = edge_point(ex[0], 0.0) * size / 100.0
		var b_pt: Vector2 = edge_point(ex[1], 0.0) * size / 100.0
		var mid := size / 2.0
		var pts := PackedVector2Array()
		for k in 21:
			var t := k / 20.0
			pts.append(a_pt.lerp(mid, t).lerp(mid.lerp(b_pt, t), t))
		var col := UI.AMBER2 if lit else UI.TEAL
		if lit:
			draw_polyline(pts, Color(col, 0.25 + 0.2 * _glow), 11.0, true)
			draw_polyline(pts, col, 5.0, true)
		else:
			for k in range(0, pts.size() - 1, 2):
				draw_line(pts[k], pts[k + 1], col, 3.0, true)
		draw_circle(a_pt, 5.0, UI.AMBER)
		draw_circle(b_pt, 5.0, UI.AMBER)
		# a bead of light runs along a lit path
		if lit and Fx.motion():
			var t2 := fmod(p._flow + float(idx) * 0.13, 1.0)
			var i := int(t2 * 20.0)
			draw_circle(pts[i], 5.0, Color(1, 1, 1, 0.9))
		# label and caption
		var lw := minf(size.x - 38.0, _font.get_string_size(_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 10.0)
		draw_rect(Rect2(3, 3, lw, 17), Color(UI.BG, 0.78))
		draw_string(_font, Vector2(7, 15), _label, HORIZONTAL_ALIGNMENT_LEFT, lw - 6.0, 10, UI.AMBER2)
		var cap := String(views_def[cur]["caption"])
		draw_rect(Rect2(0, size.y - 34, size.x, 34), Color(UI.BG, 0.72))
		draw_string(UI.font("sans"), Vector2(6, size.y - 20), cap, HORIZONTAL_ALIGNMENT_LEFT, size.x - 12.0, 11, UI.INK)
		# zoom button
		var zr := zoom_rect()
		draw_style_box(UI.flat(Color(UI.BG, 0.85), 6, UI.LINE, 1, 0), zr)
		var zc := zr.get_center()
		draw_line(zc + Vector2(-6, 0), zc + Vector2(6, 0), UI.INK, 2.0, true)
		if cur == 0:
			draw_line(zc + Vector2(0, -6), zc + Vector2(0, 6), UI.INK, 2.0, true)
		# border
		var bc := UI.AMBER if _sel else (UI.AMBER2.lerp(Color.WHITE, 0.3) if _glow > 0.5 else (UI.AMBER if lit else UI.LINE))
		draw_rect(r, bc, false, 3.0 if (_sel or lit) else 1.0)
