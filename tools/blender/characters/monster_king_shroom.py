"""Créature : Roi des champignons. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["plant"]


def build(m):
    creature(m, "plant", "mushroom_stem", "mushroom_violet", "glow_violet", eyes="glow_violet", deco=['crown:gold'], kind='mushroom')
