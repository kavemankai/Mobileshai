class_name FxButton
extends Button
## A button that presses in, springs back, and ticks. kind: normal, primary, ghost, dev.

var kind := "normal"


func _init(text_: String = "", kind_: String = "normal") -> void:
	text = text_
	kind = kind_
	custom_minimum_size.y = 48
	focus_mode = Control.FOCUS_ALL
	add_theme_font_override("font", UI.font("sans_bold"))
	add_theme_font_size_override("font_size", UI.fs(16))
	_style()
	button_down.connect(_down)
	button_up.connect(_up)
	mouse_exited.connect(_up)
	resized.connect(func() -> void: pivot_offset = size / 2.0)
	pressed.connect(func() -> void:
		Sound.sfx("tap", 0.03)
		Fx.haptic(8))


func _style() -> void:
	var bg := UI.PANEL
	var bg_hover := UI.PANEL2
	var border := UI.LINE
	var fg := UI.INK
	match kind:
		"primary":
			bg = UI.AMBER
			bg_hover = UI.AMBER2
			border = UI.AMBER
			fg = UI.DARK_INK
		"ghost":
			bg = Color(0, 0, 0, 0)
			bg_hover = Color(1, 1, 1, 0.06)
		"dev":
			bg = Color(0, 0, 0, 0)
			bg_hover = Color(0.91, 0.72, 0.47, 0.1)
			border = UI.AMBER
			fg = UI.AMBER
	var m := 14.0
	add_theme_stylebox_override("normal", UI.flat(bg, 12, border, 1, m))
	add_theme_stylebox_override("hover", UI.flat(bg_hover, 12, border, 1, m))
	add_theme_stylebox_override("pressed", UI.flat(bg_hover.darkened(0.12), 12, border, 1, m))
	add_theme_stylebox_override("disabled", UI.flat(bg.darkened(0.25), 12, border.darkened(0.3), 1, m))
	add_theme_stylebox_override("focus", UI.flat(Color(0, 0, 0, 0), 12, UI.AMBER2, 2, m))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		add_theme_color_override(c, fg)
	add_theme_color_override("font_disabled_color", fg.darkened(0.45))


func _down() -> void:
	if Fx.motion() and not disabled:
		create_tween().tween_property(self, "scale", Vector2(0.96, 0.96), 0.06)


func _up() -> void:
	if Fx.motion() and scale != Vector2.ONE:
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
