class_name ChapterScreen
extends Screen
## A chapter card: the title types itself in over a slow light. Tap to go on.

var _ready_at := 0
var _go := false


func _ready() -> void:
	var l := Game.current_level()
	var ch := int(l["ch"])
	Sound.scene(l["scene"], ch)
	if ch == 0 or not Sound.stinger("chapter_end"):
		Sound.sfx("chapter")

	var glow := TextureRect.new()
	var g := Gradient.new()
	g.colors = PackedColorArray([Color("1a3a44"), UI.BG])
	g.offsets = PackedFloat32Array([0.0, 1.0])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.38)
	gt.fill_to = Vector2(0.5, 1.05)
	glow.texture = gt
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)
	move_child(glow, 0)

	var col := UI.vbox(14)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	var pad := UI.margin(col, 28)
	pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_child(pad)
	var ch_data: Dictionary = Game.chapters[ch]
	col.add_child(UI.label("Chapter %d of %d" % [ch + 1, Game.chapters.size()], 13, UI.AMBER, "mono_bold", HORIZONTAL_ALIGNMENT_CENTER))
	var title := UI.label(String(ch_data["name"]), 46, UI.PAPER, "serif", HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_constant_override("line_spacing", -4)
	col.add_child(title)
	var sub := UI.label(String(ch_data["subtitle"]), 19, UI.INK2, "serif_italic", HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(sub)
	var hint := UI.label("Tap to continue", 12, UI.MUTE, "mono", HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(UI.spacer(24))
	col.add_child(hint)

	if Fx.motion():
		title.visible_ratio = 0.0
		sub.modulate.a = 0.0
		hint.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(title, "visible_ratio", 1.0, 1.1).set_trans(Tween.TRANS_SINE)
		tw.tween_property(sub, "modulate:a", 1.0, 0.6)
		tw.tween_property(hint, "modulate:a", 1.0, 0.4)
		tw.tween_callback(func() -> void:
			create_tween().set_loops().tween_property(hint, "modulate:a", 0.35, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).from(1.0))
	UI.qa(self, "chapter.tap")
	_ready_at = Time.get_ticks_msec() + (450 if Fx.motion() else 0)


func _gui_input(e: InputEvent) -> void:
	if _go or Time.get_ticks_msec() < _ready_at:
		return
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		_continue()


func _unhandled_key_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and (e.keycode == KEY_ENTER or e.keycode == KEY_SPACE) and not _go and Time.get_ticks_msec() >= _ready_at:
		_continue()


func _continue() -> void:
	_go = true
	Game.save["phase"] = "intro"
	Game.save["line"] = 0
	Game.write_save()
	app.render()
