"""Phénix d'aurore : oiseau de feu légendaire (surface)."""
import math  # noqa: F401
from characters._monster import eyes, wing, spine_chain  # noqa: F401
FLAT_PALETTE = True

EXTENT = 0.34


def build(m):
    m.ao_height = 0.05
    with m.anim("body", (0, 0, 0.24), bob=0.05):
        m.sphere(0.08, (0, 0.02, 0.24), "scale_red", seg=12, rings=8, scale=(0.9, 1.3, 1.0))
        m.sphere(0.055, (0, -0.06, 0.34), "fire", seg=10, rings=6)
        m.cyl(0.02, 0.05, (0, -0.11, 0.33), "gold", r2=0.0, rot=(100, 0, 0), seg=6)
        eyes(m, 0, -0.1, 0.355, r=0.011, gap=0.026, mat="glow_gold", glint=False)
        for k in range(3):
            m.cyl(0.015, 0.09, (0, -0.04 + k * 0.025, 0.38), "fire", r2=0.0, rot=(-30 + k * 25, 0, 0), seg=5)
    for side, name in ((-1, "wingl"), (1, "wingr")):
        with m.anim(name, (side * 0.06, 0.02, 0.27)):
            wing(m, side, (side * 0.06, 0.02, 0.27), 0.28, 0.16, mat="fire", bone="gold")
    with m.anim("tail", (0, 0.1, 0.2)):
        for k in range(5):
            m.rod((0, 0.1, 0.2), ((k - 2) * 0.05, 0.3, 0.1 + abs(k - 2) * 0.02), 0.012, "fire" if k % 2 else "glow_gold", seg=4, r2=0.004)
    m.light((0, 0, 0.3), "ff8a30", 0.8, 2.0)
