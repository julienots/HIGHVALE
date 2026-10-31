"""Héros : Isolde (Capitaine de la Garde). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "steel", "cloth_white", weapon=lambda m, x, z: sword(m, x, z, "steel", "glow_gold"), offhand=lambda m, x, z: shield(m, x, z, "cloth_white", "gold"), skin="skin_dark", hair="hair_black", armor="gold", pauldrons="gold", cape="cloth_white", glow="glow_gold", hair_style="braids")
