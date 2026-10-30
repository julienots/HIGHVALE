"""Infirmerie : maison blanche à colombages, croix rouge lumineuse,
lits sous auvent, jardin d'herbes et étagère de potions."""
import math

EXTENT = 3.0


def build(m):
    z = m.flagstone_plinth(2.94, 2.94, mat="marble", curb="stone_dark")
    cx, cy = -0.15, 0.45
    m.timber_walls(cx, cy, 1.9, 1.15, z, 0.8, wall="plaster", beam="wood")
    m.gable_roof((cx, cy, z + 0.8), 1.9, 1.15, 0.6, "roof_red", overhang=0.15, rows=5, gable="plaster")
    m.door((cx, cy - 0.6, z), 0, w=0.36, h=0.52, frame="wood_dark")
    for wx in (-0.6, 0.6):
        m.window((cx + wx, cy - 0.6, z + 0.25), 0, w=0.26, h=0.32, shutters="cloth_red")
    m.window((cx + 0.97, cy, z + 0.25), 90, w=0.26, h=0.32, shutters="cloth_red")
    # Croix lumineuse
    m.box((0.36, 0.06, 0.1), (cx, cy - 0.62, z + 0.68), "cloth_red", bevel=0.01)
    m.box((0.1, 0.06, 0.36), (cx, cy - 0.62, z + 0.68), "cloth_red", bevel=0.01)
    m.box((0.3, 0.02, 0.06), (cx, cy - 0.66, z + 0.68), "glow_pink", bevel=0)
    # Auvent et lits
    for px in (0.45, 1.25):
        for py in (-0.35, -1.15):
            m.box((0.06, 0.06, 0.8), (px, py, z + 0.4), "wood", bevel=0.01)
    for i in range(5):
        m.box((0.95, 0.2, 0.03), (0.85, -1.15 + i * 0.19, z + 0.82), "cloth_cream" if i % 2 else "cloth_red", rot=(8, 0, 0), bevel=0.005)
    for by in (-0.55, -0.95):
        m.box((0.6, 0.28, 0.16), (0.85, by, z + 0.16), "wood", bevel=0.02)
        m.box((0.56, 0.26, 0.06), (0.85, by, z + 0.27), "cloth_cream", bevel=0.02)
        m.box((0.14, 0.2, 0.06), (0.62, by, z + 0.32), "cloth_cream", bevel=0.03)
        m.box((0.3, 0.27, 0.03), (0.92, by, z + 0.31), "cloth_blue", bevel=0.01)
    # Jardin d'herbes
    m.box((0.9, 0.4, 0.14), (-0.85, -0.85, z + 0.07), "wood", bevel=0.02)
    m.box((0.82, 0.32, 0.03), (-0.85, -0.85, z + 0.14), "earth", bevel=0)
    for i in range(7):
        m.sphere(0.07, (-1.2 + i * 0.12, -0.85 + m.rng.uniform(-0.08, 0.08), z + 0.18), m.rng.choice(["moss", "moss", "mushroom_pink"]), seg=6, rings=4, scale=(1, 1, 1.3), smooth=False)
    # Étagère de potions
    m.box((0.5, 0.18, 0.04), (-1.15, 0.0, z + 0.4), "wood", bevel=0.01)
    m.box((0.5, 0.18, 0.04), (-1.15, 0.0, z + 0.7), "wood", bevel=0.01)
    for sx in (-1, 1):
        m.box((0.04, 0.18, 0.75), (-1.15 + sx * 0.25, 0.0, z + 0.37), "wood_dark", bevel=0.01)
    for i, mat in enumerate(["brew_green", "glow_pink", "brew_violet", "brew_green", "glow_teal", "brew_violet"]):
        sh = 0.42 if i < 3 else 0.72
        m.sphere(0.05, (-1.3 + (i % 3) * 0.15, 0.0, sh + z + 0.05), mat, seg=8, rings=5)
        m.cyl(0.018, 0.06, (-1.3 + (i % 3) * 0.15, 0.0, sh + z + 0.09), "glass", seg=6)
    with m.tier(1):
        m.lantern_post((-0.3, -1.25, z), 1.0)
    with m.tier(2):
        m.banner((1.3, 0.9, z), 1.3, "cloth_red")
    with m.tier(3):
        m.crystal_cluster((-1.2, 1.15, z), 0.35, "crystal_teal")
