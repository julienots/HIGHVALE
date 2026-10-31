"""Bosquet de champignons géants (teal)."""
import math
from props._common import glow_moss

EXTENT = 2.6


def build(m):
    m.ao_height = 1.0
    cap, glow = "mushroom_teal", "glow_teal"
    m.mushroom((0, 0, 0), 1.9, 0.75, cap, glow, bend=0.22, lean=0.8, spots=8)
    m.mushroom((0.65, -0.3, 0), 1.1, 0.45, cap, glow, bend=0.12, lean=3.0)
    m.mushroom((-0.45, 0.5, 0), 0.7, 0.3, cap, glow, bend=0.08, lean=4.5)
    for i in range(6):
        a = m.rng.uniform(0, math.tau)
        d = m.rng.uniform(0.5, 1.0)
        m.mushroom((math.cos(a) * d, math.sin(a) * d, 0), m.rng.uniform(0.15, 0.3), m.rng.uniform(0.07, 0.12), cap, glow, bend=0.02, spots=0)
    glow_moss(m, 0, 0, 0, 1.0, 8, glow)
