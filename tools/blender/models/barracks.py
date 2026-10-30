"""Caserne : fortin crénelé, tour d'angle, portail, cour d'entraînement,
mannequins de paille, râteliers et boucliers."""
import math

EXTENT = 3.0


def crenels(m, p0, p1, z, mat="stone"):
    dx, dy = p1[0] - p0[0], p1[1] - p0[1]
    L = math.hypot(dx, dy)
    n = max(2, round(L / 0.25))
    ang = math.degrees(math.atan2(dy, dx))
    for k in range(n):
        if k % 2 == 0:
            t = (k + 0.5) / n
            m.box((L / n - 0.02, 0.22, 0.16), (p0[0] + dx * t, p0[1] + dy * t, z + 0.08), mat, rot=(0, 0, ang), bevel=0.02)


def build(m):
    z = m.flagstone_plinth(2.94, 2.94, mat="stone", curb="stone_dark")
    # Corps de garde
    x0, x1, y0, y1, h = -1.3, 0.6, 0.15, 1.3, 1.0
    for a, b in [((x0, y0), (x1, y0)), ((x1, y0), (x1, y1)), ((x1, y1), (x0, y1)), ((x0, y1), (x0, y0))]:
        m.brick_wall(a, b, z, h, thick=0.22, mat="stone", course=0.17, brick=0.34)
        crenels(m, a, b, z + h)
    m.box((x1 - x0 - 0.2, y1 - y0 - 0.2, h), ((x0 + x1) / 2, (y0 + y1) / 2, z + h / 2), "stone_dark", bevel=0)
    m.box((x1 - x0 - 0.2, y1 - y0 - 0.2, 0.05), ((x0 + x1) / 2, (y0 + y1) / 2, z + h), "wood", bevel=0)
    m.door(((x0 + x1) / 2, y0 - 0.05, z), 0, w=0.5, h=0.62, frame="stone_dark")
    for wx in (-0.85, 0.25):
        m.window((wx, y0 - 0.05, z + 0.45), 0, w=0.12, h=0.3, frame="stone_dark")
    # Tour d'angle
    tx, ty = 1.0, 0.85
    m.box((0.75, 0.75, 1.6), (tx, ty, z + 0.8), "stone", bevel=0.03)
    for k in range(5):
        m.box((0.78, 0.78, 0.04), (tx, ty, z + 0.3 + k * 0.3), "stone_dark", bevel=0.01)
    for a, b in [((tx - 0.4, ty - 0.4), (tx + 0.4, ty - 0.4)), ((tx + 0.4, ty - 0.4), (tx + 0.4, ty + 0.4)),
                 ((tx + 0.4, ty + 0.4), (tx - 0.4, ty + 0.4)), ((tx - 0.4, ty + 0.4), (tx - 0.4, ty - 0.4))]:
        crenels(m, a, b, z + 1.6)
    m.window((tx, ty - 0.39, z + 1.0), 0, w=0.12, h=0.28, frame="stone_dark", arch=True)
    m.banner((tx, ty, z + 1.6), 0.9, "cloth_red")
    # Boucliers
    for i, sx in enumerate((-1.0, -0.45, 0.35)):
        m.cyl(0.13, 0.03, (sx, y0 - 0.13, z + 0.78), "cloth_red" if i % 2 else "cloth_blue", rot=(90, 0, 0), seg=14)
        m.torus(0.13, 0.015, (sx, y0 - 0.15, z + 0.78), "iron", rot=(90, 0, 0), seg=14, rseg=4)
        m.sphere(0.03, (sx, y0 - 0.17, z + 0.78), "gold", seg=6, rings=4)
    # Mannequins
    for (x, y) in [(-0.85, -0.75), (-0.25, -0.95)]:
        m.cyl(0.04, 0.85, (x, y, z), "wood_dark", seg=6)
        m.cyl(0.12, 0.38, (x, y, z + 0.3), "straw", r2=0.1, seg=10)
        m.sphere(0.1, (x, y, z + 0.8), "straw", seg=10, rings=6)
        m.rod((x - 0.24, y, z + 0.6), (x + 0.24, y, z + 0.6), 0.03, "wood_dark", seg=5)
    # Râtelier de lances
    m.box((0.08, 0.6, 0.06), (1.2, -0.6, z + 0.55), "wood", bevel=0.01)
    for k in range(4):
        y = -0.85 + k * 0.17
        m.rod((1.2, y, z), (1.2, y, z + 1.0), 0.015, "wood", seg=5)
        m.cyl(0.03, 0.12, (1.2, y, z + 1.0), "iron", r2=0.0, seg=4)
    m.crate((0.6, -1.15, z), 0.26, 10)
    with m.tier(1):
        m.torch((-1.3, -0.15, z), 0.7, tier=1)
    with m.tier(2):
        m.banner((-1.3, -1.25, z), 1.4, "cloth_red")
    with m.tier(3):
        m.sphere(0.1, (tx, ty, z + 2.55), "gold", seg=10, rings=6)
