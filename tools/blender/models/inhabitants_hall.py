"""Hôtel des habitants : maison à colombages sur rez-de-chaussée en pierre,
toit de tuiles bleues, annexe, balcon fleuri et tourelle aux niveaux supérieurs."""
import math

EXTENT = 3.0


def build(m):
    z = m.flagstone_plinth(2.94, 2.94, mat="stone_warm", curb="stone_dark")
    cx, cy, w, d = -0.3, 0.3, 1.7, 1.25
    # Rez-de-chaussée en pierre
    h1 = 0.62
    hw, hd = w / 2, d / 2
    for a, b in [((cx - hw, cy - hd), (cx + hw, cy - hd)), ((cx + hw, cy - hd), (cx + hw, cy + hd)),
                 ((cx + hw, cy + hd), (cx - hw, cy + hd)), ((cx - hw, cy + hd), (cx - hw, cy - hd))]:
        m.brick_wall(a, b, z, h1, thick=0.16, mat="stone", course=0.155, brick=0.3)
    m.box((w - 0.2, d - 0.2, h1), (cx, cy, z + h1 / 2), "stone_dark", bevel=0)
    m.box((w + 0.1, d + 0.1, 0.07), (cx, cy, z + h1 + 0.035), "wood_dark", bevel=0.015)
    # Étage à colombages (encorbellement)
    z2 = z + h1 + 0.07
    h2 = 0.62
    m.timber_walls(cx, cy, w + 0.06, d + 0.06, z2, h2)
    # Toit
    m.gable_roof((cx, cy, z2 + h2), w + 0.06, d + 0.06, 0.62, "roof_blue", overhang=0.16, rows=5)
    # Cheminée
    m.box((0.22, 0.22, 0.75), (cx - 0.5, cy + 0.32, z2 + h2 + 0.3), "stone", bevel=0.02)
    m.box((0.28, 0.28, 0.06), (cx - 0.5, cy + 0.32, z2 + h2 + 0.7), "stone_dark", bevel=0.015)
    # Façade : porte et fenêtres
    fy = cy - hd - 0.08
    m.door((cx, fy + 0.02, z), 0, w=0.36, h=0.46, frame="stone_dark")
    for wx in (-0.55, 0.55):
        m.window((cx + wx, fy, z + 0.16), 0, w=0.24, h=0.3, shutters="roof_blue")
    for wx in (-0.5, 0.0, 0.5):
        m.window((cx + wx, cy - hd - 0.05, z2 + 0.14), 0, w=0.22, h=0.3, frame="wood_dark")
    for wy in (-0.25, 0.3):
        m.window((cx + hw + 0.05, cy + wy, z2 + 0.14), 90, w=0.22, h=0.3)
    m.window((cx + hw + 0.09, cy, z + 0.16), 90, w=0.24, h=0.3, shutters="roof_blue")
    # Auvent de porte
    m.box((0.6, 0.3, 0.04), (cx, fy - 0.12, z + 0.62), "roof_blue", rot=(-20, 0, 0), bevel=0.01)
    for sx in (-1, 1):
        m.rod((cx + sx * 0.26, fy - 0.24, z), (cx + sx * 0.26, fy - 0.24, z + 0.58), 0.025, "wood_dark", seg=6)
    # Annexe
    ax, ay = 0.88, -0.6
    m.timber_walls(ax, ay, 0.78, 0.74, z, 0.55, wall="plaster", bay=0.38)
    m.gable_roof((ax, ay, z + 0.55), 0.78, 0.74, 0.42, "roof_red", overhang=0.12, rows=4, rot_z=90)
    m.door((ax, ay - 0.39, z), 0, w=0.26, h=0.38, arch=False, frame="wood_dark")
    m.window((ax + 0.4, ay, z + 0.18), 90, w=0.2, h=0.24, shutters="roof_red")
    # Abords
    m.lantern_post((-1.15, -1.15, z))
    m.barrel((-1.2, -0.55, z))
    m.barrel((-1.05, -0.35, z), r=0.12, h=0.3)
    m.crate((0.4, 1.15, z), 0.28, 15)
    m.box((0.5, 0.14, 0.05), (0.05, -1.25, z + 0.22), "wood", bevel=0.01)
    for sx in (-0.2, 0.2):
        m.box((0.05, 0.12, 0.22), (0.05 + sx, -1.25, z + 0.11), "wood_dark", bevel=0.01)
    # Niveau 3+ : balcon fleuri
    with m.tier(1):
        by = cy - hd - 0.22
        m.box((1.1, 0.3, 0.05), (cx, by, z2 - 0.02), "wood", bevel=0.01)
        for i in range(7):
            m.box((0.03, 0.03, 0.25), (cx - 0.52 + i * 0.173, by - 0.13, z2 + 0.12), "wood_dark", bevel=0)
        m.box((1.1, 0.04, 0.04), (cx, by - 0.13, z2 + 0.25), "wood_dark", bevel=0.01)
        for i in range(4):
            fx = cx - 0.42 + i * 0.28
            m.box((0.2, 0.08, 0.07), (fx, by - 0.17, z2 + 0.26), "wood", bevel=0.01)
            for k in range(3):
                m.sphere(0.035, (fx - 0.06 + k * 0.06, by - 0.17, z2 + 0.32), ["mushroom_pink", "moss", "mushroom_violet"][(i + k) % 3], seg=6, rings=4)
    # Niveau 5+ : tourelle
    with m.tier(2):
        tx, ty = 0.95, 0.85
        m.cyl(0.32, 1.45, (tx, ty, z), "stone", seg=14, smooth=False)
        for i in range(5):
            m.torus(0.325, 0.02, (tx, ty, z + 0.2 + i * 0.27), "stone_dark", seg=14, rseg=4)
        m.window((tx, ty - 0.33, z + 0.75), 0, w=0.16, h=0.24, arch=True)
        m.cone_roof((tx, ty, z + 1.45), 0.42, 0.75, "roof_blue", rings=5)
    # Niveau 7+ : girouette dorée et bannières
    with m.tier(3):
        m.cyl(0.015, 0.4, (cx, cy, z2 + h2 + 0.62), "gold", seg=6)
        m.box((0.3, 0.02, 0.08), (cx + 0.08, cy, z2 + h2 + 0.95), "gold", bevel=0)
        m.banner((-1.25, 0.6, z), 1.3, "cloth_blue")
