class_name ScrewsPuzzle
extends PuzzleBase
## Screws: unscrew the plates. Each screw flies to the open box of its colour, or waits in the tray.
## Full boxes leave and the next opens; plates drop when their last screw is out. Undo is always there.

var m: ScrewsModel
var board: ScrewsBoard
var history: Array = []
var _undo: FxButton


func build() -> void:
	m = ScrewsModel.from_def(def)
	var col := UI.vbox(8)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(col)
	col.add_child(UI.label(String(def.get("caption", "")), 12, UI.AMBER2, "mono_bold"))
	board = ScrewsBoard.new(self)
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI.qa(board, "screws.board")
	col.add_child(board)
	_undo = FxButton.new("Undo", "ghost")
	_undo.pressed.connect(undo)
	UI.qa(_undo, "screws.undo")
	col.add_child(_undo)
	board.resized.connect(func() -> void:
		if board.size.x > 0.0:
			ask_height(board.size.x * 1.25 + 24.0 + 56.0 + 16.0))
	_refresh()


func color_of(id: String) -> Color:
	return Color(def["colors"].get(id, "#cccccc"))


func _refresh() -> void:
	_undo.disabled = history.is_empty() or is_done()
	_undo.modulate.a = 0.45 if _undo.disabled else 1.0
	var left := m.screws.size() - m.removed.size()
	say("%d screws left. Tray %d of %d." % [left, m.tray.size(), m.tray_size])


func tap(k: int) -> void:
	if is_done() or board.busy:
		return
	if not m.is_free(k):
		sfx("tap")
		say("A plate is on top of that one.")
		board.wobble(k)
		return
	if m.destination(k).is_empty():
		sfx("invalid")
		haptic(18)
		say("The tray is full. Undo, or take a screw that has an open box.")
		board.wobble(k)
		return
	history.append(m.snapshot())
	var before_boxes := m.boxes.duplicate(true)
	var before_tray := m.tray.duplicate()
	var plates_before := []
	for pi in m.plates.size():
		plates_before.append(m.plate_gone(pi))
	var ev := m.take(k)
	sfx("ratchet", 0.06)
	haptic(8)
	await board.animate(k, ev, before_boxes, before_tray, plates_before)
	_refresh()
	if m.won():
		sfx("solve")
		haptic(30)
		board.celebrate()
		finish(1200 if Fx.motion() else 300)


func undo() -> void:
	if history.is_empty() or board.busy or is_done():
		return
	m.restore(history.pop_back())
	sfx("tap")
	board.reset_view()
	_refresh()


func board_hint(level: int) -> Dictionary:
	if board.busy:
		return {}
	var k := m.first_move()
	if k < 0:
		return {"text": "This can't be cleared from here. Undo a few moves."}
	var rects := [view_rect(board, board.screw_rect(k))]
	if level < 2:
		return {"rects": rects, "text": "Take this screw next."}
	var d := m.destination(k)
	if d[0] == "box":
		rects.append(view_rect(board, board.box_rect(d[1])))
	else:
		rects.append(view_rect(board, board.tray_rect(d[1])))
	return {"rects": rects, "text": "Take this screw now; it has somewhere to go."}


func ghost_move() -> Dictionary:
	var free := m.free_screws()
	for k in free:
		var d := m.destination(k)
		if not d.is_empty() and d[0] == "box":
			var a := view_rect(board, board.screw_rect(k)).get_center()
			return {"from": a, "to": a, "text": "Tap a screw that nothing covers. It goes to the box of its colour, or the tray."}
	return {}


func qa_state() -> Dictionary:
	var pts := []
	for k in m.screws.size():
		pts.append(QA.css(board, board.screw_rect(k).get_center()))
	return {"kind": "screws", "free": m.free_screws(), "removed": m.removed.keys(), "pts": pts,
		"tray": m.tray.duplicate(), "busy": board.busy, "next": m.first_move() if not board.busy else -1, "done": is_done()}


class ScrewsBoard extends Control:
	var p: ScrewsPuzzle
	var busy := false
	var plate_fall := {}      # plate -> 0..1
	var flying: Array = []    # {color, from, to, t, spin}
	var hidden_box := {}      # box -> holes not yet shown (in flight)
	var hidden_tray := 0
	var box_slide := [0.0, 0.0]
	var wob := {}
	var glow := 0.0:
		set(v):
			glow = v
			queue_redraw()
	var top_h := 120.0
	var area := Rect2()

	func _init(puzzle: ScrewsPuzzle) -> void:
		p = puzzle
		mouse_filter = Control.MOUSE_FILTER_STOP
		resized.connect(queue_redraw)

	func _process(_d: float) -> void:
		if busy or not wob.is_empty() or not flying.is_empty():
			queue_redraw()

	func _layout() -> void:
		var w := size.x
		var hole := minf(34.0, (w - 40.0) / 9.0)
		top_h = hole * 2.0 + 44.0
		var side := minf(w, size.y - top_h - 8.0)
		area = Rect2(Vector2((w - side) / 2.0, top_h + 8.0), Vector2(side, side))

	func hole() -> float:
		return minf(34.0, (size.x - 40.0) / 9.0)

	func box_rect(i: int) -> Rect2:
		var h := hole()
		var bw := h * 3.0 + 24.0
		var gap := 14.0
		var x0 := (size.x - (bw * 2.0 + gap)) / 2.0
		return Rect2(x0 + i * (bw + gap), 4.0 - box_slide[i] * 60.0, bw, h + 16.0)

	func box_hole(i: int, j: int) -> Vector2:
		var r := box_rect(i)
		var h := hole()
		return r.position + Vector2(12.0 + h * (j + 0.5), r.size.y / 2.0)

	func tray_rect(slot: int) -> Rect2:
		var h := hole()
		var n: int = p.m.tray_size
		var total := n * h + (n - 1) * 6.0
		var x0 := (size.x - total) / 2.0
		return Rect2(x0 + slot * (h + 6.0), box_rect(0).size.y + 18.0, h, h)

	func screw_pos(k: int) -> Vector2:
		_layout()
		var s: Dictionary = p.m.screws[k]
		return area.position + Vector2(s["pos"]) * area.size

	func screw_rect(k: int) -> Rect2:
		var c := screw_pos(k)
		var r := area.size.x * 0.045 + 6.0
		return Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0)

	func plate_rect(pi: int) -> Rect2:
		_layout()
		var r: Rect2 = p.m.plates[pi]["rect"]
		return Rect2(area.position + r.position * area.size, r.size * area.size)

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			# the topmost screw under the finger
			var best := -1
			var bd := 1e9
			for k in p.m.screws.size():
				if p.m.removed.has(k):
					continue
				var d := screw_pos(k).distance_to(e.position)
				if d < screw_rect(k).size.x * 0.75 and (best < 0 or int(p.m.screws[k]["plate"]) > int(p.m.screws[best]["plate"]) or d < bd):
					if best < 0 or int(p.m.screws[k]["plate"]) >= int(p.m.screws[best]["plate"]):
						best = k
						bd = d
			if best >= 0:
				p.tap(best)

	func wobble(k: int) -> void:
		if not Fx.motion():
			return
		wob[k] = 1.0
		var tw := create_tween()
		tw.tween_method(func(v: float) -> void: wob[k] = v, 1.0, 0.0, 0.35)
		tw.tween_callback(func() -> void: wob.erase(k))

	func reset_view() -> void:
		plate_fall.clear()
		flying.clear()
		hidden_box.clear()
		hidden_tray = 0
		box_slide = [0.0, 0.0]
		queue_redraw()

	func _fly(color: Color, from: Vector2, to: Vector2, dur: float) -> void:
		var f := {"color": color, "from": from, "to": to, "t": 0.0}
		flying.append(f)
		var tw := create_tween()
		tw.tween_method(func(v: float) -> void:
			f["t"] = v
			queue_redraw(), 0.0, 1.0, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tw.finished
		flying.erase(f)

	func animate(k: int, ev: Dictionary, before_boxes: Array, before_tray: Array, plates_before: Array) -> void:
		var col := p.color_of(String(p.m.screws[k]["color"]))
		var from := screw_pos(k)
		if not Fx.motion():
			queue_redraw()
			return
		busy = true
		var to: Vector2
		var dest: Array = ev["to"]
		if dest[0] == "box":
			to = box_hole(dest[1], int(before_boxes[dest[1]]["filled"]))
		else:
			to = tray_rect(dest[1]).get_center()
		# while it flies, show the boxes and tray as they were
		_show_before(before_boxes, before_tray)
		await _fly(col, from, to, 0.32)
		Sound.sfx("place", 0.05)
		# plates that just lost their last screw drop away
		for pi in p.m.plates.size():
			if p.m.plate_gone(pi) and not plates_before[pi]:
				_drop_plate(pi)
		if not ev["closed"].is_empty():
			Sound.sfx("clear")
			Fx.haptic(14)
			for c in ev["closed"]:
				var i: int = c[0]
				Fx.burst(self, box_rect(i).get_center(), p.color_of(String(c[1])), 16, 200.0, 4.0)
				var tw := create_tween()
				tw.tween_method(func(v: float) -> void:
					box_slide[i] = v
					queue_redraw(), 0.0, 1.0, 0.18)
				await tw.finished
			_shown = {}
			queue_redraw()
			for c in ev["closed"]:
				var i2: int = c[0]
				var tw2 := create_tween()
				tw2.tween_method(func(v: float) -> void:
					box_slide[i2] = v
					queue_redraw(), 1.0, 0.0, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			await get_tree().create_timer(0.2).timeout
		for ft in ev["from_tray"]:
			var b: int = ft[1]
			await _fly(p.color_of(String(p.m.boxes[b]["color"])), tray_rect(ft[0]).get_center(), box_hole(b, maxi(int(p.m.boxes[b]["filled"]) - 1, 0)), 0.22)
		_shown = {}
		busy = false
		queue_redraw()

	var _shown := {}

	func _show_before(bb: Array, bt: Array) -> void:
		_shown = {"boxes": bb, "tray": bt}
		queue_redraw()

	func _drop_plate(pi: int) -> void:
		Sound.sfx("metal")
		plate_fall[pi] = 0.0
		var tw := create_tween()
		tw.tween_method(func(v: float) -> void:
			plate_fall[pi] = v
			queue_redraw(), 0.0, 1.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	func celebrate() -> void:
		if Fx.motion():
			create_tween().tween_property(self, "glow", 1.0, 0.6)
		else:
			glow = 1.0

	func _draw() -> void:
		_layout()
		if area.size.x < 20.0:
			return
		var boxes: Array = _shown.get("boxes", p.m.boxes)
		var tray: Array = _shown.get("tray", p.m.tray)
		var h := hole()
		# boxes
		for i in boxes.size():
			var r := box_rect(i)
			var bc: String = boxes[i]["color"]
			if bc == "":
				draw_style_box(UI.flat(Color(UI.PANEL, 0.5), 10, UI.LINE, 1, 0), r)
				continue
			var col := p.color_of(bc)
			draw_style_box(UI.flat(col.darkened(0.45), 10, col, 2, 0), r)
			for j in 3:
				var c := box_hole(i, j)
				draw_circle(c, h * 0.38, Color(0, 0, 0, 0.45))
				if j < int(boxes[i]["filled"]):
					_screw_head(c, h * 0.34, col, 0.0)
		var waiting: int = p.m.queue.size() - p.m.next_box
		if waiting > 0:
			var r0 := box_rect(1)
			draw_string(UI.font("mono_bold"), Vector2(r0.end.x + 6.0, r0.get_center().y + 4.0), "+%d" % waiting, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UI.MUTE)
		# tray
		for s in p.m.tray_size:
			var tr := tray_rect(s)
			draw_style_box(UI.flat(Color(0, 0, 0, 0.35), 8, UI.LINE, 1, 0), tr)
			if s < tray.size():
				_screw_head(tr.get_center(), h * 0.34, p.color_of(String(tray[s])), 0.0)
		# the board: plates bottom to top, each with its screws
		draw_style_box(UI.flat(Color("1a2328"), 14, UI.LINE, 1, 0), area.grow(6.0))
		for pi in p.m.plates.size():
			var fall: float = float(plate_fall.get(pi, 0.0))
			if p.m.plate_gone(pi) and (fall >= 1.0 or not plate_fall.has(pi)):
				continue
			var rr := plate_rect(pi)
			var off := Vector2(0, fall * area.size.y * 0.8)
			draw_set_transform(off + rr.get_center(), fall * 0.6, Vector2.ONE)
			var tone := 0.8 + 0.06 * pi
			var sb := UI.flat(Color(0.55 * tone, 0.62 * tone, 0.66 * tone, 0.94 - 0.6 * fall), 10, Color(1, 1, 1, 0.25), 1, 0)
			sb.shadow_color = Color(0, 0, 0, 0.4)
			sb.shadow_size = 6
			draw_style_box(sb, Rect2(-rr.size / 2.0, rr.size))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			for k in p.m.plates[pi]["screws"]:
				if p.m.removed.has(k):
					continue
				var c := screw_pos(k) + off
				var sh := Vector2(sin(Time.get_ticks_msec() * 0.07) * 4.0 * float(wob.get(k, 0.0)), 0)
				var rad := screw_rect(k).size.x * 0.42
				draw_circle(c, rad * 1.15, Color(0, 0, 0, 0.35))
				_screw_head(c + sh, rad, p.color_of(String(p.m.screws[k]["color"])), 0.0)
		# screws in flight
		for f in flying:
			var t: float = f["t"]
			var pos: Vector2 = Vector2(f["from"]).lerp(f["to"], t) - Vector2(0, sin(t * PI) * 50.0)
			_screw_head(pos, h * 0.36, f["color"], t * TAU * 2.0)

	func _screw_head(c: Vector2, r: float, col: Color, spin: float) -> void:
		draw_circle(c, r, col)
		draw_circle(c + Vector2(-r * 0.25, -r * 0.25), r * 0.45, col.lightened(0.35))
		var a := Vector2(cos(spin), sin(spin)) * r * 0.6
		var b := Vector2(-a.y, a.x)
		draw_line(c - a, c + a, col.darkened(0.5), maxf(2.0, r * 0.22))
		draw_line(c - b, c + b, col.darkened(0.5), maxf(2.0, r * 0.22))
