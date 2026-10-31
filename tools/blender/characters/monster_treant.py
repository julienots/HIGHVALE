"""Sylvain ancien : arbre vivant au visage d'écorce."""
import math  # noqa: F401
from characters._monster import eyes, wing, spine_chain  # noqa: F401
FLAT_PALETTE = True

EXTENT = 0.36


def build(m):
    m.ao_height = 0.1
    for side, name in ((-1, "legl"), (1, "legr")):
        with m.anim(name, (side * 0.06, 0, 0.1)):
            m.rod((side * 0.06, 0, 0.1), (side * 0.09, -0.02, 0.0), 0.035, "bark", seg=6)
            for k in range(3):
                m.rod((side * 0.09, -0.02, 0.01), (side * 0.09 + (k - 1) * 0.04, -0.07, 0.0), 0.012, "bark", seg=4)
    with m.anim("body", (0, 0, 0.1)):
        m.cyl(0.11, 0.3, (0, 0, 0.08), "bark", r2=0.08, seg=10, smooth=False)
        eyes(m, 0, -0.1, 0.3, r=0.016, gap=0.035, mat="glow_gold", glint=False)
        m.box((0.06, 0.02, 0.015), (0, -0.1, 0.24), "dark", bevel=0.004)
        for i in range(6):
            a = math.tau * i / 6
            m.sphere(0.09, (math.cos(a) * 0.1, math.sin(a) * 0.08, 0.46 + (i % 2) * 0.04), "leaf" if i % 3 else "leaf_dark", seg=8, rings=5, smooth=False)
        m.sphere(0.11, (0, 0, 0.52), "leaf", seg=8, rings=5, smooth=False)
        m.sphere(0.03, (0.06, -0.08, 0.5), "mushroom_pink", seg=6, rings=4)
    for side, name in ((-1, "arml"), (1, "armr")):
        with m.anim(name, (side * 0.1, 0, 0.33)):
            m.rod((side * 0.1, 0, 0.33), (side * 0.2, -0.03, 0.2), 0.022, "bark", seg=5)
            m.sphere(0.035, (side * 0.21, -0.03, 0.19), "leaf", seg=6, rings=4)
