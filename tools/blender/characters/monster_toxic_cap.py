"""Créature : Amanite toxique. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["plant"]


def build(m):
    creature(m, "plant", "mushroom_stem", "feather_red", "cloth_white", eyes="dark", deco=[], kind='mushroom')
