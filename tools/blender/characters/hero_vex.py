"""Héros : Vex (Voleur de l'ombre). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_black", "leather", weapon=lambda m, x, z: dagger(m, x, z), offhand=lambda m, x, z: dagger(m, x, z), hair="hair_black", hood="cloth_black", mask="cloth_black", hair_style="short")
