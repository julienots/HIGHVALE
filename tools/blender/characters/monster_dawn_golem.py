"""Colosse d'Aurore (surface) : golem de marbre et d'or."""
import math  # noqa: F401
from characters._monster import eyes, wing, spine_chain  # noqa: F401
FLAT_PALETTE = True

EXTENT = 0.34


def build(m):
    m.ao_height = 0.1
    for side, name in ((-1, "legl"), (1, "legr")):
        with m.anim(name, (side * 0.07, 0, 0.12)):
            m.box((0.09, 0.1, 0.12), (side * 0.07, 0, 0.06), "marble", bevel=0.02)
            m.box((0.1, 0.11, 0.025), (side * 0.07, 0, 0.11), "gold", bevel=0.006)
    with m.anim("body", (0, 0, 0.12)):
        m.box((0.28, 0.18, 0.22), (0, 0, 0.24), "marble", bevel=0.04)
        m.box((0.3, 0.2, 0.03), (0, 0, 0.35), "gold", bevel=0.01)
        m.box((0.15, 0.13, 0.12), (0, -0.01, 0.42), "marble", bevel=0.03)
        m.box((0.16, 0.02, 0.03), (0, -0.075, 0.43), "glow_gold", bevel=0.005)
        m.crystal((0, -0.095, 0.25), 0.07, 0.03, "crystal", tilt=(90, 0))
        m.torus(0.06, 0.008, (0, -0.092, 0.25), "gold", rot=(90, 0, 0), seg=12, rseg=4)
    for side, name in ((-1, "arml"), (1, "armr")):
        with m.anim(name, (side * 0.17, 0, 0.32)):
            m.sphere(0.05, (side * 0.18, 0, 0.33), "gold", seg=10, rings=6)
            m.box((0.08, 0.08, 0.16), (side * 0.18, 0, 0.23), "marble", bevel=0.025)
            m.box((0.1, 0.1, 0.08), (side * 0.18, -0.01, 0.12), "marble", bevel=0.025)
    m.light((0, -0.15, 0.4), "ffd84a", 0.4, 1.5)
