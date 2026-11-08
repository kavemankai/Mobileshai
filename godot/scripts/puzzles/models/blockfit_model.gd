class_name BlockFitModel
extends RefCounted
## Cells are Vector2i(row, col). A piece is normalised: top-left at 0,0, sorted by row then column.
## The first cell is the anchor the player places.


static func normalize(cells: Array) -> Array:
	var mr := 9999
	var mc := 9999
	for c in cells:
		mr = mini(mr, c.x)
		mc = mini(mc, c.y)
	var out := []
	for c in cells:
		out.append(Vector2i(c.x - mr, c.y - mc))
	out.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x or (a.x == b.x and a.y < b.y))
	return out


static func rotate(cells: Array) -> Array:
	var out := []
	for c in cells:
		out.append(Vector2i(c.y, -c.x))
	return normalize(out)


## {board: Array of Array of bool, pieces: [{id, cells}]} from the solution picture.
static func derive(def: Dictionary) -> Dictionary:
	var board := []
	var map := {}
	var order := []
	var rows: Array = def["solution"]
	for r in rows.size():
		var line := []
		var s: String = rows[r]
		for c in s.length():
			var ch := s[c]
			line.append(ch != ".")
			if ch != ".":
				if not map.has(ch):
					map[ch] = []
					order.append(ch)
				map[ch].append(Vector2i(r, c))
		board.append(line)
	var pieces := []
	for id in order:
		pieces.append({"id": id, "cells": normalize(map[id])})
	return {"board": board, "pieces": pieces}


static func same_shape(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if a[i] != b[i]:
			return false
	return true


## Does `shape` placed with its anchor at (r, c) fit on the board, avoiding `occupied` (Dictionary cell -> piece)?
static func fits(board: Array, occupied: Dictionary, shape: Array, r: int, c: int) -> bool:
	var origin := Vector2i(r, c) - Vector2i(shape[0])
	for cell in shape:
		var p: Vector2i = origin + Vector2i(cell)
		if p.x < 0 or p.y < 0 or p.x >= board.size() or p.y >= board[0].size():
			return false
		if not board[p.x][p.y] or occupied.has(p):
			return false
	return true
