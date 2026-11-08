class_name Screen
extends Control
## A full-window screen. `content` is the readable column: centred, capped in width,
## wider in landscape. Subclasses build their UI into `content` and place it in layout().

var app: Node
var content := Control.new()
var max_width := 620.0


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(content)
	resized.connect(_relayout)
	# subclasses build in _ready; lay out again once they have
	tree_entered.connect(_relayout.call_deferred)


func landscape() -> bool:
	return size.x > size.y * 1.15


func _relayout() -> void:
	var w := minf(size.x, 1100.0 if landscape() else max_width)
	content.position = Vector2((size.x - w) / 2.0, 0.0)
	content.size = Vector2(w, size.y)
	layout()


## Called whenever the window size changes. Override to reposition.
func layout() -> void:
	pass
