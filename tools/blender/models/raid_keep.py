"""Donjon ennemi (4 × 4) : forteresse sombre à quatre tours, grand portail,
étendards rouges et feu de garde ; c'est la cible principale d'un assaut."""
import math
from models._defense import square_ring, stone_tower, round_crenels

EXTENT = 4.0


def build(m):
    z = m.flagstone_plinth(3.94, 3.94, mat="stone_dark", curb="stone_dark")
    m.ao_height = 1.8
    w = 1.25
    m.box((2 * w, 2 * w, 1.4), (0, 0, z + 0.7), "stone_dark", bevel=0.04)
    for k in range(4):
        m.box((2 * w + 0.03, 2 * w + 0.03, 0.04), (0, 0, z + 0.25 + k * 0.32), "rock", bevel=0.005)
    square_ring(m, 0, 0, w, z + 1.4, "stone_dark", 0.2, 0.26)
    m.box((1.4, 1.4, 0.9), (0, 0.1, z + 1.85), "stone_dark", bevel=0.04)
    square_ring(m, 0, 0.1, 0.7, z + 2.3, "stone_dark", 0.16, 0.22)
    m.hip_roof((0, 0.1, z + 2.45), 1.3, 0.8, "roof_slate", rows=5, hip_mat="iron")
    for sx in (-1, 1):
        for sy in (-1, 1):
            top = stone_tower(m, sx * w, sy * w, 0.42, z, 1.9, "stone_dark", "rock", rings=3)
            round_crenels(m, sx * w, sy * w, 0.4, top, "stone_dark", n=10, h=0.18)
            m.cone_roof((sx * w, sy * w, top + 0.18), 0.5, 0.65, "roof_red", rings=4, finial="iron")
    m.door((0, -w - 0.02, z), 0, w=0.7, h=0.95, mat="iron", frame="stone_dark")
    for wx in (-0.6, 0.6):
        m.window((wx, -w - 0.02, z + 0.9), 0, w=0.14, h=0.3, frame="stone_dark", arch=True)
    for sx in (-1, 1):
        m.banner((sx * 0.85, -w - 0.2, z), 1.6, "cloth_red", "gold")
        m.brazier((sx * 0.45, -w - 0.45, z), 0.13)
    m.light((0, -w - 0.5, z + 0.6), "ff8a3a", 1.2, 3.5)
    m.light((0, 0, z + 3.2), "ff5a3a", 0.6, 4.0)
    with m.anim("turret", (0, 0.1, z + 2.9), spin=("Y", 20)):
        m.sphere(0.16, (0, 0.1, z + 3.0), "fire", seg=10, rings=6)
