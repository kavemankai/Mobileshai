class_name Sheet
extends Control
## A modal sheet: a dimmed backdrop and a panel that slides up (centred in landscape).
## Build the body with add(), or fill `body` directly.

signal closed

var dim := ColorRect.new()
var panel := PanelContainer.new()
var body := VBoxContainer.new()
var scroll := ScrollContainer.new()
var dismissable := true
var _closing := false
var _title: String


func _init(title_text: String = "", dismissable_: bool = true) -> void:
	_title = title_text
	dismissable = dismissable_
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	dim.color = Color(0.016, 0.03, 0.047, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	panel.add_theme_stylebox_override("panel", UI.flat(UI.BG2, 18, UI.LINE, 1, 18))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)
	var col := UI.vbox(12)
	panel.add_child(col)
	if _title != "":
		var head := UI.hbox(8)
		var t := UI.label(_title, 24, UI.INK, "serif", HORIZONTAL_ALIGNMENT_LEFT, false)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(t)
		if dismissable:
			var x := IconButton.new("close")
			x.pressed.connect(close)
			UI.qa(x, "sheet.close")
			x.tooltip_text = "Close"
			head.add_child(x)
		col.add_child(head)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	col.add_child(scroll)
	resized.connect(_place)
	dim.gui_input.connect(func(e: InputEvent) -> void:
		if dismissable and e is InputEventMouseButton and e.pressed:
			close())


func _ready() -> void:
	_place()
	if Fx.motion():
		dim.modulate.a = 0.0
		panel.modulate.a = 0.0
		var end := panel.position
		panel.position = end + Vector2(0, 60)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(dim, "modulate:a", 1.0, 0.22)
		tw.tween_property(panel, "modulate:a", 1.0, 0.22)
		tw.tween_property(panel, "position", end, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func add(c: Control) -> Control:
	body.add_child(c)
	return c


func _place() -> void:
	var land := size.x > size.y * 1.15
	var w := minf(size.x - 24.0, 620.0)
	var max_h := size.y * (0.9 if not land else 0.92) - 24.0
	panel.size = Vector2(w, 0)
	# the scroll area gets the body's height, up to what is left of the screen
	var chrome := 18.0 * 2 + (62.0 if _title != "" else 0.0) + 12.0
	scroll.custom_minimum_size.y = minf(body.get_combined_minimum_size().y, max_h - chrome)
	panel.reset_size()
	panel.size.x = w
	var h := minf(panel.get_combined_minimum_size().y, max_h)
	panel.size = Vector2(w, h)
	var x := (size.x - w) / 2.0
	var y := (size.y - h) / 2.0 if land else size.y - h - 12.0
	panel.position = Vector2(x, y)


func close() -> void:
	if _closing:
		return
	_closing = true
	Sound.sfx("paper")
	if Fx.motion():
		var tw := create_tween().set_parallel(true)
		tw.tween_property(dim, "modulate:a", 0.0, 0.18)
		tw.tween_property(panel, "modulate:a", 0.0, 0.18)
		tw.tween_property(panel, "position:y", panel.position.y + 40.0, 0.18)
		tw.chain().tween_callback(_finish)
	else:
		_finish()


func _finish() -> void:
	closed.emit()
	queue_free()
