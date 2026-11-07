class_name HeaderBar
extends VBoxContainer
## The strip at the top of story and puzzle screens: where you are, the evidence board, the menu,
## and a thin progress line.

var _fill: ColorRect


func _init(chapter_text: String, title_text: String, progress: float, on_evidence: Callable, on_menu: Callable) -> void:
	add_theme_constant_override("separation", 8)
	var row := UI.hbox(8)
	var texts := UI.vbox(0)
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_child(UI.eyebrow(chapter_text))
	var t := UI.label(title_text, 22, UI.INK, "serif", HORIZONTAL_ALIGNMENT_LEFT, false)
	t.clip_text = true
	texts.add_child(t)
	row.add_child(texts)
	var ev := IconButton.new("evidence")
	ev.tooltip_text = "Evidence board"
	ev.pressed.connect(on_evidence)
	UI.qa(ev, "header.evidence")
	row.add_child(ev)
	var mn := IconButton.new("menu")
	mn.tooltip_text = "Menu"
	mn.pressed.connect(on_menu)
	UI.qa(mn, "header.menu")
	row.add_child(mn)
	add_child(row)
	var bar := Control.new()
	bar.custom_minimum_size.y = 3
	var track := ColorRect.new()
	track.color = UI.LINE
	track.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar.add_child(track)
	_fill = ColorRect.new()
	_fill.color = UI.AMBER
	bar.add_child(_fill)
	bar.resized.connect(func() -> void:
		var target := bar.size.x * progress
		if Fx.motion() and _fill.size.x == 0.0:
			_fill.size = Vector2(0, 3)
			create_tween().tween_property(_fill, "size:x", target, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			_fill.size = Vector2(target, 3))
	add_child(bar)
