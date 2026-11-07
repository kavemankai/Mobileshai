class_name UI
extends RefCounted
## Palette, fonts and control builders. Everything on screen is built in code from these.

const BG := Color("0b1520")
const BG2 := Color("10202a")
const PANEL := Color("142a33")
const PANEL2 := Color("1b3641")
const LINE := Color("2a4650")
const INK := Color("e9e4d8")
const INK2 := Color("b9c4c0")
const MUTE := Color("7f908c")
const AMBER := Color("e8b877")
const AMBER2 := Color("f2c77f")
const TEAL := Color("7fb7ad")
const RED := Color("c8665a")
const PAPER := Color("e3d6ba")
const PAPER2 := Color("f4ead2")
const PAPER_INK := Color("2a241b")
const PAPER_LINE := Color("c8b58c")
const DARK_INK := Color("1b140a")

static var _fonts := {}


# ---------- fonts ----------

## kind: sans, sans_bold, serif, serif_italic, serif_bold, mono, mono_bold.
## Every font falls back to the emoji subset, then to DejaVu Sans for symbols (tick, arrows, braille).
static func font(kind: String = "sans") -> Font:
	if _fonts.has(kind):
		return _fonts[kind]
	var fv := FontVariation.new()
	match kind:
		"sans", "sans_bold":
			fv.base_font = ThemeDB.fallback_font
			if kind == "sans_bold":
				fv.variation_embolden = 0.55
		"serif": fv.base_font = load("res://assets/fonts/serif.ttf")
		"serif_italic": fv.base_font = load("res://assets/fonts/serif_italic.ttf")
		"serif_bold": fv.base_font = load("res://assets/fonts/serif_bold.ttf")
		"mono": fv.base_font = load("res://assets/fonts/mono.ttf")
		"mono_bold": fv.base_font = load("res://assets/fonts/mono_bold.ttf")
		_: fv.base_font = ThemeDB.fallback_font
	fv.fallbacks = [load("res://assets/fonts/emoji_subset.ttf"), load("res://assets/fonts/symbols.ttf")]
	_fonts[kind] = fv
	return fv


## A font size scaled by the player's text-size setting.
static func fs(n: float) -> int:
	return int(round(n * Game.text_scale()))


# ---------- styles ----------

static func flat(bg: Color, radius: float = 12.0, border: Color = Color(0, 0, 0, 0), border_w: float = 0.0, margin: float = 0.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(int(radius))
	sb.border_color = border
	sb.set_border_width_all(int(border_w))
	sb.set_content_margin_all(margin)
	sb.anti_aliasing = true
	return sb


# ---------- builders ----------

static func label(text: String, size: float = 16.0, color: Color = INK, kind: String = "sans", align: int = HORIZONTAL_ALIGNMENT_LEFT, wrap: bool = true) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font(kind))
	l.add_theme_font_size_override("font_size", fs(size))
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func eyebrow(text: String, color: Color = AMBER) -> Label:
	var l := label(text.to_upper(), 12.0, color, "mono_bold")
	l.add_theme_constant_override("line_spacing", 2)
	return l


static func panel(bg: Color = PANEL, radius: float = 14.0, border: Color = LINE, border_w: float = 1.0, margin: float = 14.0) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", flat(bg, radius, border, border_w, margin))
	return p


static func vbox(sep: int = 10) -> VBoxContainer:
	var b := VBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	return b


static func hbox(sep: int = 10) -> HBoxContainer:
	var b := HBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	return b


static func margin(child: Control, all: int = 16) -> MarginContainer:
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, all)
	m.add_child(child)
	return m


static func spacer(h: float = 0.0, expand: bool = false) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = h
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if expand:
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c


## Registers a control so the browser test bridge can find it by name.
static func qa(node: Control, id: String) -> Control:
	node.set_meta("qa", id)
	node.add_to_group("qa")
	return node


static func icon_texture(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null
