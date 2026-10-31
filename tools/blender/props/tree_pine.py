"""Sapin de la surface : tronc et étages d'aiguilles."""
EXTENT = 2.4


def build(m):
    m.ao_height = 1.0
    m.cyl(0.14, 0.9, (0, 0, 0), "bark", r2=0.1, seg=8)
    for i in range(5):
        r = 0.95 - i * 0.17
        m.cyl(r, 0.6, (0, 0, 0.55 + i * 0.42), "leaf_dark" if i % 2 else "leaf", r2=0.05, seg=9, tint=m.jitter(0.1), smooth=False)
    for i in range(4):
        m.rock((m.rng.uniform(-0.8, 0.8), m.rng.uniform(-0.8, 0.8), 0), (0.12, 0.1, 0.08), "rock_light")
