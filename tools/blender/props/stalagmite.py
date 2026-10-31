"""Groupe de stalagmites annelées."""
import math

EXTENT = 2.0


def build(m):
    m.ao_height = 1.5
    for (x, y, h, r) in [(0, 0, 2.4, 0.38), (0.45, 0.25, 1.4, 0.25), (-0.35, 0.35, 0.9, 0.2)]:
        n = 7
        for i in range(n):
            t0, t1 = i / n, (i + 1) / n
            r0 = r * (1 - t0) ** 1.2 + 0.02
            r1 = r * (1 - t1) ** 1.2 + 0.01
            m.cyl(r0 * m.rng.uniform(0.95, 1.08), h / n + 0.02, (x + math.sin(t0 * 3) * 0.03, y, h * t0), "rock_light" if i % 2 else "rock",
                  r2=r1, seg=9, rot=(m.rng.uniform(-3, 3), m.rng.uniform(-3, 3), m.rng.uniform(0, 60)), smooth=False)
        m.cyl(r * 1.25, 0.12, (x, y, 0), "rock", r2=r * 0.9, seg=9, smooth=False)
    m.sphere(0.05, (0.0, 0.0, 2.42), "glow_teal", seg=6, rings=4)
