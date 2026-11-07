class_name TitleScreen
extends Screen
## The title: the motel in the rain, a slow camera drift, a neon flicker, and the way in.

var _art: ArtView
var _block := VBoxContainer.new()
var _logo: Label
var _taps := 0


func _ready() -> void:
	Sound.title()
	_art = ArtView.new(Assets.scene("title"), 0.0, 0.5, 0.55)
	_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_art)
	move_child(_art, 0)
	_art.drift(1.02, 1.09, 26.0)
	_flicker()

	var rain := ColorRect.new()
	rain.set_anchors_preset(Control.PRESET_FULL_RECT)
	rain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rm := ShaderMaterial.new()
	rm.shader = load("res://shaders/rain.gdshader")
	rm.set_shader_parameter("intensity", 0.26)
	rain.material = rm
	add_child(rain)
	move_child(rain, 1)

	# darken toward the bottom so the type reads
	var shade := TextureRect.new()
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(UI.BG, 0.0), Color(UI.BG, 0.0), Color(UI.BG, 0.88), Color(UI.BG, 1.0)])
	grad.offsets = PackedFloat32Array([0.0, 0.34, 0.74, 1.0])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	shade.texture = gt
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	move_child(shade, 2)

	_block.add_theme_constant_override("separation", 10)
	content.add_child(_block)
	var eyebrow := UI.eyebrow("A Mariner Motel mystery")
	_block.add_child(eyebrow)
	_logo = UI.label("THE LAST\nCHECK-IN", 60, UI.PAPER, "serif", HORIZONTAL_ALIGNMENT_LEFT, false)
	_logo.add_theme_constant_override("line_spacing", -6)
	_logo.mouse_filter = Control.MOUSE_FILTER_STOP
	_logo.gui_input.connect(_logo_input)
	UI.qa(_logo, "title.logo")
	_block.add_child(_logo)
	_block.add_child(UI.label("Nina never checked out. Someone wants the evidence buried.", 18, UI.INK2, "serif_italic"))
	_block.add_child(UI.spacer(10))

	var saved := Game.read_save_file()
	var resumable: bool = not saved.is_empty() and not saved["finished"] and saved["phase"] != "name"
	if resumable:
		var chapter := int(Game.level(mini(int(saved["level"]), Game.levels.size() - 1))["ch"]) + 1
		var cont := FxButton.new("Continue · Chapter %d" % chapter, "primary")
		cont.pressed.connect(func() -> void: app.continue_saved())
		UI.qa(cont, "title.continue")
		_block.add_child(cont)
		var fresh := FxButton.new("New case")
		fresh.pressed.connect(func() -> void:
			app.confirm("Start a new case? Your current progress will be lost.", "Start again", func() -> void: app.begin_new()))
		UI.qa(fresh, "title.new")
		_block.add_child(fresh)
	else:
		var begin := FxButton.new("Begin your shift", "primary")
		begin.pressed.connect(func() -> void: app.begin_new())
		UI.qa(begin, "title.begin")
		_block.add_child(begin)
	var row := UI.hbox(10)
	for spec in [["Settings", "title.settings"], ["Credits", "title.credits"]]:
		var b := FxButton.new(spec[0], "ghost")
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UI.qa(b, spec[1])
		row.add_child(b)
	row.get_child(0).pressed.connect(func() -> void: app.open_settings())
	row.get_child(1).pressed.connect(func() -> void: app.open_credits())
	_block.add_child(row)
	_block.add_child(UI.label("28 puzzles · 4 chapters · no timers · no ads · plays offline", 12, UI.MUTE, "sans", HORIZONTAL_ALIGNMENT_CENTER))

	if Fx.motion():
		for i in _block.get_child_count():
			Fx.fade_in(_block.get_child(i), 0.7, 0.25 + i * 0.09)
	layout()


var _settle_id := 0


func layout() -> void:
	if _block == null:
		return
	_settle_id += 1
	_settle(_settle_id)


## Wrapped labels only report their true height a couple of frames after the width changes,
## so place the block once they have.
func _settle(id: int) -> void:
	var margin := 24.0
	var w := minf(content.size.x - margin * 2.0, 480.0)
	_block.custom_minimum_size.x = w
	_block.size = Vector2(w, 0)
	for i in 3:
		await get_tree().process_frame
		if id != _settle_id or not is_inside_tree():
			return
		_block.size = Vector2(w, 0)
	var h := _block.get_combined_minimum_size().y
	if landscape():
		_block.position = Vector2(margin, maxf((content.size.y - h) / 2.0, margin))
	else:
		_block.position = Vector2(margin, maxf(content.size.y - h - 28.0, margin))


## The neon sign flickers now and then: a quick dip in brightness, never random enough to be annoying.
func _flicker() -> void:
	if not Fx.motion():
		return
	var tw := create_tween().set_loops()
	tw.tween_interval(3.2)
	tw.tween_callback(func() -> void: _art.set_dim(0.18))
	tw.tween_interval(0.06)
	tw.tween_callback(func() -> void: _art.set_dim(0.0))
	tw.tween_interval(0.09)
	tw.tween_callback(func() -> void: _art.set_dim(0.12))
	tw.tween_interval(0.05)
	tw.tween_callback(func() -> void: _art.set_dim(0.0))
	tw.tween_interval(5.5)


## Seven taps on the logo turn on the developer tools for this session.
func _logo_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		_taps += 1
		if _taps >= 7 and not Game.debug:
			Game.debug = true
			app.toast("Developer tools on for this session.")
