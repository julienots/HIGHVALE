"""Champignons sauvages (1 case) : petite talle lumineuse à cueillir."""
import math

EXTENT = 1.2


def build(m):
    m.ao_height = 0.4
    m.sphere(0.34, (0, 0, 0), "earth", seg=10, rings=5, hemi=True, scale=(1, 1, 0.18))
    m.mushroom((0, 0, 0.04), 0.42, 0.2, "mushroom_violet", "glow_violet", bend=0.05, lean=1.0, spots=4)
    m.mushroom((0.17, -0.12, 0.03), 0.26, 0.12, "mushroom_teal", "glow_teal", bend=0.03, lean=3.0, spots=3)
    m.mushroom((-0.16, 0.1, 0.03), 0.2, 0.09, "mushroom_pink", "glow_pink", bend=0.02, spots=0)
    for i in range(4):
        a = m.rng.uniform(0, math.tau)
        m.sphere(0.04, (math.cos(a) * 0.25, math.sin(a) * 0.25, 0.03), "moss", seg=6, rings=4, scale=(1.3, 1.3, 0.6), smooth=False)
