"""Jardin des lueurs (2 × 2) : massifs de fleurs et champignons, banc et lanterne."""
import math

EXTENT = 2.2


def build(m):
    z = m.flagstone_plinth(1.94, 1.94, mat="stone", curb="stone_dark")
    m.ao_height = 0.6
    m.box((1.6, 1.6, 0.06), (0, 0, z + 0.03), "moss", bevel=0.02)
    m.box((0.35, 1.6, 0.065), (0.0, 0, z + 0.035), "stone_warm", bevel=0.01)
    for (cx, cy) in [(-0.5, 0.0), (0.5, 0.0)]:
        for i in range(9):
            x, y = cx + m.rng.uniform(-0.25, 0.25), cy + m.rng.uniform(-0.65, 0.65)
            mat = m.rng.choice(["mushroom_pink", "straw", "mushroom_violet", "cloth_red", "glow_teal"])
            m.rod((x, y, z + 0.05), (x, y, z + 0.2), 0.012, "moss", seg=4)
            m.sphere(0.05, (x, y, z + 0.22), mat, seg=8, rings=5, scale=(1, 1, 0.7))
    m.mushroom((-0.6, 0.6, z + 0.05), 0.45, 0.2, "mushroom_teal", "glow_teal", bend=0.05)
    m.box((0.5, 0.16, 0.04), (0.55, -0.7, z + 0.22), "wood", bevel=0.01)
    for sx in (-1, 1):
        m.box((0.04, 0.14, 0.2), (0.55 + sx * 0.2, -0.7, z + 0.11), "wood_dark", bevel=0.005)
    m.lantern_post((-0.75, -0.75, z), 0.9)
    with m.tier(1):
        m.mushroom((0.65, 0.65, z + 0.05), 0.35, 0.16, "mushroom_pink", "glow_pink", bend=0.04)
    with m.tier(2):
        m.crystal_cluster((0.7, 0.1, z), 0.22, "crystal_teal", 3)
