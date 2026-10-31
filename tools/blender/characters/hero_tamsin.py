"""Héros : Tamsin (Infirmière de campagne). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_white", "cloth_red", weapon=lambda m, x, z: wand(m, x, z, "glow_pink"), hair="hair_brown", hat=('bandana', 'cloth_white'), pouch="leather", hair_style="bun")
