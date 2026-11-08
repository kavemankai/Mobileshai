class_name NameScreen
extends Screen
## "Your name badge". The player's name is spoken back to them in the story.

var _input: LineEdit
var _split := BoxContainer.new()
var _art: ArtView


func _ready() -> void:
	Sound.scene("reception", 0)
	var pad := MarginContainer.new()
	pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 16)
	content.add_child(pad)
	_split.add_theme_constant_override("separation", 18)
	pad.add_child(_split)

	_art = ArtView.new(Assets.scene("reception"), 16.0, 0.4, 0.5)
	_art.custom_minimum_size = Vector2(0, 260)
	_art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_art.drift()
	_split.add_child(_art)

	var card := UI.vbox(12)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.alignment = BoxContainer.ALIGNMENT_END
	card.add_child(UI.eyebrow("Mariner Motel · Night staff"))
	card.add_child(UI.label("Your name badge", 32, UI.INK, "serif", HORIZONTAL_ALIGNMENT_LEFT, false))
	card.add_child(UI.label("Nina trained you this week. She asked you to come in early tonight. You're running late.", 17, UI.INK2))
	_input = LineEdit.new()
	_input.placeholder_text = Game.DEFAULT_NAME
	_input.max_length = 20
	_input.custom_minimum_size.y = 58
	_input.text = String(Game.save.get("name", ""))
	_input.add_theme_font_override("font", UI.font("serif"))
	_input.add_theme_font_size_override("font_size", UI.fs(24))
	_input.add_theme_stylebox_override("normal", UI.flat(Color("0e1c24"), 12, UI.AMBER, 1, 14))
	_input.add_theme_stylebox_override("focus", UI.flat(Color("0e1c24"), 12, UI.AMBER2, 2, 14))
	_input.add_theme_color_override("font_color", UI.INK)
	_input.add_theme_color_override("caret_color", UI.AMBER)
	_input.add_theme_color_override("font_placeholder_color", UI.MUTE)
	_input.text_submitted.connect(func(_t: String) -> void: _go())
	UI.qa(_input, "name.input")
	card.add_child(_input)
	var go := FxButton.new("Start the shift", "primary")
	go.pressed.connect(_go)
	UI.qa(go, "name.start")
	card.add_child(go)
	_split.add_child(card)
	for i in card.get_child_count():
		Fx.fade_in(card.get_child(i), 0.5, 0.15 + i * 0.07)
	layout()


func layout() -> void:
	if _split:
		_split.vertical = not landscape()


func _go() -> void:
	var n := _input.text.strip_edges().substr(0, 20)
	Game.save["name"] = n if n != "" else Game.DEFAULT_NAME
	Game.save["phase"] = "chapter"
	Sound.sfx("tap")
	Game.write_save()
	app.render()
