"""Bibliothèque : bâtisse de pierre à fenêtres en arc, tour violette,
lutrin, piles de livres et grimoire flottant."""
import math

EXTENT = 3.0


def books(m, x, y, z, n):
    for k in range(n):
        m.box((0.2, 0.15, 0.04), (x + m.rng.uniform(-0.02, 0.02), y, z + 0.02 + k * 0.042), m.rng.choice(["cloth_red", "cloth_blue", "roof_violet", "moss", "straw"]),
              rot=(0, 0, m.rng.uniform(-15, 15)), bevel=0.008)


def build(m):
    z = m.flagstone_plinth(2.94, 2.94, mat="stone_warm", curb="stone_dark")
    cx, cy, w, d, h = -0.35, 0.4, 1.7, 1.3, 1.25
    for a, b in [((cx - w / 2, cy - d / 2), (cx + w / 2, cy - d / 2)), ((cx + w / 2, cy - d / 2), (cx + w / 2, cy + d / 2)),
                 ((cx + w / 2, cy + d / 2), (cx - w / 2, cy + d / 2)), ((cx - w / 2, cy + d / 2), (cx - w / 2, cy - d / 2))]:
        m.brick_wall(a, b, z, h, thick=0.18, mat="stone_warm", course=0.17, brick=0.3)
    m.box((w - 0.2, d - 0.2, h), (cx, cy, z + h / 2), "stone_dark", bevel=0)
    m.box((w + 0.12, d + 0.12, 0.08), (cx, cy, z + h + 0.04), "stone_dark", bevel=0.02)
    m.gable_roof((cx, cy, z + h + 0.08), w, d, 0.6, "roof_violet", overhang=0.14, rows=5, gable="stone_warm")
    m.door((cx, cy - d / 2 - 0.05, z), 0, w=0.4, h=0.6, frame="stone_dark")
    for wx in (-0.55, 0.55):
        m.window((cx + wx, cy - d / 2 - 0.05, z + 0.3), 0, w=0.24, h=0.6, frame="stone_dark", arch=True)
    for wy in (-0.3, 0.3):
        m.window((cx + w / 2 + 0.05, cy + wy, z + 0.3), 90, w=0.24, h=0.6, frame="stone_dark", arch=True)
    # Tour
    tx, ty = 0.85, -0.45
    m.cyl(0.4, 1.85, (tx, ty, z), "stone", seg=16, smooth=False)
    for k in range(6):
        m.torus(0.405, 0.02, (tx, ty, z + 0.2 + k * 0.3), "stone_dark", seg=16, rseg=4)
    m.window((tx, ty - 0.42, z + 0.9), 0, w=0.18, h=0.3, frame="stone_dark", arch=True)
    m.window((tx + 0.42, ty, z + 1.3), 90, w=0.18, h=0.3, frame="stone_dark", arch=True)
    m.cone_roof((tx, ty, z + 1.85), 0.52, 0.95, "roof_violet", rings=6)
    # Lutrin et livres
    m.cyl(0.04, 0.5, (-0.9, -1.0, z), "wood_dark", seg=6)
    m.box((0.3, 0.22, 0.03), (-0.9, -1.0, z + 0.52), "wood", rot=(-25, 0, 0), bevel=0.01)
    m.box((0.26, 0.18, 0.03), (-0.9, -1.0, z + 0.55), "cloth_cream", rot=(-25, 0, 0), bevel=0.005)
    books(m, -0.35, -1.1, z, 5)
    books(m, -1.25, -0.5, z, 4)
    m.crate((0.15, -1.15, z), 0.26, -8)
    books(m, 0.15, -1.15, z + 0.26, 3)
    with m.anim("grimoire", (0.85, -1.05, z + 0.9), spin=("Y", 25), bob=0.08):
        m.box((0.24, 0.18, 0.05), (0.85, -1.05, z + 0.9), "roof_violet", bevel=0.01)
        m.box((0.22, 0.16, 0.06), (0.86, -1.05, z + 0.9), "cloth_cream", bevel=0.005)
    m.torus(0.3, 0.015, (0.85, -1.05, z + 0.02), "rune", seg=20, rseg=4)
    m.light((0.85, -1.05, z + 0.6), "b49cff", 0.6, 2.2)
    with m.tier(1):
        m.lantern_post((-1.3, -1.2, z), 1.0)
    with m.tier(2):
        m.banner((-1.3, 1.25, z), 1.4, "roof_violet")
    with m.tier(3):
        m.crystal_cluster((1.25, 1.2, z), 0.35, "crystal_violet")
