class_name RoomPuzzle
extends PuzzleBase
## Explore: tap things in the scene, collect items, use them on other things.
## Items fly into the pockets, can be dragged onto a hotspot (or selected, then tap), and the keypad has a lit display.

var st := RoomModel.new()
var _stage: Control
var _bg: TextureRect
var _msg: Label
var _inv: HFlowContainer
var _root: BoxContainer
var _side: VBoxContainer
var _cards := {}            # hotspot id -> Panel
var _item_cards := {}       # item id -> ItemCard
var _selected := ""
var _drag_item := ""
var _ghost: Control
var _modal: Control
var _kp_entry := ""
var _kp_display: Label
var _kp_leds: Array = []
var _kp_keys := {}
var _w := 300.0
var _h := 375.0
var _done_goal := false


func build() -> void:
	var col := BoxContainer.new()
	_root = col
	col.vertical = true
	col.add_theme_constant_override("separation", 8)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(col)
	var holder := Control.new()
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.resized.connect(func() -> void: _relayout(holder))
	col.add_child(holder)
	_stage = Control.new()
	_stage.clip_contents = true
	_stage.mouse_filter = Control.MOUSE_FILTER_STOP
	_stage.gui_input.connect(_stage_input)
	holder.add_child(_stage)
	_bg = TextureRect.new()
	_bg.texture = Assets.scene(String(def["scene"]))
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg.modulate = Color(0.55, 0.55, 0.58)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_bg)
	for s in def["hotspots"]:
		var card := UI.panel(Color(UI.BG, 0.8), 10, Color(UI.AMBER, 0.55), 1, 4)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var v := UI.vbox(0)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_child(UI.label(String(s["icon"]), 22, Color.WHITE, "sans", HORIZONTAL_ALIGNMENT_CENTER, false))
		var l := UI.label(String(s["label"]), 10, UI.INK, "sans_bold", HORIZONTAL_ALIGNMENT_CENTER)
		l.custom_minimum_size.x = 10
		v.add_child(l)
		card.add_child(v)
		card.set_meta("spot", s)
		_cards[s["id"]] = card
		_stage.add_child(card)
	_side = UI.vbox(8)
	_side.size_flags_vertical = Control.SIZE_EXPAND_FILL if false else Control.SIZE_FILL
	col.add_child(_side)
	_msg = UI.label("Look around. Tap anything that stands out.", 14, UI.INK, "serif_italic", HORIZONTAL_ALIGNMENT_CENTER)
	_msg.custom_minimum_size.y = 40
	_side.add_child(_msg)
	var inv_panel := UI.panel(Color("0c171c"), 10, UI.LINE, 1, 6)
	_inv = HFlowContainer.new()
	_inv.add_theme_constant_override("h_separation", 8)
	_inv.add_theme_constant_override("v_separation", 8)
	_inv.custom_minimum_size.y = 58
	inv_panel.add_child(_inv)
	_side.add_child(inv_panel)
	_ghost = Control.new()
	_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ghost.visible = false
	_ghost.z_index = 50
	add_child(_ghost)
	_refresh(false)
	say("Select an item in your pockets, then tap where to use it. Or drag it there.")
	UI.qa(_stage, "room.stage")


func _relayout(holder: Control) -> void:
	if _side == null:
		return
	var land := landscape
	if land == _root.vertical:
		_root.vertical = not land
		_side.custom_minimum_size.x = 230.0 if land else 0.0
		_side.size_flags_vertical = Control.SIZE_EXPAND_FILL if land else Control.SIZE_FILL
		return
	var s := holder.size
	if s.x < 40.0:
		return
	_h = s.y
	_w = _h * 0.8
	if _w > s.x:
		_w = s.x
		_h = _w / 0.8
	_stage.size = Vector2(_w, _h)
	_stage.position = Vector2((s.x - _w) / 2.0, 0.0)
	_bg.size = _stage.size
	for id in _cards:
		var sp: Dictionary = _cards[id].get_meta("spot")
		var c: Control = _cards[id]
		c.position = Vector2(float(sp["x"]) / 100.0 * _w, float(sp["y"]) / 100.0 * _h)
		c.size = Vector2(float(sp["w"]) / 100.0 * _w, float(sp["h"]) / 100.0 * _h)
		c.pivot_offset = c.size / 2.0
	var need := minf(s.x, 480.0) / 0.8 * 0.72 + 130.0
	ask_height(need)


func _refresh(animate: bool) -> void:
	for id in _cards:
		var c: PanelContainer = _cards[id]
		var sp: Dictionary = c.get_meta("spot")
		var vis := RoomModel.spot_visible(sp, st)
		var was := c.visible
		c.visible = vis
		var used: bool = st.used.has(id) and not sp.get("keypad", false)
		c.add_theme_stylebox_override("panel", UI.flat(Color(UI.BG, 0.8), 10, UI.LINE if used else Color(UI.AMBER, 0.55), 1, 4))
		c.modulate.a = 0.6 if used else 1.0
		if vis and not was and animate and Fx.motion():
			c.scale = Vector2.ZERO
			create_tween().tween_property(c, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# pockets
	for c in _inv.get_children():
		c.queue_free()
	_item_cards.clear()
	if st.items.is_empty():
		_inv.add_child(UI.label("Pockets: empty", 13, UI.MUTE, "sans", HORIZONTAL_ALIGNMENT_LEFT, false))
	for id in st.items:
		var card := ItemCard.new(self, id, def["items"][id])
		_item_cards[id] = card
		card.set_selected(_selected == id)
		_inv.add_child(card)
		UI.qa(card, "room.item." + id)


func _spot_at(pos: Vector2) -> Dictionary:
	var best := {}
	for s in def["hotspots"]:
		if not RoomModel.spot_visible(s, st):
			continue
		var r := Rect2(float(s["x"]) / 100.0 * _w, float(s["y"]) / 100.0 * _h, float(s["w"]) / 100.0 * _w, float(s["h"]) / 100.0 * _h)
		if r.has_point(pos):
			best = s
	return best


func _stage_input(e: InputEvent) -> void:
	if is_done() or _modal != null:
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
		var s := _spot_at(e.position)
		if not s.is_empty():
			_tap(s, _selected)


func _tap(s: Dictionary, item: String) -> void:
	if is_done():
		return
	var card: Control = _cards[s["id"]]
	var r := st.use_spot(def, s, item)
	if r["keypad"]:
		_open_keypad()
		return
	if r["ok"]:
		if s.has("gives") and not _was_used_before(s):
			sfx("found")
			haptic(8)
			_fly_item(String(s["gives"]), card)
		elif s.has("needs"):
			sfx("latch")
		else:
			sfx("tap")
		if s.has("needs"):
			_selected = ""
	else:
		sfx("invalid")
		Fx.shake(card, 5.0, 0.25)
	if Fx.motion():
		Fx.pop(card, 1.08, 0.16)
	_say_msg(String(r["text"]))
	_refresh(true)
	_check_goal()


func _was_used_before(_s: Dictionary) -> bool:
	return false


func _say_msg(t: String) -> void:
	_msg.text = t
	if Fx.motion() and t != "":
		_msg.visible_ratio = 0.0
		create_tween().tween_property(_msg, "visible_ratio", 1.0, minf(float(t.length()) / 90.0, 1.2))


func _fly_item(id: String, from: Control) -> void:
	if not Fx.motion():
		return
	var fly := ItemCard.new(null, id, def["items"][id])
	fly.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fly)
	fly.z_index = 60
	fly.size = Vector2(60, 56)
	fly.global_position = from.get_global_rect().get_center() - fly.size / 2.0
	fly.scale = Vector2.ZERO
	fly.pivot_offset = fly.size / 2.0
	await get_tree().process_frame
	var target := _inv.get_global_rect().position + Vector2(40, 18)
	var tw := create_tween()
	tw.tween_property(fly, "scale", Vector2(1.3, 1.3), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(fly, "global_position", target, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(fly, "scale", Vector2(0.7, 0.7), 0.45)
	tw.tween_callback(fly.queue_free)


func select_item(id: String) -> void:
	_selected = "" if _selected == id else id
	sfx("pick")
	for k in _item_cards:
		_item_cards[k].set_selected(_selected == k)
	if _selected != "":
		_say_msg("Holding: %s. Tap where to use it." % def["items"][id]["label"])
	else:
		_say_msg("")


# ---------- drag an item onto the scene ----------

func drag_begin(id: String) -> void:
	_drag_item = id
	_ghost.visible = true
	for c in _ghost.get_children():
		c.queue_free()
	var g := ItemCard.new(null, id, def["items"][id])
	g.modulate.a = 0.9
	g.size = Vector2(60, 56)
	_ghost.add_child(g)
	_drag_move()


func _drag_move() -> void:
	if _drag_item == "":
		return
	_ghost.position = get_local_mouse_position() - Vector2(30, 70)


func drag_end() -> void:
	if _drag_item == "":
		return
	var id := _drag_item
	_drag_item = ""
	_ghost.visible = false
	var local := _stage.get_local_mouse_position()
	var s := _spot_at(local)
	if not s.is_empty() and Rect2(Vector2.ZERO, _stage.size).has_point(local):
		_tap(s, id)
	else:
		_say_msg("")


func _process(_d: float) -> void:
	if _drag_item != "":
		_drag_move()


# ---------- keypad ----------

func _open_keypad() -> void:
	if _modal:
		return
	var kp: Dictionary = def["keypad"]
	_kp_entry = ""
	_modal = Control.new()
	_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_modal)
	_modal.size = size
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal.add_child(dim)
	var box := UI.panel(Color("10202a"), 14, UI.AMBER, 1, 14)
	_modal.add_child(box)
	var v := UI.vbox(8)
	box.add_child(v)
	v.add_child(UI.label(String(kp["label"]), 11, UI.AMBER2, "mono_bold", HORIZONTAL_ALIGNMENT_CENTER))
	var disp := PanelContainer.new()
	disp.add_theme_stylebox_override("panel", UI.flat(Color("07100c"), 8, Color("1d3a2c"), 2, 8))
	_kp_display = UI.label("", 30, Color("6df0a0"), "mono_bold", HORIZONTAL_ALIGNMENT_CENTER, false)
	disp.add_child(_kp_display)
	v.add_child(disp)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	for k in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "C", "0", "✓"]:
		var b := FxButton.new(k, "primary" if k == "✓" else "normal")
		b.custom_minimum_size = Vector2(62, 40)
		b.pressed.connect(func() -> void: _kp_press(k))
		UI.qa(b, "kp." + k)
		_kp_keys[k] = b
		grid.add_child(b)
	v.add_child(grid)
	var back := FxButton.new("Step back", "ghost")
	back.pressed.connect(_close_keypad)
	UI.qa(back, "kp.back")
	v.add_child(back)
	var bw := minf(size.x - 24.0, 280.0)
	box.custom_minimum_size.x = bw
	box.size = Vector2(bw, 0)
	_modal.modulate.a = 0.0
	# wrapped text reports its height a couple of frames after the width is set
	for _f in 3:
		await get_tree().process_frame
	box.size = Vector2(bw, 0)
	box.position = ((size - Vector2(bw, box.get_combined_minimum_size().y)) / 2.0).floor()
	_modal.modulate.a = 1.0
	_kp_show()
	if Fx.motion():
		Fx.fade_in(_modal, 0.2)


func _kp_show() -> void:
	var n := String(def["keypad"]["code"]).length()
	var shown := _kp_entry
	while shown.length() < n:
		shown += "·"
	_kp_display.text = " ".join(shown.split(""))


func _kp_press(k: String) -> void:
	var kp: Dictionary = def["keypad"]
	if k == "C":
		_kp_entry = ""
	elif k == "✓":
		if st.enter_code(def, _kp_entry):
			sfx("door")
			haptic(24)
			_kp_display.add_theme_color_override("font_color", Color("9dffbf"))
			_say_msg("The lock releases.")
			if Fx.motion():
				await get_tree().create_timer(0.35).timeout
			_close_keypad()
			_refresh(true)
			_check_goal()
			return
		sfx("invalid")
		haptic(20)
		_kp_display.add_theme_color_override("font_color", UI.RED)
		Fx.shake(_kp_display, 6.0, 0.3)
		_kp_entry = ""
		get_tree().create_timer(0.35).timeout.connect(func() -> void:
			if _kp_display:
				_kp_display.add_theme_color_override("font_color", Color("6df0a0")))
	elif _kp_entry.length() < String(kp["code"]).length():
		_kp_entry += k
		sfx("click")
	_kp_show()


func _close_keypad() -> void:
	if _modal:
		_modal.queue_free()
		_modal = null
		_kp_keys.clear()
		_kp_display = null


func _check_goal() -> void:
	if not _done_goal and st.goal_reached(def):
		_done_goal = true
		sfx("door")
		haptic(30)
		if Fx.motion():
			Fx.burst(_stage, _stage.size / 2.0, UI.AMBER2, 30, 300.0, 5.0)
		finish(1200 if Fx.motion() else 300)


func board_hint(level: int) -> Dictionary:
	if _modal:
		return {"text": "The code is in what you have found in this room."}
	var step := RoomModel.next_step(def, st)
	if step.is_empty():
		return {}
	var spot: Dictionary = {}
	for s in def["hotspots"]:
		if s["id"] == step[0]:
			spot = s
	var r := Rect2(float(spot["x"]) / 100.0 * _w, float(spot["y"]) / 100.0 * _h, float(spot["w"]) / 100.0 * _w, float(spot["h"]) / 100.0 * _h)
	var item: String = step[1]
	if level < 2:
		return {"rects": [view_rect(_stage, r)], "text": "Have another look at the %s." % String(spot["label"]).to_lower()}
	var rects := []
	if item != "" and _item_cards.has(item):
		var c: Control = _item_cards[item]
		rects.append(view_rect(c, Rect2(Vector2.ZERO, c.size)))
	rects.append(view_rect(_stage, r))
	var text := "Use the %s on the %s." % [String(def["items"][item]["label"]).to_lower(), String(spot["label"]).to_lower()] if item != "" else "Tap the %s." % String(spot["label"]).to_lower()
	if step[2] == "keypad":
		text = "Open the keypad. The code is in what you have read here."
	return {"rects": rects, "text": text}

func qa_state() -> Dictionary:
	var spots := []
	for s in def["hotspots"]:
		if RoomModel.spot_visible(s, st):
			var r := Rect2(float(s["x"]) / 100.0 * _w, float(s["y"]) / 100.0 * _h, float(s["w"]) / 100.0 * _w, float(s["h"]) / 100.0 * _h)
			var pt: Array = QA.css(_stage, r.get_center())
			spots.append({"id": s["id"], "x": pt[0], "y": pt[1]})
	var inv := []
	for id in _item_cards:
		var c: Control = _item_cards[id]
		var pt: Array = QA.css(c, c.size / 2.0)
		inv.append({"id": id, "x": pt[0], "y": pt[1]})
	return {"kind": "room", "spots": spots, "items": inv, "flags": st.flags.keys(), "steps": RoomModel.auto_solve(def),
		"keypad_open": _modal != null, "code": String(def["keypad"]["code"]) if def.has("keypad") else "", "msg": _msg.text, "done": is_done()}


class ItemCard extends PanelContainer:
	var p: RoomPuzzle
	var id := ""
	var _press := Vector2.ZERO
	var _dragging := false

	func _init(puzzle: RoomPuzzle, item_id: String, data: Dictionary) -> void:
		p = puzzle
		id = item_id
		custom_minimum_size = Vector2(64, 52)
		mouse_filter = Control.MOUSE_FILTER_STOP if puzzle != null else Control.MOUSE_FILTER_IGNORE
		var v := UI.vbox(0)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		var tex := Assets.item(item_id)
		if tex:
			var tr := TextureRect.new()
			tr.texture = tex
			tr.custom_minimum_size = Vector2(32, 32)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			v.add_child(tr)
		else:
			v.add_child(UI.label(String(data["icon"]), 22, Color.WHITE, "sans", HORIZONTAL_ALIGNMENT_CENTER, false))
		v.add_child(UI.label(String(data["label"]), 10, UI.INK, "sans", HORIZONTAL_ALIGNMENT_CENTER, false))
		add_child(v)
		set_selected(false)

	func set_selected(on: bool) -> void:
		add_theme_stylebox_override("panel", UI.flat(UI.PANEL, 8, UI.AMBER if on else UI.LINE, 2 if on else 1, 4))

	func _gui_input(e: InputEvent) -> void:
		if p == null:
			return
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				_press = e.global_position
				_dragging = false
			else:
				if _dragging:
					p.drag_end()
				elif e.global_position.distance_to(_press) < 8.0:
					p.select_item(id)
				_dragging = false
		elif e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			if not _dragging and e.global_position.distance_to(_press) > 10.0:
				_dragging = true
				p.drag_begin(id)
