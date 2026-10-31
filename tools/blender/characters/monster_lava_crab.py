"""Créature : Crabe de lave. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["crab"]


def build(m):
    creature(m, "crab", "rock", "lava", "lava", eyes="fire", deco=['flame'])
