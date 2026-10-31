"""Éléments partagés par les décors de la caverne."""
import math


def strata_rock(m, x, y, z, w, d, h, layers=4, mat="rock", alt="rock_light"):
    """Formation rocheuse en strates superposées, de plus en plus étroites."""
    zz = z
    for i in range(layers):
        t = i / layers
        sw = w * (1.0 - t * 0.55) * m.rng.uniform(0.9, 1.08)
        sd = d * (1.0 - t * 0.55) * m.rng.uniform(0.9, 1.08)
        lh = h / layers * m.rng.uniform(0.85, 1.2)
        m.rock((x + m.rng.uniform(-0.1, 0.1) * w, y + m.rng.uniform(-0.1, 0.1) * d, zz), (sw / 2, sd / 2, lh * 1.25),
               mat if i % 2 == 0 else alt, subdiv=2, rough=0.12)
        zz += lh * 0.82
    return zz


def moss_patch(m, x, y, z, r, n=5):
    for _ in range(n):
        a = m.rng.uniform(0, math.tau)
        d = m.rng.uniform(0, r)
        m.sphere(m.rng.uniform(0.08, 0.16), (x + math.cos(a) * d, y + math.sin(a) * d, z), "moss", seg=6, rings=4,
                 scale=(1.4, 1.2, 0.45), smooth=False, tint=m.jitter(0.2))


def glow_moss(m, x, y, z, r, n=6, mat="glow_teal"):
    for _ in range(n):
        a = m.rng.uniform(0, math.tau)
        d = m.rng.uniform(0, r)
        m.sphere(m.rng.uniform(0.03, 0.06), (x + math.cos(a) * d, y + math.sin(a) * d, z + 0.02), mat, seg=6, rings=4, scale=(1, 1, 0.6))
