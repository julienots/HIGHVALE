"""Académie : grand bâtiment à portique, toit d'ardoises bleues, tour de
l'horloge avec cadran doré et télescope."""
import math

EXTENT = 3.0


def build(m):
    z = m.flagstone_plinth(2.94, 2.94, mat="stone_warm", curb="stone_dark")
    cx, cy, w, d, h = -0.2, 0.45, 1.9, 1.1, 1.0
    for a, b in [((cx - w / 2, cy - d / 2), (cx + w / 2, cy - d / 2)), ((cx + w / 2, cy - d / 2), (cx + w / 2, cy + d / 2)),
                 ((cx + w / 2, cy + d / 2), (cx - w / 2, cy + d / 2)), ((cx - w / 2, cy + d / 2), (cx - w / 2, cy - d / 2))]:
        m.brick_wall(a, b, z, h, thick=0.18, mat="marble", course=0.2, brick=0.4)
    m.box((w - 0.2, d - 0.2, h), (cx, cy, z + h / 2), "stone_dark", bevel=0)
    m.box((w + 0.14, d + 0.14, 0.1), (cx, cy, z + h + 0.05), "stone_warm", bevel=0.02)
    m.gable_roof((cx, cy, z + h + 0.1), w, d, 0.55, "roof_slate", overhang=0.14, rows=5, gable="marble")
    for wx in (-0.65, -0.25, 0.25, 0.65):
        m.window((cx + wx, cy - d / 2 - 0.05, z + 0.35), 0, w=0.2, h=0.42, frame="stone_dark", arch=True, sill="marble")
    # Portique
    for px in (-0.35, 0.0, 0.35):
        m.column((cx + px - 0.18 * 0, cy - d / 2 - 0.35, z), 0.055, h)
    m.box((1.0, 0.45, 0.08), (cx, cy - d / 2 - 0.22, z + h + 0.04), "marble", bevel=0.02)
    m.door((cx, cy - d / 2 - 0.05, z), 0, w=0.32, h=0.55, frame="marble")
    # Tour de l'horloge
    tx, ty = 0.95, -0.55
    m.box((0.6, 0.6, 2.0), (tx, ty, z + 1.0), "marble", bevel=0.03)
    for k in range(4):
        m.box((0.64, 0.64, 0.05), (tx, ty, z + 0.45 + k * 0.45), "stone_warm", bevel=0.01)
    m.cyl(0.2, 0.04, (tx, ty - 0.31, z + 1.65), "gold", rot=(90, 0, 0), seg=20)
    m.cyl(0.17, 0.02, (tx, ty - 0.335, z + 1.65), "cloth_cream", rot=(90, 0, 0), seg=20)
    with m.anim("hand", (tx, ty - 0.355, z + 1.65), spin=("Z", 20)):
        m.box((0.02, 0.01, 0.14), (tx, ty - 0.355, z + 1.71), "dark", bevel=0)
    m.box((0.02, 0.01, 0.1), (tx + 0.04, ty - 0.355, z + 1.65), "dark", rot=(0, 70, 0), bevel=0)
    m.window((tx + 0.31, ty, z + 1.0), 90, w=0.16, h=0.3, frame="stone_dark", arch=True)
    m.cone_roof((tx, ty, z + 2.0), 0.48, 0.8, "roof_blue", rings=5)
    # Télescope
    m.cyl(0.03, 0.4, (-1.15, -0.95, z), "bronze", seg=6)
    m.cyl(0.07, 0.55, (-1.15, -0.95, z + 0.4), "bronze", r2=0.05, rot=(-45, 0, 30), seg=10)
    m.crate((-0.55, -1.15, z), 0.24, 12)
    with m.tier(1):
        m.lantern_post((0.3, -1.25, z), 1.0)
    with m.tier(2):
        m.banner((-1.3, 1.2, z), 1.4, "cloth_blue")
    with m.tier(3):
        m.sphere(0.1, (tx, ty, z + 3.15), "gold", seg=10, rings=6)
