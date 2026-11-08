class_name EvidencePeek
extends VBoxContainer
## A "Check your evidence" button that unfolds the clues earned so far.


func _init(clues: Array) -> void:
	add_theme_constant_override("separation", 4)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	list.visible = false
	if clues.is_empty():
		list.add_child(UI.label("Nothing on the board yet.", 13, UI.MUTE))
	for c in clues:
		var p := UI.panel(Color(UI.PANEL, 0.9), 8, UI.LINE, 1, 8)
		var v := UI.vbox(2)
		v.add_child(UI.label(String(c["title"]), 12, UI.AMBER2, "mono_bold"))
		v.add_child(UI.label(String(c["text"]), 12, UI.INK2))
		p.add_child(v)
		list.add_child(p)
	var btn := FxButton.new("Check your evidence", "ghost")
	btn.pressed.connect(func() -> void:
		list.visible = not list.visible
		if list.visible:
			Fx.fade_in(list, 0.25))
	UI.qa(btn, "evidence.peek")
	add_child(btn)
	add_child(list)
