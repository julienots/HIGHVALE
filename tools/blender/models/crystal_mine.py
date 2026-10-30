"""Mine cristalline : derrick en charpente, poulie et foreuse animées,
puits lumineux, gerbes de cristaux et cabane de contrôle."""
import math

EXTENT = 3.0


def build(m):
    z = m.flagstone_plinth(2.94, 2.94, mat="stone_dark", curb="stone_dark")
    m.ao_height = 1.2
    dx, dy = -0.25, 0.15
    # Puits lumineux
    m.cyl(0.52, 0.16, (dx, dy, z), "stone", seg=16, smooth=False)
    m.cyl(0.4, 0.17, (dx, dy, z + 0.005), "dark", seg=16)
    m.torus(0.42, 0.03, (dx, dy, z + 0.165), "crystal", seg=20, rseg=5)
    m.light((dx, dy, z + 0.4), "62c8ff", 1.6, 4.5)
    # Derrick
    H = 2.25
    base, topw = 0.62, 0.17
    legs = [(sx, sy) for sx in (-1, 1) for sy in (-1, 1)]
    for sx, sy in legs:
        m.rod((dx + sx * base, dy + sy * base, z), (dx + sx * topw, dy + sy * topw, z + H), 0.05, "wood", seg=6)
        m.box((0.16, 0.16, 0.1), (dx + sx * base, dy + sy * base, z + 0.05), "stone", bevel=0.02)
    for lvl in range(3):
        t0, t1 = lvl / 3, (lvl + 1) / 3
        r0, r1 = base + (topw - base) * t0, base + (topw - base) * t1
        z0, z1 = z + H * t0, z + H * t1
        for face in range(4):
            a0 = [(-1, -1), (1, -1), (1, 1), (-1, 1)][face]
            a1 = [(-1, -1), (1, -1), (1, 1), (-1, 1)][(face + 1) % 4]
            m.rod((dx + a0[0] * r0, dy + a0[1] * r0, z0 + 0.05), (dx + a1[0] * r1, dy + a1[1] * r1, z1 - 0.05), 0.022, "wood_dark", seg=4)
            m.rod((dx + a1[0] * r0, dy + a1[1] * r0, z0 + 0.05), (dx + a0[0] * r1, dy + a0[1] * r1, z1 - 0.05), 0.022, "wood_dark", seg=4)
            m.rod((dx + a0[0] * r1, dy + a0[1] * r1, z1), (dx + a1[0] * r1, dy + a1[1] * r1, z1), 0.03, "wood", seg=4)
    pz = z + H * 0.36
    rp = base + (topw - base) * 0.36
    m.box((rp * 2 + 0.2, rp * 2 + 0.2, 0.05), (dx, dy, pz), "wood_light", bevel=0.01)
    m.box((0.5, 0.5, 0.18), (dx, dy, z + H + 0.09), "iron", bevel=0.03)
    with m.anim("pulley", (dx, dy, z + H + 0.35), spin=("Z", 120)):
        m.spoked_wheel((dx, dy, z + H + 0.35), 0.24, (90, 0, 0), "iron", spokes=6, thick=0.05)
    # Foreuse
    with m.anim("drill", (dx, dy, z), spin=("Y", 260)):
        m.cyl(0.05, H - 0.1, (dx, dy, z + 0.12), "iron", seg=8)
        for k in range(6):
            m.torus(0.07, 0.018, (dx, dy, z + 0.4 + k * 0.28), "gold", seg=10, rseg=4)
        m.cyl(0.16, 0.38, (dx, dy, z - 0.05), "gold", r2=0.0, seg=8, rot=(180, 0, 0))
    m.box((0.14, 0.4, 0.32), (dx, dy + 0.0, pz + 0.18), "iron", bevel=0.03)
    # Cristaux
    m.crystal_cluster((dx - 0.75, dy - 0.75, z), 0.75, "crystal", 6)
    m.crystal_cluster((dx + 0.95, dy + 0.85, z), 0.55, "crystal_violet", 5)
    m.crystal_cluster((dx - 0.85, dy + 0.9, z), 0.5, "crystal", 4)
    m.light((dx - 0.75, dy - 0.75, z + 0.6), "62c8ff", 0.9, 3.0)
    # Cabane de contrôle
    hx, hy = 0.9, -0.75
    for a, b in [((hx - 0.38, hy - 0.32), (hx + 0.38, hy - 0.32)), ((hx + 0.38, hy - 0.32), (hx + 0.38, hy + 0.32)),
                 ((hx + 0.38, hy + 0.32), (hx - 0.38, hy + 0.32)), ((hx - 0.38, hy + 0.32), (hx - 0.38, hy - 0.32))]:
        m.brick_wall(a, b, z, 0.58, thick=0.12, mat="stone", course=0.145, brick=0.26)
    m.box((0.66, 0.54, 0.58), (hx, hy, z + 0.29), "stone_dark", bevel=0)
    m.gable_roof((hx, hy, z + 0.58), 0.76, 0.64, 0.38, "roof_slate", overhang=0.1, rows=4, rot_z=90)
    m.door((hx - 0.1, hy - 0.33, z), 0, w=0.24, h=0.4, arch=False, frame="wood_dark")
    m.window((hx + 0.39, hy, z + 0.2), 90, w=0.2, h=0.22)
    with m.anim("gear", (hx + 0.2, hy - 0.37, z + 0.38), spin=("Z", -90)):
        m.spoked_wheel((hx + 0.2, hy - 0.37, z + 0.38), 0.12, (90, 0, 0), "bronze", spokes=4, thick=0.035)
    # Wagonnet de cristaux
    m.box((0.36, 0.28, 0.2), (0.15, -1.15, z + 0.18), "iron", bevel=0.03)
    for sx in (-1, 1):
        m.cyl(0.06, 0.03, (0.15 + sx * 0.14, -1.0, z + 0.06), "iron", rot=(90, 0, 0), seg=8)
        m.cyl(0.06, 0.03, (0.15 + sx * 0.14, -1.33, z + 0.06), "iron", rot=(90, 0, 0), seg=8)
    for k in range(4):
        m.crystal((0.15 + m.rng.uniform(-0.1, 0.1), -1.15 + m.rng.uniform(-0.07, 0.07), z + 0.26), 0.2, 0.045, "crystal",
                  tilt=(m.rng.uniform(-30, 30), m.rng.uniform(-30, 30)))
    with m.tier(1):
        m.crystal_cluster((1.15, 0.1, z), 0.4, "crystal", 4)
        m.torch((-1.2, -0.35, z), 0.7, tier=1)
    with m.tier(2):
        for sx, sy in legs:
            m.box((0.13, 0.13, 0.04), (dx + sx * (base - 0.12), dy + sy * (base - 0.12), z + 0.38), "iron", bevel=0)
        m.banner((1.25, 1.2, z), 1.3, "cloth_blue")
    with m.tier(3):
        m.crystal_cluster((dx + 0.1, dy - 0.95, z), 0.6, "crystal_teal", 5)
        m.light((dx + 0.1, dy - 0.95, z + 0.5), "7ff5e4", 0.8, 3.0, 3)
