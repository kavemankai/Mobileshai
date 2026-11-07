class_name TiltBoard
extends Control
## The tilt maze as a reusable widget (the Maze puzzle and a Mechanism stage both use it).
## The ball rolls until a wall, squashes on impact, swirls down holes, and spins the valve open on the goal.

signal won
signal note(text: String)

const DIRS := {"U": Vector2i(-1, 0), "D": Vector2i(1, 0), "L": Vector2i(0, -1), "R": Vector2i(0, 1)}

var rows: Array = []
var R := 1
var C := 1
var start := Vector2i.ZERO
var goal := Vector2i.ZERO
var cell := 40.0
var origin := Vector2.ZERO
var ball_cell := Vector2i.ZERO
var ball_px := Vector2.ZERO
var ball_scale := Vector2.ONE
var ball_alpha := 1.0
var moving := false
var finished := false
var moves := 0
var spin := 0.0
var glow := 0.0:
	set(v):
		glow = v
		queue_redraw()
var trail: Array = []
var tilt_on := false
var _p0 := Vector2.ZERO
var _down := false
var _armed := true


func _init(maze_rows: Array) -> void:
	rows = maze_rows
	R = rows.size()
	C = String(rows[0]).length()
	start = TiltModel.find(rows, "S")
	goal = TiltModel.find(rows, "G")
	ball_cell = start
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	resized.connect(_relayout)


func _ready() -> void:
	_relayout()


func _relayout() -> void:
	cell = floorf(minf(size.x / C, size.y / R))
	origin = ((size - Vector2(cell * C, cell * R)) / 2.0).floor()
	if not moving:
		ball_px = _center(ball_cell)
	queue_redraw()


func _center(p: Vector2i) -> Vector2:
	return origin + (Vector2(p.y, p.x) + Vector2(0.5, 0.5)) * cell


func _process(d: float) -> void:
	spin += d * (2.0 + 14.0 * glow)
	if moving and Fx.motion():
		trail.append(ball_px)
		if trail.size() > 14:
			trail.pop_front()
	elif not trail.is_empty():
		trail.pop_front()
	if tilt_on and not moving and not finished:
		var g := Input.get_accelerometer()
		if g != Vector3.ZERO:
			var d_: String = ""
			if absf(g.x) > absf(g.y - 5.0):
				d_ = "R" if g.x > 3.5 else ("L" if g.x < -3.5 else "")
			else:
				d_ = "D" if g.y - 5.0 < -3.5 else ("U" if g.y - 5.0 > 3.5 else "")
			if d_ == "":
				_armed = true
			elif _armed:
				_armed = false
				tilt(d_)
	queue_redraw()


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_p0 = e.position
			_down = true
			grab_focus()
		elif _down:
			_down = false
			var d: Vector2 = e.position - _p0
			if d.length() < 16.0:
				return
			tilt(("R" if d.x > 0 else "L") if absf(d.x) > absf(d.y) else ("D" if d.y > 0 else "U"))


## Arrow keys play the maze wherever the focus is, so they never get used up moving it between buttons.
func _input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and is_visible_in_tree():
		var d := ""
		match e.keycode:
			KEY_UP: d = "U"
			KEY_DOWN: d = "D"
			KEY_LEFT: d = "L"
			KEY_RIGHT: d = "R"
		if d != "":
			get_viewport().set_input_as_handled()
			tilt(d)


func tilt(dir: String) -> void:
	if moving or finished:
		return
	var res := TiltModel.roll(rows, ball_cell, dir)
	var path: Array = res["path"]
	if path.is_empty():
		Sound.sfx("tap")
		_squash(dir, 0.6)
		return
	moving = true
	moves += 1
	Sound.sfx("roll")
	var end: Vector2i = path[-1]
	var hole: bool = res["hole"]
	var dur := 0.03 if not Fx.motion() else minf(0.5, 0.07 * path.size() + 0.05)
	var target := _center(end)
	if Fx.motion():
		var tw := create_tween()
		tw.tween_property(self, "ball_px", target, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tw.finished
	else:
		ball_px = target
	ball_cell = end
	if hole:
		await _fall(target)
		return
	Fx.haptic(6)
	_squash(dir, 1.0)
	Sound.sfx("tap", 0.05)
	moving = false
	if end == goal:
		_win()
	else:
		note.emit("Tilts: %d" % moves)


func _squash(dir: String, amount: float) -> void:
	if not Fx.motion():
		return
	var along := 0.78 if amount >= 1.0 else 0.9
	var s := Vector2(along, 1.0 / along) if dir == "L" or dir == "R" else Vector2(1.0 / along, along)
	ball_scale = s
	create_tween().tween_property(self, "ball_scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _fall(hole_px: Vector2) -> void:
	Sound.sfx("invalid")
	Fx.haptic(16)
	note.emit("It dropped through. Back to the start.")
	if Fx.motion():
		var tw := create_tween().set_parallel(true)
		tw.tween_property(self, "ball_scale", Vector2.ZERO, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tw.finished
	ball_cell = start
	ball_px = _center(start)
	ball_scale = Vector2.ZERO
	if Fx.motion():
		var tw2 := create_tween()
		tw2.tween_property(self, "ball_scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await tw2.finished
	ball_scale = Vector2.ONE
	moving = false


func _win() -> void:
	finished = true
	Sound.sfx("power")
	Fx.haptic(30)
	if Fx.motion():
		create_tween().tween_property(self, "glow", 1.0, 0.6)
		Fx.burst(self, _center(goal), UI.AMBER2, 30, 280.0, 5.0)
		await get_tree().create_timer(0.7).timeout
	else:
		glow = 1.0
	won.emit()


func _draw() -> void:
	if cell < 6.0:
		return
	var board := Rect2(origin, Vector2(cell * C, cell * R))
	draw_style_box(UI.flat(Color("0d1820"), 10, UI.LINE, 2, 0), board.grow(3))
	for r in R:
		for c in C:
			var p := Vector2i(r, c)
			var ch := TiltModel.cell(rows, p)
			var rect := Rect2(origin + Vector2(c, r) * cell, Vector2(cell, cell))
			match ch:
				"#":
					var sb := UI.flat(Color("2a4350"), cell * 0.18, Color("3a5866"), 1, 0)
					sb.shadow_color = Color(0, 0, 0, 0.45)
					sb.shadow_size = int(cell * 0.1)
					sb.shadow_offset = Vector2(0, cell * 0.06)
					draw_style_box(sb, rect.grow(-cell * 0.04))
				"O":
					var ctr := rect.get_center()
					draw_circle(ctr, cell * 0.36, Color("05090d"))
					draw_arc(ctr, cell * 0.36, 0.0, TAU, 28, Color("3d2a2a"), 2.0, true)
					draw_circle(ctr, cell * 0.2, Color(0, 0, 0, 0.9))
				"G":
					_valve(rect.get_center())
				"S":
					draw_arc(rect.get_center(), cell * 0.3, 0.0, TAU, 28, Color(UI.TEAL, 0.5), 2.0, true)
				_:
					draw_rect(rect.grow(-cell * 0.46), Color(1, 1, 1, 0.05))
	# trail
	for i in trail.size():
		var a := float(i) / maxf(trail.size(), 1.0)
		draw_circle(trail[i], cell * 0.26 * a, Color(UI.AMBER2, 0.28 * a))
	# ball
	if ball_scale.x > 0.01:
		var ctr := ball_px
		var r := cell * 0.34
		draw_set_transform(ctr, 0.0, ball_scale)
		draw_circle(Vector2(r * 0.12, r * 0.2), r, Color(0, 0, 0, 0.4))
		draw_circle(Vector2.ZERO, r, Color("9aa9b1"))
		draw_circle(Vector2(-r * 0.12, -r * 0.12), r * 0.78, Color("c9d4d9"))
		draw_circle(Vector2(-r * 0.34, -r * 0.38), r * 0.28, Color(1, 1, 1, 0.85))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _valve(ctr: Vector2) -> void:
	var r := cell * 0.36
	draw_circle(ctr, r * (1.5 + 0.4 * glow), Color(UI.AMBER, 0.12 + 0.2 * glow))
	draw_arc(ctr, r, 0.0, TAU, 32, UI.AMBER2, maxf(3.0, cell * 0.08), true)
	for k in 3:
		var a := spin * 0.5 + k * TAU / 3.0
		draw_line(ctr, ctr + Vector2(cos(a), sin(a)) * r, UI.AMBER2, maxf(2.0, cell * 0.06), true)
	draw_circle(ctr, r * 0.22, UI.AMBER2)
