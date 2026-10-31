"""Héros : Idris (Sage du désert). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_cream", "cloth_orange", weapon=lambda m, x, z: staff(m, x, z, "glow_gold", "wood_dark"), offhand=lambda m, x, z: orb(m, x, z, "glow_gold"), skin="skin_dark", hair="hair_white", beard=True, hat=('bandana', 'cloth_orange'), hair_style="bald")
