class_name BoxPuzzle
extends PuzzleBase
## Mechanism: a box that opens in stages. Each stage hands you a note that helps with a later one.

var idx := 0
var _stage: Control
var _holder: Control
var _clue: Label
var _stage_label: Label
var _pips: Control
var _notes: VBoxContainer
var _busy := false
var _shown := 0


func build() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var col := UI.vbox(8)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(col)
	var head := UI.hbox(8)
	var name_l := UI.label(String(def["name"]), 16, UI.PAPER, "serif_bold", HORIZONTAL_ALIGNMENT_LEFT, false)
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_l)
	_stage_label = UI.label("", 12, UI.MUTE, "mono", HORIZONTAL_ALIGNMENT_RIGHT, false)
	head.add_child(_stage_label)
	_pips = Control.new()
	_pips.custom_minimum_size = Vector2(14.0 * def["stages"].size(), 16)
	_pips.draw.connect(_draw_pips)
	head.add_child(_pips)
	col.add_child(head)
	_clue = UI.label("", 14, UI.INK2)
	col.add_child(_clue)
	_holder = Control.new()
	_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_holder.custom_minimum_size.y = 230
	_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_holder)
	col.add_child(UI.eyebrow("Found on the mechanism", UI.MUTE))
	_notes = UI.vbox(4)
	col.add_child(_notes)
	ask_height(470)
	_show()


func _draw_pips() -> void:
	for i in def["stages"].size():
		var c := Vector2(7.0 + 14.0 * i, 8.0)
		var col := UI.TEAL if i < idx else (UI.AMBER if i == idx else UI.LINE)
		_pips.draw_circle(c, 4.5 if i == idx else 3.5, col)


func _show() -> void:
	var st: Dictionary = def["stages"][idx]
	_shown = idx
	_stage_label.text = "Stage %d of %d" % [idx + 1, def["stages"].size()]
	_pips.queue_redraw()
	_clue.text = "" if st["type"] == "screws" else String(st.get("clue", ""))
	_clue.visible = _clue.text != ""
	if _stage:
		_stage.queue_free()
	_stage = BoxStages.make(st, clues)
	_stage.status.connect(say)
	_stage.done.connect(_stage_done.bind(st))
	_holder.add_child(_stage)
	UI.qa(_stage, "box.stage")
	if Fx.motion():
		_stage.modulate.a = 0.0
		_stage.scale = Vector2(0.96, 0.96)
		_stage.pivot_offset = _holder.size / 2.0
		var tw := create_tween().set_parallel(true)
		tw.tween_property(_stage, "modulate:a", 1.0, 0.3)
		tw.tween_property(_stage, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_busy = false


func _stage_done(st: Dictionary) -> void:
	if _busy:
		return
	_busy = true
	sfx("latch")
	haptic(20)
	var note := UI.label("• " + String(st["note"]), 13, UI.INK, "serif")
	_notes.add_child(note)
	Fx.fade_in(note, 0.5)
	idx += 1
	_pips.queue_redraw()
	if Fx.motion():
		var tw := create_tween().set_parallel(true)
		tw.tween_property(_stage, "modulate", Color(1.6, 1.5, 1.2, 0.0), 0.5)
		await tw.finished
	if idx >= def["stages"].size():
		sfx("solve")
		finish(1000 if Fx.motion() else 300)
	else:
		_show()


func qa_state() -> Dictionary:
	var st: Dictionary = def["stages"][_shown]
	return {"kind": "box", "stage": _shown, "stages": def["stages"].size(), "type": st["type"], "def": st,
		"ui": _stage.qa() if _stage and is_instance_valid(_stage) else {}, "busy": _busy, "done": is_done()}
