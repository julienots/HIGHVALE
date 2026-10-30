"""Sanctuaire des héros : plateforme circulaire à degrés, colonnade en anneau
et portail d'invocation bleu tournant."""
import math

EXTENT = 3.0


def build(m):
    z = m.flagstone_plinth(2.94, 2.94, mat="marble", curb="stone_dark")
    for k, r in enumerate((1.35, 1.18, 1.0)):
        m.cyl(r, 0.12, (0, 0, z + k * 0.12), "marble" if k % 2 == 0 else "stone_warm", seg=24, smooth=False)
    top = z + 0.36
    m.torus(0.85, 0.02, (0, 0, top + 0.01), "rune", seg=32, rseg=4)
    for i in range(6):
        a = 2 * math.pi * i / 6 + math.pi / 6
        m.column((math.cos(a) * 0.95, math.sin(a) * 0.95, top), 0.07, 1.25)
    for i in range(6):
        a0, a1 = 2 * math.pi * i / 6 + math.pi / 6, 2 * math.pi * (i + 1) / 6 + math.pi / 6
        m.rod((math.cos(a0) * 0.95, math.sin(a0) * 0.95, top + 1.3), (math.cos(a1) * 0.95, math.sin(a1) * 0.95, top + 1.3), 0.07, "marble", seg=6)
    m.torus(0.95, 0.03, (0, 0, top + 1.4), "gold", seg=32, rseg=4)
    # Portail
    pz = top + 0.75
    m.torus(0.5, 0.07, (0, 0, pz), "gold", rot=(90, 0, 0), seg=28, rseg=8)
    for i in range(8):
        a = 2 * math.pi * i / 8
        m.crystal((math.cos(a) * 0.55, -0.02, pz + math.sin(a) * 0.55), 0.14, 0.035, "crystal", tilt=(90, 0), rz=0)
    with m.anim("portal", (0, 0, pz), spin=("Z", 80)):
        m.cyl(0.44, 0.02, (0, 0.01, pz), "rune", rot=(90, 0, 0), seg=24)
        m.torus(0.3, 0.02, (0, -0.02, pz), "glow_teal", rot=(90, 0, 0), seg=20, rseg=4, arc=270)
    m.light((0, -0.4, pz), "62c8ff", 1.4, 4.0)
    m.box((0.5, 0.2, 0.15), (0, 0, top + 0.07), "gold", bevel=0.02)
    # Marches d'accès
    for k in range(3):
        m.box((0.7, 0.2, 0.12 * (k + 1)), (0, -1.38 + k * 0.17, z + 0.06 * (k + 1)), "marble", bevel=0.02)
    for sx in (-1, 1):
        m.brazier((sx * 0.6, -1.25, z))
    with m.tier(1):
        m.banner((-1.3, 0.9, z), 1.5, "cloth_blue")
        m.banner((1.3, 0.9, z), 1.5, "cloth_blue")
    with m.tier(2):
        with m.anim("halo", (0, 0, top + 1.7), spin=("Y", 40)):
            for i in range(5):
                a = 2 * math.pi * i / 5
                m.sphere(0.06, (math.cos(a) * 0.5, math.sin(a) * 0.5, top + 1.7), "rune", seg=8, rings=5)
    with m.tier(3):
        m.crystal_cluster((1.2, -1.15, z), 0.35, "crystal")
        m.crystal_cluster((-1.2, -1.15, z), 0.35, "crystal")
