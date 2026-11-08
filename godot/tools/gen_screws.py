#!/usr/bin/env python3
"""Generates Screws boards (Screwdom-style) that can always be cleared, graded by how easily careless play jams.

Rules: plates stacked bottom to top, each held by coloured screws. A screw can be taken only when no plate
above it (still on the board) covers its point. Two colour boxes are open at a time, each wanting 3 screws of
its colour; when one fills it leaves and the next in the queue opens. A screw with no open box of its colour
goes to a 5-slot tray; tray screws jump into a box of their colour when one opens. If the tray is full,
the move cannot be made. A plate falls when its last screw is out.

  python3 godot/tools/gen_screws.py --plates 4 --colors 3 --seed 3
"""
import argparse
import json
import random
import sys
sys.setrecursionlimit(10000)
from functools import lru_cache

COLORS = "RBYGPO"


def covered(plates, removed_plates, pi, pt):
    x, y = pt
    for j in range(pi + 1, len(plates)):
        if j in removed_plates:
            continue
        rx, ry, rw, rh = plates[j]["rect"]
        if rx <= x <= rx + rw and ry <= y <= ry + rh:
            return True
    return False


class Game:
    def __init__(self, b):
        self.b = b
        self.screws = [(pi, s[0], s[1], s[2]) for pi, p in enumerate(b["plates"]) for s in p["screws"]]
        self.plate_of = [s[0] for s in self.screws]
        self.count_per_plate = [len(p["screws"]) for p in b["plates"]]
        # bit masks: which screws hold each plate; which plates cover each screw
        self.plate_mask = [0] * len(b["plates"])
        for k, s in enumerate(self.screws):
            self.plate_mask[s[0]] |= 1 << k
        self.covers = []
        for k, (pi, x, y, c) in enumerate(self.screws):
            over = []
            for j in range(pi + 1, len(b["plates"])):
                rx, ry, rw, rh = b["plates"][j]["rect"]
                if rx <= x <= rx + rw and ry <= y <= ry + rh:
                    over.append(self.plate_mask[j])
            self.covers.append(over)

    def start(self):
        # state: removed screws (bitmask), next box index, open boxes ((colour, filled), ...), tray (sorted str)
        q = self.b["boxes"]
        opened = tuple((q[i], 0) for i in range(min(2, len(q))))
        return (0, len(opened), opened, "")

    def removed_plates(self, mask):
        rem = set()
        for pi, n in enumerate(self.count_per_plate):
            got = sum(1 for k, s in enumerate(self.screws) if s[0] == pi and mask >> k & 1)
            if got == n:
                rem.add(pi)
        return rem

    def free(self, mask):
        out = []
        for k in range(len(self.screws)):
            if mask >> k & 1:
                continue
            if all(mask & pm == pm for pm in self.covers[k]):
                out.append(k)
        return out

    def take(self, state, k):
        mask, nxt, opened, tray = state
        c = self.screws[k][3]
        opened = list(opened)
        q = self.b["boxes"]
        placed = False
        for i, (bc, f) in enumerate(opened):
            if bc == c and f < 3:
                opened[i] = (bc, f + 1)
                placed = True
                break
        if not placed:
            if len(tray) >= self.b.get("tray", 5):
                return None
            tray = "".join(sorted(tray + c))
        mask |= 1 << k
        # full boxes leave, new ones open and pull matching screws from the tray
        changed = True
        while changed:
            changed = False
            for i, (bc, f) in enumerate(opened):
                if f >= 3 and bc != "-":
                    if nxt < len(q):
                        opened[i] = (q[nxt], 0)
                        nxt += 1
                    else:
                        opened[i] = ("-", 3)
                    changed = True
            for i, (bc, f) in enumerate(opened):
                while bc != "-" and f < 3 and bc in tray:
                    tray = tray.replace(bc, "", 1)
                    f += 1
                    changed = True
                opened[i] = (bc, f)
        return (mask, nxt, tuple(opened), tray)

    def won(self, state):
        return state[0] == (1 << len(self.screws)) - 1


def solve(b):
    g = Game(b)
    seen = set()

    def rec(st):
        if g.won(st):
            return True
        if st in seen or len(seen) > 150000:
            return False
        seen.add(st)
        for k in g.free(st[0]):
            ns = g.take(st, k)
            if ns is not None and rec(ns):
                return True
        return False

    return rec(g.start())


def random_playout(b, rng):
    g = Game(b)
    st = g.start()
    while not g.won(st):
        opts = [k for k in g.free(st[0]) if g.take(st, k) is not None]
        if not opts:
            return False
        st = g.take(st, rng.choice(opts))
    return True


def make(n_plates, n_colors, rng):
    plates = []
    for i in range(n_plates):
        w = rng.uniform(0.38, 0.62)
        h = rng.uniform(0.22, 0.36)
        x = rng.uniform(0.04, 0.96 - w)
        y = rng.uniform(0.04, 0.96 - h)
        corners = [(x + w * 0.12, y + h * 0.16), (x + w * 0.88, y + h * 0.16), (x + w * 0.12, y + h * 0.84), (x + w * 0.88, y + h * 0.84)]
        if rng.random() < 0.5:
            corners.append((x + w * 0.5, y + h * 0.5))
        k = rng.randint(2, len(corners))
        pts = rng.sample(corners, k)
        plates.append({"rect": [round(x, 3), round(y, 3), round(w, 3), round(h, 3)], "screws": [[round(px, 3), round(py, 3), ""] for px, py in pts]})
    total = sum(len(p["screws"]) for p in plates)
    total -= total % 3
    if total < 9:
        return None
    # trim extra screws from the top plates so the count is a multiple of 3
    extra = sum(len(p["screws"]) for p in plates) - total
    for p in reversed(plates):
        while extra and len(p["screws"]) > 1:
            p["screws"].pop()
            extra -= 1
    cols = COLORS[:n_colors]
    triples = [cols[i % n_colors] for i in range(total // 3)]
    rng.shuffle(triples)
    bag = [c for c in triples for _ in range(3)]
    rng.shuffle(bag)
    k = 0
    for p in plates:
        for s in p["screws"]:
            s[2] = bag[k]
            k += 1
    return {"plates": plates, "boxes": triples, "tray": 5}


def generate(n_plates, n_colors, rng, want_jam=(0.25, 0.75), tries=3000):
    for _ in range(tries):
        b = make(n_plates, n_colors, rng)
        if not b or not solve(b):
            continue
        wins = sum(random_playout(b, rng) for _ in range(60))
        jam = 1 - wins / 60
        if want_jam[0] <= jam <= want_jam[1]:
            b["jam_rate"] = round(jam, 2)
            b["screws"] = sum(len(p["screws"]) for p in b["plates"])
            return b
    return None


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--plates", type=int, default=4)
    ap.add_argument("--colors", type=int, default=3)
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--jam-min", type=float, default=0.25)
    ap.add_argument("--jam-max", type=float, default=0.75)
    a = ap.parse_args()
    b = generate(a.plates, a.colors, random.Random(a.seed), (a.jam_min, a.jam_max))
    if not b:
        sys.exit("no board; try another seed")
    print(json.dumps(b))
