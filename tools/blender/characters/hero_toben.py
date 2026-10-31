"""Héros : toben."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_blue", "steel_dark", skin="skin_dark", hair="hair_black", hair_style="short", armor="steel", pauldrons="steel", helmet="steel", cape="cloth_blue", weapon=sword, offhand=shield)
