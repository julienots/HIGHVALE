"""Briques des créatures. Articulations reconnues dans Godot (monster_rig) :
body (respiration), wingl / wingr (battement), tail (balancement), arml / armr."""
import math


def eyes(m, x, y, z, r=0.022, gap=0.035, mat="dark", glint=True):
    for sx in (-1, 1):
        m.sphere(r, (x + sx * gap, y, z), mat, seg=8, rings=6, scale=(1, 0.7, 1.15))
        if glint:
            m.sphere(r * 0.35, (x + sx * gap + r * 0.3, y - r * 0.55, z + r * 0.35), "cloth_white", seg=6, rings=4)


def wing(m, side, root, span, height, mat="membrane", bone="fur_night"):
    """Aile membraneuse dépliée vers le côté (side = -1 gauche, 1 droite)."""
    x, y, z = root
    pts = [(0, 0, 0), (side * span * 0.5, 0.01, height * 0.6), (side * span, 0.02, height * 0.35),
           (side * span * 0.8, 0.02, -height * 0.15), (side * span * 0.5, 0.01, 0.0), (side * span * 0.25, 0.0, -height * 0.25)]
    faces = [(0, 1, 2, 3, 4, 5)] if side > 0 else [(5, 4, 3, 2, 1, 0)]
    faces.append(tuple(reversed(faces[0])))
    m.poly(pts, faces, (x, y, z), mat)
    m.rod((x, y, z), (x + side * span * 0.5, y + 0.01, z + height * 0.6), 0.008, bone, seg=4)
    m.rod((x + side * span * 0.5, y + 0.01, z + height * 0.6), (x + side * span, y + 0.02, z + height * 0.35), 0.006, bone, seg=4)


def spine_chain(m, pts, radii, mat, scale=(1, 1, 1)):
    for p, r in zip(pts, radii):
        m.sphere(r, p, mat, seg=10, rings=6, scale=scale)
