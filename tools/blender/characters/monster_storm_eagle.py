"""Aigle tempête (surface)."""
import math  # noqa: F401
from characters._monster import eyes, wing, spine_chain  # noqa: F401
FLAT_PALETTE = True

EXTENT = 0.3


def build(m):
    m.ao_height = 0.1
    with m.anim("body", (0, 0, 0.18), bob=0.03):
        m.sphere(0.09, (0, 0.02, 0.2), "fur_brown", seg=12, rings=8, scale=(0.9, 1.3, 1.0))
        m.sphere(0.065, (0, -0.06, 0.32), "feather_white", seg=12, rings=8)
        m.cyl(0.025, 0.06, (0, -0.12, 0.31), "gold", r2=0.0, rot=(100, 0, 0), seg=6)
        eyes(m, 0, -0.11, 0.34, r=0.012, gap=0.03, mat="dark")
        for k in range(3):
            m.box((0.03 + k * 0.01, 0.12, 0.01), ((k - 1) * 0.03, 0.16, 0.16), "feather_white", rot=(-20, (k - 1) * 15, 0), bevel=0.004)
        for sx in (-1, 1):
            m.rod((sx * 0.03, 0.02, 0.12), (sx * 0.035, 0.0, 0.05), 0.012, "gold", seg=5)
    for side, name in ((-1, "wingl"), (1, "wingr")):
        with m.anim(name, (side * 0.07, 0.02, 0.24)):
            wing(m, side, (side * 0.07, 0.02, 0.24), 0.26, 0.12, mat="fur_brown", bone="feather_white")
            for k in range(4):
                m.box((0.05, 0.02, 0.006), (side * (0.12 + k * 0.04), 0.03, 0.26 - k * 0.01), "feather_white", bevel=0.002)
    m.light((0, 0, 0.4), "c8d8ff", 0.3, 1.2)
