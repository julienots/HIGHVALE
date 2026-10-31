"""Créature : dragonling."""
import math  # noqa: F401
from characters._monster import eyes, wing, spine_chain  # noqa: F401

EXTENT = 0.34
FLAT_PALETTE = True


def build(m):
    m.ao_height = 0.1
    for side, name in ((-1, "legl"), (1, "legr")):
        with m.anim(name, (side * 0.07, 0, 0.1)):
            m.rod((side * 0.07, 0, 0.1), (side * 0.08, -0.02, 0.02), 0.03, "scale_red", seg=6)
            m.sphere(0.035, (side * 0.08, -0.03, 0.02), "scale_red", seg=8, rings=5, scale=(1, 1.3, 0.6))
    with m.anim("body", (0, 0, 0.1)):
        m.sphere(0.11, (0, 0, 0.17), "scale_red", seg=14, rings=10, scale=(1, 1.05, 1.15))
        m.sphere(0.08, (0, -0.06, 0.16), "scale_belly", seg=12, rings=8, scale=(1, 0.6, 1.2))
        m.sphere(0.085, (0, -0.06, 0.33), "scale_red", seg=14, rings=10)
        m.sphere(0.05, (0, -0.13, 0.31), "scale_red", seg=10, rings=6, scale=(1, 1, 0.8))
        eyes(m, 0, -0.13, 0.36, r=0.02, gap=0.04, mat="eye_glow", glint=False)
        for sx in (-1, 1):
            m.cyl(0.018, 0.09, (sx * 0.05, -0.02, 0.39), "gold", r2=0.0, rot=(-35, sx * 25, 0), seg=6)
            m.sphere(0.008, (sx * 0.015, -0.17, 0.31), "dark", seg=6, rings=4)
        for i in range(4):
            m.crystal((0, 0.06 + i * 0.03, 0.29 - i * 0.05), 0.06, 0.015, "crystal", tilt=(-30, 0))
    for side, name in ((-1, "wingl"), (1, "wingr")):
        with m.anim(name, (side * 0.08, 0.05, 0.24)):
            wing(m, side, (side * 0.08, 0.05, 0.24), 0.22, 0.16, mat="scale_belly", bone="scale_red")
    with m.anim("tail", (0, 0.1, 0.12)):
        spine_chain(m, [(0, 0.13, 0.11), (0.03, 0.2, 0.08), (0.07, 0.25, 0.06)], [0.045, 0.032, 0.022], "scale_red")
        m.cyl(0.03, 0.05, (0.09, 0.28, 0.06), "fire", r2=0.0, rot=(-70, 0, 0), seg=5)
    m.light((0, -0.1, 0.4), "ff7a30", 0.4, 1.5)
