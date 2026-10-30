"""Autel divin : sanctuaire de marbre à degrés, autel d'or, orbe divin
flottant entouré d'un halo, quatre piliers à flammes dorées."""
import math

EXTENT = 3.0


def build(m):
    z = m.flagstone_plinth(2.94, 2.94, mat="marble", curb="stone_warm")
    for k, s in enumerate((2.4, 1.9, 1.4)):
        m.box((s, s, 0.16), (0, 0, z + 0.08 + k * 0.16), "marble", bevel=0.03)
        m.frame_ring(s + 0.02, z + 0.16 + k * 0.16, "gold", 0.035)
    top = z + 0.48
    for k in range(3):
        m.box((0.5, 0.18, 0.16 * (k + 1)), (0, -1.3 + k * 0.18, z + 0.08 * (k + 1)), "marble", bevel=0.02)
    m.box((0.7, 0.45, 0.45), (0, 0, top + 0.22), "gold", bevel=0.04)
    m.box((0.82, 0.55, 0.06), (0, 0, top + 0.47), "marble", bevel=0.02)
    m.box((0.5, 0.03, 0.2), (0, -0.24, top + 0.22), "glow_gold", bevel=0)
    with m.anim("orb", (0, 0, top + 1.1), bob=0.1):
        m.sphere(0.24, (0, 0, top + 1.1), "glow_gold", seg=18, rings=12)
    with m.anim("halo", (0, 0, top + 1.1), spin=("Y", 45)):
        m.torus(0.42, 0.03, (0, 0, top + 1.1), "gold", rot=(75, 0, 0), seg=28, rseg=5)
        m.torus(0.36, 0.02, (0, 0, top + 1.1), "glow_gold", rot=(-60, 30, 0), seg=24, rseg=4)
    m.light((0, 0, top + 1.1), "ffd84a", 1.8, 5.0)
    # Piliers à flammes
    for sx in (-1, 1):
        for sy in (-1, 1):
            x, y = sx * 0.95, sy * 0.95
            m.column((x, y, z + 0.16), 0.08, 1.2, "marble", "gold")
            m.cyl(0.13, 0.08, (x, y, z + 1.36), "gold", r2=0.18, seg=12)
            with m.anim("flame%d%d" % (sx + 1, sy + 1), (x, y, z + 1.5), bob=0.03):
                m.sphere(0.1, (x, y, z + 1.52), "glow_gold", seg=8, rings=6, scale=(1, 1, 1.6))
    # Ailes sculptées
    for sx in (-1, 1):
        verts = [(0, 0, 0), (sx * 0.35, 0, 0.15), (sx * 0.55, 0, 0.45), (sx * 0.5, 0, 0.7), (sx * 0.3, 0, 0.5), (sx * 0.15, 0, 0.35)]
        m.poly(verts, [(0, 1, 2, 3, 4, 5), (5, 4, 3, 2, 1, 0)], (sx * 0.38, -0.05, top + 0.45), "marble")
    with m.tier(1):
        m.banner((-1.3, 0.0, z), 1.4, "cloth_cream", emblem="gold", rot_z=90)
        m.banner((1.3, 0.0, z), 1.4, "cloth_cream", emblem="gold", rot_z=90)
    with m.tier(2):
        with m.anim("motes", (0, 0, top + 1.6), spin=("Y", -30)):
            for i in range(6):
                a = 2 * math.pi * i / 6
                m.sphere(0.04, (math.cos(a) * 0.75, math.sin(a) * 0.75, top + 1.6), "glow_gold", seg=6, rings=4)
    with m.tier(3):
        m.crystal_cluster((1.2, 1.2, z), 0.35, "crystal")
        m.crystal_cluster((-1.2, 1.2, z), 0.35, "crystal")
