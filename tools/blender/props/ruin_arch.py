"""Pan de mur antique avec arche effondrée et glyphes lumineux."""
import math

EXTENT = 3.0


def build(m):
    m.ao_height = 1.2
    m.brick_wall((-1.3, 0), (-0.55, 0), 0, 1.7, thick=0.35, mat="stone_warm", course=0.28, brick=0.42)
    m.brick_wall((0.55, 0), (1.0, 0), 0, 1.1, thick=0.35, mat="stone_warm", course=0.28, brick=0.42)
    R = 0.55
    for i in range(5):
        a = math.pi - math.pi * (i + 0.5) / 9
        m.box((0.3, 0.38, 0.22), (math.cos(a) * R, 0, 1.25 + math.sin(a) * R), "stone_warm", rot=(0, -math.degrees(a) + 90, 0), bevel=0.03)
    m.box((0.04, 0.03, 0.35), (-0.92, -0.19, 0.9), "rune", bevel=0)
    m.box((0.2, 0.03, 0.04), (-0.92, -0.19, 1.15), "rune", bevel=0)
    for i in range(9):
        m.box((0.3, 0.25, 0.2), (m.rng.uniform(-0.4, 1.2), m.rng.uniform(-0.7, -0.25), 0.1), "stone_warm",
              rot=(m.rng.uniform(-15, 15), m.rng.uniform(-15, 15), m.rng.uniform(0, 90)), bevel=0.03)
    m.sphere(0.15, (-0.9, 0.0, 1.75), "moss", seg=6, rings=4, scale=(1.8, 1.4, 0.5), smooth=False)
