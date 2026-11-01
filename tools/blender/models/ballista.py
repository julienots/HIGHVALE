"""Baliste (2 × 2) : plate-forme de pierre et de bois, grand arc d'acier et
carreau géant, longue portée."""
import math

EXTENT = 2.3


def build(m):
    z = m.flagstone_plinth(1.94, 1.94, mat="stone", curb="stone_dark")
    m.ao_height = 0.9
    m.cyl(0.75, 0.3, (0, 0, z), "stone", r2=0.7, seg=8, smooth=False)
    m.cyl(0.78, 0.05, (0, 0, z + 0.3), "stone_dark", seg=8, smooth=False)
    top = z + 0.35
    with m.anim("turret", (0, 0, top)):
        m.cyl(0.18, 0.25, (0, 0, top), "wood_dark", seg=10)
        m.box((0.16, 1.2, 0.12), (0, -0.1, top + 0.35), "wood", bevel=0.02)
        for sx in (-1, 1):
            m.rod((sx * 0.05, -0.55, top + 0.35), (sx * 0.62, -0.35, top + 0.42), 0.035, "steel_dark", seg=6, r2=0.02)
            m.rod((sx * 0.62, -0.35, top + 0.42), (sx * 0.06, 0.3, top + 0.38), 0.006, "cloth_white", seg=3)
        m.cyl(0.02, 1.0, (0, 0.25, top + 0.44), "wood_light", rot=(90, 0, 0), seg=6)
        m.cyl(0.045, 0.14, (0, -0.8, top + 0.44), "steel", r2=0.0, rot=(90, 0, 0), seg=4)
        for sx in (-1, 1):
            m.box((0.02, 0.08, 0.06), (sx * 0.03, 0.66, top + 0.44), "cloth_red", bevel=0)
        m.spoked_wheel((0.12, 0.4, top + 0.35), 0.1, (0, 90, 0), "iron", spokes=5, thick=0.03)
    m.light((0, 0, top + 0.6), "ffd890", 0.3, 2.0)
    for k in range(3):
        m.cyl(0.02, 0.7, (0.75, -0.3 + k * 0.08, z + 0.06), "wood_light", rot=(0, 90, 10), seg=5)
    with m.tier(1):
        m.crate((-0.7, 0.7, z), 0.24, 15)
    with m.tier(2):
        m.torch((0.75, 0.75, z), 0.7)
    with m.tier(3):
        m.banner((-0.75, -0.75, z), 1.1, "cloth_purple", "gold", rot_z=-45)
