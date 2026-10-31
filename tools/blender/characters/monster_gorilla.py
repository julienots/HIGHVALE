"""Créature : Gorille des ruines. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["brute"]


def build(m):
    creature(m, "brute", "fur_black", "fur_grey", "gold", eyes="dark", deco=['crown:gold'])
