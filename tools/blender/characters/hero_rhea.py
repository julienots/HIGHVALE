"""Héros : Rhéa (Mère des golems). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_brown", "rock", weapon=lambda m, x, z: staff(m, x, z, "crystal", "rock"), offhand=lambda m, x, z: gauntlet(m, x, z, "rock"), skin="skin_dark", hair="hair_silver", crown="rock_light", cape="cloth_brown", glow="glow_gold", eyes="glow_gold", hair_style="braids")
