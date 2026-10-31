"""Héros : Malakar (Seigneur de l'Abîme). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.27
FLAT_PALETTE = True


def build(m):
    hero(m, "steel_dark", "void_skin", weapon=lambda m, x, z: sword(m, x, z, "steel_dark", "glow_violet"), skin="void_skin", hair="hair_black", horns="steel_dark", wings="membrane", armor="steel_dark", pauldrons="steel_dark", cape="cloth_purple", glow="glow_violet", eyes="glow_violet", hair_style="mane")
