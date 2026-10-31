"""Créature : Ver de cristal. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["serpent"]


def build(m):
    creature(m, "serpent", "crystal", "ice", "crystal_violet", eyes="dark", deco=['crystals:crystal'], segments=8)
