"""Arbre feuillu de la surface : tronc noueux et houppier en boules."""
import math

EXTENT = 2.4


def build(m):
    m.ao_height = 1.0
    m.rod((0, 0, 0), (0.05, 0.02, 1.3), 0.16, "bark", seg=8, r2=0.1)
    m.rod((0.03, 0, 0.9), (0.45, 0.1, 1.4), 0.07, "bark", seg=6)
    for i in range(7):
        a = math.tau * i / 7
        r = 0.45 + m.rng.uniform(-0.1, 0.15)
        m.sphere(r, (math.cos(a) * 0.45, math.sin(a) * 0.4, 1.7 + m.rng.uniform(-0.15, 0.25)), "leaf" if i % 3 else "leaf_autumn", seg=10, rings=6, smooth=False, tint=m.jitter(0.12))
    m.sphere(0.6, (0.05, 0, 2.05), "leaf", seg=10, rings=6, smooth=False)
    for i in range(6):
        a = m.rng.uniform(0, math.tau)
        m.sphere(0.08, (math.cos(a) * 0.7, math.sin(a) * 0.7, 0.03), "grass", seg=6, rings=4, scale=(1.4, 1.4, 0.6), smooth=False)
