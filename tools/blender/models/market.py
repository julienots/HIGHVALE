"""Marché : étals à auvents rayés, marchandises colorées, guirlandes de fanions."""
import math

EXTENT = 3.0


def stall(m, x, y, z, cloth_a, cloth_b, goods):
    for sx in (-1, 1):
        for sy in (-1, 1):
            m.box((0.06, 0.06, 0.95 if sy > 0 else 0.8), (x + sx * 0.36, y + sy * 0.27, z + (0.475 if sy > 0 else 0.4)), "wood", bevel=0.01)
    m.box((0.82, 0.5, 0.28), (x, y, z + 0.14), "wood_light", bevel=0.02)
    m.box((0.86, 0.54, 0.04), (x, y, z + 0.3), "wood_dark", bevel=0.01)
    for i in range(6):
        m.box((0.15, 0.68, 0.03), (x - 0.375 + i * 0.15, y - 0.02, z + 0.92), cloth_a if i % 2 else cloth_b, rot=(-14, 0, 0), bevel=0.005)
    for i in range(6):
        m.box((0.15, 0.03, 0.12), (x - 0.375 + i * 0.15, y - 0.37, z + 0.79), cloth_a if i % 2 else cloth_b, bevel=0)
    for i, g in enumerate(goods):
        gx = x - 0.25 + (i % 3) * 0.25
        gy = y - 0.1 + (i // 3) * 0.2
        if g == "fruit":
            for k in range(4):
                m.sphere(0.045, (gx + (k % 2) * 0.08 - 0.04, gy + (k // 2) * 0.08 - 0.04, z + 0.36), m.rng.choice(["cloth_red", "straw", "moss"]), seg=8, rings=5)
        elif g == "crystal":
            m.crystal((gx, gy, z + 0.32), 0.2, 0.04, "crystal")
        elif g == "pot":
            m.cyl(0.06, 0.12, (gx, gy, z + 0.32), "bronze", r2=0.04, seg=10)
        elif g == "cloth":
            m.box((0.18, 0.14, 0.06), (gx, gy, z + 0.35), m.rng.choice(["cloth_blue", "roof_violet", "cloth_red"]), bevel=0.01)
        elif g == "gold":
            for k in range(3):
                m.cyl(0.05, 0.02, (gx, gy, z + 0.32 + k * 0.022), "gold", seg=10)


def build(m):
    z = m.flagstone_plinth(2.94, 2.94, mat="stone_warm", curb="stone_dark")
    stall(m, -0.75, 0.6, z, "cloth_red", "cloth_cream", ["fruit", "fruit", "pot", "fruit", "cloth", "pot"])
    stall(m, 0.65, 0.75, z, "cloth_blue", "cloth_cream", ["crystal", "crystal", "gold", "cloth", "crystal", "gold"])
    stall(m, 0.75, -0.55, z, "straw", "cloth_red", ["cloth", "cloth", "pot", "fruit", "cloth", "pot"])
    # Puits central
    m.cyl(0.32, 0.32, (-0.55, -0.55, z), "stone", seg=12, smooth=False)
    m.cyl(0.25, 0.02, (-0.55, -0.55, z + 0.3), "water", seg=12)
    for sx in (-1, 1):
        m.box((0.06, 0.06, 0.65), (-0.55 + sx * 0.28, -0.55, z + 0.6), "wood", bevel=0.01)
    m.prism(0.7, 0.5, 0.25, (-0.55, -0.55, z + 0.93), "roof_red")
    m.rod((-0.55 - 0.28, -0.55, z + 0.82), (-0.55 + 0.28, -0.55, z + 0.82), 0.025, "wood_dark", seg=6)
    # Guirlande de fanions
    pts = [(-1.3, -1.25), (-1.3, 1.25), (1.3, 1.25)]
    for p in pts:
        m.cyl(0.035, 1.35, (p[0], p[1], z), "wood_dark", seg=6)
        m.sphere(0.05, (p[0], p[1], z + 1.37), "gold", seg=8, rings=5)
    cols = ["cloth_red", "straw", "cloth_blue", "moss"]
    for (a, b) in [(pts[0], pts[1]), (pts[1], pts[2])]:
        for k in range(9):
            t = (k + 0.5) / 9
            x, y = a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t
            sag = 1.28 - math.sin(t * math.pi) * 0.18
            ang = math.degrees(math.atan2(b[1] - a[1], b[0] - a[0]))
            m.poly([(-0.06, 0, 0), (0.06, 0, 0), (0, 0, -0.13)], [(0, 1, 2)], (x, y, z + sag), cols[k % 4], rot=(0, 0, ang))
        m.rod((a[0], a[1], z + 1.3), (b[0], b[1], z + 1.3), 0.006, "cloth_cream", seg=3)
    m.crate((-1.15, -1.1, z), 0.28, 12)
    m.sack((-0.95, -1.15, z), 0.12)
    m.barrel((1.2, -1.15, z), r=0.12, h=0.3)
    with m.tier(1):
        m.lantern_post((0.0, -1.2, z), 1.0)
    with m.tier(2):
        m.banner((1.3, -0.1, z), 1.3, "cloth_red", rot_z=90)
    with m.tier(3):
        m.sphere(0.12, (-0.55, -0.55, z + 1.2), "gold", seg=12, rings=8)
