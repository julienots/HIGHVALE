"""Créature : Crabe de cristal. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["crab"]


def build(m):
    creature(m, "crab", "crystal", "ice", "crystal_violet", eyes="dark", deco=['crystals:crystal'])
