"""Héros : Cendre (Ermite des pics). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_cream", "cloth_brown", weapon=lambda m, x, z: staff(m, x, z, "rune", "wood_dark"), skin="skin_dark", hair="hair_white", beard=True, scarf="cloth_orange", hair_style="bald")
