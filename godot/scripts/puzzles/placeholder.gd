class_name PlaceholderPuzzle
extends PuzzleBase
## Stands in for a puzzle that has not been built yet, so the whole story still plays end to end.


func build() -> void:
	var col := UI.vbox(12)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(UI.margin(col, 20))
	get_child(0).set_anchors_preset(Control.PRESET_FULL_RECT)
	col.add_child(UI.label("%s puzzle" % str(Puzzles.LABEL.get(def.get("kind", ""), def.get("kind", ""))), 22, UI.INK, "serif", HORIZONTAL_ALIGNMENT_CENTER))
	col.add_child(UI.label("Not built yet.", 14, UI.MUTE, "sans", HORIZONTAL_ALIGNMENT_CENTER))
	var b := FxButton.new("Solve (placeholder)", "primary")
	b.pressed.connect(func() -> void: finish())
	qa(b, "placeholder.solve")
	col.add_child(b)
	say("Placeholder for the %s puzzle." % def.get("kind", ""))


func qa_state() -> Dictionary:
	return {"kind": def.get("kind", ""), "placeholder": true}
