class_name CryptexPuzzle
extends PuzzleBase
## Cryptex: letter rings that turn like drums. Drag a ring, flick it, or tap the faded letters; it snaps with a click.

var pos: Array = []
var rings: Array = []
var _locked := false


func build() -> void:
	pos = CryptexModel.start_positions(def, rng)
	var col := UI.vbox(10)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(col)
	col.add_child(UI.label(String(def["clue"]), 15, UI.INK2, "serif_italic"))
	var mid := Control.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(mid)
	var row := UI.hbox(5)
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_child(row)
	for i in def["rings"].size():
		var r := DrumWheel.new(i, String(def["rings"][i]), int(pos[i]))
		r.settled.connect(ring_settled)
		r.locked = func() -> bool: return is_done()
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.size_flags_vertical = Control.SIZE_EXPAND_FILL
		r.custom_minimum_size = Vector2(34, 150)
		UI.qa(r, "cx.ring.%d" % i)
		rings.append(r)
		row.add_child(r)
	col.add_child(EvidencePeek.new(clues))
	say("Swipe a ring or tap the faded letters. The cylinder opens when the word is right.")


func ring_settled(i: int, p: int) -> void:
	pos[i] = p
	if _locked or CryptexModel.word(def, pos) != String(def["word"]):
		return
	_locked = true
	sfx("latch")
	haptic(30)
	for k in rings.size():
		rings[k].celebrate(0.07 * k)
	finish(1400 if Fx.motion() else 300)


func board_hint(level: int) -> Dictionary:
	var word := String(def["word"])
	for i in pos.size():
		var ring := String(def["rings"][i])
		if ring[int(pos[i])] != word[i]:
			var r: DrumWheel = rings[i]
			if level < 2:
				return {"rects": [view_rect(r, Rect2(Vector2.ZERO, r.size))], "text": "This ring is wrong. Read Nina's note again."}
			return {"rects": [view_rect(r, Rect2(Vector2.ZERO, r.size))], "text": "Ring %d should show %s." % [i + 1, word[i]]}
	return {}

func qa_state() -> Dictionary:
	var centers := []
	for r in rings:
		centers.append(QA.css(r, r.size / 2.0))
	return {"kind": "cryptex", "pos": pos.duplicate(), "word": CryptexModel.word(def, pos), "target": def["word"],
		"rings": def["rings"], "centers": centers, "unit_css": rings[0].unit, "done": is_done()}
