"""Tour de cristal (2 × 2) : flèche de pierre runique coiffée d'un grand
cristal flottant qui foudroie les ennemis (dégâts de zone)."""
import math
from models._defense import stone_tower

EXTENT = 2.6


def build(m):
    z = m.flagstone_plinth(1.94, 1.94, mat="marble", curb="stone_dark")
    m.ao_height = 1.2
    top = stone_tower(m, 0, 0, 0.42, z, 1.25, "marble", "crystal_violet", rings=3)
    for k in range(4):
        a = math.tau * k / 4 + math.pi / 4
        m.rod((math.cos(a) * 0.62, math.sin(a) * 0.62, z), (math.cos(a) * 0.4, math.sin(a) * 0.4, top - 0.1), 0.05, "stone_dark", seg=6)
        m.box((0.06, 0.02, 0.12), (math.cos(a) * 0.43, math.sin(a) * 0.43, z + 0.7), "rune", rot=(0, 0, math.degrees(a) + 90), bevel=0)
    m.cyl(0.5, 0.1, (0, 0, top), "stone_dark", seg=12, smooth=False)
    for k in range(6):
        a = math.tau * k / 6
        m.cyl(0.04, 0.3, (math.cos(a) * 0.42, math.sin(a) * 0.42, top + 0.1), "gold", r2=0.0, seg=5)
    with m.anim("turret", (0, 0, top + 0.6), spin=("Y", 40), bob=0.05):
        m.crystal((0, 0, top + 0.25), 0.8, 0.2, "crystal_violet")
        for k in range(3):
            a = math.tau * k / 3
            m.crystal((math.cos(a) * 0.3, math.sin(a) * 0.3, top + 0.45), 0.3, 0.07, "crystal", tilt=(20 * math.sin(a), 20 * math.cos(a)))
        m.torus(0.42, 0.015, (0, 0, top + 0.6), "glow_violet", seg=20, rseg=4)
    m.light((0, 0, top + 0.7), "b464ff", 1.6, 4.0)
    with m.tier(1):
        m.crystal_cluster((0.7, -0.7, z), 0.3, "crystal_violet", 4)
    with m.tier(2):
        m.crystal_cluster((-0.7, 0.7, z), 0.3, "crystal", 4)
    with m.tier(3):
        m.torus(0.6, 0.02, (0, 0, top + 0.9), "glow_gold", seg=24, rseg=4)
