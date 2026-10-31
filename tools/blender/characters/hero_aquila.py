"""Héros : Aquila (Chasseur des cimes). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.27
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_blue", "leather", weapon=lambda m, x, z: bow(m, x, z), skin="skin_dark", hair="hair_black", wings="feather_white", hair_style="mohawk")
