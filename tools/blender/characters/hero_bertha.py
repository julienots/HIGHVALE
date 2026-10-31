"""Héros : Bertha (Cuisinière de la caserne). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_white", "cloth_red", weapon=lambda m, x, z: mace(m, x, z, "wood_light"), offhand=lambda m, x, z: lantern(m, x, z, "fire"), hair="hair_red", hat=('bandana', 'cloth_white'), hair_style="bun")
