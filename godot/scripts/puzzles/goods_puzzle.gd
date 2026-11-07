class_name GoodsPuzzle
extends PuzzleBase
## Sort: tap a card, then tap a rack with space. Cards fly in an arc; three of a kind lock, flash and burst away.

var racks: Array = []          # arrays of card uids
var kinds := {}                # uid -> type id
var nodes := {}                # uid -> Card
var _board: Control
var _sel := -1
var _busy := false
var _rack_rects: Array = []
var _next_uid := 0
var _cols := 2
var _cw := 50.0
var _ch := 56.0
var _rack_h := 72.0
var _gap := 8.0
var _origin := Vector2.ZERO
var _lock := {}                # rack index -> 0..1 lock overlay
var _legend: HFlowContainer


func build() -> void:
	var col := UI.vbox(8)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(col)
	col.add_child(UI.label("Tap a card, then tap a rack with space. Three of a kind lock away.", 14, UI.INK2, "serif_italic"))
	_board = RackBoard.new(self)
	_board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(_board)
	_legend = HFlowContainer.new()
	_legend.add_theme_constant_override("h_separation", 6)
	_legend.add_theme_constant_override("v_separation", 4)
	_legend.alignment = FlowContainer.ALIGNMENT_CENTER
	for id in def["types"]:
		var t: Dictionary = def["types"][id]
		var chip := UI.panel(Color(t["color"]), 6, Color(0, 0, 0, 0), 0, 4)
		chip.add_child(UI.label(String(t["label"]), 11, _ink(Color(t["color"])), "mono_bold", HORIZONTAL_ALIGNMENT_CENTER, false))
		_legend.add_child(chip)
	col.add_child(_legend)
	for r in GoodsModel.init_racks(def):
		var uids := []
		for t in r:
			uids.append(_new_card(String(t)))
		racks.append(uids)
	_board.resized.connect(_relayout)
	_relayout.call_deferred()
	_status()


static func _ink(c: Color) -> Color:
	return UI.DARK_INK if c.get_luminance() > 0.42 else Color("f4f0e6")


func _new_card(t: String) -> int:
	var uid := _next_uid
	_next_uid += 1
	kinds[uid] = t
	var n := Card.new(String(def["types"][t]["label"]), Color(def["types"][t]["color"]))
	nodes[uid] = n
	_board.add_child(n)
	return uid


func _status() -> void:
	var left := 0
	for r in racks:
		left += r.size()
	say("%d card%s on the racks." % [left, "" if left == 1 else "s"])


func _relayout() -> void:
	var n := racks.size()
	var w := _board.size.x
	_cols = 2 if n > 4 else 1
	var rows := ceili(float(n) / _cols)
	var cap := int(def["capacity"])
	var rack_w := (w - _gap * (_cols - 1)) / _cols
	_cw = minf((rack_w - 12.0 - 6.0 * (cap - 1)) / cap, 62.0)
	_ch = minf(_cw * 1.1, 64.0)
	_rack_h = _ch + 14.0
	var total_h := rows * _rack_h + (rows - 1) * _gap
	_origin = Vector2(0, maxf((_board.size.y - total_h) / 2.0, 0.0))
	_rack_rects.clear()
	for i in n:
		var c := i % _cols
		var r := i / _cols
		_rack_rects.append(Rect2(_origin + Vector2(c * (rack_w + _gap), r * (_rack_h + _gap)), Vector2(rack_w, _rack_h)))
	for uid in nodes:
		nodes[uid].custom_minimum_size = Vector2(_cw, _ch)
		nodes[uid].size = Vector2(_cw, _ch)
	_place(false)
	_board.queue_redraw()


func slot_pos(rack: int, slot: int) -> Vector2:
	var rr: Rect2 = _rack_rects[rack]
	var cap := int(def["capacity"])
	var span := cap * _cw + (cap - 1) * 6.0
	var x0 := rr.position.x + (rr.size.x - span) / 2.0
	return Vector2(x0 + slot * (_cw + 6.0), rr.position.y + (rr.size.y - _ch) / 2.0)


func _place(animate: bool, skip_uid: int = -1) -> void:
	for ri in racks.size():
		for si in racks[ri].size():
			var uid: int = racks[ri][si]
			if uid == skip_uid:
				continue
			var target := slot_pos(ri, si)
			var n: Card = nodes[uid]
			n.set_selected(uid == _sel)
			if animate and Fx.motion() and n.position.distance_to(target) > 1.0:
				var tw := create_tween()
				tw.tween_property(n, "position", target, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			else:
				n.position = target - (Vector2(0, 8) if uid == _sel else Vector2.ZERO)


func _rack_at(pos: Vector2) -> int:
	for i in _rack_rects.size():
		if _rack_rects[i].grow(4).has_point(pos):
			return i
	return -1


func tapped(pos: Vector2) -> void:
	if _busy or is_done():
		return
	var ri := _rack_at(pos)
	if ri < 0:
		return
	# which card was hit?
	var hit := -1
	for si in racks[ri].size():
		var p := slot_pos(ri, si)
		if Rect2(p, Vector2(_cw, _ch)).grow(3).has_point(pos):
			hit = si
	if _sel >= 0:
		var from := _rack_of(_sel)
		if from == ri:
			if hit >= 0 and racks[ri][hit] == _sel:
				_sel = -1
				sfx("tap")
				_place(true)
				return
			if hit >= 0:
				_sel = racks[ri][hit]
				sfx("pick")
				_place(true)
			return
		_drop(ri)
		return
	if hit >= 0:
		_sel = racks[ri][hit]
		sfx("pick")
		haptic(5)
		_place(true)


func _rack_of(uid: int) -> int:
	for i in racks.size():
		if racks[i].has(uid):
			return i
	return -1


func _drop(ri: int) -> void:
	var cap := int(def["capacity"])
	if racks[ri].size() >= cap:
		sfx("invalid")
		say("That rack is full.")
		Fx.shake(_board, 4.0, 0.2)
		return
	var uid := _sel
	var from := _rack_of(uid)
	racks[from].erase(uid)
	racks[ri].append(uid)
	_sel = -1
	sfx("place")
	var n: Card = nodes[uid]
	n.set_selected(false)
	n.z_index = 10
	var target := slot_pos(ri, racks[ri].size() - 1)
	_place(true, uid)
	_busy = true
	if Fx.motion():
		var a := n.position
		var tw := create_tween()
		tw.tween_method(func(t: float) -> void:
			var p := a.lerp(target, t)
			p.y -= sin(t * PI) * 46.0
			n.position = p, 0.0, 1.0, 0.3).set_trans(Tween.TRANS_SINE)
		await tw.finished
	n.position = target
	n.z_index = 0
	if Fx.motion():
		n.land()
	await _check_clear()
	_busy = false
	_status()
	if GoodsModel.solved(def, _as_types()):
		sfx("solve")
		haptic(30)
		finish(900 if Fx.motion() else 300)


func _as_types() -> Array:
	var out := []
	for r in racks:
		out.append(r.map(func(u: int) -> String: return kinds[u]))
	return out


func _check_clear() -> void:
	var cap := int(def["capacity"])
	for ri in racks.size():
		var r: Array = racks[ri]
		if GoodsModel.is_full_match(r.map(func(u: int) -> String: return kinds[u]), cap):
			sfx("clear")
			haptic(14)
			var rr: Rect2 = _rack_rects[ri]
			if Fx.motion():
				for u in r:
					nodes[u].flash()
				var tw := create_tween()
				tw.tween_method(func(v: float) -> void:
					_lock[ri] = v
					_board.queue_redraw(), 0.0, 1.0, 0.3)
				await tw.finished
				Fx.burst(_board, rr.get_center(), Color(nodes[r[0]].color), 24, 240.0, 4.0)
				var tw2 := create_tween().set_parallel(true)
				for u in r:
					tw2.tween_property(nodes[u], "scale", Vector2.ZERO, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
					tw2.tween_property(nodes[u], "modulate:a", 0.0, 0.22)
				await tw2.finished
				_lock.erase(ri)
				_board.queue_redraw()
			for u in r:
				nodes[u].queue_free()
				nodes.erase(u)
				kinds.erase(u)
			r.clear()


func qa_state() -> Dictionary:
	var pts := []
	for ri in racks.size():
		var rr: Rect2 = _rack_rects[ri]
		var c: Array = QA.css(_board, rr.get_center())
		var cards := []
		for si in racks[ri].size():
			var cp: Array = QA.css(_board, slot_pos(ri, si) + Vector2(_cw, _ch) / 2.0)
			cards.append([kinds[racks[ri][si]], cp[0], cp[1]])
		pts.append({"c": c, "cards": cards})
	return {"kind": "goods", "racks": _as_types(), "pts": pts, "capacity": def["capacity"], "leftover": def["leftover"],
		"busy": _busy, "done": is_done()}


class RackBoard extends Control:
	var p: GoodsPuzzle

	func _init(puzzle: GoodsPuzzle) -> void:
		p = puzzle
		mouse_filter = Control.MOUSE_FILTER_STOP
		clip_contents = false

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			p.tapped(e.position)

	func _draw() -> void:
		for i in p._rack_rects.size():
			var rr: Rect2 = p._rack_rects[i]
			var lk: float = float(p._lock.get(i, 0.0))
			draw_style_box(UI.flat(Color(UI.PANEL, 0.95).lerp(Color(UI.AMBER, 0.3), lk), 12, UI.LINE.lerp(UI.AMBER2, lk), 1 + int(lk), 0), rr)
			# slot wells
			for s in int(p.def["capacity"]):
				var sp: Vector2 = p.slot_pos(i, s)
				draw_style_box(UI.flat(Color(0, 0, 0, 0.22), 8, Color(0, 0, 0, 0), 0, 0), Rect2(sp, Vector2(p._cw, p._ch)))


class Card extends Panel:
	var label_text := ""
	var color := Color.WHITE
	var _sel := false
	var _label: Label

	func _init(text: String, c: Color) -> void:
		label_text = text
		color = c
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_label = UI.label(text, 10, GoodsPuzzle._ink(c), "mono_bold", HORIZONTAL_ALIGNMENT_CENTER, false)
		_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(_label)
		_restyle()
		resized.connect(func() -> void: pivot_offset = size / 2.0)

	func _restyle() -> void:
		var sb := UI.flat(color, 9, Color(UI.AMBER2) if _sel else Color(0, 0, 0, 0.3), 3 if _sel else 1, 0)
		sb.shadow_color = Color(0, 0, 0, 0.35)
		sb.shadow_size = 4 if _sel else 2
		sb.shadow_offset = Vector2(0, 3 if _sel else 1)
		add_theme_stylebox_override("panel", sb)

	func set_selected(on: bool) -> void:
		_sel = on
		_restyle()

	func land() -> void:
		scale = Vector2(1.14, 0.88)
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	func flash() -> void:
		var tw := create_tween()
		tw.tween_property(self, "modulate", Color(1.8, 1.8, 1.8), 0.1)
		tw.tween_property(self, "modulate", Color.WHITE, 0.2)
