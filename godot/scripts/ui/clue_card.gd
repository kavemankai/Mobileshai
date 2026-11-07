class_name ClueCard
extends Control
## The evidence card that lands on the screen when a puzzle is solved: paper, a rubber stamp, a short burst.

signal closed

var _dim := ColorRect.new()
var _card: PanelContainer
var _stamp: PanelContainer
var _btn: FxButton
var _done := false


func _init(clue: Dictionary, skipped: bool) -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.color = Color(0.016, 0.03, 0.047, 0.8)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_dim)

	_card = UI.panel(UI.PAPER2, 6, UI.PAPER_LINE, 1, 24)
	add_child(_card)
	var col := UI.vbox(10)
	_card.add_child(col)
	col.add_child(UI.label(("EVIDENCE ADDED · PUZZLE SKIPPED" if skipped else "EVIDENCE ADDED"), 12, Color("8a6b2f"), "mono_bold", HORIZONTAL_ALIGNMENT_LEFT, false))
	col.add_child(UI.label(String(clue["title"]), 28, UI.PAPER_INK, "serif_bold"))
	var rule := ColorRect.new()
	rule.color = UI.PAPER_LINE
	rule.custom_minimum_size.y = 1
	col.add_child(rule)
	col.add_child(UI.label(Game.fill(String(clue["text"])), 18, UI.PAPER_INK, "serif"))
	col.add_child(UI.spacer(6))
	_btn = FxButton.new("Continue", "primary")
	_btn.pressed.connect(_close)
	UI.qa(_btn, "clue.continue")
	col.add_child(_btn)

	_stamp = UI.panel(Color(0, 0, 0, 0), 4, Color(UI.RED, 0.85), 3, 6)
	_stamp.add_child(UI.label("LOGGED", 18, Color(UI.RED, 0.9), "mono_bold", HORIZONTAL_ALIGNMENT_CENTER, false))
	_stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stamp)
	resized.connect(_place)


func _ready() -> void:
	_place.call_deferred()
	_animate.call_deferred()


func _place() -> void:
	var w := minf(size.x - 32.0, 440.0)
	_card.size = Vector2(w, 0)
	_card.reset_size()
	_card.size.x = w
	_card.position = Vector2((size.x - w) / 2.0, (size.y - _card.size.y) / 2.0)
	_card.pivot_offset = _card.size / 2.0
	_stamp.reset_size()
	_stamp.pivot_offset = _stamp.size / 2.0
	_stamp.rotation = deg_to_rad(-9.0)
	_stamp.position = _card.position + Vector2(w - _stamp.size.x - 14.0, 18.0)


func _animate() -> void:
	_place()
	if not Fx.motion():
		return
	_dim.modulate.a = 0.0
	_card.modulate.a = 0.0
	_stamp.modulate.a = 0.0
	var end := _card.position
	_card.position = end + Vector2(0, 70)
	_card.rotation = deg_to_rad(2.5)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_dim, "modulate:a", 1.0, 0.25)
	tw.tween_property(_card, "modulate:a", 1.0, 0.25)
	tw.tween_property(_card, "position", end, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_card, "rotation", 0.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# the stamp lands after the paper settles
	_stamp.scale = Vector2(2.4, 2.4)
	var st := create_tween()
	st.tween_interval(0.5)
	st.tween_callback(func() -> void:
		_stamp.modulate.a = 1.0
		Sound.sfx("place")
		Fx.haptic(24))
	st.tween_property(_stamp, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	st.tween_callback(func() -> void:
		Fx.burst(self, _stamp.position + _stamp.size / 2.0, UI.AMBER, 22, 260.0, 4.0)
		Fx.shake(_card, 4.0, 0.2))


func _close() -> void:
	if _done:
		return
	_done = true
	closed.emit()
	queue_free()


func _unhandled_key_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and (e.keycode == KEY_ENTER or e.keycode == KEY_SPACE):
		_close()
