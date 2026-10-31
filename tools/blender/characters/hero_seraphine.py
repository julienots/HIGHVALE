"""Héros : seraphine."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_white", "gold", skin="skin_pale", hair="hair_blond", hair_style="long", eyes="eye_glow", crown="gold", armor="gold", cape="cloth_white", skirt="cloth_white", glow="glow_gold", weapon=lambda m, x, z: staff(m, x, z, orb="glow_gold", top="gold"))
