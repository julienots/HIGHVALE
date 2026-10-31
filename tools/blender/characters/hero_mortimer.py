"""Héros : Mortimer (Vampire distingué). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_black", "cloth_red", weapon=lambda m, x, z: wand(m, x, z, "fire"), offhand=lambda m, x, z: orb(m, x, z, "shadow_glow"), skin="skin_pale", hair="hair_black", cape="cloth_red", eyes="fire", glow="fire", hair_style="short")
