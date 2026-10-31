"""Chimère de cristal (fusion) : carapace de roche, ailes de cristal, queue à pointes."""
import math  # noqa: F401
from characters._monster import eyes, wing, spine_chain

EXTENT = 0.3
FLAT_PALETTE = True


def build(m):
    m.ao_height = 0.1
    for side, name in ((-1, "legl"), (1, "legr")):
        with m.anim(name, (side * 0.07, 0, 0.1)):
            m.rod((side * 0.07, 0, 0.1), (side * 0.09, -0.02, 0.0), 0.025, "rock", seg=6)
    with m.anim("body", (0, 0, 0.1)):
        m.sphere(0.12, (0, 0.02, 0.16), "rock_light", seg=12, rings=8, scale=(1, 1.2, 0.9), smooth=False)
        m.sphere(0.08, (0, -0.13, 0.22), "fur_violet", seg=12, rings=8)
        eyes(m, 0, -0.2, 0.24, r=0.017, gap=0.035, mat="eye_glow", glint=False)
        for sx in (-1, 1):
            m.crystal((sx * 0.05, -0.12, 0.28), 0.1, 0.02, "crystal", tilt=(-25, sx * 20))
        for i in range(4):
            m.crystal((0, 0.0 + i * 0.05, 0.26 - i * 0.02), 0.09, 0.02, "crystal_violet", tilt=(-30, 0))
    for side, name in ((-1, "wingl"), (1, "wingr")):
        with m.anim(name, (side * 0.08, 0.02, 0.22)):
            wing(m, side, (side * 0.08, 0.02, 0.22), 0.22, 0.15, mat="crystal", bone="rock")
    with m.anim("tail", (0, 0.13, 0.12)):
        spine_chain(m, [(0, 0.16, 0.11), (0.02, 0.23, 0.09)], [0.04, 0.028], "rock_light")
        m.crystal((0.03, 0.27, 0.08), 0.1, 0.025, "crystal", tilt=(-80, 0))
