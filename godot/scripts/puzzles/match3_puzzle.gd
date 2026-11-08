class_name Match3Puzzle
extends PuzzleBase
## Signal recovery: match tiles to wipe the static off the picture underneath. Four in a row makes a line clearer.
## Swaps slide, tiles pop in a burst, the column above drops with a bounce, and cascades keep going on their own.

const COLORS := [Color("e8b877"), Color("7fb7ad"), Color("c8665a"), Color("9a8fc9"), Color("d9d2c2"), Color("6f9ed6")]

var m: Match3Model
var total := 1
var nodes := {}
var static_cells := {}
var _stage := Control.new()
var _frame := Panel.new()
var _board: Control
var _meter: Control
var _art: TextureRect
var _cell := 40.0
var _origin := Vector2.ZERO
var _sel := -1
var _busy := false
var _progress := 0.0:
	set(v):
		_progress = v
		if _meter:
			_meter.queue_redraw()
var _spawn_k := {}


func build() -> void:
	m = Match3Model.create(def, seed_value)
	total = maxi(m.static_left(), 1)
	var col := UI.vbox(8)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(col)
	_meter = Control.new()
	_meter.custom_minimum_size.y = 8
	_meter.draw.connect(_draw_meter)
	col.add_child(_meter)
	_board = Control.new()
	_board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board.mouse_filter = Control.MOUSE_FILTER_STOP
	_board.gui_input.connect(_board_input)
	col.add_child(_board)
	_frame.add_theme_stylebox_override("panel", UI.flat(Color(UI.BG, 0.0), 12, UI.LINE, 2, 0))
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_board.add_child(_frame)
	_stage.clip_contents = true
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_board.add_child(_stage)
	# the picture under the static
	_art = TextureRect.new()
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.texture = _reveal_texture()
	_stage.add_child(_art)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/static.gdshader")
	for i in m.n * m.n:
		if m.stat[i]:
			var r := ColorRect.new()
			r.color = Color.WHITE
			r.material = mat
			r.mouse_filter = Control.MOUSE_FILTER_IGNORE
			static_cells[i] = r
			_stage.add_child(r)
	for i in m.n * m.n:
		var t: Dictionary = m.tiles[i]
		nodes[t["id"]] = _make_tile(t)
	_board.resized.connect(_relayout)
	_relayout.call_deferred()
	UI.qa(_board, "m3.board")
	_status()


func _reveal_texture() -> Texture2D:
	var key := String(def["reveal"].get("art", ""))
	if key == "van":
		return Assets.scene("yard")
	if key == "driver":
		return Assets.portrait({"key": "DANIEL", "mood": "", "remote": false})
	return null


func _make_tile(t: Dictionary) -> M3Tile:
	var n := M3Tile.new(int(t["c"]), String(t["sp"]))
	_stage.add_child(n)
	return n


func _draw_meter() -> void:
	var w := _meter.size.x
	_meter.draw_style_box(UI.flat(UI.LINE, 4), Rect2(0, 0, w, 8))
	if _progress > 0.0:
		_meter.draw_style_box(UI.flat(UI.AMBER, 4), Rect2(0, 0, maxf(w * _progress, 8.0), 8))


func _status() -> void:
	var left := m.static_left()
	say("Static left on %d square%s" % [left, "" if left == 1 else "s"] if left > 0 else "Signal restored.")
	var target := 1.0 - float(left) / float(total)
	if Fx.motion():
		create_tween().tween_property(self, "_progress", target, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		_progress = target


func _relayout() -> void:
	var s := _board.size
	_cell = floorf(minf(s.x, s.y) / m.n)
	if _cell < 8.0:
		return
	var bs := Vector2(_cell * m.n, _cell * m.n)
	_origin = ((s - bs) / 2.0).floor()
	_stage.position = _origin
	_stage.size = bs
	_frame.position = _origin - Vector2(2, 2)
	_frame.size = bs + Vector2(4, 4)
	_art.size = bs
	for i in static_cells:
		static_cells[i].position = _cell_pos(i)
		static_cells[i].size = Vector2(_cell, _cell)
	for i in m.n * m.n:
		var t: Dictionary = m.tiles[i]
		if nodes.has(t["id"]):
			var nd: M3Tile = nodes[t["id"]]
			nd.size = Vector2(_cell, _cell)
			nd.pivot_offset = nd.size / 2.0
			nd.position = _cell_pos(i)
	# keep the page asking for a square board plus the meter
	var need := minf(s.x, 480.0) + 20.0
	if s.x > 0.0:
		ask_height(need)


func _cell_pos(i: int) -> Vector2:
	return Vector2(i % m.n, i / m.n) * _cell


func _cell_center(i: int) -> Vector2:
	return _cell_pos(i) + Vector2(_cell, _cell) / 2.0


# ---------- input ----------

var _down := -1
var _down_pos := Vector2.ZERO
var _swiped := false


func _idx_at(p: Vector2) -> int:
	var q := (p - _origin) / _cell
	if q.x < 0 or q.y < 0 or q.x >= m.n or q.y >= m.n:
		return -1
	return int(q.y) * m.n + int(q.x)


func _board_input(e: InputEvent) -> void:
	if is_done():
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_down = _idx_at(e.position)
			_down_pos = e.position
			_swiped = false
		else:
			if _down >= 0 and not _swiped:
				var i := _idx_at(e.position)
				if i == _down:
					_tap(i)
			_down = -1
	elif e is InputEventMouseMotion and _down >= 0 and not _swiped:
		var d: Vector2 = e.position - _down_pos
		if d.length() > _cell * 0.4:
			_swiped = true
			var j := _down
			if absf(d.x) > absf(d.y):
				if (d.x > 0 and _down % m.n < m.n - 1) or (d.x < 0 and _down % m.n > 0):
					j = _down + (1 if d.x > 0 else -1)
			else:
				j = _down + (m.n if d.y > 0 else -m.n)
			if j != _down and j >= 0 and j < m.n * m.n:
				_try_swap(_down, j)


func _tap(i: int) -> void:
	if _busy:
		return
	if _sel == -1:
		_sel = i
		sfx("pick")
		_mark_selected()
	elif _sel == i:
		_sel = -1
		_mark_selected()
	elif m.adjacent(_sel, i):
		_try_swap(_sel, i)
	else:
		_sel = i
		sfx("pick")
		_mark_selected()


func _mark_selected() -> void:
	for i in m.n * m.n:
		var t: Dictionary = m.tiles[i]
		if nodes.has(t["id"]):
			nodes[t["id"]].set_selected(i == _sel)


# ---------- moves ----------

func _wait(tw: Tween, added: int) -> void:
	if added == 0:
		tw.kill()
		await get_tree().process_frame
	else:
		await tw.finished


func _slide(a: int, b: int, dur: float) -> void:
	var na: M3Tile = nodes[m.tiles[a]["id"]]
	var nb: M3Tile = nodes[m.tiles[b]["id"]]
	var pa := _cell_pos(a)
	var pb := _cell_pos(b)
	if not Fx.motion():
		na.position = pa
		nb.position = pb
		return
	var tw := create_tween().set_parallel(true)
	tw.tween_property(na, "position", pa, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(nb, "position", pb, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw.finished


func _try_swap(a: int, b: int) -> void:
	if _busy or is_done() or not m.adjacent(a, b):
		return
	_busy = true
	_sel = -1
	_mark_selected()
	m.swap_tiles(a, b)
	if m.find_matches()["cells"].is_empty():
		# show the swap, then slide back
		await _slide(a, b, 0.11)
		sfx("invalid")
		haptic(10)
		m.swap_tiles(a, b)
		await _slide(a, b, 0.13)
		_busy = false
		return
	sfx("swap")
	await _slide(a, b, 0.11)
	var chain := 0
	var prefer := [a, b]
	while true:
		var res := m.step(prefer)
		prefer = []
		if res.is_empty():
			break
		chain += 1
		sfx("combo" if chain > 1 else "clear", 0.04 * chain)
		haptic(8)
		await _animate_step(res)
	if m.has_move().is_empty():
		say("No moves left. Reshuffled.")
		await _reshuffle()
	else:
		_status()
	_busy = false
	if m.static_left() == 0:
		_win()


func _animate_step(res: Dictionary) -> void:
	for c in res["cleared"]:
		var nd: M3Tile = nodes.get(c["id"])
		nodes.erase(c["id"])
		if nd == null:
			continue
		if Fx.motion():
			Fx.burst(_stage, _cell_center(int(c["i"])), COLORS[int(c["c"]) % COLORS.size()], 7, 150.0, 3.0)
			nd.z_index = 5
			var seq := create_tween()
			seq.tween_property(nd, "scale", Vector2(1.3, 1.3), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			seq.tween_property(nd, "scale", Vector2.ZERO, 0.11).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			seq.tween_callback(nd.queue_free)
		else:
			nd.queue_free()
	for b in res["beams"]:
		_beam(int(b["at"]), String(b["sp"]))
	for i in res["static_cleared"]:
		var r: ColorRect = static_cells.get(i)
		if r:
			static_cells.erase(i)
			if Fx.motion():
				var f := create_tween()
				f.tween_property(r, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_QUAD)
				f.tween_callback(r.queue_free)
			else:
				r.queue_free()
	for mk in res["made"]:
		var nd := _make_tile({"c": mk["c"], "sp": mk["sp"], "id": mk["id"]})
		nd.size = Vector2(_cell, _cell)
		nd.pivot_offset = nd.size / 2.0
		nd.position = _cell_pos(int(mk["at"]))
		nodes[mk["id"]] = nd
		if Fx.motion():
			nd.scale = Vector2.ZERO
			var pi := create_tween()
			pi.tween_interval(0.12)
			pi.tween_property(nd, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_status()
	if Fx.motion():
		await get_tree().create_timer(0.2).timeout
	# gravity: everything left falls into place, new tiles drop in from above
	_spawn_k.clear()
	var fall := create_tween().set_parallel(true)
	var moved := 0
	for i in m.n * m.n:
		var t: Dictionary = m.tiles[i]
		var nd: M3Tile = nodes.get(t["id"])
		if nd == null:
			nd = _make_tile(t)
			nd.size = Vector2(_cell, _cell)
			nd.pivot_offset = nd.size / 2.0
			nodes[t["id"]] = nd
			var col := i % m.n
			var k: int = _spawn_k.get(col, 0)
			_spawn_k[col] = k + 1
			nd.position = Vector2(col * _cell, -(k + 1) * _cell)
		var target := _cell_pos(i)
		if nd.position.distance_to(target) > 0.5:
			if Fx.motion():
				var rows: float = absf(nd.position.y - target.y) / _cell
				fall.tween_property(nd, "position", target, 0.16 + 0.05 * rows).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
				moved += 1
			else:
				nd.position = target
	if moved > 0:
		await fall.finished
	else:
		fall.kill()
		await get_tree().process_frame


func _beam(at: int, sp: String) -> void:
	if not Fx.motion():
		return
	var r := ColorRect.new()
	r.color = Color(1.0, 0.93, 0.7, 0.85)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.z_index = 8
	var row := at / m.n
	var col := at % m.n
	if sp == "row":
		r.position = Vector2(0, row * _cell + _cell * 0.3)
		r.size = Vector2(_cell * m.n, _cell * 0.4)
	else:
		r.position = Vector2(col * _cell + _cell * 0.3, 0)
		r.size = Vector2(_cell * 0.4, _cell * m.n)
	r.pivot_offset = r.size / 2.0
	_stage.add_child(r)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(r, "modulate:a", 0.0, 0.35)
	tw.tween_property(r, "scale", Vector2(1.0, 0.1) if sp == "row" else Vector2(0.1, 1.0), 0.35)
	tw.chain().tween_callback(r.queue_free)
	sfx("static")


func _reshuffle() -> void:
	m.reshuffle()
	var old := nodes.values()
	nodes.clear()
	var tw := create_tween().set_parallel(true)
	for nd in old:
		tw.tween_property(nd, "modulate:a", 0.0, 0.2)
		tw.tween_property(nd, "scale", Vector2(0.5, 0.5), 0.2)
	if Fx.motion():
		await tw.finished
	else:
		tw.kill()
	for nd in old:
		nd.queue_free()
	for i in m.n * m.n:
		var t: Dictionary = m.tiles[i]
		var nd := _make_tile(t)
		nd.size = Vector2(_cell, _cell)
		nd.pivot_offset = nd.size / 2.0
		nd.position = _cell_pos(i)
		nodes[t["id"]] = nd
		if Fx.motion():
			Fx.fade_in(nd, 0.25)
	_status()


func _win() -> void:
	sfx("solve")
	haptic(30)
	var reveal: Dictionary = def["reveal"]
	if Fx.motion():
		var tw := create_tween().set_parallel(true)
		for nd in nodes.values():
			tw.tween_property(nd, "modulate:a", 0.0, 0.5)
			tw.tween_property(nd, "scale", Vector2(1.4, 1.4), 0.5)
		# caption slides in over the picture
		var box := UI.panel(Color(UI.BG, 0.82), 0, Color(0, 0, 0, 0), 0, 12)
		var v := UI.vbox(2)
		v.add_child(UI.eyebrow(String(reveal["title"])))
		for l in reveal["lines"]:
			v.add_child(UI.label(String(l), 13, UI.INK, "mono", HORIZONTAL_ALIGNMENT_LEFT, false))
		box.add_child(v)
		box.size = Vector2(_stage.size.x, 0)
		_stage.add_child(box)
		box.reset_size()
		box.size.x = _stage.size.x
		box.position = Vector2(0, _stage.size.y)
		var tw2 := create_tween()
		tw2.tween_interval(0.5)
		tw2.tween_property(box, "position:y", _stage.size.y - box.size.y, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	finish(2600 if Fx.motion() else 800)


func qa_state() -> Dictionary:
	var grid := []
	var centers := []
	for i in m.n * m.n:
		grid.append([m.tiles[i]["c"], m.tiles[i]["sp"]])
		var pt: Array = QA.css(_stage, _cell_center(i))
		centers.append(pt)
	return {"kind": "match3", "n": m.n, "tiles": grid, "static": m.stat.duplicate(), "left": m.static_left(),
		"centers": centers, "cell_css": _cell, "legal": _legal(), "move": m.has_move(), "busy": _busy, "done": is_done()}


func _legal() -> Array:
	var out := []
	for a in m.n * m.n:
		for b in [a + 1, a + m.n]:
			if b < m.n * m.n and m.adjacent(a, b):
				m.swap_tiles(a, b)
				if not m.find_matches()["cells"].is_empty():
					out.append([a, b])
				m.swap_tiles(a, b)
	return out


class M3Tile extends Control:
	var c := 0
	var sp := ""
	var tex: Texture2D
	var _sel := false
	var _t := 0.0

	func _init(color_index: int, special: String) -> void:
		c = color_index
		sp = special
		tex = Assets.tile(color_index % 5)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_selected(on: bool) -> void:
		_sel = on
		if Fx.motion():
			create_tween().tween_property(self, "scale", Vector2(1.12, 1.12) if on else Vector2.ONE, 0.1)
		queue_redraw()

	func _process(d: float) -> void:
		if sp != "":
			_t += d
			queue_redraw()

	func _draw() -> void:
		var s := size.x
		if s < 4.0:
			return
		var ctr := size / 2.0
		draw_circle(ctr + Vector2(0, s * 0.03), s * 0.44, Color(0, 0, 0, 0.38))
		if tex:
			var ts := s * 0.84
			draw_texture_rect(tex, Rect2(ctr - Vector2(ts, ts) / 2.0, Vector2(ts, ts)), false)
		else:
			draw_circle(ctr, s * 0.36, Match3Puzzle.COLORS[c % Match3Puzzle.COLORS.size()])
		if _sel:
			draw_arc(ctr, s * 0.46, 0.0, TAU, 32, UI.AMBER2, 3.0, true)
		if sp != "":
			var pulse := 0.5 + 0.5 * sin(_t * 6.0)
			draw_arc(ctr, s * 0.46, 0.0, TAU, 32, Color(1, 0.92, 0.6, 0.55 + 0.4 * pulse), 2.5, true)
			var a := s * 0.17
			var col := Color(1, 1, 1, 0.92)
			if sp == "row":
				draw_colored_polygon(PackedVector2Array([ctr + Vector2(-s * 0.36, 0), ctr + Vector2(-s * 0.16, -a), ctr + Vector2(-s * 0.16, a)]), col)
				draw_colored_polygon(PackedVector2Array([ctr + Vector2(s * 0.36, 0), ctr + Vector2(s * 0.16, -a), ctr + Vector2(s * 0.16, a)]), col)
			else:
				draw_colored_polygon(PackedVector2Array([ctr + Vector2(0, -s * 0.36), ctr + Vector2(-a, -s * 0.16), ctr + Vector2(a, -s * 0.16)]), col)
				draw_colored_polygon(PackedVector2Array([ctr + Vector2(0, s * 0.36), ctr + Vector2(-a, s * 0.16), ctr + Vector2(a, s * 0.16)]), col)
