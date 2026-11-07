class_name Puzzles
extends RefCounted
## Which view plays which kind of puzzle.

const LABEL := {
	"zip": "Path", "hidden": "Search", "panels": "Frames", "match3": "Signal recovery", "timeline": "Timeline",
	"logic": "Deduction", "cryptex": "Cryptex", "goods": "Sort", "water": "Pump tanks", "blockfit": "Reassemble",
	"tilt": "Maze", "box": "Mechanism", "room": "Explore",
}

## Filled in as each puzzle is built. Anything missing falls back to the placeholder.
const SCRIPTS := {}


static func make(kind: String) -> PuzzleBase:
	if SCRIPTS.has(kind):
		return SCRIPTS[kind].new()
	return PlaceholderPuzzle.new()
