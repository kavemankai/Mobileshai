class_name DrumWheel
extends Control
## A letter or digit drum: drag it, flick it, or tap the faded neighbours. It snaps with a click.

signal settled(idx: int, pos: int)

var locked := func() -> bool: return false
var idx := 0
var letters := ""
var off := 0.0:
	set(v):
		off = v
		queue_redraw()
var unit := 40.0
var glow := 0.0:
	set(v):
		glow = v
		queue_redraw()
var _drag := false
var _y0 := 0.0
var _off0 := 0.0
var _vel := 0.0
var _last_y := 0.0
var _last_t := 0.0
var _tw: Tween
var _tick := 0
var _moved := false
var _font: Font

func _init(i: int, l: String, start: int) -> void:
	idx = i
	letters = l
	off = float(start)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_font = UI.font("serif_bold")
	resized.connect(func() -> void: unit = size.y / 3.1)
	_tick = start

func _gui_input(e: InputEvent) -> void:
	if locked.call():
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_drag = true
			_moved = false
			if _tw:
				_tw.kill()
			_y0 = e.position.y
			_off0 = off
			_vel = 0.0
			_last_y = e.position.y
			_last_t = Time.get_ticks_msec() / 1000.0
		elif _drag:
			_drag = false
			if not _moved:
				var rel: float = e.position.y - size.y / 2.0
				if absf(rel) > unit * 0.55:
					_snap(roundf(off) + (-1.0 if rel < 0.0 else 1.0))
				else:
					_snap(roundf(off))
			else:
				# a pause before letting go means no flick
				var idle := Time.get_ticks_msec() / 1000.0 - _last_t
				_snap(roundf(off - (_vel * 0.12 if idle < 0.08 else 0.0)))
	elif e is InputEventMouseMotion and _drag:
		if absf(e.position.y - _y0) > 4.0:
			_moved = true
		off = _off0 - (e.position.y - _y0) / unit
		var now := Time.get_ticks_msec() / 1000.0
		var dt := maxf(now - _last_t, 0.001)
		_vel = lerpf(_vel, (e.position.y - _last_y) / unit / dt, 0.5)
		_last_y = e.position.y
		_last_t = now
		_ticks()

func _ticks() -> void:
	var r := roundi(off)
	if r != _tick:
		_tick = r
		Sound.sfx("click", 0.06)
		Fx.haptic(4)

func _snap(target: float) -> void:
	if _tw:
		_tw.kill()
	var t := roundf(target)
	var dur := clampf(absf(t - off) * 0.12 + 0.14, 0.14, 0.5)
	if not Fx.motion():
		off = t
		_done(t)
		return
	_tw = create_tween()
	_tw.tween_method(func(v: float) -> void:
		off = v
		_ticks(), off, t, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tw.tween_callback(func() -> void: _done(t))

func _done(t: float) -> void:
	var L := letters.length()
	off = float(posmod(int(t), L))
	_tick = int(off)
	settled.emit(idx, int(off))

## Turn to a value by the shortest way round (used when another wheel drags this one along).
func set_value(p: int) -> void:
	var L := letters.length()
	var cur := posmod(roundi(off), L)
	var d := posmod(p - cur + L / 2, L) - L / 2
	_snap(roundf(off) + float(d))


func celebrate(delay: float) -> void:
	if not Fx.motion():
		glow = 1.0
		return
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_property(self, "glow", 1.0, 0.25)
	tw.tween_callback(func() -> void: Fx.burst(self, size / 2.0, UI.AMBER2, 10, 140.0, 3.0))

func _draw() -> void:
	if unit < 4.0:
		return
	var w := size.x
	var body := UI.flat(Color("0e1a22").lerp(Color("2a2412"), glow), 12, UI.LINE.lerp(UI.AMBER2, glow), 1 + int(glow * 2), 0)
	draw_style_box(body, Rect2(Vector2.ZERO, size))
	# the reading window
	var band := Rect2(2, size.y / 2.0 - unit * 0.5, w - 4, unit)
	draw_style_box(UI.flat(Color(UI.AMBER, 0.09 + 0.12 * glow), 6, Color(UI.AMBER, 0.35 + 0.4 * glow), 1, 0), band)
	var L := letters.length()
	var step := 0.62
	var R := unit / sin(step) * 0.98
	var base := roundi(off)
	for k in range(base - 3, base + 4):
		var ang := (float(k) - off) * step
		if absf(ang) > 1.45:
			continue
		var c := cos(ang)
		var y := size.y / 2.0 + sin(ang) * R
		var ch := letters[posmod(k, L)]
		var fs := int(clampf(minf(unit * 0.62, w * 0.62) * c, 6.0, 64.0))
		var ts := _font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var a := pow(maxf(c, 0.0), 2.4)
		var col := UI.INK.lerp(UI.AMBER2, clampf(1.0 - absf(float(k) - off), 0.0, 1.0) * (0.35 + glow * 0.65))
		draw_string(_font, Vector2(w / 2.0 - ts.x / 2.0, y + ts.y * 0.3), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(col, a))
	# shade top and bottom so the drum looks round
	var sh := size.y * 0.3
	draw_rect(Rect2(2, 2, w - 4, sh), Color(0, 0, 0, 0.35))
	draw_rect(Rect2(2, size.y - sh - 2, w - 4, sh), Color(0, 0, 0, 0.35))
