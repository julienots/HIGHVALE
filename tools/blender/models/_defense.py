"""Briques communes aux défenses : créneaux, socle de tour, mâchicoulis."""
import math


def crenels(m, p0, p1, z, mat="stone", depth=0.16, size=0.2):
    dx, dy = p1[0] - p0[0], p1[1] - p0[1]
    L = math.hypot(dx, dy)
    n = max(2, round(L / size))
    ang = math.degrees(math.atan2(dy, dx))
    for k in range(n):
        if k % 2 == 0:
            t = (k + 0.5) / n
            m.box((L / n - 0.015, depth, size * 0.8), (p0[0] + dx * t, p0[1] + dy * t, z + size * 0.4), mat, rot=(0, 0, ang), bevel=0.015)


def square_ring(m, cx, cy, r, z, mat="stone", depth=0.16, size=0.2):
    pts = [(cx - r, cy - r), (cx + r, cy - r), (cx + r, cy + r), (cx - r, cy + r)]
    for i in range(4):
        crenels(m, pts[i], pts[(i + 1) % 4], z, mat, depth, size)


def round_crenels(m, cx, cy, r, z, mat="stone", n=10, h=0.16):
    for i in range(n):
        a = math.tau * i / n
        m.box((r * 0.42, 0.12, h), (cx + math.cos(a) * r, cy + math.sin(a) * r, z + h / 2), mat,
              rot=(0, 0, math.degrees(a) + 90), bevel=0.015)


def stone_tower(m, cx, cy, r, z, h, mat="stone", band="stone_dark", rings=4):
    m.cyl(r * 1.12, 0.16, (cx, cy, z), band, seg=14, smooth=False)
    m.cyl(r, h, (cx, cy, z + 0.16), mat, r2=r * 0.92, seg=14, smooth=False, tint=m.jitter(0.05))
    for k in range(rings):
        m.torus(r * (1.0 - 0.08 * (k + 0.5) / rings) + 0.005, 0.02, (cx, cy, z + 0.16 + h * (k + 0.5) / rings), band, seg=18, rseg=4)
    return z + 0.16 + h
