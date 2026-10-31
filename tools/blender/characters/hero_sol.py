"""Héros : sol."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_white", "gold", skin="skin_dark", hair="hair_black", hair_style="short", armor="gold", pauldrons="gold", helmet="gold", cape="cloth_white", glow="glow_gold", weapon=lambda m, x, z: sword(m, x, z, glow="glow_gold"), offhand=lambda m, x, z: shield(m, x, z, "cloth_white", "gold"))
