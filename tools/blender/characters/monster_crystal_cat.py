"""Créature : Chat de cristal. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["quad"]


def build(m):
    creature(m, "quad", "fur_grey", "fur_white", "crystal", eyes="crystal", deco=['crystals:crystal'], tail='thin')
