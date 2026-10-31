"""Crabe des marées."""
import math  # noqa: F401
from characters._monster import eyes, wing, spine_chain  # noqa: F401
FLAT_PALETTE = True

EXTENT = 0.26


def build(m):
    m.ao_height = 0.1
    with m.anim("body", (0, 0, 0.08)):
        m.sphere(0.13, (0, 0, 0.08), "shell_red", seg=14, rings=8, hemi=True, scale=(1.2, 0.95, 0.75))
        m.cyl(0.13, 0.03, (0, 0, 0.06), "scale_belly", seg=14, scale=(1.2, 0.95, 1))
        for sx in (-1, 1):
            m.rod((sx * 0.04, -0.08, 0.12), (sx * 0.05, -0.1, 0.19), 0.008, "shell_red", seg=4)
            m.sphere(0.018, (sx * 0.05, -0.1, 0.2), "dark", seg=6, rings=4)
            for k in range(3):
                y = -0.04 + k * 0.05
                m.rod((sx * 0.12, y, 0.07), (sx * 0.2, y, 0.0), 0.012, "shell_red", seg=4)
    for side, name in ((-1, "arml"), (1, "armr")):
        with m.anim(name, (side * 0.1, -0.08, 0.1)):
            m.rod((side * 0.1, -0.08, 0.1), (side * 0.15, -0.16, 0.08), 0.018, "shell_red", seg=5)
            m.sphere(0.045, (side * 0.16, -0.19, 0.09), "shell_red", seg=10, rings=6, scale=(0.8, 1.2, 0.8))
            m.cyl(0.015, 0.05, (side * 0.15, -0.23, 0.11), "shell_red", r2=0.0, rot=(80, 0, 0), seg=5)
