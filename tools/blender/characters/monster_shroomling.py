"""Créature : shroomling."""
import math  # noqa: F401
from characters._monster import eyes, wing, spine_chain  # noqa: F401

EXTENT = 0.26
FLAT_PALETTE = True


def build(m):
    m.ao_height = 0.1
    for side, name in ((-1, "legl"), (1, "legr")):
        with m.anim(name, (side * 0.04, 0, 0.06)):
            m.cyl(0.025, 0.06, (side * 0.04, 0, 0.0), "mushroom_stem", seg=8)
    with m.anim("body", (0, 0, 0.06)):
        m.cyl(0.075, 0.16, (0, 0, 0.05), "mushroom_stem", r2=0.06, seg=12)
        eyes(m, 0, -0.07, 0.15, r=0.016, gap=0.028)
        m.torus(0.018, 0.005, (0, -0.07, 0.11), "dark", rot=(90, 0, 0), seg=10, rseg=3, arc=180)
        m.sphere(0.16, (0, 0, 0.2), "mushroom_violet", seg=16, rings=8, hemi=True, scale=(1, 1, 0.65))
        m.cyl(0.15, 0.015, (0, 0, 0.195), "glow_violet", seg=16)
        for i in range(6):
            a = math.tau * i / 6
            m.sphere(0.02, (math.cos(a) * 0.09, math.sin(a) * 0.09, 0.275), "mushroom_stem", seg=6, rings=4, scale=(1, 1, 0.5))
    for side, name in ((-1, "arml"), (1, "armr")):
        with m.anim(name, (side * 0.07, 0, 0.17)):
            m.rod((side * 0.07, 0, 0.17), (side * 0.12, -0.02, 0.1), 0.014, "mushroom_stem", seg=6)
