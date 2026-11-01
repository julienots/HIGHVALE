"""Tour d'archers (2 × 2) : tour de pierre ronde, plate-forme de bois crénelée,
toit pointu, archer et arbalète montés sur la tête pivotante."""
import math
from models._defense import stone_tower, round_crenels

EXTENT = 2.4


def build(m):
    z = m.flagstone_plinth(1.94, 1.94, mat="stone", curb="stone_dark")
    m.ao_height = 1.2
    top = stone_tower(m, 0, 0, 0.5, z, 1.45, "stone", "stone_dark")
    for k in range(3):
        a = math.tau * k / 3 + 0.4
        m.window((math.cos(a) * 0.47, math.sin(a) * 0.47, z + 0.75), math.degrees(a) + 90, w=0.1, h=0.22, frame="stone_dark", arch=True)
    m.door((0, -0.5, z + 0.16), 0, w=0.24, h=0.36, frame="stone_dark")
    # Plate-forme pivotante (tête)
    with m.anim("turret", (0, 0, top)):
        m.cyl(0.66, 0.1, (0, 0, top), "wood", seg=16, smooth=False)
        for k in range(8):
            a = math.tau * k / 8
            m.rod((math.cos(a) * 0.48, math.sin(a) * 0.48, top - 0.3), (math.cos(a) * 0.62, math.sin(a) * 0.62, top), 0.03, "wood_dark", seg=4)
        round_crenels(m, 0, 0, 0.62, top + 0.1, "wood_light", n=12, h=0.2)
        for k in range(4):
            a = math.tau * k / 4
            m.rod((math.cos(a) * 0.55, math.sin(a) * 0.55, top + 0.1), (math.cos(a) * 0.55, math.sin(a) * 0.55, top + 0.75), 0.03, "wood_dark", seg=5)
        m.cone_roof((0, 0, top + 0.75), 0.75, 0.6, "roof_red", rings=4, finial="gold")
        # Arbalète géante pointée vers l'avant (-y)
        m.box((0.08, 0.5, 0.08), (0, -0.25, top + 0.32), "wood_dark", bevel=0.01)
        m.torus(0.22, 0.02, (0, -0.42, top + 0.32), "iron", rot=(0, 0, 0), seg=14, rseg=4, arc=160)
        m.cyl(0.015, 0.5, (0, -0.25, top + 0.36), "steel", rot=(90, 0, 0), seg=5)
        # Archer
        m.cyl(0.07, 0.18, (0.2, 0.15, top + 0.1), "cloth_green", seg=8)
        m.sphere(0.06, (0.2, 0.15, top + 0.34), "skin", seg=8, rings=5)
        m.sphere(0.065, (0.2, 0.15, top + 0.37), "cloth_green", seg=8, rings=5, hemi=True)
        m.torus(0.12, 0.01, (0.28, 0.08, top + 0.26), "wood", rot=(0, 90, 30), seg=10, rseg=3, arc=150)
    with m.tier(1):
        m.banner((0.62, 0.62, z), 1.1, "cloth_red", "gold", rot_z=45)
    with m.tier(2):
        for k in range(3):
            a = math.tau * k / 3
            m.torus(0.5, 0.025, (0, 0, z + 0.4 + k * 0.4), "gold", seg=18, rseg=4)
    with m.tier(3):
        m.crystal_cluster((-0.7, 0.7, z), 0.28, "crystal", 4)
    m.light((0, 0, top + 0.5), "ffb45a", 0.5, 2.5)
