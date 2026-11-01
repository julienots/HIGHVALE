"""Canon de pierre (2 × 2) : bastion bas en pierre, affût de bois tournant et
gros canon de bronze, boulets empilés."""
import math
from models._defense import square_ring

EXTENT = 2.2


def build(m):
    z = m.flagstone_plinth(1.94, 1.94, mat="stone_dark", curb="stone_dark")
    m.ao_height = 0.8
    m.box((1.5, 1.5, 0.35), (0, 0, z + 0.175), "stone", bevel=0.04)
    for k in range(3):
        m.box((1.52, 1.52, 0.03), (0, 0, z + 0.08 + k * 0.1), "stone_dark", bevel=0.005)
    square_ring(m, 0, 0, 0.72, z + 0.35, "stone", 0.14, 0.18)
    top = z + 0.35
    with m.anim("turret", (0, 0, top)):
        m.cyl(0.45, 0.08, (0, 0, top), "wood_dark", seg=16, smooth=False)
        for sx in (-1, 1):
            m.box((0.08, 0.5, 0.26), (sx * 0.22, 0.0, top + 0.21), "wood", bevel=0.02)
            m.spoked_wheel((sx * 0.3, 0.1, top + 0.16), 0.15, (0, 90, 0), "wood", spokes=6, thick=0.04)
        # Fût pointé vers l'avant (-y), légèrement relevé
        m.cyl(0.15, 0.9, (0, 0.15, top + 0.36), "bronze", r2=0.12, rot=(-100, 0, 0), seg=14)
        m.torus(0.155, 0.03, (0, -0.1, top + 0.32), "gold", rot=(80, 0, 0), seg=14, rseg=4)
        m.torus(0.14, 0.035, (0, -0.68, top + 0.25), "bronze", rot=(80, 0, 0), seg=14, rseg=4)
        m.sphere(0.12, (0, 0.2, top + 0.38), "bronze", seg=10, rings=6)
        m.cyl(0.1, 0.02, (0, -0.73, top + 0.24), "dark", rot=(80, 0, 0), seg=12)
    for (x, y) in [(0.55, 0.55), (0.48, 0.62), (0.62, 0.48), (0.55, 0.55)]:
        pass
    for i, (x, y, zz) in enumerate([(0.52, 0.5, 0.0), (0.64, 0.5, 0.0), (0.58, 0.6, 0.0), (0.58, 0.54, 0.09)]):
        m.sphere(0.06, (x, y, top + 0.06 + zz), "iron", seg=8, rings=5)
    with m.tier(1):
        m.barrel((-0.55, 0.55, top), 0.1, 0.24)
    with m.tier(2):
        for sx in (-1, 1):
            for sy in (-1, 1):
                m.cyl(0.06, 0.12, (sx * 0.72, sy * 0.72, top + 0.14), "gold", r2=0.0, seg=6)
    with m.tier(3):
        m.banner((-0.75, -0.75, z), 1.0, "cloth_blue", "gold", rot_z=-45)
