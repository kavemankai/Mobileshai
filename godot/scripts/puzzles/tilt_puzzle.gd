class_name TiltPuzzle
extends PuzzleBase
## Maze: tilt (swipe, arrow keys, buttons, or the phone) and the ball rolls until a wall. Stop it on the valve.

var board: TiltBoard
var _pad_buttons := {}


func build() -> void:
	var col := UI.vbox(8)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(col)
	col.add_child(UI.label(String(def["caption"]), 14, UI.INK2, "serif_italic"))
	board = TiltBoard.new(def["rows"])
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.note.connect(say)
	board.won.connect(func() -> void:
		sfx("solve")
		finish(1000 if Fx.motion() else 300))
	UI.qa(board, "tilt.board")
	col.add_child(board)
	var pad := UI.hbox(8)
	for d in ["L", "U", "D", "R"]:
		var b := FxButton.new({"U": "▲", "D": "▼", "L": "◀", "R": "▶"}[d])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void: board.tilt(d))
		UI.qa(b, "tilt." + d)
		_pad_buttons[d] = b
		pad.add_child(b)
	col.add_child(pad)
	var tbtn := FxButton.new("Use phone tilt", "ghost")
	tbtn.pressed.connect(func() -> void:
		board.tilt_on = not board.tilt_on
		tbtn.text = "Phone tilt on. Hold it at a comfortable angle." if board.tilt_on else "Use phone tilt")
	if OS.has_feature("mobile") or OS.has_feature("web"):
		col.add_child(tbtn)
	board.resized.connect(func() -> void:
		var need := 30.0 + board.size.x * float(board.R) / float(board.C) + 56.0 + (56.0 if col.get_child_count() > 3 else 0.0) + 28.0
		if absf(custom_minimum_size.y - need) > 1.0 and board.size.x > 0.0:
			custom_minimum_size.y = need)
	say("The ball only stops at a wall. It has to stop on the gold valve.")


func qa_state() -> Dictionary:
	return {"kind": "tilt", "ball": [board.ball_cell.x, board.ball_cell.y], "goal": [board.goal.x, board.goal.y],
		"solution": TiltModel.solve(def["rows"]), "moving": board.moving, "moves": board.moves,
		"center": QA.css(board, board.size / 2.0), "cell_css": board.cell, "done": is_done()}
