"""Héros : Lyre (Barde errant). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_red", "cloth_brown", weapon=lambda m, x, z: lute(m, x, z), hair="hair_brown", hat=('beret', 'cloth_red'), cape="cloth_green", hair_style="short")
