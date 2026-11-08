class_name PuzzleBase
extends Control
## Base class for every puzzle view. A puzzle builds its own UI in build(), says what is going on through
## say(), and calls finish() exactly once when it is solved. `hold_ms` keeps the solved board on screen
## before the evidence card covers it.

signal solved(hold_ms: int)
signal status(text: String)

var def: Dictionary = {}
var seed_value := 1
## Earned clues so far: [{title, text}]. A puzzle that needs a deduction can show them.
var clues: Array = []
var rng := RandomNumberGenerator.new()
var _done := false
## Set by the puzzle screen: in landscape there is no spare height to ask the page for.
var landscape := false
var _asked := 0.0


func setup(def_: Dictionary, seed_: int, clues_: Array) -> void:
	def = def_
	seed_value = seed_
	clues = clues_
	rng.seed = seed_
	build()


## Override: create the nodes. The view fills its parent.
func build() -> void:
	pass


## Override: what a test or the debug tools may read about the current state.
func qa_state() -> Dictionary:
	return {}


func say(text: String) -> void:
	status.emit(text)


func finish(hold_ms: int = 900) -> void:
	if _done:
		return
	_done = true
	solved.emit(hold_ms)


## A board that needs more height than the window gives asks for it; the page then scrolls.
func ask_height(h: float) -> void:
	_asked = h
	var v := 0.0 if landscape else h
	if absf(custom_minimum_size.y - v) > 0.5:
		custom_minimum_size.y = v


func set_landscape(on: bool) -> void:
	landscape = on
	ask_height(_asked)


func is_done() -> bool:
	return _done


func sfx(sfx_name: String, jitter: float = 0.0) -> void:
	Sound.sfx(sfx_name, jitter)


func haptic(ms: int = 12) -> void:
	Fx.haptic(ms)


## A stable id for the test bridge.
func qa(node: Control, id: String) -> Control:
	return UI.qa(node, id)


# ---------- hints that point at the board ----------

## Override: where the next good move is. level 1 points the way, level 2 shows it exactly.
## Returns {rects: [Rect2 in this view's coordinates], text: String}, or {} if the puzzle has nothing to point at.
func board_hint(_level: int) -> Dictionary:
	return {}


## A rectangle inside a child control, in this view's coordinates.
func view_rect(node: Control, r: Rect2) -> Rect2:
	var xf := get_global_transform().affine_inverse() * node.get_global_transform()
	return xf * r


func show_board_hint(level: int) -> bool:
	if is_done():
		return false
	var h := board_hint(level)
	if h.is_empty():
		return false
	if h.has("text") and String(h["text"]) != "":
		say(String(h["text"]))
	var rects: Array = h.get("rects", [])
	if rects.is_empty():
		return true
	for c in get_children():
		if c is HintGlow:
			c.queue_free()
	var g := HintGlow.new(rects, level)
	add_child(g)
	return true


## Pulsing outlines over the board for a few seconds.
class HintGlow extends Control:
	var rects: Array = []
	var level := 1
	var t := 0.0

	func _init(r: Array, lv: int) -> void:
		rects = r
		level = lv
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		z_index = 40

	func _process(d: float) -> void:
		t += d
		if t > 6.0:
			modulate.a = maxf(0.0, 1.0 - (t - 6.0) / 0.6)
			if t > 6.6:
				queue_free()
		queue_redraw()

	func _draw() -> void:
		var pulse := 0.5 + 0.5 * sin(t * 5.0)
		for i in rects.size():
			var r: Rect2 = rects[i]
			# the first rectangle is the thing to touch; any others are where it goes
			var col := UI.AMBER2 if i == 0 else UI.TEAL
			var grow := 3.0 + 4.0 * pulse
			draw_style_box(UI.flat(Color(col, 0.10 + 0.08 * pulse), 10, Color(col, 0.65 + 0.35 * pulse), 3, 0), r.grow(grow))
			if i > 0 and level >= 2:
				var a: Rect2 = rects[0]
				draw_line(a.get_center(), r.get_center(), Color(col, 0.5 + 0.3 * pulse), 3.0, true)
