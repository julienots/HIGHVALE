"""Colonne antique brisée, tambours tombés et dalles fissurées."""
import math

EXTENT = 2.4


def build(m):
    m.ao_height = 1.0
    m.box((1.1, 1.1, 0.18), (0, 0, 0.09), "stone_warm", rot=(0, 0, 6), bevel=0.04)
    m.box((0.6, 0.6, 0.14), (0, 0, 0.25), "stone_warm", bevel=0.03)
    h = 1.6
    m.cyl(0.24, h, (0, 0, 0.32), "stone_warm", r2=0.21, seg=14, rot=(4, -3, 0))
    for i in range(10):
        a = math.tau * i / 10
        m.box((0.04, 0.04, h - 0.1), (math.cos(a) * 0.22, math.sin(a) * 0.22, 0.32 + h / 2), "stone_warm", rot=(4, -3, math.degrees(a)), bevel=0.01, tint=0.85)
    # Cassure irrégulière
    for i in range(5):
        a = math.tau * i / 5
        m.box((0.16, 0.16, m.rng.uniform(0.05, 0.22)), (math.cos(a) * 0.12, math.sin(a) * 0.12 + 0.05, 0.32 + h), "stone_warm", rot=(0, 0, m.rng.uniform(0, 90)), bevel=0.03)
    m.cyl(0.23, 0.5, (0.75, 0.3, 0.22), "stone_warm", rot=(0, 90, 30), seg=14)
    m.cyl(0.22, 0.35, (-0.6, 0.55, 0.22), "stone_warm", rot=(90, 0, -20), seg=14)
    m.sphere(0.12, (0.15, -0.1, 1.98), "moss", seg=6, rings=4, scale=(1.5, 1.2, 0.5), smooth=False)
    for i in range(6):
        a = m.rng.uniform(0, math.tau)
        m.rock((math.cos(a) * 0.8, math.sin(a) * 0.8, 0), (0.12, 0.1, 0.08), "stone_warm")
