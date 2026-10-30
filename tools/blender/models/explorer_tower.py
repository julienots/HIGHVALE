"""Tour des explorateurs (2 × 2) : vigie en bois sur socle de pierre,
échelle, plateforme à garde-corps, toit conique et longue-vue."""
import math

EXTENT = 3.2


def build(m):
    z = m.flagstone_plinth(1.94, 1.94, mat="stone", curb="stone_dark")
    m.ao_height = 1.0
    for a, b in [((-0.5, -0.5), (0.5, -0.5)), ((0.5, -0.5), (0.5, 0.5)), ((0.5, 0.5), (-0.5, 0.5)), ((-0.5, 0.5), (-0.5, -0.5))]:
        m.brick_wall(a, b, z, 0.45, thick=0.16, mat="stone", course=0.15, brick=0.28)
    m.box((0.8, 0.8, 0.45), (0, 0, z + 0.22), "stone_dark", bevel=0)
    H = 2.4
    for sx in (-1, 1):
        for sy in (-1, 1):
            m.rod((sx * 0.42, sy * 0.42, z + 0.45), (sx * 0.3, sy * 0.3, z + H), 0.05, "wood", seg=6)
    for lvl in range(3):
        zz0, zz1 = z + 0.5 + lvl * 0.62, z + 0.5 + (lvl + 1) * 0.62
        r0, r1 = 0.42 - 0.04 * lvl, 0.42 - 0.04 * (lvl + 1)
        for face in range(4):
            c = [(-1, -1), (1, -1), (1, 1), (-1, 1)]
            a, b = c[face], c[(face + 1) % 4]
            m.rod((a[0] * r0, a[1] * r0, zz0), (b[0] * r1, b[1] * r1, zz1), 0.02, "wood_dark", seg=4)
    pz = z + H
    m.box((1.1, 1.1, 0.08), (0, 0, pz), "wood_light", bevel=0.02)
    for k in range(12):
        t = k / 12 * 4
        side, f = int(t), t - int(t)
        c = [(-0.5, -0.5), (0.5, -0.5), (0.5, 0.5), (-0.5, 0.5)]
        a, b = c[side], c[(side + 1) % 4]
        m.box((0.04, 0.04, 0.3), (a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f, pz + 0.19), "wood_dark", bevel=0)
    for face in range(4):
        c = [(-0.5, -0.5), (0.5, -0.5), (0.5, 0.5), (-0.5, 0.5)]
        a, b = c[face], c[(face + 1) % 4]
        m.rod((a[0], a[1], pz + 0.34), (b[0], b[1], pz + 0.34), 0.025, "wood", seg=4)
    for sx in (-1, 1):
        for sy in (-1, 1):
            m.box((0.06, 0.06, 0.75), (sx * 0.45, sy * 0.45, pz + 0.4), "wood", bevel=0.01)
    m.cone_roof((0, 0, pz + 0.78), 0.78, 0.7, "roof_blue", rings=5)
    # Échelle
    m.rod((-0.15, -0.62, z), (-0.15, -0.56, pz), 0.02, "wood", seg=4)
    m.rod((0.15, -0.62, z), (0.15, -0.56, pz), 0.02, "wood", seg=4)
    for k in range(12):
        zz = z + 0.15 + k * 0.19
        m.rod((-0.15, -0.61, zz), (0.15, -0.61, zz), 0.012, "wood_dark", seg=4)
    # Longue-vue
    m.cyl(0.04, 0.4, (0.35, -0.35, pz + 0.05), "bronze", r2=0.03, rot=(-70, 0, -45), seg=8)
    m.banner((0.45, 0.45, pz + 0.78), 0.8, "cloth_blue")
    m.crate((0.65, -0.6, z), 0.22, 10)
    with m.tier(1):
        m.lantern_post((-0.7, 0.65, z), 0.9)
    with m.tier(2):
        m.sack((-0.7, -0.7, z), 0.12)
    with m.tier(3):
        m.sphere(0.08, (0, 0, pz + 1.55), "gold", seg=10, rings=6)
