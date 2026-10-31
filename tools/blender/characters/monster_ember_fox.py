"""Créature : Renard de braise. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["quad"]


def build(m):
    creature(m, "quad", "fur_orange", "fur_white", "fire", eyes="dark", deco=[], tail='flame', ears='pointy')
