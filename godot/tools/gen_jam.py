#!/usr/bin/env python3
"""Generates Jam boards (Color Block Jam style), checked by a breadth-first solver and graded by minimum moves.

Rules: coloured blocks on a grid slide along rows and columns until something stops them. Gates sit in the
border; a block that slides into a gate of its own colour, at least as wide as the block, leaves the board.
Clear every block. A move is one slide of any length.

  python3 godot/tools/gen_jam.py --w 5 --h 6 --blocks 7 --min 7 --max 12 --seed 1
"""
import argparse
import json
import random
import sys
from collections import deque

SHAPES = [[(0, 0)], [(0, 0), (0, 1)], [(0, 0), (1, 0)], [(0, 0), (0, 1), (1, 0), (1, 1)], [(0, 0), (1, 0), (1, 1)],
          [(0, 0), (0, 1), (0, 2)], [(0, 0), (1, 0), (2, 0)]]
COLORS = "RBYGPO"
DIRS = {"U": (-1, 0), "D": (1, 0), "L": (0, -1), "R": (0, 1)}


def cells(block, pos):
    return [(pos[0] + dr, pos[1] + dc) for dr, dc in block["shape"]]


def exits(w, h, gates, block, pos, d):
    """Does the block leave through a matching gate when pushed in direction d from pos?"""
    cs = cells(block, pos)
    dr, dc = DIRS[d]
    side = {"U": "N", "D": "S", "L": "W", "R": "E"}[d]
    if d in "UD":
        edge_row = min(r for r, c in cs) if d == "U" else max(r for r, c in cs)
        if (d == "U" and edge_row != 0) or (d == "D" and edge_row != h - 1):
            return False
        span = (min(c for r, c in cs), max(c for r, c in cs))
    else:
        edge_col = min(c for r, c in cs) if d == "L" else max(c for r, c in cs)
        if (d == "L" and edge_col != 0) or (d == "R" and edge_col != w - 1):
            return False
        span = (min(r for r, c in cs), max(r for r, c in cs))
    for g in gates:
        if g["side"] == side and g["color"] == block["color"] and g["at"] <= span[0] and span[1] < g["at"] + g["len"]:
            return True
    return False


def slides(w, h, gates, blocks, state, i):
    """Every move for block i: (dir, steps, exits?)."""
    occ = {}
    for j, pos in enumerate(state):
        if pos is not None and j != i:
            for x in cells(blocks[j], pos):
                occ[x] = j
    out = []
    for d, (dr, dc) in DIRS.items():
        pos = state[i]
        steps = 0
        while True:
            nxt = (pos[0] + dr, pos[1] + dc)
            cs = cells(blocks[i], nxt)
            if all(0 <= r < h and 0 <= c < w and (r, c) not in occ for r, c in cs):
                pos = nxt
                steps += 1
                continue
            break
        if exits(w, h, gates, blocks[i], pos, d):
            out.append((d, steps, True, pos))
        elif steps:
            out.append((d, steps, False, pos))
    return out


def solve(b, limit=100000):
    """A* on slides, with "blocks still on the board" as the estimate (each needs at least one move).
    Returns the shortest list of moves, or None."""
    import heapq
    w, h, gates, blocks = b["w"], b["h"], b["gates"], b["blocks"]
    start = tuple(tuple(x["pos"]) for x in blocks)
    left = lambda st: sum(1 for p in st if p is not None)
    prev = {start: None}
    g = {start: 0}
    heap = [(left(start), 0, 0, start)]
    tick = 0
    while heap and len(prev) < limit:
        f, cost, _t, st = heapq.heappop(heap)
        if cost > g.get(st, 1e9):
            continue
        if left(st) == 0:
            path = []
            k = st
            while prev[k] is not None:
                k, mv = prev[k]
                path.append(mv)
            return path[::-1]
        for i, pos in enumerate(st):
            if pos is None:
                continue
            for d, steps, out, end in slides(w, h, gates, blocks, st, i):
                ns = list(st)
                ns[i] = None if out else end
                ns = tuple(ns)
                nc = cost + 1
                if nc < g.get(ns, 1e9):
                    g[ns] = nc
                    prev[ns] = (st, [i, d, steps, out])
                    tick += 1
                    heapq.heappush(heap, (nc + left(ns), nc, tick, ns))
    return None


def make(w, h, n_blocks, n_colors, rng):
    occ = set()
    blocks = []
    cols = COLORS[:n_colors]
    for _ in range(n_blocks * 30):
        if len(blocks) >= n_blocks:
            break
        shape = rng.choice(SHAPES)
        r = rng.randrange(h)
        c = rng.randrange(w)
        cs = [(r + dr, c + dc) for dr, dc in shape]
        if all(0 <= rr < h and 0 <= cc < w and (rr, cc) not in occ for rr, cc in cs):
            occ |= set(cs)
            blocks.append({"color": cols[len(blocks) % n_colors], "shape": [list(x) for x in shape], "pos": [r, c]})
    if len(blocks) < n_blocks:
        return None
    gates = []
    sides = ["N", "S", "W", "E"]
    # every colour gets one gate on a top/bottom side and one on a left/right side, without overlaps
    taken = {"N": set(), "S": set(), "W": set(), "E": set()}
    for k, col in enumerate(cols):
        for pair in (("N", "S"), ("W", "E")):
            for _ in range(20):
                side = rng.choice(pair)
                length = rng.choice([2, 3, 3])
                span = w if side in "NS" else h
                at = rng.randrange(0, span - length + 1)
                cells_ = set(range(at, at + length))
                if not cells_ & taken[side]:
                    taken[side] |= cells_
                    gates.append({"side": side, "at": at, "len": length, "color": col})
                    break
    return {"w": w, "h": h, "blocks": blocks, "gates": gates}


def generate(w, h, n_blocks, n_colors, lo, hi, rng, tries=3000):
    for _ in range(tries):
        b = make(w, h, n_blocks, n_colors, rng)
        if not b:
            continue
        sol = solve(b)
        if sol and lo <= len(sol) <= hi:
            b["par"] = len(sol)
            return b
    return None


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--w", type=int, default=5)
    ap.add_argument("--h", type=int, default=6)
    ap.add_argument("--blocks", type=int, default=7)
    ap.add_argument("--colors", type=int, default=4)
    ap.add_argument("--min", type=int, default=7)
    ap.add_argument("--max", type=int, default=12)
    ap.add_argument("--seed", type=int, default=1)
    a = ap.parse_args()
    b = generate(a.w, a.h, a.blocks, a.colors, a.min, a.max, random.Random(a.seed))
    if not b:
        sys.exit("no board")
    print(json.dumps(b))
