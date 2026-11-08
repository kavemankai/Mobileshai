class_name App
extends Control
## The root: owns the current screen, the overlay layer, and the flow between phases.

var screen: Screen
var _layer := Control.new()
var _toasts := Control.new()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toasts.set_anchors_preset(Control.PRESET_FULL_RECT)
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_layer)
	add_child(_toasts)
	get_window().size_changed.connect(_fit)
	_fit()
	render()


## One UI unit is one CSS pixel on a phone. Bigger windows scale up a little, capped, so the column stays readable.
func _fit() -> void:
	var win := get_window()
	var dpr := DisplayServer.screen_get_scale() if OS.has_feature("web") else 1.0
	var css := Vector2(win.size) / dpr
	var s := clampf(minf(css.x / 420.0, css.y / 640.0), 1.0, 1.5)
	win.content_scale_factor = dpr * s


func _unhandled_key_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
		var top := _top_sheet()
		if top and top.dismissable:
			top.close()


func _top_sheet() -> Sheet:
	for i in range(_layer.get_child_count() - 1, -1, -1):
		var c := _layer.get_child(i)
		if c is Sheet and not c.is_queued_for_deletion():
			return c
	return null


# ---------- routing ----------

func render() -> void:
	var s: Screen
	if Game.save.is_empty():
		s = TitleScreen.new()
	else:
		match String(Game.save["phase"]):
			"name": s = NameScreen.new()
			"chapter": s = ChapterScreen.new()
			"intro", "reveal": s = StoryScreen.new()
			"puzzle": s = PuzzleScreen.new()
			_: s = EndScreen.new()
	_show(s)


func _show(s: Screen) -> void:
	if screen:
		screen.queue_free()
		remove_child(screen)
	screen = s
	s.app = self
	add_child(s)
	move_child(s, 0)
	if Fx.motion():
		Fx.fade_in(s, 0.25)


func go_title() -> void:
	Game.save = {}
	Game.sandbox = false
	close_overlay()
	render()


func begin_new() -> void:
	Game.sandbox = false
	Game.save = Game.new_save("")
	Game.write_save()
	close_overlay()
	render()


func continue_saved() -> void:
	var saved := Game.read_save_file()
	if saved.is_empty():
		begin_new()
		return
	Game.sandbox = false
	Game.save = saved
	render()


func advance_line() -> void:
	var l := Game.current_level()
	var lines: Array = l["intro"] if Game.save["phase"] == "intro" else l["reveal"]
	if int(Game.save["line"]) < lines.size() - 1:
		Game.save["line"] = int(Game.save["line"]) + 1
		Game.write_save()
		if screen is StoryScreen:
			screen.show_line(true)
		else:
			render()
	else:
		finish_lines()


func finish_lines() -> void:
	if Game.save["phase"] == "intro":
		Game.save["phase"] = "puzzle"
		Game.write_save()
		render()
		return
	next_level()


func next_level() -> void:
	var cur_ch := int(Game.current_level()["ch"])
	if int(Game.save["level"]) >= Game.levels.size() - 1:
		Game.save["phase"] = "end"
		Game.save["finished"] = true
		Game.write_save()
		render()
		return
	Game.save["level"] = int(Game.save["level"]) + 1
	Game.save["line"] = 0
	Game.save["phase"] = "chapter" if int(Game.current_level()["ch"]) != cur_ch else "intro"
	Sound.sfx("door")
	Game.write_save()
	render()


func win(skipped: bool) -> void:
	if Game.save["phase"] != "puzzle":
		return
	Game.earn_clue(int(Game.save["level"]))
	Game.save["phase"] = "reveal"
	Game.save["line"] = 0
	Game.write_save()
	if not Sound.stinger("clue_found"):
		Sound.sfx("clue")
	var card := ClueCard.new(Game.current_level()["clue"], skipped)
	card.closed.connect(render)
	_push(card)


# ---------- overlays ----------

func _push(c: Control) -> void:
	close_overlay()
	_layer.add_child(c)


func has_overlay() -> bool:
	for c in _layer.get_children():
		if not c.is_queued_for_deletion():
			return true
	return false


func close_overlay() -> void:
	for c in _layer.get_children():
		_layer.remove_child(c)
		c.queue_free()


func open_evidence() -> void:
	_push(Sheets.evidence())


func open_menu() -> void:
	_push(Sheets.menu(self))


func open_settings() -> void:
	_push(Sheets.settings(self))


func open_credits() -> void:
	_push(Sheets.credits())


func open_debug() -> void:
	_push(Sheets.debug(self))


func confirm(text: String, yes: String, cb: Callable) -> void:
	_push(Sheets.confirm(self, text, yes, cb))


func toast(text: String) -> void:
	var p := UI.panel(Color(UI.PANEL2, 0.96), 12, UI.LINE, 1, 12)
	p.add_child(UI.label(text, 14, UI.INK, "sans", HORIZONTAL_ALIGNMENT_CENTER))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toasts.add_child(p)
	var w := minf(size.x - 32.0, 420.0)
	p.size = Vector2(w, 0)
	p.reset_size()
	p.size.x = w
	p.position = Vector2((size.x - w) / 2.0, size.y - p.size.y - 40.0)
	var tw := create_tween()
	if Fx.motion():
		p.modulate.a = 0.0
		tw.tween_property(p, "modulate:a", 1.0, 0.2)
	tw.tween_interval(2.2)
	tw.tween_property(p, "modulate:a", 0.0, 0.3)
	tw.tween_callback(p.queue_free)


# ---------- developer tools ----------

func debug_jump(i: int) -> void:
	i = clampi(i, 0, Game.levels.size() - 1)
	Game.sandbox = true
	var clues := []
	for k in i:
		clues.append(k)
	var s: Dictionary = Game.save.duplicate(true) if not Game.save.is_empty() else Game.new_save(Game.DEFAULT_NAME)
	s["level"] = i
	s["phase"] = "puzzle"
	s["line"] = 0
	s["clues"] = clues
	if String(s.get("name", "")) == "":
		s["name"] = Game.DEFAULT_NAME
	Game.save = s
	close_overlay()
	render()


func finish_scene() -> void:
	var ph := String(Game.save.get("phase", ""))
	if ph == "intro" or ph == "reveal":
		finish_lines()
	elif ph == "chapter":
		Game.save["phase"] = "intro"
		Game.save["line"] = 0
		render()
