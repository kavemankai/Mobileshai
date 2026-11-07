class_name ArtView
extends TextureRect
## Scene art with rounded corners, a vignette, a slow camera drift and the remote-voice look.

var mat := ShaderMaterial.new()
var _drift: Tween


func _init(tex: Texture2D = null, radius: float = 14.0, focus_y: float = 0.35, vignette: float = 0.45) -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	mat.shader = load("res://shaders/scene_art.gdshader")
	mat.set_shader_parameter("radius", radius)
	mat.set_shader_parameter("focus_y", focus_y)
	mat.set_shader_parameter("vignette", vignette)
	material = mat
	resized.connect(func() -> void: mat.set_shader_parameter("rect_size", size))
	set_art(tex)


func set_art(tex: Texture2D) -> void:
	texture = tex
	if tex:
		mat.set_shader_parameter("tex_aspect", float(tex.get_width()) / float(tex.get_height()))


func set_remote(amount: float, animate: bool = true) -> void:
	if animate and Fx.motion():
		var from: float = mat.get_shader_parameter("remote_amount")
		create_tween().tween_method(func(v: float) -> void: mat.set_shader_parameter("remote_amount", v), from, amount, 0.35)
	else:
		mat.set_shader_parameter("remote_amount", amount)


func set_dim(amount: float) -> void:
	mat.set_shader_parameter("dim", amount)


## A slow zoom and sideways drift, forever. Does nothing when motion is reduced.
func drift(zoom_from: float = 1.03, zoom_to: float = 1.1, seconds: float = 22.0) -> void:
	if not Fx.motion():
		return
	if _drift:
		_drift.kill()
	_drift = create_tween().set_loops()
	_drift.tween_method(_set_drift, 0.0, 1.0, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_drift.tween_method(_set_drift, 1.0, 0.0, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_drift_range = Vector2(zoom_from, zoom_to)
	_set_drift(0.0)


var _drift_range := Vector2(1.03, 1.1)


func _set_drift(t: float) -> void:
	mat.set_shader_parameter("zoom", lerpf(_drift_range.x, _drift_range.y, t))
	mat.set_shader_parameter("pan", Vector2(lerpf(-0.012, 0.012, t), lerpf(0.006, -0.006, t)))
