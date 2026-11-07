extends Control
# Prototype: JS bridge rect lookup + emoji font fallback + button input.
var _cb: JavaScriptObject

func _ready() -> void:
	var f := FontVariation.new()
	f.base_font = load("res://assets/fonts/serif.ttf")
	f.fallbacks = [load("res://assets/fonts/emoji_subset.ttf"), load("res://assets/fonts/symbols.ttf")]
	var lab := Label.new()
	lab.text = "🗄️ 🪛 🧤 🔦 ✓ ✗ ▲ ▼ ⠿ ⟳ 🕸️"
	lab.add_theme_font_override("font", f)
	lab.add_theme_font_size_override("font_size", 30)
	lab.position = Vector2(20, 120)
	add_child(lab)

	var btn := Button.new()
	btn.text = "Tap me"
	btn.position = Vector2(100, 300)
	btn.size = Vector2(240, 90)
	btn.add_to_group("qa")
	btn.set_meta("qa", "btn")
	add_child(btn)
	btn.pressed.connect(func() -> void:
		print("PRESSED")
		btn.text = "Pressed!")

	if OS.has_feature("web"):
		_cb = JavaScriptBridge.create_callback(_js_rects)
		var win := JavaScriptBridge.get_interface("window")
		win.__gd_rects = _cb
	print("proto ready")

func _js_rects(args: Array) -> void:
	var out := []
	var dpr: float = float(JavaScriptBridge.eval("window.devicePixelRatio"))
	var xf := get_viewport().get_final_transform()
	for n in get_tree().get_nodes_in_group("qa"):
		var c := n as Control
		if c == null or not c.is_visible_in_tree():
			continue
		var t := c.get_global_transform_with_canvas()
		var p0: Vector2 = xf * (t * Vector2.ZERO)
		var p1: Vector2 = xf * (t * c.size)
		out.append({"id": c.get_meta("qa"), "x": p0.x / dpr, "y": p0.y / dpr, "w": (p1.x - p0.x) / dpr, "h": (p1.y - p0.y) / dpr})
	args[0].v = JSON.stringify(out)
