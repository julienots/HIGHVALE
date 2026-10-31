"""Créature : glow_eel."""
import math  # noqa: F401
from characters._monster import eyes, wing, spine_chain  # noqa: F401

EXTENT = 0.3
FLAT_PALETTE = True


def build(m):
    m.ao_height = 0.1
    m.cyl(0.16, 0.012, (0, 0.04, 0), "water", seg=18)
    with m.anim("body", (0, 0, 0.0)):
        pts = [(0, 0.08, 0.02), (0.03, 0.05, 0.09), (0.03, 0.0, 0.17), (-0.01, -0.04, 0.24), (-0.03, -0.07, 0.3)]
        spine_chain(m, pts, [0.05, 0.047, 0.044, 0.042, 0.05], "eel_blue")
        for p in pts[:4]:
            m.sphere(0.012, (p[0] + 0.03, p[1] - 0.03, p[2]), "glow_teal", seg=6, rings=4)
        m.sphere(0.055, (-0.03, -0.11, 0.32), "eel_blue", seg=12, rings=8, scale=(0.9, 1.2, 0.85))
        eyes(m, -0.03, -0.16, 0.34, r=0.014, gap=0.03, mat="eye_glow", glint=False)
        m.poly([(0, 0, 0), (0, 0.06, 0.06), (0, 0.1, -0.02)], [(0, 1, 2), (2, 1, 0)], (-0.03, -0.08, 0.35), "glow_teal")
        for sx in (-1, 1):
            m.poly([(0, 0, 0), (sx * 0.06, 0.02, 0.03), (sx * 0.05, 0.03, -0.03)], [(0, 1, 2), (2, 1, 0)], (0.0, -0.02, 0.2), "cloth_teal")
    m.light((0, 0, 0.25), "7ff5e4", 0.4, 1.5)
