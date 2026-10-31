"""Héros : bram."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_brown", "leather", hair="hair_red", hair_style="short", beard=True, helmet="helmet_yellow", armor="steel_dark", pauldrons="steel_dark", weapon=greataxe)
