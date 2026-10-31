"""Héros : Grim (Fossoyeur). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_black", "leather", weapon=lambda m, x, z: scythe(m, x, z), skin="skin_pale", hair="hair_black", hat=('wide', 'cloth_black'), hair_style="short")
