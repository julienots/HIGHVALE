"""Gros rocher moussu avec galets."""
import math
from props._common import moss_patch

EXTENT = 2.0


def build(m):
    m.ao_height = 0.8
    m.rock((0, 0, 0), (0.75, 0.65, 0.85), "rock", subdiv=2, rough=0.14)
    m.rock((0.55, -0.35, 0), (0.4, 0.35, 0.45), "rock_light", subdiv=2, rough=0.14)
    moss_patch(m, -0.1, 0.05, 0.62, 0.35, 6)
    for i in range(5):
        a = m.rng.uniform(0, math.tau)
        m.rock((math.cos(a) * 0.9, math.sin(a) * 0.8, 0), (0.12, 0.11, 0.09), "rock_light")
