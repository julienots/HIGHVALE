"""Héros : Lumen (Porteuse de lanterne). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_cream", "cloth_blue", weapon=lambda m, x, z: lantern(m, x, z), offhand=lambda m, x, z: wand(m, x, z, "glow_gold"), hair="hair_blond", hood="cloth_blue", hair_style="bob")
