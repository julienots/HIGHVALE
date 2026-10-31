"""Créature : Héron céleste. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["bird"]


def build(m):
    creature(m, "bird", "feather_white", "feather_blue", "gold", eyes="dark", deco=[], legs='long', crest='feather_blue', tail='long')
