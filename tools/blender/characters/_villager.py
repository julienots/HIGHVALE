"""Habitant de HIGHVALE (style « chibi », environ 0,45 unité de haut).

Pièces animées par src/population/villager.gd (pivots aux articulations) :
  legl / legr : jambes (pivot à la hanche) ; arml / armr : bras (pivot à l'épaule) ;
  body : buste et tête ; carry : charge portée (visible pendant les trajets de retour).
Le personnage regarde vers -Y (= +Z dans Godot)."""
import math

HIP_Z = 0.13
SHOULDER_Z = 0.27


def villager(m, cloth, trousers="cloth_brown", skin="skin", hair="hair_brown", hat=None, tool=None, carry=None, apron=None, beard=False, backpack=False):
    m.ao_height = 0.15
    # Jambes
    for side, name in ((-1, "legl"), (1, "legr")):
        x = side * 0.042
        with m.anim(name, (x, 0, HIP_Z)):
            m.cyl(0.032, 0.09, (x, 0, 0.04), trousers, r2=0.036, seg=8)
            m.box((0.06, 0.085, 0.045), (x, -0.012, 0.022), "leather", bevel=0.015)
    # Buste et tête
    with m.anim("body", (0, 0, HIP_Z)):
        m.cyl(0.075, 0.07, (0, 0, HIP_Z - 0.01), trousers, r2=0.078, seg=12)
        m.cyl(0.08, 0.13, (0, 0, HIP_Z + 0.05), cloth, r2=0.068, seg=12)
        m.torus(0.079, 0.012, (0, 0, HIP_Z + 0.06), "leather", seg=14, rseg=4)
        m.box((0.022, 0.01, 0.018), (0, -0.081, HIP_Z + 0.06), "gold", bevel=0.003)
        if apron:
            m.box((0.1, 0.012, 0.12), (0, -0.074, HIP_Z + 0.05), apron, rot=(4, 0, 0), bevel=0.004)
        if backpack:
            m.box((0.11, 0.07, 0.12), (0, 0.08, HIP_Z + 0.13), "leather", bevel=0.015)
        # Tête
        hz = 0.36
        m.sphere(0.085, (0, 0, hz), skin, seg=14, rings=10)
        for sx in (-1, 1):
            m.sphere(0.012, (sx * 0.03, -0.077, hz + 0.008), "dark", seg=6, rings=4)
            m.sphere(0.013, (sx * 0.085, 0, hz), skin, seg=6, rings=4)
        m.sphere(0.012, (0, -0.088, hz - 0.012), skin, seg=6, rings=4)
        m.box((0.03, 0.006, 0.006), (0, -0.081, hz - 0.035), "skin_dark", bevel=0)
        if beard:
            m.sphere(0.055, (0, -0.045, hz - 0.05), hair, seg=10, rings=6, scale=(1.1, 0.8, 0.9))
        if hat == "helmet":
            m.sphere(0.092, (0, 0, hz + 0.012), "helmet_yellow", seg=14, rings=8, hemi=True)
            m.cyl(0.1, 0.012, (0, 0, hz + 0.008), "helmet_yellow", seg=14)
            m.cyl(0.018, 0.02, (0, -0.088, hz + 0.045), "window", rot=(90, 0, 0), seg=8)
        elif hat == "builder":
            m.sphere(0.092, (0, 0, hz + 0.012), "cloth_orange", seg=14, rings=8, hemi=True)
            m.cyl(0.11, 0.012, (0, -0.01, hz + 0.008), "cloth_orange", seg=14, scale=(1, 1.15, 1))
        elif hat == "straw":
            m.cyl(0.15, 0.012, (0, 0, hz + 0.045), "straw", seg=16)
            m.cyl(0.075, 0.06, (0, 0, hz + 0.05), "straw", r2=0.05, seg=12)
            m.torus(0.072, 0.01, (0, 0, hz + 0.06), "cloth_red", seg=12, rseg=4)
        elif hat == "cap":
            m.sphere(0.09, (0, 0.005, hz + 0.015), "cloth_blue", seg=14, rings=8, hemi=True)
            m.box((0.08, 0.06, 0.01), (0, -0.09, hz + 0.02), "cloth_blue", bevel=0.004)
        elif hat == "bun":
            m.sphere(0.09, (0, 0.012, hz + 0.012), hair, seg=14, rings=8, hemi=True)
            m.sphere(0.042, (0, 0.045, hz + 0.085), hair, seg=10, rings=6)
        else:
            m.sphere(0.089, (0, 0.01, hz + 0.01), hair, seg=14, rings=8, hemi=True)
    # Bras
    for side, name in ((-1, "arml"), (1, "armr")):
        x = side * 0.095
        with m.anim(name, (x, 0, SHOULDER_Z)):
            m.sphere(0.028, (x, 0, SHOULDER_Z), cloth, seg=8, rings=5)
            m.cyl(0.024, 0.11, (x, 0, SHOULDER_Z - 0.12), cloth, r2=0.026, seg=8)
            m.sphere(0.025, (x, 0, SHOULDER_Z - 0.13), skin, seg=8, rings=5)
            if name == "armr" and tool:
                tool(m, x, SHOULDER_Z - 0.13)
    if carry:
        with m.anim("carry", (0, 0, SHOULDER_Z)):
            carry(m)


def pickaxe(m, x, z):
    m.cyl(0.01, 0.2, (x, -0.02, z - 0.04), "wood", rot=(-70, 0, 0), seg=6)
    m.cyl(0.012, 0.14, (x - 0.07, -0.19, z + 0.03), "iron", r2=0.004, rot=(0, 90, 0), seg=6)
    m.cyl(0.012, 0.07, (x, -0.19, z + 0.03), "iron", r2=0.004, rot=(0, 90, 0), seg=6)


def hammer(m, x, z):
    m.cyl(0.01, 0.16, (x, -0.02, z - 0.03), "wood", rot=(-70, 0, 0), seg=6)
    m.box((0.06, 0.035, 0.035), (x, -0.16, z + 0.03), "iron", bevel=0.006)


def sickle(m, x, z):
    m.cyl(0.009, 0.08, (x, -0.01, z - 0.02), "wood", rot=(-60, 0, 0), seg=6)
    m.torus(0.04, 0.006, (x, -0.1, z + 0.04), "iron", rot=(0, 90, 0), seg=10, rseg=3, arc=180)


def carry_stone(m):
    m.rock((0, -0.12, SHOULDER_Z - 0.09), (0.05, 0.045, 0.04), "stone")


def carry_log(m):
    m.cyl(0.03, 0.18, (-0.09, -0.11, SHOULDER_Z - 0.08), "wood", rot=(0, 90, 0), seg=8)
    m.cyl(0.025, 0.003, (0.091, -0.11, SHOULDER_Z - 0.08), "mushroom_teal", rot=(0, 90, 0), seg=8)


def carry_crystal(m):
    m.crystal((0, -0.12, SHOULDER_Z - 0.12), 0.09, 0.025, "crystal")


def carry_crate(m):
    m.box((0.12, 0.1, 0.1), (0, 0.09, SHOULDER_Z + 0.02), "wood_light", bevel=0.01)
    m.box((0.125, 0.105, 0.02), (0, 0.09, SHOULDER_Z + 0.0), "wood_dark", bevel=0.004)


def carry_gold(m):
    m.sphere(0.05, (0, -0.12, SHOULDER_Z - 0.09), "cloth_cream", seg=8, rings=6, scale=(1, 1, 1.1))
    m.cyl(0.02, 0.02, (0, -0.12, SHOULDER_Z - 0.035), "gold", seg=8)
