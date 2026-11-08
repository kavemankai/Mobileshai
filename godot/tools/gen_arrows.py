#!/usr/bin/env python3
"""Generates Arrows boards (Arrows - Puzzle Escape style): always clearable, graded by the blocking chain.

Rules: arrows are paths of grid squares with a head at the last square, pointing away from the square before
it. Tap an arrow and it slides out along the straight line ahead of its head. It can go only if no other arrow
sits anywhere on that line. Clear every arrow.

A board is clearable exactly when "A waits for B" (B sits on A's line) has no cycle. The grade is the longest
such chain: how many arrows deep the order goes.

  python3 godot/tools/gen_arrows.py --w 6 --h 6 --seed 1
"""
import argparse
import json
import random
import sys

DIRS = [(-1, 0), (1, 0), (0, -1), (0, 1)]


def ray(w, h, head, d):
    r, c = head
    out = []
    while True:
        r += d[0]
        c += d[1]
        if not (0 <= r < h and 0 <= c < w):
            return out
        out.append((r, c))


def head_dir(path):
    (r1, c1), (r2, c2) = path[-2], path[-1]
    return (r2 - r1, c2 - c1)


def deps(w, h, arrows):
    owner = {}
    for i, a in enumerate(arrows):
        for cell in a:
            owner[cell] = i
    out = []
    for i, a in enumerate(arrows):
        out.append({owner[x] for x in ray(w, h, a[-1], head_dir(a)) if x in owner and owner[x] != i})
    return out


def chain_depth(dep):
    n = len(dep)
    memo = {}
    state = {}

    def depth(i):
        if state.get(i) == 1:
            raise ValueError("cycle")
        if i in memo:
            return memo[i]
        state[i] = 1
        d = 1 + max((depth(j) for j in dep[i]), default=0)
        state[i] = 2
        memo[i] = d
        return d

    try:
        return max(depth(i) for i in range(n))
    except ValueError:
        return None


def generate(w, h, rng, fill=0.8, max_len=5, tries=4000):
    best = None
    for _ in range(tries):
        used = set()
        arrows = []
        cells = [(r, c) for r in range(h) for c in range(w)]
        rng.shuffle(cells)
        for start in cells:
            if start in used:
                continue
            path = [start]
            length = rng.randint(2, max_len)
            while len(path) < length:
                r, c = path[-1]
                opts = [(r + dr, c + dc) for dr, dc in DIRS if 0 <= r + dr < h and 0 <= c + dc < w
                        and (r + dr, c + dc) not in used and (r + dr, c + dc) not in path]
                if not opts:
                    break
                path.append(rng.choice(opts))
            if len(path) < 2:
                continue
            trial = arrows + [path]
            if chain_depth(deps(w, h, trial)) is None:
                path = path[::-1]          # try it pointing the other way
                trial = arrows + [path]
                if chain_depth(deps(w, h, trial)) is None:
                    continue
            arrows = trial
            used |= set(path)
        if len(used) < fill * w * h:
            continue
        depth = chain_depth(deps(w, h, arrows))
        b = {"w": w, "h": h, "arrows": [[list(x) for x in a] for a in arrows], "depth": depth, "count": len(arrows)}
        if best is None or b["depth"] > best["depth"]:
            best = b
        if best["depth"] >= (w + h) // 2 + 1:
            break
    return best


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--w", type=int, default=6)
    ap.add_argument("--h", type=int, default=6)
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--tries", type=int, default=600)
    a = ap.parse_args()
    b = generate(a.w, a.h, random.Random(a.seed), tries=a.tries)
    if not b:
        sys.exit("no board")
    print(json.dumps(b))
