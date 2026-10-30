"""Champignonnière : planches de culture, champignons géants lumineux,
abri de récolte et bûches de bois fongique."""
import math

EXTENT = 3.0


def build(m):
    z = m.flagstone_plinth(2.94, 2.94, mat="stone", curb="stone_dark")
    m.ao_height = 1.2
    # Planches de culture
    for (bx, by, bw, bd) in [(-0.45, 0.45, 1.85, 1.75)]:
        m.box((bw, bd, 0.14), (bx, by, z + 0.07), "earth", bevel=0.02)
        for side in range(4):
            if side % 2 == 0:
                m.box((bw + 0.1, 0.09, 0.2), (bx, by + (bd / 2 + 0.03) * (1 if side else -1), z + 0.1), "wood", bevel=0.02)
            else:
                m.box((0.09, bd + 0.1, 0.2), (bx + (bw / 2 + 0.03) * (1 if side == 1 else -1), by, z + 0.1), "wood", bevel=0.02)
    for i in range(14):
        x, y = -0.45 + m.rng.uniform(-0.8, 0.8), 0.45 + m.rng.uniform(-0.75, 0.75)
        m.sphere(0.06, (x, y, z + 0.14), "moss", seg=6, rings=3, scale=(1, 1, 0.5), smooth=False)
    # Champignons géants
    m.mushroom((-0.75, 0.8, z + 0.13), 1.55, 0.62, "mushroom_teal", "glow_teal", bend=0.18, lean=0.5)
    m.mushroom((0.05, 0.75, z + 0.13), 1.05, 0.45, "mushroom_violet", "glow_violet", bend=0.12, lean=2.4)
    m.mushroom((-0.65, -0.05, z + 0.13), 0.8, 0.36, "mushroom_pink", "glow_pink", bend=0.1, lean=4.0)
    m.light((-0.7, 0.75, z + 1.3), "6ff5e0", 0.9, 3.5)
    # Petites pousses
    for i in range(7):
        x, y = -0.45 + m.rng.uniform(-0.8, 0.8), 0.45 + m.rng.uniform(-0.75, 0.75)
        if math.hypot(x + 0.75, y - 0.8) < 0.3 or math.hypot(x - 0.05, y - 0.75) < 0.25:
            continue
        m.mushroom((x, y, z + 0.13), m.rng.uniform(0.18, 0.3), m.rng.uniform(0.08, 0.12), "mushroom_teal", "glow_teal", bend=0.03, spots=0)
    # Abri de récolte
    sx, sy = 0.85, -0.45
    for px in (-0.38, 0.38):
        m.box((0.08, 0.08, 0.9), (sx + px, sy - 0.32, z + 0.45), "wood", bevel=0.015)
        m.box((0.08, 0.08, 1.1), (sx + px, sy + 0.32, z + 0.55), "wood", bevel=0.015)
    m.box((1.0, 0.85, 0.05), (sx, sy, z + 1.02), "wood_dark", rot=(-13, 0, 0), bevel=0.01)
    for i in range(5):
        m.box((1.04, 0.2, 0.04), (sx, sy - 0.32 + i * 0.16, z + 0.97 + i * 0.037), "roof_teal", rot=(-13, 0, 0), bevel=0.012, tint=m.jitter(0.1))
    # Bûches de bois fongique
    for row in range(3):
        for k in range(3 - row):
            y = sy - 0.18 + k * 0.17 + row * 0.085
            m.cyl(0.08, 0.6, (sx - 0.3, y, z + 0.09 + row * 0.15), "wood", rot=(0, 90, 0), seg=10)
            m.cyl(0.065, 0.005, (sx + 0.305, y, z + 0.09 + row * 0.15), "mushroom_teal", rot=(0, 90, 0), seg=10)
    m.box((0.32, 0.3, 0.16), (sx + 0.15, sy - 0.85, z + 0.08), "wood", bevel=0.02)
    for k in range(4):
        m.mushroom((sx + 0.07 + k * 0.06, sy - 0.85, z + 0.15), 0.08, 0.06, "mushroom_teal", "glow_teal", bend=0.0, spots=0)
    # Clôture avant
    for i in range(6):
        m.box((0.05, 0.05, 0.3), (-1.35 + i * 0.2, -1.1, z + 0.15), "wood", bevel=0.01)
    m.box((1.1, 0.03, 0.04), (-0.85, -1.1, z + 0.24), "wood_dark", bevel=0)
    with m.tier(1):
        m.lantern_post((-1.3, -0.8, z), 1.0)
        m.mushroom((0.3, 0.2, z + 0.13), 0.5, 0.24, "mushroom_teal", "glow_teal", bend=0.05)
    with m.tier(2):
        m.mushroom((0.45, 1.05, z + 0.13), 1.3, 0.48, "mushroom_teal", "glow_teal", bend=0.15, lean=1.5)
        with m.anim("spores", (-0.4, 0.5, z + 1.5), spin=("Y", 20), bob=0.12):
            for i in range(8):
                a = 2 * math.pi * i / 8
                m.sphere(0.035, (-0.4 + math.cos(a) * 0.7, 0.5 + math.sin(a) * 0.7, z + 1.4 + (i % 3) * 0.15), "glow_teal", seg=6, rings=4)
    with m.tier(3):
        m.crystal_cluster((1.15, 0.95, z), 0.45, "crystal_teal")
        m.cyl(0.3, 0.03, (0.75, 0.55, z), "crystal_teal", seg=16)
