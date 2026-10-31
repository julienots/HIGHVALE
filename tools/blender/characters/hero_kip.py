"""Héros : Kip (Petit ramoneur). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_black", "cloth_brown", weapon=lambda m, x, z: dagger(m, x, z, "steel"), offhand=lambda m, x, z: dagger(m, x, z, "steel"), hair="hair_black", hat=('beret', 'cloth_black'), scarf="cloth_red", hair_style="spiky")
