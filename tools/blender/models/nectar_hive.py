"""Nectarerie : fleurs-calices géantes gorgées de nectar, ruches de champignon,
cuves de nectar et jarres scellées."""
import math

EXTENT = 3.0


def flower(m, x, y, z, h, r, petal, core="glow_gold"):
    m.rod((x, y, z), (x + 0.05, y, z + h), 0.04, "moss", seg=8, r2=0.03)
    for i in range(3):
        a = m.rng.uniform(0, math.tau)
        m.poly([(0, 0, 0), (0.18, 0.05, 0.06), (0.26, 0, 0.12), (0.18, -0.05, 0.06)], [(0, 1, 2, 3), (3, 2, 1, 0)],
               (x, y, z + h * (0.3 + i * 0.2)), "moss", rot=(0, -20, math.degrees(a)))
    cx, cy, cz = x + 0.05, y, z + h
    for i in range(7):
        a = math.tau * i / 7
        m.sphere(r * 0.55, (cx + math.cos(a) * r * 0.6, cy + math.sin(a) * r * 0.6, cz + 0.02), petal, seg=10, rings=6,
                 scale=(1.0, 0.55, 0.35), rot=(0, -25, math.degrees(a)))
    m.sphere(r * 0.42, (cx, cy, cz + 0.02), "flame" if core == "flame" else core, seg=10, rings=6, scale=(1, 1, 0.55))


def build(m):
    z = m.flagstone_plinth(2.94, 2.94, mat="stone_warm", curb="stone_dark")
    m.ao_height = 1.0
    # Parterre
    m.box((1.9, 1.5, 0.12), (-0.4, 0.55, z + 0.06), "earth", bevel=0.02)
    for side in (-1, 1):
        m.box((1.98, 0.08, 0.18), (-0.4, 0.55 + side * 0.76, z + 0.09), "wood", bevel=0.015)
    for side in (-1, 1):
        m.box((0.08, 1.6, 0.18), (-0.4 + side * 0.99, 0.55, z + 0.09), "wood", bevel=0.015)
    flower(m, -0.85, 0.85, z + 0.12, 0.95, 0.32, "mushroom_pink")
    flower(m, -0.1, 0.95, z + 0.12, 0.75, 0.26, "straw")
    flower(m, -0.6, 0.15, z + 0.12, 0.6, 0.22, "mushroom_violet")
    flower(m, 0.25, 0.35, z + 0.12, 0.5, 0.18, "mushroom_pink")
    m.light((-0.6, 0.6, z + 1.0), "ffd84a", 0.9, 3.0)
    # Ruches de champignon
    for (x, y, s) in [(0.95, 0.85, 1.0), (1.05, 0.25, 0.8)]:
        m.cyl(0.08 * s, 0.35 * s, (x, y, z), "wood_dark", seg=8)
        for k in range(4):
            r = (0.28 - k * 0.05) * s
            m.cyl(r, 0.12 * s, (x, y, z + (0.3 + k * 0.1) * s), "straw", r2=r * 0.9, seg=14, tint=m.jitter(0.12))
        m.sphere(0.05 * s, (x, y - 0.24 * s, z + 0.42 * s), "dark", seg=8, rings=5)
    # Cuve de nectar
    m.cyl(0.3, 0.32, (0.55, -0.7, z), "wood", seg=14)
    for hz in (0.06, 0.26):
        m.torus(0.305, 0.018, (0.55, -0.7, z + hz), "iron", seg=16, rseg=4)
    m.cyl(0.27, 0.02, (0.55, -0.7, z + 0.3), "glow_gold", seg=14)
    # Jarres scellées
    for i, (x, y) in enumerate([(-1.15, -0.75), (-0.9, -0.95), (-1.2, -1.1), (0.05, -1.1)]):
        m.sphere(0.12, (x, y, z + 0.12), "bronze", seg=10, rings=6, scale=(1, 1, 1.1))
        m.cyl(0.06, 0.06, (x, y, z + 0.24), "bronze", seg=8)
        m.cyl(0.07, 0.03, (x, y, z + 0.3), "cloth_red", seg=8)
    with m.anim("motes", (-0.4, 0.55, z + 1.0), spin=("Y", 25), bob=0.08):
        for i in range(7):
            a = math.tau * i / 7
            m.sphere(0.03, (-0.4 + math.cos(a) * 0.65, 0.55 + math.sin(a) * 0.5, z + 0.9 + (i % 3) * 0.12), "glow_gold", seg=6, rings=4)
    with m.tier(1):
        m.lantern_post((1.25, -1.2, z), 1.0)
    with m.tier(2):
        flower(m, 0.3, 1.1, z + 0.12, 1.15, 0.36, "straw")
    with m.tier(3):
        m.crystal_cluster((-1.25, 1.2, z), 0.32, "crystal_teal")
