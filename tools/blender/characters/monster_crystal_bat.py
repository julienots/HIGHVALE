"""Créature : crystal_bat."""
import math  # noqa: F401
from characters._monster import eyes, wing, spine_chain  # noqa: F401

EXTENT = 0.26
FLAT_PALETTE = True


def build(m):
    m.ao_height = 0.1
    with m.anim("body", (0, 0, 0.22), bob=0.04):
        m.sphere(0.08, (0, 0, 0.22), "fur_violet", seg=14, rings=8, scale=(1, 0.9, 1.05))
        for sx in (-1, 1):
            m.cyl(0.03, 0.08, (sx * 0.045, 0, 0.28), "fur_violet", r2=0.0, rot=(0, sx * 18, 0), seg=6)
        eyes(m, 0, -0.07, 0.24, r=0.018, gap=0.03, mat="eye_glow", glint=False)
        for i in range(3):
            m.crystal((0, 0.05 + i * 0.015, 0.25 - i * 0.04), 0.07, 0.016, "crystal_violet", tilt=(-40, 0))
        m.cyl(0.008, 0.03, (-0.02, -0.065, 0.19), "cloth_white", r2=0.0, rot=(180, 0, 0), seg=4)
        m.cyl(0.008, 0.03, (0.02, -0.065, 0.19), "cloth_white", r2=0.0, rot=(180, 0, 0), seg=4)
    for side, name in ((-1, "wingl"), (1, "wingr")):
        with m.anim(name, (side * 0.07, 0, 0.23)):
            wing(m, side, (side * 0.07, 0.0, 0.23), 0.2, 0.12)
