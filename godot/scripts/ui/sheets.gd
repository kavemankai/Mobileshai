class_name Sheets
extends RefCounted
## The modal sheets: evidence, pause menu, settings, credits, confirm, developer tools.


static func evidence() -> Sheet:
	var s := Sheet.new("Evidence board")
	var list := Game.earned_clues()
	if list.is_empty():
		s.add(UI.label("Nothing yet. Every solved puzzle adds evidence here.", 15, UI.MUTE))
	for ch in Game.chapters.size():
		var items := list.filter(func(x: Dictionary) -> bool: return int(x["ch"]) == ch)
		if items.is_empty():
			continue
		s.add(UI.eyebrow("Chapter %d · %s" % [ch + 1, Game.chapters[ch]["name"]]))
		for x in items:
			var p := UI.panel(Color(UI.PANEL, 0.9), 10, UI.LINE, 1, 12)
			var c := UI.vbox(4)
			c.add_child(UI.label(String(x["title"]), 16, UI.AMBER2, "serif_bold"))
			c.add_child(UI.label(String(x["text"]), 14, UI.INK2))
			p.add_child(c)
			s.add(p)
	return s


static func menu(app: App) -> Sheet:
	var s := Sheet.new("Paused")
	var resume := FxButton.new("Resume", "primary")
	resume.pressed.connect(s.close)
	UI.qa(resume, "menu.resume")
	s.add(resume)
	var ev := FxButton.new("Evidence board")
	ev.pressed.connect(func() -> void: app.open_evidence())
	UI.qa(ev, "menu.evidence")
	s.add(ev)
	var st := FxButton.new("Settings")
	st.pressed.connect(func() -> void: app.open_settings())
	UI.qa(st, "menu.settings")
	s.add(st)
	if Game.debug:
		var d := FxButton.new("Developer tools", "dev")
		d.pressed.connect(func() -> void: app.open_debug())
		UI.qa(d, "menu.dev")
		s.add(d)
	var t := FxButton.new("Back to the title", "ghost")
	t.pressed.connect(func() -> void: app.go_title())
	UI.qa(t, "menu.title")
	s.add(t)
	return s


static func _grabber() -> Texture2D:
	var img := Image.create(28, 28, false, Image.FORMAT_RGBA8)
	for y in 28:
		for x in 28:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(Vector2(14, 14))
			var a := clampf(14.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(UI.AMBER2, a))
	return ImageTexture.create_from_image(img)


static func _slider(key: String, label: String) -> Control:
	var row := UI.hbox(12)
	var l := UI.label(label, 15, UI.INK, "sans", HORIZONTAL_ALIGNMENT_LEFT, false)
	l.custom_minimum_size.x = 120
	row.add_child(l)
	var sl := HSlider.new()
	sl.min_value = 0.0
	sl.max_value = 1.0
	sl.step = 0.05
	sl.value = float(Game.settings[key])
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.custom_minimum_size.y = 34
	var track := UI.flat(UI.LINE, 3)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	var fill := UI.flat(UI.AMBER, 3)
	fill.content_margin_top = 3
	fill.content_margin_bottom = 3
	sl.add_theme_stylebox_override("slider", track)
	sl.add_theme_stylebox_override("grabber_area", fill)
	sl.add_theme_stylebox_override("grabber_area_highlight", fill)
	var g := _grabber()
	sl.add_theme_icon_override("grabber", g)
	sl.add_theme_icon_override("grabber_highlight", g)
	sl.add_theme_icon_override("grabber_disabled", g)
	sl.value_changed.connect(func(v: float) -> void: Game.set_setting(key, v))
	sl.drag_ended.connect(func(_c: bool) -> void: Sound.sfx("tap"))
	UI.qa(sl, "settings." + key)
	row.add_child(sl)
	return row


static func _toggle(key: String, label: String) -> Control:
	var row := UI.hbox(12)
	var l := UI.label(label, 15, UI.INK)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var t := ToggleSwitch.new(bool(Game.settings[key]))
	t.toggled.connect(func(on: bool) -> void: Game.set_setting(key, on))
	UI.qa(t, "settings." + key)
	row.add_child(t)
	return row


static func settings(app: App) -> Sheet:
	var s := Sheet.new("Settings")
	s.add(_slider("master", "Master volume"))
	s.add(_slider("music", "Music"))
	s.add(_slider("ambience", "Ambience"))
	s.add(_slider("effects", "Effects"))
	s.add(_toggle("muted", "Mute everything"))
	s.add(_toggle("reduced_motion", "Reduce motion"))
	s.add(_toggle("haptics", "Vibration (Android)"))
	s.add(UI.label("Text size", 15, UI.INK))
	var seg := UI.hbox(8)
	for n in [1, 2, 3]:
		var b := FxButton.new(["Normal", "Large", "Larger"][n - 1], "primary" if int(Game.settings["text_size"]) == n else "normal")
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void:
			Game.set_setting("text_size", n)
			# a puzzle in progress keeps its board; the new size applies from the next screen
			if not (app.screen is PuzzleScreen):
				app.render()
			app.open_settings())
		UI.qa(b, "settings.text%d" % n)
		seg.add_child(b)
	s.add(seg)
	return s


static func credits() -> Sheet:
	var s := Sheet.new("Credits")
	s.add(UI.label("Story, puzzles and code: made for one particular player.", 16, UI.INK, "serif"))
	s.add(UI.label("Art and sound in this build are placeholders. ASSETS.md lists what each one will become.", 14, UI.INK2))
	s.add(UI.label("Built with Godot Engine. Fonts: Liberation Serif, DejaVu, Noto Color Emoji (open licences).", 12, UI.MUTE))
	return s


static func confirm(app: App, text: String, yes: String, cb: Callable) -> Sheet:
	var s := Sheet.new("Are you sure?")
	s.add(UI.label(text, 16, UI.INK))
	var y := FxButton.new(yes, "primary")
	y.pressed.connect(func() -> void:
		app.close_overlay()
		cb.call())
	UI.qa(y, "confirm.yes")
	s.add(y)
	var n := FxButton.new("Cancel", "ghost")
	n.pressed.connect(s.close)
	UI.qa(n, "confirm.no")
	s.add(n)
	return s


static func debug(app: App) -> Sheet:
	var s := Sheet.new("Developer tools")
	s.add(UI.label("Jumping opens a sandbox that never overwrites the real save. Return to the title and Continue to get back.", 12, UI.MUTE))
	s.add(UI.eyebrow("Jump to puzzle"))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	for i in Game.levels.size():
		var b := FxButton.new("%02d %s" % [i + 1, Game.level(i)["puzzle"]["kind"]], "dev")
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void: app.debug_jump(i))
		grid.add_child(b)
	s.add(grid)
	s.add(UI.eyebrow("Sound audition"))
	var g2 := GridContainer.new()
	g2.columns = 3
	g2.add_theme_constant_override("h_separation", 6)
	g2.add_theme_constant_override("v_separation", 6)
	for n in ["tap", "pick", "place", "invalid", "solve", "clue", "power", "door", "latch", "ratchet", "pour", "combo", "static", "phone", "chapter"]:
		var b := FxButton.new(n, "dev")
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void: Sound.sfx(n))
		g2.add_child(b)
	s.add(g2)
	return s
