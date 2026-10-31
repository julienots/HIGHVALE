"""Fosse de minerai sombre : carrière en gradins, filons violets luisants,
grue à benne animée, fonderie rougeoyante, rails et tas de minerai."""
import math

EXTENT = 3.0


def ore_chunk(m, x, y, z, s):
    m.rock((x, y, z + s * 0.4), (s, s * 0.9, s * 0.7), "ore_vein", subdiv=1, rough=0.3)
    m.crystal((x + s * 0.2, y, z + s * 0.5), s * 0.9, s * 0.18, "shadow_glow",
              tilt=(m.rng.uniform(-35, 35), m.rng.uniform(-35, 35)))


def build(m):
    z = m.flagstone_plinth(2.94, 2.94, mat="stone_dark", curb="stone_dark")
    m.ao_height = 1.1
    px, py = -0.35, 0.3
    # Fosse : sol sombre entouré de gradins de roche qui montent vers le bord
    m.cyl(0.62, 0.03, (px, py, z), "dark", seg=20, smooth=False)
    for ring, (r, h, n) in enumerate([(0.72, 0.16, 12), (0.92, 0.3, 15), (1.08, 0.42, 17)]):
        for i in range(n):
            a = math.tau * (i + ring * 0.37) / n
            if ring < 2 and -0.95 < a - 5.2 < 0.25:
                continue  # passage pour l'échelle
            m.rock((px + math.cos(a) * r, py + math.sin(a) * r, z + h * 0.45),
                   (0.2 + ring * 0.03, 0.15, h * 0.55), "rock" if (i + ring) % 3 else "rock_light",
                   rot_z=math.degrees(a), subdiv=1, rough=0.18, tint=m.jitter(0.1))
    # Filons de minerai luisant au fond et sur les parois
    for i in range(8):
        a = math.tau * i / 8 + m.rng.uniform(-0.2, 0.2)
        r = m.rng.uniform(0.1, 0.5)
        ore_chunk(m, px + math.cos(a) * r, py + math.sin(a) * r, z + 0.02, m.rng.uniform(0.07, 0.11))
    for i in range(6):
        a = math.tau * i / 6 + 0.3
        m.crystal((px + math.cos(a) * 0.82, py + math.sin(a) * 0.82, z + 0.28), 0.16, 0.035, "shadow_glow",
                  tilt=(math.degrees(math.sin(a)) * -0.6, math.degrees(math.cos(a)) * 0.6))
    m.light((px, py, z + 0.35), "a050ff", 1.6, 3.5)
    # Échelle vers le fond
    for sx in (-1, 1):
        m.rod((px + 0.28 + sx * 0.08, py - 0.5, z + 0.02), (px + 0.52 + sx * 0.08, py - 0.98, z + 0.5), 0.018, "wood", seg=5)
    for k in range(6):
        t = k / 5
        x, y, zz = px + 0.28 + 0.24 * t, py - 0.5 - 0.48 * t, z + 0.02 + 0.48 * t
        m.rod((x - 0.08, y, zz), (x + 0.08, y, zz), 0.012, "wood_light", seg=4)
    # Grue à benne (mât, flèche pivotante, benne qui monte et descend)
    cx, cy = 0.95, 1.0
    m.box((0.36, 0.36, 0.14), (cx, cy, z + 0.07), "stone", bevel=0.03)
    m.cyl(0.07, 1.7, (cx, cy, z + 0.14), "wood_dark", seg=8)
    for sx, sy in [(-1, -1), (1, -1), (1, 1), (-1, 1)]:
        m.rod((cx + sx * 0.16, cy + sy * 0.16, z + 0.14), (cx, cy, z + 0.9), 0.022, "wood", seg=4)
    with m.anim("boom", (cx, cy, z + 1.7), spin=("Y", 18)):
        m.box((0.2, 0.2, 0.12), (cx, cy, z + 1.84), "iron", bevel=0.02)
        m.rod((cx + 0.35, cy - 0.12, z + 1.75), (cx - 1.2, cy - 0.62, z + 1.92), 0.04, "wood", seg=6)
        m.rod((cx, cy, z + 2.1), (cx - 1.2, cy - 0.62, z + 1.92), 0.012, "iron", seg=4)
        m.rod((cx, cy, z + 2.1), (cx + 0.35, cy - 0.12, z + 1.75), 0.012, "iron", seg=4)
        m.cyl(0.03, 0.4, (cx, cy, z + 1.84), "iron", seg=6)
        m.box((0.22, 0.22, 0.22), (cx + 0.35, cy - 0.12, z + 1.62), "stone_dark", bevel=0.02)
        with m.anim("bucket", (cx - 1.15, cy - 0.6, z + 1.2), bob=0.25):
            m.rod((cx - 1.15, cy - 0.6, z + 1.9), (cx - 1.15, cy - 0.6, z + 1.05), 0.01, "iron", seg=4)
            m.cyl(0.13, 0.16, (cx - 1.15, cy - 0.6, z + 0.9), "iron", r2=0.1, seg=10, rot=(180, 0, 0))
            for k in range(3):
                m.crystal((cx - 1.15 + 0.04 * (k - 1), cy - 0.6, z + 0.92), 0.12, 0.03, "shadow_glow", tilt=(k * 15 - 15, 10))
    # Fonderie de minerai
    fx, fy = 0.95, -0.85
    m.cyl(0.36, 0.55, (fx, fy, z), "stone_warm", r2=0.3, seg=14, smooth=False)
    for k in range(5):
        m.torus(0.36 - k * 0.012, 0.025, (fx, fy, z + 0.08 + k * 0.11), "stone_dark", seg=16, rseg=4)
    m.cyl(0.12, 0.7, (fx + 0.08, fy + 0.08, z + 0.55), "iron", r2=0.09, seg=8)
    m.cyl(0.15, 0.06, (fx + 0.08, fy + 0.08, z + 1.25), "iron", seg=8)
    m.box((0.2, 0.06, 0.18), (fx - 0.12, fy - 0.33, z + 0.2), "fire", bevel=0.01)
    m.box((0.28, 0.08, 0.26), (fx - 0.12, fy - 0.32, z + 0.22), "iron", bevel=0.02, tint=(0.6, 0.6, 0.6))
    m.light((fx - 0.12, fy - 0.5, z + 0.3), "ff7a20", 1.3, 3.0)
    with m.anim("smoke", (fx + 0.08, fy + 0.08, z + 1.45), spin=("Y", 30), bob=0.08):
        for k in range(3):
            m.sphere(0.07 + k * 0.03, (fx + 0.08 + k * 0.05, fy + 0.08, z + 1.4 + k * 0.17), "stone", seg=8, rings=5)
    # Lingots refroidissant
    for k in range(4):
        m.box((0.16, 0.07, 0.05), (fx - 0.6, fy - 0.3 + k * 0.1, z + 0.03), "ore_vein", bevel=0.012)
        m.box((0.12, 0.05, 0.015), (fx - 0.6, fy - 0.3 + k * 0.1, z + 0.06), "shadow_glow", bevel=0)
    # Rails et wagonnet
    for sx in (-1, 1):
        m.box((0.04, 2.3, 0.03), (-1.2 + sx * 0.12, -0.1, z + 0.02), "iron", bevel=0)
    for k in range(9):
        m.box((0.36, 0.06, 0.025), (-1.2, -1.2 + k * 0.27, z + 0.012), "wood_dark", bevel=0)
    m.box((0.32, 0.38, 0.2), (-1.2, -0.75, z + 0.18), "iron", bevel=0.03)
    for sy in (-1, 1):
        for sx in (-1, 1):
            m.cyl(0.055, 0.03, (-1.2 + sx * 0.13, -0.75 + sy * 0.12, z + 0.06), "iron", rot=(0, 90, 0), seg=8)
    for k in range(4):
        ore_chunk(m, -1.2 + m.rng.uniform(-0.08, 0.08), -0.75 + m.rng.uniform(-0.1, 0.1), z + 0.22, 0.07)
    # Tas de minerai
    for (x, y, s) in [(-0.2, -1.15, 0.2), (0.2, -1.25, 0.15)]:
        m.rock((x, y, z + s * 0.5), (s * 1.4, s * 1.2, s), "ore_vein", subdiv=1, rough=0.25)
        m.crystal((x, y, z + s), s * 1.3, s * 0.22, "shadow_glow", tilt=(10, -15))
    with m.tier(1):
        m.lantern_post((-1.25, 1.2, z), 1.0)
        m.crate((0.35, 1.2, z), 0.28, 20)
    with m.tier(2):
        m.barrel((0.55, 1.35, z), 0.13, 0.32)
        m.torch((0.25, -0.6, z), 0.7)
    with m.tier(3):
        m.crystal_cluster((-1.25, 0.55, z), 0.4, "crystal_violet", 5)
        m.light((-1.25, 0.55, z + 0.5), "a050ff", 0.8, 2.5)
