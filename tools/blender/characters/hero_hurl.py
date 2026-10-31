"""Héros : Hurl (Dynamiteur). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_orange", "leather", weapon=lambda m, x, z: flame_hand(m, x, z), hair="hair_black", goggles="bronze", scarf="cloth_red", pouch="leather", hair_style="mohawk")
