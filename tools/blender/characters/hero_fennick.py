"""Héros : Fennick (Alchimiste). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_green", "leather", weapon=lambda m, x, z: wand(m, x, z, "brew_green"), offhand=lambda m, x, z: orb(m, x, z, "brew_green"), hair="hair_red", goggles="bronze", pouch="leather", hair_style="short")
