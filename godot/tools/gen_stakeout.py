#!/usr/bin/env python3
"""Generates Stakeout (Queens-style) boards with exactly one solution, graded by the reasoning they need.

Rules: an N x N grid split into N zones. Place N watchers, one per row, column and zone, none touching
(diagonals included).

Grading, by the hardest step a human-style solver needs:
  1  singles: a row, column or zone with one square left; every placement crosses out its row, column, zone
     and neighbours
  2  confinement: a zone whose squares all sit in one row (or column) clears that row for everyone else, and
     the reverse; also k zones confined to k rows
  3  trial: a square that, if used, would leave some row, column or zone empty
A board that needs guessing beyond level 3 is rejected.

  python3 godot/tools/gen_stakeout.py --size 6 --level 2 --seed 7      prints a board as JSON
"""
import argparse
import itertools
import json
import random
import sys


def neighbours(n, r, c):
    for dr in (-1, 0, 1):
        for dc in (-1, 0, 1):
            if (dr or dc) and 0 <= r + dr < n and 0 <= c + dc < n:
                yield r + dr, c + dc


def random_solution(n, rng):
    """One watcher per row and column, none touching."""
    for _ in range(10000):
        cols = list(range(n))
        rng.shuffle(cols)
        if all(abs(cols[i] - cols[i + 1]) > 1 for i in range(n - 1)):
            return cols
    raise RuntimeError("no placement")


def grow_zones(n, sol, rng):
    """Grow every zone outward from its watcher, smallest zone first, so the zones come out balanced."""
    zone = [[-1] * n for _ in range(n)]
    size = [1] * n
    for r, c in enumerate(sol):
        zone[r][c] = r
    left = n * n - n
    while left:
        order = sorted(range(n), key=lambda z: (size[z] + rng.random() * 2.5))
        for z in order:
            edge = [(rr, cc) for r in range(n) for c in range(n) if zone[r][c] == z
                    for rr, cc in ((r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1))
                    if 0 <= rr < n and 0 <= cc < n and zone[rr][cc] < 0]
            if edge:
                rr, cc = rng.choice(edge)
                zone[rr][cc] = z
                size[z] += 1
                left -= 1
                break
        else:
            return zone
    return zone


def connected(n, zone, z):
    cells = [(r, c) for r in range(n) for c in range(n) if zone[r][c] == z]
    if not cells:
        return False
    seen = {cells[0]}
    stack = [cells[0]]
    while stack:
        r, c = stack.pop()
        for rr, cc in ((r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1)):
            if 0 <= rr < n and 0 <= cc < n and zone[rr][cc] == z and (rr, cc) not in seen:
                seen.add((rr, cc))
                stack.append((rr, cc))
    return len(seen) == len(cells)


def solutions(n, zone, limit=2):
    out = []
    cols, zones, placed = set(), set(), []

    def rec(r):
        if len(out) >= limit:
            return
        if r == n:
            out.append(list(placed))
            return
        for c in range(n):
            if c in cols or zone[r][c] in zones or (placed and abs(placed[-1] - c) <= 1):
                continue
            cols.add(c); zones.add(zone[r][c]); placed.append(c)
            rec(r + 1)
            cols.discard(c); zones.discard(zone[r][c]); placed.pop()

    rec(0)
    return out


def make_unique(n, zone, sol, rng, rounds=300):
    """Nudge zone borders until the intended placement is the only one."""
    for _ in range(rounds):
        sols = solutions(n, zone, 2)
        alts = [s for s in sols if s != sol]
        if not alts:
            return zone
        alt = alts[0]
        # a square the other placement uses but ours does not: hand it to a neighbouring zone
        cells = [(r, alt[r]) for r in range(n) if alt[r] != sol[r]]
        rng.shuffle(cells)
        moved = False
        for r, c in cells:
            z = zone[r][c]
            if sol[r] == c:
                continue
            opts = list({zone[rr][cc] for rr, cc in ((r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1))
                         if 0 <= rr < n and 0 <= cc < n and zone[rr][cc] != z})
            rng.shuffle(opts)
            for nz in opts:
                zone[r][c] = nz
                if connected(n, zone, z) and sum(row.count(z) for row in zone) >= 2:
                    moved = True
                    break
                zone[r][c] = z
            if moved:
                break
        if not moved:
            return None
    return None


def count_solutions(n, zone, limit=2):
    found = 0
    cols, zones = set(), set()
    placed = []

    def ok(r, c):
        if c in cols or zone[r][c] in zones:
            return False
        if placed and abs(placed[-1] - c) <= 1:
            return False
        return True

    def rec(r):
        nonlocal found
        if found >= limit:
            return
        if r == n:
            found += 1
            return
        for c in range(n):
            if ok(r, c):
                cols.add(c); zones.add(zone[r][c]); placed.append(c)
                rec(r + 1)
                cols.discard(c); zones.discard(zone[r][c]); placed.pop()

    rec(0)
    return found


class Logic:
    """A human-style solver. Returns the highest level of reasoning it needed, or None if it gets stuck."""

    def __init__(self, n, zone):
        self.n = n
        self.zone = zone
        self.cand = {(r, c) for r in range(n) for c in range(n)}
        self.placed = set()
        self.level = 0
        self.steps = 0

    def groups(self):
        n = self.n
        for r in range(n):
            yield [(r, c) for c in range(n)]
        for c in range(n):
            yield [(r, c) for r in range(n)]
        for z in range(n):
            yield [(r, c) for r in range(n) for c in range(n) if self.zone[r][c] == z]

    def place(self, cell):
        r, c = cell
        self.placed.add(cell)
        kill = {(r, x) for x in range(self.n)} | {(x, c) for x in range(self.n)}
        kill |= {(rr, cc) for rr in range(self.n) for cc in range(self.n) if self.zone[rr][cc] == self.zone[r][c]}
        kill |= set(neighbours(self.n, r, c))
        self.cand -= kill
        self.steps += 1

    def broken(self):
        for g in self.groups():
            if not any(x in self.placed for x in g) and not any(x in self.cand for x in g):
                return True
        return False

    def singles(self):
        for g in self.groups():
            if any(x in self.placed for x in g):
                continue
            live = [x for x in g if x in self.cand]
            if len(live) == 1:
                self.place(live[0])
                return True
        return False

    def confinement(self):
        n = self.n
        open_zones = [z for z in range(n) if not any(self.zone[r][c] == z for r, c in self.placed)]
        cells_of = {z: [x for x in self.cand if self.zone[x[0]][x[1]] == z] for z in open_zones}
        for axis in (0, 1):
            for k in (1, 2, 3):
                for combo in itertools.combinations(open_zones, k):
                    lines = {x[axis] for z in combo for x in cells_of[z]}
                    if len(lines) == k:
                        drop = {x for x in self.cand if x[axis] in lines and self.zone[x[0]][x[1]] not in combo}
                        if drop:
                            self.cand -= drop
                            self.steps += 1
                            return True
                # the reverse: k lines whose squares all fall in k zones
                open_lines = [l for l in range(n) if not any(x[axis] == l for x in self.placed)]
                for combo in itertools.combinations(open_lines, k):
                    zs = {self.zone[x[0]][x[1]] for x in self.cand if x[axis] in combo}
                    if len(zs) == k:
                        drop = {x for x in self.cand if self.zone[x[0]][x[1]] in zs and x[axis] not in combo}
                        if drop:
                            self.cand -= drop
                            self.steps += 1
                            return True
        return False

    def trial(self):
        for cell in sorted(self.cand):
            probe = Logic(self.n, self.zone)
            probe.cand = set(self.cand)
            probe.placed = set(self.placed)
            probe.place(cell)
            while probe.singles():
                pass
            if probe.broken():
                self.cand.discard(cell)
                self.steps += 1
                return True
        return False

    def run(self):
        while len(self.placed) < self.n:
            if self.broken():
                return None
            if self.singles():
                self.level = max(self.level, 1)
                continue
            if self.confinement():
                self.level = max(self.level, 2)
                continue
            if self.trial():
                self.level = max(self.level, 3)
                continue
            return None
        return self.level


def generate(n, want_level, rng, tries=4000, pick=6):
    """The hardest of the first `pick` boards that need exactly `want_level`, judged by step count."""
    best = None
    seen = 0
    for _ in range(tries):
        sol = random_solution(n, rng)
        zone = grow_zones(n, sol, rng)
        zone = make_unique(n, zone, sol, rng)
        if zone is None or count_solutions(n, zone) != 1:
            continue
        lg = Logic(n, zone)
        lv = lg.run()
        if lv == want_level and min(sum(row.count(z) for row in zone) for z in range(n)) >= 2:
            letters = "ABCDEFGHIJ"
            b = {"size": n, "regions": ["".join(letters[zone[r][c]] for c in range(n)) for r in range(n)],
                 "solution": sol, "grade": lv, "steps": lg.steps}
            if best is None or b["steps"] > best["steps"]:
                best = b
            seen += 1
            if seen >= pick:
                break
    return best


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--size", type=int, default=6)
    ap.add_argument("--level", type=int, default=2)
    ap.add_argument("--seed", type=int, default=1)
    a = ap.parse_args()
    b = generate(a.size, a.level, random.Random(a.seed))
    if not b:
        sys.exit("no board found; try another seed")
    print(json.dumps(b))
