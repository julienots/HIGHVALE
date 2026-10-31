"""Héros : Brasier (Cracheur de feu). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_red", "cloth_brown", weapon=lambda m, x, z: flame_hand(m, x, z), offhand=lambda m, x, z: flame_hand(m, x, z), skin="skin_dark", hair="hair_black", hair_style="mohawk")
