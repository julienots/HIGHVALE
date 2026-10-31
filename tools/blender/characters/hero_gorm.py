"""Héros : Gorm (Orc des tunnels). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "leather", "cloth_brown", weapon=lambda m, x, z: mace(m, x, z, "iron"), skin="skin_green", hair="hair_black", pauldrons="fur_brown", hair_style="mohawk")
