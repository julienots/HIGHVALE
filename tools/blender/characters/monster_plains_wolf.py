"""Loup des plaines (surface)."""
import math  # noqa: F401
from characters._monster import eyes, wing, spine_chain  # noqa: F401
FLAT_PALETTE = True

EXTENT = 0.3


def build(m):
    m.ao_height = 0.1
    for side, name, y in ((-1, "legl", -0.08), (1, "legr", -0.08), (-1, "legl", 0.1), (1, "legr", 0.1)):
        with m.anim(name, (side * 0.06, y, 0.13)):
            m.rod((side * 0.06, y, 0.13), (side * 0.065, y - 0.01, 0.0), 0.025, "fur_grey", seg=6)
            m.sphere(0.028, (side * 0.065, y - 0.02, 0.012), "dark", seg=6, rings=4, scale=(1, 1.3, 0.6))
    with m.anim("body", (0, 0, 0.13)):
        m.sphere(0.12, (0, 0.01, 0.17), "fur_grey", seg=12, rings=8, scale=(0.75, 1.35, 0.75))
        m.sphere(0.07, (0, -0.06, 0.13), "feather_white", seg=10, rings=6, scale=(0.8, 1.2, 0.7))
        m.sphere(0.075, (0, -0.17, 0.25), "fur_grey", seg=12, rings=8)
        m.sphere(0.04, (0, -0.24, 0.23), "fur_grey", seg=10, rings=6, scale=(0.8, 1.3, 0.7))
        m.sphere(0.013, (0, -0.29, 0.235), "dark", seg=6, rings=4)
        eyes(m, 0, -0.23, 0.27, r=0.014, gap=0.03, mat="glow_gold", glint=False)
        for sx in (-1, 1):
            m.cyl(0.025, 0.07, (sx * 0.04, -0.16, 0.3), "fur_grey", r2=0.0, rot=(-10, sx * 15, 0), seg=4, smooth=False)
    with m.anim("tail", (0, 0.16, 0.2)):
        m.rod((0, 0.16, 0.2), (0, 0.3, 0.26), 0.03, "fur_grey", seg=6, r2=0.015)
