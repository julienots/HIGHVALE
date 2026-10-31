"""Héros : Griselda (Herboriste noire). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.27
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_black", "cloth_brown", weapon=lambda m, x, z: staff(m, x, z, "brew_green", "wood_dark"), skin="skin_green", hair="hair_white", hat=('witch', 'cloth_black'), pouch="leather", hair_style="long")
