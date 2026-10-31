"""Créature : Mante de cristal. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["insect"]


def build(m):
    creature(m, "insect", "crystal", "ice", "crystal_violet", eyes="crystal", deco=['crystals:crystal'], wings='glass')
