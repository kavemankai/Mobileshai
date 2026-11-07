class_name BoxStages
extends RefCounted
## The seven kinds of stage a puzzle box can ask for. Each is a Control that fills its holder, tells the box
## through `done` when it is open, and describes where to tap through qa() for the browser tests.

static func make(st: Dictionary, clues: Array) -> Control:
	match String(st["type"]):
		"screws": return ScrewStage.new(st)
		"sliders": return SliderStage.new(st)
		"dials": return DialStage.new(st, clues)
		"levers": return LeverStage.new(st)
		"press": return PressStage.new(st)
		"patch": return PatchStage.new(st)
		"tilt": return TiltStage.new(st)
	return Control.new()


static func metal(r: Rect2, c: Control, radius: float = 10.0, tone: float = 1.0) -> void:
	var sb := UI.flat(Color("3a4a52") * tone, radius, Color("5b707a"), 2, 0)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 4)
	c.draw_style_box(sb, r)


class Base extends Control:
	signal done
	signal status(text: String)
	var finished := false

	func _init() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func qa() -> Dictionary:
		return {}

	func css(local: Vector2) -> Array:
		return QA.css(self, local)


# ---------------------------------------------------------------- screws
class ScrewStage extends Base:
	var count := 4
	var plate := ""
	var screws: Array = []   # {a, rot, lift, gone, fall}
	var plate_drop := 0.0:
		set(v):
			plate_drop = v
			queue_redraw()
	var left := 4

	func _init(st: Dictionary) -> void:
		super()
		count = int(st["count"])
		plate = String(st["plate"])
		left = count
		for i in count:
			screws.append({"a": float(i) / count * TAU + 0.6, "rot": 0.0, "lift": 0.0, "gone": false, "fall": 0.0})
		status.emit.call_deferred("Unscrew the plate.")

	func _plate() -> Rect2:
		var w := minf(size.x - 16.0, 320.0)
		var h := minf(size.y - 8.0, w * 0.62)
		return Rect2((size - Vector2(w, h)) / 2.0, Vector2(w, h))

	func _pos(i: int) -> Vector2:
		var r := _plate()
		return r.get_center() + Vector2(cos(screws[i]["a"]) * r.size.x * 0.38, sin(screws[i]["a"]) * r.size.y * 0.34)

	func _gui_input(e: InputEvent) -> void:
		if finished:
			return
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			for i in count:
				if not screws[i]["gone"] and _pos(i).distance_to(e.position) < 24.0:
					_turn(i)
					return

	func _turn(i: int) -> void:
		var s: Dictionary = screws[i]
		s["gone"] = true
		left -= 1
		Sound.sfx("ratchet", 0.05)
		Fx.haptic(10)
		if Fx.motion():
			var tw := create_tween()
			tw.tween_method(func(v: float) -> void:
				s["rot"] = v * TAU * 3.0
				s["lift"] = minf(v * 2.0, 1.0)
				queue_redraw(), 0.0, 1.0, 0.55)
			tw.tween_method(func(v: float) -> void:
				s["fall"] = v
				queue_redraw(), 0.0, 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		else:
			s["fall"] = 1.0
		if left == 0:
			finished = true
			if Fx.motion():
				await get_tree().create_timer(0.85).timeout
				Sound.sfx("metal")
				var tw2 := create_tween()
				tw2.tween_property(self, "plate_drop", 1.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				await tw2.finished
			done.emit()
		else:
			status.emit("%d screw%s left." % [left, "" if left == 1 else "s"])
		queue_redraw()

	func _draw() -> void:
		if size.x < 40.0:
			return
		var r := _plate()
		var off := Vector2(0, plate_drop * size.y * 0.9)
		draw_set_transform(off, plate_drop * 0.25, Vector2.ONE)
		BoxStages.metal(r, self, 12.0)
		var font := UI.font("mono_bold")
		var ts := font.get_string_size(plate, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
		draw_string(font, r.get_center() + Vector2(-ts.x / 2.0, 4), plate, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("8fa3ac"))
		for i in count:
			var s: Dictionary = screws[i]
			var p := _pos(i)
			if s["gone"]:
				if s["fall"] >= 1.0:
					draw_circle(p, 9.0, Color(0, 0, 0, 0.55))      # the hole it leaves
					continue
				draw_circle(p, 9.0, Color(0, 0, 0, 0.55))
				var lp: Vector2 = p + Vector2(0, -10.0 * s["lift"] + 140.0 * s["fall"])
				var sc: float = 1.0 + 0.35 * s["lift"]
				draw_set_transform(off + lp, s["rot"], Vector2(sc, sc))
				_screw_shape(Vector2.ZERO, 1.0 - s["fall"])
				draw_set_transform(off, plate_drop * 0.25, Vector2.ONE)
			else:
				draw_set_transform(off + p, 0.0, Vector2.ONE)
				_screw_shape(Vector2.ZERO, 1.0)
				draw_set_transform(off, plate_drop * 0.25, Vector2.ONE)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func _screw_shape(c: Vector2, a: float) -> void:
		draw_circle(c + Vector2(1, 2), 11.0, Color(0, 0, 0, 0.35 * a))
		draw_circle(c, 11.0, Color("a7b4ba", a))
		draw_circle(c, 8.0, Color("c9d3d7", a))
		draw_line(c + Vector2(-6, 0), c + Vector2(6, 0), Color("4a5a62", a), 2.5)
		draw_line(c + Vector2(0, -6), c + Vector2(0, 6), Color("4a5a62", a), 2.5)

	func qa() -> Dictionary:
		var pts := []
		for i in count:
			if not screws[i]["gone"]:
				pts.append(css(_pos(i)))
		return {"pts": pts}


# ---------------------------------------------------------------- sliders
class SliderStage extends Base:
	var targets: Array = []
	var pos: Array = []          # animated float positions
	var val: Array = []          # snapped ints
	var _drag := -1
	var _ok := 0.0:
		set(v):
			_ok = v
			queue_redraw()

	func _init(st: Dictionary) -> void:
		super()
		targets = st["targets"]
		for t in targets:
			val.append((int(t) + 2) % 5)
			pos.append(float((int(t) + 2) % 5))
		status.emit.call_deferred(String(st["clue"]))

	func _track(i: int) -> Rect2:
		var n := targets.size()
		var rh := minf(52.0, (size.y - 8.0) / n)
		var w := minf(size.x - 40.0, 300.0)
		var total := rh * n
		return Rect2(Vector2((size.x - w) / 2.0, (size.y - total) / 2.0 + i * rh), Vector2(w, rh))

	func _x_of(i: int, p: float) -> float:
		var t := _track(i)
		return t.position.x + 22.0 + (t.size.x - 44.0) * p / 4.0

	func _notch_at(i: int, x: float) -> int:
		var t := _track(i)
		var f := (x - t.position.x - 22.0) / (t.size.x - 44.0) * 4.0
		return clampi(roundi(f), 0, 4)

	func _gui_input(e: InputEvent) -> void:
		if finished:
			return
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				for i in targets.size():
					if _track(i).grow(4.0).has_point(e.position):
						_drag = i
						pos[i] = clampf((e.position.x - _track(i).position.x - 22.0) / (_track(i).size.x - 44.0) * 4.0, 0.0, 4.0)
						queue_redraw()
						return
			elif _drag >= 0:
				_settle(_drag)
				_drag = -1
		elif e is InputEventMouseMotion and _drag >= 0:
			var t := _track(_drag)
			var f := clampf((e.position.x - t.position.x - 22.0) / (t.size.x - 44.0) * 4.0, 0.0, 4.0)
			pos[_drag] = f
			var near := roundi(f)
			if near != val[_drag]:
				val[_drag] = near
				Sound.sfx("click", 0.05)
				Fx.haptic(4)
			queue_redraw()

	func _settle(i: int) -> void:
		var k := roundi(float(pos[i]))
		val[i] = k
		if Fx.motion():
			var from: float = pos[i]
			create_tween().tween_method(func(v: float) -> void:
				pos[i] = v
				queue_redraw(), from, float(k), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			pos[i] = float(k)
		_check()

	func _check() -> void:
		if finished:
			return
		for i in targets.size():
			if int(val[i]) != int(targets[i]):
				return
		finished = true
		Sound.sfx("latch")
		if Fx.motion():
			var tw := create_tween()
			tw.tween_property(self, "_ok", 1.0, 0.35)
			await tw.finished
		done.emit()

	func _draw() -> void:
		var font := UI.font("mono_bold")
		for i in targets.size():
			var t := _track(i)
			var cy := t.get_center().y
			var x0 := t.position.x + 22.0
			var x1 := t.end.x - 22.0
			draw_style_box(UI.flat(Color("0b1217"), 6, Color("2e4048"), 1, 0), Rect2(x0 - 6, cy - 6, x1 - x0 + 12, 12))
			for k in 5:
				var x := x0 + (x1 - x0) * k / 4.0
				draw_line(Vector2(x, cy - 12), Vector2(x, cy - 8), Color("5b707a"), 2.0)
				var s := str(k)
				draw_string(font, Vector2(x - 3, cy + 24), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("8fa3ac"))
			var kx := _x_of(i, float(pos[i]))
			var ok := int(val[i]) == int(targets[i]) and _ok > 0.0
			var col := Color("c9d3d7").lerp(UI.TEAL, _ok if ok or finished else 0.0)
			draw_style_box(UI.flat(col, 7, Color("5b707a"), 2, 0), Rect2(kx - 14, cy - 15, 28, 30))
			var txt := str(int(round(float(pos[i]))))
			draw_string(font, Vector2(kx - 4, cy + 5), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UI.DARK_INK)

	func qa() -> Dictionary:
		var tr := []
		for i in targets.size():
			var row := []
			for k in 5:
				row.append(css(Vector2(_x_of(i, float(k)), _track(i).get_center().y)))
			tr.append(row)
		return {"tracks": tr, "targets": targets, "val": val}


# ---------------------------------------------------------------- dials
class DialStage extends Base:
	var code := ""
	var wheels: Array = []
	var val: Array = []
	var _evidence: Control

	func _init(st: Dictionary, clues: Array) -> void:
		super()
		code = String(st["code"])
		var col := UI.vbox(8)
		col.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(col)
		var mid := Control.new()
		mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
		col.add_child(mid)
		var row := UI.hbox(8)
		row.set_anchors_preset(Control.PRESET_FULL_RECT)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		mid.add_child(row)
		for i in code.length():
			var start := (int(code[i]) + 5) % 10
			val.append(start)
			var w := DrumWheel.new(i, "0123456789", start)
			w.custom_minimum_size = Vector2(48, 140)
			w.size_flags_vertical = Control.SIZE_EXPAND_FILL
			w.settled.connect(_settled)
			w.locked = func() -> bool: return finished
			UI.qa(w, "dial.%d" % i)
			wheels.append(w)
			row.add_child(w)
		if bool(st.get("evidence", false)):
			col.add_child(EvidencePeek.new(clues))
		status.emit.call_deferred(String(st["clue"]))

	func _settled(i: int, p: int) -> void:
		val[i] = p
		if finished:
			return
		var s := ""
		for v in val:
			s += str(v)
		if s == code:
			finished = true
			Sound.sfx("latch")
			for k in wheels.size():
				wheels[k].celebrate(0.06 * k)
			if Fx.motion():
				await get_tree().create_timer(0.7).timeout
			done.emit()

	func qa() -> Dictionary:
		var cs := []
		for w in wheels:
			cs.append(QA.css(w, w.size / 2.0))
		return {"centers": cs, "unit": wheels[0].unit, "val": val, "code": code}


# ---------------------------------------------------------------- levers
class LeverStage extends Base:
	var n := 3
	var state: Array = []
	var anim: Array = []      # 0..1 handle position per lever
	var _glow := 0.0:
		set(v):
			_glow = v
			queue_redraw()

	func _init(st: Dictionary) -> void:
		super()
		state = st["start"].duplicate()
		n = int(round(sqrt(state.size())))
		for v in state:
			anim.append(float(v))
		status.emit.call_deferred(String(st["clue"]))

	func _cell() -> float:
		return clampf(minf((size.x - 24.0) / n, (size.y - 8.0) / n), 30.0, 74.0)

	func _rect(i: int) -> Rect2:
		var c := _cell()
		var total := c * n
		var o := (size - Vector2(total, total)) / 2.0
		return Rect2(o + Vector2(i % n, i / n) * c, Vector2(c, c)).grow(-4.0)

	func _gui_input(e: InputEvent) -> void:
		if finished:
			return
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			for i in n * n:
				if _rect(i).has_point(e.position):
					_press(i)
					return

	func _press(i: int) -> void:
		var changed := BoxModel.neighbours(n, i)
		state = BoxModel.lever_toggle(state, i)
		Sound.sfx("click", 0.05)
		Fx.haptic(8)
		for k in changed.size():
			var idx: int = changed[k]
			var target := float(state[idx])
			if Fx.motion():
				var tw := create_tween()
				tw.tween_interval(0.0 if idx == i else 0.05)
				tw.tween_method(func(v: float) -> void:
					anim[idx] = v
					queue_redraw(), float(anim[idx]), target, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			else:
				anim[idx] = target
		queue_redraw()
		var all := true
		for v in state:
			if int(v) != 1:
				all = false
		if all and not finished:
			finished = true
			Sound.sfx("power")
			if Fx.motion():
				var tw2 := create_tween()
				tw2.tween_property(self, "_glow", 1.0, 0.5)
				await tw2.finished
			done.emit()

	func _draw() -> void:
		for i in n * n:
			var r := _rect(i)
			var a: float = anim[i]
			BoxStages.metal(r, self, 8.0, 0.9)
			var c := r.get_center()
			# a slot and a handle that swings between down and up
			var slot := Rect2(c.x - 5, r.position.y + 8, 10, r.size.y - 16)
			draw_rect(slot, Color("0a1014"))
			var hy := lerpf(slot.end.y - 6, slot.position.y + 6, a)
			var lit := UI.AMBER2.lerp(Color.WHITE, _glow * 0.4) if a > 0.5 else Color("8fa3ac")
			draw_circle(Vector2(c.x, hy), r.size.x * 0.2, lit)
			draw_circle(Vector2(c.x - 2, hy - 2), r.size.x * 0.07, Color(1, 1, 1, 0.5))
			if a > 0.5:
				draw_circle(Vector2(r.end.x - 9, r.position.y + 9), 4.0, Color(UI.TEAL, 0.9))

	func qa() -> Dictionary:
		var pts := []
		for i in n * n:
			pts.append(css(_rect(i).get_center()))
		return {"pts": pts, "state": state, "n": n}


# ---------------------------------------------------------------- press
class PressStage extends Base:
	var count := 6
	var target := 0
	var sink: Array = []
	var _clue_text := ""

	func _init(st: Dictionary) -> void:
		super()
		count = int(st["count"])
		target = int(st["target"])
		for i in count:
			sink.append(0.0)
		status.emit.call_deferred(String(st["clue"]))

	func _cols() -> int:
		return 3 if count > 4 else count

	func _rect(i: int) -> Rect2:
		var cols := _cols()
		var rows := ceili(float(count) / cols)
		var c := minf(minf((size.x - 24.0) / cols, (size.y - 8.0) / rows), 96.0)
		var o := (size - Vector2(c * cols, c * rows)) / 2.0
		return Rect2(o + Vector2(i % cols, i / cols) * c, Vector2(c, c)).grow(-6.0)

	func _gui_input(e: InputEvent) -> void:
		if finished:
			return
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			for i in count:
				if _rect(i).has_point(e.position):
					_push(i)
					return

	func _push(i: int) -> void:
		var hit := i == target
		if Fx.motion():
			var tw := create_tween()
			tw.tween_method(func(v: float) -> void:
				sink[i] = v
				queue_redraw(), 0.0, 1.0 if hit else 0.25, 0.12)
			if not hit:
				tw.tween_method(func(v: float) -> void:
					sink[i] = v
					queue_redraw(), 0.25, 0.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			sink[i] = 1.0 if hit else 0.0
		if hit:
			finished = true
			Sound.sfx("latch")
			Fx.haptic(16)
			if Fx.motion():
				await get_tree().create_timer(0.35).timeout
			queue_redraw()
			done.emit()
		else:
			Sound.sfx("tap")
			status.emit("Solid. Nothing moves.")

	func _draw() -> void:
		for i in count:
			var r := _rect(i)
			var s: float = sink[i]
			var odd := i == target
			var tone := 1.25 if odd else 0.85
			var rr := Rect2(r.position + Vector2(0, 4.0 * s), r.size).grow(-3.0 * s)
			BoxStages.metal(rr, self, 8.0, tone * (1.0 - 0.25 * s))
			for k in 4:
				var cx := rr.position.x + (10.0 if k % 2 == 0 else rr.size.x - 10.0)
				var cy := rr.position.y + (10.0 if k < 2 else rr.size.y - 10.0)
				draw_circle(Vector2(cx, cy), 3.0, Color("1c262b"))
			if not odd:
				# dust
				for k in 6:
					draw_circle(rr.position + Vector2(fmod(i * 17.0 + k * 23.0, rr.size.x), fmod(i * 11.0 + k * 31.0, rr.size.y)), 1.3, Color(0.7, 0.65, 0.55, 0.25))

	func qa() -> Dictionary:
		var pts := []
		for i in count:
			pts.append(css(_rect(i).get_center()))
		return {"pts": pts, "target": target}


# ---------------------------------------------------------------- patch
class PatchStage extends Base:
	var st_def: Dictionary
	var left: Array = []
	var right: Array = []
	var pairs: Array = []
	var linked := {}       # left index -> draw progress 0..1
	var pick := -1
	var spark := {}        # right index -> 0..1
	var _bad := {}         # left idx -> right idx, a cable that is flashing and retracting

	func _init(st: Dictionary) -> void:
		super()
		st_def = st
		left = st["left"]
		right = st["right"]
		pairs = st["pairs"]
		status.emit.call_deferred(String(st["clue"]))

	func _jack_rect(side: int, i: int) -> Rect2:
		var n := left.size()
		var rh := minf(52.0, (size.y - 8.0) / n)
		var w := minf(110.0, size.x * 0.3)
		var top := (size.y - rh * n) / 2.0
		var x := 10.0 if side == 0 else size.x - w - 10.0
		return Rect2(x, top + i * rh, w, rh).grow_individual(0, -4, 0, -4)

	func _gui_input(e: InputEvent) -> void:
		if finished:
			return
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			for i in left.size():
				if _jack_rect(0, i).has_point(e.position) and not linked.has(i):
					pick = i
					Sound.sfx("pick")
					queue_redraw()
					return
			for j in right.size():
				if _jack_rect(1, j).has_point(e.position):
					_plug(j)
					return

	func _used(j: int) -> bool:
		for i in linked:
			if pairs[i] == j:
				return true
		return false

	func _plug(j: int) -> void:
		if pick < 0 or _used(j):
			status.emit("Pick a cable on the left first.")
			return
		var i := pick
		pick = -1
		if pairs[i] == j:
			Sound.sfx("latch")
			Fx.haptic(8)
			linked[i] = 0.0 if Fx.motion() else 1.0
			if Fx.motion():
				create_tween().tween_method(func(v: float) -> void:
					linked[i] = v
					queue_redraw(), 0.0, 1.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				Fx.burst(self, _jack_rect(1, j).get_center(), UI.TEAL, 10, 140.0, 3.0)
			if linked.size() == left.size():
				finished = true
				if Fx.motion():
					await get_tree().create_timer(0.6).timeout
				done.emit()
		else:
			Sound.sfx("static")
			Fx.haptic(16)
			status.emit("Sparks. Wrong socket.")
			if Fx.motion():
				_bad[i] = j
				spark[j] = 1.0
				var tw := create_tween()
				tw.tween_method(func(v: float) -> void:
					spark[j] = v
					queue_redraw(), 1.0, 0.0, 0.4)
				tw.tween_callback(func() -> void:
					_bad.erase(i)
					queue_redraw())
		queue_redraw()

	func _cable(a: Vector2, b: Vector2, t: float, col: Color, w: float) -> void:
		var mid := (a + b) / 2.0 + Vector2(0, 18)
		var pts := PackedVector2Array()
		var n := 18
		for k in int(n * t) + 1:
			var u := float(k) / n
			pts.append(a.lerp(mid, u).lerp(mid.lerp(b, u), u))
		if pts.size() > 1:
			draw_polyline(pts, Color(0, 0, 0, 0.4), w + 3.0, true)
			draw_polyline(pts, col, w, true)

	func _draw() -> void:
		var font := UI.font("mono_bold")
		for i in left.size():
			var r := _jack_rect(0, i)
			var on: bool = linked.has(i)
			draw_style_box(UI.flat(Color("2c3c44") if not on else Color("1f4a44"), 8, UI.AMBER if pick == i else Color("5b707a"), 2 if pick == i else 1, 0), r)
			draw_string(font, Vector2(r.position.x + 8, r.get_center().y + 4), String(left[i]), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 22.0, 11, UI.INK)
			draw_circle(Vector2(r.end.x - 8, r.get_center().y), 5.0, Color("0a1014"))
		for j in right.size():
			var r := _jack_rect(1, j)
			var used := _used(j)
			var sp: float = spark.get(j, 0.0)
			draw_style_box(UI.flat(Color("2c3c44").lerp(Color("5a2a26"), sp) if not used else Color("1f4a44"), 8, Color("5b707a"), 1, 0), r)
			draw_string(font, Vector2(r.position.x + 18, r.get_center().y + 4), String(right[j]), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 22.0, 11, UI.INK)
			draw_circle(Vector2(r.position.x + 8, r.get_center().y), 5.0, Color("0a1014"))
			if sp > 0.0:
				draw_circle(Vector2(r.position.x + 8, r.get_center().y), 12.0 * sp, Color(1, 0.8, 0.4, 0.6 * sp))
		var palette := [UI.AMBER2, UI.TEAL, Color("9a8fc9"), Color("d9d2c2"), Color("c8665a")]
		for i in linked:
			var a := _jack_rect(0, i).get_center() + Vector2(_jack_rect(0, i).size.x / 2.0 - 8, 0)
			var b := _jack_rect(1, pairs[i]).get_center() - Vector2(_jack_rect(1, pairs[i]).size.x / 2.0 - 8, 0)
			_cable(a, b, float(linked[i]), palette[int(i) % palette.size()], 4.0)
		for i in _bad:
			var a2 := _jack_rect(0, i).get_center() + Vector2(_jack_rect(0, i).size.x / 2.0 - 8, 0)
			var b2 := _jack_rect(1, int(_bad[i])).get_center() - Vector2(_jack_rect(1, int(_bad[i])).size.x / 2.0 - 8, 0)
			_cable(a2, b2, 1.0, UI.RED, 4.0)

	func qa() -> Dictionary:
		var l := []
		var r := []
		for i in left.size():
			l.append(css(_jack_rect(0, i).get_center()))
		for j in right.size():
			r.append(css(_jack_rect(1, j).get_center()))
		return {"left": l, "right": r, "pairs": pairs}


# ---------------------------------------------------------------- tilt
class TiltStage extends Base:
	var board: TiltBoard

	func _init(st: Dictionary) -> void:
		super()
		var col := UI.vbox(6)
		col.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(col)
		board = TiltBoard.new(st["rows"])
		board.size_flags_vertical = Control.SIZE_EXPAND_FILL
		board.note.connect(func(t: String) -> void: status.emit(t))
		board.won.connect(func() -> void: done.emit())
		UI.qa(board, "tilt.board")
		col.add_child(board)
		var pad := UI.hbox(6)
		for d in ["L", "U", "D", "R"]:
			var b := FxButton.new({"U": "▲", "D": "▼", "L": "◀", "R": "▶"}[d])
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.pressed.connect(func() -> void: board.tilt(d))
			UI.qa(b, "tilt." + d)
			pad.add_child(b)
		col.add_child(pad)
		status.emit.call_deferred(String(st["clue"]))
		_rows = st["rows"]

	var _rows: Array = []

	func qa() -> Dictionary:
		return {"solution": TiltModel.solve(_rows), "center": QA.css(board, board.size / 2.0), "cell": board.cell, "moving": board.moving}
