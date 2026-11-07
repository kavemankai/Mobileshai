class_name StoryScreen
extends Screen
## The story: scene art that drifts under rain, a portrait that slides in when someone speaks,
## and dialogue that types itself. The screen stays alive across lines, so nothing restarts per tap.

const TYPE_SPEED := 62.0  # characters per second

var _col := VBoxContainer.new()
var _row := HBoxContainer.new()
var _left := VBoxContainer.new()
var _right := VBoxContainer.new()
var _header: Control
var _art_box := Control.new()
var _art: ArtView
var _portrait := TextureRect.new()
var _portrait_mat := ShaderMaterial.new()
var _panel: PanelContainer
var _speaker: Label
var _line: Label
var _hint: Label
var _back: FxButton
var _typing: Tween
var _typing_done := true
var _is_land := false
var _shown_portrait: Texture2D


func _ready() -> void:
	var l := Game.current_level()
	var progress := (float(Game.save["level"]) + (1.0 if Game.save["phase"] == "reveal" else 0.0)) / float(Game.levels.size())
	_header = HeaderBar.new("Chapter %d · %d/%d" % [int(l["ch"]) + 1, Game.level_in_chapter(int(Game.save["level"])), Game.chapter_size(int(l["ch"]))],
		String(l["title"]), progress, func() -> void: app.open_evidence(), func() -> void: app.open_menu())

	_art = ArtView.new(Assets.scene(l["scene"]), 14.0, 0.35, 0.45)
	_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	_art_box.clip_contents = true
	_art_box.add_child(_art)
	_art.drift()
	var rain := ColorRect.new()
	rain.set_anchors_preset(Control.PRESET_FULL_RECT)
	rain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rm := ShaderMaterial.new()
	rm.shader = load("res://shaders/rain.gdshader")
	rain.material = rm
	_art_box.add_child(rain)
	_portrait_mat.shader = load("res://shaders/portrait.gdshader")
	_portrait.material = _portrait_mat
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_SCALE
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait.visible = false
	_art_box.add_child(_portrait)
	_art_box.resized.connect(_place_portrait)
	_art_box.mouse_filter = Control.MOUSE_FILTER_PASS
	_art_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_panel = UI.panel(Color(UI.BG2, 0.97), 16, UI.LINE, 1, 18)
	_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var box := UI.vbox(8)
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	_speaker = UI.label("", 12, UI.AMBER, "mono_bold", HORIZONTAL_ALIGNMENT_LEFT, false)
	box.add_child(_speaker)
	_line = UI.label("", 20, UI.INK, "serif")
	_line.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_line)
	_hint = UI.label("", 11, UI.MUTE, "mono", HORIZONTAL_ALIGNMENT_RIGHT, false)
	box.add_child(_hint)
	_panel.add_child(box)

	var nav := UI.hbox(8)
	_back = FxButton.new("‹ Back", "ghost")
	_back.pressed.connect(_on_back)
	UI.qa(_back, "story.back")
	nav.add_child(_back)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(gap)
	var skip := FxButton.new("Skip to the puzzle ›" if Game.save["phase"] == "intro" else "Skip ›", "ghost")
	skip.pressed.connect(func() -> void: app.finish_lines())
	UI.qa(skip, "story.skip")
	nav.add_child(skip)
	_nav = nav

	_col.add_theme_constant_override("separation", 10)
	_row.add_theme_constant_override("separation", 16)
	_left.add_theme_constant_override("separation", 10)
	_right.add_theme_constant_override("separation", 10)
	_left.size_flags_stretch_ratio = 1.35
	_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for c in [_col, _row, _left, _right]:
		c.mouse_filter = Control.MOUSE_FILTER_PASS
	var pad := MarginContainer.new()
	pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	pad.mouse_filter = Control.MOUSE_FILTER_PASS
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 16)
	content.add_child(pad)
	pad.add_child(_col)
	pad.add_child(_row)
	_adopt_portrait_layout()
	UI.qa(self, "story.tap")
	layout()
	show_line(false)


var _nav: Control


func layout() -> void:
	if _col == null or _header == null:
		return
	var land := landscape()
	if land != _is_land:
		_is_land = land
		_adopt_portrait_layout()
	if not land:
		_art_box.custom_minimum_size.y = clampf(size.y * 0.46, 220.0, 480.0)
	else:
		_art_box.custom_minimum_size.y = 0.0
	_place_portrait()


func _adopt(n: Node, parent: Node) -> void:
	if n.get_parent():
		n.get_parent().remove_child(n)
	parent.add_child(n)


func _adopt_portrait_layout() -> void:
	if _is_land:
		_col.visible = false
		_row.visible = true
		_adopt(_header, _left)
		_adopt(_art_box, _left)
		_art_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_adopt(_panel, _right)
		_adopt(_nav, _right)
		_adopt(_left, _row)
		_adopt(_right, _row)
	else:
		_row.visible = false
		_col.visible = true
		_adopt(_header, _col)
		_adopt(_art_box, _col)
		_art_box.size_flags_vertical = Control.SIZE_FILL
		_adopt(_panel, _col)
		_adopt(_nav, _col)


func _lines() -> Array:
	var l := Game.current_level()
	return l["intro"] if Game.save["phase"] == "intro" else l["reveal"]


## Shows the line the save points at: speaker, portrait, scene look, then the typed text.
func show_line(animate: bool = true) -> void:
	var lines := _lines()
	var idx := clampi(int(Game.save["line"]), 0, lines.size() - 1)
	Game.save["line"] = idx
	var sp := Assets.speaker(String(lines[idx][0]))
	var narrator: bool = sp["key"] == "NARRATOR"
	var is_you: bool = sp["key"] == "YOU"
	_speaker.visible = not narrator
	_speaker.text = Game.player_name().to_upper() if is_you else String(sp["name"]).to_upper()
	_line.text = Game.fill(String(lines[idx][1]))
	_line.add_theme_font_override("font", UI.font("serif_italic" if narrator else "serif"))
	_line.add_theme_color_override("font_color", UI.INK2 if narrator else UI.INK)
	_hint.text = "Tap to continue · %d/%d" % [idx + 1, lines.size()]
	_back.disabled = idx == 0
	_back.modulate.a = 0.4 if idx == 0 else 1.0
	_art.set_remote(1.0 if sp["remote"] else 0.0, animate)
	Sound.duck(true)
	var last: bool = idx == lines.size() - 1 and Game.save["phase"] == "reveal" and int(Game.save["level"]) == Game.levels.size() - 1
	Sound.scene(Game.current_level()["scene"], int(Game.current_level()["ch"]), last and idx > 2)
	_set_portrait(Assets.portrait(sp), sp, animate)
	if animate:
		_line_sound(sp, idx, lines)
	_type(animate)


func _line_sound(sp: Dictionary, idx: int, lines: Array) -> void:
	var tag := String(lines[idx][0])
	var prev := String(lines[idx - 1][0]) if idx > 0 else ""
	var nina_arrives := tag.begins_with("NINA") and not prev.begins_with("NINA") and not tag.contains("NOTE")
	if nina_arrives and Sound.stinger("nina_voice"):
		return
	if tag.contains("PHONE"):
		Sound.sfx("phone")
	elif tag.contains("RECORDING") or tag.contains("INTERCOM"):
		Sound.sfx("static")
	else:
		Sound.sfx("tap", 0.04)


func _type(animate: bool) -> void:
	if _typing:
		_typing.kill()
	if not animate or not Fx.motion():
		_line.visible_ratio = 1.0
		_typing_done = true
		return
	_line.visible_ratio = 0.0
	_typing_done = false
	var secs := maxf(float(_line.text.length()) / TYPE_SPEED, 0.2)
	_typing = create_tween()
	_typing.tween_property(_line, "visible_ratio", 1.0, secs)
	_typing.tween_callback(func() -> void: _typing_done = true)


func _finish_typing() -> void:
	if _typing:
		_typing.kill()
	_line.visible_ratio = 1.0
	_typing_done = true


# ---------- portrait ----------

func _set_portrait(tex: Texture2D, sp: Dictionary, animate: bool) -> void:
	if tex == null:
		if _portrait.visible:
			if animate and Fx.motion():
				var tw := create_tween()
				tw.tween_property(_portrait, "modulate:a", 0.0, 0.2)
				tw.tween_callback(func() -> void: _portrait.visible = false)
			else:
				_portrait.visible = false
		_shown_portrait = null
		return
	var cut: bool = Assets.CUTOUTS.has(sp["key"])
	_portrait_mat.set_shader_parameter("edge_fade", 0.0 if cut else 1.0)
	_portrait_mat.set_shader_parameter("desaturate", 0.55 if sp["remote"] else 0.0)
	var changed := tex != _shown_portrait
	_portrait.texture = tex
	_shown_portrait = tex
	_portrait.visible = true
	_place_portrait()
	if changed and animate and Fx.motion():
		_portrait.modulate.a = 0.0
		var end := _portrait.position
		_portrait.position = end + Vector2(36, 0)
		var tw2 := create_tween().set_parallel(true)
		tw2.tween_property(_portrait, "modulate:a", 1.0, 0.35)
		tw2.tween_property(_portrait, "position", end, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		_portrait.modulate.a = 1.0


func _place_portrait() -> void:
	if _portrait.texture == null:
		return
	var box := _art_box.size
	if box.x <= 1.0 or box.y <= 1.0:
		return
	var aspect := float(_portrait.texture.get_width()) / float(_portrait.texture.get_height())
	var h := box.y * 0.94
	var w := h * aspect
	if w > box.x * 0.62:
		w = box.x * 0.62
		h = w / aspect
	_portrait.size = Vector2(w, h)
	_portrait.position = Vector2(box.x - w - 4.0, box.y - h)
	_portrait_mat.set_shader_parameter("rect_size", _portrait.size)


# ---------- input ----------

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		_tap()


func _unhandled_key_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not app.has_overlay() and (e.keycode == KEY_ENTER or e.keycode == KEY_SPACE or e.keycode == KEY_RIGHT):
		_tap()


func _tap() -> void:
	if not _typing_done:
		_finish_typing()
		return
	app.advance_line()


func _on_back() -> void:
	if int(Game.save["line"]) > 0:
		Game.save["line"] = int(Game.save["line"]) - 1
		Game.write_save()
		show_line(false)
