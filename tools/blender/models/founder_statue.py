"""Statue du Fondateur (2 × 2) : héros de pierre levant un cristal sur un socle gravé."""
import math

EXTENT = 2.4


def build(m):
    z = m.flagstone_plinth(1.94, 1.94, mat="marble", curb="stone_dark")
    m.ao_height = 1.2
    m.box((1.0, 1.0, 0.18), (0, 0, z + 0.09), "stone_dark", bevel=0.03)
    m.box((0.72, 0.72, 0.5), (0, 0, z + 0.43), "marble", bevel=0.04)
    m.box((0.5, 0.03, 0.12), (0, -0.37, z + 0.45), "gold", bevel=0.01)
    s = z + 0.68
    # Personnage
    for sx in (-1, 1):
        m.cyl(0.06, 0.32, (sx * 0.08, 0, s), "stone_warm", r2=0.07, seg=10)
    m.cyl(0.16, 0.36, (0, 0, s + 0.3), "stone_warm", r2=0.13, seg=12)
    m.sphere(0.11, (0, 0, s + 0.78), "stone_warm", seg=12, rings=8)
    m.poly([(-0.17, 0.02, 0.62), (0.17, 0.02, 0.62), (0.25, 0.16, 0.0), (-0.25, 0.16, 0.0)], [(0, 1, 2, 3), (3, 2, 1, 0)], (0, 0.02, s + 0.05), "cloth_blue")
    m.rod((-0.17, 0, s + 0.6), (-0.22, -0.05, s + 0.38), 0.04, "stone_warm", seg=8)
    m.rod((0.17, 0, s + 0.62), (0.24, -0.04, s + 1.0), 0.04, "stone_warm", seg=8)
    m.crystal((0.25, -0.04, s + 0.98), 0.3, 0.06, "crystal")
    m.light((0.25, -0.04, s + 1.2), "7fdcff", 0.7, 2.5)
    with m.tier(1):
        for sx in (-1, 1):
            m.brazier((sx * 0.72, -0.72, z))
    with m.tier(2):
        m.torus(0.13, 0.015, (0, 0, s + 0.92), "gold", seg=12, rseg=4)
