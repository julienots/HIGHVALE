"""Héros : Creux (Épouvantail vivant). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.27
FLAT_PALETTE = True


def build(m):
    hero(m, "straw", "cloth_brown", weapon=lambda m, x, z: scythe(m, x, z), skin="straw", hat=('witch', 'cloth_brown'), eyes="fire", scarf="cloth_red", hair_style="bald")
