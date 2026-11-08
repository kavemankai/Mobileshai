class_name WaterPuzzle
extends PuzzleBase
## Pump tanks: tap a tank, then the one to pour into. The tank lifts, tips over the target and the liquid runs across.

var tubes: Array = []
var cap := 4
var history: Array = []
var _sel := -1
var _busy := false
var _board: TankBoard
var _undo: FxButton


func build() -> void:
	cap = int(def["capacity"])
	tubes = def["tubes"].duplicate()
	var col := UI.vbox(8)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(col)
	col.add_child(UI.label("Tap a tank, then the tank to pour into. Each tank must end up holding one liquid.", 14, UI.INK2, "serif_italic"))
	_board = TankBoard.new(self)
	_board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(_board)
	var legend := HFlowContainer.new()
	legend.add_theme_constant_override("h_separation", 6)
	legend.alignment = FlowContainer.ALIGNMENT_CENTER
	for k in def["colors"]:
		var c: Dictionary = def["colors"][k]
		var chip := UI.panel(Color(c["color"]), 6, Color(0, 0, 0, 0), 0, 4)
		chip.add_child(UI.label(String(c["label"]), 11, _ink(Color(c["color"])), "mono_bold", HORIZONTAL_ALIGNMENT_CENTER, false))
		legend.add_child(chip)
	col.add_child(legend)
	_undo = FxButton.new("Undo pour", "ghost")
	_undo.pressed.connect(_on_undo)
	UI.qa(_undo, "water.undo")
	col.add_child(_undo)
	_refresh()
	say("The pump only runs on separated tanks.")


static func _ink(c: Color) -> Color:
	return UI.DARK_INK if c.get_luminance() > 0.42 else Color("f4f0e6")


func _refresh() -> void:
	_undo.disabled = history.is_empty() or is_done() or _busy
	_undo.modulate.a = 0.4 if _undo.disabled else 1.0
	_board.queue_redraw()


func tap(i: int) -> void:
	if is_done() or _busy:
		return
	if _sel == -1:
		if not String(tubes[i]).is_empty():
			_sel = i
			sfx("pick")
			haptic(5)
			_board.lift(i, true)
		return
	if _sel == i:
		_board.lift(i, false)
		_sel = -1
		sfx("tap")
		return
	if WaterModel.can_pour(tubes, cap, _sel, i):
		_do_pour(_sel, i)
	else:
		sfx("invalid")
		say("You can only pour onto the same liquid or into an empty tank.")
		_board.lift(_sel, false)
		Fx.shake(_board, 4.0, 0.2)
		_sel = -1


func _do_pour(a: int, b: int) -> void:
	_busy = true
	history.append(tubes.duplicate())
	var n := WaterModel.amount(tubes, cap, a, b)
	var color_id := String(tubes[a]).right(1)
	_sel = -1
	sfx("pour")
	await _board.animate_pour(a, b, n, color_id)
	tubes = WaterModel.pour(tubes, cap, a, b)
	_board.lift(a, false, true)
	_busy = false
	_refresh()
	if WaterModel.solved(tubes, cap):
		_win()


func _win() -> void:
	sfx("power")
	haptic(30)
	_board.celebrate()
	_refresh()
	finish(1400 if Fx.motion() else 300)


func _on_undo() -> void:
	if history.is_empty() or is_done() or _busy:
		return
	tubes = history.pop_back()
	_sel = -1
	sfx("tap")
	_board.reset_lifts()
	_refresh()


func qa_state() -> Dictionary:
	var pts := []
	for i in tubes.size():
		pts.append(QA.css(_board, _board.tube_rect(i).get_center()))
	return {"kind": "water", "tubes": tubes.duplicate(), "cap": cap, "pts": pts, "busy": _busy, "done": is_done()}


class TankBoard extends Control:
	var p: WaterPuzzle
	var tw := 40.0
	var unit := 30.0
	var gap := 8.0
	var x0 := 0.0
	var base_y := 0.0
	var lifts := {}            # tube -> 0..1
	var anim := {}             # a, b, n, color, t
	var glow := 0.0:
		set(v):
			glow = v
			queue_redraw()
	var _font: Font

	func _init(puzzle: WaterPuzzle) -> void:
		p = puzzle
		mouse_filter = Control.MOUSE_FILTER_STOP
		_font = UI.font("mono_bold")
		resized.connect(_relayout)

	func _ready() -> void:
		_relayout()

	func _relayout() -> void:
		var n := p.tubes.size()
		if n == 0:
			return
		gap = 8.0
		tw = clampf((size.x - gap * (n - 1)) / n, 24.0, 50.0)
		unit = clampf(minf(tw * 0.92, (size.y - 90.0) / p.cap), 16.0, 44.0)
		var total := n * tw + (n - 1) * gap
		x0 = floorf((size.x - total) / 2.0)
		base_y = floorf(size.y - 16.0)
		queue_redraw()

	func tube_h() -> float:
		return p.cap * unit + 10.0

	func tube_rect(i: int) -> Rect2:
		return Rect2(x0 + i * (tw + gap), base_y - tube_h(), tw, tube_h())

	func lift(i: int, on: bool, instant: bool = false) -> void:
		var target := 1.0 if on else 0.0
		if instant or not Fx.motion():
			lifts[i] = target
			queue_redraw()
			return
		var from: float = lifts.get(i, 0.0)
		create_tween().tween_method(func(v: float) -> void:
			lifts[i] = v
			queue_redraw(), from, target, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	func reset_lifts() -> void:
		lifts.clear()
		queue_redraw()

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			for i in p.tubes.size():
				if tube_rect(i).grow_individual(gap / 2.0, 40.0, gap / 2.0, 6.0).has_point(e.position):
					p.tap(i)
					return

	func animate_pour(a: int, b: int, n: int, color_id: String) -> void:
		lifts[a] = 0.0
		if not Fx.motion():
			return
		anim = {"a": a, "b": b, "n": n, "color": color_id, "t": 0.0}
		var t := create_tween()
		t.tween_method(func(v: float) -> void:
			anim["t"] = v
			queue_redraw(), 0.0, 1.0, 0.5 + 0.18 * n).set_trans(Tween.TRANS_LINEAR)
		await t.finished
		anim = {}
		queue_redraw()

	func celebrate() -> void:
		if Fx.motion():
			create_tween().tween_property(self, "glow", 1.0, 0.7)
			for i in p.tubes.size():
				if not String(p.tubes[i]).is_empty():
					Fx.burst(self, tube_rect(i).position + Vector2(tw / 2.0, 0), UI.AMBER2, 8, 140.0, 3.0)
		else:
			glow = 1.0

	func _process(_d: float) -> void:
		if not anim.is_empty():
			queue_redraw()

	func _ease(x: float) -> float:
		return x * x * (3.0 - 2.0 * x)

	func _draw() -> void:
		var n := p.tubes.size()
		var a := -1
		var b := -1
		var tt := 0.0
		if not anim.is_empty():
			a = anim["a"]
			b = anim["b"]
			tt = anim["t"]
		# draw the source last so it passes over the others
		for i in n:
			if i != a:
				_draw_tube(i, Transform2D.IDENTITY, 0.0, b)
		if a >= 0:
			var dir := 1.0 if b > a else -1.0
			var r := tube_rect(a)
			var rb := tube_rect(b)
			var lip := Vector2(r.position.x + (tw if dir > 0 else 0.0), r.position.y)
			var lip_target := Vector2(rb.position.x + tw / 2.0 - dir * tw * 0.12, rb.position.y - tw * 0.55)
			var ph_in := _ease(clampf(tt / 0.25, 0.0, 1.0))
			var ph_out := _ease(clampf((tt - 0.8) / 0.2, 0.0, 1.0))
			var k := ph_in * (1.0 - ph_out)
			var ang := dir * 1.05 * k
			var cur_lip := lip.lerp(lip_target, k)
			var xf := Transform2D(ang, cur_lip) * Transform2D(0.0, -lip)
			_draw_tube(a, xf, k, b)
			var fill_t := clampf((tt - 0.25) / 0.55, 0.0, 1.0)
			if fill_t > 0.0 and fill_t < 1.0 or (tt > 0.25 and tt < 0.8):
				var col := Color(p.def["colors"][anim["color"]]["color"])
				var surf := _surface_y(b, fill_t)
				draw_line(cur_lip + Vector2(0, 2), Vector2(cur_lip.x, surf), col, maxf(3.0, tw * 0.1), true)

	func _surface_y(i: int, fill_t: float) -> float:
		var r := tube_rect(i)
		var layers := String(p.tubes[i]).length()
		var extra := float(anim["n"]) * fill_t if not anim.is_empty() and anim["b"] == i else 0.0
		return r.end.y - 4.0 - (layers + extra) * unit

	func _draw_tube(i: int, xf: Transform2D, tilt: float, dest: int) -> void:
		var r := tube_rect(i)
		var lift_y: float = -14.0 * float(lifts.get(i, 0.0))
		draw_set_transform_matrix(Transform2D(0.0, Vector2(0, lift_y)) * xf)
		var t: String = p.tubes[i]
		var fill_t := 0.0
		var removing := 0.0
		var adding := 0.0
		if not anim.is_empty():
			fill_t = clampf((float(anim["t"]) - 0.25) / 0.55, 0.0, 1.0)
			if anim["a"] == i:
				removing = float(anim["n"]) * fill_t
			if anim["b"] == i:
				adding = float(anim["n"]) * fill_t
		var bottom := r.end.y - 4.0
		var inner_x := r.position.x + 4.0
		var inner_w := tw - 8.0
		# glass back
		var glass := StyleBoxFlat.new()
		glass.bg_color = Color(1, 1, 1, 0.045)
		glass.set_corner_radius_all(6)
		glass.corner_radius_bottom_left = int(tw * 0.45)
		glass.corner_radius_bottom_right = int(tw * 0.45)
		glass.border_color = UI.LINE.lerp(UI.AMBER2, glow if t.length() == p.cap else float(lifts.get(i, 0.0)) * 0.9)
		glass.set_border_width_all(2)
		glass.anti_aliasing = true
		draw_style_box(glass, r)
		# layers, bottom up
		var layers := t.length()
		for k in layers:
			var h := unit
			var from_top := layers - 1 - k
			if removing > 0.0:
				h = unit * clampf(1.0 - (removing - float(from_top)), 0.0, 1.0)
			_layer(t[k], inner_x, bottom - (k + 1) * unit + (unit - h), inner_w, h, k == 0)
		if adding > 0.0:
			var added := int(anim["n"])
			for k in added:
				var hh := unit * clampf(adding - float(k), 0.0, 1.0)
				_layer(String(anim["color"]), inner_x, bottom - (layers + k + 1) * unit + (unit - hh) + 0.0 * hh, inner_w, hh, layers == 0 and k == 0)
		# shine
		draw_rect(Rect2(r.position.x + 5.0, r.position.y + 6.0, 3.0, r.size.y - tw * 0.6), Color(1, 1, 1, 0.1))
		draw_set_transform_matrix(Transform2D.IDENTITY)

	func _layer(id: String, x: float, y: float, w: float, h: float, first: bool) -> void:
		if h < 0.5:
			return
		var col := Color(p.def["colors"][id]["color"])
		var sb := StyleBoxFlat.new()
		sb.bg_color = col
		sb.anti_aliasing = true
		if first:
			sb.corner_radius_bottom_left = int(tw * 0.38)
			sb.corner_radius_bottom_right = int(tw * 0.38)
		draw_style_box(sb, Rect2(x, y, w, h))
		draw_rect(Rect2(x, y, w, 2.0), col.lightened(0.18))
		if h > unit * 0.6:
			var ch := String(p.def["colors"][id]["label"]).left(1)
			var fs := int(unit * 0.42)
			var sz := _font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
			draw_string(_font, Vector2(x + (w - sz.x) / 2.0, y + (h + sz.y * 0.55) / 2.0), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(WaterPuzzle._ink(col), 0.7))
