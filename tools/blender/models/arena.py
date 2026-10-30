"""Arène (4 × 4) : amphithéâtre circulaire à arcades sur deux niveaux,
piste de sable, portail et bannières."""
import math

EXTENT = 4.0


def build(m):
    z = m.flagstone_plinth(3.94, 3.94, mat="stone_warm", curb="stone_dark")
    m.ao_height = 1.2
    m.cyl(1.25, 0.04, (0, 0, z), "straw", seg=32)
    m.torus(1.25, 0.03, (0, 0, z + 0.04), "stone_dark", seg=32, rseg=4)
    n = 16
    R = 1.6
    for i in range(n):
        a = 2 * math.pi * i / n
        x, y = math.cos(a) * R, math.sin(a) * R
        if abs(a - 3 * math.pi / 2) < 0.2:
            continue
        m.box((0.12, 0.32, 0.75), (x, y, z + 0.37), "stone_warm", rot=(0, 0, math.degrees(a)), bevel=0.02)
        m.box((0.1, 0.3, 0.55), (x * 1.0, y * 1.0, z + 0.75 + 0.28), "stone", rot=(0, 0, math.degrees(a)), bevel=0.02)
    for lvl, zz in enumerate((z + 0.75, z + 1.32)):
        for i in range(n):
            a0, a1 = 2 * math.pi * i / n, 2 * math.pi * (i + 1) / n
            m.rod((math.cos(a0) * R, math.sin(a0) * R, zz), (math.cos(a1) * R, math.sin(a1) * R, zz), 0.09, "stone_warm" if lvl == 0 else "stone", seg=6)
    # Gradins
    for k in range(3):
        m.torus(1.42 - k * 0.0, 0.08, (0, 0, z + 0.2 + k * 0.15), "stone", seg=32, rseg=4, arc=300)
    # Portail
    for sx in (-1, 1):
        m.box((0.2, 0.3, 1.2), (sx * 0.3, -R, z + 0.6), "stone", bevel=0.03)
    m.box((0.85, 0.34, 0.2), (0, -R, z + 1.25), "stone_warm", bevel=0.03)
    m.torus(0.22, 0.05, (0, -R - 0.12, z + 0.85), "stone_dark", rot=(90, 0, 0), seg=12, rseg=5, arc=180)
    for k in range(5):
        m.box((0.02, 0.02, 0.6), (-0.16 + k * 0.08, -R - 0.12, z + 0.3), "iron", bevel=0)
    # Bannières sur le pourtour
    for i in range(4):
        a = 2 * math.pi * i / 4 + math.pi / 4
        m.banner((math.cos(a) * R, math.sin(a) * R, z + 1.38), 0.8, "cloth_red", rot_z=math.degrees(a))
    # Mannequins / cibles au centre
    m.cyl(0.25, 0.04, (0, 0, z + 0.04), "stone_dark", seg=16)
    m.box((0.3, 0.06, 0.4), (0, 0, z + 0.28), "wood", bevel=0.02)
    m.cyl(0.13, 0.03, (0, -0.04, z + 0.32), "cloth_red", rot=(90, 0, 0), seg=14)
    with m.tier(1):
        for sx in (-1, 1):
            m.brazier((sx * 0.6, -1.85, z))
    with m.tier(2):
        m.torus(R, 0.03, (0, 0, z + 1.42), "gold", seg=32, rseg=4)
    with m.tier(3):
        m.crystal_cluster((1.6, 1.6, z), 0.4, "crystal")
