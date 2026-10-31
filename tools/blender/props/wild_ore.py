"""Filon de pierre sauvage (1 case) : rochers veinés d'or, à récolter d'un toucher."""
import math

EXTENT = 1.2


def build(m):
    m.ao_height = 0.5
    m.rock((0, 0, 0), (0.36, 0.32, 0.38), "rock_light", subdiv=2, rough=0.15)
    m.rock((0.2, -0.18, 0), (0.18, 0.16, 0.18), "rock", subdiv=1)
    m.rock((-0.22, 0.12, 0), (0.15, 0.14, 0.14), "rock", subdiv=1)
    for i in range(5):
        a = m.rng.uniform(0, math.tau)
        m.rock((math.cos(a) * 0.2, math.sin(a) * 0.17, 0.14 + m.rng.uniform(0, 0.12)), (0.045, 0.04, 0.035), "gold", subdiv=1)
    m.sphere(0.05, (0.05, 0.05, 0.36), "moss", seg=6, rings=4, scale=(1.4, 1.1, 0.5), smooth=False)
