"""Créatures paramétriques : plans de corps (gelée, quadrupède, drake, oiseau,
serpent, insecte, golem, esprit, plante, poisson, crustacé, batracien, méduse,
brute) et ornements (cristaux, piquants, flammes, mousse, champignons, cornes,
bois, couronne, carapace, runes, auréole, feuilles).
Articulations reconnues dans Godot : body, tail, wingl / wingr, legl / legr, arml / armr.

creature(m, plan, c1, c2, c3, eyes="dark", deco=(), **options)
"""
import math
from characters._monster import eyes as _eyes, wing as _wing

# Boîte englobante approximative de chaque plan (portrait).
EXTENTS = dict(blob=0.22, quad=0.3, drake=0.34, bird=0.3, serpent=0.3, insect=0.26, golem=0.32, spirit=0.24,
               plant=0.26, fish=0.2, crab=0.26, frog=0.24, jelly=0.26, brute=0.3)


def face(m, x, y, z, r, mat, gap=None, mouth=None, glint=True):
    _eyes(m, x, y, z, r=r, gap=gap or r * 1.7, mat=mat, glint=glint)
    if mouth == "smile":
        m.torus(r * 0.9, r * 0.22, (x, y - 0.004, z - r * 1.6), "dark", rot=(-90, 0, 0), seg=10, rseg=3, arc=180)
    elif mouth == "fangs":
        for sx in (-1, 1):
            m.cyl(r * 0.3, r * 1.1, (x + sx * r * 0.7, y, z - r * 2.4), "cloth_white", r2=0.0, rot=(180, 0, 0), seg=4)


# --- Ornements -----------------------------------------------------------------

def decorate(m, deco, back, head, rng):
    for d in deco:
        kind, _, arg = d.partition(":")
        if kind == "crystals":
            for i, p in enumerate(back):
                m.crystal(p, 0.06 + 0.03 * (i % 2), 0.014, arg or "crystal", tilt=(rng.uniform(-25, 25), rng.uniform(-25, 25)))
        elif kind == "spikes":
            for p in back:
                m.cyl(0.018, 0.06, p, arg or "bone", r2=0.0, seg=5, rot=(-25, 0, 0), smooth=False)
        elif kind == "flame":
            hx, hy, hz = back[-1] if back else head
            for k in range(3):
                m.sphere(0.03 - k * 0.007, (hx, hy + 0.01 * k, hz + 0.02 + k * 0.035), ("lava", "fire", "glow_gold")[k] if not arg else arg,
                         seg=8, rings=5, scale=(1, 1, 1.4))
        elif kind == "moss":
            for p in back:
                m.sphere(0.03, p, arg or "moss", seg=7, rings=4, scale=(1.2, 1.2, 0.5))
        elif kind == "mushrooms":
            for p in back[::2]:
                m.cyl(0.008, 0.035, p, "mushroom_stem", seg=5)
                m.sphere(0.026, (p[0], p[1], p[2] + 0.035), arg or "mushroom_pink", seg=8, rings=5, hemi=True)
        elif kind == "horns":
            x, y, z = head
            for sx in (-1, 1):
                m.rod((x + sx * 0.03, y, z), (x + sx * 0.06, y + 0.02, z + 0.07), 0.012, arg or "bone", seg=5, r2=0.003)
        elif kind == "horn":
            x, y, z = head
            m.cyl(0.016, 0.08, (x, y - 0.02, z), arg or "gold", r2=0.0, seg=6, rot=(-25, 0, 0))
        elif kind == "antlers":
            x, y, z = head
            for sx in (-1, 1):
                a = (x + sx * 0.03, y + 0.01, z)
                b = (x + sx * 0.07, y + 0.02, z + 0.08)
                m.rod(a, b, 0.008, arg or "bark", seg=4)
                m.rod(b, (x + sx * 0.11, y + 0.0, z + 0.11), 0.006, arg or "bark", seg=4)
                m.rod(b, (x + sx * 0.06, y + 0.05, z + 0.13), 0.006, arg or "bark", seg=4)
        elif kind == "crown":
            x, y, z = head
            m.torus(0.035, 0.008, (x, y, z + 0.01), arg or "gold", seg=12, rseg=4)
            for i in range(5):
                a = math.tau * i / 5
                m.cyl(0.007, 0.025, (x + math.cos(a) * 0.035, y + math.sin(a) * 0.035, z + 0.01), arg or "gold", r2=0.0, seg=4)
        elif kind == "halo":
            x, y, z = head
            m.torus(0.05, 0.007, (x, y + 0.01, z + 0.06), arg or "glow_gold", seg=16, rseg=4)
        elif kind == "runes":
            for p in back[::2]:
                m.box((0.03, 0.03, 0.006), p, arg or "rune", rot=(0, 0, 45), bevel=0.002)
        elif kind == "leaves":
            for i, p in enumerate(back):
                m.sphere(0.04, (p[0], p[1], p[2] + 0.03), arg or "leaf", seg=8, rings=5, scale=(0.5, 0.25, 1.2), rot=(0, (i % 3 - 1) * 25, i * 70))
        elif kind == "shell":
            x, y, z = back[len(back) // 2] if back else head
            m.sphere(0.12, (x, y, z - 0.03), arg or "shell_red", seg=12, rings=8, hemi=True, scale=(1.0, 1.2, 0.8), smooth=False)
        elif kind == "glowspots":
            for p in back:
                m.sphere(0.012, p, arg or "glow_teal", seg=6, rings=4)
        elif kind == "smoke":
            hx, hy, hz = back[-1] if back else head
            for k in range(3):
                m.sphere(0.02 + k * 0.01, (hx + k * 0.01, hy, hz + 0.04 + k * 0.04), arg or "stone", seg=6, rings=4)


# --- Plans de corps ---------------------------------------------------------------

def _blob(m, c1, c2, c3, eye, o):
    tall = o.get("tall", 1.0)
    with m.anim("body", (0, 0, 0)):
        m.sphere(0.15, (0, 0, 0.0), c1, seg=18, rings=10, hemi=True, scale=(1.1, 1.0, 1.05 * tall))
        m.sphere(0.075, (0, 0, 0.15 * tall), c1, seg=12, rings=8, scale=(1, 1, 0.9))
        m.sphere(0.05, (0, -0.07, 0.04), c2, seg=10, rings=6, scale=(1.2, 0.5, 0.8))
        m.sphere(0.022, (0.05, -0.06, 0.12 * tall), "cloth_white", seg=6, rings=4)
        face(m, 0, -0.14, 0.09 * tall, 0.024, eye, mouth=o.get("mouth", "smile"))
        for i in range(3):
            m.sphere(0.012, (m.rng.uniform(-0.08, 0.08), m.rng.uniform(-0.04, 0.05), m.rng.uniform(0.03, 0.1)), c3, seg=6, rings=4)
    back = [(-0.06, 0.04, 0.15 * tall), (0.0, 0.05, 0.2 * tall), (0.06, 0.04, 0.15 * tall)]
    return back, (0, 0, 0.21 * tall)


def _legs4(m, c, foot, y0, y1, hip, xs=0.06, r=0.022, short=False):
    h = hip * (0.6 if short else 1.0)
    for side, name, y in ((-1, "legl", y0), (1, "legr", y0), (-1, "legl", y1), (1, "legr", y1)):
        with m.anim(name, (side * xs, y, h)):
            m.rod((side * xs, y, h), (side * (xs + 0.005), y - 0.01, 0.0), r, c, seg=6)
            m.sphere(r * 1.15, (side * (xs + 0.005), y - 0.02, 0.012), foot, seg=6, rings=4, scale=(1, 1.3, 0.6))
    return h


def _quad(m, c1, c2, c3, eye, o, drake=False):
    bulk = o.get("bulk", 1.0)
    short = o.get("legs") == "short"
    hip = 0.13
    h = _legs4(m, c1, o.get("foot", "dark"), -0.08, 0.1, hip, xs=0.06 * bulk, r=0.022 * bulk, short=short)
    bz = h + 0.04
    snout = o.get("snout", 0.05)
    with m.anim("body", (0, 0, bz)):
        m.sphere(0.12, (0, 0.01, bz), c1, seg=12, rings=8, scale=(0.75 * bulk, 1.35, 0.75 * bulk))
        m.sphere(0.07, (0, -0.06, bz - 0.04), c2, seg=10, rings=6, scale=(0.8 * bulk, 1.2, 0.6))
        hy, hz = -0.17, bz + 0.08
        m.sphere(0.075, (0, hy, hz), c1, seg=12, rings=8)
        if snout > 0:
            m.sphere(0.04, (0, hy - 0.06, hz - 0.02), c2, seg=10, rings=6, scale=(0.85, 0.6 + snout * 8, 0.7))
            m.sphere(0.012, (0, hy - 0.08 - snout * 0.6, hz - 0.012), "dark", seg=6, rings=4)
        face(m, 0, hy - 0.06, hz + 0.025, 0.015, eye, gap=0.03, mouth="fangs" if o.get("fangs") else None, glint=True)
        ears = o.get("ears", "pointy")
        for sx in (-1, 1):
            if ears == "pointy":
                m.cyl(0.024, 0.06, (sx * 0.04, hy + 0.01, hz + 0.05), c1, r2=0.0, rot=(-10, sx * 15, 0), seg=4, smooth=False)
            elif ears == "round":
                m.sphere(0.025, (sx * 0.05, hy + 0.01, hz + 0.06), c1, seg=8, rings=5, scale=(1, 0.5, 1))
            elif ears == "long":
                m.sphere(0.022, (sx * 0.04, hy + 0.02, hz + 0.1), c1, seg=8, rings=5, scale=(0.6, 0.4, 2.0))
            elif ears == "fins":
                m.poly([(0, 0, 0), (sx * 0.06, 0.03, 0.04), (sx * 0.04, 0.05, -0.01)], [(0, 1, 2), (2, 1, 0)],
                       (sx * 0.06, hy, hz), c3, smooth=False)
        if o.get("mane"):
            m.sphere(0.085, (0, hy + 0.05, hz - 0.01), o["mane"], seg=12, rings=8, scale=(1.1, 0.8, 1.05))
        if drake:
            for sx in (-1, 1):
                m.rod((sx * 0.03, hy + 0.03, hz + 0.05), (sx * 0.06, hy + 0.08, hz + 0.1), 0.012, c3, seg=5, r2=0.003)
    tail = o.get("tail", "thin")
    with m.anim("tail", (0, 0.16, bz)):
        if tail == "bushy":
            m.sphere(0.05, (0, 0.24, bz + 0.05), o.get("tailc", c1), seg=10, rings=6, scale=(0.8, 1.6, 0.8))
        elif tail == "thin":
            m.rod((0, 0.15, bz), (0, 0.3, bz + 0.07), 0.018, c1, seg=6, r2=0.006)
        elif tail == "club":
            m.rod((0, 0.15, bz), (0, 0.28, bz + 0.02), 0.025, c1, seg=6, r2=0.015)
            m.sphere(0.04, (0, 0.3, bz + 0.03), c3, seg=8, rings=5)
        elif tail == "flame":
            m.rod((0, 0.15, bz), (0, 0.26, bz + 0.06), 0.02, c1, seg=6, r2=0.01)
            m.sphere(0.035, (0, 0.28, bz + 0.09), "fire", seg=8, rings=5, scale=(1, 1, 1.4))
        elif tail == "long":
            m.rod((0, 0.15, bz), (0, 0.27, bz - 0.02), 0.03, c1, seg=6, r2=0.02)
            m.rod((0, 0.27, bz - 0.02), (0, 0.38, bz - 0.06), 0.02, c1, seg=6, r2=0.005)
    if drake or o.get("wings"):
        for side, name in ((-1, "wingl"), (1, "wingr")):
            with m.anim(name, (side * 0.06, 0.0, bz + 0.06)):
                _wing(m, side, (side * 0.06, 0.0, bz + 0.06), 0.24, 0.14, mat=o.get("wingc", "membrane"), bone=c1)
    back = [(0, -0.06 + k * 0.06, bz + 0.085) for k in range(4)]
    return back, (0, -0.17, bz + 0.15)


def _bird(m, c1, c2, c3, eye, o):
    long_legs = o.get("legs") == "long"
    lz = 0.1 if long_legs else 0.0
    for side, name in ((-1, "legl"), (1, "legr")):
        with m.anim(name, (side * 0.03, 0.01, 0.12 + lz)):
            m.rod((side * 0.03, 0.01, 0.12 + lz), (side * 0.035, 0.0, 0.03), 0.011, c3, seg=5)
            m.sphere(0.02, (side * 0.035, -0.01, 0.02), c3, seg=6, rings=4, scale=(1, 1.4, 0.4))
    bz = 0.2 + lz
    with m.anim("body", (0, 0, bz), bob=0.02):
        m.sphere(0.09, (0, 0.02, bz), c1, seg=12, rings=8, scale=(0.9, 1.25, 1.0))
        m.sphere(0.06, (0, -0.04, bz - 0.02), c2, seg=10, rings=6, scale=(0.9, 0.8, 1.0))
        m.sphere(0.06, (0, -0.06, bz + 0.11), c1, seg=12, rings=8)
        m.cyl(0.022, 0.06, (0, -0.11, bz + 0.1), c3, r2=0.0, rot=(100, 0, 0), seg=6)
        face(m, 0, -0.1, bz + 0.13, 0.012, eye, gap=0.028)
        if o.get("crest"):
            for k in range(3):
                m.cyl(0.012, 0.07, (0, -0.04 + k * 0.025, bz + 0.16), o["crest"], r2=0.0, rot=(-30 + k * 15, 0, 0), seg=4)
    with m.anim("tail", (0, 0.1, bz)):
        n = 5 if o.get("tail") == "fan" else 3
        for k in range(n):
            a = (k - (n - 1) / 2) * 18
            m.box((0.03, 0.14 if o.get("tail") == "long" else 0.1, 0.008), (math.sin(math.radians(a)) * 0.04, 0.16, bz - 0.01),
                  c2 if k % 2 else c1, rot=(-15, 0, a), bevel=0.003)
    for side, name in ((-1, "wingl"), (1, "wingr")):
        with m.anim(name, (side * 0.07, 0.02, bz + 0.04)):
            _wing(m, side, (side * 0.07, 0.02, bz + 0.04), 0.24, 0.12, mat=c1, bone=c2)
            for k in range(3):
                m.box((0.05, 0.02, 0.006), (side * (0.12 + k * 0.04), 0.03, bz + 0.05 - k * 0.012), c2, bevel=0.002)
    back = [(0, 0.0 + k * 0.05, bz + 0.08) for k in range(2)]
    return back, (0, -0.06, bz + 0.17)


def _serpent(m, c1, c2, c3, eye, o):
    n = o.get("segments", 7)
    pts = []
    for i in range(n):
        t = i / (n - 1)
        pts.append((math.sin(t * 5.0) * 0.08, 0.2 - t * 0.32, 0.04 + t * t * 0.18))
    with m.anim("tail", (0, 0.2, 0.04)):
        for i, p in enumerate(pts[:n // 2]):
            m.sphere(0.035 + i * 0.005, p, c1, seg=10, rings=6)
    with m.anim("body", (0, 0, 0.1)):
        for i, p in enumerate(pts[n // 2:]):
            r = 0.05 + i * 0.004
            m.sphere(r, p, c1, seg=10, rings=6)
            m.sphere(r * 0.7, (p[0], p[1] - r * 0.4, p[2] - r * 0.2), c2, seg=8, rings=5, scale=(1, 0.6, 1))
        hx, hy, hz = pts[-1]
        hy -= 0.05
        hz += 0.04
        m.sphere(0.06, (hx, hy, hz), c1, seg=12, rings=8, scale=(1, 1.2, 0.8))
        face(m, hx, hy - 0.068, hz + 0.015, 0.016, eye, gap=0.03, mouth="fangs" if o.get("fangs") else None)
        if o.get("hood"):
            m.sphere(0.065, (hx, hy + 0.04, hz - 0.02), c3, seg=12, rings=6, scale=(1.4, 0.3, 1.1))
        if o.get("fins"):
            for sx in (-1, 1):
                m.poly([(0, 0, 0), (sx * 0.07, 0.04, 0.04), (sx * 0.05, 0.07, -0.02)], [(0, 1, 2), (2, 1, 0)],
                       (hx + sx * 0.04, hy, hz), c3, smooth=False)
    back = [(p[0], p[1], p[2] + 0.04) for p in pts[1:-1:2]]
    return back, (hx, hy, hz + 0.05)


def _insect(m, c1, c2, c3, eye, o):
    with m.anim("body", (0, 0, 0.08)):
        m.sphere(0.12, (0, 0.06, 0.08), c1, seg=12, rings=8, hemi=True, scale=(0.9, 1.25, 0.9), smooth=False)
        m.box((0.008, 0.26, 0.08), (0, 0.06, 0.1), c3, bevel=0.003)
        m.sphere(0.07, (0, -0.1, 0.07), c2, seg=10, rings=6)
        m.sphere(0.055, (0, -0.17, 0.08), c1, seg=10, rings=6)
        face(m, 0, -0.21, 0.09, 0.016, eye, gap=0.03, glint=False)
        for sx in (-1, 1):
            m.rod((sx * 0.02, -0.2, 0.12), (sx * 0.06, -0.26, 0.2), 0.005, c2, seg=4)
            m.sphere(0.01, (sx * 0.06, -0.26, 0.2), c3, seg=6, rings=4)
            for k in range(3):
                y = -0.12 + k * 0.08
                m.rod((sx * 0.06, y, 0.06), (sx * 0.16, y - 0.02, 0.0), 0.01, c2, seg=5)
        if o.get("stinger"):
            m.cyl(0.02, 0.07, (0, 0.2, 0.08), c3, r2=0.0, rot=(-80, 0, 0), seg=6)
    if o.get("wings"):
        for side, name in ((-1, "wingl"), (1, "wingr")):
            with m.anim(name, (side * 0.04, 0.0, 0.16)):
                for k in (0, 1):
                    m.sphere(0.1, (side * 0.13, 0.02 + k * 0.1, 0.17), o["wings"], seg=10, rings=4, scale=(1.2, 0.35, 0.06))
    back = [(sx * 0.04, 0.0 + k * 0.08, 0.17) for k in range(2) for sx in (-1, 1)]
    return back, (0, -0.17, 0.13)


def _golem(m, c1, c2, c3, eye, o):
    for side, name in ((-1, "legl"), (1, "legr")):
        with m.anim(name, (side * 0.06, 0, 0.1)):
            m.box((0.07, 0.08, 0.1), (side * 0.06, 0, 0.05), c1, bevel=0.015)
    with m.anim("body", (0, 0, 0.1)):
        m.box((0.2, 0.15, 0.17), (0, 0, 0.19), c1, bevel=0.03)
        m.sphere(0.035, (0, -0.075, 0.2), c3, seg=10, rings=6)
        m.box((0.12, 0.1, 0.08), (0, -0.01, 0.31), c2, bevel=0.02)
        face(m, 0, -0.06, 0.32, 0.014, eye, gap=0.03, glint=False)
    for side, name in ((-1, "arml"), (1, "armr")):
        with m.anim(name, (side * 0.13, 0, 0.25)):
            m.box((0.07, 0.07, 0.06), (side * 0.14, 0, 0.26), c2, bevel=0.015)
            m.box((0.06, 0.06, 0.14), (side * 0.15, -0.01, 0.17), c1, bevel=0.015)
            m.box((0.075, 0.075, 0.06), (side * 0.15, -0.02, 0.09), c2, bevel=0.015)
    back = [(sx * 0.07, 0.04, 0.29) for sx in (-1, 1)] + [(0, 0.06, 0.29)]
    return back, (0, -0.01, 0.35)


def _spirit(m, c1, c2, c3, eye, o):
    kind = o.get("kind", "wisp")
    with m.anim("body", (0, 0, 0.2), bob=0.04):
        if kind == "ghost":
            m.sphere(0.1, (0, 0, 0.22), c1, seg=14, rings=8, scale=(1, 1, 1.1))
            m.cyl(0.1, 0.12, (0, 0, 0.1), c1, r2=0.06, seg=14)
            for i in range(5):
                a = math.tau * i / 5
                m.cyl(0.025, 0.05, (math.cos(a) * 0.07, math.sin(a) * 0.07, 0.07), c1, r2=0.0, rot=(180, 0, 0), seg=5)
            for sx in (-1, 1):
                m.sphere(0.03, (sx * 0.1, -0.02, 0.18), c1, seg=8, rings=5, scale=(1, 1, 1.4))
            face(m, 0, -0.09, 0.24, 0.02, eye, mouth="smile")
        elif kind == "flame":
            m.sphere(0.09, (0, 0, 0.17), c1, seg=12, rings=8, scale=(1, 1, 1.2))
            for k in range(4):
                m.sphere(0.06 - k * 0.012, (0.01 * k, 0.01 * k, 0.26 + k * 0.05), c2, seg=8, rings=5, scale=(1, 1, 1.5))
            face(m, 0, -0.085, 0.18, 0.02, eye)
        else:
            m.sphere(0.075, (0, 0, 0.2), c1, seg=14, rings=8)
            m.sphere(0.1, (0, 0, 0.2), "glass", seg=12, rings=8)
            for i in range(6):
                a = math.tau * i / 6
                m.sphere(0.014, (math.cos(a) * 0.13, math.sin(a) * 0.13, 0.2 + math.sin(a * 2) * 0.03), c3, seg=6, rings=4)
            face(m, 0, -0.07, 0.21, 0.018, eye)
    with m.anim("tail", (0, 0.04, 0.1)):
        for k in range(3):
            m.sphere(0.04 - k * 0.011, (0, 0.05 + k * 0.04, 0.1 - k * 0.03), c2, seg=8, rings=5)
    m.light((0, 0, 0.25), o.get("light", "fff1a8"), 0.4, 1.2)
    return [(0, 0.03, 0.3)], (0, 0, 0.32)


def _plant(m, c1, c2, c3, eye, o):
    kind = o.get("kind", "flower")
    for side, name in ((-1, "legl"), (1, "legr")):
        with m.anim(name, (side * 0.04, 0, 0.06)):
            m.rod((side * 0.04, 0, 0.06), (side * 0.07, -0.02, 0.0), 0.018, "bark", seg=5)
    with m.anim("body", (0, 0, 0.06)):
        if kind == "cactus":
            m.cyl(0.08, 0.24, (0, 0, 0.05), c1, r2=0.07, seg=10)
            m.sphere(0.07, (0, 0, 0.29), c1, seg=10, rings=6)
            for sx in (-1, 1):
                m.rod((sx * 0.07, 0, 0.16), (sx * 0.13, 0, 0.2), 0.03, c1, seg=8)
                m.rod((sx * 0.13, 0, 0.2), (sx * 0.13, 0, 0.27), 0.028, c1, seg=8)
            for i in range(8):
                a = math.tau * i / 8
                m.cyl(0.004, 0.02, (math.cos(a) * 0.08, math.sin(a) * 0.08, 0.1 + (i % 3) * 0.05), "cloth_white", r2=0.0, seg=3,
                      rot=(90, 0, math.degrees(a) - 90))
            m.sphere(0.03, (0, 0, 0.36), c2, seg=8, rings=5)
            face(m, 0, -0.075, 0.2, 0.016, eye, mouth="smile")
            return [(0, 0, 0.36)], (0, 0, 0.36)
        m.cyl(0.07, 0.16, (0, 0, 0.05), c1, r2=0.05, seg=12)
        face(m, 0, -0.065, 0.14, 0.016, eye, mouth="smile")
        if kind == "mushroom":
            m.sphere(0.15, (0, 0, 0.2), c2, seg=16, rings=8, hemi=True, scale=(1, 1, 0.7))
            for i in range(6):
                a = math.tau * i / 6
                m.sphere(0.018, (math.cos(a) * 0.09, math.sin(a) * 0.09, 0.26), c3, seg=6, rings=4)
            top = (0, 0, 0.3)
        elif kind == "bulb":
            m.sphere(0.1, (0, 0, 0.27), c2, seg=12, rings=8, scale=(1, 1, 1.2))
            for i in range(3):
                a = math.tau * i / 3
                m.poly([(0, 0, 0), (0.05, 0.02, 0.08), (0, 0.04, 0.14), (-0.04, 0.02, 0.07)], [(0, 1, 2, 3), (3, 2, 1, 0)],
                       (0, 0, 0.36), c1, rot=(0, -30, math.degrees(a)), smooth=False)
            top = (0, 0, 0.42)
        else:
            m.sphere(0.04, (0, 0, 0.26), c3, seg=10, rings=6)
            for i in range(7):
                a = math.tau * i / 7
                m.sphere(0.05, (math.cos(a) * 0.07, math.sin(a) * 0.07 + 0.02, 0.26), c2, seg=8, rings=5,
                         scale=(1.0, 0.5, 0.35), rot=(-20, 0, math.degrees(a)))
            top = (0, 0, 0.31)
    for side, name in ((-1, "arml"), (1, "armr")):
        with m.anim(name, (side * 0.07, 0, 0.16)):
            m.sphere(0.05, (side * 0.12, -0.01, 0.16), "leaf", seg=8, rings=5, scale=(1.4, 0.3, 0.55), rot=(0, side * 15, 0))
    return [top], top


def _fish(m, c1, c2, c3, eye, o):
    with m.anim("body", (0, 0, 0.16), bob=0.03):
        m.sphere(0.1, (0, 0, 0.16), c1, seg=14, rings=8, scale=(0.7, 1.4, 0.9))
        m.sphere(0.07, (0, -0.03, 0.12), c2, seg=10, rings=6, scale=(0.7, 1.3, 0.6))
        face(m, 0, -0.12, 0.18, 0.018, eye, gap=0.045)
        m.torus(0.02, 0.006, (0, -0.145, 0.14), c3, rot=(90, 0, 0), seg=10, rseg=3)
        m.poly([(0, 0, 0), (0, 0.08, 0.1), (0, 0.14, 0.0)], [(0, 1, 2), (2, 1, 0)], (0, -0.02, 0.23), c3, smooth=False)
        for sx in (-1, 1):
            m.poly([(0, 0, 0), (sx * 0.08, 0.04, -0.03), (sx * 0.03, 0.07, -0.02)], [(0, 1, 2), (2, 1, 0)], (sx * 0.06, -0.02, 0.13), c3, smooth=False)
    with m.anim("tail", (0, 0.13, 0.16)):
        m.poly([(0, 0, 0), (0, 0.1, 0.08), (0, 0.06, 0.0), (0, 0.1, -0.08)], [(0, 1, 2, 3), (3, 2, 1, 0)], (0, 0.12, 0.16), c3, smooth=False)
    return [(0, -0.02 + k * 0.06, 0.25) for k in range(2)], (0, -0.06, 0.26)


def _crab(m, c1, c2, c3, eye, o):
    with m.anim("body", (0, 0, 0.08)):
        m.sphere(0.13, (0, 0, 0.1), c1, seg=14, rings=8, hemi=True, scale=(1.2, 0.95, 0.7), smooth=False)
        m.cyl(0.13, 0.03, (0, 0, 0.08), c2, seg=14, scale=(1.2, 0.95, 1))
        for sx in (-1, 1):
            m.rod((sx * 0.04, -0.08, 0.14), (sx * 0.05, -0.1, 0.2), 0.008, c1, seg=4)
            m.sphere(0.018, (sx * 0.05, -0.1, 0.2), eye, seg=8, rings=5)
            m.sphere(0.006, (sx * 0.05 + 0.006, -0.116, 0.205), "cloth_white", seg=4, rings=3)
            for k in range(3):
                y = -0.04 + k * 0.06
                m.rod((sx * 0.13, y, 0.08), (sx * 0.22, y + 0.02, 0.0), 0.012, c1, seg=5)
    for side, name in ((-1, "arml"), (1, "armr")):
        with m.anim(name, (side * 0.12, -0.08, 0.1)):
            m.rod((side * 0.12, -0.08, 0.1), (side * 0.18, -0.18, 0.12), 0.018, c1, seg=6)
            m.sphere(0.05, (side * 0.19, -0.22, 0.13), c3, seg=10, rings=6, scale=(0.8, 1.2, 0.7))
            m.cyl(0.02, 0.06, (side * 0.19, -0.27, 0.15), c3, r2=0.0, rot=(-80, 0, 0), seg=5)
    return [(sx * 0.05, 0.02, 0.18) for sx in (-1, 1)], (0, -0.04, 0.2)


def _frog(m, c1, c2, c3, eye, o):
    for side, name in ((-1, "legl"), (1, "legr")):
        with m.anim(name, (side * 0.08, 0.05, 0.05)):
            m.sphere(0.05, (side * 0.1, 0.06, 0.05), c1, seg=10, rings=6, scale=(0.8, 1.4, 0.7))
            m.sphere(0.03, (side * 0.12, -0.02, 0.01), c1, seg=8, rings=5, scale=(1.2, 1.4, 0.4))
    with m.anim("body", (0, 0, 0.05)):
        m.sphere(0.12, (0, 0.02, 0.1), c1, seg=14, rings=8, scale=(1.05, 1.0, 0.85))
        m.sphere(0.09, (0, -0.06, 0.07), c2, seg=10, rings=6, scale=(1.0, 0.7, 0.8))
        for sx in (-1, 1):
            m.sphere(0.035, (sx * 0.055, -0.04, 0.19), c1, seg=10, rings=6)
        face(m, 0, -0.065, 0.2, 0.022, eye, gap=0.055)
        m.torus(0.05, 0.006, (0, -0.1, 0.13), "dark", rot=(-90, 0, 0), seg=12, rseg=3, arc=180)
        for i in range(4):
            m.sphere(0.012, (m.rng.uniform(-0.08, 0.08), m.rng.uniform(0.0, 0.08), 0.18), c3, seg=6, rings=4)
    for side, name in ((-1, "arml"), (1, "armr")):
        with m.anim(name, (side * 0.08, -0.08, 0.08)):
            m.rod((side * 0.08, -0.08, 0.08), (side * 0.09, -0.11, 0.0), 0.014, c1, seg=5)
    return [(sx * 0.05, 0.04, 0.2) for sx in (-1, 1)], (0, -0.02, 0.23)


def _jelly(m, c1, c2, c3, eye, o):
    with m.anim("body", (0, 0, 0.25), bob=0.04):
        m.sphere(0.13, (0, 0, 0.24), c1, seg=16, rings=8, hemi=True, scale=(1, 1, 0.8))
        m.sphere(0.06, (0, 0, 0.27), c3, seg=10, rings=6)
        m.cyl(0.13, 0.02, (0, 0, 0.23), c2, seg=16)
        face(m, 0, -0.11, 0.27, 0.018, eye, mouth="smile")
    with m.anim("tail", (0, 0, 0.22)):
        for i in range(8):
            a = math.tau * i / 8
            x, y = math.cos(a) * 0.08, math.sin(a) * 0.08
            m.rod((x, y, 0.22), (x * 1.2, y * 1.2, 0.12), 0.01, c2, seg=4)
            m.rod((x * 1.2, y * 1.2, 0.12), (x * 0.9, y * 0.9, 0.03), 0.007, c2, seg=4)
    m.light((0, 0, 0.25), o.get("light", "8ae0ff"), 0.4, 1.2)
    return [(0, 0, 0.34)], (0, 0, 0.34)


def _brute(m, c1, c2, c3, eye, o):
    for side, name in ((-1, "legl"), (1, "legr")):
        with m.anim(name, (side * 0.06, 0, 0.1)):
            m.rod((side * 0.06, 0, 0.1), (side * 0.065, 0, 0.02), 0.03, c1, seg=6)
            m.sphere(0.035, (side * 0.065, -0.02, 0.015), c2, seg=6, rings=4, scale=(1, 1.4, 0.6))
    with m.anim("body", (0, 0, 0.1)):
        m.sphere(0.13, (0, 0.02, 0.2), c1, seg=14, rings=8, scale=(1.1, 0.9, 1.0))
        m.sphere(0.08, (0, -0.07, 0.18), c2, seg=10, rings=6, scale=(1.1, 0.5, 1.0))
        m.sphere(0.07, (0, -0.06, 0.31), c1, seg=12, rings=8)
        m.sphere(0.045, (0, -0.11, 0.29), c2, seg=10, rings=6, scale=(1.1, 0.6, 0.8))
        face(m, 0, -0.115, 0.33, 0.015, eye, gap=0.03, mouth="fangs" if o.get("fangs") else None)
    for side, name in ((-1, "arml"), (1, "armr")):
        with m.anim(name, (side * 0.13, 0, 0.26)):
            m.sphere(0.05, (side * 0.14, 0, 0.26), c1, seg=10, rings=6)
            m.rod((side * 0.15, 0, 0.24), (side * 0.17, -0.03, 0.1), 0.035, c1, seg=6, r2=0.03)
            m.sphere(0.045, (side * 0.17, -0.04, 0.07), c2, seg=8, rings=5)
    return [(sx * 0.06, 0.06, 0.3) for sx in (-1, 1)], (0, -0.06, 0.37)


PLANS = dict(blob=_blob, quad=_quad, bird=_bird, serpent=_serpent, insect=_insect, golem=_golem, spirit=_spirit,
             plant=_plant, fish=_fish, crab=_crab, frog=_frog, jelly=_jelly, brute=_brute,
             drake=lambda m, c1, c2, c3, eye, o: _quad(m, c1, c2, c3, eye, o, drake=True))


def creature(m, plan, c1, c2, c3, eyes="dark", deco=(), light=None, **o):
    m.ao_height = 0.1
    back, head = PLANS[plan](m, c1, c2, c3, eyes, o)
    # Les ornements suivent le corps : même groupe (et même pivot) que « body ».
    body = next((g for g in m.pivots if g.startswith("body_")), None)
    old = m.group
    if body:
        m.group = body
    decorate(m, deco, back, head, m.rng)
    m.group = old
    if light:
        m.light((0, 0, 0.3), light, 0.35, 1.2)
