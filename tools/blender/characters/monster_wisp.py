"""Créature : wisp."""
import math  # noqa: F401
from characters._monster import eyes, wing, spine_chain  # noqa: F401

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    m.ao_height = 0.1
    with m.anim("body", (0, 0, 0.26), bob=0.05):
        m.sphere(0.08, (0, 0, 0.26), "glow_gold", seg=14, rings=8)
        m.cyl(0.06, 0.12, (0, 0.01, 0.3), "glow_gold", r2=0.0, seg=10)
        eyes(m, 0, -0.074, 0.27, r=0.02, gap=0.03, mat="fur_night", glint=True)
    with m.anim("tail", (0, 0, 0.2), spin=("Y", 90)):
        for i in range(6):
            a = math.tau * i / 6
            m.sphere(0.02 - i * 0.002, (math.cos(a) * 0.12, math.sin(a) * 0.12, 0.16 + i * 0.012), "glow_gold", seg=6, rings=4)
    m.light((0, 0, 0.3), "ffd84a", 0.7, 2.0)
