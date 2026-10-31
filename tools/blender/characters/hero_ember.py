"""Héros : Braise (Gardienne du foyer). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_red", "steel_dark", weapon=lambda m, x, z: mace(m, x, z, "fire"), offhand=lambda m, x, z: shield(m, x, z, "cloth_red", "steel_dark"), hair="hair_red", armor="steel_dark", glow="fire", hair_style="bob")
