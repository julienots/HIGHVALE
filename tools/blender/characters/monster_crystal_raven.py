"""Créature : Corbeau de cristal. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["bird"]


def build(m):
    creature(m, "bird", "feather_black", "crystal_violet", "crystal", eyes="crystal", deco=['crystals:crystal_violet'])
