"""Créature : fire_salamander."""
import math  # noqa: F401
from characters._monster import eyes, wing, spine_chain  # noqa: F401

EXTENT = 0.3
FLAT_PALETTE = True


def build(m):
    m.ao_height = 0.1
    with m.anim("body", (0, 0, 0.08)):
        spine_chain(m, [(0, -0.12, 0.09), (0, -0.03, 0.08), (0, 0.06, 0.08)], [0.075, 0.07, 0.065], "scale_red", scale=(1, 1.1, 0.85))
        m.sphere(0.075, (0, -0.2, 0.11), "scale_red", seg=12, rings=8, scale=(1, 1.2, 0.85))
        eyes(m, 0, -0.27, 0.13, r=0.016, gap=0.035, mat="fire", glint=False)
        m.sphere(0.06, (0, -0.06, 0.04), "scale_belly", seg=10, rings=6, scale=(1, 2.3, 0.5))
        for i in range(5):
            m.cyl(0.02, 0.06, (0, -0.16 + i * 0.06, 0.14 + (0.02 if i == 0 else 0)), "fire", r2=0.0, seg=5)
        for sx in (-1, 1):
            for y in (-0.1, 0.05):
                m.rod((sx * 0.05, y, 0.06), (sx * 0.11, y - 0.02, 0.0), 0.016, "scale_red", seg=5)
    with m.anim("tail", (0, 0.1, 0.08)):
        spine_chain(m, [(0, 0.14, 0.07), (0.02, 0.21, 0.06), (0.05, 0.27, 0.06)], [0.05, 0.035, 0.022], "scale_red")
        m.sphere(0.04, (0.06, 0.31, 0.08), "fire", seg=8, rings=6, scale=(1, 1, 1.5))
    m.light((0, 0, 0.3), "ff7a30", 0.5, 1.5)
