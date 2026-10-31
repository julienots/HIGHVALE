"""Héros : Dorrin (Maître des forges). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "leather", "steel_dark", weapon=lambda m, x, z: sword(m, x, z, "steel", "fire"), skin="skin_dark", hair="hair_white", beard=True, armor="steel_dark", pauldrons="steel_dark", cape="cloth_red", glow="fire", hair_style="bald")
