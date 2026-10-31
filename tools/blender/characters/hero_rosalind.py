"""Héros : Rosalinde (Grande prêtresse). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_white", "gold", weapon=lambda m, x, z: staff(m, x, z, "glow_gold", "gold"), offhand=lambda m, x, z: orb(m, x, z, "glow_gold"), skin="skin_dark", hair="hair_white", crown="gold", cape="cloth_white", skirt="cloth_white", glow="glow_gold", hair_style="bun")
