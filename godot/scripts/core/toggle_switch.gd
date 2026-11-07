class_name ToggleSwitch
extends Control
## An on/off switch with a sliding knob.

signal toggled(on: bool)

var on := false:
	set(v):
		on = v
		_animate()
var _t := 0.0:
	set(v):
		_t = v
		queue_redraw()


func _init(initial: bool = false) -> void:
	custom_minimum_size = Vector2(56, 32)
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	on = initial
	_t = 1.0 if initial else 0.0


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		_flip()
	elif e is InputEventKey and e.pressed and (e.keycode == KEY_SPACE or e.keycode == KEY_ENTER):
		_flip()


func _flip() -> void:
	on = not on
	Sound.sfx("click")
	Fx.haptic(6)
	toggled.emit(on)


func _animate() -> void:
	if Fx.motion() and is_inside_tree():
		create_tween().tween_property(self, "_t", 1.0 if on else 0.0, 0.16).set_trans(Tween.TRANS_QUAD)
	else:
		_t = 1.0 if on else 0.0


func _draw() -> void:
	var r := size.y / 2.0
	var track := UI.LINE.lerp(UI.AMBER, _t)
	draw_style_box(UI.flat(track, r), Rect2(Vector2.ZERO, size))
	var x := lerpf(r, size.x - r, _t)
	draw_circle(Vector2(x, r), r - 4.0, UI.DARK_INK if _t > 0.5 else UI.INK)
	if has_focus():
		draw_style_box(UI.flat(Color(0, 0, 0, 0), r, UI.AMBER2, 2), Rect2(Vector2.ZERO, size))
