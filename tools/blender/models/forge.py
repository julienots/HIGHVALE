"""Forge : atelier de pierre, grande cheminée, four rougeoyant, enclume et râtelier."""
import math

EXTENT = 3.0


def build(m):
    z = m.flagstone_plinth(2.94, 2.94, mat="stone_dark", curb="stone_dark")
    cx, cy, w, d = 0.0, 0.55, 2.2, 1.0
    for a, b in [((cx - w / 2, cy - d / 2), (cx - w / 2, cy + d / 2)), ((cx - w / 2, cy + d / 2), (cx + w / 2, cy + d / 2)),
                 ((cx + w / 2, cy + d / 2), (cx + w / 2, cy - d / 2))]:
        m.brick_wall(a, b, z, 1.0, thick=0.2, mat="stone_dark", course=0.16, brick=0.32)
    m.box((w - 0.2, d - 0.2, 1.0), (cx, cy + 0.05, z + 0.5), "stone_dark", bevel=0)
    m.gable_roof((cx, cy, z + 1.0), w, d, 0.5, "roof_slate", overhang=0.14, rows=4, gable="stone_dark")
    # Appentis de travail
    for px in (-1.0, 0.0, 1.0):
        m.box((0.1, 0.1, 0.9), (px, -0.35, z + 0.45), "wood", bevel=0.02)
    m.box((2.2, 0.12, 0.1), (0, -0.35, z + 0.92), "wood", bevel=0.02)
    for i in range(4):
        m.box((2.3, 0.25, 0.04), (0, -0.3 + i * 0.2, z + 0.97 + i * 0.03), "roof_slate", rot=(-10, 0, 0), bevel=0.012, tint=m.jitter(0.1))
    # Cheminée
    chx, chy = 0.75, 0.75
    for k in range(9):
        m.box((0.42, 0.42, 0.18), (chx, chy, z + 0.09 + k * 0.19), "stone" if k % 2 else "stone_dark", rot=(0, 0, (k % 2) * 3), bevel=0.025)
    m.box((0.5, 0.5, 0.08), (chx, chy, z + 1.76), "iron", bevel=0.02)
    m.cyl(0.14, 0.04, (chx, chy, z + 1.8), "flame", seg=10)
    m.light((chx, chy, z + 2.0), "ff8a30", 0.8, 3.0)
    # Four
    fx, fy = -0.55, 0.3
    m.sphere(0.48, (fx, fy, z), "stone", seg=14, rings=8, hemi=True, smooth=False)
    m.box((0.36, 0.2, 0.3), (fx, fy - 0.42, z + 0.16), "dark", bevel=0.03)
    m.box((0.26, 0.05, 0.2), (fx, fy - 0.52, z + 0.13), "flame", bevel=0.0)
    m.light((fx, fy - 0.7, z + 0.3), "ff7a2a", 1.0, 2.8)
    # Enclume sur souche
    ax, ay = 0.15, -0.75
    m.cyl(0.17, 0.32, (ax, ay, z), "wood_dark", seg=10)
    m.box((0.34, 0.14, 0.08), (ax, ay, z + 0.36), "iron", bevel=0.02)
    m.box((0.16, 0.1, 0.08), (ax, ay, z + 0.44), "iron", bevel=0.02)
    m.cyl(0.05, 0.12, (ax + 0.17, ay, z + 0.4), "iron", r2=0.0, rot=(0, 90, 0), seg=8)
    m.box((0.2, 0.03, 0.04), (ax - 0.05, ay - 0.1, z + 0.5), "wood", rot=(0, 0, 25), bevel=0)
    # Bac de trempe
    m.box((0.5, 0.32, 0.26), (0.85, -0.85, z + 0.13), "wood_dark", bevel=0.02)
    m.box((0.42, 0.24, 0.02), (0.85, -0.85, z + 0.25), "water", bevel=0)
    # Râtelier d'armes
    m.box((0.7, 0.08, 0.06), (-0.95, -0.95, z + 0.55), "wood", bevel=0.01)
    for i in range(4):
        x = -1.2 + i * 0.17
        m.box((0.05, 0.02, 0.55), (x, -0.97, z + 0.33), "iron", bevel=0.005)
        m.box((0.14, 0.04, 0.03), (x, -0.97, z + 0.58), "gold" if i % 2 else "bronze", bevel=0)
    m.barrel((-1.2, -0.45, z))
    with m.tier(1):
        m.crate((1.2, -0.35, z), 0.26, 10)
        for i in range(3):
            m.cyl(0.14, 0.03, (-1.25, -1.2 + i * 0.0, z + i * 0.035), "iron", seg=12)
    with m.tier(2):
        m.banner((1.3, 1.25, z), 1.4, "cloth_red")
        m.torch((-1.3, 1.25, z), 0.7, tier=2)
    with m.tier(3):
        m.crystal_cluster((-1.2, 1.1, z), 0.35, "crystal")
