"""Héros : Serre (Dresseur de chauves-souris). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_black", "leather", weapon=lambda m, x, z: wand(m, x, z, "crystal_violet"), offhand=lambda m, x, z: lantern(m, x, z, "glow_violet"), hair="hair_brown", scarf="cloth_purple", goggles="iron", hair_style="spiky")
