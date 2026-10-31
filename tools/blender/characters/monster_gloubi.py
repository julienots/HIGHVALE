"""Créature : gloubi."""
import math  # noqa: F401
from characters._monster import eyes, wing, spine_chain  # noqa: F401

EXTENT = 0.22
FLAT_PALETTE = True


def build(m):
    m.ao_height = 0.1
    with m.anim("body", (0, 0, 0), bob=0.0):
        m.sphere(0.16, (0, 0, 0.0), "slime", seg=18, rings=10, hemi=True, scale=(1.1, 1.0, 1.05))
        m.sphere(0.07, (0, 0, 0.16), "slime", seg=12, rings=8, scale=(1, 1, 0.9))
        m.sphere(0.03, (0.05, -0.06, 0.12), "cloth_white", seg=8, rings=5)
        for i in range(4):
            m.sphere(0.015, (m.rng.uniform(-0.08, 0.08), m.rng.uniform(-0.05, 0.05), m.rng.uniform(0.03, 0.1)), "glow_teal", seg=6, rings=4)
        eyes(m, 0, -0.15, 0.09, r=0.026, gap=0.05)
        m.torus(0.025, 0.006, (0, -0.16, 0.04), "dark", rot=(90, 0, 0), seg=10, rseg=3, arc=180)
