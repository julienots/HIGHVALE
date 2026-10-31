"""Héros : gorrak."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "leather", "cloth_brown", skin="skin_green", hair="hair_black", hair_style="mane", beard=True, eyes="fire", pauldrons="iron", weapon=greataxe, offhand=greataxe)
