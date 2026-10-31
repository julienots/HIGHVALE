"""Héros : Ottilie (Cartographe). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_green", "leather", weapon=lambda m, x, z: tome(m, x, z, "cloth_green"), offhand=lambda m, x, z: lantern(m, x, z), hair="hair_red", hat=('beret', 'cloth_green'), goggles="gold", hair_style="bun")
