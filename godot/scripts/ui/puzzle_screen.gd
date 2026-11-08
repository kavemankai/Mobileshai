class_name PuzzleScreen
extends Screen
## A puzzle: header, the task, the board, a status line, hints, and reset / hint / skip.
## Fixed to the window: boards size themselves to the space they get. Portrait stacks; landscape puts the board
## on the left and the controls on the right.

var view: PuzzleBase
var _col := VBoxContainer.new()
var _row := HBoxContainer.new()
var _left := VBoxContainer.new()
var _right := VBoxContainer.new()
var _header: Control
var _head := VBoxContainer.new()
var _frame: PanelContainer
var _board := Control.new()
var _status: Label
var _hint_box := VBoxContainer.new()
var _hint_btn: FxButton
var _actions := VBoxContainer.new()
var _is_land := false
var _page := ScrollContainer.new()
var _holder := VBoxContainer.new()
var _pad: MarginContainer
var _spacer := UI.spacer(0, true)
var _solved := false


func _ready() -> void:
	var l := Game.current_level()
	var lvl := int(Game.save["level"])
	Sound.scene(l["scene"], int(l["ch"]))
	Sound.duck(false)
	_header = HeaderBar.new("Chapter %d · %d/%d" % [int(l["ch"]) + 1, Game.level_in_chapter(lvl), Game.chapter_size(int(l["ch"]))],
		String(l["title"]), float(lvl) / float(Game.levels.size()), func() -> void: app.open_evidence(), func() -> void: app.open_menu())

	var kind := String(l["puzzle"]["kind"])
	_head.add_theme_constant_override("separation", 4)
	_head.add_child(UI.eyebrow("%s · %s" % [Puzzles.LABEL.get(kind, kind), l["title"]]))
	_head.add_child(UI.label(Game.fill(String(l["task"])), 16, UI.INK))

	_frame = UI.panel(UI.BG2, 16, UI.LINE, 1, 8)
	_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_frame.custom_minimum_size.y = 200
	_board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board.clip_contents = true
	_frame.add_child(_board)

	_status = UI.label("", 14, UI.INK2, "sans", HORIZONTAL_ALIGNMENT_CENTER)
	_status.custom_minimum_size.y = 22
	_hint_box.add_theme_constant_override("separation", 6)

	_actions.add_theme_constant_override("separation", 8)
	var row := UI.hbox(10)
	var reset := FxButton.new("↺ Reset")
	reset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset.pressed.connect(_on_reset)
	UI.qa(reset, "puzzle.reset")
	row.add_child(reset)
	_hint_btn = FxButton.new("", "normal")
	_hint_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint_btn.pressed.connect(_on_hint)
	UI.qa(_hint_btn, "puzzle.hint")
	row.add_child(_hint_btn)
	_actions.add_child(row)
	if Game.debug:
		var dev := FxButton.new("DEV skip", "dev")
		dev.pressed.connect(func() -> void: app.win(true))
		UI.qa(dev, "puzzle.dev_skip")
		_actions.add_child(dev)
	_actions.add_child(UI.label("No timer. No penalties. Progress saves automatically.", 12, UI.MUTE, "sans", HORIZONTAL_ALIGNMENT_CENTER))

	_col.add_theme_constant_override("separation", 10)
	_row.add_theme_constant_override("separation", 16)
	_left.add_theme_constant_override("separation", 10)
	_right.add_theme_constant_override("separation", 10)
	_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_left.size_flags_stretch_ratio = 1.25
	_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pad := MarginContainer.new()
	_pad = pad
	pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 16)
	content.add_child(pad)
	# a board that needs more room than the window has makes the page scroll, instead of squeezing the board
	_page.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_page.follow_focus = false
	pad.add_child(_page)
	_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page.add_child(_holder)
	_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_holder.add_child(_col)
	_holder.add_child(_row)
	_adopt_layout()
	_refresh_hints()
	_mount()
	layout()


func layout() -> void:
	if _col == null or _header == null:
		return
	var land := landscape()
	if land != _is_land:
		_is_land = land
		_adopt_layout()
		if view:
			view.set_landscape(_is_land)
		_fit_frame()


func _adopt(n: Node, parent: Node) -> void:
	if n.get_parent():
		n.get_parent().remove_child(n)
	parent.add_child(n)


func _adopt_layout() -> void:
	if _is_land:
		_col.visible = false
		_row.visible = true
		# the whole left half is the board; everything else stacks on the right
		_adopt(_header, _right)
		_adopt(_head, _right)
		_adopt(_status, _right)
		_adopt(_hint_box, _right)
		_adopt(_spacer, _right)
		_adopt(_actions, _right)
		_adopt(_frame, _left)
		_adopt(_left, _row)
		_adopt(_right, _row)
		for side in ["top", "bottom"]:
			_pad.add_theme_constant_override("margin_" + side, 10)
	else:
		_row.visible = false
		_col.visible = true
		_adopt(_header, _col)
		_adopt(_head, _col)
		_adopt(_frame, _col)
		_adopt(_status, _col)
		_adopt(_hint_box, _col)
		_adopt(_actions, _col)
		for side in ["top", "bottom"]:
			_pad.add_theme_constant_override("margin_" + side, 16)


## Builds (or rebuilds, for Reset) the puzzle view inside the board.
func _mount() -> void:
	if view:
		view.queue_free()
	_solved = false
	var l := Game.current_level()
	view = Puzzles.make(String(l["puzzle"]["kind"]))
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.status.connect(func(t: String) -> void: _status.text = t)
	view.solved.connect(_on_solved)
	_board.add_child(view)
	view.setup(l["puzzle"], (int(Game.save["level"]) + 1) * 7919, Game.earned_clues())
	view.set_landscape(_is_land)
	view.minimum_size_changed.connect(_fit_frame)
	_fit_frame()
	if Fx.motion():
		Fx.fade_in(view, 0.3)


## A puzzle that needs more height than the window gives sets its own minimum; the page then scrolls.
func _fit_frame() -> void:
	if view:
		# landscape has no height to give: boards fit the window and scroll inside themselves if they must
		_frame.custom_minimum_size.y = 200.0 if _is_land else maxf(200.0, view._asked + 16.0)


func _on_solved(hold_ms: int) -> void:
	if _solved:
		return
	_solved = true
	Fx.haptic(30)
	var lvl := int(Game.save["level"])
	await get_tree().create_timer(float(hold_ms) / 1000.0 if Fx.motion() else 0.3).timeout
	if is_inside_tree() and int(Game.save["level"]) == lvl and Game.save["phase"] == "puzzle":
		app.win(false)


func _on_reset() -> void:
	Sound.sfx("tap")
	_mount()


func _refresh_hints() -> void:
	for c in _hint_box.get_children():
		c.queue_free()
	var lvl := int(Game.save["level"])
	var n := Game.hints_used(lvl)
	var hints: Array = Game.current_level()["hints"]
	for i in mini(n, 2):
		var p := UI.panel(Color(UI.AMBER, 0.08), 8, Color(0, 0, 0, 0), 0, 10)
		var t := UI.label("Hint %d: %s" % [i + 1, Game.fill(String(hints[i]))], 15, UI.INK)
		p.add_child(t)
		_hint_box.add_child(p)
	_hint_btn.text = "Hint %d" % (n + 1) if n < 2 else "Skip puzzle"


func _on_hint() -> void:
	var lvl := int(Game.save["level"])
	if Game.hints_used(lvl) < 2:
		Game.add_hint(lvl)
		Game.write_save()
		Sound.sfx("paper")
		_refresh_hints()
		var p := _hint_box.get_child(_hint_box.get_child_count() - 1) if _hint_box.get_child_count() > 0 else null
		await get_tree().process_frame
		if p and is_instance_valid(p) and p is Control:
			Fx.fade_in(p, 0.3)
	else:
		app.confirm("Skip this puzzle? You still get the evidence and the story carries on. No penalty.", "Skip it", func() -> void: app.win(true))
