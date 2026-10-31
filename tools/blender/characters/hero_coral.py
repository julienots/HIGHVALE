"""Héros : Corail (Plongeuse). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_red", "cloth_teal", weapon=lambda m, x, z: dagger(m, x, z, "steel"), offhand=lambda m, x, z: dagger(m, x, z, "steel"), hair="hair_red", goggles="bronze", hair_style="ponytail")
