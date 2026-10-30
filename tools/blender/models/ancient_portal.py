"""Portail antique : arche de blocs runiques, vortex tournant,
colonnes brisées, éboulis et rochers flottants."""
import math

EXTENT = 3.0


def build(m):
    z = m.flagstone_plinth(2.94, 2.94, mat="stone_dark", curb="stone_dark")
    m.ao_height = 1.2
    m.box((1.9, 0.7, 0.14), (0, 0.1, z + 0.07), "stone", bevel=0.03)
    m.box((1.5, 0.5, 0.1), (0, 0.1, z + 0.19), "stone_warm", bevel=0.02)
    # Arche
    R, n = 0.82, 11
    for i in range(n):
        a0 = math.pi * i / n
        a1 = math.pi * (i + 1) / n
        am = (a0 + a1) / 2
        m.box((0.36, 0.42, R * (a1 - a0) + 0.02), (math.cos(am) * R, 0.1, z + 0.85 + math.sin(am) * R), "stone" if i % 2 else "rock_light",
              rot=(0, -math.degrees(am) + 90, 0), bevel=0.03)
        if i % 3 == 1:
            m.box((0.04, 0.03, 0.12), (math.cos(am) * (R - 0.0), -0.13, z + 0.85 + math.sin(am) * R), "rune", rot=(0, -math.degrees(am) + 90, 0), bevel=0)
    for sx in (-1, 1):
        m.box((0.42, 0.48, 0.65), (sx * R, 0.1, z + 0.55), "stone", bevel=0.03)
        m.box((0.05, 0.03, 0.4), (sx * R, -0.15, z + 0.55), "rune", bevel=0)
    with m.anim("vortex", (0, 0.1, z + 0.95), spin=("Z", 110)):
        m.cyl(0.62, 0.03, (0, 0.11, z + 0.95), "brew_violet", rot=(90, 0, 0), seg=28, scale=(1, 1.15, 1))
        m.torus(0.45, 0.025, (0, 0.08, z + 0.95), "rune", rot=(90, 0, 0), seg=20, rseg=4, arc=240)
        m.torus(0.25, 0.02, (0, 0.07, z + 0.95), "glow_violet", rot=(90, 0, 0), seg=16, rseg=4, arc=200)
    m.light((0, -0.3, z + 1.0), "a050ff", 1.6, 4.5)
    # Colonnes brisées et éboulis
    for (x, y, hh, tilt) in [(-1.15, -0.8, 0.9, 8), (1.1, -0.95, 0.55, -6), (1.15, 1.0, 0.75, 0)]:
        m.cyl(0.15, hh, (x, y, z), "stone_warm", seg=10, rot=(tilt, 0, 0))
        m.box((0.36, 0.36, 0.08), (x, y, z + 0.04), "stone_dark", bevel=0.02)
    m.cyl(0.14, 0.6, (-0.75, -1.15, z + 0.15), "stone_warm", seg=10, rot=(0, 90, 25))
    for i in range(7):
        m.rock((m.rng.uniform(-1.3, 1.3), m.rng.uniform(-1.3, -0.6), z), (0.12, 0.12, 0.09), "rock_light")
    # Rochers flottants
    for i, (x, y, zz) in enumerate([(-1.0, 0.8, 1.3), (0.9, 0.5, 1.7), (-0.4, 0.9, 2.0)]):
        with m.anim("float%d" % i, (x, y, z + zz), bob=0.12):
            m.rock((x, y, z + zz), (0.18, 0.16, 0.14), "rock")
            m.crystal((x, y, z + zz + 0.05), 0.18, 0.04, "crystal_violet")
    with m.tier(1):
        m.crystal_cluster((-1.2, 1.2, z), 0.35, "crystal")
    with m.tier(2):
        m.brazier((0.6, -1.15, z))
        m.brazier((-0.6, -1.15, z))
    with m.tier(3):
        m.crystal_cluster((1.25, -0.2, z), 0.4, "crystal_violet")
