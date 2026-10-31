"""Héros : Fizz (Artificière). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_red", "cloth_black", weapon=lambda m, x, z: wand(m, x, z, "fire"), offhand=lambda m, x, z: flame_hand(m, x, z), hair="hair_blond", goggles="bronze", pouch="leather", hair_style="twintails")
