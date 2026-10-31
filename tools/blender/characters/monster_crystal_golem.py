"""Créature : crystal_golem."""
import math  # noqa: F401
from characters._monster import eyes, wing, spine_chain  # noqa: F401

EXTENT = 0.34
FLAT_PALETTE = True


def build(m):
    m.ao_height = 0.1
    for side, name in ((-1, "legl"), (1, "legr")):
        with m.anim(name, (side * 0.07, 0, 0.12)):
            m.box((0.08, 0.09, 0.12), (side * 0.07, 0, 0.06), "rock", bevel=0.02)
    with m.anim("body", (0, 0, 0.12)):
        m.box((0.26, 0.18, 0.22), (0, 0, 0.24), "rock_light", bevel=0.04)
        m.box((0.16, 0.13, 0.12), (0, -0.02, 0.41), "rock", bevel=0.03)
        eyes(m, 0, -0.088, 0.42, r=0.017, gap=0.035, mat="eye_glow", glint=False)
        m.crystal((0, -0.09, 0.24), 0.07, 0.03, "crystal", tilt=(90, 0))
        for sx in (-1, 1):
            m.crystal((sx * 0.13, 0.02, 0.33), 0.16, 0.035, "crystal", tilt=(0, sx * 25))
            m.crystal((sx * 0.08, 0.06, 0.36), 0.11, 0.028, "crystal_violet", tilt=(-20, sx * 15))
    for side, name in ((-1, "arml"), (1, "armr")):
        with m.anim(name, (side * 0.16, 0, 0.32)):
            m.box((0.08, 0.08, 0.16), (side * 0.17, 0, 0.24), "rock", bevel=0.025)
            m.box((0.1, 0.1, 0.08), (side * 0.17, -0.01, 0.13), "rock_light", bevel=0.025)
    m.light((0, -0.15, 0.3), "62c8ff", 0.5, 1.5)
