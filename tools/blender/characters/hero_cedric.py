"""Héros : Cédric (Porte-étendard). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_blue", "steel", weapon=lambda m, x, z: banner_pole(m, x, z, "cloth_blue"), offhand=lambda m, x, z: shield(m, x, z, "cloth_blue", "gold"), hair="hair_blond", armor="steel", cape="cloth_blue", hair_style="short")
