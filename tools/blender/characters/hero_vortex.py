"""Héros : Vortex (Invocatrice des failles). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.27
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_purple", "cloth_black", weapon=lambda m, x, z: staff(m, x, z, "crystal_violet", "steel_dark"), offhand=lambda m, x, z: orb(m, x, z, "glow_violet"), skin="skin_pale", hair="hair_silver", horns="crystal_violet", eyes="glow_violet", glow="glow_violet", hair_style="twintails")
