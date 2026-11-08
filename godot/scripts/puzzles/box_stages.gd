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
	## A line the box shows under the clue when the stage has a rule the player has to discover.
	var hint := ""

	func _init() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func qa() -> Dictionary:
		return {}

	func css(local: Vector2) -> Array:
		return QA.css(self, local)


# ---------------------------------------------------------------- screws
## Four bits, four kinds of head, and the plate only comes off if the screws go in the order stamped beside them.
## Pick the matching bit, then turn the screw about a turn and a half with a circular drag.
class ScrewStage extends Base:
	const HEADS := ["slot", "cross", "hex", "star"]
	var count := 4
	var plate := ""
	var screws: Array = []   # {a, head, num, turn, lift, gone, fall}
	var bit := -1
	var next_num := 1
	var plate_drop := 0.0:
		set(v):
			plate_drop = v
			queue_redraw()
	var left := 4
	var _active := -1
	var _last_ang := 0.0
	var _shake := {}

	func _init(st: Dictionary) -> void:
		super()
		count = int(st["count"])
		plate = String(st["plate"])
		left = count
		hint = "Match the bit to the head, then unscrew in the order stamped on the plate. Turn the screw round with your finger."
		var r := RandomNumberGenerator.new()
		r.seed = hash(plate + str(count))
		var nums := range(1, count + 1)
		for i in range(count - 1, 0, -1):
			var j := r.randi_range(0, i)
			var t = nums[i]
			nums[i] = nums[j]
			nums[j] = t
		for i in count:
			screws.append({"a": float(i) / count * TAU + 0.6, "head": r.randi_range(0, 3), "num": nums[i], "turn": 0.0, "lift": 0.0, "gone": false, "fall": 0.0})
		# every bit is needed at least once when there are four or more screws
		if count >= 4:
			for i in 4:
				screws[i]["head"] = i
			for i in range(count - 1, 0, -1):
				var j := r.randi_range(0, i)
				var t = screws[i]["head"]
				screws[i]["head"] = screws[j]["head"]
				screws[j]["head"] = t
		status.emit.call_deferred("Pick a bit, then a screw.")

	func _plate() -> Rect2:
		var w := minf(size.x - 16.0, 320.0)
		var h := minf(size.y - 76.0, w * 0.6)
		return Rect2(Vector2((size.x - w) / 2.0, 4.0), Vector2(w, h))

	func _pos(i: int) -> Vector2:
		var r := _plate()
		return r.get_center() + Vector2(cos(screws[i]["a"]) * r.size.x * 0.38, sin(screws[i]["a"]) * r.size.y * 0.32)

	func _bit_rect(k: int) -> Rect2:
		var w := minf((size.x - 20.0) / 4.0, 70.0)
		var total := w * 4.0
		return Rect2((size.x - total) / 2.0 + k * w, size.y - 62.0, w - 6.0, 56.0)

	func _process(_d: float) -> void:
		if _shake.size() > 0:
			queue_redraw()

	func _gui_input(e: InputEvent) -> void:
		if finished:
			return
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				for k in 4:
					if _bit_rect(k).has_point(e.position):
						bit = k
						Sound.sfx("pick")
						queue_redraw()
						return
				for i in count:
					if not screws[i]["gone"] and _pos(i).distance_to(e.position) < 26.0:
						_grab(i, e.position)
						return
			else:
				_active = -1
		elif e is InputEventMouseMotion and _active >= 0:
			var c := _pos(_active)
			var ang: float = (e.position - c).angle()
			var d: float = wrapf(ang - _last_ang, -PI, PI)
			_last_ang = ang
			if e.position.distance_to(c) > 8.0:
				_turn(_active, d)

	func _grab(i: int, p: Vector2) -> void:
		var s: Dictionary = screws[i]
		if bit < 0:
			status.emit("Pick a bit from the tray first.")
			Sound.sfx("invalid")
			_wobble(i)
			return
		if bit != int(s["head"]):
			status.emit("That bit slips. Look at the head of the screw.")
			Sound.sfx("invalid")
			Fx.haptic(14)
			_wobble(i)
			return
		if int(s["num"]) != next_num:
			status.emit("It binds. The plate has to come off in the stamped order.")
			Sound.sfx("static")
			Fx.haptic(14)
			_wobble(i)
			return
		_active = i
		_last_ang = float((p - _pos(i)).angle())

	func _wobble(i: int) -> void:
		if not Fx.motion():
			return
		_shake[i] = 1.0
		var tw := create_tween()
		tw.tween_method(func(v: float) -> void:
			_shake[i] = v
			queue_redraw(), 1.0, 0.0, 0.35)
		tw.tween_callback(func() -> void:
			_shake.erase(i)
			queue_redraw())

	func _turn(i: int, d: float) -> void:
		var s: Dictionary = screws[i]
		s["turn"] = clampf(float(s["turn"]) + absf(d) / (TAU * 1.5), 0.0, 1.0)
		if int(float(s["turn"]) * 12.0) != int(float(s["turn"]) * 12.0 - absf(d) / (TAU * 1.5) * 12.0):
			Sound.sfx("ratchet", 0.08)
		queue_redraw()
		if float(s["turn"]) >= 1.0:
			_active = -1
			_out(i)

	func _out(i: int) -> void:
		var s: Dictionary = screws[i]
		s["gone"] = true
		left -= 1
		next_num += 1
		Fx.haptic(12)
		if Fx.motion():
			var tw := create_tween()
			tw.tween_method(func(v: float) -> void:
				s["lift"] = v
				queue_redraw(), 0.0, 1.0, 0.25)
			tw.tween_method(func(v: float) -> void:
				s["fall"] = v
				queue_redraw(), 0.0, 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		else:
			s["fall"] = 1.0
		if left == 0:
			finished = true
			if Fx.motion():
				await get_tree().create_timer(0.8).timeout
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
		var ts := font.get_string_size(plate, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
		draw_string(font, r.get_center() + Vector2(-ts.x / 2.0, 4), plate, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("8fa3ac"))
		for i in count:
			var s: Dictionary = screws[i]
			var p := _pos(i)
			var sh := Vector2(sin(Time.get_ticks_msec() * 0.06) * 4.0 * float(_shake.get(i, 0.0)), 0)
			draw_circle(p, 10.0, Color(0, 0, 0, 0.55))
			var ns := str(int(s["num"]))
			draw_string(font, p + Vector2(-4, -17), ns, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UI.AMBER2 if int(s["num"]) >= next_num else Color("5b707a"))
			if s["gone"] and float(s["fall"]) >= 1.0:
				continue
			var lp := p + sh
			var sc := 1.0
			var a := 1.0
			if s["gone"]:
				lp += Vector2(0, -10.0 * float(s["lift"]) + 140.0 * float(s["fall"]))
				sc = 1.0 + 0.35 * float(s["lift"])
				a = 1.0 - float(s["fall"])
			draw_set_transform(off + lp, float(s["turn"]) * TAU * 1.5, Vector2(sc, sc))
			_screw_shape(int(s["head"]), a)
			draw_set_transform(off, plate_drop * 0.25, Vector2.ONE)
			if not s["gone"] and float(s["turn"]) > 0.0:
				draw_arc(p, 16.0, -PI / 2.0, -PI / 2.0 + TAU * float(s["turn"]), 24, UI.AMBER2, 2.5, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# the bit tray
		for k in 4:
			var br := _bit_rect(k)
			draw_style_box(UI.flat(Color("22323a"), 8, UI.AMBER if bit == k else Color("4a5d66"), 2 if bit == k else 1, 0), br)
			draw_set_transform(br.get_center(), 0.0, Vector2.ONE)
			_head_glyph(k, 1.0, 0.8)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func _head_glyph(kind: int, a: float, scale_: float) -> void:
		var col := Color("4a5a62", a)
		var k := 6.0 * scale_ * 1.4
		match kind:
			0:
				draw_line(Vector2(-k, 0), Vector2(k, 0), col, 3.0)
			1:
				draw_line(Vector2(-k, 0), Vector2(k, 0), col, 3.0)
				draw_line(Vector2(0, -k), Vector2(0, k), col, 3.0)
			2:
				var pts := PackedVector2Array()
				for q in 6:
					pts.append(Vector2(cos(q * TAU / 6.0), sin(q * TAU / 6.0)) * k)
				draw_colored_polygon(pts, col)
			3:
				for q in 3:
					var ang: float = q * PI / 3.0
					draw_line(Vector2(cos(ang), sin(ang)) * -k, Vector2(cos(ang), sin(ang)) * k, col, 2.5)

	func _screw_shape(kind: int, a: float) -> void:
		draw_circle(Vector2(1, 2), 11.0, Color(0, 0, 0, 0.35 * a))
		draw_circle(Vector2.ZERO, 11.0, Color("a7b4ba", a))
		draw_circle(Vector2.ZERO, 8.0, Color("c9d3d7", a))
		_head_glyph(kind, a, 0.8)

	func stage_hint(level: int) -> Dictionary:
		for i in count:
			var sc: Dictionary = screws[i]
			if not sc["gone"] and int(sc["num"]) == next_num:
				var p := _pos(i)
				var rects := [Rect2(p - Vector2(18, 18), Vector2(36, 36))]
				var text := "Screw %d comes out next." % next_num
				if level >= 2:
					rects = [_bit_rect(int(sc["head"])), Rect2(p - Vector2(18, 18), Vector2(36, 36))]
					text = "Take the %s bit, then turn screw %d round." % [HEADS[int(sc["head"])], next_num]
				return {"rects": rects, "text": text}
		return {}

	func qa() -> Dictionary:
		var pts := []
		var order := []
		for i in count:
			order.append({"num": screws[i]["num"], "head": screws[i]["head"], "gone": screws[i]["gone"], "pt": css(_pos(i))})
		var bits := []
		for k in 4:
			bits.append(css(_bit_rect(k).get_center()))
		return {"screws": order, "bits": bits, "radius": 14.0}


# ---------------------------------------------------------------- sliders
class SliderStage extends Base:
	var targets: Array = []
	var pos: Array = []          # animated float positions
	var val: Array = []          # snapped ints
	var _drag := -1
	var _from := 0
	var _ok := 0.0:
		set(v):
			_ok = v
			queue_redraw()

	func _init(st: Dictionary) -> void:
		super()
		targets = st["targets"]
		hint = "The stops are linked: moving one drags the next one the other way (and the last drags the first)."
		# start from the answer and undo a few linked moves, so the box can always be opened
		var r := RandomNumberGenerator.new()
		r.seed = hash(String(st["clue"]))
		var v := targets.duplicate()
		for _k in 7:
			var i := r.randi_range(0, v.size() - 1)
			var d := r.randi_range(1, 4)
			v[i] = posmod(int(v[i]) + d, 5)
			v[(i + 1) % v.size()] = posmod(int(v[(i + 1) % v.size()]) - d, 5)
		if v == targets:
			v[0] = posmod(int(v[0]) + 1, 5)
			v[1] = posmod(int(v[1]) - 1, 5)
		for x in v:
			val.append(int(x))
			pos.append(float(x))
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

	func _gui_input(e: InputEvent) -> void:
		if finished:
			return
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				for i in targets.size():
					if _track(i).grow(4.0).has_point(e.position):
						_drag = i
						_from = int(val[i])
						pos[i] = clampf((e.position.x - _track(i).position.x - 22.0) / (_track(i).size.x - 44.0) * 4.0, 0.0, 4.0)
						queue_redraw()
						return
			elif _drag >= 0:
				_release(_drag)
				_drag = -1
		elif e is InputEventMouseMotion and _drag >= 0:
			var t := _track(_drag)
			var f := clampf((e.position.x - t.position.x - 22.0) / (t.size.x - 44.0) * 4.0, 0.0, 4.0)
			pos[_drag] = f
			if roundi(f) != roundi(float(pos[_drag]) - 0.0001) or true:
				var near := roundi(f)
				if near != val[_drag] and near != _last_tick:
					_last_tick = near
					Sound.sfx("click", 0.05)
					Fx.haptic(4)
			queue_redraw()

	var _last_tick := -1

	func _release(i: int) -> void:
		var k := roundi(float(pos[i]))
		var d := k - _from
		val[i] = k
		_last_tick = -1
		_glide(i, float(k))
		if d != 0:
			# the neighbour is dragged the other way, wrapping round the notches
			var j := (i + 1) % targets.size()
			val[j] = posmod(int(val[j]) - d, 5)
			Sound.sfx("ratchet", 0.05)
			_glide(j, float(val[j]))
		_check()

	func _glide(i: int, to: float) -> void:
		if Fx.motion():
			var from: float = pos[i]
			create_tween().tween_method(func(v: float) -> void:
				pos[i] = v
				queue_redraw(), from, to, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			pos[i] = to
			queue_redraw()

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
			# a small gear between linked stops
			if i < targets.size() - 1:
				draw_string(font, Vector2(size.x / 2.0 - 4, t.end.y + 3), "⇅", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("4a5d66"))
			for k in 5:
				var x := x0 + (x1 - x0) * k / 4.0
				draw_line(Vector2(x, cy - 12), Vector2(x, cy - 8), Color("5b707a"), 2.0)
				draw_string(font, Vector2(x - 3, cy + 24), str(k), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("8fa3ac"))
			var kx := _x_of(i, float(pos[i]))
			var col := Color("c9d3d7").lerp(UI.TEAL, _ok if finished else 0.0)
			draw_style_box(UI.flat(col, 7, Color("5b707a"), 2, 0), Rect2(kx - 14, cy - 15, 28, 30))
			draw_string(font, Vector2(kx - 4, cy + 5), str(int(round(float(pos[i])))), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UI.DARK_INK)

	func stage_hint(level: int) -> Dictionary:
		var n := targets.size()
		var start := ",".join(val.map(func(x: int) -> String: return str(x)))
		var prev := {start: null}
		var queue := [val.duplicate()]
		var head := 0
		while head < queue.size():
			var v: Array = queue[head]
			head += 1
			var ok := true
			for i in n:
				if int(v[i]) != int(targets[i]):
					ok = false
			if ok:
				var k := ",".join(v.map(func(x: int) -> String: return str(x)))
				var mv = null
				while prev[k] != null:
					mv = prev[k][1]
					k = prev[k][0]
				if mv == null:
					return {}
				var i0: int = mv[0]
				var to: int = mv[1]
				var t := _track(i0)
				if level < 2:
					return {"rects": [t], "text": "Move this stop first."}
				return {"rects": [t, Rect2(Vector2(_x_of(i0, float(to)) - 16, t.get_center().y - 18), Vector2(32, 36))], "text": "Slide this stop to %d." % to}
			var kv := ",".join(v.map(func(x: int) -> String: return str(x)))
			for i in n:
				for k2 in 5:
					if k2 == int(v[i]):
						continue
					var o := v.duplicate()
					var d := k2 - int(v[i])
					o[i] = k2
					o[(i + 1) % n] = posmod(int(v[(i + 1) % n]) - d, 5)
					var ko := ",".join(o.map(func(x: int) -> String: return str(x)))
					if not prev.has(ko):
						prev[ko] = [kv, [i, k2]]
						queue.append(o)
		return {}

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
	var _silent := {}

	func _init(st: Dictionary, clues: Array) -> void:
		super()
		code = String(st["code"])
		hint = "The wheels are geared together: turning one turns the next the other way."
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
		# start from the code and undo a few geared turns, so there is always a way in
		var r := RandomNumberGenerator.new()
		r.seed = hash(code + String(st["clue"]))
		var v := []
		for ch in code:
			v.append(int(ch))
		for _k in 6:
			var i := r.randi_range(0, v.size() - 1)
			var d := r.randi_range(1, 9)
			v[i] = posmod(v[i] + d, 10)
			v[(i + 1) % v.size()] = posmod(v[(i + 1) % v.size()] - d, 10)
		if "".join(v.map(func(x: int) -> String: return str(x))) == code:
			v[0] = posmod(v[0] + 3, 10)
			v[1] = posmod(v[1] - 3, 10)
		for i in code.length():
			val.append(v[i])
			var w := DrumWheel.new(i, "0123456789", v[i])
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
		var old: int = val[i]
		val[i] = p
		if _silent.get(i, 0) > 0:
			_silent[i] = int(_silent[i]) - 1
		elif p != old:
			# the geared neighbour turns the other way by the same amount
			var d := posmod(p - old + 5, 10) - 5
			var j := (i + 1) % wheels.size()
			var target := posmod(int(val[j]) - d, 10)
			_silent[j] = int(_silent.get(j, 0)) + 1
			Sound.sfx("ratchet", 0.05)
			wheels[j].set_value(target)
			return
		_check()

	func _check() -> void:
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

	func stage_hint(level: int) -> Dictionary:
		var n := wheels.size()
		var goal := []
		for ch in code:
			goal.append(int(ch))
		var key := func(v: Array) -> String: return ",".join(v.map(func(x: int) -> String: return str(x)))
		var prev := {key.call(val): null}
		var queue := [val.duplicate()]
		var head := 0
		while head < queue.size() and prev.size() < 20000:
			var v: Array = queue[head]
			head += 1
			if v == goal:
				var k: String = key.call(v)
				var mv = null
				while prev[k] != null:
					mv = prev[k][1]
					k = prev[k][0]
				if mv == null:
					return {}
				var w: Control = wheels[mv[0]]
				var r := get_global_transform().affine_inverse() * w.get_global_transform() * Rect2(Vector2.ZERO, w.size)
				var d: int = mv[1]
				if level < 2:
					return {"rects": [r], "text": "Start with this wheel."}
				return {"rects": [r], "text": "Turn this wheel %s by %d." % ["up" if d > 0 else "down", absi(d)]}
			var kv: String = key.call(v)
			for i in n:
				for d in range(-5, 5):
					if d == 0:
						continue
					var o := v.duplicate()
					o[i] = posmod(int(v[i]) + d, 10)
					o[(i + 1) % n] = posmod(int(v[(i + 1) % n]) - d, 10)
					var ko: String = key.call(o)
					if not prev.has(ko):
						prev[ko] = [kv, [i, d]]
						queue.append(o)
		return {}

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

	func stage_hint(level: int) -> Dictionary:
		var press := BoxModel.lever_solve(state)
		if press.is_empty():
			return {}
		var rects := []
		for k in (press.size() if level >= 2 else 1):
			rects.append(_rect(int(press[k])))
		return {"rects": rects, "text": "Flip this lever." if level < 2 else "Flip each glowing lever once, in any order."}

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
	var wear: Array = []
	var _held := -1
	var _held_t := 0.0

	func _init(st: Dictionary) -> void:
		super()
		count = int(st["count"])
		target = int(st["target"])
		hint = "Press and hold a panel. Solid ones do not move. The one that is loose will give."
		var r := RandomNumberGenerator.new()
		r.seed = hash(String(st["clue"]))
		for i in count:
			sink.append(0.0)
			# dust everywhere; the loose panel is only a little cleaner, and two decoys are about as clean
			wear.append(r.randf_range(0.82, 1.0))
		var decoys := 0
		for i in count:
			if i != target and decoys < 2:
				wear[i] = r.randf_range(1.0, 1.08)
				decoys += 1
		wear[target] = 1.07
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
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				for i in count:
					if _rect(i).has_point(e.position):
						_held = i
						_held_t = 0.0
						Sound.sfx("tap", 0.05)
						return
			else:
				_release()

	func _release() -> void:
		if _held < 0:
			return
		var i := _held
		_held = -1
		if not finished and float(sink[i]) > 0.0 and Fx.motion():
			var from: float = sink[i]
			create_tween().tween_method(func(v: float) -> void:
				sink[i] = v
				queue_redraw(), from, 0.0, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			sink[i] = 0.0
		if _held_t < 0.45 and i != target:
			status.emit("Solid. Hold a little longer to feel for give.")

	func _process(d: float) -> void:
		if _held < 0 or finished:
			return
		_held_t += d
		var i := _held
		# solid panels barely move; the loose one gives under a steady press
		var limit := 1.0 if i == target else 0.14
		sink[i] = minf(float(sink[i]) + d * (2.2 if i == target else 1.0), limit)
		queue_redraw()
		if i == target and float(sink[i]) >= 1.0:
			finished = true
			_held = -1
			Sound.sfx("latch")
			Fx.haptic(16)
			_finish_press()

	func _finish_press() -> void:
		if Fx.motion():
			await get_tree().create_timer(0.35).timeout
		done.emit()

	func _draw() -> void:
		for i in count:
			var r := _rect(i)
			var s: float = sink[i]
			var rr := Rect2(r.position + Vector2(0, 4.0 * s), r.size).grow(-3.0 * s)
			BoxStages.metal(rr, self, 8.0, float(wear[i]) * (1.0 - 0.25 * s))
			for k in 4:
				var cx := rr.position.x + (10.0 if k % 2 == 0 else rr.size.x - 10.0)
				var cy := rr.position.y + (10.0 if k < 2 else rr.size.y - 10.0)
				draw_circle(Vector2(cx, cy), 3.0, Color("1c262b"))
			# dust, thicker where the panel is dirtier
			var dust := int((1.1 - float(wear[i])) * 60.0) + 2
			for k in dust:
				draw_circle(rr.position + Vector2(fmod(i * 17.0 + k * 23.0, rr.size.x), fmod(i * 11.0 + k * 31.0, rr.size.y)), 1.2, Color(0.7, 0.65, 0.55, 0.28))

	func stage_hint(level: int) -> Dictionary:
		if level >= 2:
			return {"rects": [_rect(target)], "text": "Press and hold this one."}
		var order := range(count)
		order.sort_custom(func(a: int, b: int) -> bool: return float(wear[a]) > float(wear[b]))
		var rects := []
		for k in mini(3, count):
			rects.append(_rect(order[k]))
		return {"rects": rects, "text": "It is one of the cleanest three. Hold each until one gives."}

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

	func stage_hint(level: int) -> Dictionary:
		for i in left.size():
			if not linked.has(i):
				var rects := [_jack_rect(0, i)]
				var text := "Plug this cable in next. Read the chart again."
				if level >= 2:
					rects.append(_jack_rect(1, int(pairs[i])))
					text = "%s goes to %s." % [left[i], right[pairs[i]]]
				return {"rects": rects, "text": text}
		return {}

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

	func stage_hint(level: int) -> Dictionary:
		var h := board.next_tilt()
		if h.is_empty():
			return {}
		var xf := get_global_transform().affine_inverse() * board.get_global_transform()
		var names := {"U": "up", "D": "down", "L": "left", "R": "right"}
		return {"rects": [xf * Rect2(h["rest"])], "text": "Get the bearing to stop on the glowing square." if level < 2 else "Tilt %s." % names[h["dir"]]}

	func qa() -> Dictionary:
		return {"solution": TiltModel.solve(_rows), "center": QA.css(board, board.size / 2.0), "cell": board.cell, "moving": board.moving}
