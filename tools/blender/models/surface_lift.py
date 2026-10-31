"""Ascenseur de surface (2 × 2) : tour de charpente et d'acier qui monte vers
la voûte, cabine animée, grande roue de treuil, contrepoids, quai de
chargement et bannière des explorateurs."""
import math

EXTENT = 3.6


def build(m):
    z = m.flagstone_plinth(1.94, 1.94, mat="stone", curb="stone_dark")
    m.ao_height = 1.0
    H = 3.2
    tx, ty = -0.25, 0.25
    s = 0.42
    # Montants et entretoises
    for sx, sy in [(-1, -1), (1, -1), (1, 1), (-1, 1)]:
        m.box((0.16, 0.16, 0.12), (tx + sx * s, ty + sy * s, z + 0.06), "stone_dark", bevel=0.02)
        m.box((0.08, 0.08, H), (tx + sx * s, ty + sy * s, z + 0.12 + H / 2), "wood", bevel=0.012)
    for k in range(5):
        zz = z + 0.4 + k * 0.62
        for face in range(4):
            c = [(-1, -1), (1, -1), (1, 1), (-1, 1)]
            a0, a1 = c[face], c[(face + 1) % 4]
            m.rod((tx + a0[0] * s, ty + a0[1] * s, zz), (tx + a1[0] * s, ty + a1[1] * s, zz), 0.022, "iron", seg=4)
            if face in (1, 2):
                m.rod((tx + a0[0] * s, ty + a0[1] * s, zz), (tx + a1[0] * s, ty + a1[1] * s, zz + 0.6), 0.016, "wood_dark", seg=4)
    # Tête : poutre et grande roue
    m.box((1.1, 0.22, 0.14), (tx, ty, z + H + 0.18), "iron", bevel=0.02)
    with m.anim("wheel", (tx, ty, z + H + 0.48), spin=("Z", 70)):
        m.spoked_wheel((tx, ty, z + H + 0.48), 0.32, (90, 0, 0), "bronze", spokes=8, thick=0.05)
    m.cone_roof((tx, ty, z + H + 0.85), 0.36, 0.38, "roof_teal", rings=4, finial="gold")
    for sx in (-1, 1):
        m.rod((tx + sx * 0.3, ty, z + H + 0.25), (tx + sx * 0.3, ty, z + H + 0.85), 0.025, "wood_dark", seg=4)
    # Cabine qui monte et descend
    with m.anim("cabin", (tx, ty, z + 1.4), bob=0.9):
        m.rod((tx, ty, z + H + 0.2), (tx, ty, z + 1.4 + 0.52), 0.012, "iron", seg=4)
        m.box((0.62, 0.62, 0.05), (tx, ty, z + 1.0), "wood_light", bevel=0.01)
        m.box((0.62, 0.62, 0.05), (tx, ty, z + 1.52), "iron", bevel=0.01)
        for sx, sy in [(-1, -1), (1, -1), (1, 1), (-1, 1)]:
            m.rod((tx + sx * 0.29, ty + sy * 0.29, z + 1.0), (tx + sx * 0.29, ty + sy * 0.29, z + 1.52), 0.016, "bronze", seg=4)
        for sy in (-1, 1):
            m.rod((tx - 0.29, ty + sy * 0.29, z + 1.22), (tx + 0.29, ty + sy * 0.29, z + 1.22), 0.01, "bronze", seg=4)
        m.crate((tx + 0.1, ty - 0.08, z + 1.03), 0.2, 15)
        m.sphere(0.05, (tx, ty, z + 1.45), "glow_gold", seg=8, rings=5)
    m.light((tx, ty, z + 2.0), "ffd84a", 1.0, 3.5)
    # Contrepoids
    with m.anim("counterweight", (tx + s + 0.12, ty, z + 2.2), bob=0.6):
        m.rod((tx + s + 0.12, ty, z + H + 0.2), (tx + s + 0.12, ty, z + 2.35), 0.01, "iron", seg=4)
        m.box((0.14, 0.22, 0.3), (tx + s + 0.12, ty, z + 2.2), "stone_dark", bevel=0.02)
    # Quai de chargement
    m.box((0.7, 0.55, 0.12), (0.55, -0.6, z + 0.06), "wood_light", bevel=0.015)
    for k in range(5):
        m.box((0.7, 0.012, 0.005), (0.55, -0.82 + k * 0.11, z + 0.122), "wood_dark", bevel=0)
    m.crate((0.4, -0.55, z + 0.12), 0.26, 10)
    m.crate((0.7, -0.68, z + 0.12), 0.22, -15)
    m.sack((0.72, -0.4, z + 0.12), 0.14)
    m.barrel((-0.75, -0.75, z), 0.13, 0.32)
    # Treuil à manivelle
    m.box((0.3, 0.2, 0.22), (0.7, 0.55, z + 0.11), "wood_dark", bevel=0.02)
    with m.anim("winch", (0.7, 0.55, z + 0.32), spin=("X", 90)):
        m.cyl(0.08, 0.32, (0.54, 0.55, z + 0.32), "iron", rot=(0, 90, 0), seg=10)
        m.torus(0.09, 0.012, (0.7, 0.55, z + 0.32), "bronze", rot=(0, 90, 0), seg=12, rseg=4)
    m.rod((0.7, 0.55, z + 0.32), (tx + 0.1, ty, z + H + 0.25), 0.008, "iron", seg=4)
    # Bannière des explorateurs
    m.banner((0.85, 0.2, z), 1.3, "cloth_green", "gold", rot_z=-30)
    with m.tier(1):
        m.lantern_post((-0.8, 0.85, z), 1.0)
    with m.tier(2):
        m.torch((0.2, -0.9, z), 0.7)
        m.spoked_wheel((-0.85, 0.1, z + 0.22), 0.2, (90, 0, 20), "wood", spokes=6, thick=0.04)
    with m.tier(3):
        m.crystal_cluster((0.85, 0.85, z), 0.3, "crystal_teal", 4)
