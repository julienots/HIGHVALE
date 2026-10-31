"""Héros : Uriel (Ange déchu). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.27
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_white", "gold", weapon=lambda m, x, z: sword(m, x, z, "steel", "glow_gold"), skin="skin_pale", hair="hair_blond", wings="cloth_white", armor="gold", pauldrons="gold", glow="glow_gold", eyes="glow_gold", hair_style="long")
