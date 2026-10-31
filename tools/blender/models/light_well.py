"""Puits de lumière (2 × 2) : une colonne de soleil tombe de la surface par
un puits creusé dans la voûte, sur une margelle de marbre fleurie ; miroirs
dorés orientés et herbe venue d'en haut."""
import math

EXTENT = 2.4


def build(m):
    z = m.flagstone_plinth(1.94, 1.94, mat="marble", curb="stone_warm")
    m.ao_height = 0.9
    # Pelouse et fleurs de surface
    m.cyl(0.92, 0.04, (0, 0, z), "grass", seg=20, smooth=False)
    for i in range(26):
        a = m.rng.uniform(0, math.tau)
        r = m.rng.uniform(0.58, 0.9)
        x, y = math.cos(a) * r, math.sin(a) * r
        if abs(x) > 0.82 and abs(y) > 0.82:
            continue
        m.cyl(0.012, 0.12, (x, y, z + 0.03), "grass", seg=4, smooth=False)
        if i % 3 == 0:
            m.sphere(0.035, (x, y, z + 0.16), m.rng.choice(["glow_gold", "mushroom_pink", "cloth_white"]), seg=6, rings=4,
                     scale=(1, 1, 0.6))
    # Margelle
    for i in range(14):
        a = math.tau * i / 14
        m.box((0.24, 0.13, 0.26), (math.cos(a) * 0.5, math.sin(a) * 0.5, z + 0.15), "marble",
              rot=(0, 0, math.degrees(a) + 90), bevel=0.03, tint=m.jitter(0.06))
    m.torus(0.5, 0.05, (0, 0, z + 0.29), "gold", seg=28, rseg=6)
    m.cyl(0.42, 0.2, (0, 0, z + 0.04), "water", seg=20)
    m.cyl(0.3, 0.02, (0, 0, z + 0.24), "glow_gold", seg=20)
    # Colonne de lumière (tombe de la voûte)
    m.cyl(0.36, 3.6, (0, 0, z + 0.26), "sunbeam", r2=0.5, seg=20, smooth="sides")
    m.cyl(0.2, 3.6, (0, 0, z + 0.26), "sunbeam", r2=0.3, seg=16, smooth="sides")
    m.light((0, 0, z + 1.6), "fff2c8", 3.0, 6.0)
    m.light((0, 0, z + 0.5), "ffe9a0", 1.6, 3.0)
    # Poussières dorées dans le rayon
    with m.anim("motes", (0, 0, z + 1.2), spin=("Y", 14), bob=0.1):
        for i in range(14):
            a = math.tau * i / 14
            r = 0.1 + (i % 4) * 0.07
            m.sphere(0.018, (math.cos(a) * r, math.sin(a) * r, z + 0.6 + (i * 0.17) % 2.0), "glow_gold", seg=5, rings=3)
    # Miroirs dorés sur trépieds, orientés vers le puits
    for i in range(3):
        a = math.tau * i / 3 + 0.5
        x, y = math.cos(a) * 0.8, math.sin(a) * 0.8
        for k in range(3):
            b = a + math.tau * k / 3
            m.rod((x + math.cos(b) * 0.1, y + math.sin(b) * 0.1, z), (x, y, z + 0.55), 0.014, "bronze", seg=4)
        with m.anim("mirror%d" % i, (x, y, z + 0.62), spin=("Y", 10 + i * 4)):
            m.cyl(0.13, 0.025, (x, y, z + 0.62), "gold", seg=14, rot=(70, 0, math.degrees(a) + 90))
            m.cyl(0.11, 0.03, (x, y, z + 0.62), "glow_gold", seg=14, rot=(70, 0, math.degrees(a) + 90))
    with m.tier(1):
        m.lantern_post((0.85, -0.85, z), 0.9)
    with m.tier(2):
        for (x, y) in [(-0.82, 0.82), (0.82, 0.82)]:
            m.cyl(0.1, 0.14, (x, y, z), "stone_warm", r2=0.13, seg=10)
            m.sphere(0.11, (x, y, z + 0.2), "leaf", seg=8, rings=6)
    with m.tier(3):
        with m.anim("halo", (0, 0, z + 2.2), spin=("Y", 20)):
            m.torus(0.55, 0.025, (0, 0, z + 2.2), "glow_gold", seg=28, rseg=4)
