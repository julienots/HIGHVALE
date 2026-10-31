"""Héros : Mila (Fille-renarde). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_orange", "cloth_white", weapon=lambda m, x, z: dagger(m, x, z, "fire"), offhand=lambda m, x, z: dagger(m, x, z, "fire"), hair="hair_red", ears="cloth_orange", tail="cloth_orange", scarf="cloth_white", hair_style="short")
