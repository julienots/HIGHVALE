"""Entrepôt : grange à planches sur soubassement de pierre, grandes portes,
toit de tuiles, palan de grenier et marchandises empilées."""
import math

EXTENT = 3.0


def build(m):
    z = m.flagstone_plinth(2.94, 2.94, mat="stone", curb="stone_dark")
    cx, cy, w, d = 0.0, 0.25, 2.1, 1.45
    hw, hd = w / 2, d / 2
    # Soubassement de pierre
    for a, b in [((cx - hw, cy - hd), (cx + hw, cy - hd)), ((cx + hw, cy - hd), (cx + hw, cy + hd)),
                 ((cx + hw, cy + hd), (cx - hw, cy + hd)), ((cx - hw, cy + hd), (cx - hw, cy - hd))]:
        m.brick_wall(a, b, z, 0.26, thick=0.2, mat="stone", course=0.13, brick=0.32)
    m.box((w - 0.2, d - 0.2, 0.26), (cx, cy, z + 0.13), "stone_dark", bevel=0)
    # Murs en planches verticales
    zw, hwl = z + 0.26, 0.95
    m.box((w - 0.08, d - 0.08, hwl), (cx, cy, zw + hwl / 2), "wood_dark", bevel=0)
    for face in range(4):
        length = (w if face % 2 == 0 else d) - 0.08
        n = round(length / 0.13)
        for k in range(n):
            t = -length / 2 + length * (k + 0.5) / n
            p = [(cx + t, cy - hd + 0.02), (cx + hw - 0.02, cy + t), (cx - t, cy + hd - 0.02), (cx - hw + 0.02, cy - t)][face]
            m.box((length / n - 0.012, 0.05, hwl * m.rng.uniform(0.97, 1.0)), (p[0], p[1], zw + hwl / 2), "wood",
                  rot=(0, 0, [0, 90, 180, 270][face]), bevel=0.008, tint=m.jitter(0.14))
    for sx in (-1, 1):
        for sy in (-1, 1):
            m.box((0.12, 0.12, hwl + 0.05), (cx + sx * hw, cy + sy * hd, zw + hwl / 2), "wood_light", bevel=0.02)
    for hz in (zw + 0.05, zw + hwl - 0.04):
        m.box((w + 0.04, 0.07, 0.08), (cx, cy - hd - 0.02, hz), "wood_light", bevel=0.015)
        m.box((0.07, d + 0.04, 0.08), (cx + hw + 0.02, cy, hz), "wood_light", bevel=0.015)
    # Toit
    m.gable_roof((cx, cy, zw + hwl), w, d, 0.75, "roof_red", overhang=0.18, rows=6)
    # Grandes portes
    fy = cy - hd - 0.05
    for sx in (-1, 1):
        dx = cx + sx * 0.22
        m.box((0.42, 0.06, 0.72), (dx, fy, zw + 0.36), "wood_light", bevel=0.015)
        for hz in (0.12, 0.36, 0.6):
            m.box((0.42, 0.03, 0.05), (dx, fy - 0.035, zw + hz), "wood_dark", bevel=0)
        m.rod((dx - 0.19, fy - 0.04, zw + 0.06), (dx + 0.19, fy - 0.04, zw + 0.66), 0.02, "wood_dark", seg=4)
        m.rod((dx + 0.19, fy - 0.04, zw + 0.06), (dx - 0.19, fy - 0.04, zw + 0.66), 0.02, "wood_dark", seg=4)
        m.torus(0.035, 0.01, (dx - sx * 0.15, fy - 0.07, zw + 0.36), "iron", rot=(90, 0, 0), seg=8, rseg=4)
    m.box((0.98, 0.1, 0.1), (cx, fy - 0.02, zw + 0.78), "wood_light", bevel=0.02)
    # Porte de grenier et palan
    m.box((0.34, 0.05, 0.3), (cx, cy - hd - 0.04, zw + hwl + 0.22), "wood_dark", bevel=0.01)
    m.box((0.1, 0.65, 0.1), (cx, cy - hd - 0.12, zw + hwl + 0.55), "wood_light", bevel=0.02)
    m.rod((cx, cy - hd - 0.4, zw + hwl + 0.5), (cx, cy - hd - 0.4, zw + 0.55), 0.012, "cloth_cream", seg=4)
    m.crate((cx, cy - hd - 0.4, zw + 0.3), 0.24, 10)
    # Marchandises
    m.crate((-1.15, -0.95, z), 0.32, 8)
    m.crate((-0.82, -1.05, z), 0.3, -12)
    m.crate((-1.0, -0.98, z + 0.32), 0.26, 25)
    m.barrel((1.15, -0.65, z))
    m.barrel((0.85, -0.95, z))
    m.barrel((1.15, -1.0, z), r=0.13, h=0.32)
    for (x, y) in [(0.45, -1.2), (0.6, -1.05), (0.52, -1.1)]:
        m.sack((x, y, z), 0.13)
    m.lantern_post((-0.6, -1.25, z), 1.0)
    with m.tier(1):
        lx = cx - hw - 0.3
        for py in (-0.3, 0.6):
            m.box((0.07, 0.07, 0.7), (lx - 0.12, cy + py, z + 0.35), "wood", bevel=0.01)
        m.box((0.5, 1.1, 0.04), (lx, cy + 0.15, z + 0.75), "roof_red", rot=(0, 18, 0), bevel=0.01)
        for row in range(3):
            for k in range(4 - row):
                m.cyl(0.06, 0.4, (lx - 0.05, cy - 0.15 + k * 0.13 + row * 0.065, z + 0.06 + row * 0.11), "wood", rot=(90, 0, 0), seg=8)
    with m.tier(2):
        for sx in (-1, 1):
            for hz in (zw + 0.3, zw + 0.7):
                m.box((0.14, 0.14, 0.03), (cx + sx * hw, cy - hd, hz), "iron", bevel=0)
        m.torch((cx + hw + 0.15, cy - hd - 0.2, z), 0.7, tier=2)
    with m.tier(3):
        m.banner((-1.3, 0.9, z), 1.5, "cloth_blue")
        m.crate((1.15, 1.05, z), 0.34, 0)
        m.crate((1.15, 1.05, z + 0.34), 0.28, 20)
