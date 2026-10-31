"""Créature : abyss_owl."""
import math  # noqa: F401
from characters._monster import eyes, wing, spine_chain  # noqa: F401

EXTENT = 0.28
FLAT_PALETTE = True


def build(m):
    m.ao_height = 0.1
    with m.anim("body", (0, 0, 0.05)):
        m.sphere(0.12, (0, 0, 0.17), "fur_night", seg=14, rings=10, scale=(1, 0.9, 1.15))
        m.sphere(0.08, (0, -0.06, 0.15), "fur_violet", seg=12, rings=8, scale=(1, 0.6, 1.1))
        for sx in (-1, 1):
            m.sphere(0.04, (sx * 0.045, -0.09, 0.23), "cloth_white", seg=10, rings=6, scale=(1, 0.5, 1))
            m.sphere(0.025, (sx * 0.045, -0.105, 0.23), "shadow_glow", seg=8, rings=5, scale=(1, 0.5, 1))
            m.cyl(0.02, 0.07, (sx * 0.08, 0, 0.3), "fur_night", r2=0.0, rot=(0, sx * 25, 0), seg=5)
            m.rod((sx * 0.04, 0, 0.05), (sx * 0.05, -0.04, 0.0), 0.012, "gold", seg=5)
        m.cyl(0.012, 0.03, (0, -0.11, 0.2), "gold", r2=0.0, rot=(160, 0, 0), seg=5)
        m.crystal((0, 0.08, 0.28), 0.08, 0.018, "crystal_violet", tilt=(-30, 0))
    for side, name in ((-1, "wingl"), (1, "wingr")):
        with m.anim(name, (side * 0.11, 0.0, 0.2)):
            m.sphere(0.06, (side * 0.12, 0.02, 0.15), "fur_night", seg=10, rings=6, scale=(0.5, 1, 1.6))
            for k in range(3):
                m.crystal((side * 0.13, 0.03, 0.06 + k * 0.01), 0.07, 0.012, "crystal_violet", tilt=(180, side * (10 + k * 10)))
