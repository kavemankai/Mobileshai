class_name PanelArt
extends RefCounted
## Footage behind the frames, by "<panel id>_<view>". Placeholders until the art pass.
## zoom/x/y pan the crop; focus picks the band of a tall picture.

const TABLE := {
	"a_wide": {"f": "cctv/02_wide.webp"}, "a_close": {"f": "cctv/02_close.webp"},
	"b_wide": {"f": "cctv/01_wide.webp"}, "b_close": {"f": "cctv/01_close.webp"},
	"c_wide": {"f": "cctv/05_wide.webp"}, "c_close": {"f": "cctv/05_close.webp"},
	"d_wide": {"f": "art/yard.webp", "focus": 1.0}, "d_close": {"f": "art/yard.webp", "zoom": 2.2, "x": 0.85, "y": 0.8, "focus": 1.0},
	"p_wide": {"f": "art/yard.webp", "focus": 0.0}, "p_close": {"f": "art/yard.webp", "zoom": 2.4, "x": 0.3, "y": 0.2, "focus": 0.0},
	"q_wide": {"f": "art/yard.webp", "focus": 0.5}, "q_close": {"f": "art/yard.webp", "zoom": 2.0, "x": 0.6, "y": 0.6, "focus": 0.5},
	"g_wide": {"f": "art/yard.webp", "zoom": 1.4, "x": 0.1, "y": 0.7, "focus": 0.5}, "g_close": {"f": "art/yard.webp", "zoom": 2.6, "x": 0.05, "y": 0.75, "focus": 0.5},
	"r_wide": {"f": "art/laundry.webp", "focus": 0.5}, "r_close": {"f": "art/laundry.webp", "zoom": 2.2, "x": 0.7, "y": 0.6, "focus": 0.5},
	"t_wide": {"f": "art/yard.webp", "zoom": 1.2, "x": 0.5, "y": 1.0, "focus": 1.0}, "t_close": {"f": "art/yard.webp", "zoom": 2.4, "x": 0.7, "y": 0.9, "focus": 1.0},
	"l_wide": {"f": "art/yard.webp", "zoom": 1.3, "x": 0.9, "y": 0.5, "focus": 0.5}, "l_close": {"f": "art/yard.webp", "zoom": 2.4, "x": 0.95, "y": 0.6, "focus": 0.5},
}


## Textures must stay referenced: a draw call holds only the GPU handle, so a texture nobody owns is freed and draws white.
static var _cache := {}


## {tex, src} where src is the part of the picture to show in a square frame.
static func get_crop(key: String) -> Dictionary:
	if not TABLE.has(key):
		return {}
	var e: Dictionary = TABLE[key]
	var path := "res://assets/%s" % e["f"]
	if not ResourceLoader.exists(path):
		return {}
	if not _cache.has(path):
		_cache[path] = load(path)
	var tex: Texture2D = _cache[path]
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	var s := minf(tw, th)
	var focus := float(e.get("focus", 0.5))
	var ox := (tw - s) * 0.5 if tw > th else 0.0
	var oy := (th - s) * focus if th > tw else 0.0
	var z := float(e.get("zoom", 1.0))
	var px := float(e.get("x", 0.5))
	var py := float(e.get("y", 0.5))
	var side := s / z
	var src := Rect2(ox + (s - side) * px, oy + (s - side) * py, side, side)
	return {"tex": tex, "src": src}
