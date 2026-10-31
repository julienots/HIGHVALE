"""Héros : draven."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_black", "steel_dark", skin="skin_pale", hair="hair_black", hair_style="spiky", eyes="fire", armor="steel_dark", pauldrons="steel_dark", helmet="steel_dark", cape="cloth_red", glow="fire", weapon=greataxe)
