class_name Puzzles
extends RefCounted
## Which view plays which kind of puzzle.

const LABEL := {
	"zip": "Path", "hidden": "Search", "panels": "Frames", "match3": "Signal recovery", "timeline": "Timeline",
	"logic": "Deduction", "cryptex": "Cryptex", "goods": "Sort", "water": "Pump tanks", "blockfit": "Reassemble",
	"tilt": "Maze", "box": "Mechanism", "room": "Explore", "stakeout": "Stakeout", "screws": "Screws", "arrows": "Arrows",
}

## Add a case here as each puzzle is built. Anything missing falls back to the placeholder.
static func make(kind: String) -> PuzzleBase:
	match kind:
		"zip": return ZipPuzzle.new()
		"timeline": return TimelinePuzzle.new()
		"cryptex": return CryptexPuzzle.new()
		"logic": return LogicPuzzle.new()
		"goods": return GoodsPuzzle.new()
		"water": return WaterPuzzle.new()
		"match3": return Match3Puzzle.new()
		"tilt": return TiltPuzzle.new()
		"blockfit": return BlockFitPuzzle.new()
		"panels": return PanelsPuzzle.new()
		"hidden": return HiddenPuzzle.new()
		"room": return RoomPuzzle.new()
		"box": return BoxPuzzle.new()
		"stakeout": return StakeoutPuzzle.new()
		"screws": return ScrewsPuzzle.new()
		"arrows": return ArrowsPuzzle.new()
	return PlaceholderPuzzle.new()
