"""Créature : Béhémoth. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["quad"]


def build(m):
    creature(m, "quad", "rock", "rock_light", "crystal", eyes="glow_gold", deco=['crystals:crystal', 'horns:bone', 'moss'], ears='none', legs='short', bulk=1.6, tail='club')
