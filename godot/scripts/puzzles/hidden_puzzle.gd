class_name HiddenPuzzle
extends PuzzleBase
## Search: find the listed items in the cluttered scene. A found item pops, flies to its place on the list and ticks it off.
## A miss ripples out. After a long quiet spell a faint glimmer points at something still missing.

var spots: Array = []         # {id, x, y, node, found}
var need := {}
var got := {}
var chips := {}               # target id -> {panel, count_label}
var _stage: Control
var _scene_holder: Control
var _bg: TextureRect
var _list: HFlowContainer
var _idle := 0.0
var _glint: Control
var _w := 300.0
var _h := 400.0


func build() -> void:
	for t in def["targets"]:
		spots.append({"id": t["id"], "x": float(t["x"]), "y": float(t["y"]), "found": false})
		var extra: Array = def.get("extra", {}).get(t["id"], [])
		for xy in extra:
			spots.append({"id": t["id"], "x": float(xy[0]), "y": float(xy[1]), "found": false})
	for t in def["targets"]:
		var n := 0
		for s in spots:
			if s["id"] == t["id"]:
				n += 1
		need[t["id"]] = n
		got[t["id"]] = 0
	var col := UI.vbox(8)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(col)
	_scene_holder = Control.new()
	_scene_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scene_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scene_holder.resized.connect(_relayout)
	col.add_child(_scene_holder)
	_stage = Control.new()
	_stage.clip_contents = true
	_stage.mouse_filter = Control.MOUSE_FILTER_STOP
	_stage.gui_input.connect(_stage_input)
	_scene_holder.add_child(_stage)
	_bg = TextureRect.new()
	_bg.texture = Assets.scene(String(def["scene"]))
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg.modulate = Color(0.62, 0.62, 0.66)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_bg)
	# clutter first, away from the targets so none is fully covered
	var glyphs: Array = def["clutterGlyphs"]
	var placed := 0
	var tries := 0
	while placed < int(def["clutter"]) and tries < int(def["clutter"]) * 20:
		tries += 1
		var x := 4.0 + rng.randf() * 92.0
		var y := 4.0 + rng.randf() * 92.0
		var near := false
		for s in spots:
			if Vector2(s["x"] - x, (s["y"] - y) * 0.75).length() < 5.0:
				near = true
		if near:
			continue
		var g := UI.label(String(glyphs[rng.randi_range(0, glyphs.size() - 1)]), 26, Color.WHITE, "sans", HORIZONTAL_ALIGNMENT_CENTER, false)
		g.set_meta("pct", Vector2(x, y))
		g.rotation = deg_to_rad(rng.randf_range(-35, 35))
		g.scale = Vector2.ONE * rng.randf_range(0.7, 1.3)
		g.modulate.a = rng.randf_range(0.55, 0.95)
		_stage.add_child(g)
		placed += 1
	for s in spots:
		var t := _target(String(s["id"]))
		var g := UI.label(String(t["glyph"]), 26, Color.WHITE, "sans", HORIZONTAL_ALIGNMENT_CENTER, false)
		g.set_meta("pct", Vector2(s["x"], s["y"]))
		g.rotation = deg_to_rad(rng.randf_range(-25, 25))
		s["node"] = g
		_stage.add_child(g)
	# the list
	_list = HFlowContainer.new()
	_list.add_theme_constant_override("h_separation", 6)
	_list.add_theme_constant_override("v_separation", 6)
	_list.alignment = FlowContainer.ALIGNMENT_CENTER
	col.add_child(_list)
	for t in def["targets"]:
		var panel := UI.panel(Color(UI.PANEL, 0.95), 10, UI.LINE, 1, 8)
		var row := UI.hbox(6)
		row.add_child(UI.label(String(t["glyph"]), 16, Color.WHITE, "sans", HORIZONTAL_ALIGNMENT_CENTER, false))
		row.add_child(UI.label(String(t["label"]), 12, UI.INK, "sans", HORIZONTAL_ALIGNMENT_LEFT, false))
		var cnt := UI.label("", 12, UI.TEAL, "mono_bold", HORIZONTAL_ALIGNMENT_LEFT, false)
		row.add_child(cnt)
		panel.add_child(row)
		_list.add_child(panel)
		chips[t["id"]] = {"panel": panel, "count": cnt}
	_refresh()
	say("Tap the items on the list. Missing costs nothing.")
	UI.qa(_stage, "hidden.scene")


func _target(id: String) -> Dictionary:
	for t in def["targets"]:
		if t["id"] == id:
			return t
	return {}


func _relayout() -> void:
	var s := _scene_holder.size
	if s.x < 40.0:
		return
	_h = s.y
	_w = _h * 0.75
	if _w > s.x:
		_w = s.x
		_h = _w / 0.75
	_stage.size = Vector2(_w, _h)
	_stage.position = Vector2((s.x - _w) / 2.0, 0)
	_bg.size = _stage.size
	for c in _stage.get_children():
		if c.has_meta("pct"):
			var pct: Vector2 = c.get_meta("pct")
			c.size = Vector2(40, 40)
			c.pivot_offset = c.size / 2.0
			c.position = Vector2(pct.x / 100.0 * _w, pct.y / 100.0 * _h) - c.size / 2.0
	var need_h := _w / 0.75 * 0.0 + minf(s.x, 480.0) / 0.75 * 0.66 + 90.0
	if absf(custom_minimum_size.y - need_h) > 1.0:
		custom_minimum_size.y = need_h


func _process(d: float) -> void:
	if is_done():
		return
	_idle += d
	if _idle > 25.0 and _glint == null:
		_show_glint()


func _show_glint() -> void:
	for s in spots:
		if not s["found"]:
			var n: Label = s["node"]
			_glint = Control.new()
			_glint.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_glint.position = n.position + n.size / 2.0
			_glint.draw.connect(func() -> void:
				var t := Time.get_ticks_msec() / 1000.0
				var r := 18.0 + 6.0 * sin(t * 3.0)
				_glint.draw_arc(Vector2.ZERO, r, 0.0, TAU, 28, Color(UI.AMBER2, 0.35 + 0.2 * sin(t * 3.0)), 2.0, true))
			_stage.add_child(_glint)
			var tw := create_tween().set_loops()
			tw.tween_callback(func() -> void: _glint.queue_redraw())
			tw.tween_interval(0.03)
			return


func _clear_glint() -> void:
	_idle = 0.0
	if _glint:
		_glint.queue_free()
		_glint = null


func _stage_input(e: InputEvent) -> void:
	if is_done():
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
		var best := -1
		var bd := 26.0
		for i in spots.size():
			if spots[i]["found"]:
				continue
			var n: Label = spots[i]["node"]
			var d: float = (n.position + n.size / 2.0).distance_to(e.position)
			if d < bd:
				bd = d
				best = i
		if best >= 0:
			_found(best)
		else:
			Fx.ripple(_stage, e.position, Color(1, 1, 1, 0.5))
			sfx("tap", 0.05)
			_idle = 0.0


func _found(i: int) -> void:
	var s: Dictionary = spots[i]
	s["found"] = true
	got[s["id"]] = int(got[s["id"]]) + 1
	_clear_glint()
	sfx("found")
	haptic(10)
	var t := _target(String(s["id"]))
	say("Found: %s" % t["label"])
	var n: Label = s["node"]
	n.z_index = 10
	n.modulate.a = 1.0
	if Fx.motion():
		Fx.burst(_stage, n.position + n.size / 2.0, UI.AMBER2, 12, 160.0, 3.0)
		var chip: Control = chips[s["id"]]["panel"]
		var target_local: Vector2 = _stage.get_global_transform().affine_inverse() * (chip.get_global_rect().get_center())
		var tw := create_tween()
		tw.tween_property(n, "scale", Vector2(2.0, 2.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.08)
		tw.set_parallel(true)
		tw.tween_property(n, "position", target_local - n.size / 2.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.tween_property(n, "scale", Vector2(0.4, 0.4), 0.35)
		tw.tween_property(n, "modulate:a", 0.0, 0.35)
		tw.chain().tween_callback(func() -> void:
			n.visible = false
			_refresh()
			var pnl: Control = chips[s["id"]]["panel"]
			Fx.pop(pnl, 1.12, 0.2))
	else:
		n.visible = false
		_refresh()
	var all := true
	for id in need:
		if int(got[id]) < int(need[id]):
			all = false
	if all:
		sfx("solve")
		finish(1000 if Fx.motion() else 300)


func _refresh() -> void:
	for t in def["targets"]:
		var id: String = t["id"]
		var n := int(need[id])
		var g := int(got[id])
		var cnt: Label = chips[id]["count"]
		cnt.text = ("%d/%d" % [g, n]) if n > 1 else ("✓" if g > 0 else "")
		var pnl: PanelContainer = chips[id]["panel"]
		var done := g >= n
		pnl.add_theme_stylebox_override("panel", UI.flat(Color(UI.TEAL, 0.18) if done else Color(UI.PANEL, 0.95), 10, UI.TEAL if done else UI.LINE, 1, 8))
		pnl.modulate.a = 0.6 if done else 1.0


func qa_state() -> Dictionary:
	var pts := []
	for s in spots:
		var n: Label = s["node"]
		var pt: Array = QA.css(_stage, n.position + n.size / 2.0)
		pts.append({"id": s["id"], "x": pt[0], "y": pt[1], "found": s["found"]})
	return {"kind": "hidden", "spots": pts, "got": got.duplicate(), "need": need.duplicate(), "done": is_done(),
		"miss": QA.css(_stage, Vector2(_w * 0.5, 4.0))}
