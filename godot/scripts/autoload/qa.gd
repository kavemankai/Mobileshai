extends Node
## Test bridge for the browser, on only when the page is opened with ?debug=1.
## window.__lci.<call>(...) returns plain JSON. Control positions come out in CSS pixels
## so a test can click exactly where a player would.

var _cb: JavaScriptObject


func _ready() -> void:
	if not (OS.has_feature("web") and Game.debug):
		return
	_cb = JavaScriptBridge.create_callback(_call)
	var win := JavaScriptBridge.get_interface("window")
	win.__lci_cb = _cb
	JavaScriptBridge.eval("""
	(function () {
		const call = (n, a) => { const h = {}; window.__lci_cb(n, JSON.stringify(a), h); return h.v === undefined ? null : JSON.parse(h.v); };
		window.__lci = {};
		for (const n of ['state','jump','skip','finishScene','closeOverlay','level','audio','rects','puzzle','screen','meta'])
			window.__lci[n] = (...a) => call(n, a);
	})();
	""")


func _app() -> App:
	return get_tree().current_scene as App


func _call(args: Array) -> void:
	var name_: String = args[0]
	var a: Array = JSON.parse_string(args[1])
	var out: Variant = null
	var app := _app()
	match name_:
		"state":
			var s: Dictionary = Game.save.duplicate(true)
			if not s.is_empty():
				s["sandbox"] = Game.sandbox
				s["overlay"] = app.has_overlay() if app else false
			out = s if not s.is_empty() else null
		"meta":
			out = {"levels": Game.levels.size(), "debug": Game.debug}
		"screen":
			out = app.screen.get_class() if app and app.screen else ""
			if app and app.screen and app.screen.get_script():
				out = String(app.screen.get_script().get_global_name())
		"jump":
			app.debug_jump(int(a[0]))
		"skip":
			if Game.save.get("phase", "") == "puzzle":
				app.win(true)
		"finishScene":
			app.finish_scene()
		"closeOverlay":
			app.close_overlay()
			app.render()
		"level":
			out = Game.level(int(a[0]))["puzzle"]
		"audio":
			out = Sound.status()
		"puzzle":
			var v = app.screen.get("view") if app and app.screen else null
			out = v.qa_state() if v else null
		"rects":
			out = _rects()
	var holder: JavaScriptObject = args[2]
	holder.v = JSON.stringify(out)


func _rects() -> Array:
	var dpr := float(JavaScriptBridge.eval("window.devicePixelRatio || 1"))
	var res := []
	var vp := get_tree().root
	for n in get_tree().get_nodes_in_group("qa"):
		if not (n is Control) or not n.is_visible_in_tree():
			continue
		var c: Control = n
		var xf := vp.get_final_transform() * c.get_global_transform_with_canvas()
		var r := xf * Rect2(Vector2.ZERO, c.size)
		res.append({"id": String(c.get_meta("qa")), "x": r.position.x / dpr, "y": r.position.y / dpr, "w": r.size.x / dpr, "h": r.size.y / dpr,
			"disabled": (c is BaseButton and c.disabled)})
	return res
