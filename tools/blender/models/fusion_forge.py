"""Fusionnerie : plateforme runique, grand chaudron bouillonnant violet,
pylônes à orbes flottants et arcs de fusion tournants."""
import math

EXTENT = 3.0


def build(m):
    z = m.flagstone_plinth(2.94, 2.94, mat="stone_dark", curb="stone_dark")
    m.ao_height = 1.0
    m.cyl(1.25, 0.1, (0, 0, z), "stone_dark", seg=8, smooth=False)
    m.torus(1.05, 0.02, (0, 0, z + 0.11), "brew_violet", seg=32, rseg=4)
    for i in range(8):
        a = 2 * math.pi * i / 8
        m.box((0.12, 0.04, 0.02), (math.cos(a) * 0.9, math.sin(a) * 0.9, z + 0.11), "brew_violet", rot=(0, 0, math.degrees(a)), bevel=0)
    # Chaudron
    for i in range(3):
        a = 2 * math.pi * i / 3 + 0.5
        m.rod((math.cos(a) * 0.55, math.sin(a) * 0.55, z + 0.1), (math.cos(a) * 0.35, math.sin(a) * 0.35, z + 0.45), 0.045, "iron", seg=6)
    m.sphere(0.6, (0, 0, z + 0.85), "iron", seg=18, rings=10, scale=(1, 1, 0.85), rot=(180, 0, 0), hemi=True)
    m.torus(0.6, 0.06, (0, 0, z + 0.85), "iron", seg=20, rseg=6)
    with m.anim("brew", (0, 0, z + 0.82), bob=0.03):
        m.cyl(0.56, 0.04, (0, 0, z + 0.8), "brew_violet", seg=20)
        for k in range(5):
            a = 2 * math.pi * k / 5
            m.sphere(0.07, (math.cos(a) * 0.25, math.sin(a) * 0.25, z + 0.86), "glow_violet", seg=8, rings=5)
    m.light((0, 0, z + 1.2), "b464ff", 1.6, 4.5)
    # Pylônes
    for sx, sy in [(-1.05, 0.95), (1.05, 0.95), (-1.05, -0.95)]:
        m.box((0.32, 0.32, 0.14), (sx, sy, z + 0.07), "stone_dark", bevel=0.03)
        m.cyl(0.12, 1.3, (sx, sy, z + 0.14), "stone", r2=0.07, seg=4, rot=(0, 0, 45), smooth=False)
        m.box((0.03, 0.06, 0.6), (sx, sy - 0.1, z + 0.6), "brew_violet", bevel=0)
        with m.anim("orb%d" % int((sx + 2) * 10 + sy * 3), (sx, sy, z + 1.7), bob=0.1):
            m.sphere(0.13, (sx, sy, z + 1.7), "glow_violet", seg=12, rings=8)
    # Arcs de fusion
    with m.anim("arcs", (0, 0, z + 1.5), spin=("Y", 45)):
        m.torus(0.75, 0.03, (0, 0, z + 1.5), "brew_violet", rot=(70, 0, 0), seg=24, rseg=4, arc=200)
        m.torus(0.65, 0.025, (0, 0, z + 1.5), "rune", rot=(-60, 30, 0), seg=24, rseg=4, arc=160)
    # Chaînes et coffre d'ingrédients
    for k in range(6):
        m.torus(0.04, 0.012, (1.1, -0.95, z + 0.1 + k * 0.06), "iron", rot=(90 * (k % 2), 0, 0), seg=8, rseg=4)
    m.box((0.36, 0.24, 0.22), (1.05, -0.6, z + 0.11), "wood_dark", bevel=0.02)
    m.box((0.38, 0.26, 0.04), (1.05, -0.6, z + 0.2), "bronze", bevel=0.01)
    with m.tier(1):
        m.crystal_cluster((0.0, 1.2, z), 0.3, "crystal_violet")
    with m.tier(2):
        m.brazier((1.15, 0.2, z))
    with m.tier(3):
        m.crystal_cluster((-1.2, -0.1, z), 0.45, "crystal_violet")
