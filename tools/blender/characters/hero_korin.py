"""Héros : korin."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "leather", "cloth_brown", skin="skin_dark", hair="hair_black", hair_style="bald", beard=True, armor="iron", pauldrons="iron", weapon=hammer_big)
