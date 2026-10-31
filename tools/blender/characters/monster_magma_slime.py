"""Gelée de magma (fusion) : gelée incandescente à croûte de roche."""
import math  # noqa: F401
from characters._monster import eyes

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    m.ao_height = 0.1
    with m.anim("body", (0, 0, 0)):
        m.sphere(0.17, (0, 0, 0.0), "fire", seg=18, rings=10, hemi=True, scale=(1.1, 1.0, 1.05))
        for i in range(6):
            a = math.tau * i / 6
            m.rock((math.cos(a) * 0.12, math.sin(a) * 0.1, 0.1 + (i % 2) * 0.04), (0.05, 0.045, 0.035), "rock")
        m.rock((0, 0.02, 0.17), (0.06, 0.05, 0.04), "rock")
        eyes(m, 0, -0.16, 0.09, r=0.026, gap=0.05, mat="dark")
        m.torus(0.025, 0.006, (0, -0.165, 0.045), "dark", rot=(90, 0, 0), seg=10, rseg=3, arc=180)
    m.light((0, 0, 0.2), "ff7a30", 0.6, 1.6)
