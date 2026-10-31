"""Héros : valdor."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_black", "steel_dark", skin="skin_pale", hair="hair_silver", hair_style="long", eyes="shadow_glow", crown="steel_dark", armor="steel_dark", pauldrons="steel_dark", cape="cloth_red", glow="shadow_glow", weapon=lambda m, x, z: sword(m, x, z, glow="shadow_glow"))
