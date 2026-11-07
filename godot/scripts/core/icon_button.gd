class_name IconButton
extends Button
## A round button with a vector icon: evidence, menu, close, back.

var icon_kind := "menu"


func _init(kind_: String = "menu") -> void:
	icon_kind = kind_
	custom_minimum_size = Vector2(46, 46)
	focus_mode = Control.FOCUS_ALL
	var normal := UI.flat(Color(0, 0, 0, 0), 23, UI.LINE, 1, 0)
	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", UI.flat(Color(1, 1, 1, 0.06), 23, UI.LINE, 1, 0))
	add_theme_stylebox_override("pressed", UI.flat(Color(1, 1, 1, 0.12), 23, UI.AMBER, 1, 0))
	add_theme_stylebox_override("focus", UI.flat(Color(0, 0, 0, 0), 23, UI.AMBER2, 2, 0))
	resized.connect(func() -> void: pivot_offset = size / 2.0)
	button_down.connect(func() -> void:
		if Fx.motion():
			create_tween().tween_property(self, "scale", Vector2(0.92, 0.92), 0.06))
	button_up.connect(func() -> void:
		if Fx.motion():
			create_tween().tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
	pressed.connect(func() -> void:
		Sound.sfx("tap", 0.03)
		Fx.haptic(8))


func _draw() -> void:
	var c := size / 2.0
	var col := UI.INK
	var w := 2.4
	match icon_kind:
		"menu":
			for dy in [-7.0, 0.0, 7.0]:
				draw_line(c + Vector2(-9, dy), c + Vector2(9, dy), col, w, true)
		"close":
			draw_line(c + Vector2(-8, -8), c + Vector2(8, 8), col, w, true)
			draw_line(c + Vector2(-8, 8), c + Vector2(8, -8), col, w, true)
		"back":
			draw_polyline(PackedVector2Array([c + Vector2(4, -9), c + Vector2(-5, 0), c + Vector2(4, 9)]), col, w, true)
		"evidence":
			# a folder with a tab and two lines of notes
			var pts := PackedVector2Array([c + Vector2(-10, -7), c + Vector2(-3, -7), c + Vector2(0, -4), c + Vector2(10, -4), c + Vector2(10, 8), c + Vector2(-10, 8), c + Vector2(-10, -7)])
			draw_polyline(pts, col, w, true)
			draw_line(c + Vector2(-5, 1), c + Vector2(5, 1), col, 1.8, true)
			draw_line(c + Vector2(-5, 5), c + Vector2(2, 5), col, 1.8, true)
