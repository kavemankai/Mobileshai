class_name PuzzleBase
extends Control
## Base class for every puzzle view. A puzzle builds its own UI in build(), says what is going on through
## say(), and calls finish() exactly once when it is solved. `hold_ms` keeps the solved board on screen
## before the evidence card covers it.

signal solved(hold_ms: int)
signal status(text: String)

var def: Dictionary = {}
var seed_value := 1
## Earned clues so far: [{title, text}]. A puzzle that needs a deduction can show them.
var clues: Array = []
var rng := RandomNumberGenerator.new()
var _done := false
## Set by the puzzle screen: in landscape there is no spare height to ask the page for.
var landscape := false
var _asked := 0.0


func setup(def_: Dictionary, seed_: int, clues_: Array) -> void:
	def = def_
	seed_value = seed_
	clues = clues_
	rng.seed = seed_
	build()


## Override: create the nodes. The view fills its parent.
func build() -> void:
	pass


## Override: what a test or the debug tools may read about the current state.
func qa_state() -> Dictionary:
	return {}


func say(text: String) -> void:
	status.emit(text)


func finish(hold_ms: int = 900) -> void:
	if _done:
		return
	_done = true
	solved.emit(hold_ms)


## A board that needs more height than the window gives asks for it; the page then scrolls.
func ask_height(h: float) -> void:
	_asked = h
	var v := 0.0 if landscape else h
	if absf(custom_minimum_size.y - v) > 0.5:
		custom_minimum_size.y = v


func set_landscape(on: bool) -> void:
	landscape = on
	ask_height(_asked)


func is_done() -> bool:
	return _done


func sfx(sfx_name: String, jitter: float = 0.0) -> void:
	Sound.sfx(sfx_name, jitter)


func haptic(ms: int = 12) -> void:
	Fx.haptic(ms)


## A stable id for the test bridge.
func qa(node: Control, id: String) -> Control:
	return UI.qa(node, id)
