"""Héros : Kaito (Rônin des profondeurs). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_blue", "cloth_black", weapon=lambda m, x, z: katana(m, x, z, "steel"), skin="skin_pale", hair="hair_black", hat=('bandana', 'cloth_blue'), hair_style="ponytail")
