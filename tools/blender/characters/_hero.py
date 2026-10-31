"""Héros de HIGHVALE : silhouette chibi héroïque (environ 0,5 unité), armures,
capes, coiffures et armes variées. Mêmes articulations que les habitants
(legl, legr, arml, armr, body) pour l'animation dans Godot."""
import math

HIP_Z = 0.14
SHOULDER_Z = 0.29
HEAD_Z = 0.4


def _hair(m, style, mat, hz):
    if style == "short":
        m.sphere(0.096, (0, 0.012, hz + 0.012), mat, seg=14, rings=8, hemi=True)
    elif style == "spiky":
        m.sphere(0.094, (0, 0.012, hz + 0.01), mat, seg=12, rings=8, hemi=True)
        for i in range(7):
            a = math.pi * (0.15 + 0.7 * i / 6)
            m.cyl(0.03, 0.09, (math.cos(a) * 0.06, 0.03 + math.sin(a) * 0.02, hz + 0.06), mat, r2=0.0, seg=5,
                  rot=(-25 - i % 2 * 15, (i - 3) * 14, 0), smooth=False)
    elif style == "long":
        m.sphere(0.098, (0, 0.012, hz + 0.01), mat, seg=14, rings=8, hemi=True)
        m.box((0.18, 0.06, 0.2), (0, 0.06, hz - 0.07), mat, bevel=0.03)
        for sx in (-1, 1):
            m.box((0.04, 0.05, 0.16), (sx * 0.085, -0.02, hz - 0.06), mat, bevel=0.015)
    elif style == "ponytail":
        m.sphere(0.096, (0, 0.012, hz + 0.012), mat, seg=14, rings=8, hemi=True)
        m.rod((0, 0.09, hz + 0.05), (0, 0.15, hz - 0.12), 0.035, mat, seg=8, r2=0.012)
        m.torus(0.03, 0.01, (0, 0.1, hz + 0.03), "gold", rot=(70, 0, 0), seg=10, rseg=4)
    elif style == "bald":
        pass
    elif style == "mane":
        m.sphere(0.1, (0, 0.065, hz + 0.01), mat, seg=14, rings=8, scale=(1.2, 1.0, 1.12))
        for sx in (-1, 1):
            m.sphere(0.045, (sx * 0.09, 0.0, hz - 0.03), mat, seg=8, rings=5, scale=(0.8, 1.0, 1.3))


def hero(m, outfit, outfit2="leather", skin="skin", hair="hair_brown", hair_style="short", armor=None, cape=None,
         helmet=None, crown=None, hood=None, weapon=None, offhand=None, beard=False, eyes="dark", pauldrons=None,
         skirt=None, glow=None):
    m.ao_height = 0.2
    for side, name in ((-1, "legl"), (1, "legr")):
        x = side * 0.046
        with m.anim(name, (x, 0, HIP_Z)):
            m.cyl(0.034, 0.1, (x, 0, 0.045), outfit2, r2=0.038, seg=10)
            m.box((0.066, 0.095, 0.05), (x, -0.012, 0.025), armor or "leather", bevel=0.016)
            m.cyl(0.042, 0.025, (x, 0, 0.06), armor or "leather", seg=10)
    with m.anim("body", (0, 0, HIP_Z)):
        m.cyl(0.08, 0.07, (0, 0, HIP_Z - 0.01), outfit2, r2=0.084, seg=14)
        m.cyl(0.088, 0.14, (0, 0, HIP_Z + 0.05), outfit, r2=0.074, seg=14)
        if skirt:
            m.cyl(0.11, 0.1, (0, 0, HIP_Z - 0.05), skirt, r2=0.085, seg=14)
        if armor:
            m.cyl(0.092, 0.1, (0, -0.004, HIP_Z + 0.09), armor, r2=0.08, seg=14, scale=(1, 0.9, 1))
            m.box((0.05, 0.02, 0.06), (0, -0.085, HIP_Z + 0.13), glow or "gold", bevel=0.008)
        m.torus(0.086, 0.014, (0, 0, HIP_Z + 0.055), "leather", seg=16, rseg=4)
        m.box((0.03, 0.012, 0.024), (0, -0.088, HIP_Z + 0.055), "gold", bevel=0.004)
        if cape:
            verts, faces = [], []
            for j in range(5):
                for i in range(5):
                    u, v = i / 4, j / 4
                    w = 0.09 + v * 0.07
                    verts.append(((u - 0.5) * 2 * w, 0.085 + v * 0.05 + math.sin(u * 6.28) * 0.012 * v, SHOULDER_Z - 0.01 - v * 0.27))
            for j in range(4):
                for i in range(4):
                    a = j * 5 + i
                    faces.append((a, a + 1, a + 6, a + 5))
                    faces.append((a + 5, a + 6, a + 1, a))
            m.poly(verts, faces, (0, 0, 0), cape, smooth=True)
        # Tête
        hz = HEAD_Z
        m.sphere(0.092, (0, 0, hz), skin, seg=16, rings=10)
        for sx in (-1, 1):
            m.sphere(0.014, (sx * 0.033, -0.083, hz + 0.008), eyes, seg=6, rings=4, scale=(1, 0.7, 1.25))
            m.box((0.03, 0.008, 0.008), (sx * 0.034, -0.086, hz + 0.034), "hair_black" if hair != "hair_white" else "hair_white", rot=(0, sx * 10, 0), bevel=0)
            m.sphere(0.014, (sx * 0.092, 0, hz), skin, seg=6, rings=4)
        m.sphere(0.012, (0, -0.094, hz - 0.012), skin, seg=6, rings=4)
        m.box((0.032, 0.006, 0.006), (0, -0.087, hz - 0.038), "skin_dark", bevel=0)
        if beard:
            m.sphere(0.06, (0, -0.05, hz - 0.055), hair, seg=10, rings=6, scale=(1.15, 0.85, 1.0))
        if hood:
            m.sphere(0.106, (0, 0.045, hz + 0.012), hood, seg=14, rings=8, scale=(1.02, 1.0, 1.08))
            m.torus(0.088, 0.018, (0, -0.045, hz + 0.0), hood, rot=(90, 0, 0), seg=16, rseg=5)
            m.cyl(0.03, 0.08, (0, 0.13, hz - 0.02), hood, r2=0.0, rot=(-70, 0, 0), seg=6)
        else:
            _hair(m, hair_style, hair, hz)
        if helmet:
            m.sphere(0.1, (0, 0, hz + 0.01), helmet, seg=14, rings=8, hemi=True)
            m.torus(0.098, 0.014, (0, 0, hz + 0.012), "gold", seg=16, rseg=4)
            m.box((0.02, 0.03, 0.08), (0, -0.09, hz + 0.0), helmet, bevel=0.006)
            m.cyl(0.012, 0.09, (0, 0.01, hz + 0.1), "cloth_red", r2=0.03, rot=(-30, 0, 0), seg=6)
        if crown:
            m.torus(0.075, 0.014, (0, 0.005, hz + 0.075), crown, seg=16, rseg=4)
            for i in range(5):
                a = math.pi * (0.2 + 0.6 * i / 4)
                m.cyl(0.013, 0.05, (math.cos(a) * 0.072, -math.sin(a) * 0.072 + 0.005, hz + 0.08), crown, r2=0.0, seg=5)
            m.crystal((0, -0.075, hz + 0.08), 0.05, 0.014, "crystal")
    for side, name in ((-1, "arml"), (1, "armr")):
        x = side * 0.104
        with m.anim(name, (x, 0, SHOULDER_Z)):
            if pauldrons:
                m.sphere(0.045, (x, 0, SHOULDER_Z + 0.005), pauldrons, seg=10, rings=6, hemi=True, scale=(1.1, 1.0, 0.8))
            else:
                m.sphere(0.03, (x, 0, SHOULDER_Z), outfit, seg=8, rings=5)
            m.cyl(0.026, 0.12, (x, 0, SHOULDER_Z - 0.13), outfit, r2=0.028, seg=8)
            m.cyl(0.031, 0.04, (x, 0, SHOULDER_Z - 0.14), armor or outfit2, seg=8)
            m.sphere(0.027, (x, 0, SHOULDER_Z - 0.145), skin, seg=8, rings=5)
            if name == "armr" and weapon:
                weapon(m, x, SHOULDER_Z - 0.145)
            if name == "arml" and offhand:
                offhand(m, x, SHOULDER_Z - 0.145)


# --- Armes (tenues dans la main, pointées vers l'avant/le haut) -------------

def sword(m, x, z, blade="steel", glow=None):
    m.cyl(0.012, 0.06, (x, -0.01, z - 0.03), "leather", seg=6)
    m.box((0.07, 0.02, 0.016), (x, -0.01, z + 0.03), "gold", bevel=0.004)
    m.box((0.026, 0.008, 0.2), (x, -0.01, z + 0.14), glow or blade, bevel=0.003)
    m.cyl(0.013, 0.03, (x, -0.01, z + 0.24), glow or blade, r2=0.0, seg=4, rot=(0, 0, 45))


def greataxe(m, x, z):
    m.cyl(0.012, 0.32, (x, -0.01, z - 0.06), "wood_dark", seg=6)
    m.cyl(0.07, 0.012, (x + 0.035, -0.016, z + 0.2), "steel", seg=12, rot=(90, 0, 0), scale=(1, 1.3, 1))
    m.cyl(0.05, 0.012, (x - 0.025, -0.016, z + 0.2), "steel", seg=12, rot=(90, 0, 0), scale=(1, 1.3, 1))
    m.box((0.03, 0.03, 0.05), (x, -0.01, z + 0.2), "steel_dark", bevel=0.006)


def bow(m, x, z):
    m.torus(0.13, 0.008, (x, -0.02, z + 0.02), "wood", rot=(0, 90, 0), seg=14, rseg=4, arc=150)
    m.rod((x, -0.02 + 0.0, z + 0.15), (x, -0.02, z - 0.11), 0.002, "cloth_white", seg=3)


def staff(m, x, z, orb="crystal", top="gold"):
    m.cyl(0.011, 0.42, (x, -0.02, z - 0.12), "wood_dark", seg=6)
    m.torus(0.03, 0.008, (x, -0.02, z + 0.31), top, rot=(90, 0, 0), seg=10, rseg=4)
    if orb.startswith("crystal"):
        m.crystal((x, -0.02, z + 0.29), 0.09, 0.022, orb)
    else:
        m.sphere(0.03, (x, -0.02, z + 0.32), orb, seg=10, rings=6)


def dagger(m, x, z, glow="shadow_glow"):
    m.cyl(0.01, 0.04, (x, -0.01, z - 0.02), "leather", seg=6)
    m.box((0.04, 0.012, 0.012), (x, -0.01, z + 0.02), "steel_dark", bevel=0.003)
    m.box((0.02, 0.006, 0.1), (x, -0.01, z + 0.07), glow, bevel=0.002)


def shield(m, x, z, face="cloth_blue", rim="gold"):
    sx = -1 if x < 0 else 1
    m.cyl(0.085, 0.02, (x + sx * 0.03, -0.01, z + 0.04), face, rot=(0, 90, 0), seg=16)
    m.torus(0.085, 0.012, (x + sx * 0.04, -0.01, z + 0.04), rim, rot=(0, 90, 0), seg=16, rseg=4)
    m.sphere(0.022, (x + sx * 0.05, -0.01, z + 0.04), rim, seg=8, rings=5)


def book(m, x, z, cover="cloth_purple"):
    m.box((0.07, 0.09, 0.02), (x, -0.05, z + 0.02), cover, rot=(20, 0, 0), bevel=0.006)
    m.box((0.06, 0.085, 0.022), (x + 0.004, -0.05, z + 0.02), "cloth_cream", rot=(20, 0, 0), bevel=0.003)
    m.sphere(0.03, (x, -0.06, z + 0.09), "rune", seg=8, rings=5)


def hammer_big(m, x, z):
    m.cyl(0.012, 0.3, (x, -0.01, z - 0.06), "wood", seg=6)
    m.box((0.1, 0.05, 0.06), (x, -0.01, z + 0.22), "steel_dark", bevel=0.01)


def wrench(m, x, z):
    m.cyl(0.01, 0.14, (x, -0.01, z - 0.02), "iron", seg=6)
    m.torus(0.025, 0.01, (x, -0.01, z + 0.13), "iron", rot=(90, 0, 0), seg=10, rseg=4, arc=270)


def scythe(m, x, z):
    m.cyl(0.011, 0.42, (x, -0.02, z - 0.12), "wood_dark", seg=6)
    m.torus(0.1, 0.012, (x - 0.1, -0.02, z + 0.3), "shadow_glow", rot=(90, 0, 0), seg=12, rseg=4, arc=110)


def flame_hand(m, x, z):
    m.sphere(0.04, (x, -0.04, z + 0.03), "fire", seg=8, rings=6, scale=(1, 1, 1.4))
