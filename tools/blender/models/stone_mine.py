"""Mine de pierre : colline rocheuse, galerie étayée, rails et wagonnet,
chevalement à roue animée et blocs de pierre taillée."""
import math

EXTENT = 3.0


def build(m):
    z = m.flagstone_plinth(2.94, 2.94, mat="stone", curb="stone_dark")
    m.ao_height = 1.0
    # Colline
    for (x, y, sx, sy, sz, mat) in [(-0.55, 0.55, 0.95, 0.85, 1.25, "rock"), (0.15, 0.75, 0.75, 0.6, 0.95, "rock_light"),
                                     (-1.0, -0.1, 0.55, 0.6, 0.75, "rock_light"), (0.55, 0.95, 0.5, 0.45, 0.6, "rock"),
                                     (-0.95, 0.95, 0.5, 0.5, 0.8, "rock_light"), (-0.25, 0.15, 0.6, 0.45, 0.7, "rock")]:
        m.rock((x, y, z), (sx, sy, sz), mat, subdiv=2, rough=0.16)
    for (x, y, zz) in [(-0.7, 0.5, 1.12), (-0.45, 0.75, 1.1), (0.15, 0.85, 0.85), (-1.0, 0.95, 0.72)]:
        for k in range(3):
            m.sphere(0.09, (x + m.rng.uniform(-0.1, 0.1), y + m.rng.uniform(-0.1, 0.1), z + zz), "moss", seg=6, rings=4, scale=(1.3, 1.1, 0.6), smooth=False)
    # Galerie
    gx, gy = -0.3, -0.25
    m.box((0.62, 0.5, 0.72), (gx, gy + 0.18, z + 0.36), "dark", bevel=0)
    for sx in (-1, 1):
        m.box((0.11, 0.11, 0.82), (gx + sx * 0.36, gy - 0.08, z + 0.41), "wood", bevel=0.02)
        m.rod((gx + sx * 0.36, gy - 0.08, z + 0.5), (gx + sx * 0.18, gy - 0.08, z + 0.8), 0.035, "wood_dark", seg=6)
    m.box((0.95, 0.13, 0.13), (gx, gy - 0.08, z + 0.86), "wood", bevel=0.02)
    m.box((0.5, 0.04, 0.16), (gx, gy - 0.16, z + 1.03), "wood_light", rot=(0, 4, 0), bevel=0.01)
    m.box((0.3, 0.02, 0.05), (gx, gy - 0.19, z + 1.03), "dark", bevel=0)
    m.lantern_post((gx + 0.55, gy - 0.25, z), 0.95)
    # Rails et traverses
    for i in range(9):
        m.box((0.42, 0.08, 0.04), (gx, gy - 0.25 - i * 0.14, z + 0.02), "wood_dark", bevel=0.01, tint=m.jitter(0.15))
    for sx in (-0.13, 0.13):
        m.box((0.035, 1.3, 0.04), (gx + sx, gy - 0.82, z + 0.06), "iron", bevel=0.008)
    # Wagonnet chargé
    cyy = gy - 0.95
    m.box((0.4, 0.5, 0.24), (gx, cyy, z + 0.24), "wood_dark", bevel=0.03)
    m.box((0.44, 0.54, 0.04), (gx, cyy, z + 0.36), "iron", bevel=0.01)
    for sx in (-1, 1):
        for sy in (-1, 1):
            m.cyl(0.07, 0.04, (gx + sx * 0.2, cyy + sy * 0.16, z + 0.1), "iron", rot=(0, 90, 0), seg=10)
    for i in range(5):
        m.rock((gx + m.rng.uniform(-0.12, 0.12), cyy + m.rng.uniform(-0.15, 0.15), z + 0.38), (0.11, 0.1, 0.09), "stone", subdiv=1)
    # Chevalement à roue
    hx, hy = 0.8, -0.05
    for sy in (-0.25, 0.25):
        m.rod((hx - 0.3, hy + sy, z), (hx, hy + sy, z + 1.35), 0.045, "wood", seg=6)
        m.rod((hx + 0.3, hy + sy, z), (hx, hy + sy, z + 1.35), 0.045, "wood", seg=6)
        m.rod((hx - 0.17, hy + sy, z + 0.6), (hx + 0.17, hy + sy, z + 0.6), 0.03, "wood_dark", seg=4)
    m.rod((hx, hy - 0.3, z + 1.35), (hx, hy + 0.3, z + 1.35), 0.04, "iron", seg=8)
    with m.anim("wheel", (hx, hy, z + 1.35), spin=("Z", 70)):
        m.spoked_wheel((hx, hy, z + 1.35), 0.32, (90, 0, 0), "wood", spokes=6, thick=0.06)
    m.rod((hx + 0.32, hy, z + 1.35), (hx + 0.32, hy, z + 0.5), 0.012, "cloth_cream", seg=4)
    m.barrel((hx + 0.32, hy, z + 0.32), r=0.11, h=0.18)
    # Blocs de pierre taillée
    for i, (bx, by, bz) in enumerate([(0.55, -0.85, 0), (0.85, -0.85, 0), (0.7, -0.62, 0), (0.7, -0.85, 1)]):
        m.box((0.27, 0.2, 0.18), (bx, by, z + 0.09 + bz * 0.19), "stone", rot=(0, 0, m.rng.uniform(-8, 8)), bevel=0.025)
    m.crate((1.1, -1.15, z), 0.26, 20)
    # Râtelier d'outils
    m.box((0.5, 0.06, 0.05), (-1.05, -0.95, z + 0.45), "wood_dark", bevel=0.01)
    for i in range(3):
        px = -1.2 + i * 0.15
        m.rod((px, -0.98, z), (px, -0.98, z + 0.55), 0.015, "wood", seg=5)
        m.box((0.16, 0.025, 0.04), (px, -0.98, z + 0.55), "iron", rot=(0, 15, 0), bevel=0)
    with m.tier(1):
        for i, (bx, by, bz) in enumerate([(1.1, -0.45, 0), (1.1, -0.2, 0), (1.1, -0.32, 1)]):
            m.box((0.24, 0.2, 0.17), (bx, by, z + 0.085 + bz * 0.18), "stone_warm", bevel=0.025)
        m.torch((-0.75, -0.4, z), 0.6, tier=1)
    with m.tier(2):
        for sx in (-1, 1):
            m.box((0.13, 0.13, 0.05), (gx + sx * 0.36, gy - 0.08, z + 0.3), "iron", bevel=0)
            m.box((0.13, 0.13, 0.05), (gx + sx * 0.36, gy - 0.08, z + 0.65), "iron", bevel=0)
        for (x, y, zz) in [(-0.85, 0.3, 0.55), (-0.2, 0.55, 0.9), (0.3, 0.6, 0.65)]:
            m.rock((x, y, z + zz), (0.07, 0.07, 0.06), "gold", subdiv=1)
    with m.tier(3):
        m.crystal_cluster((-0.15, 0.9, z + 0.55), 0.4, "crystal")
        m.crystal_cluster((-1.05, 0.35, z + 0.35), 0.32, "crystal_violet", 4)
        m.light((-0.5, 0.6, z + 1.0), "7fdcff", 0.8, 3.0, 3)
