"""Laboratoire : bâtisse de pierre, serre vitrée, grande cuve d'incubation
lumineuse, alambics reliés par des tubes et bobine à étincelles."""
import math

EXTENT = 3.0


def build(m):
    z = m.flagstone_plinth(2.94, 2.94, mat="stone_dark", curb="stone_dark")
    m.ao_height = 1.2
    cx, cy, w, d = -0.45, 0.55, 1.6, 1.1
    for a, b in [((cx - w / 2, cy - d / 2), (cx + w / 2, cy - d / 2)), ((cx + w / 2, cy - d / 2), (cx + w / 2, cy + d / 2)),
                 ((cx + w / 2, cy + d / 2), (cx - w / 2, cy + d / 2)), ((cx - w / 2, cy + d / 2), (cx - w / 2, cy - d / 2))]:
        m.brick_wall(a, b, z, 0.85, thick=0.18, mat="stone", course=0.17, brick=0.32)
    m.box((w - 0.2, d - 0.2, 0.85), (cx, cy, z + 0.42), "stone_dark", bevel=0)
    m.box((w + 0.12, d + 0.12, 0.08), (cx, cy, z + 0.89), "iron", bevel=0.02)
    # Serre vitrée
    for i in range(7):
        a = math.pi * i / 6
        m.torus(0.5, 0.025, (cx - 0.55 + i * 0.18, cy, z + 0.93), "iron", rot=(90, 0, 90), seg=12, rseg=4, arc=180)
    m.cyl(0.5, 1.1, (cx - 0.55, cy, z + 0.93), "glass", rot=(0, 90, 0), seg=16, scale=(1, 1, 1))
    m.door((cx + 0.2, cy - d / 2 - 0.05, z), 0, w=0.32, h=0.5, frame="iron", arch=True)
    m.window((cx - 0.4, cy - d / 2 - 0.05, z + 0.3), 0, w=0.26, h=0.32, frame="iron", arch=True)
    # Cuve d'incubation
    tx, ty = 0.7, 0.45
    m.cyl(0.45, 0.2, (tx, ty, z), "iron", seg=16)
    m.cyl(0.38, 1.0, (tx, ty, z + 0.2), "glass", seg=16)
    m.cyl(0.33, 0.85, (tx, ty, z + 0.22), "brew_green", seg=14)
    m.cyl(0.42, 0.14, (tx, ty, z + 1.2), "iron", r2=0.3, seg=16)
    for i in range(4):
        a = 2 * math.pi * i / 4 + 0.4
        m.rod((tx + math.cos(a) * 0.4, ty + math.sin(a) * 0.4, z + 0.2), (tx + math.cos(a) * 0.4, ty + math.sin(a) * 0.4, z + 1.22), 0.03, "bronze", seg=6)
    with m.anim("bubbles", (tx, ty, z + 0.6), bob=0.15):
        for k in range(6):
            m.sphere(0.04 + k * 0.006, (tx + m.rng.uniform(-0.18, 0.18), ty + m.rng.uniform(-0.18, 0.18), z + 0.35 + k * 0.1), "glow_teal", seg=6, rings=4)
    m.light((tx, ty, z + 0.7), "5bff8a", 1.2, 3.5)
    # Alambics et tubes
    for i, (fx, fy, mat) in enumerate([(-0.15, -0.65, "brew_violet"), (0.25, -0.85, "glow_pink"), (0.65, -0.6, "brew_green")]):
        m.cyl(0.14, 0.32, (fx, fy, z), "wood", seg=10)
        m.sphere(0.13, (fx, fy, z + 0.45), "glass", seg=12, rings=8)
        m.sphere(0.1, (fx, fy, z + 0.43), mat, seg=10, rings=6)
        m.cyl(0.03, 0.25, (fx, fy, z + 0.55), "glass", seg=8)
        m.rod((fx, fy, z + 0.78), (tx - 0.2, ty - 0.2, z + 1.05), 0.022, "bronze", seg=6)
    # Bobine à étincelles
    sx, sy = -1.15, -0.75
    m.cyl(0.15, 0.15, (sx, sy, z), "iron", seg=10)
    for k in range(6):
        m.torus(0.08, 0.022, (sx, sy, z + 0.22 + k * 0.08), "bronze", seg=10, rseg=4)
    m.cyl(0.03, 0.7, (sx, sy, z + 0.15), "iron", seg=6)
    with m.anim("spark", (sx, sy, z + 0.95), bob=0.03):
        m.sphere(0.09, (sx, sy, z + 0.95), "rune", seg=10, rings=6)
    m.light((sx, sy, z + 1.0), "7fe8ff", 0.7, 2.5)
    with m.tier(1):
        m.crate((1.2, -1.15, z), 0.26, 10)
        m.barrel((1.2, -0.75, z), 0.12, 0.3)
    with m.tier(2):
        m.banner((-1.3, 1.25, z), 1.3, "cloth_blue")
    with m.tier(3):
        m.crystal_cluster((1.2, 1.2, z), 0.35, "crystal_teal")
