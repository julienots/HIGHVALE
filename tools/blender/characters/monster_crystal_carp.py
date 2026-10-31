"""Créature : Carpe de cristal. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["fish"]


def build(m):
    creature(m, "fish", "crystal", "ice", "crystal_violet", eyes="dark", deco=['crystals:crystal'])
