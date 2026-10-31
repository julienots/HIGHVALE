"""Sylphe du vent (surface)."""
import math  # noqa: F401
from characters._monster import eyes, wing, spine_chain  # noqa: F401
FLAT_PALETTE = True

EXTENT = 0.28


def build(m):
    m.ao_height = 0.05
    with m.anim("body", (0, 0, 0.25), bob=0.06):
        m.sphere(0.06, (0, 0, 0.35), "glow_teal", seg=12, rings=8)
        eyes(m, 0, -0.055, 0.36, r=0.012, gap=0.022, mat="fur_night")
        m.cyl(0.05, 0.16, (0, 0, 0.17), "glow_teal", r2=0.03, seg=10)
        m.cyl(0.03, 0.12, (0, 0, 0.06), "glow_teal", r2=0.0, seg=8, rot=(180, 0, 0))
        for sx in (-1, 1):
            m.rod((sx * 0.04, 0, 0.3), (sx * 0.12, -0.02, 0.22), 0.012, "glow_teal", seg=5)
    with m.anim("tail", (0, 0, 0.2), spin=("Y", 120)):
        for i in range(3):
            m.torus(0.1 + i * 0.03, 0.006, (0, 0, 0.12 + i * 0.08), "cloth_white", rot=(10 * i, 0, 0), seg=16, rseg=3, arc=240)
