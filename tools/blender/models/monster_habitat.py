"""Habitat des monstres (4 × 4) : prairie, mare, tanière rocheuse,
nid d'œufs, mangeoire et palissade."""
import math

EXTENT = 4.0


def build(m):
    z = m.flagstone_plinth(3.94, 3.94, mat="stone", curb="stone_dark")
    m.ao_height = 1.0
    m.box((3.5, 3.5, 0.06), (0, 0, z + 0.03), "moss", bevel=0.02)
    for i in range(40):
        x, y = m.rng.uniform(-1.6, 1.6), m.rng.uniform(-1.6, 1.6)
        m.cyl(0.03, m.rng.uniform(0.08, 0.16), (x, y, z + 0.05), "moss", r2=0.0, seg=4, tint=m.jitter(0.25))
    # Mare
    m.cyl(0.75, 0.05, (0.75, 0.65, z + 0.03), "water", seg=20, scale=(1, 0.8, 1))
    for i in range(12):
        a = 2 * math.pi * i / 12
        m.rock((0.75 + math.cos(a) * 0.78, 0.65 + math.sin(a) * 0.62, z + 0.05), (0.12, 0.12, 0.09), "rock_light")
    # Tanière
    for (x, y, sx, sy, sz) in [(-0.95, 0.95, 0.8, 0.75, 0.95), (-0.35, 1.25, 0.55, 0.5, 0.6), (-1.35, 0.35, 0.45, 0.5, 0.55)]:
        m.rock((x, y, z), (sx, sy, sz), "rock", subdiv=2, rough=0.15)
    m.sphere(0.32, (-0.8, 0.45, z + 0.04), "dark", seg=12, rings=6, hemi=True, scale=(1, 0.6, 1.1))
    # Nid et œufs
    m.torus(0.26, 0.08, (0.8, -0.85, z + 0.1), "straw", seg=14, rseg=6)
    for i, mat in enumerate(["mushroom_teal", "mushroom_violet", "cloth_cream"]):
        a = 2 * math.pi * i / 3
        m.sphere(0.1, (0.8 + math.cos(a) * 0.09, -0.85 + math.sin(a) * 0.09, z + 0.16), mat, seg=10, rings=8, scale=(1, 1, 1.3))
    # Mangeoire
    m.box((0.7, 0.3, 0.18), (-0.6, -1.2, z + 0.15), "wood", bevel=0.02)
    for k in range(5):
        m.sphere(0.06, (-0.85 + k * 0.12, -1.2, z + 0.27), m.rng.choice(["cloth_red", "straw", "mushroom_pink"]), seg=6, rings=4)
    # Champignons et cristaux
    m.mushroom((1.45, 1.45, z + 0.05), 0.55, 0.25, "mushroom_teal", "glow_teal", bend=0.05)
    m.crystal_cluster((1.4, -0.3, z + 0.05), 0.35, "crystal")
    # Palissade avec portail
    n = 28
    for i in range(n):
        a = 2 * math.pi * i / n
        if abs(math.sin(a) + 1) < 0.08:
            continue
        x, y = math.cos(a) * 1.82, math.sin(a) * 1.82
        if abs(x) > 1.86 or abs(y) > 1.86:
            continue
        m.cyl(0.05, 0.42 + (i % 2) * 0.06, (x, y, z), "wood", r2=0.035, seg=6)
    for sx in (-1, 1):
        m.box((0.12, 0.12, 0.85), (sx * 0.32, -1.82, z + 0.42), "wood_dark", bevel=0.02)
    m.box((0.85, 0.12, 0.12), (0, -1.82, z + 0.82), "wood_dark", bevel=0.02)
    with m.tier(1):
        m.lantern_post((1.6, -1.55, z), 1.0)
    with m.tier(2):
        m.mushroom((-1.5, -0.5, z + 0.05), 0.9, 0.35, "mushroom_violet", "glow_violet", bend=0.1)
    with m.tier(3):
        m.crystal_cluster((-1.4, 1.5, z), 0.5, "crystal_violet")
