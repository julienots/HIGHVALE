"""Créature : rock_beetle."""
import math  # noqa: F401
from characters._monster import eyes, wing, spine_chain  # noqa: F401

EXTENT = 0.26
FLAT_PALETTE = True


def build(m):
    m.ao_height = 0.1
    with m.anim("body", (0, 0, 0.08), bob=0.0):
        m.sphere(0.15, (0, 0.02, 0.07), "rock_light", seg=12, rings=8, hemi=True, scale=(1.0, 1.25, 0.9), smooth=False)
        m.box((0.01, 0.34, 0.1), (0, 0.03, 0.12), "rock", bevel=0.004)
        for i in range(5):
            m.rock((m.rng.uniform(-0.09, 0.09), m.rng.uniform(-0.08, 0.15), 0.14), (0.04, 0.04, 0.03), "rock")
        m.sphere(0.07, (0, -0.17, 0.07), "stone_dark", seg=10, rings=6)
        m.crystal((0, -0.22, 0.09), 0.12, 0.022, "crystal", tilt=(-55, 0))
        eyes(m, 0, -0.22, 0.08, r=0.014, gap=0.035, mat="eye_glow", glint=False)
        for sx in (-1, 1):
            for k in range(3):
                y = -0.08 + k * 0.1
                m.rod((sx * 0.1, y, 0.06), (sx * 0.19, y - 0.02, 0.0), 0.012, "stone_dark", seg=5)
