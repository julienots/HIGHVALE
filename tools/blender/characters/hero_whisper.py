"""Héros : Murmure (Espionne silencieuse). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_black", "cloth_purple", weapon=lambda m, x, z: dagger(m, x, z, "glow_violet"), offhand=lambda m, x, z: chakram(m, x, z, "steel_dark"), skin="skin_pale", hair="hair_silver", mask="cloth_black", eyes="glow_violet", hair_style="bob")
