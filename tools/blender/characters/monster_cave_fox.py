"""Créature : Renard des cavernes. Généré par tools/data/gen_collection.py."""
from characters._beast import creature, EXTENTS

FLAT_PALETTE = True
EXTENT = EXTENTS["quad"]


def build(m):
    creature(m, "quad", "fur_black", "fur_grey", "glow_violet", eyes="glow_gold", deco=[], tail='bushy', tailc='fur_grey')
