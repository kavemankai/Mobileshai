class_name TimelinePuzzle
extends PuzzleBase
## Timeline: put the cards in order. Drag a card by its grip and the others slide out of the way;
## arrows and tap-to-swap work too. A wrong check ticks the cards that are already right.

var order: Array = []
var cards := {}                      # id -> TLCard
var _list := Control.new()
var _scroll := ScrollContainer.new()
var _spine := ColorRect.new()
var _check: FxButton
var _card_h := 70.0
var _gap := 8.0
var _sel := ""
var _drag_id := ""
var _drag_off := 0.0
var _settle_id := 0
var _w := 0.0


func build() -> void:
	order = TimelineModel.initial_order(def, rng)
	var col := UI.vbox(8)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(col)
	col.add_child(UI.label(String(def["prompt"]), 14, UI.INK2, "serif_italic"))
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(_scroll)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_list)
	_spine.color = Color(UI.LINE, 0.9)
	_spine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list.add_child(_spine)
	var by_id := {}
	for c in def["cards"]:
		by_id[c["id"]] = c
	for id in def["order"]:
		var card := TLCard.new(self, by_id[id])
		cards[id] = card
		_list.add_child(card)
	_check = FxButton.new("Check the order", "primary")
	_check.pressed.connect(_on_check)
	UI.qa(_check, "tl.check")
	col.add_child(_check)
	resized.connect(_schedule)
	_scroll.resized.connect(_schedule)
	say("Earliest at the top. Drag the handle ⠿, or use the arrows. The evidence board has the facts.")
	_schedule()


func _schedule() -> void:
	_settle_id += 1
	_settle(_settle_id)


## Wrapped text reports its height a few frames after the width is set, so measure after that.
func _settle(id: int) -> void:
	# leave room for the scroll bar so the list never feeds its own width back
	var w := _scroll.size.x - 12.0
	if w < 40.0:
		return
	_w = w
	for c in cards.values():
		c.body.custom_minimum_size.x = w - 150.0
		c.size = Vector2(w, 0)
	for i in 2:
		await get_tree().process_frame
		if id != _settle_id or not is_inside_tree():
			return
	var h := 0.0
	for c in cards.values():
		h = maxf(h, c.get_combined_minimum_size().y)
	_card_h = ceilf(h)
	for c in cards.values():
		c.size = Vector2(w, _card_h)
	var total := cards.size() * (_card_h + _gap) - _gap
	_list.custom_minimum_size = Vector2(0, total)
	_spine.position = Vector2(25, 0)
	_spine.size = Vector2(2, total)
	_place(false)


func _step() -> float:
	return _card_h + _gap


func _place(animate: bool) -> void:
	for i in order.size():
		var card: TLCard = cards[order[i]]
		card.set_index(i, order.size(), is_done())
		if order[i] == _drag_id:
			continue
		var target := Vector2(0, i * _step())
		if animate and Fx.motion():
			if card.tw:
				card.tw.kill()
			card.tw = create_tween()
			card.tw.tween_property(card, "position", target, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			card.position = target
		card.set_selected(order[i] == _sel)


func move(id: String, to: int) -> void:
	if is_done():
		return
	var a := order.find(id)
	to = clampi(to, 0, order.size() - 1)
	if a == to:
		return
	order.remove_at(a)
	order.insert(to, id)
	_sel = ""
	sfx("paper")
	_place(true)


func tap(id: String) -> void:
	if is_done():
		return
	if _sel == "":
		_sel = id
		sfx("pick")
	elif _sel == id:
		_sel = ""
	else:
		var a := order.find(_sel)
		var b := order.find(id)
		order[a] = id
		order[b] = _sel
		_sel = ""
		sfx("swap")
	_place(true)


# ---------- dragging ----------

func drag_start(card: TLCard) -> void:
	if is_done():
		return
	_drag_id = card.id
	_drag_off = _list.get_local_mouse_position().y - card.position.y
	if card.tw:
		card.tw.kill()
	card.z_index = 5
	card.set_lifted(true)
	sfx("pick")
	haptic(8)


func drag_move() -> void:
	if _drag_id == "":
		return
	var card: TLCard = cards[_drag_id]
	var max_y := (order.size() - 1) * _step()
	card.position.y = clampf(_list.get_local_mouse_position().y - _drag_off, 0.0, max_y)
	var to := clampi(roundi(card.position.y / _step()), 0, order.size() - 1)
	if to != order.find(_drag_id):
		order.erase(_drag_id)
		order.insert(to, _drag_id)
		sfx("tap", 0.05)
		_place(true)
	# near the edge of a short viewport: scroll
	var my := _scroll.get_local_mouse_position().y
	if my < 24.0:
		_scroll.scroll_vertical -= 10
	elif my > _scroll.size.y - 24.0:
		_scroll.scroll_vertical += 10


func drag_end() -> void:
	if _drag_id == "":
		return
	var card: TLCard = cards[_drag_id]
	_drag_id = ""
	card.z_index = 0
	card.set_lifted(false)
	_sel = ""
	sfx("place")
	_place(true)


# ---------- checking ----------

func _on_check() -> void:
	if is_done():
		return
	var n := TimelineModel.in_place(def, order)
	if n == order.size():
		_win()
		return
	sfx("invalid")
	haptic(18)
	say("%d of %d in the right place." % [n, order.size()])
	for i in order.size():
		var ok: bool = def["order"][i] == order[i]
		cards[order[i]].flash(ok)


func _win() -> void:
	sfx("solve")
	haptic(30)
	_check.disabled = true
	_place(false)
	if Fx.motion():
		var tw := create_tween().set_parallel(true)
		tw.tween_property(_spine, "color", Color(UI.AMBER, 0.9), 0.5)
		for i in order.size():
			var card: TLCard = cards[order[i]]
			card.flash(true, 0.09 * i)
	finish(1200 if Fx.motion() else 300)


func qa_state() -> Dictionary:
	var grips := {}
	for id in cards:
		var c: TLCard = cards[id]
		grips[id] = QA.css(c.grip, c.grip.size / 2.0)
	return {"kind": "timeline", "order": order.duplicate(), "solution": def["order"].duplicate(), "grips": grips,
		"step_css": _step(), "done": is_done(),
		"view": [QA.css(_scroll, Vector2.ZERO)[1], QA.css(_scroll, _scroll.size)[1]]}


class TLCard extends PanelContainer:
	var id := ""
	var p: TimelinePuzzle
	var pos_label: Label
	var grip: Label
	var body: VBoxContainer
	var up: Button
	var down: Button
	var tw: Tween
	var _state := "normal"
	var _press := Vector2.ZERO

	func _init(puzzle: TimelinePuzzle, data: Dictionary) -> void:
		p = puzzle
		id = String(data["id"])
		mouse_filter = Control.MOUSE_FILTER_PASS
		var row := UI.hbox(10)
		add_child(row)
		pos_label = UI.label("1", 13, UI.DARK_INK, "mono_bold", HORIZONTAL_ALIGNMENT_CENTER, false)
		pos_label.custom_minimum_size = Vector2(26, 26)
		pos_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var badge := PanelContainer.new()
		badge.add_theme_stylebox_override("panel", UI.flat(UI.AMBER, 13, Color(0, 0, 0, 0), 0, 0))
		badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		badge.add_child(pos_label)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(badge)
		grip = UI.label("⠿", 22, UI.MUTE, "sans", HORIZONTAL_ALIGNMENT_CENTER, false)
		grip.custom_minimum_size = Vector2(30, 40)
		grip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		grip.mouse_filter = Control.MOUSE_FILTER_STOP
		grip.mouse_default_cursor_shape = Control.CURSOR_DRAG
		grip.gui_input.connect(_grip_input)
		UI.qa(grip, "tl.grip." + id)
		row.add_child(grip)
		body = UI.vbox(2)
		body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		body.add_child(UI.label(String(data["title"]), 15, UI.INK, "serif_bold"))
		body.add_child(UI.label(String(data["detail"]), 12, UI.INK2))
		row.add_child(body)
		var arrows := UI.vbox(4)
		arrows.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		up = _arrow("▲")
		down = _arrow("▼")
		arrows.add_child(up)
		arrows.add_child(down)
		up.pressed.connect(func() -> void: p.move(id, p.order.find(id) - 1))
		down.pressed.connect(func() -> void: p.move(id, p.order.find(id) + 1))
		UI.qa(up, "tl.up." + id)
		UI.qa(down, "tl.down." + id)
		row.add_child(arrows)
		resized.connect(func() -> void: pivot_offset = size / 2.0)
		_style("normal")

	func _arrow(txt: String) -> Button:
		var b := Button.new()
		b.text = txt
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(36, 26)
		b.add_theme_font_size_override("font_size", 12)
		b.add_theme_font_override("font", UI.font("sans"))
		for st in ["normal", "hover", "pressed", "disabled"]:
			var sb := UI.flat(Color(1, 1, 1, 0.05 if st != "pressed" else 0.14), 8, UI.LINE, 1, 2)
			b.add_theme_stylebox_override(st, sb)
		b.add_theme_color_override("font_color", UI.INK2)
		b.add_theme_color_override("font_disabled_color", UI.MUTE)
		b.pressed.connect(func() -> void: Sound.sfx("tap"))
		return b

	func _style(s: String) -> void:
		_state = s
		var bg := UI.PANEL
		var border := UI.LINE
		match s:
			"sel":
				bg = UI.PANEL2
				border = UI.AMBER
			"ok":
				bg = Color("1c3a34")
				border = UI.TEAL
			"bad":
				bg = Color("3a2224")
				border = UI.RED
			"lift":
				bg = UI.PANEL2
				border = UI.AMBER2
		add_theme_stylebox_override("panel", UI.flat(bg, 12, border, 1 if s == "normal" else 2, 10))

	func set_index(i: int, n: int, solved: bool) -> void:
		pos_label.text = str(i + 1)
		up.disabled = i == 0 or solved
		down.disabled = i == n - 1 or solved
		up.modulate.a = 0.35 if up.disabled else 1.0
		down.modulate.a = 0.35 if down.disabled else 1.0

	func set_selected(on: bool) -> void:
		if _state in ["ok", "bad", "lift"]:
			return
		_style("sel" if on else "normal")

	func set_lifted(on: bool) -> void:
		_style("lift" if on else "normal")
		if Fx.motion():
			create_tween().tween_property(self, "scale", Vector2(1.025, 1.025) if on else Vector2.ONE, 0.12)

	func flash(ok: bool, delay: float = 0.0) -> void:
		if delay > 0.0:
			await get_tree().create_timer(delay).timeout
		_style("ok" if ok else "bad")
		if Fx.motion():
			var t := create_tween()
			if ok:
				scale = Vector2(1.04, 1.04)
				t.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			else:
				var x0 := position.x
				for d in [8.0, -8.0, 5.0, -5.0, 0.0]:
					t.tween_property(self, "position:x", x0 + d, 0.05)
		if not ok and not p.is_done():
			await get_tree().create_timer(1.1).timeout
			if is_inside_tree() and _state == "bad":
				_style("normal")
		elif ok and not p.is_done():
			await get_tree().create_timer(1.1).timeout
			if is_inside_tree() and _state == "ok" and not p.is_done():
				_style("normal")

	func _grip_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				p.drag_start(self)
			else:
				p.drag_end()
		elif e is InputEventMouseMotion and p._drag_id == id:
			p.drag_move()

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				_press = e.global_position
			elif e.global_position.distance_to(_press) < 8.0:
				p.tap(id)
