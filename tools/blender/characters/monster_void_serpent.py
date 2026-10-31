"""Serpent du Néant, gardien de l'Abîme."""
import math  # noqa: F401
from characters._monster import eyes, wing, spine_chain  # noqa: F401
FLAT_PALETTE = True

EXTENT = 0.32


def build(m):
    m.ao_height = 0.1
    with m.anim("body", (0, 0, 0.0)):
        for i in range(14):
            a = i * 0.55
            r = 0.13 - i * 0.004
            z = 0.04 + i * 0.022
            m.sphere(0.045 - i * 0.0015, (math.cos(a) * r, math.sin(a) * r, z), "void_skin", seg=10, rings=6)
            if i % 2 == 0:
                m.sphere(0.012, (math.cos(a) * (r + 0.035), math.sin(a) * (r + 0.035), z + 0.01), "shadow_glow", seg=6, rings=4)
        m.sphere(0.06, (0.02, -0.06, 0.38), "void_skin", seg=12, rings=8, scale=(1, 1.3, 0.8))
        eyes(m, 0.02, -0.12, 0.4, r=0.013, gap=0.028, mat="shadow_glow", glint=False)
        for sx in (-1, 1):
            m.cyl(0.012, 0.07, (0.02 + sx * 0.03, -0.04, 0.42), "gold", r2=0.0, rot=(-50, sx * 20, 0), seg=5)
    m.light((0, 0, 0.3), "a050ff", 0.6, 1.8)
