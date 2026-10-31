"""Fontaine de cristal (2 × 2) : bassin de pierre, vasque, jet animé."""
import math

EXTENT = 2.2


def build(m):
    z = m.flagstone_plinth(1.94, 1.94, mat="marble", curb="stone_dark")
    m.ao_height = 0.8
    for i in range(12):
        a = math.tau * i / 12
        m.box((0.36, 0.14, 0.28), (math.cos(a) * 0.72, math.sin(a) * 0.72, z + 0.14), "stone_warm", rot=(0, 0, math.degrees(a) + 90), bevel=0.03)
    m.cyl(0.66, 0.2, (0, 0, z), "water", seg=20)
    m.cyl(0.12, 0.6, (0, 0, z), "marble", r2=0.08, seg=12)
    m.cyl(0.32, 0.1, (0, 0, z + 0.6), "marble", r2=0.36, seg=16)
    m.cyl(0.3, 0.02, (0, 0, z + 0.69), "water", seg=16)
    m.crystal((0, 0, z + 0.68), 0.42, 0.08, "crystal")
    with m.anim("jet", (0, 0, z + 1.1), bob=0.05):
        for i in range(6):
            a = math.tau * i / 6
            m.sphere(0.035, (math.cos(a) * 0.2, math.sin(a) * 0.2, z + 0.95 - i % 2 * 0.1), "glow_teal", seg=6, rings=4)
    m.light((0, 0, z + 1.0), "7fdcff", 0.8, 3.0)
    with m.tier(1):
        for i in range(4):
            a = math.tau * i / 4 + math.pi / 4
            m.sphere(0.07, (math.cos(a) * 0.86, math.sin(a) * 0.86, z + 0.32), "moss", seg=8, rings=5, scale=(1.2, 1.2, 0.9))
    with m.tier(2):
        m.torus(0.33, 0.02, (0, 0, z + 0.7), "gold", seg=16, rseg=4)
