"""Héros : Hector (Champion de l'Arène). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "leather", "cloth_red", weapon=lambda m, x, z: sword(m, x, z, "steel"), offhand=lambda m, x, z: shield(m, x, z, "cloth_red", "bronze"), skin="skin_dark", hair="hair_black", helmet="bronze", armor="bronze", pauldrons="bronze", cape="cloth_red", hair_style="short")
