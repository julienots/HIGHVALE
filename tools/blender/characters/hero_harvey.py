"""Héros : Harvey (Fermier des plaines). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_blue", "cloth_brown", weapon=lambda m, x, z: trident(m, x, z, "iron"), hair="hair_blond", hat=('wide', 'straw'), hair_style="short")
