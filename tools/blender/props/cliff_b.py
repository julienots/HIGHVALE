"""Falaise de caverne (b) : strates rocheuses, mousse, cristaux et lichens lumineux."""
import math
from props._common import strata_rock, moss_patch, glow_moss

EXTENT = 5.0
VARIANT = "b"


def build(m):
    m.ao_height = 2.5
    m.rng.seed(sum(map(ord, VARIANT)) * 7)
    w, d, h = {"a": (3.6, 3.0, 5.5), "b": (3.0, 2.6, 7.0), "c": (4.2, 3.2, 4.2)}[VARIANT]
    top = strata_rock(m, 0, 0, 0, w, d, h, layers=5)
    for i in range(3):
        a = math.tau * i / 3 + m.rng.uniform(-0.4, 0.4)
        strata_rock(m, math.cos(a) * w * 0.45, math.sin(a) * d * 0.45, 0, w * 0.45, d * 0.45, h * m.rng.uniform(0.3, 0.55), layers=3,
                    mat="rock_light", alt="rock")
    moss_patch(m, 0, 0, top - 0.2, w * 0.25, 7)
    for i in range(4):
        a = m.rng.uniform(0, math.tau)
        moss_patch(m, math.cos(a) * w * 0.4, math.sin(a) * d * 0.4, h * m.rng.uniform(0.2, 0.5), 0.4, 3)
    # Veines de cristaux et lichens lumineux
    a = m.rng.uniform(0, math.tau)
    m.crystal_cluster((math.cos(a) * w * 0.42, math.sin(a) * d * 0.42, h * 0.25), 0.7, ["crystal", "crystal_violet", "crystal_teal"][ord(VARIANT) % 3], 4)
    glow_moss(m, math.cos(a + 1.5) * w * 0.45, math.sin(a + 1.5) * d * 0.45, 0.05, 0.7, 10)
    # Éboulis au pied
    for i in range(8):
        a = m.rng.uniform(0, math.tau)
        m.rock((math.cos(a) * w * 0.62, math.sin(a) * d * 0.62, 0), (0.25, 0.22, 0.18), "rock_light")
