class_name Fx
extends RefCounted
## Small reusable animations. Every one is skipped, or made instant, when the player asked for reduced motion.

static func motion() -> bool:
	return not Game.reduced_motion()


static func haptic(ms: int = 12) -> void:
	if Game.settings["haptics"]:
		Input.vibrate_handheld(ms)


static func center_pivot(c: Control) -> void:
	c.pivot_offset = c.size / 2.0


## A quick scale pop, for a thing that was just touched or earned.
static func pop(c: Control, amount: float = 1.14, dur: float = 0.2) -> void:
	if not motion():
		return
	center_pivot(c)
	var tw := c.create_tween()
	tw.tween_property(c, "scale", Vector2.ONE * amount, dur * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "scale", Vector2.ONE, dur * 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## A short shake, for a move that is refused.
static func shake(c: CanvasItem, amount: float = 7.0, dur: float = 0.32) -> void:
	if not motion():
		return
	var tw := c.create_tween()
	var base: Vector2 = c.position if c is Control else Vector2.ZERO
	var contained: bool = c is Control and c.get_parent() is Container
	for i in 5:
		var k := (1.0 - float(i) / 5.0) * amount * (1.0 if i % 2 == 0 else -1.0)
		if contained:
			tw.tween_property(c, "rotation", deg_to_rad(k * 0.35), dur / 6.0)
		else:
			tw.tween_property(c, "position", base + Vector2(k, 0), dur / 6.0)
	if contained:
		tw.tween_property(c, "rotation", 0.0, dur / 6.0)
	else:
		tw.tween_property(c, "position", base, dur / 6.0)


static func fade_in(c: CanvasItem, dur: float = 0.35, delay: float = 0.0) -> void:
	if not motion():
		return
	c.modulate.a = 0.0
	var tw := c.create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_property(c, "modulate:a", 1.0, dur).set_trans(Tween.TRANS_SINE)


## Rises into place from below while fading in. Only for a control whose parent is not a container.
static func rise_in(c: Control, dist: float = 24.0, dur: float = 0.5, delay: float = 0.0) -> void:
	if not motion():
		return
	var end := c.position
	c.position = end + Vector2(0, dist)
	c.modulate.a = 0.0
	var tw := c.create_tween().set_parallel(true)
	if delay > 0.0:
		tw.tween_interval(delay)
		tw.chain()
	tw.tween_property(c, "position", end, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "modulate:a", 1.0, dur * 0.8)


## A burst of small squares from a point, for a match, a lock or a find.
static func burst(parent: Node, pos: Vector2, color: Color = UI.AMBER, amount: int = 16, speed: float = 220.0, size: float = 4.0) -> void:
	if not motion():
		return
	var p := CPUParticles2D.new()
	p.position = pos
	p.one_shot = true
	p.amount = amount
	p.lifetime = 0.7
	p.explosiveness = 1.0
	p.spread = 180.0
	p.gravity = Vector2(0, 380)
	p.initial_velocity_min = speed * 0.45
	p.initial_velocity_max = speed
	p.scale_amount_min = size * 0.6
	p.scale_amount_max = size
	var g := Gradient.new()
	g.set_color(0, color)
	g.set_color(1, Color(color.r, color.g, color.b, 0.0))
	p.color_ramp = g
	p.z_index = 20
	parent.add_child(p)
	p.emitting = true
	p.get_tree().create_timer(1.0).timeout.connect(p.queue_free)


## An expanding ring where the player tapped, for a tap that found nothing.
static func ripple(parent: Control, local_pos: Vector2, color: Color = Color(1, 1, 1, 0.5), max_r: float = 34.0) -> void:
	if not motion():
		return
	var r := Ripple.new()
	r.position = local_pos
	r.color = color
	r.max_r = max_r
	parent.add_child(r)
	var tw := r.create_tween()
	tw.tween_property(r, "t", 1.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(r.queue_free)


## Counts a number up on a label.
static func count_up(l: Label, to: int, dur: float = 0.6) -> void:
	if not motion():
		l.text = str(to)
		return
	var tw := l.create_tween()
	tw.tween_method(func(v: float) -> void: l.text = str(int(v)), 0.0, float(to), dur)


class Ripple extends Control:
	var t := 0.0:
		set(v):
			t = v
			queue_redraw()
	var color := Color.WHITE
	var max_r := 34.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		z_index = 30

	func _draw() -> void:
		draw_arc(Vector2.ZERO, max_r * t, 0.0, TAU, 40, Color(color.r, color.g, color.b, color.a * (1.0 - t)), 2.5, true)
