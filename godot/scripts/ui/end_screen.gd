class_name EndScreen
extends Screen
## Case closed: the motel at dawn and a short wrap-up.


func _ready() -> void:
	Sound.scene("exterior", 3, true)
	Sound.duck(false)
	var art := ArtView.new(Assets.scene("exterior"), 0.0, 0.5, 0.5)
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(art)
	move_child(art, 0)
	art.drift(1.02, 1.08, 30.0)
	var shade := ColorRect.new()
	shade.color = Color(UI.BG, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	move_child(shade, 1)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var pad := UI.margin(UI.vbox(0), 16)
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(pad)
	var outer: VBoxContainer = pad.get_child(0)
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(UI.spacer(0, true))

	var card := UI.panel(Color(UI.BG2, 0.95), 18, UI.LINE, 1, 22)
	outer.add_child(card)
	var col := UI.vbox(10)
	card.add_child(col)
	var hints := 0
	for k in Game.save["hints"]:
		hints += int(Game.save["hints"][k])
	col.add_child(UI.eyebrow("Case closed"))
	col.add_child(UI.label("Before dawn", 34, UI.PAPER, "serif", HORIZONTAL_ALIGNMENT_LEFT, false))
	col.add_child(UI.label("Nina is safe. Daniel Price is in custody. Owen Mercer is answering questions he has avoided for seven years. Mara Ward’s case is open again.", 17, UI.INK, "serif"))
	col.add_child(UI.label(Game.fill("And {name} has a story nobody at the Mariner will let them forget."), 17, UI.INK2, "serif_italic"))
	col.add_child(UI.label("%d pieces of evidence · %d hint%s used" % [Game.save["clues"].size(), hints, "" if hints == 1 else "s"], 12, UI.MUTE, "mono", HORIZONTAL_ALIGNMENT_LEFT, false))
	var ev := FxButton.new("Evidence board")
	ev.pressed.connect(func() -> void: app.open_evidence())
	UI.qa(ev, "end.evidence")
	col.add_child(ev)
	var back := FxButton.new("Back to the title", "primary")
	back.pressed.connect(func() -> void: app.go_title())
	UI.qa(back, "end.title")
	col.add_child(back)
	if Fx.motion():
		for i in col.get_child_count():
			Fx.fade_in(col.get_child(i), 0.7, 0.3 + i * 0.12)
