"""Créature : Taupe cristalline. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["quad"]


def build(m):
    creature(m, "quad", "fur_grey", "skin_pale", "crystal", eyes="dark", deco=['crystals:crystal_violet'], ears='none', legs='short', snout=0.06)
