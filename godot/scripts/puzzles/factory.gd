class_name Puzzles
extends RefCounted
## Which view plays which kind of puzzle.

const LABEL := {
	"zip": "Path", "panels": "Frames", "match3": "Signal recovery", "logic": "Deduction", "cryptex": "Cryptex", "goods": "Sort", "water": "Pump tanks", "blockfit": "Reassemble",
	"tilt": "Maze", "box": "Mechanism", "stakeout": "Stakeout", "screws": "Screws", "arrows": "Arrows", "jam": "Jam",
}

## Add a case here as each puzzle is built. Anything missing falls back to the placeholder.
static func make(kind: String) -> PuzzleBase:
	match kind:
		"zip": return ZipPuzzle.new()
		"cryptex": return CryptexPuzzle.new()
		"logic": return LogicPuzzle.new()
		"goods": return GoodsPuzzle.new()
		"water": return WaterPuzzle.new()
		"match3": return Match3Puzzle.new()
		"tilt": return TiltPuzzle.new()
		"blockfit": return BlockFitPuzzle.new()
		"panels": return PanelsPuzzle.new()
		"box": return BoxPuzzle.new()
		"stakeout": return StakeoutPuzzle.new()
		"screws": return ScrewsPuzzle.new()
		"arrows": return ArrowsPuzzle.new()
		"jam": return JamPuzzle.new()
	return PlaceholderPuzzle.new()
