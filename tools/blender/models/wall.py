"""Rempart (1 × 1) : pilier de pierre crénelé et quatre jonctions (linkpx,
linknx, linkpy, linkny) que le jeu n'affiche que vers les remparts voisins."""
import math

EXTENT = 1.1


def build(m):
    m.ao_height = 0.7
    h = 0.62
    m.box((0.5, 0.5, h), (0, 0, h / 2), "stone", bevel=0.04, tint=m.jitter(0.06))
    m.box((0.56, 0.56, 0.08), (0, 0, 0.04), "stone_dark", bevel=0.02)
    m.box((0.56, 0.56, 0.06), (0, 0, h + 0.03), "stone_dark", bevel=0.02)
    for sx in (-1, 1):
        for sy in (-1, 1):
            m.box((0.16, 0.16, 0.14), (sx * 0.19, sy * 0.19, h + 0.13), "stone", bevel=0.02)
    for name, (dx, dy) in (("linkpx", (1, 0)), ("linknx", (-1, 0)), ("linkpy", (0, 1)), ("linkny", (0, -1))):
        with m.anim(name, (dx * 0.37, dy * 0.37, 0)):
            sx, sy = (0.26, 0.4) if dx else (0.4, 0.26)
            m.box((sx, sy, h - 0.1), (dx * 0.37, dy * 0.37, (h - 0.1) / 2), "stone", bevel=0.03, tint=m.jitter(0.06))
            m.box((sx * 0.6 if dx else sx, sy if dx else sy * 0.6, 0.1), (dx * 0.37, dy * 0.37, h - 0.05), "stone", bevel=0.02)
    with m.tier(1):
        for sx in (-1, 1):
            m.box((0.52, 0.04, 0.05), (0, sx * 0.25, h * 0.55), "iron", bevel=0.005)
    with m.tier(2):
        m.box((0.05, 0.05, 0.05), (0, -0.26, h * 0.75), "gold", bevel=0.01)
        m.box((0.05, 0.05, 0.05), (0, 0.26, h * 0.75), "gold", bevel=0.01)
    with m.tier(3):
        m.crystal((0, 0, h + 0.06), 0.18, 0.05, "crystal")
