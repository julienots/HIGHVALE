"""Héros : Yseult (Chevalière errante). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "steel", "cloth_purple", weapon=lambda m, x, z: sword(m, x, z, "steel"), offhand=lambda m, x, z: shield(m, x, z, "cloth_purple", "steel"), hair="hair_black", armor="steel", pauldrons="steel", cape="cloth_purple", hair_style="long")
